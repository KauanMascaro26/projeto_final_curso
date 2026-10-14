import re
import unicodedata

from fastapi import FastAPI, HTTPException
from pydantic import BaseModel, Field
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
                    cp.longitude
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
                }
                for row in rows
            ]

    finally:
        connection.close()



class ChatRequest(BaseModel):
    message: str = Field(min_length=1, max_length=500)


def _normalize_chat_text(value: str) -> str:
    normalized = unicodedata.normalize("NFKD", value.casefold())
    without_accents = "".join(
        character for character in normalized
        if not unicodedata.combining(character)
    )
    return re.sub(r"[^a-z0-9\\s]", " ", without_accents).strip()


@app.post("/api/chat")
def chat_with_disposal_assistant(request: ChatRequest):
    message = request.message.strip()

    if not message:
        raise HTTPException(
            status_code=422,
            detail="Digite uma mensagem para conversar com o assistente.",
        )

    normalized_message = _normalize_chat_text(message)
    tokens = {
        token for token in normalized_message.split()
        if len(token) >= 3
    }
    greeting_tokens = {
        "oi", "ola", "olá", "bom", "boa", "dia", "tarde", "noite",
        "obrigado", "obrigada", "valeu", "ajuda", "ajudar",
    }

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
    finally:
        connection.close()

    waste_items = [
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

    suggestions = [item["nome"] for item in waste_items[:4]]

    if not tokens or tokens.issubset(greeting_tokens):
        return {
            "answer": (
                "Olá! Sou o assistente do Descarte Inteligente. "
                "Posso ajudar com orientações de descarte dos materiais "
                "cadastrados. Por exemplo: como descartar uma pilha usada "
                "ou como preparar uma garrafa PET?"
            ),
            "matched_waste": None,
            "suggestions": suggestions,
        }

    ignored_tokens = {
        "como", "qual", "quais", "onde", "quando", "porque", "por que",
        "posso", "pode", "devo", "descartar", "descarte", "jogar",
        "jogo", "lixo", "residuo", "residuos", "material", "materiais",
        "uma", "uns", "umas", "para", "com", "sem", "que", "isso",
        "esse", "essa", "este", "esta", "tem", "ser", "seria", "faz",
        "fazer", "reciclar", "reciclavel", "reciclaveis", "meu", "minha",
        "por", "favor", "sobre", "orientacao", "orientacoes",
    }
    useful_tokens = tokens - ignored_tokens

    best_item = None
    best_score = 0

    for item in waste_items:
        name = _normalize_chat_text(item["nome"] or "")
        category = _normalize_chat_text(item["categoria"] or "")
        details = _normalize_chat_text(" ".join([
            str(item["descricao"] or ""),
            str(item["orientacao_descarte"] or ""),
            str(item["preparacao"] or ""),
        ]))

        name_tokens = set(name.split())
        category_tokens = set(category.split())
        detail_tokens = set(details.split())

        score = 0
        if name and name in normalized_message:
            score += 10

        score += 4 * len(useful_tokens & name_tokens)
        score += 3 * len(useful_tokens & category_tokens)
        score += len(useful_tokens & detail_tokens)

        if score > best_score:
            best_score = score
            best_item = item

    if best_item is None or best_score == 0:
        return {
            "answer": (
                "Ainda não encontrei esse material na minha base de dados. "
                "Por enquanto, consigo orientar sobre os resíduos cadastrados. "
                "Tente informar o nome de um objeto, como garrafa PET, papelão, "
                "garrafa de vidro, lata de alumínio, pilha usada ou óleo de cozinha usado."
            ),
            "matched_waste": None,
            "suggestions": suggestions,
        }

    item_name = best_item["nome"]
    answer_parts = [
        f"Sobre {item_name}: {best_item['orientacao_descarte']}"
    ]

    preparation = (best_item["preparacao"] or "").strip()
    if preparation:
        answer_parts.append(f"Preparação: {preparation}")

    if best_item["reciclavel"]:
        answer_parts.append(
            "Esse material está marcado como reciclável na base de dados."
        )
    else:
        answer_parts.append(
            "A base de dados indica que pode ser necessário um ponto de "
            "recebimento específico para esse material."
        )

    return {
        "answer": " ".join(answer_parts),
        "matched_waste": {
            "id": best_item["id"],
            "nome": best_item["nome"],
            "categoria": best_item["categoria"],
            "orientacao_descarte": best_item["orientacao_descarte"],
            "preparacao": best_item["preparacao"],
            "reciclavel": best_item["reciclavel"],
        },
        "suggestions": suggestions,
    }
