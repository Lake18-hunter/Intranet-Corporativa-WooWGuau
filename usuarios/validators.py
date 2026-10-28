import re
from datetime import date, datetime

ESTATUS_VALIDOS = ("Activo", "Inactivo", "Baja Logica")
FECHA_MINIMA = date(1990, 1, 1)

_L = "A-Za-zÁÉÍÓÚÜÑáéíóúüñ"
RE_NOMBRE = re.compile(rf"^[{_L}][{_L} .'-]*$")
RE_PUESTO = re.compile(rf"^[{_L}0-9][{_L}0-9 .,/&()-]*$")
RE_NUMERO = re.compile(r"^[A-Z0-9-]+$")


def limpiar_texto(valor):
    """Sanitiza: quita caracteres de control, recorta y colapsa espacios repetidos."""
    if valor is None:
        return ""
    valor = re.sub(r"[\x00-\x1f\x7f]", " ", str(valor))
    return re.sub(r"\s+", " ", valor).strip()


def _texto_obligatorio(datos, campo, etiqueta, max_len, patron, limpio, errores):
    valor = limpiar_texto(datos.get(campo))
    if not valor:
        errores[campo] = f"{etiqueta} es obligatorio."
    elif len(valor) > max_len:
        errores[campo] = f"{etiqueta} no puede pasar de {max_len} caracteres."
    elif not patron.match(valor):
        errores[campo] = f"{etiqueta} contiene caracteres no permitidos."
    else:
        limpio[campo] = valor


def validar_empleado(datos):
    """Recibe request.POST. Devuelve (datos_limpios, errores)."""
    limpio, errores = {}, {}

    # Número de empleado: se guarda en mayúsculas
    numero = limpiar_texto(datos.get("numero_empleado")).upper()
    if not numero:
        errores["numero_empleado"] = "El número de empleado es obligatorio."
    elif len(numero) > 15 or not RE_NUMERO.match(numero):
        errores["numero_empleado"] = "Usa solo letras, números y guiones (máximo 15)."
    else:
        limpio["numero_empleado"] = numero

    _texto_obligatorio(datos, "nombre_empleado", "El nombre", 50, RE_NOMBRE, limpio, errores)
    _texto_obligatorio(datos, "apellido_paterno", "El apellido paterno", 50, RE_NOMBRE, limpio, errores)
    _texto_obligatorio(datos, "puesto_trabajo", "El puesto", 50, RE_PUESTO, limpio, errores)

    # Apellido materno: opcional
    materno = limpiar_texto(datos.get("apellido_materno"))
    if not materno:
        limpio["apellido_materno"] = None
    elif len(materno) > 50 or not RE_NOMBRE.match(materno):
        errores["apellido_materno"] = "El apellido materno no es válido."
    else:
        limpio["apellido_materno"] = materno

    # Teléfono: opcional; si viene, 10 dígitos (se guarda solo con dígitos)
    tel = limpiar_texto(datos.get("telefono_contacto"))
    if not tel:
        limpio["telefono_contacto"] = None
    elif not re.fullmatch(r"[0-9 ()+-]+", tel) or len(re.sub(r"\D", "", tel)) != 10:
        errores["telefono_contacto"] = "El teléfono debe tener 10 dígitos."
    else:
        limpio["telefono_contacto"] = re.sub(r"\D", "", tel)

    # Fecha de ingreso: AAAA-MM-DD, no futura
    fecha_txt = limpiar_texto(datos.get("fecha_ingreso"))
    if not fecha_txt:
        errores["fecha_ingreso"] = "La fecha de ingreso es obligatoria."
    else:
        try:
            fecha = datetime.strptime(fecha_txt, "%Y-%m-%d").date()
        except ValueError:
            errores["fecha_ingreso"] = "La fecha debe tener el formato AAAA-MM-DD."
        else:
            if fecha > date.today():
                errores["fecha_ingreso"] = "La fecha de ingreso no puede ser futura."
            elif fecha < FECHA_MINIMA:
                errores["fecha_ingreso"] = "La fecha de ingreso no es válida."
            else:
                limpio["fecha_ingreso"] = fecha

    # Estatus: opcional; si no viene, no se toca (en alta queda "Activo")
    estatus = limpiar_texto(datos.get("estatus_laboral"))
    if estatus:
        if estatus not in ESTATUS_VALIDOS:
            errores["estatus_laboral"] = "El estatus no es válido."
        else:
            limpio["estatus_laboral"] = estatus

    return limpio, errores