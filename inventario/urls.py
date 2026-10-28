from django.urls import path
from . import views

urlpatterns = [
    path("productos/", views.productos_lista, name="productos_lista"),
    path("productos/<int:id_producto>/stock/", views.producto_stock, name="producto_stock"),
    path("catalogos/", views.catalogos, name="catalogos"),
]