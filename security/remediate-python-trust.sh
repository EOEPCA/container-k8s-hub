#!/bin/sh
# Use the patched uv binary and the updated operating system trust store.
set -eu
python_bin="${1:-python3}"
export UV_SYSTEM_CERTS=true
if [ "${2:-}" != "--check" ]; then
    uv pip install --python "$python_bin" --no-cache --upgrade 'certifi>=2026.10.19'
fi
uv --version
"$python_bin" - <<'PYTHON'
from importlib.metadata import PackageNotFoundError, version
from packaging.version import Version
import subprocess
uv_version = subprocess.check_output(["uv", "--version"], text=True).split()[1]
assert Version(uv_version) >= Version("0.13.4"), uv_version
for package, minimum in {'certifi': '2026.10.19', 'sigstore': '4.5.1'}.items():
    try:
        installed = version(package)
    except PackageNotFoundError:
        if package == 'certifi':
            raise
        continue
    assert Version(installed) >= Version(minimum), (package, installed, minimum)
    print(f'{package} {installed}: security minimum satisfied')
try:
    version('pip')
except PackageNotFoundError:
    pass
else:
    raise RuntimeError('pip must not be installed in the runtime environment')
PYTHON
