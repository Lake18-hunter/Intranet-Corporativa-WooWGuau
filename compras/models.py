from django.db import models


class Proveedor(models.Model):
    id_proveedor = models.AutoField(primary_key=True)
    nombre_proveedor = models.CharField(max_length=100)
    rfc = models.CharField(max_length=13, unique=True)
    nombre_contacto = models.CharField(max_length=100, null=True, blank=True)
    telefono = models.CharField(max_length=15, null=True, blank=True)
    correo = models.CharField(max_length=100, null=True, blank=True)
    direccion = models.CharField(max_length=200, null=True, blank=True)
    estatus_proveedor = models.IntegerField(default=1)   # 1 activo, 0 inactivo

    class Meta:
        managed = False
        db_table = "proveedores"

    def __str__(self):
        return self.nombre_proveedor


class OrdenCompra(models.Model):
    ESTATUS_BORRADOR = "Borrador"
    ESTATUS_ENVIADA = "Enviada"
    ESTATUS_RECIBIDA = "Recibida"
    ESTATUS_CANCELADA = "Cancelada"

    id_orden = models.AutoField(primary_key=True)
    folio_orden = models.CharField(max_length=25, unique=True)
    proveedor = models.ForeignKey(Proveedor, on_delete=models.DO_NOTHING,
                                  db_column="id_proveedor", related_name="ordenes")
    usuario_crea = models.ForeignKey("usuarios.UsuarioSistema", on_delete=models.DO_NOTHING,
                                     db_column="id_usuario_crea", related_name="ordenes_creadas")
    estatus_orden = models.CharField(max_length=9, default=ESTATUS_BORRADOR)
    total_orden = models.DecimalField(max_digits=12, decimal_places=2)
    observaciones = models.TextField(null=True, blank=True)
    fecha_recepcion = models.DateTimeField(null=True, blank=True)

    class Meta:
        managed = False
        db_table = "ordenes_compra"

    def __str__(self):
        return self.folio_orden


class DetalleOrdenCompra(models.Model):
    id_detalle = models.AutoField(primary_key=True)
    orden = models.ForeignKey(OrdenCompra, on_delete=models.DB_CASCADE,
                              db_column="id_orden", related_name="detalles")
    producto = models.ForeignKey("inventario.Producto", on_delete=models.DO_NOTHING,
                                 db_column="id_producto", related_name="detalles_orden")
    cantidad_solicitada = models.IntegerField()
    costo_unitario = models.DecimalField(max_digits=10, decimal_places=2)

    class Meta:
        managed = False
        db_table = "detalle_orden_compra"
        unique_together = (("orden", "producto"),)