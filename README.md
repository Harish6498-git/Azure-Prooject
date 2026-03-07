Azure Project - Enterprise Infrastructure
Terraform-based Azure infrastructure following enterprise best practices:
Hub-Spoke networking, private subnets, NSGs, Key Vault, and NAT Gateway.
Architecture
• Hub VNet (10.0.0.0/16) — Firewall, Gateway, Management subnets
• Spoke VNet (10.1.0.0/16) — Frontend, Backend, Database, App Gateway subnets
• VNet Peering — Bidirectional Hub-Spoke connectivity
• NAT Gateway — Controlled outbound access for private subnets
• NSGs — Least-privilege inbound rules per tier
• Key Vault — RBAC-enabled secrets management