# ProjectP – Production-Grade ECS Fargate Deployment

This repository demonstrates a production-grade DevOps workflow for deploying a simple API service on AWS.  

---

## Objective

The objective of this project is to demonstrate the ability to:
- Containerize and deploy a service on AWS
- Automate CI/CD pipelines using GitHub Actions
- Implement monitoring and alerting
- Apply IAM least-privilege and HTTPS enforcement
- Document a clear, reproducible cloud architecture

---

## Application Overview

The service is a simple **FastAPI** application exposing two endpoints:

| Endpoint        | Description                       |
|-----------------|-----------------------------------|
| `GET /health`   | Health check endpoint             |
| `GET /predict`  | Returns a static prediction score |

Example response:
```json
{ "score": 0.85 }
````

---

## Architecture

### Components

- **Route53** – DNS for `api.tejas-electricals.in`
- **Application Load Balancer (ALB)** – TLS termination and traffic routing
- **AWS Certificate Manager (ACM)** – HTTPS certificates
- **ECS Fargate** – Serverless container orchestration
- **Amazon ECR** – Container image registry
- **CloudWatch** – Logs, metrics, dashboards, and alarms
- **Terraform** – Infrastructure as Code
- **GitHub Actions** – CI/CD automation

---

### Traffic Flow

1. Client sends an HTTPS request to `https://api.tejas-electricals.in`
2. Route53 resolves the domain to the Application Load Balancer
3. ALB enforces HTTPS and forwards traffic to the ECS target group
4. ECS Fargate tasks run the containerized API in private subnets
5. Logs and metrics are emitted to CloudWatch
6. Alarms monitor service health and resource usage

---

### Architecture Diagram

```mermaid
flowchart LR
  U[User] -->|HTTPS| R53[Route53 api.tejas-electricals.in]
  R53 --> ALB[ALB :443 TLS]
  ALB --> TG[Target Group /health]
  TG --> ECS[ECS Fargate Service]
  ECS --> CWL[CloudWatch Logs]
  ECS --> CWM[CloudWatch Metrics]
  CWM --> AL[CloudWatch Alarms]
````

---

## Containerization

### Docker Implementation

- Multi-stage Dockerfile to minimize final image size
- Non-root user for runtime security
- Built-in container healthcheck calling /health
- Minimal Python base image

### Local Testing

```bash
docker build -t projectp-api:local .
docker run --rm -p 8080:8080 projectp-api:local

curl http://localhost:8080/health
curl http://localhost:8080/predict
````

---

## Infrastructure as Code (Terraform)

All AWS infrastructure is provisioned and managed using Terraform, ensuring repeatable and auditable deployments.

### Provisioned Resources

- VPC with public and private subnets
- NAT Gateway for outbound traffic from private subnets
- Application Load Balancer with HTTP → HTTPS redirect
- ACM certificate with DNS validation via Route53
- ECS Cluster and ECS Fargate Service
- CloudWatch Log Group
- CloudWatch dashboards and alarms
- Route53 alias record for the application domain
- IAM roles for ECS and GitHub Actions (least privilege)

### Deploy/Destroy Infrastructure

```bash
aws configure

cd terraform
terraform init
terraform plan
terraform apply

terraform destroy
````

---

## CI/CD Pipeline (GitHub Actions)

Workflow file: .github/workflows/ci-cd.yml

### Continuous Integration (CI)

Triggered on pull requests and pushes:
- Install dependencies
- Run unit tests using pytest

### Continuous Deployment (CD)

Triggered on pushes to main:
1. Authenticate to AWS using GitHub OIDC
2. Build Docker image
3. Push image to Amazon ECR
4. Fetch current ECS task definition
5. Register a new task definition revision with updated image
6. Update ECS service using rolling deployment
7. Wait for service stability

### Deployment Strategy
- Rolling deployments via ECS Service
- Zero downtime using minimum healthy percent configuration

---

## Monitoring & Alerting

### CloudWatch Metrics
- ECS CPUUtilization
- ECS MemoryUtilization
- ALB HTTPCode_Target_5XX_Count
- ALB UnHealthyHostCount

### CloudWatch Dashboard
- Visualizes CPU and memory usage, error rates and Target group health.
- Alerts on high CPU utilization alarm and unhealthy target alarm (failed health checks)

---

## Security Considerations

### IAM & Access Control
- ECS task execution role: ECR pull + CloudWatch logs (Least-privilege)
- GitHub Actions role: ECR push, ECS deploy, iam:PassRole (Least-privilege)
- No AWS credentials stored in the repository
- GitHub Actions authenticates using OIDC

### Network Security
- ECS tasks run in private subnets
- ALB is the only public-facing component
- Security groups restrict traffic to required ports only

### HTTPS Enforcement
- ALB listener on port 80 redirects to HTTPS (443)
- TLS certificates managed by AWS ACM
- All client traffic encrypted in transit

### Secrets Management
- Infrastructure supports AWS Secrets Manager / SSM Parameter Store
- Secrets can be injected into ECS task definitions
- This demo service does not require runtime secrets

---

## For authenticating GitHub actions with AWS using OIDC

### 1. Create GitHub OIDC provider (one-time)
( IAM → Identity providers → create )
- Type: OpenID Connect
- URL: https://token.actions.githubusercontent.com
- Audience: sts.amazonaws.com

### 2. Create IAM Role (ProjectP-GitHubDeployRole) for GitHub Actions deploy

Trust policy (repo + branch locked):
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::047719624596:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        },
        "StringLike": {
          "token.actions.githubusercontent.com:sub": "repo:Tejas1409/ProjectP:ref:refs/heads/main"
        }
      }
    }
  ]
}
````

Inline permissions policy to the role (least privilege):
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "EcrAuth",
      "Effect": "Allow",
      "Action": "ecr:GetAuthorizationToken",
      "Resource": "*"
    },
    {
      "Sid": "EcrPushRepo",
      "Effect": "Allow",
      "Action": [
        "ecr:BatchCheckLayerAvailability",
        "ecr:BatchGetImage",
        "ecr:CompleteLayerUpload",
        "ecr:GetDownloadUrlForLayer",
        "ecr:InitiateLayerUpload",
        "ecr:PutImage",
        "ecr:UploadLayerPart"
      ],
      "Resource": "arn:aws:ecr:us-east-1:047719624596:repository/simple-web-app/projectp-api"
    },
    {
      "Sid": "EcsDeploy",
      "Effect": "Allow",
      "Action": [
        "ecs:DescribeServices",
        "ecs:DescribeTaskDefinition",
        "ecs:RegisterTaskDefinition",
        "ecs:UpdateService"
      ],
      "Resource": "*"
    },
    {
      "Sid": "PassOnlyTaskRoles",
      "Effect": "Allow",
      "Action": "iam:PassRole",
      "Resource": [
        "arn:aws:iam::047719624596:role/projectp-api-task-exec",
        "arn:aws:iam::047719624596:role/projectp-api-task-role"
      ]
    }
  ]
}
````
