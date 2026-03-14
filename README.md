# Azure Project - Enterprise 3-Tier Application

> A production-grade, enterprise-level 3-tier web application deployed on Azure following real-world cloud operations best practices. Built with Hub-Spoke networking, private subnets, and zero-trust security — all managed via Terraform.

## Live Demo

![Image](https://github.com/user-attachments/assets/6ab18aa3-ba21-46e4-955b-716562a4f15b)

## Architecture

![Image](https://github.com/user-attachments/assets/07c77fef-9d91-4611-8a2b-cca15649a6d0)

## What I Built

### Phase 1 — Foundation (Networking + Security)

- **Hub-Spoke VNet Topology** with bidirectional peering
- **Private Subnets** — all application subnets have default outbound disabled
- **NAT Gateway** — controlled outbound internet access
- **NSGs** — least-privilege rules per tier (Frontend ← AppGW only, Backend ← Frontend only, Database ← Backend only)
- **Key Vault** — RBAC-enabled secrets management

### Phase 2 — Application (Compute + Database)

- **Backend VM** — Ubuntu 24.04, FastAPI (Python) To-Do REST API
- **Frontend VM** — Ubuntu 24.04, Nginx (reverse proxy + static web UI)
- **Azure SQL Database** — Private Endpoint, zero public exposure
- **Application Gateway** — Layer 7 entry point with WAF capability

## Tech Stack

| Component | Technology |
|-----------|-----------|
| IaC | Terraform (modular) |
| Networking | Hub-Spoke VNet, VNet Peering, NAT Gateway |
| Security | NSGs, Key Vault (RBAC), Private Endpoints |
| Frontend | Nginx, HTML, CSS, JavaScript |
| Backend | Python, FastAPI, Uvicorn |
| Database | Azure SQL Database |
| Entry Point | Application Gateway v2 |
| OS | Ubuntu 24.04 LTS |

## Request Flow

```
User (Browser)
  → Application Gateway (Public IP)
    → Frontend VM / Nginx (10.1.1.0/24)
      → serves HTML/CSS/JS
      → proxies /api/* to Backend
        → Backend VM / FastAPI (10.1.2.0/24)
          → Azure SQL via Private Endpoint (10.1.3.0/24)
            → Response flows back
```

## Project Structure

```
Azure-Prooject/
├── infrastructure/
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   ├── modules/
│   │   ├── networking/
│   │   ├── security/
│   │   ├── keyvault/
│   │   ├── compute/
│   │   ├── database/
│   │   └── appgateway/
│   └── environments/
│       └── dev/
│           └── dev.tfvars
├── app/
│   ├── backend/
│   │   ├── main.py
│   │   ├── requirements.txt
│   │   └── todoapp.service
│   └── frontend/
│       ├── index.html
│       └── nginx.conf
├── docs/
├── .gitignore
└── README.md
```

---

## Deployment Guide

### Prerequisites

| Tool | Version | Install |
|------|---------|---------|
| Azure CLI | 2.80+ | https://learn.microsoft.com/en-us/cli/azure/install-azure-cli |
| Terraform | 1.5+ | https://developer.hashicorp.com/terraform/install |
| Git | 2.40+ | https://git-scm.com/downloads |

You also need an **Azure subscription** (free account with $200 credits works).

### Step 1: Clone and Configure

```bash
git clone https://github.com/Harish6498-git/Azure-Prooject.git
cd Azure-Prooject

az login

ssh-keygen -t rsa -b 4096 -f ~/.ssh/secureapp-key -N ""
```

### Step 2: Deploy Infrastructure with Terraform

```bash
cd infrastructure
terraform init

terraform plan -var-file="environments/dev/dev.tfvars" \
  -var="ssh_public_key=$(cat ~/.ssh/secureapp-key.pub)"

terraform apply -var-file="environments/dev/dev.tfvars" \
  -var="ssh_public_key=$(cat ~/.ssh/secureapp-key.pub)"
```

Save the outputs — you'll need `backend_private_ip`, `sql_server_fqdn`, and `app_gateway_public_ip`.

### Step 3: Configure Backend VM

**3a. Create temporary SSH access:**

```bash
az network nsg rule create \
  --resource-group secureapp-spoke-dev-rg \
  --nsg-name secureapp-backend-dev-nsg \
  --name Temp-SSH --priority 150 --access Allow \
  --protocol Tcp --direction Inbound \
  --source-address-prefixes $(curl -s ifconfig.me) \
  --destination-port-ranges 22

az network public-ip create \
  --resource-group secureapp-spoke-dev-rg \
  --name backend-temp-pip --sku Standard

az network nic ip-config update \
  --resource-group secureapp-spoke-dev-rg \
  --nic-name secureapp-backend-dev-nic \
  --name internal --public-ip-address backend-temp-pip

# Get the public IP
az network public-ip show \
  --resource-group secureapp-spoke-dev-rg \
  --name backend-temp-pip --query ipAddress -o tsv
```

**3b. SSH in and install dependencies:**

```bash
ssh -i ~/.ssh/secureapp-key azureuser@<BACKEND_PUBLIC_IP>
```

```bash
sudo apt update && sudo apt upgrade -y
sudo apt install -y python3 python3-pip python3-venv

# Install SQL Server ODBC driver
curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | sudo gpg --dearmor -o /usr/share/keyrings/microsoft-prod.gpg
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/microsoft-prod.gpg] https://packages.microsoft.com/ubuntu/24.04/prod noble main" | sudo tee /etc/apt/sources.list.d/mssql-release.list
sudo apt update
sudo ACCEPT_EULA=Y apt install -y msodbcsql18 unixodbc-dev
```

**3c. Clone repo and set up the app:**

```bash
cd ~
git clone https://github.com/Harish6498-git/Azure-Prooject.git
cd Azure-Prooject/app/backend
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

**3d. Update database connection:**

Edit `main.py` and update `DB_SERVER` with your `sql_server_fqdn` from Terraform output:

```bash
nano main.py
# Update: DB_SERVER = "your-sql-server.database.windows.net"
```

**3e. Create service and start:**

```bash
sudo bash -c 'cat > /etc/systemd/system/todoapp.service << EOF
[Unit]
Description=SecureApp Todo API
After=network.target

[Service]
Type=simple
User=azureuser
WorkingDirectory=/home/azureuser/Azure-Prooject/app/backend
ExecStart=/home/azureuser/Azure-Prooject/app/backend/venv/bin/uvicorn main:app --host 0.0.0.0 --port 8000
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF'

sudo systemctl daemon-reload
sudo systemctl enable todoapp
sudo systemctl start todoapp
sudo systemctl status todoapp
# Should show: active (running) and "Database connected and table ready!"

exit
```

### Step 4: Configure Frontend VM

**4a. Swap temp IP from Backend to Frontend:**

```bash
# Remove backend temp IP
az network nic ip-config update \
  --resource-group secureapp-spoke-dev-rg \
  --nic-name secureapp-backend-dev-nic \
  --name internal --remove publicIpAddress

az network public-ip delete \
  --resource-group secureapp-spoke-dev-rg --name backend-temp-pip

# Create frontend temp IP
az network public-ip create \
  --resource-group secureapp-spoke-dev-rg \
  --name frontend-temp-pip --sku Standard

az network nsg rule create \
  --resource-group secureapp-spoke-dev-rg \
  --nsg-name secureapp-frontend-dev-nsg \
  --name Temp-SSH --priority 150 --access Allow \
  --protocol Tcp --direction Inbound \
  --source-address-prefixes $(curl -s ifconfig.me) \
  --destination-port-ranges 22

az network nic ip-config update \
  --resource-group secureapp-spoke-dev-rg \
  --nic-name secureapp-frontend-dev-nic \
  --name internal --public-ip-address frontend-temp-pip

az network public-ip show \
  --resource-group secureapp-spoke-dev-rg \
  --name frontend-temp-pip --query ipAddress -o tsv
```

**4b. SSH in and set up Nginx:**

```bash
ssh -i ~/.ssh/secureapp-key azureuser@<FRONTEND_PUBLIC_IP>
```

```bash
sudo apt update && sudo apt upgrade -y
sudo apt install -y nginx

cd ~
git clone https://github.com/Harish6498-git/Azure-Prooject.git

# Copy frontend files
sudo cp ~/Azure-Prooject/app/frontend/index.html /var/www/html/index.html

# Update backend IP in nginx config and copy
sed -i 's/BACKEND_PRIVATE_IP/10.1.2.4/g' ~/Azure-Prooject/app/frontend/nginx.conf
sudo cp ~/Azure-Prooject/app/frontend/nginx.conf /etc/nginx/sites-available/default

sudo nginx -t
sudo systemctl restart nginx

# Verify full stack
curl http://localhost/api/todos
# Should return [] or list of tasks

exit
```

### Step 5: Clean Up Temp Resources

```bash
az network nic ip-config update \
  --resource-group secureapp-spoke-dev-rg \
  --nic-name secureapp-frontend-dev-nic \
  --name internal --remove publicIpAddress

az network public-ip delete \
  --resource-group secureapp-spoke-dev-rg --name frontend-temp-pip

az network nsg rule delete \
  --resource-group secureapp-spoke-dev-rg \
  --nsg-name secureapp-frontend-dev-nsg --name Temp-SSH

az network nsg rule delete \
  --resource-group secureapp-spoke-dev-rg \
  --nsg-name secureapp-backend-dev-nsg --name Temp-SSH
```

### Step 6: Add App Gateway Health Probe Rule

```bash
az network nsg rule create \
  --resource-group secureapp-spoke-dev-rg \
  --nsg-name secureapp-frontend-dev-nsg \
  --name Allow-AppGW-Infra --priority 120 --access Allow \
  --protocol Tcp --direction Inbound \
  --source-address-prefixes GatewayManager \
  --destination-port-ranges 65200-65535
```

### Step 7: Access the App

Open your browser:

```
http://<app_gateway_public_ip>
```

Get the IP from: `terraform output app_gateway_public_ip`

---

## Destroy Resources (Save Credits)

```bash
cd infrastructure
terraform destroy -var-file="environments/dev/dev.tfvars" \
  -var="ssh_public_key=$(cat ~/.ssh/secureapp-key.pub)"
```

## Cost Estimate

| Resource | ~Monthly Cost |
|----------|--------------|
| VMs (2x D2als_v7) | ~$120 |
| Application Gateway v2 | ~$175 |
| Azure SQL (Basic) | ~$5 |
| NAT Gateway | ~$32 |
| Other (IPs, Storage) | ~$10 |
| **Total** | **~$342/month** |

> **Tip:** Destroy resources when not actively working to save credits.
