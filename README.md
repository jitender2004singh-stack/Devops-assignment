# Hotel Bookings: Terraform + Database Reliability

This repository contains two things:

1. **AWS infrastructure as code (Terraform)** for `Internet -> ALB -> ECS/Fargate -> RDS PostgreSQL`, with separate `dev` and `prod` environments. It is plan-only: nothing is deployed to AWS.
2. **A local PostgreSQL database (Docker Compose)** with migrations, seed data, an optimised index, and backup/restore scripts.

```
.
├── docker-compose.yml            # local PostgreSQL 16 (migrations + seed run on first start)
├── db/
│   ├── migrations/
│   │   ├── 001_create_tables.sql # hotel_bookings, booking_events
│   │   └── 002_add_indexes.sql   # index for the Delhi report query
│   ├── seed/seed.sql             # 10,000 bookings + ~20,000 events
│   └── queries/explain_before_after.sql
├── scripts/
│   ├── backup.sh                 # timestamped pg_dump into ./backups
│   ├── restore.sh                # restore into a FRESH database + verify
│   ├── seed.sh                   # re-run the seed on a running database
│   ├── explain.sh                # EXPLAIN ANALYZE before/after the index
│   └── tf-check.sh               # fmt + init + validate + plan, offline
├── infra/
│   ├── modules/
│   │   ├── network/              # VPC, subnets, NAT, security groups
│   │   ├── rds/                  # private RDS PostgreSQL
│   │   └── ecs/                  # ALB, ECS cluster, task definition, service
│   └── envs/
│       ├── dev/                  # backend.tf, variables.tf, terraform.tfvars, ...
│       └── prod/
└── .github/workflows/
    ├── terraform.yml             # PR: fmt, init, validate, plan (comment + artifact)
    └── db-test.yml               # PR: docker compose up, backup, restore
```

---

## 1. Local database

**Prerequisites:** Docker with Compose v2.

### Setup

```bash
docker compose up -d --wait
```

On the first start (when the data volume is empty) Postgres runs, in order:
`001_create_tables.sql`, `002_add_indexes.sql`, `seed.sql`. `--wait` returns once the healthcheck passes.

Check the data:

```bash
docker compose exec db psql -U postgres -d bookings -c \
  "SELECT count(*) AS bookings,
          count(DISTINCT city)   AS cities,
          count(DISTINCT org_id) AS orgs,
          count(DISTINCT status) AS statuses,
          (SELECT count(*) FROM booking_events) AS events
   FROM hotel_bookings;"
```

Expected: 10,000 bookings, 6 cities, 5 organisations, 4 statuses and about 20,000 events. The seed is repeatable (`setseed`; only the UUIDs and the timestamps relative to `NOW()` differ between runs) and can be re-run at any time with `./scripts/seed.sh`. To start from scratch: `docker compose down -v && docker compose up -d --wait`.

### Schema

`hotel_bookings` and `booking_events` follow the suggested schema exactly (`db/migrations/001_create_tables.sql`).

Seed data covers 6 cities (delhi, mumbai, bangalore, goa, chennai, hyderabad), 5 organisations and 4 statuses (confirmed, pending, cancelled, completed). Every booking has a `booking_created` event; paid bookings have `payment_received`, cancelled ones `booking_cancelled`, and completed ones `checked_out`.

### Query optimisation

```sql
SELECT org_id, status, COUNT(*), SUM(amount)
FROM hotel_bookings
WHERE city = 'delhi'
  AND created_at >= NOW() - INTERVAL '30 days'
GROUP BY org_id, status;
```

Index (`002_add_indexes.sql`):

```sql
CREATE INDEX idx_hotel_bookings_city_created_at
    ON hotel_bookings (city, created_at)
    INCLUDE (org_id, status, amount);
```

Why this index:

- **`city` first:** it is an equality filter, so the index can jump straight to the `delhi` entries.
- **`created_at` second:** within one city the entries are sorted by `created_at`, so the "last 30 days" range is one contiguous slice of the index instead of a scan of every Delhi row.
- **`INCLUDE (org_id, status, amount)`:** these columns are only *read* (for `GROUP BY` and `SUM`), not filtered on. Storing them in the index leaf pages allows an **Index Only Scan**, so Postgres never visits the table. They are not index keys, so the index stays smaller and cheaper to maintain than `(city, created_at, org_id, status, amount)`.
- A second small index on `booking_events (booking_id, created_at)` serves "all events of a booking" lookups.

