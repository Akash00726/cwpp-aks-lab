import os
from flask import Flask, render_template
import socket
app_name = os.getenv("APP_NAME", "Default App")
app_env = os.getenv("APP_ENV", "Development")
app_version = os.getenv("APP_VERSION", "1.0")
log_level = os.getenv("LOG_LEVEL", "INFO")
app = Flask(__name__)

@app.route("/")
def home():
    return render_template(
        "index.html",
        hostname=socket.gethostname(),
        app_name=app_name,
        app_env=app_env,
        app_version=app_version,
        log_level=log_level
    )

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)