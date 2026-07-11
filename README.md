# Jenkins → Minikube CI/CD Pipeline

A complete, local CI/CD demo: Jenkins (in Docker) builds a Go app container, pushes it to a local registry, and deploys it to Minikube — all on your laptop.

## Architecture

```
┌──────────┐     ┌─────────────────────────────────────────────────┐     ┌────────────────┐
│Developer │────▶│             Jenkins (Docker)                     │────▶│   Minikube     │
│          │     │                                                  │     │                │
│ git push │     │  Checkout → Test → Build → Push → Deploy → Verify│     │  ┌──────────┐ │
└──────────┘     └────────────────────┬────────────────────────────┘     │  │demo-app  │ │
                                      │                                   │  │(2 pods)  │ │
                                      ▼                                   │  └──────────┘ │
                              ┌───────────────┐                           └────────────────┘
                              │Local Registry │
                              │localhost:5000 │
                              └───────────────┘
```

## Prerequisites

| Tool | Minimum Version | Install |
|------|----------------|---------|
| Docker Desktop | 24.x | [docker.com/desktop](https://www.docker.com/products/docker-desktop/) |
| Minikube | 1.32+ | `brew install minikube` |
| kubectl | 1.28+ | `brew install kubectl` |

## Quick Start

```bash
# 1. Clone the repo
git clone https://github.com/durrello/jenkins-minikube-cicd.git
cd jenkins-minikube-cicd

# 2. Bootstrap the environment
chmod +x scripts/setup.sh scripts/teardown.sh
./scripts/setup.sh

# 3. Open Jenkins at http://localhost:8080
#    Create a Pipeline job → point it to this repo → Build Now
```

## Pipeline Stages

| Stage | What It Does |
|-------|-------------|
| **Checkout** | Clones the repository |
| **Unit Test** | Runs `go test` inside a Go container |
| **Build Image** | Multi-stage Docker build of the Go app |
| **Push to Registry** | Pushes tagged image to `localhost:5000` |
| **Deploy to Minikube** | Applies Kubernetes manifests (namespace, deployment, service) |
| **Verify Deployment** | Waits for rollout to complete successfully |

## Project Structure

```
jenkins-minikube-cicd/
├── app/
│   ├── main.go           # Go HTTP server (/, /health, /ready)
│   ├── main_test.go      # Unit tests
│   ├── go.mod            # Go module definition
│   └── Dockerfile        # Multi-stage build (build + alpine runtime)
├── k8s/
│   ├── namespace.yaml    # 'demo' namespace
│   ├── deployment.yaml   # 2-replica Deployment with probes
│   └── service.yaml      # NodePort Service
├── jenkins/
│   ├── Dockerfile        # Custom Jenkins with Docker CLI + kubectl
│   └── plugins.txt       # Pre-installed plugins
├── scripts/
│   ├── setup.sh          # One-command environment bootstrap
│   └── teardown.sh       # Clean teardown
├── docker-compose.yml    # Jenkins + Registry services
├── Jenkinsfile           # Declarative pipeline definition
├── .gitignore
├── LICENSE               # MIT
└── README.md
```

## How It Works

1. **Environment Setup** — `setup.sh` starts Minikube (with insecure registry enabled) and spins up Jenkins + a Docker registry via Docker Compose.

2. **Jenkins Configuration** — The custom Jenkins image comes pre-loaded with Docker CLI, kubectl, and all required plugins. It mounts the Docker socket so it can build images directly.

3. **Pipeline Execution** — When you trigger a build, the Jenkinsfile orchestrates:
   - Running Go unit tests in an ephemeral container
   - Building the app image and tagging it with the build number
   - Pushing to the local registry at `localhost:5000`
   - Applying Kubernetes manifests to deploy/update the app
   - Verifying the rollout completed successfully

4. **Kubernetes Deployment** — The app runs as 2 replicas with resource limits, liveness probes (`/health`), and readiness probes (`/ready`).

## Customization

### Change the app
Edit `app/main.go`, add your logic, update tests, and push. Jenkins picks up changes automatically if configured with a webhook or SCM polling.

### Adjust resources
Edit `k8s/deployment.yaml` to change replica count, CPU/memory limits, or probe settings.

### Add pipeline stages
Edit `Jenkinsfile` to add stages (e.g., integration tests, security scanning, notifications).

### Use a different base image
Update `app/Dockerfile` to use a different Go version or base image for the runtime stage.

## Troubleshooting

| Problem | Solution |
|---------|----------|
| Jenkins container won't start | Check Docker is running: `docker info` |
| Can't push to registry | Verify registry is up: `curl http://localhost:5000/v2/` |
| kubectl commands fail in Jenkins | Ensure kubectl is in the Jenkins image and kubeconfig is accessible |
| Minikube can't pull from localhost:5000 | Restart Minikube with `--insecure-registry`: see `setup.sh` |
| Pods stuck in ImagePullBackOff | Check the registry has the image: `curl http://localhost:5000/v2/demo-app/tags/list` |
| Jenkins shows "permission denied" on docker.sock | On Linux, match the docker GID: `DOCKER_GID=$(getent group docker \| cut -d: -f3)` and rebuild |

### Useful commands

```bash
# Check pod status
kubectl get pods -n demo

# View app logs
kubectl logs -n demo -l app=demo-app

# Access the app via Minikube
minikube service demo-app -n demo --url

# View Jenkins logs
docker logs jenkins

# List images in local registry
curl http://localhost:5000/v2/_catalog
```

## Clean Up

```bash
./scripts/teardown.sh
```

This stops Jenkins, removes the registry, deletes the Minikube cluster, and cleans up Docker volumes.

## License

[MIT](LICENSE) © 2025 Durrell Gemuh