Compare the plans yourself (drops the index, explains, re-creates the index, explains):

```bash
./scripts/explain.sh
```

Result on the 10,000-row seed (the gap grows with table size):

| | Plan node | Buffers | Execution time |
|---|---|---|---|
| Before | `Seq Scan on hotel_bookings` (removes 9,442 rows) | 143 | ~2.4 ms |
| After | `Index Only Scan using idx_hotel_bookings_city_created_at` (`Heap Fetches: 0`) | 11 | ~0.4 ms |

To try it with a bigger table, raise `generate_series(1, 10000)` in `db/seed/seed.sql` and run `./scripts/seed.sh`.

### Backup and restore

```bash
./scripts/backup.sh     # creates backups/bookings_YYYYMMDD_HHMMSS.sql
./scripts/restore.sh    # restores the newest backup into a fresh database "bookings_restore"
```

- `backup.sh` runs `pg_dump` inside the container (plain SQL, `--no-owner --no-privileges`) and writes the file atomically, so a failed dump never leaves a half-written backup.
- `restore.sh` drops and re-creates `bookings_restore` (the original `bookings` database is never modified), loads the dump with `ON_ERROR_STOP`, and then verifies the result. To restore a specific file: `./scripts/restore.sh backups/<file>.sql`.

### How to verify that the restore worked

`restore.sh` prints a comparison and exits non-zero on any mismatch (example output; the checksum differs on every machine because the seed UUIDs are random):

```
Verifying restore ('bookings' vs 'bookings_restore'):
  OK    hotel_bookings rows    10000
  OK    booking_events rows    20014
  OK    total amount           181060851.28
  OK    booking ids checksum   38844f22fe6bbc20ae0aa8234d5539b2
  OK    index count            4

Restore verified: 'bookings_restore' matches 'bookings'.
```

You can also check by hand, including that the optimised query works on the restored copy:

```bash
docker compose exec db psql -U postgres -d bookings_restore -c "SELECT count(*) FROM hotel_bookings;"
docker compose exec db psql -U postgres -d bookings_restore -c "SELECT count(*) FROM booking_events;"
docker compose exec db psql -U postgres -d bookings_restore -c "\di"          # indexes were restored
docker compose exec db psql -U postgres -d bookings_restore -c \
  "SELECT org_id, status, COUNT(*), SUM(amount) FROM hotel_bookings
   WHERE city = 'delhi' AND created_at >= NOW() - INTERVAL '30 days' GROUP BY org_id, status;"
```

The counts must match the `bookings` database. (If you change data in `bookings` after taking the backup, the comparison will of course differ. Take a new backup first.)

---

## 2. Terraform

### Architecture

```
Internet
   │ 80/443
┌──▼──────────────────────────  public subnets (2 AZs)
│  ALB            (alb-sg)      NAT gateway(s)
└──┬──────────────────────────
   │ app port, only from alb-sg
┌──▼──────────────────────────  private subnets (2 AZs)
│  ECS Fargate    (ecs-sg)      nginx placeholder image
└──┬──────────────────────────
   │ 5432, only from ecs-sg
┌──▼──────────────────────────  private subnets (2 AZs)
│  RDS PostgreSQL (rds-sg)      publicly_accessible = false
└─────────────────────────────
```

| Security group | Inbound | Outbound |
|---|---|---|
| `alb-sg` | 80, 443 from `0.0.0.0/0` | app port to `ecs-sg` |
| `ecs-sg` | app port from `alb-sg` only | 5432 to `rds-sg`; 443 to the internet via NAT (image pull, logs, Secrets Manager) |
| `rds-sg` | 5432 from `ecs-sg` only | none |

RDS is private in three independent ways: it lives in private subnets (no route to an internet gateway), `publicly_accessible = false`, and its security group only references the ECS security group (not a CIDR).

### Modules

- **`modules/network`**: VPC, public and private subnets across the given AZs, internet gateway, NAT gateway(s), route tables, and the three security groups with their rules (security groups live here so that `ecs` and `rds` do not depend on each other).
- **`modules/rds`**: DB subnet group and a PostgreSQL `aws_db_instance`: encrypted storage, gp3, storage autoscaling, CloudWatch log exports, and `manage_master_user_password = true`, so the master password is generated by RDS into AWS Secrets Manager and never appears in code, tfvars or plain state.
- **`modules/ecs`**: ECS cluster (Container Insights), Fargate task definition (nginx by default), service with deployment circuit breaker and rollback, task execution/task IAM roles (the execution role can read the DB secret), ALB + target group + listeners (HTTPS with HTTP redirect when `certificate_arn` is set), CloudWatch log group, and CPU target-tracking autoscaling. The DB host, name and credentials are injected into the container as environment variables / Secrets Manager secrets.

