import json
import logging
import os
import requests
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel

CLICKHOUSE_URL = os.getenv("CLICKHOUSE_URL", "http://host.docker.internal:8123/")
CH_USER = os.getenv("CLICKHOUSE_USER", "default")
CH_PASSWORD = os.getenv("CLICKHOUSE_PASSWORD", "")
logger = logging.getLogger(__name__)

app = FastAPI(title="Villa Web Analytics Collector")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

class AnalyticsEvent(BaseModel):
    event_type: str
    property_category: str = "General"
    page_url: str = "/"
    session_id: str = "anon"
    engagement_value: str = ""

@app.get("/health")
def health():
    return {"status": "healthy", "service": "analytics-service"}

@app.post("/track")
def track_event(event: AnalyticsEvent):
    query = (
        "INSERT INTO villa_analytics.events "
        "(event_type, property_category, page_url, session_id, engagement_value) "
        "FORMAT JSONEachRow\n"
    )
    headers = {
        "X-ClickHouse-User": CH_USER,
        "X-ClickHouse-Key": CH_PASSWORD,
    }
    try:
        resp = requests.post(
            CLICKHOUSE_URL,
            params={"wait_end_of_query": 1},
            data=(query + json.dumps(event.model_dump()) + "\n").encode("utf-8"),
            headers=headers,
            timeout=5,
        )
        resp.raise_for_status()
    except requests.HTTPError as exc:
        logger.error("ClickHouse rejected analytics insert: %s", exc.response.text)
        raise HTTPException(status_code=502, detail="ClickHouse rejected the event") from exc
    except requests.RequestException as exc:
        logger.error("ClickHouse analytics request failed: %s", exc)
        raise HTTPException(status_code=503, detail="ClickHouse is unavailable") from exc
    return {"status": "recorded", "clickhouse_status": resp.status_code, "detail": resp.text}
