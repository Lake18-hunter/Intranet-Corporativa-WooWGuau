document.addEventListener("DOMContentLoaded", function () {
    const formulario = document.getElementById("loginForm");
    if (!formulario) return;

    formulario.addEventListener("submit", function (event) {
        const correo = formulario.elements["correo"].value.trim();
        const contrasena = formulario.elements["contrasena"].value;

        // Solo se detiene el envío si falta algún dato; si todo está lleno, el formulario viaja a Django
       if (!correo || !contrasena) {
    event.preventDefault();
    const msg = document.getElementById("statusMessage");
    msg.className = "status-message error";
    msg.style.display = "block";
    msg.textContent = "Escribe tu correo y tu contraseña.";
}
    });
});