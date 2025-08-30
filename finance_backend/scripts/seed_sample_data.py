# Simple seed script for dev only.
from sqlmodel import Session, select
from app.db.session import engine
from app.models.user import User

def seed():
    from sqlmodel import SQLModel
    SQLModel.metadata.create_all(engine)
    with Session(engine) as s:
        if not s.exec(select(User)).first():
            u = User(email='demo@example.com', password_hash='pbkdf2:...')
            s.add(u)
            s.commit()
            print('seeded demo user')

if __name__ == '__main__':
    seed()
