from fastapi import FastAPI
from app.database import get_connection
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
    connection = get_connection()

    try:
        with connection.cursor() as cursor:
            cursor.execute("""
                SELECT
                    id,
                    nome,
                    endereco,
                    tipos_residuos,
                    latitude,
                    longitude
                FROM collection_points
                ORDER BY id
            """)

            rows = cursor.fetchall()

            return [
                {
                    "id": row[0],
                    "nome": row[1],
                    "endereco": row[2],
                    "tipos_residuos": row[3],
                    "latitude": row[4],
                    "longitude": row[5],
                }
                for row in rows
            ]

    finally:
        connection.close()


@app.get("/api/collection-points/nearby")
def get_nearby_collection_points(
    latitude: float,
    longitude: float,
):
    connection = get_connection()

    try:
        with connection.cursor() as cursor:
            cursor.execute("""
                SELECT
                    id,
                    nome,
                    endereco,
                    tipos_residuos,
                    latitude,
                    longitude
                FROM collection_points
            """)

            rows = cursor.fetchall()

        points_with_distance = []

        for row in rows:
            lat1 = radians(latitude)
            lon1 = radians(longitude)
            lat2 = radians(row[4])
            lon2 = radians(row[5])

            dlat = lat2 - lat1
            dlon = lon2 - lon1

            a = (
                sin(dlat / 2) ** 2
                + cos(lat1)
                * cos(lat2)
                * sin(dlon / 2) ** 2
            )

            c = 2 * atan2(sqrt(a), sqrt(1 - a))

            distance = 6371 * c

            points_with_distance.append({
                "id": row[0],
                "nome": row[1],
                "endereco": row[2],
                "tipos_residuos": row[3],
                "latitude": row[4],
                "longitude": row[5],
                "distancia_km": round(distance, 2),
            })

        points_with_distance.sort(
            key=lambda point: point["distancia_km"]
        )

        return points_with_distance

    finally:
        connection.close()