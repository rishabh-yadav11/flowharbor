# FlowHarbor

A production-style AWS CI/CD pipeline, built on the AWS Free Tier, demonstrating a full path from `git push` to a running, environment-aware demo app across Test → Staging → Production.

## What it does

FlowHarbor is a small Node.js/Express demo app (greet, add, palindrome-check endpoints, plus a live build-info badge) wired up to a real CI/CD pipeline. The interesting part isn't the app — it's the pipeline and infrastructure around it: a two-tier AWS architecture, Dockerized deploys, Jenkins automation, and manual approval gates between environments, all built and debugged from the ground up.

## Architecture

```
Internet → Cloudflare DNS → Elastic IP → Public EC2 (nginx-server)
                                              │
                                    Nginx reverse proxy + Jenkins
                                              │
                                   SSH-only, no public route
                                              │
                                    Private EC2 (no public IP)
                                              │
                          Docker containers: Test (8081) · Staging (8082) · Production (8083)
```

**Networking**
- Single VPC (`10.0.0.0/16`), split into a public subnet (`10.0.1.0/24`, has the Internet Gateway route) and a private subnet (`10.0.10.0/24`, local-only routing)
- Security groups: SSH and Jenkins restricted to admin IP; private server only reachable from the public server's security group
- Domains via Cloudflare: `flowharbor.in`, `www`, `testing`, `staging`, `jenkins` subdomains

## CI/CD pipeline

1. Push to GitHub (`main`)
2. Jenkins checks out the commit and captures the commit hash
3. Installs dependencies and runs the unit test suite (Jest) in a throwaway Node container
4. Builds a multi-stage Docker image (tests re-run inside the image build as a safety net)
5. Saves and `scp`s the image to the private server over SSH
6. Deploys to **Test** automatically
7. **Manual approval gate** → deploys to **Staging**
8. **Manual approval gate** → deploys to **Production**

Each deploy passes `APP_ENV`, `BUILD_NUMBER`, `GIT_COMMIT`, and `DEPLOYED_AT` into the container, which the app surfaces on a live status badge — so you can watch a build visibly promote from environment to environment.

Deployment is SSH-only; the private server has no public IP or inbound internet route.

## Demo app

- `GET /health` — health check
- `GET /api/info` — returns environment, build number, commit, deploy timestamp
- `GET /api/greet?name=` — greeting endpoint
- `POST /add` — adds two numbers
- `GET /palindrome/:word` — palindrome check
- `/` — static UI exercising all of the above, with a live environment badge

## Running a demo

1. Push a small change to `main`
2. Open Jenkins and trigger (or watch) the build
3. Show it pass through Checkout → Install → Test → Build → Copy → Deploy Test
4. Open `testing.flowharbor.in` — badge shows `TESTING · build #N · <commit>`
5. Approve the Staging gate in Jenkins → refresh `staging.flowharbor.in`, badge updates
6. Approve Production → refresh `flowharbor.in`, badge updates again

## Known limitations / trade-offs

- Running on Free Tier (t2/t3.micro, 1GB RAM) — memory is tight; a swapfile was added as a stopgap after builds triggered OOM-related restarts. A right-sized instance would be the real fix.
- Deploys use direct SSH rather than AWS SSM (roadmap item)
- No HTTPS/TLS termination yet (Let's Encrypt planned)
- No image vulnerability scanning yet (Trivy/Hadolint planned)
- No observability stack yet (Prometheus/Grafana/Loki planned)
- Infrastructure is hand-provisioned, not yet IaC (Terraform/Ansible planned)

## Roadmap

- Image scanning (Trivy, Hadolint)
- Observability: Prometheus, Grafana, Loki, Alertmanager
- Infrastructure as Code: Terraform, Ansible
- Replace SSH deploys with AWS SSM
- Load balancing / autoscaling
- Hardening: WAF, GuardDuty, IAM least privilege, fail2ban