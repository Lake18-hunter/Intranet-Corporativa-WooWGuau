USE woowguau_db;

-- 1. TABLA: Proveedores
CREATE TABLE proveedores (
    id_proveedor INT AUTO_INCREMENT PRIMARY KEY,
    nombre_proveedor VARCHAR(100) NOT NULL,
    rfc VARCHAR(13) NOT NULL UNIQUE,
    nombre_contacto VARCHAR(100) NULL,
    telefono VARCHAR(15) NULL,
    correo VARCHAR(100) NULL,
    direccion VARCHAR(200) NULL,
    estatus_proveedor TINYINT(1) DEFAULT 1,
    fecha_alta DATETIME DEFAULT CURRENT_TIMESTAMP,
    fecha_modificacion DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT chk_rfc_valido
        CHECK (CHAR_LENGTH(rfc) IN (12, 13))
) ENGINE=InnoDB;

-- 2. TABLA: Ordenes de compra
CREATE TABLE ordenes_compra (
    id_orden INT AUTO_INCREMENT PRIMARY KEY,
    folio_orden VARCHAR(25) NOT NULL UNIQUE,
    id_proveedor INT NOT NULL,
    id_usuario_crea INT NOT NULL,
    estatus_orden ENUM('Borrador', 'Enviada', 'Recibida', 'Cancelada') DEFAULT 'Borrador',
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
    CONSTRAINT chk_total_orden_valido
        CHECK (total_orden >= 0)
) ENGINE=InnoDB;

-- 3. TABLA: Detalle de orden de compra
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
    CONSTRAINT uq_orden_producto
        UNIQUE (id_orden, id_producto),
    CONSTRAINT chk_cantidad_solicitada_valida
        CHECK (cantidad_solicitada > 0),
    CONSTRAINT chk_costo_unitario_valido
        CHECK (costo_unitario >= 0)
) ENGINE=InnoDB;
