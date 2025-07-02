
--1. **Médicos más solicitados**: Identifica los médicos con mayor demanda y su efectividad

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

--2. **Ocupación de consultorios**: Analiza el uso de espacios físicos y recursos

SELECT
    co.numero AS consultorio,
    co.ubicacion,
    DATE_PART('month', c.fecha) AS mes,
    COUNT(c.id_cita) AS citas_programadas,
    COUNT(DISTINCT c.dni_medico) AS medicos_diferentes,
    COUNT(DISTINCT c.dni_personal) AS personal_asignado,
    AVG(CASE
            WHEN c.estado = 'atendida' THEN 1
            ELSE 0
        END) AS tasa_atencion
FROM Consultorio co
         LEFT JOIN Cita c ON co.numero = c.numero_consultorio
WHERE c.fecha >= CURRENT_DATE - INTERVAL '3 months'
GROUP BY co.numero, co.ubicacion, DATE_PART('month', c.fecha)
HAVING COUNT(c.id_cita) > 5
ORDER BY consultorio, mes;

--3. **Patrones de pacientes**: Detecta pacientes frecuentes y sus hábitos de atención

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

--4. **Carga de trabajo del personal**: Evalúa la distribución de trabajo en cabinas

SELECT
    p.nombre || ' ' || p.apellido AS personal,
    ca.numero AS cabina,
    ca.ubicacion,
    COUNT(DISTINCT t.fecha) AS dias_trabajados,
    STRING_AGG(DISTINCT t.horario, ', ' ORDER BY t.horario) AS turnos_asignados,
    COUNT(DISTINCT c.id_cita) AS citas_gestionadas,
    AVG(CASE
            WHEN c.estado IN ('confirmada', 'atendida') THEN 1
            ELSE 0
        END) AS tasa_confirmacion
FROM Personal p
         JOIN Turno t ON p.dni = t.dni_personal
         JOIN Cabina ca ON t.numero_cabina = ca.numero
         LEFT JOIN Cita c ON p.dni = c.dni_personal
    AND c.fecha = t.fecha
WHERE t.fecha >= CURRENT_DATE - INTERVAL '1 month'
GROUP BY p.dni, p.nombre, p.apellido, ca.numero, ca.ubicacion
ORDER BY citas_gestionadas DESC, dias_trabajados DESC;

--5. **Disponibilidad vs demanda**: Compara recursos médicos disponibles con la demanda real

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