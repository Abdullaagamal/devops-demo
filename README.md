# DevOps Automated CI/CD Portfolio Project

A production-ready automated CI/CD pipeline built using industry-standard DevOps tools to streamline application delivery, containerization, and cluster management.

## 🚀 Architecture & Tech Stack
* **Containerization:** Docker (Multi-stage/Alpine optimized)
* **Orchestration:** Kubernetes (Deployments & Services)
* **Package Management:** Helm Charts (Dynamic templating for multi-environment deployments)
* **Automation & CI/CD:** GitHub Actions (Automated build, push, and chart linting)
* **Application:** Node.js (Express API)

## 🔄 CI/CD Workflow
1. **Code Push:** Developer pushes changes to the `main` branch on GitHub.
2. **Build & Push:** GitHub Actions automatically builds the Docker image and pushes it securely to Docker Hub.
3. **Helm Validation:** The pipeline lints and validates the Helm chart to ensure zero configuration errors before deployment.