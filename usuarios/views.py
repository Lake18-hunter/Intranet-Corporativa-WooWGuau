from django.http import HttpResponse
from django.shortcuts import render, redirect
from django.utils import timezone
from django.views.decorators.http import require_http_methods

from .models import UsuarioSistema

# Ajusta estos nombres si BD usó otros en la tabla roles_usuario (se compara en minúsculas)
ROLES_ADMIN = {"administrador", "admin"}
ROLES_EMPLEADO = {"empleado"}


def _tipo_de_rol(nombre_rol):
    nombre = nombre_rol.strip().lower()
    if nombre in ROLES_ADMIN:
        return "admin"
    if nombre in ROLES_EMPLEADO:
        return "empleado"
    return None


@require_http_methods(["GET", "POST"])
def login_view(request):
    if request.method == "GET":
        return render(request, "usuarios/index.html")

    correo = request.POST.get("correo", "").strip()
    contrasena = request.POST.get("contrasena", "")

    if not correo or not contrasena:
        return render(request, "usuarios/index.html",
                      {"error": "Escribe tu correo y tu contraseña."}, status=400)

    try:
        user = UsuarioSistema.objects.select_related("rol").get(correo__iexact=correo)
    except UsuarioSistema.DoesNotExist:
        user = None

    if user is None or not user.verificar_contrasena(contrasena):
        return render(request, "usuarios/index.html",
                      {"error": "Correo o contraseña incorrectos."}, status=401)
    # 4. Cuenta activa
    if not user.estatus_cuenta:
        return render(request, "usuarios/index.html",
                      {"error": "Tu cuenta está inactiva. Contacta al administrador."},
                      status=403)

    # 5. Rol válido
    tipo = _tipo_de_rol(user.rol.nombre_rol)
    if tipo is None:
        return render(request, "usuarios/index.html",
                      {"error": "Tu cuenta no tiene un rol válido. Contacta al administrador."},
                      status=403)

    # 6. Registrar el acceso (esto también actualiza fecha_modificacion por el ON UPDATE de MySQL)
    UsuarioSistema.objects.filter(pk=user.pk).update(fecha_ultimo_acceso=timezone.now())

    # 7. Iniciar sesión con los datos mínimos
    request.session.cycle_key()
    request.session["usuario_id"] = user.pk
    request.session["nombre_usuario"] = user.nombre_usuario
    request.session["rol"] = tipo   # "admin" o "empleado"

    # 8. Redirigir según el rol
    return redirect("panel_admin" if tipo == "admin" else "panel_empleado")


def logout_view(request):
    request.session.flush()
    return redirect("login")


# Vistas provisionales: la siguiente tarea (enrutamiento restrictivo) las reemplaza
def panel_admin(request):
    return HttpResponse("Panel de administrador (provisional)")


def panel_empleado(request):
    return HttpResponse("Panel de empleado (provisional)")