
document.addEventListener("DOMContentLoaded", function () {

    // Elementos principales
    const tabla = document.getElementById("tabla-empleados");
    const formulario = document.getElementById("form-editar");
    const modal = document.getElementById("modal-editar");

    if (!tabla || !formulario || !modal) {
        console.error("No se encontró la tabla, el formulario o el modal de edición.");
        return;
    }

    // Crear los campos que faltan en el HTML
    const grid = formulario.querySelector(".form__grid");

    function crearCampo(id, etiqueta, tipo) {
        let campo = document.getElementById(id);

        if (campo) return campo;

        const grupo = document.createElement("div");
        grupo.className = "form__group";

        const label = document.createElement("label");
        label.htmlFor = id;
        label.textContent = etiqueta;

        campo = document.createElement("input");
        campo.type = tipo;
        campo.id = id;
        campo.name = id.replace("editar-", "");

        if (tipo === "number") {
            campo.min = "0";
            campo.step = "1";
        }

        grupo.appendChild(label);
        grupo.appendChild(campo);

        if (grid) {
            grid.appendChild(grupo);
        }

        return campo;
    }

    const horario = crearCampo("editar-horario", "Horario", "text");
    const edad = crearCampo("editar-edad", "Edad", "number");
    const direccion = crearCampo("editar-direccion", "Dirección", "text");
    const telefono = crearCampo("editar-telefono", "Teléfono", "tel");

    // Obtener un campo por su identificador
    function campo(id) {
        return document.getElementById(id);
    }

    // Cargar los datos del empleado seleccionado
    function cargarEmpleado(fila) {
        const celdas = fila.querySelectorAll("td");

        if (celdas.length < 7) {
            console.error("La fila no contiene todos los datos del empleado.");
            return;
        }

        campo("editar-id").value = celdas[0].textContent.trim();
        campo("editar-nombre").value = celdas[1].textContent.trim();
        campo("editar-correo").value = celdas[2].textContent.trim();
        campo("editar-puesto").value = celdas[3].textContent.trim();
        campo("editar-depto").value = celdas[4].textContent.trim();

        const rol = celdas[5].textContent.trim().toLowerCase();
        campo("editar-rol").value =
            rol.includes("administrador") ? "administrador" : "empleado";

        const estado = celdas[6].textContent.trim().toLowerCase();
        campo("editar-estado").value =
            estado.includes("inactivo") ? "inactivo" : "activo";

        // Estos datos no están en la tabla actual, así que empiezan vacíos.
        horario.value = "";
        edad.value = "";
        direccion.value = "";
        telefono.value = "";
    }

    // Abrir el modal al pulsar Editar
    tabla.addEventListener("click", function (event) {
        const boton = event.target.closest('a[href="#modal-editar"]');

        if (!boton) return;

        event.preventDefault();

        const fila = boton.closest("tr");

        if (!fila) return;

        cargarEmpleado(fila);

        window.location.hash = "modal-editar";
    });

    // Preparar los datos al enviar el formulario
    formulario.addEventListener("submit", function (event) {
        event.preventDefault();

        if (!formulario.reportValidity()) {
            return;
        }

        const empleadoActualizado = {
            id: campo("editar-id").value.trim(),
            nombre: campo("editar-nombre").value.trim(),
            correo: campo("editar-correo").value.trim(),
            puesto: campo("editar-puesto").value.trim(),
            departamento: campo("editar-depto").value,
            rol: campo("editar-rol").value,
            estado: campo("editar-estado").value,
            horario: horario.value.trim(),
            edad: edad.value,
            direccion: direccion.value.trim(),
            telefono: telefono.value.trim()
        };

        // Mostrar los datos preparados para comprobar el funcionamiento.
        console.log("Datos del empleado preparados:", empleadoActualizado);

        alert("Los datos se prepararon correctamente. Todavía no se enviaron al servidor.");

        // Cerrar el modal sin guardar cambios permanentes.
        window.location.hash = "panel_admin";
    });

    // Limpiar el formulario cuando se cancela o se cierra el modal.
    modal.querySelectorAll('a[href="#panel_admin"]').forEach(function (enlace) {
        enlace.addEventListener("click", function () {
            setTimeout(function () {
                formulario.reset();
            }, 0);
        });
    });

    console.log("panel_admin.js se cargó correctamente.");

});
