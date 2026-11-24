/* =====================================================
   WooWGuau · Panel de Empleado · Reporte de incidentes
   El empleado envía un incidente y consulta su estatus.

   MODO DE PRUEBA: mientras no exista el backend,
   USAR_DATOS_DE_PRUEBA = true y todo funciona en memoria.
   Al integrar con Django, cambia a false.
   ===================================================== */

const USAR_DATOS_DE_PRUEBA = true;

/* ---------- Rutas propuestas para backend ---------- */
const RUTAS = {
  crear: "/incidentes/crear/",   // POST: registra el incidente del empleado en sesión
  mios:  "/incidentes/mios/",    // GET: incidentes del empleado en sesión
};

/* ---------- Catálogos ---------- */
const TIPOS = {
  faltante: "Faltante de producto",
  diferencia: "Diferencia entre sistema y stock físico",
  danado: "Producto dañado",
  caducado: "Producto caducado",
  cliente: "Situación con un cliente",
  instalaciones: "Instalaciones o equipo",
  otro: "Otro",
};

// Estos tipos son de stock: necesitan un producto relacionado
const TIPOS_DE_STOCK = ["faltante", "diferencia", "danado", "caducado"];

const GRAVEDADES = {
  baja:  { texto: "Baja",  clase: "badge--neutral" },
  media: { texto: "Media", clase: "badge--warning" },
  alta:  { texto: "Alta",  clase: "badge--danger" },
};

const ESTATUS = {
  Enviado:  "badge--warning",
  Revisado: "badge--success",
};

/* ---------- Datos de prueba ----------
   Mismo formato que debe devolver el backend en /incidentes/mios/ */
let incidentesPrueba = [
  { id_incidente: 12, fecha_incidente: "2026-11-16T09:30", fecha_envio: "2026-11-16T09:42",
    tipo: "danado", gravedad: "media", id_producto: 2,
    nombre_producto: "Arena Sanitaria Aglutinante 10kg", cantidad_afectada: 3,
    descripcion: "Tres bolsas llegaron rotas en la entrega de la mañana.", estatus: "Enviado" },
  { id_incidente: 9, fecha_incidente: "2026-11-14T18:10", fecha_envio: "2026-11-14T18:25",
    tipo: "diferencia", gravedad: "alta", id_producto: 1,
    nombre_producto: "Croquetas Premium Adulto 20kg", cantidad_afectada: 5,
    descripcion: "El sistema marca 12 piezas y en anaquel solo hay 7.", estatus: "Revisado" },
];
let siguienteIdPrueba = 13;

/* =====================================================
   UTILIDADES
   ===================================================== */

const $ = (id) => document.getElementById(id);

// Fecha y hora local en formato del input datetime-local: "2026-11-23T21:05"
function ahoraLocal() {
  const d = new Date();
  d.setMinutes(d.getMinutes() - d.getTimezoneOffset());
  return d.toISOString().slice(0, 16);
}

// "2026-11-16T09:30" -> "16/11/2026 09:30"
function formatearFecha(valor) {
  if (!valor) return "—";
  const [fecha, hora = ""] = valor.split("T");
  const [a, m, d] = fecha.split("-");
  return `${d}/${m}/${a}${hora ? " " + hora.slice(0, 5) : ""}`;
}

// 12 -> "INC-012"
function folio(id) {
  return "INC-" + String(id).padStart(3, "0");
}

function crearBadge(texto, clase) {
  const span = document.createElement("span");
  span.className = `badge ${clase}`;
  span.textContent = texto;
  return span;
}

function nombreProducto(idProducto) {
  if (!idProducto) return "";
  const opcion = $("inc-producto").querySelector(`option[value="${idProducto}"]`);
  if (!opcion) return "";
  // "SKU-PER-001 · Croquetas Premium..." -> "Croquetas Premium..."
  const partes = opcion.textContent.split("·");
  return partes[partes.length - 1].trim();
}

function obtenerCookie(nombre) {
  const m = document.cookie.match(new RegExp("(^|;\\s*)" + nombre + "=([^;]*)"));
  return m ? decodeURIComponent(m[2]) : null;
}

