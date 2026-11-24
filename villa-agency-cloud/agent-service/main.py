import os
from fastapi import FastAPI
from pydantic import BaseModel
from sqlalchemy import create_engine, Column, Integer, String
from sqlalchemy.orm import declarative_base, sessionmaker

DATABASE_URL = os.getenv("DATABASE_URL", "sqlite:///./agents.db")
connect_args = {"check_same_thread": False} if DATABASE_URL.startswith("sqlite") else {}

engine = create_engine(DATABASE_URL, connect_args=connect_args)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()

class AgentDB(Base):
    __tablename__ = "agents"
    agent_id = Column(Integer, primary_key=True, index=True)
    agent_name = Column(String, nullable=False)
    email_address = Column(String, nullable=False)
    contact_number = Column(String, nullable=False)
    area_of_specialization = Column(String, nullable=False)
    assigned_property_count = Column(Integer, default=0)

Base.metadata.create_all(bind=engine)

class AgentCreate(BaseModel):
    agent_name: str
    email_address: str
    contact_number: str
    area_of_specialization: str
    assigned_property_count: int = 0

app = FastAPI(title="Agent Service")

@app.get("/health")
def health():
    return {"status": "healthy", "service": "agent-service"}

@app.post("/agents")
def create_agent(agent: AgentCreate):
    db = SessionLocal()
    new_agent = AgentDB(**agent.model_dump())
    db.add(new_agent)
    db.commit()
    db.refresh(new_agent)
    db.close()
    return new_agent

@app.get("/agents")
def list_agents():
    db = SessionLocal()
    items = db.query(AgentDB).all()
    db.close()
    return items