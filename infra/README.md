# Low-Cost EKS Demo Runbook

This repo contains a minimal EKS demo path:

- `infra/terraform/modules/low-cost-eks` contains the reusable EKS module.
- `infra/terraform/environments/dev` is the runnable dev environment and keeps the current low-cost config.
- Terraform creates VPC, EKS, one small Spot managed node group, EBS CSI, and IAM roles.
- Helm deploys the Node.js app, PostgreSQL, a small gp3 PVC, and an ALB Ingress.
- Expensive or heavy add-ons are intentionally excluded from v1: NAT Gateway, Traefik, cert-manager, Prometheus, and Argo CD.

## 1. Provision AWS

Check that the AWS profile exists and can call AWS. Replace `default` if you use a
different profile.

```bash
aws configure list-profiles
aws sts get-caller-identity --profile default
```

Create the environment configuration. `public_access_cidrs` must contain your public
IPv4 address with a `/32` suffix, not a private `192.168.x.x` address.

```bash
cp infra/terraform/environments/dev/terraform.tfvars.example \
  infra/terraform/environments/dev/terraform.tfvars
# Edit aws_profile, cluster_name, and public_access_cidrs before planning.
curl -4 https://checkip.amazonaws.com
```

Example:

```hcl
aws_profile         = "default"
cluster_name        = "cicd-demo"
public_access_cidrs = ["203.0.113.10/32"]
```

Configure `config.s3.backendtf` with an existing S3 bucket, a unique state key, and
the same AWS region. S3 native locking is enabled with `use_lockfile = true`.

```hcl
bucket       = "your-terraform-state-bucket"
key          = "terraform/backends/dev"
region       = "ap-southeast-1"
use_lockfile = true
```

Initialize and apply:

```bash
terraform -chdir=infra/terraform/environments/dev init \
  -reconfigure \
  -backend-config=config.s3.backendtf
terraform -chdir=infra/terraform/environments/dev fmt -check -recursive
terraform -chdir=infra/terraform/environments/dev validate
terraform -chdir=infra/terraform/environments/dev plan -out=tfplan
terraform -chdir=infra/terraform/environments/dev apply tfplan
terraform -chdir=infra/terraform/environments/dev output
```

The public EKS endpoint is restricted to `public_access_cidrs`. The private endpoint
is also enabled so worker nodes can join the cluster without opening the public API
to their public IP addresses.

Configure kubeconfig:

```bash
aws eks update-kubeconfig \
  --region "$(terraform -chdir=infra/terraform/environments/dev output -raw aws_region)" \
  --name "$(terraform -chdir=infra/terraform/environments/dev output -raw cluster_name)"
kubectl get nodes -o wide
```

To pause app capacity while keeping the paid EKS control plane:

```bash
terraform -chdir=infra/terraform/environments/dev apply \
  -var='node_min_size=0' \
  -var='node_desired_size=0'
```

## 2. Install AWS Load Balancer Controller

Read the cluster name and controller IAM role directly from Terraform output.

```bash
CLUSTER_NAME="$(terraform -chdir=infra/terraform/environments/dev output -raw cluster_name)"
LBC_ROLE_ARN="$(terraform -chdir=infra/terraform/environments/dev output -raw aws_load_balancer_controller_role_arn)"
helm repo add eks https://aws.github.io/eks-charts
helm repo update
helm upgrade --install aws-load-balancer-controller eks/aws-load-balancer-controller \
  --namespace kube-system \
  -f infra/values/aws-load-balancer-controller.demo.yaml \
  --set "clusterName=$CLUSTER_NAME" \
  --set-string "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn=$LBC_ROLE_ARN"
kubectl -n kube-system rollout status deployment/aws-load-balancer-controller
```

## 3. Select The App Image

This repo already builds and publishes the app image to GHCR.

On a push to `main`, `.github/workflows/ci.yml` calls `.github/workflows/reusable-build.yml`
and pushes:

