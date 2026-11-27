USE woowguau_db;

-- 1. Horarios de empleado
CREATE TABLE horarios_empleado (
    id_horario INT AUTO_INCREMENT PRIMARY KEY,
    id_empleado INT NOT NULL,
    dia_semana ENUM('Lunes', 'Martes', 'Miercoles', 'Jueves', 'Viernes', 'Sabado', 'Domingo') NOT NULL,
    hora_entrada TIME NOT NULL,
    hora_salida TIME NOT NULL,
    fecha_alta DATETIME DEFAULT CURRENT_TIMESTAMP,
    fecha_modificacion DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_horarios_empleado
        FOREIGN KEY (id_empleado) REFERENCES expediente_empleados(id_empleado)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT uq_empleado_dia
        UNIQUE (id_empleado, dia_semana),
    CONSTRAINT chk_horas_validas
        CHECK (hora_entrada < hora_salida)
) ENGINE=InnoDB;

-- 2. Asistencias
CREATE TABLE asistencias (
    id_asistencia INT AUTO_INCREMENT PRIMARY KEY,
    id_empleado INT NOT NULL,
    fecha_asistencia DATE NOT NULL,
    hora_entrada_real TIME NULL,
    hora_salida_real TIME NULL,
    estatus_asistencia ENUM('Asistio', 'Retardo', 'Falta', 'Permiso') NOT NULL DEFAULT 'Falta',
    observaciones VARCHAR(255) NULL,
    fecha_alta DATETIME DEFAULT CURRENT_TIMESTAMP,
    fecha_modificacion DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_asistencias_empleado
        FOREIGN KEY (id_empleado) REFERENCES expediente_empleados(id_empleado)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT uq_empleado_fecha
        UNIQUE (id_empleado, fecha_asistencia),
    CONSTRAINT chk_horas_reales_validas
        CHECK (hora_entrada_real IS NULL OR hora_salida_real IS NULL OR hora_entrada_real < hora_salida_real)
) ENGINE=InnoDB;

-- 3. Incidencias laborales
CREATE TABLE incidencias_laborales (
    id_incidencia INT AUTO_INCREMENT PRIMARY KEY,
    id_empleado INT NOT NULL,
    id_usuario_registra INT NOT NULL,
    tipo_incidencia ENUM('Incapacidad', 'Desaprobacion', 'Accidente', 'Conducta', 'Otro') NOT NULL,
    fecha_incidencia DATE NOT NULL,
    descripcion TEXT NOT NULL,
    estatus_incidencia ENUM('Abierta', 'En Revision', 'Cerrada') DEFAULT 'Abierta',
    fecha_alta DATETIME DEFAULT CURRENT_TIMESTAMP,
    fecha_modificacion DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_incidencias_empleado
        FOREIGN KEY (id_empleado) REFERENCES expediente_empleados(id_empleado)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_incidencias_usuario
        FOREIGN KEY (id_usuario_registra) REFERENCES usuarios_sistema(id_usuario)
        ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;