function mostrarAviso(mensaje, tipo = "ok") {
  let aviso = $("aviso-panel");
  if (!aviso) {
    aviso = document.createElement("div");
    aviso.id = "aviso-panel";
    aviso.setAttribute("role", "status");
    document.body.appendChild(aviso);
  }
  aviso.className = `aviso aviso--${tipo} aviso--visible`;
  aviso.textContent = mensaje;
  clearTimeout(aviso._temporizador);
  aviso._temporizador = setTimeout(() => aviso.classList.remove("aviso--visible"), 3500);
}

function abrirModal(id) { window.location.hash = id; }
function cerrarModal()  { window.location.hash = "emp-panel"; }

/* ---------- Pantallas: "Reportar incidente" y "Mis incidentes" ---------- */
function mostrarVista(nombre) {
  const vista = nombre === "mis" ? "mis" : "reportar";

  document.querySelectorAll("section.vista").forEach((s) => {
    s.hidden = s.dataset.vista !== vista;
  });

  document.querySelectorAll(".panel-nav [data-vista]").forEach((enlace) => {
    const activa = enlace.dataset.vista === vista;
    enlace.classList.toggle("panel-nav__link--current", activa);
    if (activa) enlace.setAttribute("aria-current", "page");
    else enlace.removeAttribute("aria-current");
  });

  // La dirección refleja la pantalla (?vista=mis) sin recargar
  const url = new URL(window.location.href);
  if (vista === "mis") url.searchParams.set("vista", "mis");
  else url.searchParams.delete("vista");
  history.replaceState(null, "", url.pathname + url.search + url.hash);

  document.title = (vista === "mis" ? "Mis incidentes" : "Reportar incidente") + " | WooWGuau";
  window.scrollTo({ top: 0 });
  if (vista === "reportar") $("inc-fecha").focus({ preventScroll: true });
}
/* =====================================================
   COMUNICACIÓN CON EL SERVIDOR (o datos de prueba)
   Devuelven { ok, datos }; si falla:
   datos.errores = { campo: "mensaje" } o datos.error = "mensaje"
   ===================================================== */

const api = {
  async mios() {
    if (USAR_DATOS_DE_PRUEBA) return { ok: true, datos: { incidentes: incidentesPrueba } };
    try {
      const resp = await fetch(RUTAS.mios, { credentials: "same-origin" });
      return { ok: resp.ok, datos: await resp.json() };
    } catch (err) {
      return { ok: false, datos: { error: "No se pudieron cargar tus incidentes." } };
    }
  },

  async crear(formData) {
    if (USAR_DATOS_DE_PRUEBA) {
      const idProducto = Number(formData.get("id_producto")) || null;
      const cantidad = formData.get("cantidad_afectada");
      const nuevo = {
        id_incidente: siguienteIdPrueba++,
        fecha_incidente: formData.get("fecha_incidente"),
        fecha_envio: ahoraLocal(),
        tipo: formData.get("tipo"),
        gravedad: formData.get("gravedad"),
        id_producto: idProducto,
        nombre_producto: nombreProducto(idProducto),
        cantidad_afectada: cantidad ? Number(cantidad) : null,
        descripcion: formData.get("descripcion").trim(),
        estatus: "Enviado",
      };
      incidentesPrueba.push(nuevo);
      return { ok: true, datos: { incidente: nuevo } };
    }
    try {
      const resp = await fetch(RUTAS.crear, {
        method: "POST",
        headers: { "X-CSRFToken": obtenerCookie("csrftoken") || "" },
        body: formData,
        credentials: "same-origin",
      });
      const datos = await resp.json().catch(() => ({}));
      return { ok: resp.ok, datos };
    } catch (err) {
      return { ok: false, datos: { error: "No se pudo conectar con el servidor. Intenta de nuevo." } };
    }
  },
};

/* =====================================================
   FORMULARIO: VALIDACIÓN Y ERRORES
   ===================================================== */

