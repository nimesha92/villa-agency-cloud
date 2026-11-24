import os
from datetime import datetime, timezone
import requests
from fastapi import FastAPI
from pydantic import BaseModel
from sqlalchemy import create_engine, Column, Integer, String, DateTime
from sqlalchemy.orm import declarative_base, sessionmaker

DATABASE_URL = os.getenv("DATABASE_URL", "sqlite:///./enquiries.db")
SERVERLESS_WEBHOOK_URL = os.getenv("SERVERLESS_WEBHOOK_URL", "")
ENQUIRY_THRESHOLD = int(os.getenv("ENQUIRY_THRESHOLD", "10"))

connect_args = {"check_same_thread": False} if DATABASE_URL.startswith("sqlite") else {}
engine = create_engine(DATABASE_URL, connect_args=connect_args)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()

class EnquiryDB(Base):
    __tablename__ = "enquiries"
    enquiry_id = Column(Integer, primary_key=True, index=True)
    property_id = Column(Integer, nullable=False, index=True)
    customer_name = Column(String, nullable=False)
    customer_email = Column(String, nullable=False)
    contact_number = Column(String, nullable=False)
    preferred_viewing_datetime = Column(String, nullable=False)
    enquiry_message = Column(String, nullable=False)
    timestamp = Column(DateTime, default=lambda: datetime.now(timezone.utc))
    enquiry_status = Column(String, default="New")

Base.metadata.create_all(bind=engine)

class EnquiryCreate(BaseModel):
    property_id: int
    customer_name: str
    customer_email: str
    contact_number: str
    preferred_viewing_datetime: str
    enquiry_message: str
    enquiry_status: str = "New"

app = FastAPI(title="Viewing and Enquiry Service")

@app.get("/health")
def health():
    return {"status": "healthy", "service": "enquiry-service"}

@app.post("/enquiries")
def create_enquiry(enquiry: EnquiryCreate):
    db = SessionLocal()
    new_enquiry = EnquiryDB(**enquiry.model_dump())
    db.add(new_enquiry)
    db.commit()
    db.refresh(new_enquiry)

    total_count = db.query(EnquiryDB).filter(
        EnquiryDB.property_id == enquiry.property_id
    ).count()

    serverless_triggered = False
    if total_count > ENQUIRY_THRESHOLD:
        payload = {
            "property_id": enquiry.property_id,
            "total_enquiries": total_count,
            "timestamp": datetime.now(timezone.utc).isoformat(),
            "message": f"Threshold exceeded ({total_count} enquiries) for Property ID {enquiry.property_id}"
        }
        if SERVERLESS_WEBHOOK_URL:
            try:
                requests.post(SERVERLESS_WEBHOOK_URL, json=payload, timeout=5)
                serverless_triggered = True
            except Exception as e:
                print(f"Serverless trigger error: {e}")
        else:
            print(f"[SIMULATED SERVERLESS TRIGGER] {payload}")
            serverless_triggered = True

    db.close()
    return {
        "enquiry": new_enquiry,
        "total_enquiries_for_property": total_count,
        "serverless_triggered": serverless_triggered
    }

@app.get("/enquiries")
def list_enquiries():
    db = SessionLocal()
    items = db.query(EnquiryDB).all()
    db.close()
    return items