from flask import Flask, jsonify
import socket, os, time

app = Flask(__name__)
START_TIME = time.time()

@app.route("/")
def home():
    return jsonify({
        "message": "Hello from the GitOps EKS platform!",
        "hostname": socket.gethostname(),
        "version": os.getenv("APP_VERSION", "dev"),
    })

@app.route("/healthz")
def healthz():
    return jsonify({"status": "ok"}), 200

@app.route("/readyz")
def readyz():
    # Simulate real readiness: not ready in first 5s after boot
    if time.time() - START_TIME < 5:
        return jsonify({"status": "starting"}), 503
    return jsonify({"status": "ready"}), 200

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080)
