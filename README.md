# cicd_basics

Node.js demo app with a low-cost Amazon EKS deployment path.

Start with [infra/README.md](infra/README.md) for the EKS runbook. The Terraform root is
under `infra/terraform/environments/dev`, the reusable module is under
`infra/terraform/modules/low-cost-eks`, and the Helm chart is under `charts/demo-app`.
