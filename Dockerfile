# The build stage
FROM rockylinux:9.3-minimal as build-stage

WORKDIR /build-stage

# Set pip's cache directory
ARG PIP_CACHE_DIR=/tmp/pip-cache

# Install Python and pip
RUN microdnf install -y python39 python3-pip libcurl-devel gcc gcc-c++ python3-devel openssl-devel && \
    pip3 install wheel && \
    microdnf clean all

# Build wheels
COPY requirements.txt requirements.txt
RUN --mount=type=cache,target=${PIP_CACHE_DIR} \
    pip3 install build \
    && pip3 wheel -r requirements.txt

# The final stage
FROM rockylinux:9.3-minimal

ARG NB_USER=jovyan
ARG NB_UID=1000
ARG HOME=/home/jovyan

RUN useradd -m -u ${NB_UID} ${NB_USER}

# Install required packages
RUN microdnf update -y && microdnf upgrade -y && microdnf install -y \
        python39 \
        python3-pip \
        curl \
        bind-utils \
        git \
        less \
        vim \
        libcurl \
        sqlite \
    && microdnf clean all
# Install Tini
RUN curl -L -o /usr/local/bin/tini https://github.com/krallin/tini/releases/latest/download/tini && chmod +x /usr/local/bin/tini

# Set pip's cache directory
ARG PIP_CACHE_DIR=/tmp/pip-cache

# Install wheels built in the build-stage
COPY requirements.txt /tmp/requirements.txt
RUN --mount=type=cache,target=${PIP_CACHE_DIR} \
    --mount=type=cache,from=build-stage,source=/build-stage,target=/tmp/wheels \
    pip3 install \
        --find-links=/tmp/wheels/ \
        -r /tmp/requirements.txt

# Check and set the correct version of requirejs
RUN sed -i 's/"version": "[^"]*"/"version": "2.3.7"/' /usr/local/share/jupyterhub/static/components/requirejs/package.json

WORKDIR /srv/jupyterhub
RUN chown ${NB_USER}:${NB_USER} /srv/jupyterhub
USER ${NB_USER}

EXPOSE 8081
ENTRYPOINT ["tini", "--"]
CMD ["jupyterhub", "--config", "/usr/local/etc/jupyterhub/jupyterhub_config.py"]
