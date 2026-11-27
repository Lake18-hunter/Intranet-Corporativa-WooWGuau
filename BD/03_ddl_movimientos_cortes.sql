USE woowguau_db;

-- costo_unitario, stock_minimo y fecha_caducidad a inventario_productos
ALTER TABLE inventario_productos
    ADD COLUMN costo_unitario DECIMAL(10,2) NOT NULL DEFAULT 0.00 AFTER precio_publico,
    ADD COLUMN stock_minimo INT NOT NULL DEFAULT 5 AFTER stock_actual,
    ADD COLUMN fecha_caducidad DATE NULL AFTER stock_minimo,
    ADD CONSTRAINT chk_costo_unitario_producto CHECK (costo_unitario >= 0),
    ADD CONSTRAINT chk_stock_minimo_producto CHECK (stock_minimo >= 0);

--  Movimientos de inventario
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
    CONSTRAINT chk_cantidad_movimiento_valida
        CHECK (cantidad > 0),
    CONSTRAINT chk_precio_unitario_movimiento
        CHECK (precio_unitario IS NULL OR precio_unitario >= 0),
    CONSTRAINT chk_precio_venta_obligatorio
        CHECK (tipo_movimiento <> 'Venta' OR precio_unitario IS NOT NULL),
    INDEX idx_movimientos_fecha_tipo (fecha_alta, tipo_movimiento)
) ENGINE=InnoDB;

-- Cortes de caja
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
