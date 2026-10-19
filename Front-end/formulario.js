
document.addEventListener("DOMContentLoaded", function () {
    const formulario = document.getElementById("loginForm");

    if (formulario) {
        formulario.addEventListener("submit", function (event) {
            event.preventDefault();

            if (typeof handleLogin === "function") {
                handleLogin();
            }
        });
    }
});
