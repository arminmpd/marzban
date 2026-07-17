from fastapi import FastAPI
import uvicorn
import os

app = FastAPI(title="Marzban Panel", version="1.0.0")

@app.get("/")
async def root():
    return {"status": "running", "message": "Marzban Panel is working!"}

@app.get("/api/health")
async def health():
    return {"status": "healthy"}

if name == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=int(os.getenv("PORT", 8000)))
