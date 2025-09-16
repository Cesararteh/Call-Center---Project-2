USE call_center;

-- Visualización de la base de datos 
SELECT * FROM call_center_base;

-- CREACIÓN DE TABLAS
-- Tabla de agentes únicos
CREATE TABLE Agents(
	id_agents int IDENTITY(1,1) PRIMARY KEY,
	name_agent VARCHAR(70))
--Visualización de agentes únicos
SELECT DISTINCT Agent from call_center_base;
--Insertar datos de los agentes en la tabla Agents
INSERT INTO Agents (name_agent)
SELECT DISTINCT Agent
FROM call_center_base
WHERE Agent IS NOT NULL;
--Verificación de la tabla 
SELECT * FROM Agents;

-- Creación de tabla Topic
CREATE TABLE Topic (
	id_topic int IDENTITY(1,1) PRIMARY KEY,
	name_topic VARCHAR(100))
--Visualización de temas únicos
SELECT DISTINCT Topic from call_center_base;
--Insertar datos de los temas en la tabla Topic
INSERT INTO Topic(name_topic)
SELECT DISTINCT Topic
FROM call_center_base
WHERE Topic IS NOT NULL;
--Verificación de la tabla 
SELECT * FROM Topic;

-- Creación de tabla Calls
SELECT * INTO Calls
FROM call_center_base;


-- Verificar algo en la tabla original
SELECT *
FROM call_center_base
WHERE Answered_Y_N <> Answered
   OR (Answered_Y_N IS NULL AND Answered IS NOT NULL)
   OR (Answered_Y_N IS NOT NULL AND Answered IS NULL);

SELECT 
    COUNT(*) AS total_filas,
    SUM(CASE WHEN Answered_Y_N = Answered THEN 1 ELSE 0 END) AS iguales,
    SUM(CASE WHEN Answered_Y_N <> Answered OR Answered_Y_N IS NULL OR Answered IS NULL THEN 1 ELSE 0 END) AS diferentes
FROM call_center_base;

-- Verificación de datos en la tabla Calls
select * from Calls;
SELECT COLUMN_NAME, DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'call_center_base' AND COLUMN_NAME = 'Time';


-- Limpieza de la copia de tabla base (Calls)
Select * from Calls; 
-- Añadir la columna id_call
ALTER TABLE Calls
ADD id_call INT IDENTITY(1,1);
-- Añadir la columna id_agent y id_topic
ALTER TABLE Calls
ADD id_agent INT,
id_topic INT;
--Establecer foreing keys
ALTER TABLE Calls
ADD CONSTRAINT FK_calls
FOREIGN KEY (id_agent)
REFERENCES Agents (id_agents);

ALTER TABLE Calls
ADD CONSTRAINT FK_topics
FOREIGN KEY (id_topic)
REFERENCES Topic (id_topic);

-- Realización de joins entre las tablas
Select * from Calls; 
SELECT 
    c.Call_Id,
    a.name_agent,
    a.id_agents
FROM Calls c
JOIN Agents a ON c.Agent = a.name_agent

UPDATE c
SET c.id_agent = a.id_agents
FROM Calls c
JOIN Agents a ON c.Agent = a.name_agent;


SELECT 
    c.Call_Id,
    t.name_topic,
    t.id_topic
FROM Calls c
JOIN Topic t ON c.Topic = t.name_topic

UPDATE c
SET c.id_topic = t.id_topic
FROM Calls c
JOIN Topic t ON c.Topic = t.name_topic;


-- LIMPIEZA DE LA TABLA CALLS
ALTER TABLE Calls
DROP COLUMN Agent, Topic, Answered_Y_N;

-- PROCEDIMIENTOS EXTRAS
SELECT COLUMN_NAME, DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'Calls'


ALTER TABLE Calls
ADD CONSTRAINT FK_agent
FOREIGN KEY (id_agent) REFERENCES Agents(id_agents);

ALTER TABLE Calls
ADD CONSTRAINT FK_topic
FOREIGN KEY (id_topic) REFERENCES Topic(id_topic);

--VISTA PRINCIPAL POR AGENTE

Select * from Calls;

