from flask import Flask, jsonify, render_template
from json import JSONDecodeError
from urllib.parse import unquote_plus
import json
import os

import pgpy
import requests

app = Flask(__name__)

PASSBOLT_BASE_URL = os.getenv("PASSBOLT_BASE_URL", "http://passbolt-real")
PASSBOLT_SERVICE_KEY_ID = os.getenv("PASSBOLT_SERVICE_KEY_ID", "")
PASSBOLT_PRIVATE_KEY = os.getenv("PASSBOLT_PRIVATE_KEY", "")
PASSBOLT_PRIVATE_KEY_FILE = os.getenv("PASSBOLT_PRIVATE_KEY_FILE", "")
PASSBOLT_PRIVATE_KEY_PASSPHRASE = os.getenv("PASSBOLT_PRIVATE_KEY_PASSPHRASE", "")
PASSBOLT_SECRET_RESOURCE_ID = os.getenv("PASSBOLT_SECRET_RESOURCE_ID", "")


def load_private_key():
    key_blob = PASSBOLT_PRIVATE_KEY
    if not key_blob and PASSBOLT_PRIVATE_KEY_FILE:
        with open(PASSBOLT_PRIVATE_KEY_FILE, "r", encoding="utf-8") as key_file:
            key_blob = key_file.read()

    if not key_blob:
        raise ValueError("PASSBOLT_PRIVATE_KEY is not configured")

    key, _ = pgpy.PGPKey.from_blob(key_blob)
    return key


def decrypt_user_auth_token(encoded_token):
    armored_token = unquote_plus(encoded_token.replace("\\", ""))
    message = pgpy.PGPMessage.from_blob(armored_token)
    private_key = load_private_key()

    if PASSBOLT_PRIVATE_KEY_PASSPHRASE:
        with private_key.unlock(PASSBOLT_PRIVATE_KEY_PASSPHRASE):
            decrypted = private_key.decrypt(message)
    else:
        decrypted = private_key.decrypt(message)

    clear_value = getattr(decrypted, "message", str(decrypted))
    if isinstance(clear_value, (bytes, bytearray)):
        return clear_value.decode("utf-8")
    return str(clear_value)


def passbolt_login(session):
    if not PASSBOLT_SERVICE_KEY_ID:
        raise ValueError("PASSBOLT_SERVICE_KEY_ID is not configured")

    stage0 = session.post(
        f"{PASSBOLT_BASE_URL}/auth/login.json",
        json={"data": {"gpg_auth": {"keyid": PASSBOLT_SERVICE_KEY_ID}}},
        timeout=10,
    )
    stage0.raise_for_status()

    user_auth_token = stage0.headers.get("X-GPGAuth-User-Auth-Token")
    if not user_auth_token:
        raise ValueError("Passbolt did not return X-GPGAuth-User-Auth-Token")

    user_token_result = decrypt_user_auth_token(user_auth_token)

    stage1 = session.post(
        f"{PASSBOLT_BASE_URL}/auth/login.json",
        json={
            "data": {
                "gpg_auth": {
                    "keyid": PASSBOLT_SERVICE_KEY_ID,
                    "user_token_result": user_token_result,
                }
            }
        },
        timeout=10,
    )
    stage1.raise_for_status()


def get_real_secret(session, resource_id):
    response = session.get(f"{PASSBOLT_BASE_URL}/secrets/resource/{resource_id}.json", timeout=10)
    response.raise_for_status()
    payload = response.json()

    if isinstance(payload, dict) and "body" in payload and isinstance(payload["body"], dict):
        payload = payload["body"]

    if isinstance(payload, dict) and "data" in payload:
        data = payload["data"]
        if isinstance(data, dict):
            return data
        if isinstance(data, str):
            if data.strip().startswith("-----BEGIN PGP MESSAGE-----"):
                private_key = load_private_key()
                encrypted_message = pgpy.PGPMessage.from_blob(data)
                if PASSBOLT_PRIVATE_KEY_PASSPHRASE:
                    with private_key.unlock(PASSBOLT_PRIVATE_KEY_PASSPHRASE):
                        decrypted_message = private_key.decrypt(encrypted_message)
                else:
                    decrypted_message = private_key.decrypt(encrypted_message)

                clear_value = getattr(decrypted_message, "message", str(decrypted_message))
                if isinstance(clear_value, (bytes, bytearray)):
                    clear_value = clear_value.decode("utf-8")

                return json.loads(str(clear_value))

            try:
                return json.loads(data)
            except JSONDecodeError:
                return {"data": data}

    if isinstance(payload, dict):
        return payload

    raise ValueError("Unsupported Passbolt secret payload")


