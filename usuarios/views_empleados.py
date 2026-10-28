from django.db import IntegrityError, transaction
from django.http import JsonResponse
from django.views.decorators.http import require_GET, require_POST

from .decorators import rol_requerido
from .models import Empleado, UsuarioSistema
from .validators import validar_empleado


def _a_dict(e):
    return {
        "id_empleado": e.pk,
        "numero_empleado": e.numero_empleado,
        "nombre_empleado": e.nombre_empleado,
        "apellido_paterno": e.apellido_paterno,
        "apellido_materno": e.apellido_materno or "",
        "telefono_contacto": e.telefono_contacto or "",
        "puesto_trabajo": e.puesto_trabajo,
        "fecha_ingreso": e.fecha_ingreso.isoformat(),
        "estatus_laboral": e.estatus_laboral,
    }


def _buscar(id_empleado):
    try:
        return Empleado.objects.get(pk=id_empleado)
    except Empleado.DoesNotExist:
        return None


def _no_encontrado():
    return JsonResponse({"error": "Empleado no encontrado."}, status=404)


@rol_requerido("admin")
@require_GET
def empleados_lista(request):
    """Lista empleados. Por defecto oculta las bajas; con ?bajas=1 las incluye."""
    qs = Empleado.objects.all().order_by("apellido_paterno", "nombre_empleado")
    if request.GET.get("bajas") != "1":
        qs = qs.exclude(estatus_laboral="Baja Logica")
    return JsonResponse({"empleados": [_a_dict(e) for e in qs]})


@rol_requerido("admin")
@require_GET
def empleado_detalle(request, id_empleado):
    """Devuelve un empleado (sirve para llenar el modal de edición)."""
    e = _buscar(id_empleado)
    if e is None:
        return _no_encontrado()
    return JsonResponse({"empleado": _a_dict(e)})


@rol_requerido("admin")
@require_POST
def empleado_crear(request):
    datos, errores = validar_empleado(request.POST)
    if errores:
        return JsonResponse({"errores": errores}, status=400)
    if Empleado.objects.filter(numero_empleado=datos["numero_empleado"]).exists():
        return JsonResponse(
            {"errores": {"numero_empleado": "Ya existe un empleado con ese número."}},
            status=409)
    try:
        e = Empleado.objects.create(**datos)
    except IntegrityError:
        return JsonResponse({"error": "No se pudo guardar el empleado."}, status=409)
    return JsonResponse({"empleado": _a_dict(e)}, status=201)


@rol_requerido("admin")
@require_POST
def empleado_editar(request, id_empleado):
    e = _buscar(id_empleado)
    if e is None:
        return _no_encontrado()
    datos, errores = validar_empleado(request.POST)
    if errores:
        return JsonResponse({"errores": errores}, status=400)
    if (Empleado.objects.filter(numero_empleado=datos["numero_empleado"])
            .exclude(pk=e.pk).exists()):
        return JsonResponse(
            {"errores": {"numero_empleado": "Ya existe un empleado con ese número."}},
            status=409)
    for campo, valor in datos.items():
        setattr(e, campo, valor)
    try:
        e.save()
    except IntegrityError:
        return JsonResponse({"error": "No se pudo actualizar el empleado."}, status=409)
    return JsonResponse({"empleado": _a_dict(e)})


@rol_requerido("admin")
@require_POST
def empleado_baja(request, id_empleado):
    """Baja lógica: marca al empleado y, si tiene cuenta de acceso, la desactiva."""
    e = _buscar(id_empleado)
    if e is None:
        return _no_encontrado()
    with transaction.atomic():
        e.estatus_laboral = "Baja Logica"
        e.save(update_fields=["estatus_laboral"])
        