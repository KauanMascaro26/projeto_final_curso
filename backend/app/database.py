import os

import psycopg
from dotenv import load_dotenv

load_dotenv()

DATABASE_URL = os.getenv("DATABASE_URL", "").strip()


def get_connection():
    if not DATABASE_URL:
        raise RuntimeError(
            "DATABASE_URL não configurada. Defina a variável no arquivo .env do backend."
        )

    if not DATABASE_URL.startswith(("postgresql://", "postgres://")):
        raise RuntimeError(
            "DATABASE_URL inválida. Informe uma URL de conexão PostgreSQL."
        )

    return psycopg.connect(DATABASE_URL)
