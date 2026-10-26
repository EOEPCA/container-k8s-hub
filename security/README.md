# Python TLS trust remediation

Advisory: https://discuss.python.org/t/109576

The hub runtime uses Rocky Linux 10.2 minimal, updated system certificates,
Python 3.12 in `/opt/hub-venv`, and uv 0.13.4 with system certificate trust.
Pip is used only in the base image's build stage, where it is bootstrapped
using the advisory's SHA-256-verified wheel. No pip is installed in the
final image; the runtime virtual environment is created without pip.

`UV_CONSTRAINT` enforces certificate and application security minimums,
including certifi >=2026.10.19. The downstream application installs its
requirements and local package with `uv pip install` into the same environment.
Final build checks verify the trust minimums, absence of pip, and dependency
consistency. The base image installs its dependencies from built wheels offline.

Rebuild with `docker build --pull --no-cache -t IMAGE .`.
Build and publish the base image before rebuilding `application-hub-context`;
its base reference must resolve to the newly rebuilt image. Publish and redeploy
both images to update running services.

For an existing pip-free environment, or immediately after creating a new one:

```sh
sh /opt/python-security/remediate-python-trust.sh /path/to/venv/bin/python
```

Use `python3 -m venv --without-pip` to create environments. The script uses the
image's uv binary and fails if security minimums are not met. Do not disable TLS
verification or remove constraints to work around dependency conflicts.