def extract_service_settings(secret_payload):
    if not isinstance(secret_payload, dict):
        raise ValueError("Passbolt secret must be a JSON object")

    if "keycloak" in secret_payload or "app_z" in secret_payload:
        keycloak_settings = secret_payload.get("keycloak", {})
        app_z_settings = secret_payload.get("app_z", {})
    else:
        keycloak_settings = secret_payload
        app_z_settings = secret_payload

    settings = {
        "keycloak": {
            "client_id": keycloak_settings.get("client_id") or keycloak_settings.get("keycloak_client_id"),
            "client_secret": keycloak_settings.get("client_secret") or keycloak_settings.get("keycloak_client_secret"),
            "token_url": keycloak_settings.get("token_url") or keycloak_settings.get("keycloak_token_url"),
        },
        "app_z": {
            "base_url": app_z_settings.get("base_url") or app_z_settings.get("app_z_base_url"),
            "resource_path": app_z_settings.get("resource_path") or app_z_settings.get("app_z_resource_path", "/secure-data"),
        },
    }

    missing_fields = []
    for section_name, section in settings.items():
        for field_name, field_value in section.items():
            if not field_value:
                missing_fields.append(f"{section_name}.{field_name}")

    if missing_fields:
        raise ValueError(f"Missing required secret fields: {', '.join(missing_fields)}")

    return settings


@app.get("/health")
def health():
    return {"status": "ok", "service": "app-x"}


@app.get("/")
def home():
    return render_template("index.html")


@app.get("/login-and-consume-z")
def login_and_consume_z():
    try:
        if not PASSBOLT_SECRET_RESOURCE_ID:
            raise ValueError("PASSBOLT_SECRET_RESOURCE_ID is not configured")

        session = requests.Session()
        passbolt_login(session)
        secret_payload = get_real_secret(session, PASSBOLT_SECRET_RESOURCE_ID)
        settings = extract_service_settings(secret_payload)

        token_response = requests.post(
            settings["keycloak"]["token_url"],
            data={
                "grant_type": "client_credentials",
                "client_id": settings["keycloak"]["client_id"],
                "client_secret": settings["keycloak"]["client_secret"],
            },
            timeout=10,
        )
        token_response.raise_for_status()
        access_token = token_response.json().get("access_token")

        if not access_token:
            return jsonify({"error": "token_not_received"}), 500

        app_z_url = f"{settings['app_z']['base_url']}{settings['app_z']['resource_path']}"
        z_response = requests.get(
            app_z_url,
            headers={"Authorization": f"Bearer {access_token}"},
            timeout=10,
        )

        return jsonify(
            {
                "flow": "passbolt-real -> keycloak -> app-z",
                "app_z_status_code": z_response.status_code,
                "app_z_response": z_response.json(),
            }
        ), z_response.status_code

    except ValueError as exc:
        return jsonify({"error": "configuration_error", "details": str(exc)}), 500
    except requests.HTTPError as exc:
        status_code = exc.response.status_code if exc.response is not None else 500
        body = exc.response.text if exc.response is not None else str(exc)
        return jsonify({"error": "http_error", "details": body}), status_code
    except Exception as exc:
        return jsonify({"error": "unexpected_error", "details": str(exc)}), 500


