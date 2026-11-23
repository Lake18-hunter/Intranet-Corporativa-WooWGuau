/* =====================================================
   WooWGuau · Panel de Administrador
   Gestión de empleados (expediente) y cuentas de acceso.

   MODO DE PRUEBA: mientras el HTML no lo sirva Django,
   USAR_DATOS_DE_PRUEBA = true y todo funciona en memoria.
   Al integrar con el backend, cambia a false.
   ===================================================== */

const USAR_DATOS_DE_PRUEBA = true;

/* ---------- Rutas del backend ----------
   Las de empleados ya existen.
   Las de cuenta son la PROPUESTA para backend: confirmarlas. */
const RUTAS = {
  listar:        "/empleados/",
  crear:         "/empleados/crear/",
  editar:        (id) => `/empleados/${id}/editar/`,
  baja:          (id) => `/empleados/${id}/baja/`,
  crearCuenta:   (id) => `/empleados/${id}/cuenta/crear/`,
  editarCuenta:  (id) => `/empleados/${id}/cuenta/editar/`,
};

/* ---------- Datos de prueba ----------
   Mismo formato que debe devolver el backend en /empleados/ */
let empleadosPrueba = [
  { id_empleado: 1, numero_empleado: "EMP-001", nombre_empleado: "Susie",
    apellido_paterno: "Escobar", apellido_materno: "Ruiz", telefono_contacto: "5512345678",
    puesto_trabajo: "Gerente de TI", fecha_ingreso: "2024-03-01", estatus_laboral: "Activo",
    cuenta: { nombre_usuario: "sescobar", correo: "susie.escobar@empresa.com",
              rol: "Administrador", estatus_cuenta: true } },
  { id_empleado: 2, numero_empleado: "EMP-002", nombre_empleado: "Carlos",
    apellido_paterno: "Ramírez", apellido_materno: "", telefono_contacto: "",
    puesto_trabajo: "Cajero", fecha_ingreso: "2024-08-15", estatus_laboral: "Activo",
    cuenta: { nombre_usuario: "cramirez", correo: "carlos.ramirez@empresa.com",
              rol: "Empleado", estatus_cuenta: true } },
  { id_empleado: 3, numero_empleado: "EMP-003", nombre_empleado: "Ana",
    apellido_paterno: "López", apellido_materno: "Torres", telefono_contacto: "5587654321",
    puesto_trabajo: "Auxiliar de almacén", fecha_ingreso: "2025-01-15", estatus_laboral: "Activo",
    cuenta: null },  // registrada por el gerente, sin credenciales
  { id_empleado: 4, numero_empleado: "EMP-004", nombre_empleado: "Laura",
    apellido_paterno: "Méndez", apellido_materno: "", telefono_contacto: "5524681357",
    puesto_trabajo: "Gerente de tienda", fecha_ingreso: "2023-06-10", estatus_laboral: "Inactivo",
    cuenta: { nombre_usuario: "lmendez", correo: "laura.mendez@empresa.com",
              rol: "Gerente", estatus_cuenta: false } },
];
let siguienteIdPrueba = 5;

/* =====================================================
   UTILIDADES
   ===================================================== */

const $ = (id) => document.getElementById(id);

function nombreCompleto(e) {
  return [e.nombre_empleado, e.apellido_paterno, e.apellido_materno].filter(Boolean).join(" ");
}

// "2024-03-01" -> "01/03/2024"
function formatearFecha(iso) {
  if (!iso) return "—";
  const [a, m, d] = iso.split("-");
  return `${d}/${m}/${a}`;
}

// "5512345678" -> "55 1234 5678"
function formatearTelefono(tel) {
  if (!tel) return "—";
  return tel.length === 10 ? `${tel.slice(0, 2)} ${tel.slice(2, 6)} ${tel.slice(6)}` : tel;
}

function textoEstatus(estatus) {
  return estatus === "Baja Logica" ? "Baja" : estatus;
}

function claseEstatus(estatus) {
  if (estatus === "Activo") return "badge--active";
  if (estatus === "Inactivo") return "badge--inactive";
  return "badge--baja";
}

function crearBadge(texto, clase) {
  const span = document.createElement("span");
  span.className = `badge ${clase}`;
  span.textContent = texto;
  return span;
}

