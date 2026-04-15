from flask import Flask, jsonify, request
import os

app = Flask(__name__)

SECRETS = {
    "keycloak/app-x-service": {
        "client_id": os.getenv("KEYCLOAK_APP_X_CLIENT_ID", "app-x-service"),
        "client_secret": os.getenv("KEYCLOAK_APP_X_CLIENT_SECRET", "app-x-secret-123"),
        "token_url": os.getenv("KEYCLOAK_TOKEN_URL", "http://keycloak:8080/realms/machine-realm/protocol/openid-connect/token"),
    },
    "app-z/base-url": {
        "base_url": os.getenv("APP_Z_BASE_URL", "http://app-z:5002"),
        "resource_path": "/secure-data",
    },
}


@app.get("/health")
def health():
    return {"status": "ok", "service": "passbolt-mock"}


@app.get("/secrets/<path:secret_path>")
def get_secret(secret_path):
    access_token = request.headers.get("X-Passbolt-Token", "")
    expected_token = os.getenv("PASSBOLT_ACCESS_TOKEN", "passbolt-demo-token")

    if access_token != expected_token:
        return jsonify({"error": "unauthorized"}), 401

    secret = SECRETS.get(secret_path)
    if not secret:
        return jsonify({"error": "secret_not_found"}), 404

    return jsonify(secret)


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5001)
