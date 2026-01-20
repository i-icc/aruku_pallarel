import logging
import os

from flask import Flask, jsonify, request

app = Flask(__name__)

logging.basicConfig(level=os.getenv("LOG_LEVEL", "INFO"))

PORT = int(os.getenv("PORT", "8080"))


@app.get("/")
def index():
    return jsonify(service="osm-stub", status="ok")


@app.get("/health")
def health():
    return jsonify(status="ok")


@app.post("/nearest")
def nearest():
    payload = request.get_json(silent=True) or {}
    lat = payload.get("lat")
    lon = payload.get("lon")
    if not isinstance(lat, (int, float)) or not isinstance(lon, (int, float)):
        return jsonify(error="lat/lon required"), 400
    return jsonify(lat=lat, lon=lon, distance_m=0)


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=PORT)
