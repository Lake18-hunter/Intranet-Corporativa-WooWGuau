from django.db import models


class TipoEspecie(models.Model):
    id_especie = models.AutoField(primary_key=True)
    nombre_especie = models.CharField(max_length=50, unique=True)

    class Meta:
        managed = False            # tablas creadas por BD; Django solo las consulta
        db_table = "tipos_especie"


class CategoriaProducto(models.Model):
    id_categoria = models.AutoField(primary_key=True)
    nombre_categoria = models.CharField(max_length=50, unique=True)

    class Meta:
        managed = False
        db_table = "categorias_producto"


class MarcaComercial(models.Model):
    id_marca = models.AutoField(primary_key=True)
    nombre_marca = models.CharField(max_length=50, unique=True)

    class Meta:
        managed = False
        db_table = "marcas_comerciales"


class Producto(models.Model):
    id_producto = models.AutoField(primary_key=True)
    codigo_sku = models.CharField(max_length=30, unique=True)
    nombre_producto = models.CharField(max_length=100)
    descripcion_producto = models.TextField(null=True, blank=True)
    precio_publico = models.DecimalField(max_digits=10, decimal_places=2)
    stock_actual = models.IntegerField(default=0)
    especie = models.ForeignKey(TipoEspecie, on_delete=models.PROTECT, db_column="id_especie")
    categoria = models.ForeignKey(CategoriaProducto, on_delete=models.PROTECT, db_column="id_categoria")
    marca = models.ForeignKey(MarcaComercial, on_delete=models.PROTECT, db_column="id_marca")
    estatus_producto = models.BooleanField(default=True)   # 1 activo, 0 descontinuado

    class Meta:
        managed = False
        db_table = "inventario_productos"