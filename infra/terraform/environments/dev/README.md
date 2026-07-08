# Low-Cost EKS Demo Terraform

This Terraform root is the dev/demo environment for the reusable low-cost EKS module.
It creates a small public-subnet EKS demo cluster in `ap-southeast-1`.
It intentionally avoids NAT Gateway, private subnets, control-plane CloudWatch logs,
ECR, and large add-ons to keep runtime cost low. The app image is expected to come
from GHCR.

It still creates paid AWS resources. EKS control plane, EC2, EBS, ALB, public IPv4, and
data transfer can all incur charges. Create the cluster only when needed and destroy it
after the demo.

If you already applied this environment before the module refactor, migrate Terraform
state addresses with `terraform state mv` before planning. Without state moves,
Terraform will see the module resources as new resources. Fresh environments do not
need this migration.

## Usage

Verify the AWS CLI profile first:

```bash
aws configure list-profiles
aws sts get-caller-identity --profile default
```

```bash
cd infra/terraform/environments/dev
cp terraform.tfvars.example terraform.tfvars
# Edit aws_profile and set public_access_cidrs to your public IPv4 address plus /32.
curl -4 https://checkip.amazonaws.com
# Edit config.s3.backendtf for your existing S3 state bucket.
terraform init -reconfigure -backend-config=config.s3.backendtf
terraform fmt -check -recursive
terraform validate
terraform plan -out=tfplan
terraform apply tfplan
```

Configure `kubectl`:

```bash
aws eks update-kubeconfig \
  --region "$(terraform output -raw aws_region)" \
  --name "$(terraform output -raw cluster_name)"
kubectl get nodes -o wide
```

Worker nodes use the private EKS endpoint. The public endpoint remains available only
to the CIDRs in `public_access_cidrs`.

If a previous apply left the Spot node group in `CREATE_FAILED`, run `terraform plan`
with the current module. If the plan does not replace it, run:

```bash
terraform apply \
  -replace='module.eks.module.eks.module.eks_managed_node_group["spot"].aws_eks_node_group.this[0]'
```

Scale the node group to zero when you want to pause workloads but keep the control plane:

```bash
terraform apply -var='node_desired_size=0' -var='node_min_size=0'
```

Destroy the environment when the demo is finished:

```bash
terraform destroy
```
