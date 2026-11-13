import logging
import time
from collections import defaultdict, deque
from math import atan2, cos, radians, sin, sqrt

from fastapi import FastAPI, HTTPException, Query, Request
from fastapi.responses import JSONResponse
from app.chat_service import router as chat_router
from app.database import get_connection


logger = logging.getLogger(__name__)

# Limites por IP e por processo. Em produção com múltiplas instâncias,
# substituir/centralizar o controle em Redis ou no gateway da infraestrutura.
RATE_LIMIT_WINDOW_SECONDS = 60
API_RATE_LIMIT = 120
CHAT_RATE_LIMIT = 10
_rate_limit_buckets = defaultdict(deque)
_last_bucket_cleanup = 0.0


app = FastAPI(
    title="Descarte Inteligente API",
    description="API para identificação e orientação de descarte de resíduos.",
    version="1.0.0",
)

app.include_router(chat_router)


@app.middleware("http")
async def apply_security_headers_and_rate_limits(request: Request, call_next):
    global _last_bucket_cleanup

    path = request.url.path
    if path.startswith("/api/"):
        client_ip = request.client.host if request.client else "unknown"
        is_chat = path == "/api/chat"
        limit = CHAT_RATE_LIMIT if is_chat else API_RATE_LIMIT
        bucket_key = (client_ip, "chat" if is_chat else "api")
        now = time.monotonic()
        bucket = _rate_limit_buckets[bucket_key]

        while bucket and now - bucket[0] >= RATE_LIMIT_WINDOW_SECONDS:
            bucket.popleft()

        if len(bucket) >= limit:
            retry_after = max(
                1,
                int(RATE_LIMIT_WINDOW_SECONDS - (now - bucket[0])),
            )
            return JSONResponse(
                status_code=429,
                content={"detail": "Muitas requisições. Aguarde um instante e tente novamente."},
                headers={"Retry-After": str(retry_after)},
            )

        bucket.append(now)

        # Evita que endereços que já não fazem requisições fiquem acumulados.
        if now - _last_bucket_cleanup >= RATE_LIMIT_WINDOW_SECONDS:
            expired_keys = [
                key for key, timestamps in _rate_limit_buckets.items()
                if not timestamps or now - timestamps[-1] >= RATE_LIMIT_WINDOW_SECONDS
            ]
            for key in expired_keys:
                _rate_limit_buckets.pop(key, None)
            _last_bucket_cleanup = now

    response = await call_next(request)
    response.headers["X-Content-Type-Options"] = "nosniff"
    response.headers["X-Frame-Options"] = "DENY"
    response.headers["Referrer-Policy"] = "no-referrer"
    return response


@app.exception_handler(Exception)
async def handle_unexpected_exception(request: Request, exc: Exception):
    logger.exception(
        "Erro interno ao processar %s %s",
        request.method,
        request.url.path,
    )
    return JSONResponse(
        status_code=500,
        content={"detail": "Ocorreu um erro interno. Tente novamente mais tarde."},
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
    latitude: float = Query(..., ge=-90, le=90),
    longitude: float = Query(..., ge=-180, le=180),
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
def search_waste_types(q: str = Query(..., min_length=1, max_length=100)):
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

