# Azure Project - Enterprise Infrastructure

Phase-1 Foundation (Networking + Security)

Resource Groups — Separate resource groups for Hub, Spoke, and Security following enterprise RBAC isolation patterns.
Hub-Spoke VNet Topology — Hub VNet (10.0.0.0/16) with firewall, gateway, management, and bastion subnets. Spoke VNet (10.1.0.0/16) with frontend, backend, database, and app gateway subnets. Bidirectional VNet peering connects them.
Private Subnets — All application subnets have default outbound access disabled. No VM can reach the internet directly — outbound traffic goes through the NAT Gateway only.
Network Security Groups — Least-privilege inbound rules per tier. Frontend only accepts HTTP/HTTPS from App Gateway. Backend only accepts port 8000 from Frontend. Database only accepts port 1433 from Backend. SSH restricted to management subnet only.
NAT Gateway — Attached to all private subnets for controlled outbound internet access (package installations, updates).
Key Vault — RBAC-enabled secrets management. Database credentials stored as secrets, never hardcoded.

![Image](https://github.com/user-attachments/assets/6ab18aa3-ba21-46e4-955b-716562a4f15b)

------------------------------------------------------------------------------------------

Phase - 2 Application (Compute + Database)

Backend VM — Ubuntu 24.04 LTS running a FastAPI (Python) To-Do REST API. Handles CRUD operations, connects to Azure SQL via Private Endpoint. Runs as a systemd service for auto-restart.
Frontend VM — Ubuntu 24.04 LTS running Nginx as both a static file server (HTML/CSS/JS web UI) and a reverse proxy forwarding /api/* requests to the Backend VM on port 8000.
Azure SQL Database — Fully managed SQL database with Private Endpoint. Gets a private IP (10.1.3.x) inside the database subnet — zero public internet exposure. Stores task data with full CRUD support.
Application Gateway — Layer 7 load balancer and entry point from the internet. Routes external traffic to the Frontend VM. Supports WAF, SSL termination, and URL-based routing.
Azure Bastion — Secure SSH access to VMs through the Azure Portal. Sits in the Hub VNet and reaches Spoke VMs through VNet peering — no public IPs needed on VMs.

![Image](https://github.com/user-attachments/assets/07c77fef-9d91-4611-8a2b-cca15649a6d0)


