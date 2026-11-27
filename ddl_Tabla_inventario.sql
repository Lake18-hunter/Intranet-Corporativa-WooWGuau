USE woowguau_db;

-- 1. TABLA: Tipos de especie
CREATE TABLE tipos_especie (
    id_especie INT AUTO_INCREMENT PRIMARY KEY,
    nombre_especie VARCHAR(30) NOT NULL UNIQUE
) ENGINE=InnoDB;

-- 2. TABLA: Categorías de productos
CREATE TABLE categorias_producto (
    id_categoria INT AUTO_INCREMENT PRIMARY KEY,
    nombre_categoria VARCHAR(50) NOT NULL UNIQUE,
    descripcion_categoria VARCHAR(150)
) ENGINE=InnoDB;

-- 3. TABLA: Marcas comerciales
CREATE TABLE marcas_comerciales (
    id_marca INT AUTO_INCREMENT PRIMARY KEY,
    nombre_marca VARCHAR(50) NOT NULL UNIQUE
) ENGINE=InnoDB;

-- 4. TABLA: Inventario de productos
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
