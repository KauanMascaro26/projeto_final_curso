from fastapi import FastAPI
from app.data.collection_points import collection_points

app = FastAPI(
    title="Descarte Inteligente API",
    description="API para identificação e orientação de descarte de resíduos.",
    version="1.0.0",
)


@app.get("/")
def root():
    return {
        "message": "Descarte Inteligente API",
        "status": "online",
    }


@app.get("/health")
def health_check():
    return {
        "status": "healthy",
    }


@app.get("/api/test")
def api_test():
    return {
        "message": "API funcionando corretamente",
    }

@app.get("/api/collection-points")
def get_collection_points():
    return collection_points