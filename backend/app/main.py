from fastapi import FastAPI, HTTPException
from app.database import get_connection
from app.chat_service import router as chat_router
from math import radians, sin, cos, sqrt, atan2


app = FastAPI(
    title="Descarte Inteligente API",
    description="API para identificação e orientação de descarte de resíduos.",
    version="1.0.0",
)

app.include_router(chat_router)


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
                    longitude,
                    origem
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
                    "origem": row[6],
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
                    longitude,
                    origem
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
                "origem": row[6],
                "distancia_km": round(distance, 2),
            })

        points_with_distance.sort(
            key=lambda point: point["distancia_km"]
        )

        return points_with_distance

    finally:
        connection.close()


@app.get("/api/waste-types")
def get_waste_types():
    connection = get_connection()

    try:
        with connection.cursor() as cursor:
            cursor.execute("""
                SELECT
                    wt.id,
                    wt.nome,
                    wt.descricao,
                    wt.orientacao_descarte,
                    wt.preparacao,
                    wt.reciclavel,
                    wc.nome AS categoria
                FROM waste_types wt
                JOIN waste_categories wc
                    ON wc.id = wt.categoria_id
                WHERE wt.ativo = TRUE
                ORDER BY wt.nome
            """)

            rows = cursor.fetchall()

            return [
                {
                    "id": row[0],
                    "nome": row[1],
                    "descricao": row[2],
                    "orientacao_descarte": row[3],
                    "preparacao": row[4],
                    "reciclavel": row[5],
                    "categoria": row[6],
                }
                for row in rows
            ]

    finally:
        connection.close()


@app.get("/api/waste-types/search")
def search_waste_types(q: str):
    connection = get_connection()

    try:
        with connection.cursor() as cursor:
            cursor.execute("""
                SELECT
                    wt.id,
                    wt.nome,
                    wt.descricao,
                    wt.orientacao_descarte,
                    wt.preparacao,
                    wt.reciclavel,
                    wc.nome AS categoria
                FROM waste_types wt
                JOIN waste_categories wc
                    ON wc.id = wt.categoria_id
                WHERE wt.ativo = TRUE
                  AND (
                      wt.nome ILIKE %s
                      OR wt.descricao ILIKE %s
                      OR wc.nome ILIKE %s
                  )
                ORDER BY wt.nome
            """, (f"%{q}%", f"%{q}%", f"%{q}%"))

            rows = cursor.fetchall()

            return [
                {
                    "id": row[0],
                    "nome": row[1],
                    "descricao": row[2],
                    "orientacao_descarte": row[3],
                    "preparacao": row[4],
                    "reciclavel": row[5],
                    "categoria": row[6],
                }
                for row in rows
            ]

    finally:
        connection.close()


@app.get("/api/waste-types/{waste_id}")
def get_waste_type(waste_id: int):
    connection = get_connection()

    try:
        with connection.cursor() as cursor:
            cursor.execute("""
                SELECT
                    wt.id,
                    wt.nome,
                    wt.descricao,
                    wt.orientacao_descarte,
                    wt.preparacao,
                    wt.reciclavel,
                    wc.nome AS categoria
                FROM waste_types wt
                JOIN waste_categories wc
                    ON wc.id = wt.categoria_id
                WHERE wt.id = %s
                  AND wt.ativo = TRUE
            """, (waste_id,))

            row = cursor.fetchone()

            if row is None:
                raise HTTPException(
                    status_code=404,
                    detail="Resíduo não encontrado.",
                )

            return {
                "id": row[0],
                "nome": row[1],
                "descricao": row[2],
                "orientacao_descarte": row[3],
                "preparacao": row[4],
                "reciclavel": row[5],
                "categoria": row[6],
            }

    finally:
        connection.close()


@app.get("/api/waste-types/{waste_id}/collection-points")
def get_collection_points_for_waste(waste_id: int):
    connection = get_connection()

    try:
        with connection.cursor() as cursor:
            cursor.execute("""
                SELECT id
                FROM waste_types
                WHERE id = %s AND ativo = TRUE
            """, (waste_id,))

            if cursor.fetchone() is None:
                raise HTTPException(
                    status_code=404,
                    detail="Resíduo não encontrado.",
                )

            cursor.execute("""
                SELECT
                    cp.id,
                    cp.nome,
                    cp.endereco,
                    cp.tipos_residuos,
                    cp.latitude,
                    cp.longitude,
                    cp.origem
                FROM collection_points cp
                JOIN waste_collection_point_types wcpt
                    ON wcpt.collection_point_id = cp.id
                WHERE wcpt.waste_type_id = %s
                ORDER BY cp.nome
            """, (waste_id,))

            rows = cursor.fetchall()

            return [
                {
                    "id": row[0],
                    "nome": row[1],
                    "endereco": row[2],
                    "tipos_residuos": row[3],
                    "latitude": row[4],
                    "longitude": row[5],
                    "origem": row[6],
                }
                for row in rows
            ]

    finally:
        connection.close()