Select
    id_agent,
    COUNT(*) as Total_cases,
    ROUND(AVG(speed_of_answer_in_seconds),2) AS Speed_answer ,
    AVG(DATEDIFF(SECOND, 0, AvgTalkDuration)) AS avg_talk_duration,
    ROUND(AVG(Satisfaction_rating), 2) AS avg_rating
from vw_agent_performance
where Month(Date) = 01 and Answered = 1 or Resolved = 1
group by id_agent
order by id_agent;

CREATE PROCEDURE sp_AgentPerformanceSummary
    @Month INT,
    @Answered BIT,
    @Resolved BIT,
    @Year INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        id_agent,
        COUNT(*) AS Total_cases,
        ROUND(AVG(speed_of_answer_in_seconds), 2) AS Speed_answer,
        AVG(DATEDIFF(SECOND, 0, AvgTalkDuration)) AS avg_talk_duration,
        ROUND(AVG(Satisfaction_rating), 2) AS avg_rating
    FROM vw_agent_performance
    WHERE 
        YEAR(Date) = @Year 
        AND MONTH(Date) = @Month 
        AND (Answered = @Answered OR Resolved = @Resolved)
    GROUP BY id_agent
    ORDER BY id_agent;
END;


EXEC sp_AgentPerformanceSummary 
    @Month = 2, 
    @Answered = 1, 
    @Resolved = 1, 
    @Year = 2021;


DECLARE @MetaMensual INT = 1500;
DECLARE @UltimoYear INT;
DECLARE @UltimoMes INT;

-- Identificar último año y mes con registros
SELECT 
    @UltimoYear = YEAR(MAX(Date)),
    @UltimoMes = MONTH(MAX(Date))
FROM Calls;

-- Consulta principal
SELECT 
    id_agent,
    COUNT(*) AS casos_ultimo_mes,
    ROUND((COUNT(*) * 1.0 / total_global) * @MetaMensual, 0) AS casos_estimados
FROM Calls
CROSS JOIN (
    SELECT COUNT(*) AS total_global
    FROM Calls
    WHERE YEAR(Date) = @UltimoYear AND MONTH(Date) = @UltimoMes
) AS global
WHERE YEAR(Date) = @UltimoYear AND MONTH(Date) = @UltimoMes
GROUP BY id_agent, total_global;

--VISTA DE QUANTITY PERFORMANCE
CREATE VIEW vw_AgentProductivity AS
WITH UltimoMes AS (
    SELECT 
        YEAR(MAX(Date)) AS UltimoYear,
        MONTH(MAX(Date)) AS UltimoMes
    FROM Calls
),
MetaGeneral AS (
    SELECT ROUND(AVG(casos), 0) AS meta_general
    FROM (
        SELECT id_agent, COUNT(*) AS casos
        FROM Calls, UltimoMes
        WHERE YEAR(Date) = UltimoMes.UltimoYear 
          AND MONTH(Date) = UltimoMes.UltimoMes
        GROUP BY id_agent
    ) AS t
)
SELECT 
    c.id_agent,
    COUNT(*) AS casos_ultimo_mes,
    m.meta_general
FROM Calls c
CROSS JOIN UltimoMes u
CROSS JOIN MetaGeneral m
WHERE YEAR(c.Date) = u.UltimoYear 
  AND MONTH(c.Date) = u.UltimoMes
GROUP BY c.id_agent, m.meta_general;

Select * from vw_AgentProductivity3;

-- VISTA DE QUALITY PERFORMANCE

CREATE VIEW vw_AgentProductivity3 AS
WITH UltimoMes AS (
    SELECT 
        YEAR(MAX(Date)) AS UltimoYear,
        MONTH(MAX(Date)) AS UltimoMes
    FROM Calls
)
SELECT 
    c.id_agent,
    SUM(CASE WHEN c.Resolved = 1 THEN 1 ELSE 0 END) AS resolved_cases,
    CAST(SUM(CASE WHEN c.Resolved = 1 THEN 1 ELSE 0 END) AS FLOAT) / COUNT(*) * 100 AS porcentaje_resueltas
FROM Calls c
CROSS JOIN UltimoMes u
WHERE YEAR(c.Date) = u.UltimoYear 
  AND MONTH(c.Date) = u.UltimoMes
GROUP BY c.id_agent;