// Fecha de hoy en formato AAAA-MM-DD (hora local)
function hoyISO() {
  const h = new Date();
  h.setMinutes(h.getMinutes() - h.getTimezoneOffset());
  return h.toISOString().slice(0, 10);
}

// Lee la cookie csrftoken que pone Django
function obtenerCookie(nombre) {
  const m = document.cookie.match(new RegExp("(^|;\\s*)" + nombre + "=([^;]*)"));
  return m ? decodeURIComponent(m[2]) : null;
}

// Aviso breve en pantalla
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
function cerrarModal()  { window.location.hash = "admin-panel"; }

/* =====================================================
   COMUNICACIÓN CON EL SERVIDOR (o datos de prueba)
   Todas devuelven { ok, datos } donde, si falla,
   datos.errores = { campo: "mensaje" } o datos.error = "mensaje"
   ===================================================== */

async function peticionPost(url, formData) {
  try {
    const resp = await fetch(url, {
      method: "POST",
      headers: { "X-CSRFToken": obtenerCookie("csrftoken") || "" },
      body: formData,
      credentials: "same-origin",
    });
    const datos = await resp.json().catch(() => ({}));
    return { ok: resp.ok, datos };
  } catch (err) {
    return { ok: false, datos: { error: "No se pudo conectar con el servidor." } };
  }
}

// Simula la validación de duplicados del servidor en modo prueba
function duplicadosPrueba(fd, idExcluir) {
  const errores = {};
  const numero = (fd.get("numero_empleado") || "").toUpperCase();
  const correo = (fd.get("correo") || "").toLowerCase();
  const usuario = (fd.get("nombre_usuario") || "").toLowerCase();
  empleadosPrueba.forEach((e) => {
    if (e.id_empleado === idExcluir) return;
    if (numero && e.numero_empleado === numero) errores.numero_empleado = "Ya existe un empleado con ese número.";
    if (e.cuenta && correo && e.cuenta.correo.toLowerCase() === correo) errores.correo = "Ese correo ya está registrado.";
    if (e.cuenta && usuario && e.cuenta.nombre_usuario.toLowerCase() === usuario) errores.nombre_usuario = "Ese nombre de usuario ya existe.";
  });
  return errores;
}

function datosEmpleadoDesde(fd) {
  return {
    numero_empleado: fd.get("numero_empleado").trim().toUpperCase(),
    nombre_empleado: fd.get("nombre_empleado").trim(),
    apellido_paterno: fd.get("apellido_paterno").trim(),
    apellido_materno: (fd.get("apellido_materno") || "").trim(),
    telefono_contacto: (fd.get("telefono_contacto") || "").trim(),
    puesto_trabajo: fd.get("puesto_trabajo").trim(),
    fecha_ingreso: fd.get("fecha_ingreso"),
    estatus_laboral: fd.get("estatus_laboral") || "Activo",
  };
}

function datosCuentaDesde(fd, cuentaAnterior) {
  return {
    nombre_usuario: fd.get("nombre_usuario").trim(),
    correo: fd.get("correo").trim(),
    rol: fd.get("rol"),
    // En crear no hay casilla: la cuenta nace activa
    estatus_cuenta: fd.has("estatus_cuenta") || !cuentaAnterior ? fd.get("estatus_cuenta") !== null || !cuentaAnterior : false,
  };
}

