import os
from flask import Flask
import redis

app = Flask(__name__)

REDIS_HOST = os.environ.get("REDIS_HOST", "localhost")
REDIS_PORT = int(os.environ.get("REDIS_PORT", 6379))

try:
    r = redis.Redis(host=REDIS_HOST, port=REDIS_PORT)
    r.ping()
    redis_status = "Connected"
except Exception as e:
    redis_status = f"Error connecting to Redis: {e}"


@app.route("/")
def hello():
    return f"Hello, World! This app is running. Redis Status: {redis_status}"


if __name__ == "__main__":
    # Changed host to 0.0.0.0 to allow external connections
    app.run(host="0.0.0.0", port=8000)
