from functools import wraps
from django.http import HttpResponseForbidden
from django.shortcuts import redirect
from django.views.decorators.cache import never_cache


def rol_requerido(*roles_permitidos):
    """Protege una vista: exige sesión iniciada y que el rol esté permitido."""
    def decorador(vista):
        @wraps(vista)
        @never_cache  # evita que el botón "atrás" muestre un panel guardado tras cerrar sesión
        def envoltura(request, *args, **kwargs):
            # 1. Sin sesión -> al login
            if "usuario_id" not in request.session:
                return redirect("login")
            # 2. Con sesión pero rol no permitido -> bloqueado
            if request.session.get("rol") not in roles_permitidos:
                return HttpResponseForbidden(
                    "<h1>Acceso denegado</h1>"
                    "<p>No tienes permiso para ver esta página.</p>"
                    "<a href='javascript:history.back()'>Volver</a>"
                )
            return vista(request, *args, **kwargs)
        return envoltura
    return decorador