/* =====================================================
   Panel de Empleado - Lógica de Inventario (WooWGuau)
   - Consulta de stock con actualización automática (cada 12 s, sin websockets)
   - Registro de salidas: venta, merma y uso interno
   - El stock ya NO se suma ni resta a mano: sube con las órdenes
     recibidas y baja con las salidas; los ajustes los hace el gerente.
   ===================================================== */

const INTERVALO_ACTUALIZACION_MS = 12000;   // decisión 7: entre 10 y 15 segundos
let ultimaConsulta = "";                    // conserva los filtros en cada actualización

document.addEventListener("DOMContentLoaded", () => {
    cargarCatalogos();
    cargarProductos();
    iniciarActualizacionAutomatica();

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

    // Acciones de la tabla (Ver / Registrar salida) con un solo listener
    const tbody = document.getElementById("inventory-tbody");
    if (tbody) {
        tbody.addEventListener("click", (e) => {
            const boton = e.target.closest("a[data-action]");
            if (!boton) return;
            const fila = boton.closest("tr");
            if (!fila) return;

            if (boton.dataset.action === "ver") verProducto(fila.dataset);
            if (boton.dataset.action === "salida") prepararSalida(fila.dataset.id);
        });
    }

    // Registrar salida
    const formSalida = document.getElementById("form-salida");
    if (formSalida) {
        const selectProducto = document.getElementById("salida-producto");
        selectProducto.addEventListener("change", () => mostrarDisponible(selectProducto.value));
        formSalida.addEventListener("submit", registrarSalida);
    }
});

/* ---------- Actualización automática ---------- */
function iniciarActualizacionAutomatica() {
    setInterval(() => {
        // No refrescar con la pestaña oculta ni mientras hay un modal abierto
        const hayModalAbierto = window.location.hash.startsWith("#modal-")
            || document.querySelector(".modal.is-open");
        if (document.hidden || hayModalAbierto) return;
        cargarProductos(ultimaConsulta, true);
    }, INTERVALO_ACTUALIZACION_MS);
}

function marcarActualizacion(ok) {
    const indicador = document.getElementById("live-indicator");
    if (!indicador) return;
    if (ok) {
        indicador.classList.remove("live-indicator--error");
        indicador.textContent = `Actualizado ${new Date().toLocaleTimeString("es-MX")}`;
    } else {
        indicador.classList.add("live-indicator--error");
        indicador.textContent = "Sin conexión con el servidor";
    }
}

/* ---------- Modal Ver ---------- */
function verProducto(d) {
    document.getElementById("ver-id").textContent = d.id;
    document.getElementById("ver-sku").textContent = d.sku;
    document.getElementById("ver-nombre").textContent = d.nombre;
    document.getElementById("ver-desc").textContent = d.desc || "Sin descripción";
    document.getElementById("ver-precio").textContent = `$${d.precio}`;
    document.getElementById("ver-stock").textContent = d.stock;
    document.getElementById("ver-especie").textContent = d.especie;
    document.getElementById("ver-categoria").textContent = d.categoria;
    document.getElementById("ver-marca").textContent = d.marca;
    document.getElementById("ver-estatus").textContent = "Activo";
}

/* ---------- Salidas ---------- */
function prepararSalida(idProducto) {
    const select = document.getElementById("salida-producto");
    select.value = String(idProducto);
    mostrarDisponible(select.value);
}

function stockDe(idProducto) {
    const fila = document.querySelector(`#inventory-tbody tr[data-id="${idProducto}"]`);
    return fila ? parseInt(fila.dataset.stock, 10) : null;
}

function mostrarDisponible(idProducto) {
    const aviso = document.getElementById("salida-disponible");
    const stock = idProducto ? stockDe(idProducto) : null;
    aviso.textContent = stock === null ? "Stock disponible: —" : `Stock disponible: ${stock}`;
}

function obtenerCsrf() {
    const m = document.cookie.match(/(?:^|;\s*)csrftoken=([^;]+)/);
    return m ? decodeURIComponent(m[1]) : "";
}

