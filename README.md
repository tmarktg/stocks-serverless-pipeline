# Stocks Serverless Pipeline

A fully automated AWS serverless pipeline that tracks daily top movers across a tech stock watchlist and displays results on a public dashboard.

## Architecture

```
EventBridge (daily cron)
        │
        ▼
Lambda: ingestion          ──► Secrets Manager (Massive API key)
        │                  ──► Massive API (OHLC data)
        ▼
   DynamoDB (stock-movers)
        │
        ▼
Lambda: retrieval  ◄── API Gateway (GET /movers)
                              │
                              ▼
                     S3 Static Website (frontend)
```

**Watchlist:** AAPL · MSFT · GOOGL · AMZN · TSLA · NVDA

**Logic:** Each trading day at ~5 PM ET, the ingestion Lambda fetches the previous day's OHLC bar for every ticker, calculates `((close - open) / open) * 100` for each, and writes the single largest absolute mover to DynamoDB.

## Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/install) >= 1.9
- [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html) configured (`aws configure`)
- A free [Massive.com](https://massive.com) account with an API key
- An AWS account (everything fits within Free Tier)

## Deploy

```bash
# 1. Clone the repo
git clone https://github.com/tmarktg/stocks-serverless-pipeline
cd stocks-serverless-pipeline

# 2. Set your API key (choose one method)
#    Option A — tfvars file (local deploys)
cp terraform/terraform.tfvars.example terraform/terraform.tfvars
# Edit terraform.tfvars and fill in massive_api_key

#    Option B — environment variable
export TF_VAR_massive_api_key="your_key_here"

# 3. Deploy
cd terraform
terraform init
terraform apply          # review the plan, then type "yes"

# 4. View outputs
terraform output api_endpoint     # REST API URL
terraform output frontend_url     # Public dashboard URL
```

The first deploy takes ~2 minutes. Subsequent deploys are incremental.

## Trigger the ingestion Lambda manually

Useful for testing before the daily cron fires:

```bash
aws lambda invoke \
  --function-name stocks-serverless-ingestion \
  --payload '{}' \
  --cli-binary-format raw-in-base64-out \
  response.json && cat response.json
```

## CI/CD (GitHub Actions)

Add these secrets to your GitHub repository (`Settings → Secrets → Actions`):

| Secret | Value |
|---|---|
| `AWS_ACCESS_KEY_ID` | IAM user access key |
| `AWS_SECRET_ACCESS_KEY` | IAM user secret key |
| `MASSIVE_API_KEY` | Your Massive.com API key |

- **PRs:** Runs `terraform plan` — no changes applied.
- **Push to `main`:** Runs `terraform apply` automatically.

## API

`GET /movers` — returns the last 7 trading days of top movers.

```json
{
  "movers": [
    {
      "date": "2025-06-13",
      "ticker": "NVDA",
      "pct_change": 4.21,
      "close_price": 131.38
    }
  ],
  "count": 7
}
```

HTTP status codes: `200 OK`, `404 Not Found` (no data yet), `405 Method Not Allowed`, `500 Internal Server Error`.

## Trade-offs & Notes

- **Secrets Manager** stores the Massive API key (~$0.40/month after free trial). For zero cost, swap to SSM Parameter Store SecureString (free) by changing `secrets.tf`.
- **DynamoDB `date` as PK** means PutItem is idempotent — re-running the Lambda on the same day safely overwrites rather than duplicates.
- **Scan vs Query** — the retrieval Lambda uses `Scan` with a date filter. This is fine at this scale (≤365 items/year). For a larger dataset, add a GSI with a static partition key.
- **`/prev` endpoint** — using Massive's previous-day-bar endpoint means the Lambda handles weekends/holidays automatically: no data is returned and no write occurs.
- **API caching** — the retrieval Lambda sets `Cache-Control: max-age=300` (5 min). Full API Gateway caching would require a paid cache cluster.

## Tear down

```bash
cd terraform
terraform destroy
```
