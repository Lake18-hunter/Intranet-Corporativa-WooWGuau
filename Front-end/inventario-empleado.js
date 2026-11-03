/* =====================================================
   Panel de Empleado - Lógica de Inventario (WooWGuau)
   ===================================================== */

document.addEventListener("DOMContentLoaded", () => {
    cargarCatalogos();
    cargarProductos();

    // Filtros
    const filterForm = document.getElementById("filter-form");
    if (filterForm) {
        filterForm.addEventListener("submit", (e) => {
            e.preventDefault();
            const formData = new FormData(filterForm);
            const params = new URLSearchParams(formData).toString();
            cargarProductos(`?${params}`);
        });
    }

    // Crear Producto
    const formCrear = document.getElementById("form-crear-producto");
    if (formCrear) {
        formCrear.addEventListener("submit", async (e) => {
            e.preventDefault();
            const formData = new FormData(formCrear);
            try {
                const response = await fetch("/inventario/productos/", { method: "POST", body: formData });
                if (response.ok) {
                    window.location.hash = "emp-panel";
                    formCrear.reset();
                    cargarProductos();
                } else {
                    const err = await response.json();
                    mostrarAlerta("Error", err.error || "No se pudo registrar el producto.");
                }
            } catch (error) {
                window.location.hash = "emp-panel";
                mostrarAlerta("Éxito (Simulación)", "Producto registrado correctamente.");
                formCrear.reset();
            }
        });
    }

    // Editar Producto
    const formEditar = document.getElementById("form-editar");
    if (formEditar) {
        formEditar.addEventListener("submit", async (e) => {
            e.preventDefault();
            const id = document.getElementById("editar-id").value;
            const formData = new FormData(formEditar);
            try {
                const response = await fetch(`/inventario/productos/${id}/`, { method: "PUT", body: formData });
                if (response.ok) {
                    window.location.hash = "emp-panel";
                    cargarProductos();
                } else {
                    const err = await response.json();
                    mostrarAlerta("Error", err.error || "No se pudo actualizar el producto.");
                }
            } catch (error) {
                window.location.hash = "emp-panel";
                mostrarAlerta("Éxito (Simulación)", "Cambios guardados correctamente.");
            }
        });
    }

    // Eliminar Producto
    const formEliminar = document.getElementById("form-eliminar");
    if (formEliminar) {
        formEliminar.addEventListener("submit", async (e) => {
            e.preventDefault();
            const id = document.getElementById("eliminar-id").value;
            try {
                const response = await fetch(`/inventario/productos/${id}/`, { method: "DELETE" });
                if (response.ok) {
                    window.location.hash = "emp-panel";
                    cargarProductos();
                } else {
                    const err = await response.json();
                    mostrarAlerta("Error", err.error || "No se pudo eliminar el producto.");
                }
            } catch (error) {
                window.location.hash = "emp-panel";
                mostrarAlerta("Éxito (Simulación)", "Producto eliminado del inventario.");
            }
        });
    }
});

// Funciones para rellenar modales de Ver, Editar y Eliminar
function verProducto(id, sku, nombre, desc, precio, stock, especie, categoria, marca, estatus) {
    document.getElementById("ver-id").textContent = id;
    document.getElementById("ver-sku").textContent = sku;
    document.getElementById("ver-nombre").textContent = nombre;
    document.getElementById("ver-desc").textContent = desc || "Sin descripción";
    document.getElementById("ver-precio").textContent = `$${precio}`;
    document.getElementById("ver-stock").textContent = stock;
    document.getElementById("ver-especie").textContent = especie;
    document.getElementById("ver-categoria").textContent = categoria;
    document.getElementById("ver-marca").textContent = marca;
    document.getElementById("ver-estatus").textContent = estatus;
}

function prepararEdicion(id, sku, nombre, desc, precio, especie, categoria, marca) {
    document.getElementById("editar-id").value = id;
    document.getElementById("editar-sku").value = sku;
    document.getElementById("editar-nombre").value = nombre;
    document.getElementById("editar-precio").value = precio;
    document.getElementById("editar-especie").value = especie;
    document.getElementById("editar-categoria").value = categoria;
    document.getElementById("editar-marca").value = marca;
    document.getElementById("editar-desc").value = desc || "";
}

function prepararEliminacion(id, nombre) {
    document.getElementById("eliminar-id").value = id;
    document.getElementById("eliminar-nombre").textContent = nombre;
}

// Catálogos y Tabla
async function cargarCatalogos() {
    try {
        const response = await fetch("/inventario/catalogos/");
        if (!response.ok) throw new Error();
        const data = await response.json();
        poblarSelect("select-especie", data.especies, "Todas las especies");
        poblarSelect("select-categoria", data.categorias, "Todas las categorías");
        poblarSelect("select-marca", data.marcas, "Todas las marcas");
    } catch (e) {
        console.warn("Modo estático de catálogos activo.");
    }
}

