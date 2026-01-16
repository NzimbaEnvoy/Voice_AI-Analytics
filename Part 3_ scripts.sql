---top three friction points in Voice AI interactions
SELECT
  friction_type,
  avg_rate
FROM (
  SELECT
    'Misunderstanding rate' AS friction_type,
    AVG(fvas.misunderstanding_rate) AS avg_rate
  FROM fact_voice_ai_sessions fvas

  UNION ALL

  SELECT
    'Silence rate',
    AVG(fvas.silence_rate)
  FROM fact_voice_ai_sessions fvas

  UNION ALL

  SELECT
    'Escalation rate',
    AVG(CASE WHEN fvas.is_escalated = 1 THEN 1.0 ELSE 0.0 END)
  FROM fact_voice_ai_sessions fvas
) x
ORDER BY avg_rate DESC
LIMIT 3;



---Voice vs non-voice channels

SELECT
  fvas.channel,
  COUNT(*) AS total_sessions,
  AVG(CASE WHEN fvas.is_completed = 1 THEN 1.0 ELSE 0.0 END) AS completion_rate
FROM fact_voice_ai_sessions fvas
GROUP BY fvas.channel
ORDER BY completion_rate DESC;



----Rural vs urban users

SELECT
  fvas.region,
  COUNT(*) AS total_sessions,
  AVG(CASE WHEN fvas.is_completed = 1 THEN 1.0 ELSE 0.0 END) AS completion_rate,
  AVG(CASE WHEN fvas.is_escalated = 1 THEN 1.0 ELSE 0.0 END) AS escalation_rate
FROM fact_voice_ai_sessions fvas
GROUP BY fvas.region;


---First-time digital users — performance by channel

SELECT
  fvas.channel,
  COUNT(*) AS total_sessions,
  AVG(CASE WHEN fvas.is_completed = 1 THEN 1.0 ELSE 0.0 END) AS completion_rate,
  AVG(CASE WHEN fvas.is_escalated = 1 THEN 1.0 ELSE 0.0 END) AS escalation_rate
FROM fact_voice_ai_sessions fvas
WHERE fvas.first_time_digital_user = 'yes'
GROUP BY fvas.channel
ORDER BY completion_rate DESC;



---Compare first-time vs experienced users
select
  fvas.channel,
  fvas.first_time_digital_user,
  COUNT(*) AS total_sessions,
  AVG(CASE WHEN fvas.is_completed = 1 THEN 1.0 ELSE 0.0 END) AS completion_rate,
  AVG(CASE WHEN fvas.is_escalated = 1 THEN 1.0 ELSE 0.0 END) AS escalation_rate
FROM fact_voice_ai_sessions fvas
WHERE fvas.channel = 'voice'
GROUP BY fvas.first_time_digital_user, fvas.channel;


---Consolidated effectiveness view

SELECT
  fvas.channel,
  fvas.first_time_digital_user,
  fvas.region,
  COUNT(*) AS sessions,
  AVG(fvas.is_completed) AS completion_rate,
  AVG(fvas.is_escalated) AS escalation_rate,
  AVG(fvas.misunderstanding_rate) AS misunderstanding_rate,
  AVG(fvas.silence_rate) AS silence_rate
FROM fact_voice_ai_sessions fvas
GROUP BY
  fvas.channel,
  fvas.first_time_digital_user,
  fvas.region;


