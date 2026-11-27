USE woowguau_db;

-- 1. ROLES DE USUARIO (3 roles)
INSERT IGNORE INTO roles_usuario (nombre_rol, descripcion_rol) VALUES
('Administrador', 'Control total del sistema, usuarios, expedientes y reportes'),
('Gerente', 'Gestion de compras, proveedores, personal, cortes de caja e incidentes'),
('Empleado', 'Consulta de inventario, registro de salidas e incidentes en tienda');

-- 2. USUARIOS DEL SISTEMA (1 por cada rol; contrasena de prueba: 'WooWGuau2026*')
INSERT IGNORE INTO usuarios_sistema (nombre_usuario, correo, hash_contrasena, id_rol, estatus_cuenta) VALUES
('admin.woow', 'admin@woowguau.mx', 'pbkdf2_sha256$600000$woowguau$9f86d081884c7d659a2feaa0c55ad015a3bf4f1b2b0b822cd15d6c15b0f00a08',
    (SELECT id_rol FROM roles_usuario WHERE nombre_rol = 'Administrador'), 1),
('gerente.pau', 'gerente@woowguau.mx', 'pbkdf2_sha256$600000$woowguau$9f86d081884c7d659a2feaa0c55ad015a3bf4f1b2b0b822cd15d6c15b0f00a08',
    (SELECT id_rol FROM roles_usuario WHERE nombre_rol = 'Gerente'), 1),
('empleado.luis', 'empleado@woowguau.mx', 'pbkdf2_sha256$600000$woowguau$9f86d081884c7d659a2feaa0c55ad015a3bf4f1b2b0b822cd15d6c15b0f00a08',
    (SELECT id_rol FROM roles_usuario WHERE nombre_rol = 'Empleado'), 1);

-- 3. EXPEDIENTE DE EMPLEADOS (3 con cuenta activa y 1 pendiente de crear usuario)
INSERT IGNORE INTO expediente_empleados (id_usuario, numero_empleado, nombre_empleado, apellido_paterno, apellido_materno, telefono_contacto, puesto_trabajo, fecha_ingreso, estatus_laboral) VALUES
((SELECT id_usuario FROM usuarios_sistema WHERE nombre_usuario = 'admin.woow'), 'EMP-001', 'Carlos', 'Mendoza', 'Ruiz', '5512345601', 'Administrador General', '2025-01-15', 'Activo'),
((SELECT id_usuario FROM usuarios_sistema WHERE nombre_usuario = 'gerente.pau'), 'EMP-002', 'Paulina', 'Gonzalez', 'Garcia', '5512345602', 'Gerente de Tienda', '2025-03-01', 'Activo'),
((SELECT id_usuario FROM usuarios_sistema WHERE nombre_usuario = 'empleado.luis'), 'EMP-003', 'Luis', 'Hernandez', 'Soto', '5512345603', 'Asesor de Piso y Caja', '2025-06-10', 'Activo'),
(NULL, 'EMP-004', 'Valeria', 'Torres', 'Vega', '5512345604', 'Auxiliar de Almacen', '2026-11-15', 'Activo');

-- 4. CATALOGOS BASE: Tipos de especie, categorias y marcas
INSERT IGNORE INTO tipos_especie (nombre_especie) VALUES
('Perro'),
('Gato'),
('Multiespecie');

INSERT IGNORE INTO categorias_producto (nombre_categoria, descripcion_categoria) VALUES
('Alimento Seco', 'Croquetas y alimento balanceado por etapa y tamano'),
('Alimento Humedo', 'Sobres, latas y alimento en salsa'),
('Accesorios', 'Collares, correas, platos y juguetes'),
('Higiene y Limpieza', 'Arenas sanitarias, shampoo y tapetes entrenadores');

INSERT IGNORE INTO marcas_comerciales (nombre_marca) VALUES
('Royal Canin'),
('Nupec'),
('Whiskas'),
('Kong');

