CREATE TABLE fact_voice_ai_sessions AS
WITH
a_one AS (
  SELECT
    a.*,
    ROW_NUMBER() OVER (
      PARTITION BY a.session_id
      ORDER BY a.submitted_at DESC
    ) AS rn
  FROM applications a
),
vt_session AS (
  SELECT
    vt.session_id,

    COUNT(*) AS vt_total_turns,
    AVG(vt.turn_duration_sec) AS vt_avg_turn_duration_sec,

    -- treating "no_user_input" as silence-like event
    AVG(CASE WHEN vt.error_type = 'no_user_input' THEN 1.0 ELSE 0.0 END) AS vt_silence_rate,

    -- treating "misunderstanding" as misunderstanding event
    AVG(CASE WHEN vt.error_type = 'misunderstanding' THEN 1.0 ELSE 0.0 END) AS vt_misunderstanding_rate,

    -- Turn-level confidence averages
    AVG(vt.asr_confidence)    AS vt_avg_asr_confidence,
    AVG(vt.intent_confidence) AS vt_avg_intent_confidence,

    -- Useful counts for debugging / KPI reporting
    SUM(CASE WHEN vt.error_type IS NOT NULL THEN 1 ELSE 0 END) AS vt_error_turns,
    SUM(CASE WHEN vt.error_type = 'no_user_input' THEN 1 ELSE 0 END) AS vt_silence_turns,
    SUM(CASE WHEN vt.error_type = 'misunderstanding' THEN 1 ELSE 0 END) AS vt_misunderstanding_turns

  FROM voice_turns vt
  GROUP BY vt.session_id
)
SELECT
  -- Keys
  vs.session_id,
  vs.user_id,

  -- User attributes
  u.region,
  u.disability_flag,
  u.first_time_digital_user,

  -- Session attributes
  vs.channel,
  vs.language,
  vs.created_at AS session_date,
  vs.total_duration_sec,
  vs.total_turns,
  vs.final_outcome,
  vs.transfer_reason,

  -- AI metrics
  vam.avg_asr_confidence,
  vam.avg_intent_confidence,
  vam.misunderstanding_rate,
  vam.silence_rate,
  vam.recovery_success,
  vam.escalation_flag,

  -- Turn-derived metrics
  vt.vt_total_turns,
  vt.vt_avg_turn_duration_sec,
  vt.vt_avg_asr_confidence,
  vt.vt_avg_intent_confidence,
  vt.vt_silence_rate,
  vt.vt_misunderstanding_rate,
  vt.vt_error_turns,
  vt.vt_silence_turns,
  vt.vt_misunderstanding_turns,

  -- Application
  a.application_id,
  a.service_code,
  a.channel AS application_channel,
  a.status  AS application_status,
  a.time_to_submit_sec,
  a.submitted_at,

  -- KPI helper flags
  CASE WHEN vs.final_outcome = 'completed'   THEN 1 ELSE 0 END AS is_completed,
  CASE WHEN vs.final_outcome = 'transferred' THEN 1 ELSE 0 END AS is_transferred,
  CASE WHEN vs.final_outcome = 'abandoned'   THEN 1 ELSE 0 END AS is_abandoned,

  CASE
    WHEN COALESCE(vam.escalation_flag,'no') = 'yes'
      OR vs.final_outcome = 'transferred'
    THEN 1 ELSE 0
  END AS is_escalated,

  CASE WHEN COALESCE(vam.recovery_success,'no') = 'yes' THEN 1 ELSE 0 END AS is_recovered,
  CASE WHEN a.session_id IS NOT NULL THEN 1 ELSE 0 END AS has_application,
  CASE WHEN a.status = 'completed' THEN 1 ELSE 0 END AS application_completed

FROM voice_sessions vs
LEFT JOIN users u
  ON u.user_id = vs.user_id
LEFT JOIN voice_ai_metrics vam
  ON vam.session_id = vs.session_id
LEFT JOIN vt_session vt
  ON vt.session_id = vs.session_id
LEFT JOIN a_one a
  ON a.session_id = vs.session_id
 AND a.rn = 1;








