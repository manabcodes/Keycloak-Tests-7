from flask import Flask, jsonify, request
import os
import requests

app = Flask(__name__)

KEYCLOAK_INTROSPECTION_URL = os.getenv(
    "KEYCLOAK_INTROSPECTION_URL",
    "http://keycloak:8080/realms/machine-realm/protocol/openid-connect/token/introspect",
)
INTROSPECTION_CLIENT_ID = os.getenv("INTROSPECTION_CLIENT_ID", "app-z-api")
INTROSPECTION_CLIENT_SECRET = os.getenv("INTROSPECTION_CLIENT_SECRET", "app-z-secret-123")
REQUIRED_CLIENT_ID = os.getenv("REQUIRED_CLIENT_ID", "app-x-service")


@app.get("/health")
def health():
    return {"status": "ok", "service": "app-z"}


@app.get("/secure-data")
def secure_data():
    auth_header = request.headers.get("Authorization", "")
    if not auth_header.startswith("Bearer "):
        return jsonify({"error": "missing_bearer_token"}), 401

    token = auth_header.replace("Bearer ", "", 1)

    introspection_response = requests.post(
        KEYCLOAK_INTROSPECTION_URL,
        data={"token": token},
        auth=(INTROSPECTION_CLIENT_ID, INTROSPECTION_CLIENT_SECRET),
        timeout=10,
    )

    if introspection_response.status_code != 200:
        return jsonify({"error": "introspection_failed"}), 401

    token_data = introspection_response.json()

    if not token_data.get("active"):
        return jsonify({"error": "token_inactive"}), 401

    if token_data.get("client_id") != REQUIRED_CLIENT_ID:
        return jsonify({"error": "invalid_client_for_resource"}), 403

    return jsonify(
        {
            "message": "Datos protegidos de la aplicacion Z",
            "authorized_client": token_data.get("client_id"),
            "scope": token_data.get("scope", ""),
        }
    )


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5002)
