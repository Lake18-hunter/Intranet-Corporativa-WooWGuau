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

-- 8. TABLA: Inventario de los productos (con costo_unitario, stock_minimo y fecha_caducidad integrados)
CREATE TABLE inventario_productos (
    id_producto INT AUTO_INCREMENT PRIMARY KEY,
    codigo_sku VARCHAR(30) NOT NULL UNIQUE,
    nombre_producto VARCHAR(100) NOT NULL,
    descripcion_producto TEXT NULL,
    precio_publico DECIMAL(10,2) NOT NULL,
    costo_unitario DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    stock_actual INT NOT NULL DEFAULT 0,
    stock_minimo INT NOT NULL DEFAULT 5,
    fecha_caducidad DATE NULL,
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
    CONSTRAINT chk_precio_publico_valido CHECK (precio_publico >= 0),
    CONSTRAINT chk_costo_unitario_producto CHECK (costo_unitario >= 0),
    CONSTRAINT chk_stock_actual_valido CHECK (stock_actual >= 0),
    CONSTRAINT chk_stock_minimo_producto CHECK (stock_minimo >= 0)
) ENGINE=InnoDB;

-- 9. TABLA: Proveedores
CREATE TABLE proveedores (
    id_proveedor INT AUTO_INCREMENT PRIMARY KEY,
    nombre_proveedor VARCHAR(120) NOT NULL,
    rfc VARCHAR(13) NOT NULL UNIQUE,
    nombre_contacto VARCHAR(100) NULL,
    telefono VARCHAR(20) NULL,
    correo VARCHAR(100) NULL,
    direccion VARCHAR(255) NULL,
    estatus_proveedor TINYINT(1) NOT NULL DEFAULT 1,
    fecha_alta DATETIME DEFAULT CURRENT_TIMESTAMP,
    fecha_modificacion DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT chk_rfc_longitud CHECK (CHAR_LENGTH(rfc) IN (12, 13)),
    CONSTRAINT chk_estatus_proveedor CHECK (estatus_proveedor IN (0, 1))
) ENGINE=InnoDB;

-- 10. TABLA: Ordenes de compra
CREATE TABLE ordenes_compra (
    id_orden INT AUTO_INCREMENT PRIMARY KEY,
    folio_orden VARCHAR(30) NOT NULL UNIQUE,
    id_proveedor INT NOT NULL,
    id_usuario_crea INT NOT NULL,
    estatus_orden ENUM('Borrador', 'Enviada', 'Recibida', 'Cancelada') NOT NULL DEFAULT 'Borrador',
    total_orden DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    observaciones TEXT NULL,
    fecha_recepcion DATETIME NULL,
    fecha_alta DATETIME DEFAULT CURRENT_TIMESTAMP,
    fecha_modificacion DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_ordenes_proveedor
        FOREIGN KEY (id_proveedor) REFERENCES proveedores(id_proveedor)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_ordenes_usuario
        FOREIGN KEY (id_usuario_crea) REFERENCES usuarios_sistema(id_usuario)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT chk_total_orden_valido CHECK (total_orden >= 0)
) ENGINE=InnoDB;

-- 11. TABLA: Detalle de orden de compra
CREATE TABLE detalle_orden_compra (
    id_detalle INT AUTO_INCREMENT PRIMARY KEY,
    id_orden INT NOT NULL,
    id_producto INT NOT NULL,
    cantidad_solicitada INT NOT NULL,
    costo_unitario DECIMAL(10,2) NOT NULL,
    fecha_alta DATETIME DEFAULT CURRENT_TIMESTAMP,
    fecha_modificacion DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_detalle_orden
        FOREIGN KEY (id_orden) REFERENCES ordenes_compra(id_orden)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_detalle_producto
        FOREIGN KEY (id_producto) REFERENCES inventario_productos(id_producto)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT uq_orden_producto UNIQUE (id_orden, id_producto),
    CONSTRAINT chk_cantidad_solicitada CHECK (cantidad_solicitada > 0),
    CONSTRAINT chk_costo_unitario_detalle CHECK (costo_unitario >= 0)
) ENGINE=InnoDB;

-- 12. TABLA: Movimientos de inventario
CREATE TABLE movimientos_inventario (
    id_movimiento INT AUTO_INCREMENT PRIMARY KEY,
    id_producto INT NOT NULL,
    tipo_movimiento ENUM('Compra', 'Venta', 'Merma', 'Uso Interno') NOT NULL,
    cantidad INT NOT NULL,
    precio_unitario DECIMAL(10,2) NULL,
    id_usuario INT NOT NULL,
    id_orden INT NULL,
    observaciones VARCHAR(255) NULL,
    fecha_alta DATETIME DEFAULT CURRENT_TIMESTAMP,
    fecha_modificacion DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_movimientos_producto
        FOREIGN KEY (id_producto) REFERENCES inventario_productos(id_producto)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_movimientos_usuario
        FOREIGN KEY (id_usuario) REFERENCES usuarios_sistema(id_usuario)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_movimientos_orden
        FOREIGN KEY (id_orden) REFERENCES ordenes_compra(id_orden)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT chk_cantidad_movimiento_valida CHECK (cantidad > 0),
    CONSTRAINT chk_precio_unitario_movimiento CHECK (precio_unitario IS NULL OR precio_unitario >= 0),
    CONSTRAINT chk_precio_venta_obligatorio CHECK (tipo_movimiento <> 'Venta' OR precio_unitario IS NOT NULL),
    INDEX idx_movimientos_fecha_tipo (fecha_alta, tipo_movimiento)
) ENGINE=InnoDB;

