from fastapi import FastAPI

from app.routers import health, trips

app = FastAPI(
    title="Car Tracker API",
    version="0.1.0",
    description="API pentru călătoriile înregistrate cu aplicația mobilă.",
)

app.include_router(health.router, prefix="/api/v1")
app.include_router(trips.router, prefix="/api/v1")
