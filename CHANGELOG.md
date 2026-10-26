# Changelog

## 5.0.0

### Breaking changes

- The runtime no longer includes pip or its ensurepip seed wheel. Downstream images must install packages with `uv pip install --python /opt/hub-venv/bin/python3`.
- Python packages and JupyterHub assets now live under `/opt/hub-venv`. Update downstream paths that previously used `/usr/local`.
- The base image is now Rocky Linux 10.2 minimal from Rocky's Quay registry, with a Python 3.12 virtual environment.

### Security and maintenance

- Refresh operating system trust and bootstrap build-stage pip from the Python advisory's hash-verified wheel.
- Provide uv 0.13.4 using system certificates and disable runtime package caching.
- Upgrade vulnerable Python dependencies and enforce minimum versions through `UV_CONSTRAINT`.
- Install runtime dependencies offline from wheels and check Python trust and dependency consistency during the build.
- Disable CI image caching, use Trivy 0.76.1, and block high or critical findings before publishing.
- Enable daily Dependabot checks for Python packages and GitHub Actions.

### Validation

- The release implementation built successfully locally and passed dependency and import checks as the runtime user.
- Trivy 0.76.1 reported 0 critical, 0 high, and 16 medium findings for the validated image.
- The downstream application-hub-context image built with uv against the updated local base and passed dependency and import checks.

### Upgrade

After the release image is published, update downstream base references to `ghcr.io/eoepca/container-k8s-hub:5.0.0` and rebuild without layer caching. Apply the corresponding uv installation changes in application-hub-context before rebuilding and redeploying it. Existing running images are not updated automatically.
