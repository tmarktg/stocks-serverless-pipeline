import json
import os
import datetime
import boto3
from boto3.dynamodb.conditions import Attr
from decimal import Decimal

_dynamodb = boto3.resource("dynamodb")

CORS_HEADERS = {
    "Content-Type": "application/json",
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Methods": "GET,OPTIONS",
    "Access-Control-Allow-Headers": "Content-Type",
    "Cache-Control": "max-age=300",
}


class _DecimalEncoder(json.JSONEncoder):
    def default(self, obj):
        if isinstance(obj, Decimal):
            return float(obj)
        return super().default(obj)


def _response(status: int, body: dict) -> dict:
    return {
        "statusCode": status,
        "headers": CORS_HEADERS,
        "body": json.dumps(body, cls=_DecimalEncoder),
    }


def lambda_handler(event, context):
    method = event.get("httpMethod", "GET")

    if method == "OPTIONS":
        return {"statusCode": 200, "headers": CORS_HEADERS, "body": ""}

    if method != "GET":
        return _response(405, {"error": "Method not allowed"})

    table = _dynamodb.Table(os.environ["TABLE_NAME"])
    cutoff = (datetime.datetime.utcnow() - datetime.timedelta(days=7)).strftime("%Y-%m-%d")

    try:
        result = table.scan(
            FilterExpression=Attr("date").gte(cutoff),
            ProjectionExpression="#d, ticker, pct_change, close_price",
            ExpressionAttributeNames={"#d": "date"},
        )
    except Exception as exc:
        print(f"DynamoDB scan failed: {exc}")
        return _response(500, {"error": "Failed to retrieve data"})

    movers = sorted(result.get("Items", []), key=lambda x: x["date"], reverse=True)

    if not movers:
        return _response(404, {"error": "No data available yet", "movers": []})

    return _response(200, {"movers": movers, "count": len(movers)})