function poblarSelect(elementId, items = [], defaultText) {
    const select = document.getElementById(elementId);
    if (!select || !items || items.length === 0) return;
    select.innerHTML = `<option value="">${defaultText}</option>`;
    items.forEach(item => {
        const nombre = typeof item === "string" ? item : (item.nombre || item.nombre_especie || item.nombre_categoria || item.nombre_marca);
        const opt = document.createElement("option");
        opt.value = nombre;
        opt.textContent = nombre;
        select.appendChild(opt);
    });
}

async function cargarProductos(queryString = "") {
    try {
        const response = await fetch(`/inventario/productos/${queryString}`);
        if (!response.ok) throw new Error();
        const productos = await response.json();
        renderizarTabla(productos);
    } catch (e) {
        console.warn("Modo estático de productos activo.");
    }
}

function renderizarTabla(productos) {
    const tbody = document.getElementById("inventory-tbody");
    const countSpan = document.getElementById("result-count");
    if (!productos || productos.length === 0) return;

    tbody.innerHTML = "";
    countSpan.textContent = `Mostrando ${productos.length} producto(s)`;

    productos.forEach(prod => {
        const tr = document.createElement("tr");
        tr.innerHTML = `
            <td data-label="SKU"><strong>${prod.codigo_sku}</strong></td>
            <td data-label="Producto">${prod.nombre_producto}</td>
            <td data-label="Especie">${prod.especie || 'N/D'}</td>
            <td data-label="Categoría">${prod.categoria || 'N/D'}</td>
            <td data-label="Marca">${prod.marca || 'N/D'}</td>
            <td data-label="Precio">$${prod.precio_publico}</td>
            <td data-label="Stock Actual"><span id="stock-val-${prod.id_producto}" style="font-weight:700;">${prod.stock_actual}</span></td>
            <td data-label="Control Stock">
                <div class="stock-control">
                    <button type="button" class="btn btn--stock btn--stock-minus" onclick="modificarStock(${prod.id_producto}, 'restar')" title="Restar 1">-</button>
                    <span class="stock-control__value" id="stock-num-${prod.id_producto}">${prod.stock_actual}</span>
                    <button type="button" class="btn btn--stock btn--stock-plus" onclick="modificarStock(${prod.id_producto}, 'sumar')" title="Sumar 1">+</button>
                </div>
            </td>
            <td data-label="Acciones" class="data-table__actions">
                <a href="#modal-ver" class="btn btn--small btn--ghost" onclick="verProducto(${prod.id_producto}, '${prod.codigo_sku}', '${prod.nombre_producto}', '${prod.descripcion_producto || ''}', '${prod.precio_publico}', '${prod.stock_actual}', '${prod.especie}', '${prod.categoria}', '${prod.marca}', 'Activo')">Ver</a>
                <a href="#modal-editar" class="btn btn--small btn--secondary" onclick="prepararEdicion(${prod.id_producto}, '${prod.codigo_sku}', '${prod.nombre_producto}', '${prod.descripcion_producto || ''}', '${prod.precio_publico}', '${prod.especie}', '${prod.categoria}', '${prod.marca}')">Editar</a>
                <a href="#modal-eliminar" class="btn btn--small btn--danger" onclick="prepararEliminacion(${prod.id_producto}, '${prod.nombre_producto}')">Eliminar</a>
            </td>
        `;
        tbody.appendChild(tr);
    });
}

async function modificarStock(idProducto, operacion) {
    try {
        const formData = new FormData();
        formData.append("operacion", operacion);
        formData.append("cantidad", "1");

        const response = await fetch(`/inventario/productos/${idProducto}/stock/`, { method: "POST", body: formData });
        const data = await response.json();

        if (response.ok) {
            const nuevoStock = data.producto.stock_actual;
            document.getElementById(`stock-val-${idProducto}`).textContent = nuevoStock;
            document.getElementById(`stock-num-${idProducto}`).textContent = nuevoStock;
        } else if (response.status === 409) {
            mostrarAlerta("Conflicto de Stock", data.error || "No se pudo completar la operación.");
        } else {
            mostrarAlerta("Aviso", data.error || data.mensaje || "Error al actualizar stock.");
        }
    } catch (error) {
        const spanNum = document.getElementById(`stock-num-${idProducto}`);
        const spanVal = document.getElementById(`stock-val-${idProducto}`);
        if (!spanNum) return;
        let actual = parseInt(spanNum.textContent);
        
        if (operacion === 'sumar') actual += 1;
        else if (operacion === 'restar' && actual > 0) actual -= 1;
        else if (operacion === 'restar' && actual <= 0) {
            mostrarAlerta("Stock Insuficiente", "El stock actual es 0 y no se puede reducir más.");
            return;
        }

        spanNum.textContent = actual;
        spanVal.textContent = actual;
    }
}

function mostrarAlerta(titulo, mensaje) {
    document.getElementById("alert-title").textContent = titulo;
    document.getElementById("alert-message").textContent = mensaje;
    document.getElementById("alert-modal").classList.add("is-open");
}

function closeAlertModal() {
    document.getElementById("alert-modal").classList.remove("is-open");
}