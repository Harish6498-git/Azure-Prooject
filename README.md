# Azure Project - Enterprise Infrastructure

## Overview
Terraform-based Azure infrastructure following enterprise best practices:
Hub-Spoke networking, private subnets, NSGs, Key Vault, and NAT Gateway.

## Architecture
- **Hub VNet** (10.0.0.0/16) — Firewall, Gateway, Management subnets
- **Spoke VNet** (10.1.0.0/16) — Frontend, Backend, Database, App Gateway subnets
- **VNet Peering** — Bidirectional Hub-Spoke connectivity
- **NAT Gateway** — Controlled outbound access for private subnets
- **NSGs** — Least-privilege inbound rules per tier
- **Key Vault** — RBAC-enabled secrets management

## Deploy
```bash
cd infrastructure
terraform init
terraform plan -var-file="environments/dev/dev.tfvars"
terraform apply -var-file="environments/dev/dev.tfvars"
```

## Cleanup
```bash
terraform destroy -var-file="environments/dev/dev.tfvars"
```

