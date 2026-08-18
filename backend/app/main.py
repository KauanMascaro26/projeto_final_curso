from fastapi import FastAPI
from app.data.collection_points import collection_points
from math import radians, sin, cos, sqrt, atan2

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

@app.get("/api/collection-points/nearby")
def get_nearby_collection_points(
    latitude: float,
    longitude: float,
):
    points_with_distance = []

    for point in collection_points:
        lat1 = radians(latitude)
        lon1 = radians(longitude)
        lat2 = radians(point.latitude)
        lon2 = radians(point.longitude)

        dlat = lat2 - lat1
        dlon = lon2 - lon1

        a = (
            sin(dlat / 2) ** 2
            + cos(lat1) * cos(lat2) * sin(dlon / 2) ** 2
        )

        c = 2 * atan2(sqrt(a), sqrt(1 - a))

        distance = 6371 * c

        points_with_distance.append({
            **point.model_dump(),
            "distancia_km": round(distance, 2),
        })

    points_with_distance.sort(
        key=lambda point: point["distancia_km"]
    )

    return points_with_distance