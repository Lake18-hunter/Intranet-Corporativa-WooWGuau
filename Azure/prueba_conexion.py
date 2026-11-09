"""
Post-condición (Tarea: Configurar servidor MySQL en Microsoft Azure):
verifica que el servidor recibe comandos SQL desde Python.

El servidor tiene acceso privado: este script se ejecuta dentro de la VNet,
en la VM cliente, mediante 03_vm_cliente_python.sh. Las credenciales llegan
como variables de entorno; nunca están escritas aquí.
"""
import os
import sys

import mysql.connector


def ruta_ca():
    """Certificados raíz para validar el TLS del servidor."""
    if os.environ.get("MYSQL_SSL_CA"):
        return os.environ["MYSQL_SSL_CA"]
    try:
        import certifi
        return certifi.where()
    except ImportError:
        return "/etc/ssl/certs/ca-certificates.crt"  # Ubuntu


config = {
    "host": os.environ.get(
        "MYSQL_HOST", f"{os.environ['MYSQL_SERVER_NAME']}.mysql.database.azure.com"
    ),
    "port": 3306,
    "user": os.environ["MYSQL_ADMIN_USER"],
    "password": os.environ["MYSQL_ADMIN_PASSWORD"],
    "database": os.environ["MYSQL_DATABASE"],
    "ssl_ca": ruta_ca(),
    "ssl_verify_cert": True,
    "connection_timeout": 15,
}

try:
    conexion = mysql.connector.connect(**config)
except mysql.connector.Error as err:
    print(f"No se pudo conectar: {err}")
    print("Revisa que la VM esté en snet-app y que la NSG permita 3306 desde esa subred.")
    sys.exit(1)

cursor = conexion.cursor()

cursor.execute("SELECT VERSION(), CURRENT_USER()")
version, usuario = cursor.fetchone()
print(f"Conectado a MySQL {version} como {usuario} (host {config['host']})")

cursor.execute("SHOW STATUS LIKE 'Ssl_cipher'")
print(f"Cifrado TLS de la sesión: {cursor.fetchone()[1] or 'SIN TLS'}")

cursor.execute(
    """
    CREATE TABLE IF NOT EXISTS prueba_conexion (
        id INT AUTO_INCREMENT PRIMARY KEY,
        mensaje VARCHAR(100) NOT NULL,
        creado TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )
    """
)
cursor.execute(
    "INSERT INTO prueba_conexion (mensaje) VALUES (%s)",
    ("Conexión desde Python correcta",),
)
conexion.commit()

cursor.execute("SELECT id, mensaje, creado FROM prueba_conexion ORDER BY id DESC LIMIT 3")
print("\nÚltimos registros:")
for fila in cursor.fetchall():
    print(f"  {fila[0]} | {fila[1]} | {fila[2]}")

cursor.close()
conexion.close()
print("\nPrueba terminada: el servidor recibe comandos SQL desde Python.")
