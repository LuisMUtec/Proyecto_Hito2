/* Tabla Persona */
CREATE TABLE Persona (
                         id_persona INT,
                         nombre VARCHAR(50),
                         apellido VARCHAR(50),
                         dni VARCHAR(8),
                         fecha_nacimiento DATE,
                         sexo CHAR(1),
                         correo VARCHAR(100),
                         telefono VARCHAR(15)
);

ALTER TABLE Persona ADD CONSTRAINT Persona_PK PRIMARY KEY (id_persona);


/* Tabla Paciente */
CREATE TABLE Paciente (
                          id_paciente INT,
                          id_persona INT,
                          tipo_seguro VARCHAR(10),
                          fecha_registro DATE
);

ALTER TABLE Paciente ADD CONSTRAINT Paciente_PK PRIMARY KEY (id_paciente);
ALTER TABLE Paciente ADD CONSTRAINT Paciente_FK FOREIGN KEY (id_persona) REFERENCES Persona(id_persona);


/* Tabla Especialidad */
CREATE TABLE Especialidad (
                              id_especialidad INT,
                              nombre VARCHAR(50),
                              descripcion TEXT
);

ALTER TABLE Especialidad ADD CONSTRAINT Especialidad_PK PRIMARY KEY (id_especialidad);


/* Tabla Médico */
CREATE TABLE Medico (
                        id_medico INT,
                        id_persona INT,
                        id_especialidad INT
);

ALTER TABLE Medico ADD CONSTRAINT Medico_PK PRIMARY KEY (id_medico);
ALTER TABLE Medico ADD CONSTRAINT Medico_FK1 FOREIGN KEY (id_persona) REFERENCES Persona(id_persona);
ALTER TABLE Medico ADD CONSTRAINT Medico_FK2 FOREIGN KEY (id_especialidad) REFERENCES Especialidad(id_especialidad);


/* Tabla Cabina */
CREATE TABLE Cabina (
                        id_cabina INT,
                        numero VARCHAR(10),
                        ubicacion VARCHAR(100)
);

ALTER TABLE Cabina ADD CONSTRAINT Cabina_PK PRIMARY KEY (id_cabina);


/* Tabla Personal */
CREATE TABLE Personal (
                          id_personal INT,
                          id_persona INT,
                          rol VARCHAR(20)
);

ALTER TABLE Personal ADD CONSTRAINT Personal_PK PRIMARY KEY (id_personal);
ALTER TABLE Personal ADD CONSTRAINT Personal_FK FOREIGN KEY (id_persona) REFERENCES Persona(id_persona);


/* Tabla Turno */
CREATE TABLE Turno (
                       id_personal INT,
                       id_cabina INT,
                       fecha DATE,
                        turno VARCHAR(20)
);

ALTER TABLE Turno ADD CONSTRAINT Turno_PK PRIMARY KEY (fecha, turno);
ALTER TABLE Turno ADD CONSTRAINT Turno_FK1 FOREIGN KEY (id_personal) REFERENCES Personal(id_personal);
ALTER TABLE Turno ADD CONSTRAINT Turno_FK2 FOREIGN KEY (id_cabina) REFERENCES Cabina(id_cabina);


/* Tabla Cita */
CREATE TABLE Cita (
                      id_cita INT,
                      id_paciente INT,
                      id_medico INT,
                      fecha DATE,
                      hora TIME,
                      estado VARCHAR(20),
                      id_personal_registro INT
);

ALTER TABLE Cita ADD CONSTRAINT Cita_PK PRIMARY KEY (id_cita);
ALTER TABLE Cita ADD CONSTRAINT Cita_FK1 FOREIGN KEY (id_paciente) REFERENCES Paciente(id_paciente);
ALTER TABLE Cita ADD CONSTRAINT Cita_FK2 FOREIGN KEY (id_medico) REFERENCES Medico(id_medico);
ALTER TABLE Cita ADD CONSTRAINT Cita_FK3 FOREIGN KEY (id_personal_registro) REFERENCES Personal(id_personal);


select*from cita
