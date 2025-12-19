from sqlalchemy.orm import Session
from app.core.logger import logger

class BaseService:
    def __init__(self, db: Session):
        self.db = db
        self.logger = logger
