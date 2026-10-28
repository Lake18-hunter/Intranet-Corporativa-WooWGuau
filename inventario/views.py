import logging

from django.db import IntegrityError
from django.db.models import F, Q
from django.http import JsonResponse
from django.views.decorators.http import require_GET, require_POST

from usuarios.decorators import rol_requerido
from .models import CategoriaProducto, MarcaComercial, Producto, TipoEspecie
from .validators import validar_operacion

logger = logging.getLogger(__name__)


def _a_dict(p):
    return {
        "id_producto": p.pk,
        "codigo_sku": p.codigo_sku,
        "nombre_producto": p.nombre_producto,
        "descripcion_producto": p.descripcion_producto or "",
        "precio_publico": str(p.precio_publico),
        "stock_actual": p.stock_actual,
        "especie": p.especie.nombre_especie,
        "categoria": p.categoria.nombre_categoria,
        "marca": p.marca.nombre_marca,
    }


def _productos():
    return Producto.objects.select_related("especie", "categoria", "marca")


@rol_requerido("empleado")
@require_GET
def productos_lista(request):
    """Lista productos activos. Filtros opcionales: ?especie=, ?categoria=, ?q="""
    qs = _productos().filter(estatus_producto=True)
    especie = request.GET.get("especie", "").strip()[:50]
    categoria = request.GET.get("categoria", "").strip()[:50]
    q = request.GET.get("q", "").strip()[:100]
    if especie:
        qs = qs.filter(especie__nombre_especie__iexact=especie)
    if categoria:
        qs = qs.filter(categoria__nombre_categoria__iexact=categoria)
    if q:
        qs = qs.filter(Q(nombre_producto__icontains=q) | Q(codigo_sku__icontains=q)
                       | Q(marca__nombre_marca__icontains=q))
    qs = qs.order_by("categoria__nombre_categoria", "nombre_producto")
    return JsonResponse({"productos": [_a_dict(p) for p in qs]})


@rol_requerido("empleado")
@require_GET
def catalogos(request):
    """Especies, categorías y marcas, para construir los filtros del panel."""
    return JsonResponse({
        "especies": [{"id": e.pk, "nombre": e.nombre_especie}
                     for e in TipoEspecie.objects.order_by("nombre_especie")],
        "categorias": [{"id": c.pk, "nombre": c.nombre_categoria}
                       for c in CategoriaProducto.objects.order_by("nombre_categoria")],
        "marcas": [{"id": m.pk, "nombre": m.nombre_marca}
                   for m in MarcaComercial.objects.order_by("nombre_marca")],
    })


@rol_requerido("empleado")
@require_POST
def producto_stock(request, id_producto):
    """Suma o resta stock. Recibe: operacion ('sumar'|'restar') y cantidad (opcional, 1 por defecto)."""
    datos, errores = validar_operacion(request.POST)
    if errores:
        return JsonResponse({"errores": errores}, status=400)
    operacion, cantidad = datos["operacion"], datos["cantidad"]

    activos = Producto.objects.filter(pk=id_producto, estatus_producto=True)
    try:
        # UPDATE atómico: la resta solo se aplica si alcanza el stock, y dos empleados
        # actuando a la vez no pisan el cambio del otro (sin leer y luego escribir).
        if operacion == "sumar":
            filas = activos.update(stock_actual=F("stock_actual") + cantidad)
        else:
            filas = (activos.filter(stock_actual__gte=cantidad)
                     .update(stock_actual=F("stock_actual") - cantidad))
    except IntegrityError:   # red de seguridad: el CHECK (stock_actual >= 0) de la BD
        return JsonResponse(
            {"error": "La base de datos rechazó la operación (stock no válido)."}, status=409)

    if filas == 0:   # no se aplicó: averiguar por qué
        try:
            p = Producto.objects.get(pk=id_producto)
        except Producto.DoesNotExist:
            return JsonResponse({"error": "Producto no encontrado."}, status=404)
        if not p.estatus_producto:
            return JsonResponse({"error": "El producto está descontinuado."}, status=409)
        return JsonResponse(
            {"error": f"Stock insuficiente. Disponible: {p.stock_actual}."}, status=409)

    p = _productos().get(pk=id_producto)
    logger.info("Stock %s: producto=%s cantidad=%s usuario=%s nuevo_stock=%s",
                operacion, id_producto, cantidad, request.session.get("usuario_id"), p.stock_actual)
    return JsonResponse({"mensaje": "Stock actualizado.", "producto": _a_dict(p)})