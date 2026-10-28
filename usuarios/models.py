from django.db import models
from django.contrib.auth.hashers import check_password


class Rol(models.Model):
    id_rol = models.AutoField(primary_key=True)
    nombre_rol = models.CharField(max_length=30, unique=True)
    descripcion_rol = models.CharField(max_length=150, null=True, blank=True)

    class Meta:
        managed = False            # la tabla la creó BD; Django solo la consulta
        db_table = "roles_usuario"

    def __str__(self):
        return self.nombre_rol


class UsuarioSistema(models.Model):
    id_usuario = models.AutoField(primary_key=True)
    nombre_usuario = models.CharField(max_length=50, unique=True)
    correo = models.CharField(max_length=100, unique=True)
    hash_contrasena = models.CharField(max_length=255)
    rol = models.ForeignKey(Rol, on_delete=models.PROTECT, db_column="id_rol")
    estatus_cuenta = models.BooleanField(default=True)
    fecha_ultimo_acceso = models.DateTimeField(null=True, blank=True)

    class Meta:
        managed = False
        db_table = "usuarios_sistema"

    def verificar_contrasena(self, contrasena_plana):
        return check_password(contrasena_plana, self.hash_contrasena)

    def __str__(self):
        return f"{self.nombre_usuario} ({self.rol.nombre_rol})"


class Empleado(models.Model):
    id_empleado = models.AutoField(primary_key=True)
    usuario = models.OneToOneField(UsuarioSistema, null=True, blank=True,
                                   on_delete=models.SET_NULL, db_column="id_usuario")
    numero_empleado = models.CharField(max_length=15, unique=True)
    nombre_empleado = models.CharField(max_length=50)
    apellido_paterno = models.CharField(max_length=50)
    apellido_materno = models.CharField(max_length=50, null=True, blank=True)
    telefono_contacto = models.CharField(max_length=15, null=True, blank=True)
    puesto_trabajo = models.CharField(max_length=50)
    fecha_ingreso = models.DateField()
    estatus_laboral = models.CharField(max_length=20, default="Activo")

    class Meta:
        managed = False
        db_table = "expediente_empleados"