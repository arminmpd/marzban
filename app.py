from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
import uvicorn
import os
import sqlite3
import hashlib
from datetime import datetime, timedelta
from typing import Optional, List

app = FastAPI(title="Marzban Panel", version="1.0.0")

DB_PATH = "/app/data/db.sqlite3"

def init_db():
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            username TEXT UNIQUE NOT NULL,
            hashed_password TEXT NOT NULL,
            is_sudo INTEGER DEFAULT 0,
            created_at TEXT,
            status TEXT DEFAULT 'active',
            data_limit INTEGER DEFAULT 0,
            used_traffic INTEGER DEFAULT 0,
            expire_at TEXT
        )
    ''')
    
    conn.commit()
    conn.close()

init_db()

class UserCreate(BaseModel):
    username: str
    password: str
    volume_gb: float = 10
    expire_days: int = 30

@app.get("/")
async def root():
    return {
        "name": "Marzban Panel",
        "version": "1.0.0",
        "status": "running",
        "endpoints": {
            "create_user": "/api/user/create",
            "users": "/api/users",
            "subscription": "/api/user/{username}/subscription"
        }
    }

@app.get("/api/health")
async def health():
    return {"status": "healthy", "timestamp": datetime.now().isoformat()}

@app.post("/api/user/create")
async def create_user(user: UserCreate):
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    
    cursor.execute("SELECT * FROM users WHERE username = ?", (user.username,))
    if cursor.fetchone():
        conn.close()
        raise HTTPException(status_code=400, detail="Username already exists")
    
    hashed = hashlib.sha256(user.password.encode()).hexdigest()
    expire = (datetime.now() + timedelta(days=user.expire_days)).isoformat()
    
    cursor.execute(
        "INSERT INTO users (username, hashed_password, data_limit, expire_at, created_at) VALUES (?, ?, ?, ?, ?)",
        (user.username, hashed, int(user.volume_gb * 1024**3), expire, datetime.now().isoformat())
    )
    conn.commit()
    conn.close()
    
    return {
        "success": True,
        "message": f"User {user.username} created",
        "username": user.username,
        "volume_gb": user.volume_gb,
        "expire": expire,
        "subscription_url": f"/api/user/{user.username}/subscription"
    }

@app.get("/api/users")
async def get_users():
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    cursor.execute("SELECT username, data_limit, used_traffic, expire_at, status FROM users")
    users = cursor.fetchall()
    conn.close()
    
    return {
        "users": [
            {
                "username": u[0],
                "volume_gb": round(u[1] / 1024**3, 2) if u[1] else 0,
                "used_gb": round(u[2] / 1024**3, 2) if u[2] else 0,
                "expire": u[3],
                "status": u[4]
            }
            for u in users
        ]
    }

@app.get("/api/user/{username}/subscription")
async def get_subscription(username: str):
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    cursor.execute("SELECT username, data_limit, used_traffic, expire_at, status FROM users WHERE username = ?", (username,))
    user = cursor.fetchone()
    conn.close()
    
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    return {
        "username": user[0],
        "volume_gb": round(user[1] / 1024**3, 2) if user[1] else 0,
        "used_gb": round(user[2] / 1024**3, 2) if user[2] else 0,
        "remaining_gb": round((user[1] - user[2]) / 1024**3, 2) if user[1] and user[2] else 0,
        "expire": user[3],
        "status": user[4]
    }

# ✅ این قسمت رو حذف کنید یا اصلاح کنید
# if name == "__main__":
#     uvicorn.run(app, host="0.0.0.0", port=int(os.getenv("PORT", 8000)))
