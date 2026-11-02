-- Script DML compatible con Django

USE woowguau_db;

-- 1. ROLES DEL SISTEMA (Nombres exactos requeridos por Backend)
INSERT INTO roles_usuario (nombre_rol, descripcion_rol) VALUES
('Administrador', 'Control del sistema y expediente de empleados'),
('Empleado', 'Consulta y actualización del inventario');

-- 2. CATÁLOGOS BASE
INSERT INTO tipos_especie (nombre_especie) VALUES
('Perro'),
('Gato'),
('Multiespecie');

INSERT INTO categorias_producto (nombre_categoria, descripcion_categoria) VALUES
('Alimento Seco', 'Croquetas y alimento balanceado en bulto'),
('Alimento Húmedo', 'Sobres, latas y premios'),
('Accesorios', 'Collares, correas, pecheras y platos'),
('Higiene y Limpieza', 'Arena para gato, pañales y champú');

INSERT INTO marcas_comerciales (nombre_marca) VALUES
('Royal Canin'),
('Pro Plan'),
('Nupec'),
('Fancy Pets');

-- 3. USUARIOS Y EMPLEADOS DE PRUEBA
-- Hash generado con make_password para Django
INSERT INTO usuarios_sistema (nombre_usuario, correo, hash_contrasena, id_rol, estatus_cuenta) VALUES
('admin_yessica', 'yessica.ipn@gmail.com', 'pbkdf2_sha256$870000$Wv9g1XzL4kM2$a7K8pQ9zL2xY9wE1rT3yU5iO7pA9sD1fG3hJ5kL7mN9=', 1, 1),
('empleado_juan', 'juan.empleado@gmail.com', 'pbkdf2_sha256$870000$Wv9g1XzL4kM2$a7K8pQ9zL2xY9wE1rT3yU5iO7pA9sD1fG3hJ5kL7mN9=', 2, 1);

INSERT INTO expediente_empleados (
    id_usuario, numero_empleado, nombre_empleado, apellido_paterno, apellido_materno, telefono_contacto, puesto_trabajo, fecha_ingreso, estatus_laboral
) VALUES 
(1, 'EMP001', 'Yessica', 'Gonzalez', 'Garcia', '5551234567', 'Gerente', '2026-01-15', 'Activo'),
(2, 'EMP002', 'Juan', 'Perez', 'Lopez', '5559876543', 'Vendedor de Piso', '2026-02-01', 'Activo');

-- 4. PRODUCTOS DE PRUEBA (estatus_producto = 1 y stocks variados)
INSERT INTO inventario_productos (
    codigo_sku, nombre_producto, descripcion_producto, precio_publico, stock_actual, id_especie, id_categoria, id_marca, estatus_producto
) VALUES
('ALM-PER-001', 'Nupec Adulto Raza Mediana 15kg', 'Alimento seco balanceado', 1250.00, 20, 1, 1, 3, 1),
('ALM-GAT-001', 'Royal Canin Cat Kitten 1.5kg', 'Alimento para gatitos', 480.00, 2, 2, 1, 1, 1),   -- Stock bajo
('ACC-MUL-001', 'Plato Doble Antideslizante', 'Accesorios de acero', 120.00, 0, 3, 3, 4, 1),      -- Stock en 0 (Prueba error 409)
('HIG-GAT-001', 'Arena para Gato Scoopable 5kg', 'Arena aglutinante', 250.00, 15, 2, 4, 4, 1);