function limpiarErrores() {
  const form = $("form-incidente");
  form.querySelectorAll("[data-error-for]").forEach((el) => (el.textContent = ""));
  form.querySelectorAll("[aria-invalid]").forEach((el) => el.removeAttribute("aria-invalid"));
}

function mostrarErrores(errores) {
  const form = $("form-incidente");
  let primerCampo = null;
  Object.entries(errores).forEach(([nombre, mensaje]) => {
    const destino = form.querySelector(`[data-error-for="${nombre}"]`)
                 || form.querySelector('[data-error-for="general"]');
    if (destino) destino.textContent = mensaje;
    const campo = form.querySelector(`[name="${nombre}"]`);
    if (campo) {
      campo.setAttribute("aria-invalid", "true");
      if (!primerCampo) primerCampo = campo;
    }
  });
  if (primerCampo) primerCampo.focus();
}

function validar() {
  const errores = {};
  const fecha = $("inc-fecha").value;
  const tipo = $("inc-tipo").value;
  const gravedad = $("inc-gravedad").value;
  const producto = $("inc-producto").value;
  const cantidad = $("inc-cantidad").value.trim();
  const descripcion = $("inc-descripcion").value.trim();

  // Fecha: obligatoria, no futura y de máximo 30 días atrás
  if (!fecha) {
    errores.fecha_incidente = "Indica cuándo ocurrió.";
  } else if (fecha > ahoraLocal()) {
    errores.fecha_incidente = "La fecha no puede ser futura.";
  } else {
    const limite = new Date();
    limite.setDate(limite.getDate() - 30);
    if (new Date(fecha) < limite) {
      errores.fecha_incidente = "Solo se pueden reportar incidentes de los últimos 30 días.";
    }
  }

  if (!tipo || !TIPOS[tipo]) errores.tipo = "Elige el tipo de incidente.";
  if (!GRAVEDADES[gravedad]) errores.gravedad = "Elige la gravedad.";

  // Los incidentes de stock necesitan producto
  if (TIPOS_DE_STOCK.includes(tipo) && !producto) {
    errores.id_producto = "Para un incidente de stock, elige el producto.";
  }

  if (cantidad) {
    const n = Number(cantidad);
    if (!Number.isInteger(n) || n < 1 || n > 9999) {
      errores.cantidad_afectada = "Escribe una cantidad entera entre 1 y 9999.";
    } else if (!producto) {
      errores.id_producto = "Elige el producto al que corresponde la cantidad.";
    }
  }

  if (descripcion.length < 10) {
    errores.descripcion = "Describe lo ocurrido con al menos 10 caracteres.";
  } else if (descripcion.length > 500) {
    errores.descripcion = "La descripción no puede pasar de 500 caracteres.";
  }

  return errores;
}

// Cambia la etiqueta de producto entre "(opcional)" y "(obligatorio)"
function actualizarProductoSegunTipo() {
  const esStock = TIPOS_DE_STOCK.includes($("inc-tipo").value);
  const etiqueta = document.querySelector('label[for="inc-producto"] .form__optional');
  if (etiqueta) etiqueta.textContent = esStock ? "(obligatorio)" : "(opcional)";
  $("inc-producto").required = esStock;
}

function actualizarContador() {
  const largo = $("inc-descripcion").value.length;
  const contador = $("contador-descripcion");
  contador.textContent = `${largo} / 500`;
  contador.classList.toggle("form__counter--limite", largo >= 450);
}

function prepararFormulario() {
  limpiarErrores();
  const ahora = ahoraLocal();
  $("inc-fecha").max = ahora;
  $("inc-fecha").value = ahora;  // por defecto: ahora mismo
  actualizarProductoSegunTipo();
  actualizarContador();
}

