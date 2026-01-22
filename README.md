# container-k8s-hub

Jupyterhub base image for the [ApplicationHub](https://github.com/EOEPCA/application-hub-context) project.

## Container Image Strategy & Availability

This project publishes container images to GitHub Container Registry (GHCR) following a clear and deterministic tagging strategy aligned with the Git branching and release model.

### Image Registry

Images are published to:

```
ghcr.io/<repository-owner>/container-k8s-hub
```

The registry owner corresponds to the GitHub repository owner (user or organization).

Images are built using Kaniko and pushed using OCI-compliant tooling.

### Tagging Strategy

The image tag is derived automatically from the Git reference that triggered the build:


| Git reference    | Image tag    | Purpose                            |
| ---------------- | ------------ | ---------------------------------- |
| `develop` branch | `latest-dev` | Development and integration builds |
| `main` branch    | `latest`     | Stable branch builds               |
| Git tag `vX.Y.Z` | `X.Y.Z`      | Immutable release builds           |