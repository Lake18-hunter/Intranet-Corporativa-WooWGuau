import re

OPERACIONES = ("sumar", "restar")
CANTIDAD_MAX = 1000


def validar_operacion(datos):
    """Recibe request.POST. Devuelve (datos_limpios, errores)."""
    limpio, errores = {}, {}

    operacion = str(datos.get("operacion", "")).strip().lower()
    if operacion not in OPERACIONES:
        errores["operacion"] = "La operación debe ser 'sumar' o 'restar'."
    else:
        limpio["operacion"] = operacion

    cantidad_txt = str(datos.get("cantidad", "")).strip() or "1"   # si no viene, 1
    if not re.fullmatch(r"[0-9]{1,4}", cantidad_txt):
        errores["cantidad"] = "La cantidad debe ser un número entero positivo."
    else:
        cantidad = int(cantidad_txt)
        if cantidad < 1 or cantidad > CANTIDAD_MAX:
            errores["cantidad"] = f"La cantidad debe estar entre 1 y {CANTIDAD_MAX}."
        else:
            limpio["cantidad"] = cantidad

    return limpio, errores