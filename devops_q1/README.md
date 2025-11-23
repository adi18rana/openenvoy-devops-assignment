# Flask Application Deployment

## Bugs Found and Fixes

- **Missing `redis` in `requirements.txt`:**  
  The legacy application used the `redis` Python package but it was not listed as a dependency. Added `redis` to requirements to ensure the app installs and runs correctly.

- **Flask app binding only on localhost (`127.0.0.1`):**  
  The app ran only on the loopback interface, making it unreachable from outside. Modified the `app.py` to bind on `0.0.0.0` so it is accessible via EC2 public IP or container network.

## Reverse Proxy Choice

- Chose **NGINX** for the reverse proxy due to its performance, ease of configuration, and wide usage in production environments.  
- It cleanly proxies incoming HTTP requests from port 80 to the Gunicorn server running the Flask app on port 8000.  
- NGINX also provides buffering and header management, enhancing security and reliability.

## Docker vs Native (systemd) Deployment

| Aspect       | Native (systemd)                                | Docker Containerization                            |
|--------------|------------------------------------------------|--------------------------------------------------|
| **Security** | Runs directly on host; dependencies and conflicts may impact stability | Isolates application; easily restricts permissions; secure environment |
| **Resources**| Requires manual dependency management; environment differences can cause bugs | Standardized environment with cached dependencies; predictable runtime |
| **Portability**| Tightly coupled to host setup and OS versions | Containers are portable, easily deployed anywhere (local, cloud, CI/CD) |

Containers enable easier scaling, consistent deployments, and enable microservices architecture transitions. Native systemd deploy remains simpler for single-instance or small scale use cases.

---

This deployment ensures a stable production setup addressing original bugs and improving accessibility, maintainability, and scalability using modern containerization best practices.
