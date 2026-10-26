# AWS Cloud Infrastructure & IaC Lab

> A persistent, containerized AWS-compatible learning environment built with Floci, Docker Desktop, Terraform, AWS CLI, PowerShell, and VS Code.


![Status](https://img.shields.io/badge/Status-Foundation%20Complete-brightgreen)
![Terraform](https://img.shields.io/badge/IaC-Terraform-844FBA)
![AWS](https://img.shields.io/badge/Cloud-AWS%20Emulated-FF9900)
![Floci](https://img.shields.io/badge/AWS%20Emulator-Floci-635BFF)
![Docker](https://img.shields.io/badge/Containers-Docker-2496ED)
![VS Code](https://img.shields.io/badge/IDE-VS%20Code-007ACC)
![PowerShell](https://img.shields.io/badge/Scripting-PowerShell-5391FE)
![AWS CLI](https://img.shields.io/badge/CLI-AWS%20CLI-FF9900)


## Project overview

This independent hands-on lab is designed to learn AWS fundamentals, infrastructure as code (IaC), cloud resource management, and troubleshooting without deploying the initial exercises into a paid AWS account. Floci emulates AWS-compatible APIs locally; it is **not** the actual AWS cloud and does not reproduce every AWS behavior.

**Current milestone:** a Terraform-managed S3 bucket (`elie-security-lab`) created and verified through AWS CLI, retained across a Floci container restart, and visible through the Floci web console.

## Architecture

```text
Windows 11 workstation
├── VS Code / PowerShell
├── Terraform (AWS provider) ──┐
├── AWS CLI (profile: floci) ──┤ HTTP API http://127.0.0.1:4566
└── Docker Desktop             │
    ├── Floci AWS emulator ◄───┘
    │   └── S3: elie-security-lab
    ├── Bind-mounted persistent data: ./data → /app/data
    └── Floci UI container → http://localhost:4500/console/aws
```

## Technologies

| Technology | Purpose |
| --- | --- |
| Windows 11, PowerShell, VS Code | Development and command-line environment |
| Docker Desktop and Docker Compose | Run and configure Floci |
| Floci 2.3.0 (observed) | Local AWS-compatible service emulator |
| Terraform 1.16.6 (observed) | Declarative IaC, state and drift checks |
| HashiCorp AWS provider 6.70.0 (observed) | Terraform AWS resource provider |
| AWS CLI v2 (observed v2.38.5) | Independent API verification |
| Floci Web Console | Browse emulated resources |

Version numbers describe the tested environment, not minimum supported versions.

## Implemented and verified

- [x] Run Floci in Docker Desktop, bound to loopback on port 4566.
- [x] Configure Docker Compose and persistent data bind mount.
- [x] Resolve the initial memory-only storage issue by setting `FLOCI_STORAGE_MODE=persistent`.
- [x] Configure an AWS CLI profile named `floci` using **dummy** credentials (`test`).
- [x] Configure Terraform AWS provider with an S3 endpoint override to the local emulator.
- [x] Create `elie-security-lab` in `us-east-1` using Terraform.
- [x] Confirm the bucket with `aws s3api list-buckets`.
- [x] Confirm `terraform plan` reports **No changes** after deployment.
- [x] Restart the Floci container and confirm the bucket persists.
- [x] Enable the Docker socket mount for Floci's UI launcher and open the web console on port 4500.

**Not yet implemented:** IAM resources or policy enforcement tests, VPC/EC2 deployments, S3 versioning/encryption/public-access configuration, CI/CD, and real AWS deployments.

## Project layout

```text
aws-cloud-iac-lab/
├── README.md
├── .gitignore
├── docker-compose.yml
├── terraform/
│   ├── provider.tf
│   ├── main.tf
│   └── outputs.tf
└── data/                    # Local emulator state; never commit
```

## Reproduce locally

### 1. Prerequisites

Install Docker Desktop, Terraform, AWS CLI v2, and VS Code. Start Docker Desktop.

### 2. Start the emulator

```powershell
docker compose config
docker compose up -d
docker ps
```

The Docker Compose file uses the local `./data` directory for persistent emulator state. **Security:** mounting `/var/run/docker.sock` gives the container powerful Docker access; use this only in a trusted, isolated local lab.

### 3. Configure local AWS CLI credentials

```powershell
aws configure --profile floci
```

Use dummy access key `test`, dummy secret `test`, region `us-east-1`, and output `json`. **Do not use real AWS credentials for this emulator.**

### 4. Provision with Terraform

```powershell
cd terraform
terraform init
terraform validate
terraform plan
terraform apply
```

Confirm with `yes` when prompted. Terraform's `provider.tf` explicitly redirects S3 to the emulator. Other AWS services require their own supported endpoint configuration when added.

### 5. Verify using AWS CLI

```powershell
aws --profile floci --endpoint-url=http://127.0.0.1:4566 s3api list-buckets
terraform plan
```

Expected: the `elie-security-lab` bucket is listed and Terraform reports `No changes`.

### 6. Persistence test

```powershell
docker restart floci
aws --profile floci --endpoint-url=http://127.0.0.1:4566 s3api list-buckets
terraform plan
```

Wait for the Floci container to be healthy before making API requests. The bucket should remain present.

### 7. Open the UI

- Emulator status: http://localhost:4566
- Web console: http://localhost:4500/console/aws
- UI launcher: http://localhost:4566/_floci/ui

The web console may start as a separate Docker container when launched. Its UI does not necessarily expose every emulator service.

## Troubleshooting notes

**Problem:** `terraform apply` succeeded, but the bucket disappeared after `docker restart floci`.

**Cause:** the initial Compose configuration mounted `/app/data` but did not enable persistent storage; logs showed `Storage: memory Path: /app/data`.

**Fix:** set both `FLOCI_STORAGE_MODE=persistent` and `FLOCI_STORAGE_PERSISTENT_PATH=/app/data`, recreate the container, apply Terraform, and verify persistence after restart.

**Problem:** Floci UI failed with `java.net.SocketException: No such file or directory`.

**Cause:** the emulator could not access the Docker container runtime to launch the UI.

**Fix:** mount `/var/run/docker.sock:/var/run/docker.sock`, recreate the container, verify the socket exists, and relaunch the UI. Socket existence alone does not guarantee access; confirm the UI opens.

## Security and limitations

- The environment uses **emulated AWS**, not real AWS infrastructure.
- AWS-style credentials used here are placeholders; never commit real credentials or AWS profile files.
- Docker socket access is high privilege; do not expose the emulator/UI to untrusted networks.
- Floci service availability does not guarantee full AWS feature parity or IAM enforcement.
- Do not commit `data/`, `.terraform/`, state files, or sensitive variable files.
- A successful Terraform plan verifies observed configuration at that moment, not production readiness.

## Roadmap

- [ ] Phase 2 — S3 versioning, encryption, public-access controls and object operations.
- [ ] Phase 3 — IAM users, groups, roles, policies; verify emulator enforcement support.
- [ ] Phase 4 — VPC, subnets, route tables, security groups and EC2 API exercises.
- [ ] Phase 5 — Terraform variables, outputs, modules and reusable environments.
- [ ] Phase 6 — Lambda, API Gateway, DynamoDB and observability exercises.
- [ ] Phase 7 — CI checks, linting and security scanning for IaC.
- [ ] Phase 8 — Compare the local emulator workflow with a carefully budgeted real AWS sandbox and Azure IaC.

## Learning outcomes

Terraform lifecycle (`init`, `validate`, `plan`, `apply`), local AWS API endpoint configuration, AWS CLI verification, Docker Compose, bind mounts, persistent state, web console troubleshooting, and configuration drift detection.

## References

- [Floci documentation](https://floci.io/floci/)
- [Floci storage configuration](https://floci.io/floci/configuration/storage/)
- [Terraform documentation](https://developer.hashicorp.com/terraform/docs)
- [AWS CLI documentation](https://docs.aws.amazon.com/cli/)

---

*Status: Foundation completed and verified in October 2026. This repository documents an independent cloud/IaC learning project.*