const api = {
  async listar() {
    if (USAR_DATOS_DE_PRUEBA) return { ok: true, datos: { empleados: empleadosPrueba } };
    try {
      const resp = await fetch(RUTAS.listar + "?bajas=1", { credentials: "same-origin" });
      return { ok: resp.ok, datos: await resp.json() };
    } catch (err) {
      return { ok: false, datos: { error: "No se pudo cargar la lista de empleados." } };
    }
  },

  async crearEmpleado(fd) {
    if (USAR_DATOS_DE_PRUEBA) {
      const errores = duplicadosPrueba(fd, null);
      delete errores.correo; delete errores.nombre_usuario;
      if (Object.keys(errores).length) return { ok: false, datos: { errores } };
      const nuevo = { id_empleado: siguienteIdPrueba++, ...datosEmpleadoDesde(fd), cuenta: null };
      empleadosPrueba.push(nuevo);
      return { ok: true, datos: { empleado: nuevo } };
    }
    return peticionPost(RUTAS.crear, fd);
  },

  async editarEmpleado(id, fd) {
    if (USAR_DATOS_DE_PRUEBA) {
      const errores = duplicadosPrueba(fd, id);
      delete errores.correo; delete errores.nombre_usuario;
      if (Object.keys(errores).length) return { ok: false, datos: { errores } };
      const e = empleadosPrueba.find((x) => x.id_empleado === id);
      Object.assign(e, datosEmpleadoDesde(fd));
      return { ok: true, datos: { empleado: e } };
    }
    return peticionPost(RUTAS.editar(id), fd);
  },

  async guardarCuenta(id, fd, esNueva) {
    if (USAR_DATOS_DE_PRUEBA) {
      const errores = duplicadosPrueba(fd, id);
      delete errores.numero_empleado;
      if (Object.keys(errores).length) return { ok: false, datos: { errores } };
      const e = empleadosPrueba.find((x) => x.id_empleado === id);
      e.cuenta = datosCuentaDesde(fd, esNueva ? null : e.cuenta);
      return { ok: true, datos: { empleado: e } };
    }
    return peticionPost(esNueva ? RUTAS.crearCuenta(id) : RUTAS.editarCuenta(id), fd);
  },

  async darDeBaja(id) {
    if (USAR_DATOS_DE_PRUEBA) {
      const e = empleadosPrueba.find((x) => x.id_empleado === id);
      e.estatus_laboral = "Baja Logica";
      if (e.cuenta) e.cuenta.estatus_cuenta = false;
      return { ok: true, datos: { empleado: e } };
    }
    return peticionPost(RUTAS.baja(id), new FormData());
  },
};

/* =====================================================
   VALIDACIÓN Y ERRORES EN LOS FORMULARIOS
   ===================================================== */

function limpiarErrores(form) {
  form.querySelectorAll("[data-error-for]").forEach((el) => (el.textContent = ""));
  form.querySelectorAll("[aria-invalid]").forEach((el) => el.removeAttribute("aria-invalid"));
}

function mostrarErrores(form, errores) {
  let primerCampo = null;
  Object.entries(errores).forEach(([nombre, mensaje]) => {
    const destino = form.querySelector(`[data-error-for="${nombre}"]`)
                 || form.querySelector('[data-error-for="general"]');
    if (destino) destino.textContent = mensaje;
    const input = form.querySelector(`[name="${nombre}"]`);
    if (input) {
      input.setAttribute("aria-invalid", "true");
      if (!primerCampo) primerCampo = input;
    }
  });
  if (primerCampo) primerCampo.focus();
}

