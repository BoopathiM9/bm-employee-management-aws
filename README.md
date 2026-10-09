# Enterprise Employee Management System on AWS

[![AWS Architecture](https://img.shields.io/badge/AWS-Production%20Ready-232F3E?logo=amazon-aws)](https://d2c62ftth95z24.cloudfront.net)
[![Infrastructure as Code](https://img.shields.io/badge/IaC-Terraform%201.16-7B42BC?logo=terraform)](https://www.terraform.io/)
[![CI/CD](https://img.shields.io/badge/CI%2FCD-GitHub%20Actions%20(OIDC)-2088FF?logo=github-actions)](https://github.com)
[![Status](https://img.shields.io/badge/Status-Live%20Production-success)](https://d2c62ftth95z24.cloudfront.net)

A highly available, production-grade 3-tier enterprise employee management portal deployed entirely on native **Amazon Web Services (AWS)** using **Terraform** Infrastructure-as-Code and **GitHub Actions** with OpenID Connect (OIDC).

---

## 🌐 Live Production Application & Documentation

- **Official PDF Documentation**: [Download `PROJECT_DOCUMENTATION.pdf`](./PROJECT_DOCUMENTATION.pdf)
- **Live AWS CloudFront Portal (HTTPS)**: [https://d2c62ftth95z24.cloudfront.net](https://d2c62ftth95z24.cloudfront.net)
- **Permanent Free Demo Portal (Vercel)**: [https://bm-employee-management-aws.vercel.app](https://bm-employee-management-aws.vercel.app)
- **Application Load Balancer Health Endpoint**: [http://bm-alb-457926190.us-east-1.elb.amazonaws.com/health](http://bm-alb-457926190.us-east-1.elb.amazonaws.com/health)

---

## 🏛️ High-Level Architecture

```
                                [ Public Users (HTTPS:443) ]
                                             |
                                             v
                           +-----------------------------------+
                           |    Amazon CloudFront CDN (Edge)   |
                           |   (Global Caching, OAC, TLS 1.3)  |
                           +-----------------+-----------------+
                                             |
                   +-------------------------+-------------------------+
                   |                                                   |
         Default (*) / SPA Routing                                 /api/* (API Calls)
                   |                                                   |
                   v                                                   v
      +-------------------------+                        +---------------------------+
      |  Private S3 Bucket      |                        | Application Load Balancer |
      |  (React 18 SPA Build)   |                        |   (bm_alb - Public SG)    |
      |  Block Public Access: ON|                        +-------------+-------------+
      +-------------------------+                                      |
                                                                       | Port: 8080 (SG Ref)
                                                                       v
                                                +---------------------------------------------+
                                                |  EC2 Auto Scaling Group (bm_backend_asg)    |
                                                |  - Private App Subnet 1 (us-east-1a)        |
                                                |  - Private App Subnet 2 (us-east-1b)        |
                                                |  - Amazon Linux 2023 + Node.js 20 systemd   |
                                                |  - NO Public IPs (SSM Session Manager only) |
                                                +----------------------+----------------------+
                                                                       |
                                                                       | Port: 5432 (TLS/SSL)
                                                                       v
                                                +---------------------------------------------+
                                                |  Amazon RDS PostgreSQL 16 (Multi-AZ)        |
                                                |  - Private DB Subnet 1 (us-east-1a)         |
                                                |  - Private DB Subnet 2 (us-east-1b)         |
                                                |  - Storage Encrypted (gp3 KMS)              |
                                                |  - Automated 7-Day Backups                  |
                                                |  - Public Accessibility: DISABLED           |
                                                +---------------------------------------------+
```

---

## 🔒 Security & Enterprise Best Practices

1. **Zero Open SSH Ports**: Administration is conducted strictly through **AWS Systems Manager Session Manager (SSM)**. No EC2 key pairs or port 22 open.
2. **Strict Defense-in-Depth Security Groups**:
   - ALB Security Group accepts HTTP 80 & HTTPS 443 from internet.
   - Backend EC2 Security Group ONLY accepts port 8080 from the ALB SG.
   - RDS Security Group ONLY accepts port 5432 from the Backend EC2 SG.
3. **AWS Secrets Manager (`bm_db_credentials`)**: Database credentials and master password are automatically generated and stored in Secrets Manager. Node.js retrieves credentials at runtime using an IAM Role.
4. **Isolated Subnets**: EC2 instances and RDS database reside in dedicated private subnets with **no public IP addresses**.
5. **Private S3 Bucket with OAC**: S3 Block Public Access is 100% enabled. Only CloudFront can read files via Origin Access Control (SigV4).
6. **Passwordless CI/CD**: Uses GitHub Actions **OpenID Connect (OIDC)** to deploy updates without storing long-lived AWS keys in GitHub repository secrets.

---

## 🛠️ Technology Stack

- **Frontend**: React 18, React Hooks, Responsive CSS3
- **Backend**: Node.js 20 LTS, Express, `pg` (Connection Pooling with SSL)
- **Database**: PostgreSQL 16.3 on AWS RDS Multi-AZ
- **Infrastructure as Code**: HashiCorp Terraform 1.16+
- **Cloud Provider**: Amazon Web Services (AWS) in `us-east-1`
- **CI/CD**: GitHub Actions (OIDC Authentication)

---

## 📂 Repository Structure

```text
├── .github/
│   └── workflows/
│       ├── frontend-ci-cd.yml      # Automated test, build, S3 sync & CloudFront invalidation
│       └── backend-ci-cd.yml       # Automated test, packaging, S3 upload & rolling EC2 update
├── backend/
│   ├── src/
│   │   ├── controllers/            # Controller logic for Employee CRUD
│   │   ├── database/               # PostgreSQL connection pool & schema init
│   │   ├── middleware/            # Validation & centralized error handler
│   │   ├── routes/                 # Express API routes
│   │   ├── services/               # AWS Secrets Manager integration
│   │   ├── app.js                  # Express application setup
│   │   └── server.js               # Server entry point & graceful shutdown
│   ├── tests/                      # Jest unit test suite (13 passing tests)
│   └── package.json
├── frontend/
│   ├── src/
│   │   ├── components/             # Reusable UI components (Navbar, Modal, Alert)
│   │   ├── pages/                  # Dashboard, EmployeeList, EmployeeForm, Login
│   │   ├── services/               # API service with dynamic relative endpoints
│   │   └── App.js
│   └── package.json
├── deployment/
│   └── terraform/                  # Production Terraform IaC modules
│       ├── networking.tf           # VPC, 6 Subnets across 2 AZs, IGW, NAT Gateway
│       ├── security-groups.tf      # Least-privilege SG chained references
│       ├── iam.tf                  # EC2 runtime role & GitHub OIDC role
│       ├── secrets.tf              # AWS Secrets Manager configuration
│       ├── rds.tf                  # RDS PostgreSQL Multi-AZ
│       ├── alb.tf                  # Application Load Balancer & Target Group
│       ├── ec2.tf                  # Launch Template with bootstrap User Data
│       ├── autoscaling.tf          # Auto Scaling Group (Min 2, Desired 2, Max 4)
│       ├── s3.tf                   # Private frontend bucket & OAC policy
│       ├── cloudfront.tf           # CloudFront CDN distribution
│       ├── cloudwatch.tf           # Centralized logging & metric alarms
│       └── sns.tf                  # Production alert notifications
└── .gitignore                      # Enforces zero secrets or credentials committed
```

---

## 🚀 Local Development

### 1. Prerequisites
- Node.js 18+ & npm
- PostgreSQL 16 (or AWS RDS)

### 2. Backend Setup
```bash
cd backend
npm install
npm test
node src/server.js
```

### 3. Frontend Setup
```bash
cd frontend
npm install
npm test
npm start
```
