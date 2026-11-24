import json

def lambda_handler(event, context):
    body = event.get("body", "{}")
    if isinstance(body, str):
        try:
            data = json.loads(body)
        except Exception:
            data = {"raw_body": body}
    else:
        data = body

    print("ALERT RECEIVED FROM EKS ENQUIRY-SERVICE:", json.dumps(data))

    return {
        "statusCode": 200,
        "headers": {"Content-Type": "application/json"},
        "body": json.dumps({
            "lambda_status": "Triggered successfully",
            "property_id": data.get("property_id"),
            "total_enquiries": data.get("total_enquiries"),
            "action_taken": "High-demand property alert logged and agent notified"
        })
    }