// Mismas reglas que validators.py del backend
function validarFormulario(form) {
  const errores = {};
  const campos = form.querySelectorAll("input[name], select[name]");

  campos.forEach((input) => {
    if (input.disabled || input.type === "hidden" || input.type === "checkbox") return;
    const valor = input.value.trim();
    const nombre = input.name;

    if (input.required && !valor) {
      errores[nombre] = "Este campo es obligatorio.";
      return;
    }
    if (!valor) return;

    if (nombre === "telefono_contacto" && !/^\d{10}$/.test(valor)) {
      errores[nombre] = "El teléfono debe tener 10 dígitos, sin espacios.";
    } else if (nombre === "numero_empleado" && !/^[A-Za-z0-9-]+$/.test(valor)) {
      errores[nombre] = "Usa solo letras, números y guiones (máximo 15).";
    } else if (["nombre_empleado", "apellido_paterno", "apellido_materno"].includes(nombre)
               && !/^[A-Za-zÁÉÍÓÚÜÑáéíóúüñ][A-Za-zÁÉÍÓÚÜÑáéíóúüñ .'-]*$/.test(valor)) {
      errores[nombre] = "Solo se permiten letras.";
    } else if (nombre === "fecha_ingreso" && valor > hoyISO()) {
      errores[nombre] = "La fecha de ingreso no puede ser futura.";
    } else if (nombre === "fecha_ingreso" && valor < "1990-01-01") {
      errores[nombre] = "La fecha de ingreso no es válida.";
    } else if (nombre === "correo" && !input.checkValidity()) {
      errores[nombre] = "Escribe un correo válido.";
    } else if (nombre === "contrasena" && valor.length < 8) {
      errores[nombre] = "La contraseña debe tener al menos 8 caracteres.";
    }
  });

  return errores;
}

function bloquearBoton(form, bloquear) {
  const boton = form.querySelector('button[type="submit"]');
  if (boton) boton.disabled = bloquear;
}

/* =====================================================
   TABLA, BÚSQUEDA Y FILTROS
   ===================================================== */

let empleados = [];

function empleadoPorId(id) {
  return empleados.find((e) => e.id_empleado === Number(id));
}

function pasaFiltros(e) {
  const texto = $("buscar").value.trim().toLowerCase();
  const estatus = $("filtro-estatus").value;
  const cuenta = $("filtro-cuenta").value;

  // Sin filtro de estatus se ocultan las bajas
  if (estatus === "" && e.estatus_laboral === "Baja Logica") return false;
  if (estatus !== "" && e.estatus_laboral !== estatus) return false;

  if (cuenta === "con" && !e.cuenta) return false;
  if (cuenta === "sin" && e.cuenta) return false;

  if (texto) {
    const buscable = [nombreCompleto(e), e.numero_empleado, e.puesto_trabajo,
                      e.cuenta ? e.cuenta.correo : "", e.cuenta ? e.cuenta.nombre_usuario : ""]
                      .join(" ").toLowerCase();
    if (!buscable.includes(texto)) return false;
  }
  return true;
}

function crearCelda(etiqueta, contenido) {
  const td = document.createElement("td");
  td.dataset.label = etiqueta;
  if (contenido instanceof Node) td.appendChild(contenido);
  else td.textContent = contenido;
  return td;
}

function crearBotonAccion(texto, href, accion, clase) {
  const a = document.createElement("a");
  a.href = href;
  a.className = `btn btn--small ${clase}`;
  a.dataset.accion = accion;
  a.textContent = texto;
  return a;
}

function crearFila(e) {
  const tr = document.createElement("tr");
  tr.dataset.id = e.id_empleado;

  // Celda de cuenta
  const cuenta = document.createDocumentFragment();
  if (e.cuenta) {
    const correo = document.createElement("span");
    correo.className = "cuenta__correo";
    correo.textContent = e.cuenta.correo;
    cuenta.appendChild(correo);
    cuenta.appendChild(crearBadge(e.cuenta.rol, "badge--role"));
    if (!e.cuenta.estatus_cuenta) cuenta.appendChild(crearBadge("Cuenta desactivada", "badge--inactive"));
  } else {
        // Atajo: abre "Asignar cuenta" con este empleado ya elegido (2 clics)
    if (e.estatus_laboral !== "Baja Logica") {
      const asignar = document.createElement("a");
      asignar.href = "#modal-crear";
      asignar.className = "badge badge--sin-cuenta";
      asignar.dataset.accion = "asignar";
      asignar.title = "Asignar cuenta de acceso";
      asignar.textContent = "Sin cuenta · Asignar";
      cuenta.appendChild(asignar);
    } else {
      cuenta.appendChild(crearBadge("Sin cuenta", "badge--sin-cuenta"));
    }
  }

  // Celda de acciones
  const acciones = crearCelda("Acciones", "");
  acciones.className = "data-table__actions";
  acciones.appendChild(crearBotonAccion("Ver", "#modal-ver", "ver", "btn--ghost"));
  if (e.estatus_laboral !== "Baja Logica") {
    acciones.appendChild(crearBotonAccion("Editar", "#modal-editar", "editar", "btn--secondary"));
    acciones.appendChild(crearBotonAccion("Dar de baja", "#modal-baja", "baja", "btn--danger"));
  }

  tr.append(
    crearCelda("Nº empleado", e.numero_empleado),
    crearCelda("Nombre", nombreCompleto(e)),
    crearCelda("Puesto", e.puesto_trabajo),
    crearCelda("Teléfono", formatearTelefono(e.telefono_contacto)),
    crearCelda("Ingreso", formatearFecha(e.fecha_ingreso)),
    crearCelda("Estatus", crearBadge(textoEstatus(e.estatus_laboral), claseEstatus(e.estatus_laboral))),
    crearCelda("Cuenta de acceso", cuenta),
    acciones
  );
  return tr;
}

function pintarTabla() {
  const tbody = $("tbody-empleados");
  const visibles = empleados
    .filter(pasaFiltros)
    .sort((a, b) => nombreCompleto(a).localeCompare(nombreCompleto(b), "es"));

  tbody.replaceChildren(...visibles.map(crearFila));

  const total = empleados.filter((e) => e.estatus_laboral !== "Baja Logica").length;
  $("contador-empleados").textContent =
    `Mostrando ${visibles.length} de ${total} empleado${total === 1 ? "" : "s"}`;
  $("tabla-vacia").hidden = visibles.length > 0;

  llenarSelectorExpedientes();
}

async function cargarEmpleados() {
  const { ok, datos } = await api.listar();
  if (!ok) {
    mostrarAviso(datos.error || "No se pudo cargar la lista de empleados.", "error");
    return;
  }
  empleados = datos.empleados || [];
  pintarTabla();
}

/* =====================================================
   MODAL: CREAR EMPLEADO / ASIGNAR CUENTA
   ===================================================== */

function llenarSelectorExpedientes() {
  const select = $("crear-expediente");
  const valorActual = select.value;
  const sinCuenta = empleados.filter((e) => !e.cuenta && e.estatus_laboral !== "Baja Logica");

  const opciones = [new Option("Crear empleado nuevo", "")];
  sinCuenta.forEach((e) => {
    opciones.push(new Option(`${e.numero_empleado} · ${nombreCompleto(e)} · sin cuenta de acceso`, e.id_empleado));
  });
  select.replaceChildren(...opciones);
  select.value = sinCuenta.some((e) => String(e.id_empleado) === valorActual) ? valorActual : "";
}

function prepararModalCrear() {
  const form = $("form-crear");
  form.reset();
  limpiarErrores(form);
  $("crear-seccion-empleado").disabled = false;
  $("crear-ingreso").max = hoyISO();
  $("titulo-crear").textContent = "Nuevo empleado";
}

// Al elegir un expediente existente, se rellenan sus datos y se bloquean
function alCambiarExpediente() {
  const form = $("form-crear");
  const seccion = $("crear-seccion-empleado");
  limpiarErrores(form);
  const e = empleadoPorId($("crear-expediente").value);

  if (!e) {
    seccion.disabled = false;
    seccion.querySelectorAll("input").forEach((i) => (i.value = ""));
    $("crear-estatus").value = "Activo";
    $("titulo-crear").textContent = "Nuevo empleado";
    return;
  }

  $("crear-numero").value = e.numero_empleado;
  $("crear-puesto").value = e.puesto_trabajo;
  $("crear-nombre").value = e.nombre_empleado;
  $("crear-paterno").value = e.apellido_paterno;
  $("crear-materno").value = e.apellido_materno || "";
  $("crear-telefono").value = e.telefono_contacto || "";
  $("crear-ingreso").value = e.fecha_ingreso;
  $("crear-estatus").value = e.estatus_laboral === "Inactivo" ? "Inactivo" : "Activo";
  seccion.disabled = true;  // un fieldset deshabilitado no se envía
  $("titulo-crear").textContent = "Asignar cuenta de acceso";
  $("crear-usuario").focus();
}

async function alEnviarCrear(evento) {
  evento.preventDefault();
  const form = $("form-crear");
  limpiarErrores(form);

  const errores = validarFormulario(form);
  if (Object.keys(errores).length) return mostrarErrores(form, errores);

  bloquearBoton(form, true);
  const fd = new FormData(form);
  const idExistente = Number($("crear-expediente").value) || null;
  let idEmpleado = idExistente;

  // 1. Si es nuevo, primero se crea el expediente
  if (!idExistente) {
    const r = await api.crearEmpleado(fd);
    if (!r.ok) {
      bloquearBoton(form, false);
      return mostrarErrores(form, r.datos.errores || { general: r.datos.error || "No se pudo guardar el empleado." });
    }
    idEmpleado = r.datos.empleado.id_empleado;
  }

  // 2. Después se crea su cuenta de acceso
  const rc = await api.guardarCuenta(idEmpleado, fd, true);
  bloquearBoton(form, false);

  if (!rc.ok) {
    await cargarEmpleados();
    if (!idExistente) {
      // El expediente sí se guardó: se cambia al modo "asignar cuenta" para reintentar
      $("crear-expediente").value = idEmpleado;
      alCambiarExpediente();
    }
    return mostrarErrores(form, rc.datos.errores || { general: rc.datos.error || "No se pudo crear la cuenta." });
  }

  cerrarModal();
  mostrarAviso(idExistente ? "Cuenta de acceso asignada." : "Empleado y cuenta creados.");
  await cargarEmpleados();
}

/* =====================================================
   MODAL: EDITAR EMPLEADO Y CUENTA
   ===================================================== */

const CAMPOS_CUENTA_EDITAR = ["editar-usuario", "editar-correo", "editar-rol", "editar-password"];

function prepararModalEditar(e) {
  const form = $("form-editar");
  form.reset();
  limpiarErrores(form);

  $("editar-id").value = e.id_empleado;
  $("editar-numero").value = e.numero_empleado;
  $("editar-puesto").value = e.puesto_trabajo;
  $("editar-nombre").value = e.nombre_empleado;
  $("editar-paterno").value = e.apellido_paterno;
  $("editar-materno").value = e.apellido_materno || "";
  $("editar-telefono").value = e.telefono_contacto || "";
  $("editar-ingreso").value = e.fecha_ingreso;
  $("editar-ingreso").max = hoyISO();
  $("editar-estatus").value = e.estatus_laboral === "Inactivo" ? "Inactivo" : "Activo";

  const tieneCuenta = Boolean(e.cuenta);
  form.dataset.tieneCuenta = tieneCuenta ? "1" : "0";
  $("editar-leyenda-cuenta").textContent = tieneCuenta ? "Cuenta de acceso" : "Crear cuenta de acceso (opcional)";
  $("editar-cuenta-activa").closest(".form__group").hidden = !tieneCuenta;

  if (tieneCuenta) {
    $("editar-usuario").value = e.cuenta.nombre_usuario;
    $("editar-correo").value = e.cuenta.correo;
    $("editar-rol").value = e.cuenta.rol;
    $("editar-cuenta-activa").checked = Boolean(e.cuenta.estatus_cuenta);
    $("editar-usuario").required = true;
    $("editar-correo").required = true;
    $("editar-password").required = false;
  } else {
    // Sin cuenta: los campos son opcionales hasta que se escriba algo
    CAMPOS_CUENTA_EDITAR.forEach((id) => ($(id).required = false));
  }
  $("editar-password").value = "";  // nunca se precarga
}

async function alEnviarEditar(evento) {
  evento.preventDefault();
  const form = $("form-editar");
  limpiarErrores(form);

  const id = Number($("editar-id").value);
  const tieneCuenta = form.dataset.tieneCuenta === "1";
  const quiereCrearCuenta = !tieneCuenta &&
    ["editar-usuario", "editar-correo", "editar-password"].some((c) => $(c).value.trim() !== "");

  // Si va a crear cuenta, todos sus campos se vuelven obligatorios
  if (quiereCrearCuenta) CAMPOS_CUENTA_EDITAR.forEach((c) => ($(c).required = true));

  const errores = validarFormulario(form);
  if (!quiereCrearCuenta && !tieneCuenta) {
    ["nombre_usuario", "correo", "contrasena"].forEach((c) => delete errores[c]);
  }
  if (quiereCrearCuenta) CAMPOS_CUENTA_EDITAR.forEach((c) => ($(c).required = false));
  if (Object.keys(errores).length) return mostrarErrores(form, errores);

  bloquearBoton(form, true);
  const fd = new FormData(form);
  if (!$("editar-password").value) fd.delete("contrasena");  // vacía = conservar la actual
  if (tieneCuenta) fd.set("estatus_cuenta", $("editar-cuenta-activa").checked ? "1" : "0");

  // 1. Datos del expediente
  const r = await api.editarEmpleado(id, fd);
  if (!r.ok) {
    bloquearBoton(form, false);
    return mostrarErrores(form, r.datos.errores || { general: r.datos.error || "No se pudo actualizar el empleado." });
  }

  // 2. Cuenta de acceso (editar la existente o crear una nueva)
  if (tieneCuenta || quiereCrearCuenta) {
    const rc = await api.guardarCuenta(id, fd, quiereCrearCuenta);
    if (!rc.ok) {
      bloquearBoton(form, false);
      await cargarEmpleados();
      return mostrarErrores(form, rc.datos.errores || { general: rc.datos.error || "No se pudo guardar la cuenta." });
    }
  }

  bloquearBoton(form, false);
  cerrarModal();
  mostrarAviso("Cambios guardados.");
  await cargarEmpleados();
}

/* =====================================================
   MODAL: VER DETALLE
   ===================================================== */

function prepararModalVer(e) {
  $("ver-numero").textContent = e.numero_empleado;
  $("ver-nombre").textContent = nombreCompleto(e);
  $("ver-puesto").textContent = e.puesto_trabajo;
  $("ver-telefono").textContent = formatearTelefono(e.telefono_contacto);
  $("ver-ingreso").textContent = formatearFecha(e.fecha_ingreso);
  $("ver-estatus").textContent = textoEstatus(e.estatus_laboral);

  $("ver-usuario").textContent = e.cuenta ? e.cuenta.nombre_usuario : "—";
  $("ver-correo").textContent = e.cuenta ? e.cuenta.correo : "—";
  $("ver-rol").textContent = e.cuenta ? e.cuenta.rol : "—";
  $("ver-cuenta-estado").textContent = !e.cuenta ? "Sin cuenta de acceso"
    : e.cuenta.estatus_cuenta ? "Activa" : "Desactivada";
}

/* =====================================================
   MODAL: DAR DE BAJA
   ===================================================== */

function prepararModalBaja(e) {
  const form = $("form-baja");
  limpiarErrores(form);
  $("baja-id").value = e.id_empleado;
  $("baja-nombre").textContent = nombreCompleto(e);
}

async function alEnviarBaja(evento) {
  evento.preventDefault();
  const form = $("form-baja");
  limpiarErrores(form);
  bloquearBoton(form, true);

  const { ok, datos } = await api.darDeBaja(Number($("baja-id").value));
  bloquearBoton(form, false);

  if (!ok) return mostrarErrores(form, { general: datos.error || "No se pudo dar de baja al empleado." });

  cerrarModal();
  mostrarAviso("Empleado dado de baja. Su cuenta quedó desactivada.");
  await cargarEmpleados();
}

/* =====================================================
   EVENTOS
   ===================================================== */

document.addEventListener("DOMContentLoaded", () => {

  // Si la página se recarga con un modal abierto, se cierra
  if (window.location.hash.startsWith("#modal-")) cerrarModal();

  // Botones de la tabla: se llenan los datos ANTES de que se abra el modal
  $("tabla-empleados").addEventListener("click", (evento) => {
    const boton = evento.target.closest("[data-accion]");
    if (!boton) return;
    const e = empleadoPorId(boton.closest("tr").dataset.id);
    if (!e) { evento.preventDefault(); return; }

    if (boton.dataset.accion === "ver") prepararModalVer(e);
    if (boton.dataset.accion === "editar") prepararModalEditar(e);
    if (boton.dataset.accion === "baja") prepararModalBaja(e);
    // El enlace (href="#modal-...") abre el modal por sí solo
    if (boton.dataset.accion === "asignar") {
      prepararModalCrear();
      $("crear-expediente").value = e.id_empleado;
      alCambiarExpediente();
      setTimeout(() => $("crear-usuario").focus(), 50);  // foco cuando el modal ya se ve
    }
  });

  // Botón "+ Nuevo empleado"
  document.querySelector('a[href="#modal-crear"]').addEventListener("click", prepararModalCrear);
  $("crear-expediente").addEventListener("change", alCambiarExpediente);

  // Formularios
  $("form-crear").addEventListener("submit", alEnviarCrear);
  $("form-editar").addEventListener("submit", alEnviarEditar);
  $("form-baja").addEventListener("submit", alEnviarBaja);

  // Al corregir un campo, se quita su mensaje de error
  document.querySelectorAll(".modal form").forEach((form) => {
    form.addEventListener("input", (evento) => {
      const campo = evento.target;
      if (!campo.name) return;
      campo.removeAttribute("aria-invalid");
      const error = form.querySelector(`[data-error-for="${campo.name}"]`);
      if (error) error.textContent = "";
    });
  });

  // El teléfono solo acepta dígitos
  ["crear-telefono", "editar-telefono"].forEach((id) => {
    $(id).addEventListener("input", (evento) => {
      evento.target.value = evento.target.value.replace(/\D/g, "").slice(0, 10);
    });
  });

  // Búsqueda y filtros
  $("buscar").addEventListener("input", pintarTabla);
  $("filtro-estatus").addEventListener("change", pintarTabla);
  $("filtro-cuenta").addEventListener("change", pintarTabla);

  // Tecla Esc cierra el modal abierto
  document.addEventListener("keydown", (evento) => {
    if (evento.key === "Escape" && window.location.hash.startsWith("#modal-")) cerrarModal();
  });

  cargarEmpleados();
});
