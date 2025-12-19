import asyncio

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.config import settings
from app.database import create_tables, SessionLocal
from app.routers import auth, users, events, admin, files, chats
from app.services.cleanup import reset_skip_lists
from app.services.mock_data import create_mock_data
from app.core.error_handlers import register_exception_handlers


app = FastAPI(
    title=settings.app_name,
    description="API для приложения ConnectHub",
    version="1.0.0",
    docs_url="/docs",
    redoc_url="/redoc",
    openapi_url="/docs-json"
)

register_exception_handlers(app)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


app.include_router(auth.router)
app.include_router(users.router)
app.include_router(events.router)
app.include_router(admin.router)
app.include_router(files.router)
app.include_router(chats.router)


@app.on_event("startup")
def on_startup() -> None:
    """Initialize database tables on startup."""
    create_tables()

    # Seed mock data in mock/demo mode
    if settings.mock_mode:
        db = SessionLocal()
        try:
            create_mock_data(db)
        finally:
            db.close()


async def _skip_reset_scheduler() -> None:
    """Background scheduler for daily skip list reset."""
    while True:
        await asyncio.sleep(60 * 60 * 24)  # once per day
        db = SessionLocal()
        try:
            reset_skip_lists(db)
        finally:
            db.close()


@app.on_event("startup")
async def start_skip_reset_scheduler() -> None:
    """Start background task for periodic skip list cleanup."""
    asyncio.create_task(_skip_reset_scheduler())


@app.get("/health")
def health_check():
    """Health check endpoint."""
    return {"status": "ok"}


@app.get("/")
def root():
    """Root endpoint."""
    return {
        "name": settings.app_name,
        "version": "1.0.0",
        "docs": "/docs"
    }

