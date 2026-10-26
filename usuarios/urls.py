from django.urls import path
from . import views

urlpatterns = [
    path("", views.login_view, name="login"),
    path("logout/", views.logout_view, name="logout"),
    path("panel-admin/", views.panel_admin, name="panel_admin"),
    path("panel-empleado/", views.panel_empleado, name="panel_empleado"),
]