-- 13. TABLA: Cortes de caja
CREATE TABLE cortes_caja (
    id_corte INT AUTO_INCREMENT PRIMARY KEY,
    fecha_corte DATE NOT NULL UNIQUE,
    total_ventas DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    total_piezas_vendidas INT NOT NULL DEFAULT 0,
    total_piezas_merma INT NOT NULL DEFAULT 0,
    total_piezas_uso_interno INT NOT NULL DEFAULT 0,
    estatus_corte ENUM('Pendiente', 'Revisado') NOT NULL DEFAULT 'Pendiente',
    id_usuario_revisa INT NULL,
    observaciones TEXT NULL,
    fecha_revision DATETIME NULL,
    fecha_alta DATETIME DEFAULT CURRENT_TIMESTAMP,
    fecha_modificacion DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_cortes_usuario_revisa
        FOREIGN KEY (id_usuario_revisa) REFERENCES usuarios_sistema(id_usuario)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT chk_cortes_totales_validos
        CHECK (total_ventas >= 0 AND total_piezas_vendidas >= 0 AND total_piezas_merma >= 0 AND total_piezas_uso_interno >= 0),
    CONSTRAINT chk_corte_revisado_fecha
        CHECK (estatus_corte <> 'Revisado' OR fecha_revision IS NOT NULL)
) ENGINE=InnoDB;

-- 14. TABLA: Horarios de empleado
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
    CONSTRAINT uq_empleado_dia UNIQUE (id_empleado, dia_semana),
    CONSTRAINT chk_horas_validas CHECK (hora_entrada < hora_salida)
) ENGINE=InnoDB;

-- 15. TABLA: Asistencias
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
    CONSTRAINT uq_empleado_fecha UNIQUE (id_empleado, fecha_asistencia),
    CONSTRAINT chk_horas_reales_validas
        CHECK (hora_entrada_real IS NULL OR hora_salida_real IS NULL OR hora_entrada_real < hora_salida_real)
) ENGINE=InnoDB;

-- 16. TABLA: Incidencias laborales
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

-- 17. TABLA: Reportes del gerente al administrador
CREATE TABLE reportes_gerente (
    id_reporte INT AUTO_INCREMENT PRIMARY KEY,
    id_usuario_gerente INT NOT NULL,
    categoria_reporte ENUM('Personal', 'Inventario', 'Compras', 'Ventas', 'Sistema', 'Otro') NOT NULL,
    asunto VARCHAR(120) NOT NULL,
    descripcion TEXT NOT NULL,
    estatus_reporte ENUM('Pendiente', 'Atendido') NOT NULL DEFAULT 'Pendiente',
    id_usuario_admin INT NULL,
    respuesta_admin TEXT NULL,
    fecha_atencion DATETIME NULL,
    fecha_alta DATETIME DEFAULT CURRENT_TIMESTAMP,
    fecha_modificacion DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_reportes_gerente
        FOREIGN KEY (id_usuario_gerente) REFERENCES usuarios_sistema(id_usuario)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_reportes_admin
        FOREIGN KEY (id_usuario_admin) REFERENCES usuarios_sistema(id_usuario)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT chk_atencion_completa
        CHECK (estatus_reporte = 'Pendiente' OR fecha_atencion IS NOT NULL)
) ENGINE=InnoDB;

-- 18. TABLA: Incidentes de tienda
CREATE TABLE incidentes_tienda (
    id_incidente_tienda INT AUTO_INCREMENT PRIMARY KEY,
    id_usuario_reporta INT NOT NULL,
    tipo_incidente ENUM('Stock', 'Situacion en Tienda') NOT NULL,
    id_producto INT NULL,
    descripcion TEXT NOT NULL,
    estatus_incidente ENUM('Pendiente', 'Revisado', 'Resuelto') NOT NULL DEFAULT 'Pendiente',
    id_usuario_revisa INT NULL,
    comentario_revision TEXT NULL,
    fecha_revision DATETIME NULL,
    fecha_alta DATETIME DEFAULT CURRENT_TIMESTAMP,
    fecha_modificacion DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_incidentes_usuario_reporta
        FOREIGN KEY (id_usuario_reporta) REFERENCES usuarios_sistema(id_usuario)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_incidentes_producto
        FOREIGN KEY (id_producto) REFERENCES inventario_productos(id_producto)
        ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT fk_incidentes_usuario_revisa
        FOREIGN KEY (id_usuario_revisa) REFERENCES usuarios_sistema(id_usuario)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT chk_revision_completa
        CHECK (estatus_incidente = 'Pendiente' OR fecha_revision IS NOT NULL)
) ENGINE=InnoDB;
