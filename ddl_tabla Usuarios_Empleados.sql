USE woowguau_db;

-- 1. TABLA: Roles del sistema
CREATE TABLE roles_usuario (
    id_rol INT AUTO_INCREMENT PRIMARY KEY,
    nombre_rol VARCHAR(30) NOT NULL UNIQUE,
    descripcion_rol VARCHAR(150),
    fecha_registro DATETIME DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- 2. TABLA: Usuarios del sistema (con hash para contraseñas)
CREATE TABLE usuarios_sistema (
    id_usuario INT AUTO_INCREMENT PRIMARY KEY,
    nombre_usuario VARCHAR(50) NOT NULL UNIQUE,
    correo VARCHAR(100) NOT NULL UNIQUE,
    hash_contrasena VARCHAR(255) NOT NULL,
    id_rol INT NOT NULL,
    estatus_cuenta TINYINT(1) DEFAULT 1,
    fecha_ultimo_acceso DATETIME NULL,
    fecha_alta DATETIME DEFAULT CURRENT_TIMESTAMP,
    fecha_modificacion DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_usuarios_roles
        FOREIGN KEY (id_rol) REFERENCES roles_usuario(id_rol)
        ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;

-- 3. TABLA: Expediente de los empleados
CREATE TABLE expediente_empleados (
    id_empleado INT AUTO_INCREMENT PRIMARY KEY,
    id_usuario INT UNIQUE NULL,
    numero_empleado VARCHAR(15) NOT NULL UNIQUE,
    nombre_empleado VARCHAR(50) NOT NULL,
    apellido_paterno VARCHAR(50) NOT NULL,
    apellido_materno VARCHAR(50) NULL,
    telefono_contacto VARCHAR(15) NULL,
    puesto_trabajo VARCHAR(50) NOT NULL,
    fecha_ingreso DATE NOT NULL,
    estatus_laboral ENUM('Activo', 'Inactivo', 'Baja Logica') DEFAULT 'Activo',
    fecha_alta DATETIME DEFAULT CURRENT_TIMESTAMP,
    fecha_modificacion DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_empleados_usuarios
        FOREIGN KEY (id_usuario) REFERENCES usuarios_sistema(id_usuario)
        ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB;
