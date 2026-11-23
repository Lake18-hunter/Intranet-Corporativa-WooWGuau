SET NAMES utf8mb4;
USE woowguau_db;

-- Asegurar que los roles originales existan como deben ser
INSERT IGNORE INTO roles_usuario (nombre_rol, descripcion_rol) VALUES
('Administrador', 'Control del sistema, cuentas de usuario, expedientes y atencion de reportes'),
('Empleado',      'Consulta de inventario, salidas de mercancia e incidentes de tienda');

-- Insertar el nuevo rol Gerente
INSERT IGNORE INTO roles_usuario (nombre_rol, descripcion_rol) VALUES
('Gerente',       'Compras, proveedores, personal, cortes de caja y reportes');

-- Consulta de verificación (debe devolver exactamente 3 filas)
SELECT id_rol, nombre_rol, descripcion_rol FROM roles_usuario ORDER BY id_rol;