async function registrarSalida(e) {
    e.preventDefault();
    const form = e.currentTarget;
    const idProducto = document.getElementById("salida-producto").value;
    const cantidad = parseInt(document.getElementById("salida-cantidad").value, 10);
    const disponible = stockDe(idProducto);

    // Validación rápida en pantalla; el servidor sigue siendo quien decide
    if (disponible !== null && cantidad > disponible) {
        mostrarAlerta("Stock insuficiente", `Solo hay ${disponible} pieza(s) disponibles.`);
        return;
    }

    try {
        const response = await fetch("/inventario/salidas/", {
            method: "POST",
            body: new FormData(form),
            headers: { "X-CSRFToken": obtenerCsrf() }
        });

        if (response.ok) {
            window.location.hash = "emp-panel";
            form.reset();
            mostrarDisponible("");
            await cargarProductos(ultimaConsulta);
            mostrarAlerta("Salida registrada", "La salida se registró y el stock se actualizó.");
        } else {
            const data = await response.json();
            const titulo = response.status === 409 ? "Conflicto de stock" : "Error";
            mostrarAlerta(titulo, data.error || "No se pudo registrar la salida.");
        }
    } catch (error) {
        // Modo estático (sin backend): se simula el descuento en pantalla
        const fila = document.querySelector(`#inventory-tbody tr[data-id="${idProducto}"]`);
        if (fila) {
            const nuevo = (disponible || 0) - cantidad;
            fila.dataset.stock = nuevo;
            const span = document.getElementById(`stock-val-${idProducto}`);
            if (span) span.textContent = nuevo;
        }
        window.location.hash = "emp-panel";
        form.reset();
        mostrarDisponible("");
        mostrarAlerta("Éxito (Simulación)", "Salida registrada correctamente.");
    }
}

/* ---------- Catálogos y tabla ---------- */
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

async function cargarProductos(queryString = "", silencioso = false) {
    ultimaConsulta = queryString;
    try {
        const response = await fetch(`/inventario/productos/${queryString}`);
        if (!response.ok) throw new Error();
        const productos = await response.json();
        renderizarTabla(productos);
        marcarActualizacion(true);
    } catch (e) {
        if (!silencioso) console.warn("Modo estático de productos activo.");
        marcarActualizacion(false);
    }
}

function esc(valor) {
    return String(valor ?? "").replace(/[&<>"']/g, c => (
        { "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[c]
    ));
}

function renderizarTabla(productos) {
    const tbody = document.getElementById("inventory-tbody");
    const countSpan = document.getElementById("result-count");
    if (!productos || productos.length === 0) return;

    tbody.innerHTML = "";
    countSpan.textContent = `Mostrando ${productos.length} producto(s)`;

    productos.forEach(prod => {
        const tr = document.createElement("tr");
        tr.dataset.id = prod.id_producto;
        tr.dataset.sku = prod.codigo_sku;
        tr.dataset.nombre = prod.nombre_producto;
        tr.dataset.desc = prod.descripcion_producto || "";
        tr.dataset.precio = prod.precio_publico;
        tr.dataset.stock = prod.stock_actual;
        tr.dataset.especie = prod.especie || "N/D";
        tr.dataset.categoria = prod.categoria || "N/D";
        tr.dataset.marca = prod.marca || "N/D";

        tr.innerHTML = `
            <td data-label="SKU"><strong>${esc(prod.codigo_sku)}</strong></td>
            <td data-label="Producto">${esc(prod.nombre_producto)}</td>
            <td data-label="Especie">${esc(prod.especie || "N/D")}</td>
            <td data-label="Categoría">${esc(prod.categoria || "N/D")}</td>
            <td data-label="Marca">${esc(prod.marca || "N/D")}</td>
            <td data-label="Precio">$${esc(prod.precio_publico)}</td>
            <td data-label="Stock Actual"><span id="stock-val-${esc(prod.id_producto)}" style="font-weight:700;">${esc(prod.stock_actual)}</span></td>
            <td data-label="Acciones" class="data-table__actions">
                <a href="#modal-ver" class="btn btn--small btn--ghost" data-action="ver">Ver</a>
                <a href="#modal-salida" class="btn btn--small btn--secondary" data-action="salida">Registrar salida</a>
            </td>
        `;
        tbody.appendChild(tr);
    });

    sincronizarSelectSalida(productos);
}

// Mantiene el select del modal de salida igual a los productos de la tabla
function sincronizarSelectSalida(productos) {
    const select = document.getElementById("salida-producto");
    if (!select) return;
    const seleccionado = select.value;
    select.innerHTML = '<option value="">Seleccionar…</option>';
    productos.forEach(p => {
        const opt = document.createElement("option");
        opt.value = p.id_producto;
        opt.textContent = `${p.codigo_sku} · ${p.nombre_producto}`;
        select.appendChild(opt);
    });
    select.value = seleccionado;
    mostrarDisponible(select.value);
}

function mostrarAlerta(titulo, mensaje) {
    document.getElementById("alert-title").textContent = titulo;
    document.getElementById("alert-message").textContent = mensaje;
    document.getElementById("alert-modal").classList.add("is-open");
}

function closeAlertModal() {
    document.getElementById("alert-modal").classList.remove("is-open");
}
