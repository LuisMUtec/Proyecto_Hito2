-- Configuración para obtener mejores métricas de rendimiento
SET track_io_timing = ON;  -- Habilita el seguimiento de tiempo de I/O

-- Limpiar caché para medición "cold query" (opcional, comentar si no se desea)
SELECT pg_stat_reset();
DISCARD ALL;

--1. **Médicos más solicitados**: Identifica los médicos con mayor demanda y su efectividad
EXPLAIN (ANALYZE, BUFFERS, VERBOSE, FORMAT TEXT)
SELECT
    e.nombre AS especialidad,
    m.nombre || ' ' || m.apellido AS medico,
    COUNT(c.id_cita) AS total_citas,
    COUNT(CASE WHEN c.estado = 'atendida' THEN 1 END) AS citas_atendidas,
    COUNT(CASE WHEN c.estado = 'cancelada' THEN 1 END) AS citas_canceladas,
    ROUND(
            COUNT(CASE WHEN c.estado = 'atendida' THEN 1 END) * 100.0 / COUNT(c.id_cita), 2
    ) AS porcentaje_efectividad
FROM Medico m
         JOIN Medico_Especialidad me ON m.dni = me.dni_medico
         JOIN Especialidad e ON me.nombre_especialidad = e.nombre
         LEFT JOIN Cita c ON m.dni = c.dni_medico
WHERE c.fecha >= CURRENT_DATE - INTERVAL '6 months'
GROUP BY e.nombre, m.dni, m.nombre, m.apellido
HAVING COUNT(c.id_cita) > 0
ORDER BY total_citas DESC;

--2. **Patrones de pacientes**: Detecta pacientes frecuentes y sus hábitos de atención
EXPLAIN (ANALYZE, BUFFERS, VERBOSE, FORMAT TEXT)
SELECT
    p.dni,
    p.nombre || ' ' || p.apellido AS paciente,
    p.tipo_seguro,
    COUNT(c.id_cita) AS total_citas,
    COUNT(DISTINCT c.dni_medico) AS medicos_diferentes,
    COUNT(DISTINCT me.nombre_especialidad) AS especialidades_visitadas,
    MIN(c.fecha) AS primera_cita,
    MAX(c.fecha) AS ultima_cita,
    AVG(EXTRACT(EPOCH FROM c.hora) / 3600) AS hora_promedio_citas,
    STRING_AGG(DISTINCT me.nombre_especialidad, ', ') AS especialidades
FROM Paciente p
         JOIN Cita c ON p.dni = c.dni_paciente
         JOIN Medico_Especialidad me ON c.dni_medico = me.dni_medico
WHERE c.fecha >= CURRENT_DATE - INTERVAL '1 year'
GROUP BY p.dni, p.nombre, p.apellido, p.tipo_seguro
HAVING COUNT(c.id_cita) >= 3
ORDER BY total_citas DESC, especialidades_visitadas DESC;

--3. **Disponibilidad vs demanda**: Compara recursos médicos disponibles con la demanda real
EXPLAIN (ANALYZE, BUFFERS, VERBOSE, FORMAT TEXT)
WITH disponibilidad_medica AS (
    SELECT
        e.nombre AS especialidad,
        COUNT(DISTINCT m.dni) AS total_medicos,
        COUNT(DISTINCT CASE
                           WHEN c.fecha >= CURRENT_DATE - INTERVAL '1 month'
                               THEN m.dni
            END) AS medicos_activos
    FROM Especialidad e
             LEFT JOIN Medico_Especialidad me ON e.nombre = me.nombre_especialidad
             LEFT JOIN Medico m ON me.dni_medico = m.dni
             LEFT JOIN Cita c ON m.dni = c.dni_medico
    GROUP BY e.nombre
),
     demanda_especialidad AS (
         SELECT
             e.nombre AS especialidad,
             COUNT(c.id_cita) AS citas_solicitadas,
             COUNT(CASE WHEN c.estado = 'cancelada' THEN 1 END) AS citas_canceladas,
             COUNT(CASE WHEN c.fecha > CURRENT_DATE THEN 1 END) AS citas_futuras
         FROM Especialidad e
                  JOIN Medico_Especialidad me ON e.nombre = me.nombre_especialidad
                  JOIN Cita c ON me.dni_medico = c.dni_medico
         WHERE c.fecha >= CURRENT_DATE - INTERVAL '2 months'
         GROUP BY e.nombre
     )
SELECT
    d.especialidad,
    dm.total_medicos,
    dm.medicos_activos,
    d.citas_solicitadas,
    d.citas_canceladas,
    d.citas_futuras,
    ROUND(d.citas_solicitadas::DECIMAL / NULLIF(dm.medicos_activos, 0), 2) AS citas_por_medico_activo,
    ROUND(d.citas_canceladas * 100.0 / d.citas_solicitadas, 2) AS porcentaje_cancelacion
FROM disponibilidad_medica dm
         JOIN demanda_especialidad d ON dm.especialidad = d.especialidad
WHERE dm.total_medicos > 0
ORDER BY citas_por_medico_activo DESC;

-- Consultas adicionales para análisis de rendimiento
-- Estadísticas de tablas (ejecutar antes y después para comparar)
EXPLAIN (ANALYZE, BUFFERS) SELECT COUNT(*) FROM Medico;
EXPLAIN (ANALYZE, BUFFERS) SELECT COUNT(*) FROM Cita;
EXPLAIN (ANALYZE, BUFFERS) SELECT COUNT(*) FROM Paciente;
EXPLAIN (ANALYZE, BUFFERS) SELECT COUNT(*) FROM Especialidad;
EXPLAIN (ANALYZE, BUFFERS) SELECT COUNT(*) FROM Medico_Especialidad;

-- Verificar estadísticas de índices utilizados (CORREGIDA)
SELECT 
    schemaname,
    relname as tabla,
    indexrelname as indice,
    idx_scan as escaneos_indice,
    idx_tup_read as tuplas_leidas,
    idx_tup_fetch as tuplas_obtenidas
FROM pg_stat_user_indexes 
WHERE relname IN ('medico', 'cita', 'paciente', 'especialidad', 'medico_especialidad')
ORDER BY idx_scan DESC;

-- Consultas alternativas para estadísticas de índices si la anterior no funciona
-- Opción 1: Ver todos los índices de las tablas
SELECT 
    t.relname AS tabla,
    i.relname AS indice,
    pg_size_pretty(pg_relation_size(i.oid)) AS tamaño_indice
FROM pg_class t
JOIN pg_index ix ON t.oid = ix.indrelid
JOIN pg_class i ON i.oid = ix.indexrelid
WHERE t.relname IN ('medico', 'cita', 'paciente', 'especialidad', 'medico_especialidad')
ORDER BY t.relname, i.relname;

-- Opción 2: Estadísticas básicas de tablas
SELECT 
    relname as tabla,
    n_tup_ins as inserciones,
    n_tup_upd as actualizaciones,
    n_tup_del as eliminaciones,
    n_live_tup as filas_activas,
    n_dead_tup as filas_muertas,
    last_vacuum,
    last_autovacuum,
    last_analyze,
    last_autoanalyze
FROM pg_stat_user_tables 
WHERE relname IN ('medico', 'cita', 'paciente', 'especialidad', 'medico_especialidad')
ORDER BY relname;