-- ========================================
-- Tabla PACIENTE
-- ========================================
CREATE TABLE Paciente (
                          dni CHAR(8) NOT NULL,
                          nombre VARCHAR(50) NOT NULL,
                          apellido VARCHAR(50) NOT NULL,
                          fecha_nacimiento DATE,
                          sexo CHAR(1),
                          correo VARCHAR(100),
                          telefono VARCHAR(15),
                          tipo_seguro VARCHAR(10),
                          fecha_registro DATE DEFAULT CURRENT_DATE
);

ALTER TABLE Paciente ADD CONSTRAINT paciente_pk PRIMARY KEY (dni);
ALTER TABLE Paciente ADD CONSTRAINT paciente_uq_correo UNIQUE (correo);
ALTER TABLE Paciente ADD CONSTRAINT paciente_ck_sexo CHECK (sexo IN ('M', 'F'));
ALTER TABLE Paciente ADD CONSTRAINT paciente_ck_seguro CHECK (tipo_seguro IN ('SIS', 'Essalud', 'Privado', 'Ninguno'));


-- ========================================
-- Tabla ESPECIALIDAD
-- ========================================
CREATE TABLE Especialidad (
                              nombre VARCHAR(50) NOT NULL,
                              descripcion TEXT
);

ALTER TABLE Especialidad ADD CONSTRAINT especialidad_pk PRIMARY KEY (nombre);
ALTER TABLE Especialidad ADD CONSTRAINT especialidad_uq_nombre UNIQUE (nombre);


-- ========================================
-- Tabla MEDICO
-- ========================================
CREATE TABLE Medico (
                        dni CHAR(8) NOT NULL,
                        nombre VARCHAR(50) NOT NULL,
                        apellido VARCHAR(50) NOT NULL,
                        fecha_nacimiento DATE,
                        sexo CHAR(1),
                        correo VARCHAR(100),
                        telefono VARCHAR(15)
);

ALTER TABLE Medico ADD CONSTRAINT medico_pk PRIMARY KEY (dni);
ALTER TABLE Medico ADD CONSTRAINT medico_uq_correo UNIQUE (correo);
ALTER TABLE Medico ADD CONSTRAINT medico_ck_sexo CHECK (sexo IN ('M', 'F'));


-- ========================================
-- Tabla MEDICO_ESPECIALIDAD (N:M)
-- ========================================
CREATE TABLE Medico_Especialidad (
                                     dni_medico CHAR(8) NOT NULL,
                                     nombre_especialidad VARCHAR(50) NOT NULL
);

ALTER TABLE Medico_Especialidad ADD CONSTRAINT medico_especialidad_pk PRIMARY KEY (dni_medico, nombre_especialidad);
ALTER TABLE Medico_Especialidad ADD CONSTRAINT medico_especialidad_fk_medico FOREIGN KEY (dni_medico) REFERENCES Medico(dni);
ALTER TABLE Medico_Especialidad ADD CONSTRAINT medico_especialidad_fk_especialidad FOREIGN KEY (nombre_especialidad) REFERENCES Especialidad(nombre);


-- ========================================
-- Tabla CABINA
-- ========================================
CREATE TABLE Cabina (
                        numero VARCHAR(30) NOT NULL,
                        ubicacion VARCHAR(100) NOT NULL
);

ALTER TABLE Cabina ADD CONSTRAINT cabina_pk PRIMARY KEY (numero);
ALTER TABLE Cabina ADD CONSTRAINT cabina_uq UNIQUE (numero, ubicacion);


-- ========================================
-- Tabla CONSULTORIO
-- ========================================
CREATE TABLE Consultorio (
                             numero VARCHAR(30) NOT NULL,
                             ubicacion VARCHAR(100) NOT NULL
);

ALTER TABLE Consultorio ADD CONSTRAINT consultorio_pk PRIMARY KEY (numero);
ALTER TABLE Consultorio ADD CONSTRAINT consultorio_uq UNIQUE (numero, ubicacion);


-- ========================================
-- Tabla PERSONAL
-- ========================================
CREATE TABLE Personal (
                          dni CHAR(8) NOT NULL,
                          nombre VARCHAR(50) NOT NULL,
                          apellido VARCHAR(50) NOT NULL,
                          fecha_nacimiento DATE,
                          sexo CHAR(1),
                          correo VARCHAR(100),
                          telefono VARCHAR(15)
);

ALTER TABLE Personal ADD CONSTRAINT personal_pk PRIMARY KEY (dni);
ALTER TABLE Personal ADD CONSTRAINT personal_uq_correo UNIQUE (correo);
ALTER TABLE Personal ADD CONSTRAINT personal_ck_sexo CHECK (sexo IN ('M', 'F'));


-- ========================================
-- Tabla TURNO (id_turno manual y numero_cabina)
-- ========================================
CREATE TABLE Turno (
                       dni_personal CHAR(8) NOT NULL,
                       numero_cabina VARCHAR(30) NOT NULL,
                       fecha DATE NOT NULL,
                       horario VARCHAR(20) NOT NULL
);

ALTER TABLE Turno ADD CONSTRAINT turno_pk PRIMARY KEY (horario, fecha, numero_cabina);
ALTER TABLE Turno ADD CONSTRAINT turno_fk_personal FOREIGN KEY (dni_personal) REFERENCES Personal(dni);
ALTER TABLE Turno ADD CONSTRAINT turno_fk_cabina FOREIGN KEY (numero_cabina) REFERENCES Cabina(numero);
ALTER TABLE Turno ADD CONSTRAINT turno_ck_turno CHECK (horario IN ('mañana', 'tarde', 'noche'));



-- ========================================
-- Tabla CITA (id_cita SERIAL y numero_consultorio)
-- ========================================
CREATE TABLE Cita (
                      id_cita SERIAL,
                      dni_paciente CHAR(8) NOT NULL,
                      dni_medico CHAR(8) NOT NULL,
                      fecha DATE NOT NULL,
                      hora TIME NOT NULL,
                      estado VARCHAR(20),
                      dni_personal CHAR(8) NOT NULL,
                      numero_consultorio VARCHAR(30) NOT NULL
);

ALTER TABLE Cita ADD CONSTRAINT cita_pk PRIMARY KEY (id_cita);
ALTER TABLE Cita ADD CONSTRAINT cita_fk_paciente FOREIGN KEY (dni_paciente) REFERENCES Paciente(dni);
ALTER TABLE Cita ADD CONSTRAINT cita_fk_medico FOREIGN KEY (dni_medico) REFERENCES Medico(dni);
ALTER TABLE Cita ADD CONSTRAINT cita_fk_personal FOREIGN KEY (dni_personal) REFERENCES Personal(dni);
ALTER TABLE Cita ADD CONSTRAINT cita_fk_consultorio FOREIGN KEY (numero_consultorio) REFERENCES Consultorio(numero);
ALTER TABLE Cita ADD CONSTRAINT cita_ck_estado CHECK (estado IN ('pendiente', 'confirmada', 'cancelada', 'atendida'));
ALTER TABLE Cita ADD CONSTRAINT cita_uq UNIQUE (dni_medico, fecha, hora);


