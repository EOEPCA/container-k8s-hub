# Build dependencies with the same Python runtime used by the final image.
FROM quay.io/rockylinux/rockylinux:10.2-minimal AS build-stage

WORKDIR /build-stage
COPY security/ /opt/python-security/
ENV PIP_CONSTRAINT=/opt/python-security/python-constraints.txt
RUN microdnf update -y && microdnf install -y \
        ca-certificates python3.12 python3.12-pip python3.12-devel \
        libcurl-devel gcc gcc-c++ openssl-devel && \
    microdnf clean all && \
    /usr/bin/python3.12 -m venv /opt/hub-venv
ENV PATH=/opt/hub-venv/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
RUN python3 -m pip install --no-cache-dir --upgrade \
    'pip @ https://files.pythonhosted.org/packages/3f/06/3e4420302363fbb71be3c7f35ce042f54bfca330e3e66b3a2e3c4cca579f/pip-26.2.2-py3-none-any.whl#sha256=fd7f4dfa8190e014013b9f08f3e973f4e4c26ffd179a204895533a7254813a70' && \
    python3 -m pip install --no-cache-dir 'uv==0.13.4'

COPY requirements.txt requirements.txt
RUN PYCURL_SSL_LIBRARY=openssl python3 -m pip wheel --no-cache-dir \
        --wheel-dir=/build-stage/wheels -r requirements.txt

FROM quay.io/rockylinux/rockylinux:10.2-minimal

ARG NB_USER=jovyan
ARG NB_UID=1000
ARG HOME=/home/jovyan

COPY security/ /opt/python-security/
ENV PIP_CONSTRAINT=/opt/python-security/python-constraints.txt
RUN microdnf update -y && microdnf install -y \
        ca-certificates python3.12 \
        curl bind-utils git less vim libcurl sqlite shadow-utils && \
    microdnf clean all && \
    /usr/bin/python3.12 -m venv --without-pip /opt/hub-venv
ENV PATH=/opt/hub-venv/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
COPY --from=build-stage /opt/hub-venv/bin/uv /usr/local/bin/uv
ENV UV_SYSTEM_CERTS=true
ENV UV_CONSTRAINT=/opt/python-security/python-constraints.txt
ENV UV_NO_CACHE=true

# Python RPMs include an ensurepip seed wheel; omit pip from the runtime entirely.
RUN rm -f /usr/share/python-wheels/pip-*.whl /usr/share/python3-wheels/pip-*.whl

RUN useradd -m -u ${NB_UID} ${NB_USER}

# Install Tini.
RUN curl -fL -o /usr/local/bin/tini https://github.com/krallin/tini/releases/latest/download/tini && chmod +x /usr/local/bin/tini

COPY --from=build-stage /build-stage/wheels /tmp/wheels
COPY requirements.txt /tmp/requirements.txt
RUN uv pip install --python /opt/hub-venv/bin/python3 --no-cache --no-index \
        --find-links=/tmp/wheels -r /tmp/requirements.txt && \
    rm -rf /tmp/wheels /tmp/requirements.txt && \
    sh /opt/python-security/remediate-python-trust.sh python3 --check && \
    uv pip check --python /opt/hub-venv/bin/python3

# Check and set the correct version of requirejs.
RUN sed -i 's/"version": "[^"]*"/"version": "2.3.7"/' /opt/hub-venv/share/jupyterhub/static/components/requirejs/package.json

WORKDIR /srv/jupyterhub
RUN chown ${NB_USER}:${NB_USER} /srv/jupyterhub
USER ${NB_USER}

EXPOSE 8081
ENTRYPOINT ["tini", "--"]
CMD ["jupyterhub", "--config", "/usr/local/etc/jupyterhub/jupyterhub_config.py"]
