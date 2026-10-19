-- 1. Creación de la bd
DROP DATABASE IF EXISTS woowguau_db;

CREATE DATABASE woowguau_db
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_spanish_ci;

USE woowguau_db;


-- 2. TABLA: Usuario/rol
CREATE TABLE roles_usuario (
    id_rol INT AUTO_INCREMENT PRIMARY KEY,
    nombre_rol VARCHAR(30) NOT NULL UNIQUE,
    descripcion_rol VARCHAR(150),
    fecha_registro DATETIME DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;


-- 3. TABLA: Usuarios del sistema
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


-- 4. TABLA: Expediente de los empleados
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


-- 5. TABLA: Tipos de especie
CREATE TABLE tipos_especie (
    id_especie INT AUTO_INCREMENT PRIMARY KEY,
    nombre_especie VARCHAR(30) NOT NULL UNIQUE
) ENGINE=InnoDB;


-- 6. TABLA: Categorias de los productos
CREATE TABLE categorias_producto (
    id_categoria INT AUTO_INCREMENT PRIMARY KEY,
    nombre_categoria VARCHAR(50) NOT NULL UNIQUE,
    descripcion_categoria VARCHAR(150)
) ENGINE=InnoDB;


-- 7. TABLA: Marcas comerciales
CREATE TABLE marcas_comerciales (
    id_marca INT AUTO_INCREMENT PRIMARY KEY,
    nombre_marca VARCHAR(50) NOT NULL UNIQUE
) ENGINE=InnoDB;


-- 8. TABLA: Inventario de los productos
CREATE TABLE inventario_productos (
    id_producto INT AUTO_INCREMENT PRIMARY KEY,
    codigo_sku VARCHAR(30) NOT NULL UNIQUE,
    nombre_producto VARCHAR(100) NOT NULL,
    descripcion_producto TEXT NULL,
    precio_publico DECIMAL(10,2) NOT NULL,
    stock_actual INT NOT NULL DEFAULT 0,
    id_especie INT NOT NULL,
    id_categoria INT NOT NULL,
    id_marca INT NOT NULL,
    estatus_producto TINYINT(1) DEFAULT 1,
    fecha_alta DATETIME DEFAULT CURRENT_TIMESTAMP,
    fecha_modificacion DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    CONSTRAINT fk_productos_especie
        FOREIGN KEY (id_especie) REFERENCES tipos_especie(id_especie)
        ON DELETE RESTRICT ON UPDATE CASCADE,

    CONSTRAINT fk_productos_categoria
        FOREIGN KEY (id_categoria) REFERENCES categorias_producto(id_categoria)
        ON DELETE RESTRICT ON UPDATE CASCADE,

    CONSTRAINT fk_productos_marca
        FOREIGN KEY (id_marca) REFERENCES marcas_comerciales(id_marca)
        ON DELETE RESTRICT ON UPDATE CASCADE,

    CONSTRAINT chk_stock_valido
        CHECK (stock_actual >= 0)
) ENGINE=InnoDB;
