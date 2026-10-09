# Project Presentation Guide — For Mentor / Evaluator Review

> **Author**: Boopathi Murugesan  
> **Project**: Production 3-Tier Enterprise Employee Management System on AWS  
> **Repository**: [https://github.com/BoopathiM9/bm-employee-management-aws](https://github.com/BoopathiM9/bm-employee-management-aws)  
> **Live AWS CloudFront Portal**: [https://d2c62ftth95z24.cloudfront.net](https://d2c62ftth95z24.cloudfront.net)  
> **Permanent Free Demo Portal (Vercel)**: [https://bm-employee-management-aws.vercel.app](https://bm-employee-management-aws.vercel.app)  

---

## 1. Project Elevator Pitch (What to say in the first 60 seconds)

> *"Hi, for this project, I designed, built, and deployed an end-to-end production-grade 3-tier web application on Amazon Web Services (AWS) using Terraform Infrastructure-as-Code and GitHub Actions CI/CD.*
>
> *The application is an Enterprise Employee Management Portal. Instead of just doing a basic single-server deployment, I implemented real-world cloud architecture best practices: high availability across two Availability Zones, a private network topology with no public IPs on backend servers, Multi-AZ database replication, least-privilege security groups, and automated CI/CD using passwordless AWS OIDC authentication."*

---

## 2. Step-by-Step Architecture Walkthrough (How to explain the flow)

When presenting the architecture diagram to your mentor, walk through the 4 layers in this order:

### 1. Edge & Frontend Layer (CDN + S3)
- *"For the frontend, I developed a single-page application using **React 18**.*
- *Instead of hosting it on a public S3 bucket, I followed AWS security standards: **S3 Block Public Access is 100% enabled**, making the bucket strictly private.*
- *I placed **Amazon CloudFront CDN** in front of S3 using **Origin Access Control (OAC)** with SigV4 signing. This provides global edge caching, SSL/HTTPS termination, and ensures users can only access the application through CloudFront, never directly from S3.*
- *CloudFront also acts as our unified entry point: it serves the React UI on `/` and automatically proxies `/api/*` requests directly to our backend load balancer, avoiding all CORS and mixed-content issues."*

### 2. Networking & Load Balancing Layer (VPC + ALB)
- *"I designed a custom Virtual Private Cloud (**VPC `10.0.0.0/16`**) spanning two Availability Zones (**`us-east-1a`** and **`us-east-1b`**).*
- *I divided the network into **6 dedicated subnets**:*
  - *2 Public Subnets: for the Application Load Balancer and NAT Gateway.*
  - *2 Private App Subnets: for our backend servers.*
  - *2 Private DB Subnets: isolated for our database.*
- *I deployed an **Application Load Balancer (ALB)** in the public subnets to distribute traffic across Availability Zones, with automated health checks polling `/health` on port 8080."*

### 3. Compute & Auto Scaling Layer (EC2 + ASG + SSM)
- *"For the backend, I built a REST API using **Node.js and Express** with 13 automated unit tests.*
- *To ensure high availability and scalability, I created an **Auto Scaling Group** with a Launch Template running **Amazon Linux 2023**.*
- *The instances are located strictly in **private application subnets with NO public IP addresses**.*
- *For security, **Port 22 (SSH) is completely closed**. Instead, I configured **AWS Systems Manager (SSM) Session Manager**, which allows secure, auditable console access and command execution via IAM roles without exposing any inbound management ports."*

### 4. Database Layer (RDS PostgreSQL Multi-AZ + Secrets Manager)
- *"For data persistence, I provisioned an **Amazon RDS PostgreSQL 16** instance in the private database subnets.*
- *I enabled **Multi-AZ synchronous replication**: the primary database runs in `us-east-1a`, and AWS synchronously mirrors the storage to a standby replica in `us-east-1b`. If the primary zone fails, AWS automatically fails over in under 60 seconds with zero data loss.*
- *To avoid storing credentials in source code or environment files, I integrated **AWS Secrets Manager**. The master database credentials are generated using AWS-managed random generation. When backend instances boot, Node.js securely fetches the database credentials at runtime using its IAM instance profile.*
- *All communication between Node.js and PostgreSQL is encrypted using **TLS/SSL**."*

---

## 3. Automation, CI/CD & Infrastructure as Code (IaC)

- *"To ensure repeatability and zero manual drift, I wrote **100% of the AWS infrastructure using HashiCorp Terraform** (over 45 managed AWS resources across networking, compute, database, IAM, and CDN).*
- *For CI/CD, I created two **GitHub Actions workflows**:*
  - *`frontend-ci-cd.yml`: Runs tests, builds the production bundle, syncs to S3, and creates a CloudFront cache invalidation.*
  - *`backend-ci-cd.yml`: Runs unit tests, packages the application, uploads artifacts to S3, and performs rolling updates across EC2 instances using AWS Systems Manager.*
- *I implemented **AWS OpenID Connect (OIDC)** for GitHub Actions. This eliminates long-lived AWS Access Keys from GitHub repository secrets; GitHub assumes a temporary, short-lived IAM role during pipeline execution."*

---

## 4. Key Questions Your Mentor Might Ask & How to Answer

### Q1: *"Why did you use Multi-AZ for the database?"*
> **Your Answer**: *"In a production enterprise system, high availability is critical. By enabling Multi-AZ on Amazon RDS, AWS automatically provisions and maintains a synchronous standby replica in a second Availability Zone (`us-east-1b`). If the primary instance in `us-east-1a` suffers an outage or maintenance event, RDS performs an automatic failover without changing the DNS endpoint, ensuring high availability and zero data loss."*

### Q2: *"Why are your EC2 instances in private subnets? How do they download packages?"*
> **Your Answer**: *"Following the principle of defense-in-depth, application servers that process business logic should never have public IP addresses or be directly accessible from the internet. They sit in private subnets and only accept traffic from the Application Load Balancer on port 8080. To download system updates and npm packages, they route outbound traffic through a NAT Gateway located in the public subnet."*

### Q3: *"How do you connect to your EC2 instances if SSH port 22 is disabled?"*
> **Your Answer**: *"I used AWS Systems Manager (SSM) Session Manager. The instances run the SSM Agent and have an IAM role with SSM permissions. This eliminates the need for open port 22, bastion hosts, or managing `.pem` SSH key files. All access is authenticated through AWS IAM and logged in AWS CloudTrail for audit compliance."*

### Q4: *"Where are the database passwords stored?"*
> **Your Answer**: *"There are zero database passwords in the source code, Git, `.env` files, or AMI User Data. The password is generated randomly by Terraform and stored in AWS Secrets Manager (`bm_db_credentials`). At application boot, the Node.js backend uses the AWS SDK v3 to fetch the secret securely over the AWS private network using its IAM instance role."*

### Q5: *"Why did you use CloudFront with Origin Access Control (OAC) instead of S3 website hosting?"*
> **Your Answer**: *"S3 Static Website Hosting requires the S3 bucket to be publicly accessible, which violates cloud security benchmarks. Origin Access Control (OAC) allows us to keep the S3 bucket 100% private (Block Public Access ON) and only allow CloudFront's service principal to read objects using AWS SigV4 request signing. Additionally, CloudFront provides HTTPS/TLS encryption and edge caching globally."*

---

## 5. Live Demonstration Checklist

During your review, show these 4 live screens:

1. **Live Web App**: Open [https://d2c62ftth95z24.cloudfront.net](https://d2c62ftth95z24.cloudfront.net) and create a new employee. Show that the employee immediately appears in the directory and persists.
2. **AWS RDS Console**: Show `bm-postgres-db` in the AWS Console with **Multi-AZ: Enabled** and **Publicly Accessible: No**.
3. **AWS EC2 Console**: Show the 2 instances running with **NO public IP addresses** and the Target Group showing **2/2 targets `healthy`**.
4. **GitHub Repository**: Show your repository structure with the **Terraform files**, **CI/CD workflows**, and the **13 passing unit tests**.
