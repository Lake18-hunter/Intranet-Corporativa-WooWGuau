from django.urls import path
from . import views, views_empleados

urlpatterns = [
    path("", views.login_view, name="login"),
    path("logout/", views.logout_view, name="logout"),
    path("panel-admin/", views.panel_admin, name="panel_admin"),
    path("panel-empleado/", views.panel_empleado, name="panel_empleado"),

    path("empleados/", views_empleados.empleados_lista, name="empleados_lista"),
    path("empleados/crear/", views_empleados.empleado_crear, name="empleado_crear"),
    path("empleados/<int:id_empleado>/", views_empleados.empleado_detalle, name="empleado_detalle"),
    path("empleados/<int:id_empleado>/editar/", views_empleados.empleado_editar, name="empleado_editar"),
    path("empleados/<int:id_empleado>/baja/", views_empleados.empleado_baja, name="empleado_baja"),
]