async function alEnviar(evento) {
  evento.preventDefault();
  limpiarErrores();

  const errores = validar();
  if (Object.keys(errores).length) return mostrarErrores(errores);

  const boton = $("btn-enviar");
  boton.disabled = true;
  boton.textContent = "Enviando…";

  const { ok, datos } = await api.crear(new FormData($("form-incidente")));

  boton.disabled = false;
  boton.textContent = "Enviar incidente";

  if (!ok) {
    return mostrarErrores(datos.errores || { general: datos.error || "No se pudo enviar el incidente." });
  }

  // Éxito: limpiar, actualizar la tabla y confirmar con el folio
  $("form-incidente").reset();
  prepararFormulario();
  $("filtro-estatus").value = "";
  await cargarIncidentes(datos.incidente ? datos.incidente.id_incidente : null);

  $("enviado-folio").textContent = datos.incidente ? folio(datos.incidente.id_incidente) : "";
  abrirModal("modal-enviado");
}

/* =====================================================
   MIS INCIDENTES: TABLA, FILTRO Y DETALLE
   ===================================================== */

let incidentes = [];

function incidentePorId(id) {
  return incidentes.find((i) => i.id_incidente === Number(id));
}

function crearCelda(etiqueta, contenido) {
  const td = document.createElement("td");
  td.dataset.label = etiqueta;
  if (contenido instanceof Node) td.appendChild(contenido);
  else td.textContent = contenido;
  return td;
}

function crearFila(inc, resaltar) {
  const tr = document.createElement("tr");
  tr.dataset.id = inc.id_incidente;
  if (resaltar) tr.classList.add("fila--nueva");

  const gravedad = GRAVEDADES[inc.gravedad] || { texto: inc.gravedad, clase: "badge--neutral" };

  const ver = document.createElement("a");
  ver.href = "#modal-ver";
  ver.className = "btn btn--small btn--ghost";
  ver.dataset.accion = "ver";
  ver.textContent = "Ver";
  const acciones = crearCelda("Acciones", ver);
  acciones.className = "data-table__actions";

  tr.append(
    crearCelda("Folio", folio(inc.id_incidente)),
    crearCelda("Fecha", formatearFecha(inc.fecha_incidente)),
    crearCelda("Tipo", TIPOS[inc.tipo] || inc.tipo),
    crearCelda("Producto", inc.nombre_producto || "—"),
    crearCelda("Gravedad", crearBadge(gravedad.texto, gravedad.clase)),
    crearCelda("Estatus", crearBadge(inc.estatus, ESTATUS[inc.estatus] || "badge--neutral")),
    acciones
  );
  return tr;
}

function pintarTabla(idResaltar = null) {
  const filtro = $("filtro-estatus").value;
  const texto = $("buscar-incidente").value.trim().toLowerCase();

  const visibles = incidentes
    .filter((i) => !filtro || i.estatus === filtro)
    .filter((i) => {
      if (!texto) return true;
      return [folio(i.id_incidente), TIPOS[i.tipo], i.nombre_producto, i.descripcion]
        .join(" ").toLowerCase().includes(texto);
    })
    .sort((a, b) => (b.fecha_envio || b.fecha_incidente).localeCompare(a.fecha_envio || a.fecha_incidente));

  $("incidentes-tbody").replaceChildren(
    ...visibles.map((i) => crearFila(i, i.id_incidente === idResaltar))
  );

  const vacia = $("tabla-vacia");
  vacia.hidden = visibles.length > 0;
  vacia.textContent = incidentes.length === 0
    ? "Todavía no has reportado incidentes."
    : "No hay incidentes que coincidan con la búsqueda.";

  const pendientes = incidentes.filter((i) => i.estatus === "Enviado").length;
  const revisados = incidentes.filter((i) => i.estatus === "Revisado").length;

  $("result-count").textContent =
    `Mostrando ${visibles.length} de ${incidentes.length} incidente${incidentes.length === 1 ? "" : "s"}`;

  // Tarjetas de resumen
  $("resumen-total").textContent = incidentes.length;
  $("resumen-enviados").textContent = pendientes;
  $("resumen-revisados").textContent = revisados;

  // Número en el menú "Mis incidentes": los que esperan revisión
  const contador = $("nav-contador");
  contador.textContent = pendientes;
  contador.hidden = pendientes === 0;
}