-- 5. INVENTARIO DE PRODUCTOS (con costo_unitario, stock_minimo y fecha_caducidad)
INSERT IGNORE INTO inventario_productos (codigo_sku, nombre_producto, descripcion_producto, precio_publico, costo_unitario, stock_actual, stock_minimo, fecha_caducidad, id_especie, id_categoria, id_marca, estatus_producto) VALUES
('WG-PER-001', 'Croquetas Nupec Adulto 8kg', 'Alimento seco para perro adulto raza mediana y grande', 980.00, 720.00, 18, 5, '2027-06-15',
    (SELECT id_especie FROM tipos_especie WHERE nombre_especie = 'Perro'),
    (SELECT id_categoria FROM categorias_producto WHERE nombre_categoria = 'Alimento Seco'),
    (SELECT id_marca FROM marcas_comerciales WHERE nombre_marca = 'Nupec'), 1),
('WG-GAT-002', 'Sobre Whiskas Salmon 85g', 'Alimento humedo sabor salmon para gato adulto', 18.00, 11.50, 45, 15, '2026-12-10',
    (SELECT id_especie FROM tipos_especie WHERE nombre_especie = 'Gato'),
    (SELECT id_categoria FROM categorias_producto WHERE nombre_categoria = 'Alimento Humedo'),
    (SELECT id_marca FROM marcas_comerciales WHERE nombre_marca = 'Whiskas'), 1),
('WG-PER-003', 'Juguete Kong Classic Mediano', 'Juguete dispensador de premios de caucho resistente', 340.00, 210.00, 4, 6, NULL,
    (SELECT id_especie FROM tipos_especie WHERE nombre_especie = 'Perro'),
    (SELECT id_categoria FROM categorias_producto WHERE nombre_categoria = 'Accesorios'),
    (SELECT id_marca FROM marcas_comerciales WHERE nombre_marca = 'Kong'), 1),
('WG-GAT-004', 'Royal Canin Indoor Cat 3kg', 'Alimento seco para gato de interior', 790.00, 580.00, 9, 4, '2027-03-20',
    (SELECT id_especie FROM tipos_especie WHERE nombre_especie = 'Gato'),
    (SELECT id_categoria FROM categorias_producto WHERE nombre_categoria = 'Alimento Seco'),
    (SELECT id_marca FROM marcas_comerciales WHERE nombre_marca = 'Royal Canin'), 1);

-- 6. PROVEEDORES
INSERT IGNORE INTO proveedores (nombre_proveedor, rfc, nombre_contacto, telefono, correo, direccion, estatus_proveedor) VALUES
('Distribuidora PetNutricion SA de CV', 'DPN180412AB3', 'Roberto Silva', '5544332211', 'ventas@petnutricion.mx', 'Av. Industrial 450, Tlalnepantla, Edo. Mex.', 1),
('Comercializadora Mascota Feliz SA de CV', 'CMF200905XY9', 'Mariana Ortiz', '5599887766', 'pedidos@mascotafeliz.mx', 'Calz. Vallejo 1020, Azcapotzalco, CDMX', 1);

-- 7. ORDENES DE COMPRA (1 Recibida y 1 Enviada)
INSERT IGNORE INTO ordenes_compra (folio_orden, id_proveedor, id_usuario_crea, estatus_orden, total_orden, observaciones, fecha_recepcion) VALUES
('OC-2026-0001',
    (SELECT id_proveedor FROM proveedores WHERE rfc = 'DPN180412AB3'),
    (SELECT id_usuario FROM usuarios_sistema WHERE nombre_usuario = 'gerente.pau'),
    'Recibida', 7775.00, 'Resurtido quincenal de alimento seco y humedo', '2026-11-20 11:30:00'),
('OC-2026-0002',
    (SELECT id_proveedor FROM proveedores WHERE rfc = 'CMF200905XY9'),
    (SELECT id_usuario FROM usuarios_sistema WHERE nombre_usuario = 'gerente.pau'),
    'Enviada', 2100.00, 'Reposicion urgente de juguetes Kong por stock bajo', NULL);

