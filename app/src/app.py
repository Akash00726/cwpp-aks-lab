from flask import Flask, render_template
from datetime import datetime
import os

app = Flask(__name__)

@app.route("/")
def home():
    return render_template(
        "index.html",
        current_date=datetime.now().strftime("%d-%b-%Y %H:%M:%S"),
        hostname=os.getenv("HOSTNAME", "Unknown"),
        app_name=os.getenv("APP_NAME", "CWPP Lab"),
        app_env=os.getenv("APP_ENV", "Development"),
        app_version=os.getenv("APP_VERSION", "1.0"),
        git_commit=os.getenv("GIT_COMMIT", "N/A"),
        image_tag=os.getenv("IMAGE_TAG", "N/A"),
        namespace=os.getenv("NAMESPACE", "Unknown"),
        node_name=os.getenv("NODE_NAME", "Unknown")
    )

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)