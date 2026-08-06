# EKS GitOps

GitOps configuration for the EKS cluster from [eks-terraform-foundation](https://github.com/TisigheLivinstone/eks-terraform-foundation). Argo CD watches this repo and syncs the cluster to match — every merge to main is a deployment.

Part of the Production EKS on AWS series:
- [Part 1 — Networking](https://www.livinstone.dev/blog/terraform-multi-environment-iac)
- [Part 2 — EKS Cluster](https://www.livinstone.dev/blog/building-production-eks-cluster-from-scratch)
- [Part 3 — Application Deployment](https://www.livinstone.dev/blog/eks-deploying-scaling-applications)
- [Part 4 — GitHub Actions CI/CD](https://www.livinstone.dev/blog/github-actions-cicd-pipeline-to-kubernetes)
- **Part 5 — GitOps with Argo CD (this repo)**

## Structure

```
eks-gitops/
├── apps/
│   ├── api-production.yaml   # Argo CD Application — production
│   └── api-dev.yaml          # Argo CD Application — dev
├── environments/
│   ├── production/
│   │   └── values.yaml       # Production Helm values (image tag lives here)
│   └── dev/
│       └── values.yaml       # Dev Helm values
└── install/
    ├── install-argocd.sh         # Install Argo CD
    └── install-image-updater.sh  # Install Image Updater
```

## Setup

**Step 1 — Install Argo CD:**
```bash
chmod +x install/install-argocd.sh
./install/install-argocd.sh
```

**Step 2 — Access the UI:**
```bash
kubectl port-forward svc/argocd-server -n argocd 8080:443
# Open https://localhost:8080 — username: admin
```

**Step 3 — Deploy the Applications:**
```bash
kubectl apply -f apps/api-production.yaml
kubectl apply -f apps/api-dev.yaml
```

**Step 4 — Verify:**
```bash
kubectl get applications -n argocd
kubectl get pods -n production
```

**Step 5 — Install Image Updater (automatic image tag updates):**
```bash
chmod +x install/install-image-updater.sh
./install/install-image-updater.sh
```

## How It Works

1. Developer pushes code to `eks-app-deployment`
2. CodeBuild builds the image and pushes to ECR
3. Image Updater detects the new image in ECR and commits the updated SHA tag to this repo
4. Argo CD detects the Git change and syncs the cluster
5. New pods roll out — readiness probe gates traffic until they are ready

## Test Self-Healing

```bash
# Make a manual change — bypassing Git
kubectl scale deployment api-api --replicas=1 -n production

# Wait 3 minutes
kubectl get deployment api-api -n production
# Replicas back to 3 — Argo CD reverted it automatically
```

## Rollback

```bash
# Preferred — shows up in Git history with author and reason
git revert HEAD
git push

# Emergency only — no trace in Git history
argocd app rollback api-production 1
```

## Screenshots

![Argo CD dashboard](screenshots/argocd-dashboard.png)
*Both applications Synced and Healthy*

![Resource tree](screenshots/argocd-resource-tree.png)
*api-production resource tree — Deployment, Service, HPA all green*

## Full write-up

[GitOps with Argo CD: A Practical Kubernetes Guide](https://www.livinstone.dev/blog/setting-up-argocd-gitops-kubernetes)