-- 8. DETALLE DE ORDEN DE COMPRA
INSERT IGNORE INTO detalle_orden_compra (id_orden, id_producto, cantidad_solicitada, costo_unitario) VALUES
((SELECT id_orden FROM ordenes_compra WHERE folio_orden = 'OC-2026-0001'),
    (SELECT id_producto FROM inventario_productos WHERE codigo_sku = 'WG-PER-001'), 10, 720.00),
((SELECT id_orden FROM ordenes_compra WHERE folio_orden = 'OC-2026-0001'),
    (SELECT id_producto FROM inventario_productos WHERE codigo_sku = 'WG-GAT-002'), 50, 11.50),
((SELECT id_orden FROM ordenes_compra WHERE folio_orden = 'OC-2026-0002'),
    (SELECT id_producto FROM inventario_productos WHERE codigo_sku = 'WG-PER-003'), 10, 210.00);

-- 9. MOVIMIENTOS DE INVENTARIO (Compra, Venta, Merma y Uso Interno)
INSERT INTO movimientos_inventario (id_producto, tipo_movimiento, cantidad, precio_unitario, id_usuario, id_orden, observaciones) VALUES
((SELECT id_producto FROM inventario_productos WHERE codigo_sku = 'WG-PER-001'), 'Compra', 10, 720.00,
    (SELECT id_usuario FROM usuarios_sistema WHERE nombre_usuario = 'gerente.pau'),
    (SELECT id_orden FROM ordenes_compra WHERE folio_orden = 'OC-2026-0001'), 'Entrada por recepcion de OC-2026-0001'),
((SELECT id_producto FROM inventario_productos WHERE codigo_sku = 'WG-PER-001'), 'Venta', 2, 980.00,
    (SELECT id_usuario FROM usuarios_sistema WHERE nombre_usuario = 'empleado.luis'), NULL, 'Venta en mostrador'),
((SELECT id_producto FROM inventario_productos WHERE codigo_sku = 'WG-GAT-002'), 'Venta', 5, 18.00,
    (SELECT id_usuario FROM usuarios_sistema WHERE nombre_usuario = 'empleado.luis'), NULL, 'Venta en mostrador'),
((SELECT id_producto FROM inventario_productos WHERE codigo_sku = 'WG-GAT-002'), 'Merma', 1, NULL,
    (SELECT id_usuario FROM usuarios_sistema WHERE nombre_usuario = 'empleado.luis'), NULL, 'Sobre perforado en anaquel'),
((SELECT id_producto FROM inventario_productos WHERE codigo_sku = 'WG-PER-003'), 'Uso Interno', 1, NULL,
    (SELECT id_usuario FROM usuarios_sistema WHERE nombre_usuario = 'gerente.pau'), NULL, 'Muestra fisica en exhibidor');

-- 10. CORTES DE CAJA (1 revisado y 1 pendiente)
INSERT IGNORE INTO cortes_caja (fecha_corte, total_ventas, total_piezas_vendidas, total_piezas_merma, total_piezas_uso_interno, estatus_corte, id_usuario_revisa, observaciones, fecha_revision) VALUES
('2026-11-25', 2940.00, 4, 0, 0, 'Revisado',
    (SELECT id_usuario FROM usuarios_sistema WHERE nombre_usuario = 'gerente.pau'), 'Corte cuadrado sin diferencias', '2026-11-25 20:15:00'),
('2026-11-26', 2050.00, 7, 1, 1, 'Pendiente', NULL, NULL, NULL);

