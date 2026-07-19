# OpenProject & Odoo on AWS

A Terraform-managed AWS deployment of OpenProject and Odoo, with CI/CD, automated backups, monitoring, and HTTPS.

## Description

This project deploys two full open-source business applications — OpenProject
(project management) and Odoo (ERP) — on AWS infrastructure defined entirely
as code. It was built as a hands-on DevOps learning project, prioritizing real
production practices (remote state, CI/CD, observability, backups, HTTPS)
over a minimal "it runs" deployment.

## Features

- Full AWS infrastructure via Terraform (VPC, EC2, RDS, S3, IAM, CloudWatch, SNS)
- Two isolated application databases on a shared RDS instance
- Automated, verified nightly PostgreSQL backups to S3
- CloudWatch dashboard and alarm-based email alerting
- AWS Budget cost governance
- GitHub Actions CI/CD authenticated via IAM OIDC (no stored AWS keys)
- Nginx reverse proxy with Let's Encrypt HTTPS

## Architecture

\`\`\`mermaid
flowchart TB
    subgraph VPC["VPC 10.0.0.0/16"]
        subgraph AZ1["eu-central-1a"]
            EC2["EC2: OpenProject + Odoo\n(Docker Compose)"]
        end
        subgraph AZ2["eu-central-1b"]
            SUBNET2["Subnet only\n(RDS AZ requirement)"]
        end
        RDS[("RDS PostgreSQL\n2 databases")]
    end
    SM["Secrets Manager"]
    S3B["S3: Backups"]
    S3S["S3: Terraform State"]
    CW["CloudWatch\nAlarms + Dashboard"]
    SNS["SNS: Email Alerts"]
    GH["GitHub Actions\n(OIDC)"]
    NGINX["Nginx + Let's Encrypt"]
    USER["Internet"]

    USER -->|HTTPS| NGINX --> EC2
    EC2 -->|fetch password| SM
    EC2 <--> RDS
    EC2 -->|nightly cron| S3B
    CW --> SNS
    GH -->|terraform apply| VPC
    GH -.->|state| S3S
\`\`\`

## Folder Structure

\`\`\`
openproject-odoo-project/
├── terraform/              # Main infrastructure
│   ├── provider.tf
│   ├── variables.tf
│   ├── vpc.tf
│   ├── security-groups.tf
│   ├── rds-free.tf
│   ├── ec2-free.tf
│   ├── s3-free.tf
│   ├── cloudwatch-free.tf
│   ├── cloudwatch-dashboard.tf
│   ├── budget.tf
│   └── github-oidc.tf
├── bootstrap/               # Remote state backend (separate project)
│   └── backend-setup.tf
├── scripts/
│   ├── user_data.sh.tpl     # EC2 boot script
│   └── backup-db.sh         # Nightly backup script
└── .github/workflows/
    └── terraform.yml        # CI/CD pipeline
\`\`\`

## Installation

1. Clone this repository
2. Configure AWS credentials (\`aws configure\`)
3. Create \`terraform/terraform.tfvars\` with your values (see below)
4. \`cd bootstrap && terraform init && terraform apply\` (one-time, creates remote state backend)
5. \`cd ../terraform && terraform init && terraform apply\`

## Environment Variables (terraform.tfvars)

| Variable | Description | Example |
|---|---|---|
| \`aws_region\` | AWS region | \`eu-central-1\` |
| \`instance_type\` | EC2 instance size | \`t3.micro\` |
| \`db_instance_class\` | RDS instance size | \`db.t4g.micro\` |
| \`your_ip\` | IP allowed to SSH | \`x.x.x.x/32\` |
| \`alert_email\` | CloudWatch/Budget alert recipient | \`sahilrao2424.com\` |
| \`key_pair_name\` | SSH key pair name | \`terraform-key\` |
| \`public_key_path\` | Path to SSH public key | \`./terraform-key.pub\` |


## API Endpoints

This project deploys pre-built applications rather than a custom API — no
custom backend routes were written. However, both deployed applications
expose their own built-in APIs, reachable through this infrastructure:

- **OpenProject REST API** — available at `/api/v3/` on the OpenProject
  instance (e.g. `https://sahil-devops.ddns.net/api/v3/projects`).
  See [OpenProject's official API documentation](https://www.openproject.org/docs/api/)
- **Odoo External API** — Odoo exposes XML-RPC and JSON-RPC endpoints for
  external integrations. See
  [Odoo's official external API documentation](https://www.odoo.com/documentation/17.0/developer/reference/external_api.html)

Neither API was customized or extended as part of this project.

## Screenshots

**CloudWatch monitoring dashboard**
<img width="947" height="485" alt="image" src="https://github.com/user-attachments/assets/01f82239-10eb-45ca-bb28-0fecf7aae11d" />

**GitHub Actions — successful CI/CD pipeline run**
<img width="947" height="422" alt="image" src="https://github.com/user-attachments/assets/95d070f6-488d-42c8-9664-d24111ebc53e" />

**Odoo login (HTTPS via Let's Encrypt)**
<img width="958" height="410" alt="image" src="https://github.com/user-attachments/assets/24c4b70d-6249-4385-806b-f944dafab742" />

## Deployment Instructions

Infrastructure changes are deployed automatically via GitHub Actions on merge
to \`main\`. Pull requests trigger a \`terraform plan\`, posted as a PR comment
for review, before any change is applied.

## Future Improvements

- [ ] Extend HTTPS to OpenProject (currently only Odoo)
- [ ] Back up both application databases (currently only one)
- [ ] Refactor into reusable Terraform modules
- [ ] Narrow IAM policies scoped broadly during development
- [ ] Resolve a permanent, owned domain
- [ ] Document a Kubernetes migration path
