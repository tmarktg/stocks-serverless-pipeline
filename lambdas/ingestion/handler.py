import json
import os
import time
import datetime
import boto3
import urllib3
from decimal import Decimal

WATCHLIST = ["AAPL", "MSFT", "GOOGL", "AMZN", "TSLA", "NVDA"]
BASE_URL = "https://api.massive.com"
MAX_RETRIES = 3

_http = urllib3.PoolManager()
_dynamodb = boto3.resource("dynamodb")
_secrets = boto3.client("secretsmanager")


def _get_api_key() -> str:
    secret = _secrets.get_secret_value(SecretId=os.environ["SECRET_NAME"])
    return json.loads(secret["SecretString"])["api_key"]


def _fetch_prev_bar(ticker: str, api_key: str) -> dict | None:
    """Fetch the previous trading day's OHLC bar for a ticker.

    Retries up to MAX_RETRIES times on 429 rate-limit responses.
    Returns None on market-closed / no-data (not an error).
    """
    url = f"{BASE_URL}/v2/aggs/ticker/{ticker}/prev"
    headers = {"Authorization": f"Bearer {api_key}"}

    for attempt in range(MAX_RETRIES):
        resp = _http.request("GET", url, headers=headers)

        if resp.status == 200:
            data = json.loads(resp.data)
            if data.get("status") == "OK" and data.get("results"):
                return data["results"][0]
            # Market was closed — not a failure
            print(f"[{ticker}] No data returned (market closed or holiday): {data.get('status')}")
            return None

        if resp.status == 429:
            delay = 2 ** attempt
            print(f"[{ticker}] Rate limited, retrying in {delay}s (attempt {attempt + 1}/{MAX_RETRIES})")
            time.sleep(delay)
            continue

        print(f"[{ticker}] Unexpected HTTP {resp.status}: {resp.data[:200]}")
        return None

    print(f"[{ticker}] Max retries exceeded")
    return None


def lambda_handler(event, context):
    api_key = _get_api_key()
    table = _dynamodb.Table(os.environ["TABLE_NAME"])

    candidates = []
    for ticker in WATCHLIST:
        bar = _fetch_prev_bar(ticker, api_key)
        if bar is None:
            continue

        try:
            open_price = float(bar["o"])
            close_price = float(bar["c"])
            if open_price == 0:
                print(f"[{ticker}] Open price is 0, skipping")
                continue
            pct_change = ((close_price - open_price) / open_price) * 100
            timestamp_ms = int(bar["t"])
        except (KeyError, ValueError, TypeError) as exc:
            print(f"[{ticker}] Parse error: {exc} — bar={bar}")
            continue

        candidates.append({
            "ticker": ticker,
            "close": close_price,
            "pct_change": pct_change,
            "timestamp_ms": timestamp_ms,
        })

    if not candidates:
        print("No candidates collected — market may be closed or API unavailable. Skipping write.")
        return {"statusCode": 204, "body": "no data"}

    winner = max(candidates, key=lambda x: abs(x["pct_change"]))
    date_str = datetime.datetime.utcfromtimestamp(winner["timestamp_ms"] / 1000).strftime("%Y-%m-%d")

    item = {
        "date": date_str,
        "ticker": winner["ticker"],
        "pct_change": Decimal(str(round(winner["pct_change"], 4))),
        "close_price": Decimal(str(round(winner["close"], 4))),
    }

    table.put_item(Item=item)
    print(f"Stored top mover: {item}")

    return {
        "statusCode": 200,
        "body": json.dumps({"date": date_str, "winner": winner["ticker"]}),
    }