@app.get("/flow/detailed")
def flow_detailed():
    steps = []
    try:
        if not PASSBOLT_SECRET_RESOURCE_ID:
            raise ValueError("PASSBOLT_SECRET_RESOURCE_ID is not configured")

        session = requests.Session()
        passbolt_login(session)
        steps.append({
            "step": 1, "name": "Autenticación en Passbolt", "status": "ok",
            "detail": f"Cuenta de servicio autenticada con GPG · Fingerprint: {PASSBOLT_SERVICE_KEY_ID[:16]}…",
        })

        secret_payload = get_real_secret(session, PASSBOLT_SECRET_RESOURCE_ID)
        settings = extract_service_settings(secret_payload)
        steps.append({
            "step": 2, "name": "Secreto leído y descifrado", "status": "ok",
            "detail": f"Recurso: {PASSBOLT_SECRET_RESOURCE_ID[:8]}… · client_id: {settings['keycloak']['client_id']}",
        })

        token_response = requests.post(
            settings["keycloak"]["token_url"],
            data={
                "grant_type": "client_credentials",
                "client_id": settings["keycloak"]["client_id"],
                "client_secret": settings["keycloak"]["client_secret"],
            },
            timeout=10,
        )
        token_response.raise_for_status()
        access_token = token_response.json().get("access_token", "")
        steps.append({
            "step": 3, "name": "Token obtenido de Keycloak", "status": "ok",
            "detail": f"Bearer {access_token[:28]}…",
        })

        app_z_url = f"{settings['app_z']['base_url']}{settings['app_z']['resource_path']}"
        z_response = requests.get(
            app_z_url,
            headers={"Authorization": f"Bearer {access_token}"},
            timeout=10,
        )
        z_json = z_response.json()
        steps.append({
            "step": 4, "name": "App Z respondió", "status": "ok" if z_response.status_code == 200 else "error",
            "detail": f"HTTP {z_response.status_code} · authorized_client: {z_json.get('authorized_client', '—')}",
        })

        return jsonify({"steps": steps, "final_status": z_response.status_code, "final_response": z_json})

    except Exception as exc:
        steps.append({"step": len(steps) + 1, "name": "Error en el flujo", "status": "error", "detail": str(exc)})
        return jsonify({"steps": steps, "final_status": 500, "final_response": {"error": str(exc)}}), 500


@app.get("/flow/invalid-token")
def flow_invalid_token():
    fake_token = "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.PAYLOAD_FALSO.FIRMA_INVALIDA"
    steps = [
        {
            "step": 1, "name": "Passbolt omitido (simulación de ataque)", "status": "warn",
            "detail": "Se construye un Bearer token falso sin pasar por Passbolt ni Keycloak",
        },
        {
            "step": 2, "name": "Token inválido construido manualmente", "status": "warn",
            "detail": f"Bearer {fake_token[:36]}…",
        },
    ]
    try:
        z_response = requests.get(
            "http://app-z:5002/secure-data",
            headers={"Authorization": f"Bearer {fake_token}"},
            timeout=10,
        )
        z_json = z_response.json()
        steps.append({
            "step": 3, "name": "Respuesta de App Z",
            "status": "error" if z_response.status_code != 200 else "ok",
            "detail": f"HTTP {z_response.status_code} · {next(iter(z_json.values()), '')}",
        })
        return jsonify({"steps": steps, "final_status": z_response.status_code, "final_response": z_json}), z_response.status_code
    except Exception as exc:
        steps.append({"step": 3, "name": "Error de red", "status": "error", "detail": str(exc)})
        return jsonify({"steps": steps, "final_status": 500, "final_response": {"error": str(exc)}}), 500


@app.get("/flow/no-token")
def flow_no_token():
    steps = [
        {
            "step": 1, "name": "Acceso directo a App Z sin token", "status": "warn",
            "detail": "Petición a /secure-data sin cabecera Authorization",
        }
    ]
    try:
        z_response = requests.get("http://app-z:5002/secure-data", timeout=10)
        z_json = z_response.json()
        steps.append({
            "step": 2, "name": "Respuesta de App Z",
            "status": "error" if z_response.status_code != 200 else "ok",
            "detail": f"HTTP {z_response.status_code} · {next(iter(z_json.values()), '')}",
        })
        return jsonify({"steps": steps, "final_status": z_response.status_code, "final_response": z_json}), z_response.status_code
    except Exception as exc:
        steps.append({"step": 2, "name": "Error de red", "status": "error", "detail": str(exc)})
        return jsonify({"steps": steps, "final_status": 500, "final_response": {"error": str(exc)}}), 500


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
