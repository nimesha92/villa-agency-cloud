import os
from fastapi import FastAPI
from pydantic import BaseModel
from sqlalchemy import create_engine, Column, Integer, String, Float
from sqlalchemy.orm import declarative_base, sessionmaker

DATABASE_URL = os.getenv("DATABASE_URL", "sqlite:///./properties.db")
connect_args = {"check_same_thread": False} if DATABASE_URL.startswith("sqlite") else {}

engine = create_engine(DATABASE_URL, connect_args=connect_args)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()

class PropertyDB(Base):
    __tablename__ = "properties"
    property_id = Column(Integer, primary_key=True, index=True)
    property_title = Column(String, nullable=False)
    property_type = Column(String, nullable=False)
    location = Column(String, nullable=False)
    price = Column(Float, nullable=False)
    bedrooms = Column(Integer, nullable=False)
    bathrooms = Column(Integer, nullable=False)
    floor_area = Column(Float, nullable=False)
    property_status = Column(String, default="Available")
    assigned_agent = Column(String, nullable=False)

Base.metadata.create_all(bind=engine)

class PropertyCreate(BaseModel):
    property_title: str
    property_type: str
    location: str
    price: float
    bedrooms: int
    bathrooms: int
    floor_area: float
    property_status: str = "Available"
    assigned_agent: str

app = FastAPI(title="Property Service")

@app.get("/health")
def health():
    return {"status": "healthy", "service": "property-service"}

@app.post("/properties")
def create_property(prop: PropertyCreate):
    db = SessionLocal()
    new_prop = PropertyDB(**prop.model_dump())
    db.add(new_prop)
    db.commit()
    db.refresh(new_prop)
    db.close()
    return new_prop

@app.get("/properties")
def list_properties():
    db = SessionLocal()
    items = db.query(PropertyDB).all()
    db.close()
    return items