### Environments

Each of `infra/envs/dev` and `infra/envs/prod` has its own `variables.tf`, `terraform.tfvars` (loaded automatically), `backend.tf` (separate S3 bucket, state key and DynamoDB lock table), `main.tf`, `providers.tf`, `versions.tf` and `outputs.tf`.

| Setting | dev | prod |
|---|---|---|
| VPC CIDR | `10.10.0.0/16` | `10.20.0.0/16` |
| NAT gateways | 1 (shared) | 1 per AZ |
| Fargate task | 0.25 vCPU / 512 MiB | 0.5 vCPU / 1 GiB |
| Task count (autoscaling) | 1 (1 to 2) | 2 (2 to 6) |
| RDS instance class | `db.t3.micro` | `db.m6g.large` |
| RDS storage | 20 GiB (max 50) | 100 GiB (max 500) |
| RDS Multi-AZ | no | yes |
| **RDS backup retention** | **3 days** | **14 days** |
| **RDS deletion protection** | **false** (no final snapshot) | **true** (final snapshot on destroy) |
| Performance Insights | off | on |
| ALB deletion protection | off | on |
| HTTPS | HTTP only | HTTPS + redirect (placeholder certificate ARN) |
| Log retention | 7 days | 90 days |

### Running the review checks (no AWS account needed)

Prerequisite: Terraform >= 1.5.

```bash
./scripts/tf-check.sh dev
./scripts/tf-check.sh prod
```

This runs `terraform fmt -check -recursive`, `init`, `validate` and `plan -refresh=false`, and saves the plan to `plan-dev.txt` / `plan-prod.txt`.

Two details make a plan possible without AWS access:

1. **Backend.** `backend.tf` points at S3 (the real setup), and `terraform init` against it needs AWS credentials and an existing bucket. For offline review the script temporarily adds a `backend_override.tf` with a local backend and removes it afterwards. The manual equivalent:

   ```bash
   terraform fmt -check -recursive infra
   cd infra/envs/dev
   printf 'terraform {\n  backend "local" {\n    path = "offline.tfstate"\n  }\n}\n' > backend_override.tf
   terraform init
   terraform validate
   terraform plan -refresh=false
   rm backend_override.tf
   ```

2. **Provider credentials.** `offline_plan = true` (in `terraform.tfvars`) makes the AWS provider skip authentication and account lookups, and the code uses no data sources, so `plan -refresh=false` runs offline. The availability zones are plain variables for the same reason.

### Deploying for real (not required for this exercise)

1. Create the S3 bucket and DynamoDB lock table named in `backend.tf` (per environment).
2. Set `offline_plan = false` in `terraform.tfvars` and authenticate to AWS.
3. In prod, replace the placeholder `certificate_arn` with a real ACM certificate in the same region.
4. `terraform init && terraform plan && terraform apply` from `infra/envs/<env>`.

---

## 3. GitHub Actions

- **`.github/workflows/terraform.yml`** runs on pull requests that touch `infra/**`, for `dev` and `prod`: `terraform fmt -check`, `init`, `validate`, `plan -refresh=false`. The plan is shared three ways: as a **PR comment** (updated in place on every push), as a **workflow artifact** (`tfplan-dev`, `tfplan-prod`), and in the **job summary**.
- **`.github/workflows/db-test.yml`** runs `docker compose up`, `backup.sh` and `restore.sh` on pull requests that touch the database files, so the restore verification is checked in CI.

---

## 4. Notes and trade-offs

- **NAT gateway cost:** prod uses one NAT gateway per AZ for availability; dev shares one to save cost. VPC endpoints (ECR, Secrets Manager, Logs) could replace NAT for AWS-only traffic.
- **Secrets:** no password is committed anywhere in the Terraform code. The local Docker database uses throwaway `postgres/postgres` credentials and is not exposed beyond your machine.
- **Backups:** the local scripts use logical dumps (`pg_dump`), which is right for this size and for restoring into a fresh database. In AWS, RDS automated backups (retention above) provide point-in-time recovery.
- **Engine version:** `modules/rds` defaults to PostgreSQL `16.6`; adjust `engine_version` to a currently supported minor version before a real deployment.
