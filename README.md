![CI/CD Pipeline](https://github.com/Abdullaagamal/devops-demo/actions/workflows/ci-cd.yml/badge.svg)
![License](https://img.shields.io/badge/license-MIT-blue)
![Node.js 22](https://img.shields.io/badge/Node.js%2022-green)
![Express 5](https://img.shields.io/badge/Express%205-black)
![Docker](https://img.shields.io/badge/Docker-Multi--stage-2496ED)
![Kubernetes](https://img.shields.io/badge/Kubernetes-blue)
![Helm](https://img.shields.io/badge/Helm-v3-0F1689)

# DevOps Demo — CI/CD Portfolio Project

A tiny **Express API** wired through a complete, production-grade software delivery pipeline: multi-stage Docker build, Kubernetes orchestration with Helm packaging, and automated CI/CD that publishes container images to the GitHub Container Registry.

The application is intentionally **infra-heavy on purpose**: the point is a practical, end-to-end DevOps setup, not a rich application.

```
┌──────────┐   git push   ┌──────────────────────────┐        ┌──────┐
│ Developer │────────────▶│  GitHub Actions           │ push   │ GHCR │
└──────────┘              │  CI: lint/build/validate  │──────▶ │      │
                          │  CD: buildx + publish     │        └──┬───┘
                          └──────────────────────────┘           │ pull
                                                                  ▼
                                                ┌──────────────────────────┐
                                                │  Kubernetes               │
                                                │  Deployment ──▶ API        │
                                                │  (Downward API telemetry) │
                                                └──────────────────────────┘
```

## What the app reports

`GET /` returns the version plus, when running inside a cluster, live pod telemetry injected through the [Kubernetes Downward API](https://kubernetes.io/docs/concepts/workloads/pods/pod/#downward-api):

```json
{
  "message": "Hello, the app is working very well from Docker",
  "version": "1.0.0",
  "environment": {
    "pod": "demo-deployment-7d8c94f5-x2n1l",
    "podIP": "10.244.0.7",
    "node": "minikube"
  }
}
```

Run it outside a cluster (`npm start`) and `environment` falls back to `"local-dev"` — one image, two worlds.

## What it demonstrates

| Concept | Implementation |
|---|---|
| Multi-stage Docker build | `node:22-alpine` deps → production runner as non-root `nodeuser` (uid 1001), `HEALTHCHECK` against `/health` |
| Kubernetes manifests | Deployment (2 replicas, probes, resource limits, non-root securityContext, Downward API), Service (NodePort), Ingress, ConfigMap |
| Manifest validation | `kubeconform` validates both raw `k8s/` and Helm-rendered manifests — offline, no cluster needed |
| Helm chart | Parameterised templates, reusable `_helpers.tpl`, values-driven configuration |
| GitHub Actions CI/CD | CI on every push/PR (npm ci, build image, validate); CD on `main` merge (build + push) |
| Image publishing | GHCR with SHA-pinned and `latest` tags, GitHub Actions build cache |
| Dependency hygiene | `package-lock.json` + `npm ci`, Express 5, `qs` pinned via `overrides` — `npm audit` reports **0 vulnerabilities** |

## Tech stack

- **Runtime:** Node.js 22 (Alpine)
- **Framework:** Express 5
- **Container:** Docker multi-stage (Alpine)
- **Orchestration:** Kubernetes (`apps/v1`)
- **Packaging:** Helm
- **CI/CD:** GitHub Actions
- **Registry:** GitHub Container Registry (GHCR)

---

## Project structure

```
.
├── app.js                  # Express API: /health + / with Downward API telemetry
├── k8s/                    # Raw Kubernetes manifests
│   ├── configmap.yml
│   ├── deployment.yml
│   ├── ingress.yml
│   └── service.yml
├── devops-chart/           # Helm chart
│   ├── templates/
│   │   ├── _helpers.tpl
│   │   ├── configmap.yaml
│   │   ├── deployment.yaml
│   │   ├── ingress.yaml
│   │   └── service.yaml
│   ├── Chart.yaml
│   └── values.yaml
├── .github/workflows/
│   └── ci-cd.yml           # CI (push/PR) + CD (main merge)
├── Dockerfile              # 2-stage production build
├── docker-compose.yml      # Local containerised run
├── package.json
└── package-lock.json
```

---

## Quickstart

### Prerequisites

- Node.js 20+
- Docker 24+ (for the containerised paths)
- Optional: a local Kubernetes cluster — [minikube](https://minikube.sigs.k8s.io/docs/), [kind](https://kind.sigs.k8s.io/), or Docker Desktop's built-in cluster

### 1. Run locally

```bash
npm install
npm start
# → http://localhost:3000  → {"message":"Hello, the app is working very well from Docker",...}
```

### 2. Run with Docker

```bash
docker compose up --build
# → http://localhost:3000
```

### 3. Deploy with kubectl

The image is public on GHCR, so `kubectl` will pull it automatically:

```bash
kubectl apply -f k8s/
kubectl get pods -l app=demo
kubectl port-forward svc/demo-service 3000:3000
```

> Forked it and pushing your own image? Override the image in `k8s/deployment.yml`, or build into your local cluster first:
> `eval $(minikube docker-env) && docker build -t ghcr.io/abdullaagamal/devops-demo:latest .`

### 4. Deploy with Helm

```bash
helm install demo ./devops-chart
helm status demo
```

Override releases without editing files:

```bash
helm install demo ./devops-chart \
  --set image.repository=my-registry/devops-demo \
  --set image.tag=$GITHUB_SHA \
  --set replicaCount=3 \
  --set ingress.enabled=false
```

Key chart values (`devops-chart/values.yaml`):

| Key | Default | Purpose |
|---|---|---|
| `replicaCount` | `2` | Desired pod count |
| `image.repository` | `ghcr.io/abdullaagamal/devops-demo` | Image name |
| `image.tag` | `latest` | Image tag |
| `image.pullPolicy` | `Always` | Image pull behaviour |
| `service.type` | `NodePort` | Service exposure (NodePort / ClusterIP / LoadBalancer) |
| `service.nodePort` | `30000` | Node port when `type: NodePort` |
| `ingress.host` | `devops-demo.local` | Ingress host |
| `resources.requests / limits` | `100m/128Mi · 250m/256Mi` | CPU & memory bounds |

---

## CI/CD pipeline

Triggered on every push to `main` (full pipeline) and on every pull request (CI only).

```
push / PR
  │
  ▼
┌────────────────────────────────────────────┐
│ CI — build & validate                     │
│  npm ci → node --check app.js             │
│  docker build (no push)                   │
│  helm lint                                 │
│  kubeconform (raw k8s + Helm-rendered)      │
└────────────────────────────────────────────┘
  │
  ▼  (main only)
┌────────────────────────────────────────────┐
│ CD — build & publish image                 │
│  docker login → GHCR (GITHUB_TOKEN)        │
│  buildx build + push → GHCR                │
│  tags: <git-sha> and latest                │
└────────────────────────────────────────────┘
```

## How the app reports its environment

`app.js` reads **runtime environment variables** on every request:

- **`NODE_ENV`**, **`PORT`** — injected via the ConfigMap
- **`POD_NAME`**, **`POD_IP`**, **`NODE_NAME`** — injected by Kubernetes via the [Downward API](https://kubernetes.io/docs/concepts/workloads/pods/pod/#downward-api)
- **`/health`** — the lightweight endpoint used by the container `HEALTHCHECK` and the Kubernetes liveness/readiness probes

## What I learned

- Building minimal, reproducible containers with multi-stage Docker and a non-root user
- Reading runtime environment (port, health, cluster telemetry) instead of baking it in
- Structuring Kubernetes manifests with health probes, resource limits, and environment injection
- Writing Helm charts with named templates, helpers, and values-driven configuration
- Designing GitHub Actions workflows that build, validate, and publish without any manual steps
- Publishing to GHCR with a zero-secret bind — `GITHUB_TOKEN` does the auth
- Pinning a transitive dependency (`qs`) via `npm overrides` to ship a CVE-clean lockfile

## Debugging snapshot

> One CI saga taught me more than a dozen green runs. Three consecutive commits in this repo
> are literally named *"Fix workflow file encoding and syntax"* — my workflow file kept failing to
> parse. The YAML had a stray BOM and CRLF line endings, GitHub Actions' parser trips on that:
> the file wouldn't even load, so the run died before a single step executed.
> I normalized the file to UTF-8 with LF endings, switched to LF-only checkout in Git, and — hardest
> part — validated the pipeline offline with `actionlint` before pushing again.

---

## Roadmap

- [ ] Add an end-to-end smoke test that curls `/` and `/health` against the running image
- [ ] Verify the `actionlint` validation step in CI itself
- [ ] Automatically deploy a staging environment from GitHub Actions
- [ ] Terminate TLS with cert-manager on the Ingress

## License

[MIT](LICENSE)