-- 11. HORARIOS DE EMPLEADO
INSERT IGNORE INTO horarios_empleado (id_empleado, dia_semana, hora_entrada, hora_salida) VALUES
((SELECT id_empleado FROM expediente_empleados WHERE numero_empleado = 'EMP-002'), 'Lunes', '09:00:00', '17:00:00'),
((SELECT id_empleado FROM expediente_empleados WHERE numero_empleado = 'EMP-002'), 'Martes', '09:00:00', '17:00:00'),
((SELECT id_empleado FROM expediente_empleados WHERE numero_empleado = 'EMP-003'), 'Lunes', '10:00:00', '18:00:00'),
((SELECT id_empleado FROM expediente_empleados WHERE numero_empleado = 'EMP-003'), 'Martes', '10:00:00', '18:00:00');

-- 12. ASISTENCIAS
INSERT IGNORE INTO asistencias (id_empleado, fecha_asistencia, hora_entrada_real, hora_salida_real, estatus_asistencia, observaciones) VALUES
((SELECT id_empleado FROM expediente_empleados WHERE numero_empleado = 'EMP-002'), '2026-11-26', '08:55:00', '17:05:00', 'Asistio', NULL),
((SELECT id_empleado FROM expediente_empleados WHERE numero_empleado = 'EMP-003'), '2026-11-26', '10:18:00', '18:00:00', 'Retardo', 'Retraso por transporte publico');

-- 13. INCIDENCIAS LABORALES
INSERT INTO incidencias_laborales (id_empleado, id_usuario_registra, tipo_incidencia, fecha_incidencia, descripcion, estatus_incidencia) VALUES
((SELECT id_empleado FROM expediente_empleados WHERE numero_empleado = 'EMP-003'),
    (SELECT id_usuario FROM usuarios_sistema WHERE nombre_usuario = 'gerente.pau'),
    'Conducta', '2026-11-26', 'Acumulacion de segundo retardo en la semana; se realiza llamada de atencion verbal.', 'Cerrada');

-- 14. REPORTES DEL GERENTE AL ADMINISTRADOR
INSERT INTO reportes_gerente (id_usuario_gerente, categoria_reporte, asunto, descripcion, estatus_reporte, id_usuario_admin, respuesta_admin, fecha_atencion) VALUES
((SELECT id_usuario FROM usuarios_sistema WHERE nombre_usuario = 'gerente.pau'),
    'Personal', 'Solicitud de cuenta para nuevo auxiliar',
    'Se dio de alta el expediente EMP-004 de Valeria Torres. Favor de generar su usuario con rol Empleado.',
    'Pendiente', NULL, NULL, NULL),
((SELECT id_usuario FROM usuarios_sistema WHERE nombre_usuario = 'gerente.pau'),
    'Sistema', 'Ajuste en permisos de vista de compras',
    'Confirmacion de acceso correcto al modulo de ordenes de compra.',
    'Atendido',
    (SELECT id_usuario FROM usuarios_sistema WHERE nombre_usuario = 'admin.woow'),
    'Permisos verificados y activos en produccion.', '2026-11-24 16:00:00');

-- 15. INCIDENTES DE TIENDA
INSERT INTO incidentes_tienda (id_usuario_reporta, tipo_incidente, id_producto, descripcion, estatus_incidente, id_usuario_revisa, comentario_revision, fecha_revision) VALUES
((SELECT id_usuario FROM usuarios_sistema WHERE nombre_usuario = 'empleado.luis'),
    'Stock',
    (SELECT id_producto FROM inventario_productos WHERE codigo_sku = 'WG-PER-003'),
    'Quedan solo 4 piezas de Kong Classic Mediano en anaquel, esta por debajo del minimo.',
    'Revisado',
    (SELECT id_usuario FROM usuarios_sistema WHERE nombre_usuario = 'gerente.pau'),
    'Ya se genero la orden de compra OC-2026-0002 con el proveedor.', '2026-11-26 13:20:00'),
((SELECT id_usuario FROM usuarios_sistema WHERE nombre_usuario = 'empleado.luis'),
    'Situacion en Tienda', NULL,
    'Falla intermitente en el lector de codigo de barras de la caja principal.',
    'Pendiente', NULL, NULL, NULL);