```text
ghcr.io/<repo-owner>/demo-app:sha-<git-sha>
ghcr.io/<repo-owner>/demo-app:latest
```

On a Git tag like `v1.2.3`, `.github/workflows/release.yml` promotes the matching
`sha-<git-sha>` image to:

```text
ghcr.io/<repo-owner>/demo-app:v1.2.3
```

Use `latest` for a quick demo, or use `sha-<git-sha>` / `vX.Y.Z` for a reproducible
deploy. Update `charts/demo-app/values-demo.yaml`:

```yaml
image:
  repository: ghcr.io/<owner>/demo-app
  tag: latest
```

Public GHCR packages can be pulled by EKS without a Kubernetes pull secret. Private
GHCR packages need a Kubernetes `docker-registry` Secret and `image.pullSecrets` in
the Helm values:

```bash
kubectl create namespace demo --dry-run=client -o yaml | kubectl apply -f -
kubectl -n demo create secret docker-registry ghcr-pull-secret \
  --docker-server=ghcr.io \
  --docker-username='<github-user>' \
  --docker-password='<classic-pat-with-read-packages>' \
  --docker-email='unused@example.com'
```

Then set:

```yaml
image:
  pullSecrets:
    - ghcr-pull-secret
```

## 4. Deploy The Stack

Create the database Secret. Percent-encode special characters in the password when putting it inside `DATABASE_URL`.

```bash
kubectl create namespace demo --dry-run=client -o yaml | kubectl apply -f -
kubectl -n demo create secret generic demo-stack-db \
  --from-literal=POSTGRES_DB=demo \
  --from-literal=POSTGRES_USER=demo \
  --from-literal=POSTGRES_PASSWORD='<random-password>' \
  --from-literal=DATABASE_URL='postgresql://demo:<url-encoded-password>@demo-stack-postgres:5432/demo'

helm lint charts/demo-app -f charts/demo-app/values-demo.yaml
helm upgrade --install demo-stack charts/demo-app \
  --namespace demo \
  -f charts/demo-app/values-demo.yaml
kubectl -n demo rollout status deploy/demo-stack
kubectl -n demo rollout status statefulset/demo-stack-postgres
kubectl -n demo get ingress demo-stack
```

When the ALB address appears:

```bash
ALB="$(kubectl -n demo get ingress demo-stack -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')"
curl "http://$ALB/health"
curl -X POST "http://$ALB/tasks" -H 'content-type: application/json' -d '{"title":"persist after restart"}'
curl "http://$ALB/tasks"
```

## 5. Cleanup

Delete Kubernetes resources that create AWS resources before destroying Terraform.

```bash
helm -n demo uninstall demo-stack
kubectl -n demo delete pvc --all
kubectl -n kube-system delete deployment aws-load-balancer-controller

terraform -chdir=infra/terraform/environments/dev destroy
```

Check the AWS console or CLI for leftover ALB, target groups, EBS volumes, Elastic IPs, NAT Gateways, and EC2 instances.

## Troubleshooting

If Terraform reports an S3 state lock, first make sure no Terraform process is still
running. Only force-unlock a stale lock owned by your previous command:

```bash
pgrep -af terraform
terraform -chdir=infra/terraform/environments/dev force-unlock '<LOCK_ID>'
```

Do not use `-lock=false` for normal plan or apply operations.

If an apply made the node group `CREATE_FAILED` with `Instances failed to join the
kubernetes cluster`, use the current module configuration and run `terraform plan`.
It should replace the failed node group. If it does not, force replacement explicitly:

```bash
terraform -chdir=infra/terraform/environments/dev apply \
  -replace='module.eks.module.eks.module.eks_managed_node_group["spot"].aws_eks_node_group.this[0]'
```

The EBS CSI add-on waits for the EKS module, including its managed node group. A
previously degraded add-on should recover after the replacement node becomes Ready.
