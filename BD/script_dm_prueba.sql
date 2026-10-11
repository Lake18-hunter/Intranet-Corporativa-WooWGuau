USE woowguau_db;

-- 1. REGISTRO DE ROLES DEL SISTEMA
INSERT INTO roles_usuario (nombre_rol, descripcion_rol) VALUES
('Administrador', 'Control total del sistema y expediente de empleados'),
('Empleado', 'Consulta y actualización operativa del inventario');

-- 2. REGISTRO DE CATÁLOGOS BASE
INSERT INTO tipos_especie (nombre_especie) VALUES
('Perro'),
('Gato'),
('Otros');

INSERT INTO categorias_producto (nombre_categoria, descripcion_categoria) VALUES
('Alimento Seco', 'Croquetas y alimento balanceado en bulto'),
('Alimento Húmedo', 'Sobres, latas y premios jugosos'),
('Accesorios', 'Collares, correas, pecheras y platos'),
('Higiene y Limpieza', 'Arena para gato, pañales y champú');

INSERT INTO marcas_comerciales (nombre_marca) VALUES
('Minimo Adulto'),
('Pro Plan'),
('Nupec'),
('Fancy Pets');

-- 3. USUARIO Y EMPLEADO DE PRUEBA
INSERT INTO usuarios_sistema (nombre_usuario, correo, hash_contrasena, id_rol) VALUES
('yessica_gonzalez', 'yessica.ipn@gmail.com', 'g4t1t0s', 1);

INSERT INTO expediente_empleados (
    id_usuario, numero_empleado, nombre_empleado, apellido_paterno, apellido_materno, telefono_contacto, puesto_trabajo, fecha_ingreso
) VALUES (
    1, 'EMP001', 'Yessica', 'Gonzalez', 'Garcia', '5551234567', 'Gerente', '2026-01-15'
);

-- 4. PRODUCTOS DE PRUEBA PARA INVENTARIO
INSERT INTO inventario_productos (
    codigo_sku, nombre_producto, precio_publico, stock_actual, id_especie, id_categoria, id_marca
) VALUES
('ALM-PER-001', 'Nupec Adulto Raza Mediana 15kg', 1250.00, 20, 1, 1, 3),
('ALM-GAT-001', 'Minimo Adulto 1.5kg', 480.00, 15, 2, 1, 1),
('ACC-MUL-001', 'Plato Doble Antideslizante', 120.00, 30, 3, 3, 4);
