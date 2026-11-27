USE woowguau_db;

-- 1. TABLA: Incidentes de tienda
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
        CHECK (estatus_incidente = 'Pendiente' OR (id_usuario_revisa IS NOT NULL AND fecha_revision IS NOT NULL))
) ENGINE=InnoDB;