async function cargarIncidentes(idResaltar = null) {
  const { ok, datos } = await api.mios();
  if (!ok) {
    mostrarAviso(datos.error || "No se pudieron cargar tus incidentes.", "error");
    return;
  }
  incidentes = datos.incidentes || [];
  pintarTabla(idResaltar);
}

function prepararModalVer(inc) {
  const gravedad = GRAVEDADES[inc.gravedad];
  $("ver-id").textContent = folio(inc.id_incidente);
  $("ver-estatus").replaceChildren(crearBadge(inc.estatus, ESTATUS[inc.estatus] || "badge--neutral"));
  $("ver-fecha").textContent = formatearFecha(inc.fecha_incidente);
  $("ver-enviado").textContent = formatearFecha(inc.fecha_envio);
  $("ver-tipo").textContent = TIPOS[inc.tipo] || inc.tipo;
  $("ver-gravedad").textContent = gravedad ? gravedad.texto : inc.gravedad;
  $("ver-producto").textContent = inc.nombre_producto || "Ninguno";
  $("ver-cantidad").textContent = inc.cantidad_afectada ? `${inc.cantidad_afectada} pza.` : "—";
  $("ver-descripcion").textContent = inc.descripcion;
}

/* =====================================================
   EVENTOS
   ===================================================== */

document.addEventListener("DOMContentLoaded", () => {

  // Si la página se recarga con un modal abierto, se cierra
  if (window.location.hash.startsWith("#modal-")) cerrarModal();

  const form = $("form-incidente");
  prepararFormulario();

  form.addEventListener("submit", alEnviar);

  // "Limpiar": después del reset se vuelve a poner la fecha de ahora
  form.addEventListener("reset", () => setTimeout(prepararFormulario, 0));

  // Al corregir un campo se quita su error
  form.addEventListener("input", (evento) => {
    const campo = evento.target;
    if (!campo.name) return;
    campo.removeAttribute("aria-invalid");
    const error = form.querySelector(`[data-error-for="${campo.name}"]`);
    if (error) error.textContent = "";
  });

  $("inc-tipo").addEventListener("change", actualizarProductoSegunTipo);
  $("inc-descripcion").addEventListener("input", actualizarContador);

  // La cantidad solo acepta dígitos
  $("inc-cantidad").addEventListener("input", (evento) => {
    evento.target.value = evento.target.value.replace(/\D/g, "").slice(0, 4);
  });

  // Botón Ver de cada fila: llena el detalle antes de abrir el modal
  $("tabla-incidentes").addEventListener("click", (evento) => {
    const boton = evento.target.closest('[data-accion="ver"]');
    if (!boton) return;
    const inc = incidentePorId(boton.closest("tr").dataset.id);
    if (inc) prepararModalVer(inc);
    else evento.preventDefault();
  });

    $("filtro-estatus").addEventListener("change", () => pintarTabla());
  $("buscar-incidente").addEventListener("input", () => pintarTabla());

  // Cambiar de pantalla: menú, "+ Reportar incidente" y "Ver mis incidentes"
  document.addEventListener("click", (evento) => {
    const enlace = evento.target.closest("[data-vista]");
    if (!enlace || enlace.tagName === "SECTION") return;
    evento.preventDefault();
    if (enlace.closest(".modal")) cerrarModal();
    mostrarVista(enlace.dataset.vista);
  });

  // Confirmación: "Reportar otro" vuelve al formulario con el foco en la fecha
  $("btn-reportar-otro").addEventListener("click", () => {
    setTimeout(() => {
      $("seccion-formulario").scrollIntoView({ behavior: "smooth", block: "start" });
      $("inc-fecha").focus({ preventScroll: true });
    }, 50);
  });

  // Tecla Esc cierra el modal abierto
  document.addEventListener("keydown", (evento) => {
    if (evento.key === "Escape" && window.location.hash.startsWith("#modal-")) cerrarModal();
  });

    // Abrir la pantalla que pida la dirección (?vista=mis)
  mostrarVista(new URLSearchParams(window.location.search).get("vista"));

  cargarIncidentes();
});
