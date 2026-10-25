"""
Cadastro inicial de pontos de coleta de São Carlos/SP.

Uso (na pasta backend, com .env configurado):
    python scripts/seed_collection_points.py

O script geocodifica os endereços uma única vez, respeitando o limite de
requisições do Nominatim, e só altera o banco se todos os endereços forem
localizados. As coordenadas ficam gravadas no PostgreSQL para não precisar
geocodificar a cada execução do aplicativo.
"""
from __future__ import annotations

import sys
import time
from pathlib import Path

from geopy.geocoders import Nominatim
from geopy.exc import GeocoderServiceError, GeocoderTimedOut

# Permite executar o script a partir da pasta backend.
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from app.database import get_connection  # noqa: E402


CITY = "São Carlos, São Paulo, Brasil"

PUBLIC_POINTS = [
    {
        "nome": "Ecoponto São Carlos VIII",
        "endereco": "Rua Capitão Luiz Brandão, 1847, esquina com Avenida Cônego Alberico Volpe, São Carlos, SP, Brasil",
        "types": ["Garrafa PET", "Papelão", "Garrafa de vidro", "Lata de alumínio"],
    },
    {
        "nome": "Ecoponto Jardim Paulistano",
        "endereco": "Rua Indalécio de Campos Pereira, 1120, esquina com Rua Américo Jacomino Canhoto, São Carlos, SP, Brasil",
        "types": ["Garrafa PET", "Papelão", "Garrafa de vidro", "Lata de alumínio"],
    },
    {
        "nome": "Ecoponto Jardim Ipanema (provisório)",
        "endereco": "Rua Miguel Petrucelli, s/n, São Carlos, SP, Brasil",
        "types": ["Garrafa PET", "Papelão", "Garrafa de vidro", "Lata de alumínio"],
    },
    {
        "nome": "Ecoponto Jardim Medeiros",
        "endereco": "Rua Aristodemo Pelegrini, esquina com Rua João Genovez, São Carlos, SP, Brasil",
        "types": ["Garrafa PET", "Papelão", "Garrafa de vidro", "Lata de alumínio"],
    },
    {
        "nome": "Ecoponto Vida Nova (Planalto Verde)",
        "endereco": "Avenida Regit Arab, 1205, São Carlos, SP, Brasil",
        "types": ["Garrafa PET", "Papelão", "Garrafa de vidro", "Lata de alumínio"],
    },
    {
        "nome": "Ecoponto Cidade Aracy",
        "endereco": "Avenida Arnoldo Almeida Pires, 1507, São Carlos, SP, Brasil",
        # A Prefeitura restringe este ponto a resíduos de construção e volumosos.
        # Esses tipos ainda não existem na tabela waste_types.
        "types": [],
    },
]

PRIVATE_POINTS = [
    ("Atacadão São Carlos", "Rua Miguel Petroni, 5170, São Carlos, SP, Brasil"),
    ("Carrefour Santa Felícia", "Rua Bruno Ruggiero Filho, 1751, São Carlos, SP, Brasil"),
    ("Carrefour Vila Costa do Sol", "Avenida São Carlos, 3594, São Carlos, SP, Brasil"),
    ("Extra Mercado São Carlos", "Rua São Sebastião, 1746, Centro, São Carlos, SP, Brasil"),
    ("Disafe Comercial de Ferragens", "Avenida Doutor Carlos Botelho, 2135, Centro, São Carlos, SP, Brasil"),
    ("Droga Raia - Avenida São Carlos, 2461", "Avenida São Carlos, 2461, esquina com Avenida Doutor Carlos Botelho, São Carlos, SP, Brasil"),
    ("Droga Raia - Avenida São Carlos, 1325", "Avenida São Carlos, 1325, Centro, São Carlos, SP, Brasil"),
    ("Droga Raia - Avenida São Carlos, 1903", "Avenida São Carlos, 1903, Centro, São Carlos, SP, Brasil"),
    ("Droga Raia - Avenida Doutor Carlos Botelho, 1464", "Avenida Doutor Carlos Botelho, 1464, Centro, São Carlos, SP, Brasil"),
    ("Droga Raia - Rua Desembargador Júlio Faria, 458", "Rua Desembargador Júlio Faria, 458, Vila Boa Vista, São Carlos, SP, Brasil"),
    ("Drogaria São Paulo - Avenida São Carlos, 2358", "Avenida São Carlos, 2358, Centro, São Carlos, SP, Brasil"),
    ("Drogaria São Paulo - Rua Miguel Petroni, 1800", "Rua Miguel Petroni, 1800, São Carlos, SP, Brasil"),
    ("Drogaria São Paulo - Rua Serafim Vieira de Almeida, 310", "Rua Doutor Serafim Vieira de Almeida, 310, Jardim Paraíso, São Carlos, SP, Brasil"),
    ("Pão de Açúcar - Parque Faber Castell II", "Rua Passeio dos Flamboyants, 200, Parque Faber Castell II, São Carlos, SP, Brasil"),
    ("Kalunga São Carlos", "Rua Belarmino Indalécio de Souza, 79, Centro, São Carlos, SP, Brasil"),
    ("Sancamix - Jardim Bandeirantes", "Rua Miguel Petroni, 1780, Jardim Bandeirantes, São Carlos, SP, Brasil"),
    ("Sancamix - Parque Faber Castell II", "Rua Passeio dos Flamboyants, 200, Parque Faber Castell II, São Carlos, SP, Brasil"),
    ("Tenda São Carlos", "Estrada Municipal Rubens Fernando Monte Ribeiro, Jardim Novo Horizonte, São Carlos, SP, Brasil"),
]


def _address_queries(address: str) -> list[str]:
    """Create less restrictive alternatives when OSM cannot match the full address."""
    queries = [address]
    simplified = address.replace(", Brasil", "").replace(", Brazil", "")
    if ", esquina com " in simplified:
        simplified = simplified.split(", esquina com ", 1)[0] + ", São Carlos, SP"
    queries.append(simplified)

    parts = simplified.split(",")
    if len(parts) >= 2:
        queries.append(f"{parts[0]}, {parts[1]}, São Carlos, São Paulo, Brasil")
    if parts:
        queries.append(f"{parts[0]}, São Carlos, São Paulo, Brasil")
    return list(dict.fromkeys(q.strip() for q in queries if q.strip()))


def geocode_all(geolocator: Nominatim, points: list[dict]) -> None:
    """Resolve all coordinates before opening a DB transaction, with fallback queries."""
    failures = []
    request_count = 0
    for point in points:
        location = None
        last_error = None
        for query in _address_queries(point["endereco"]):
            if request_count:
                time.sleep(1.2)  # Respect Nominatim's public-service rate limit.
            request_count += 1
            try:
                location = geolocator.geocode(
                    query, exactly_one=True, country_codes="br", timeout=15
                )
            except (GeocoderServiceError, GeocoderTimedOut) as exc:
                last_error = exc
                print(f"Aviso de geocodificação para {point['nome']} ({query}): {exc}")
                continue
            if location is not None:
                break

        if location is None:
            detail = f" — último erro: {last_error}" if last_error else ""
            failures.append(f"{point['nome']} — {point['endereco']}{detail}")
            print(f"Não localizado: {point['nome']}")
            continue
        point["latitude"] = float(location.latitude)
        point["longitude"] = float(location.longitude)
        print(f"Localizado: {point['nome']} ({point['latitude']:.6f}, {point['longitude']:.6f})")

    if failures:
        raise RuntimeError(
            "Nenhuma alteração foi feita no banco. Não foi possível localizar:\\n- "
            + "\\n- ".join(failures)
            + "\\nConfira os endereços ou ajuste manualmente as coordenadas e execute novamente."
        )


def main() -> None:
    geolocator = Nominatim(
        user_agent="descarte-inteligente-saocarlos-seed/1.0 (cadastro inicial do TCC)"
    )

    points = PUBLIC_POINTS + [
        {
            "nome": name,
            "endereco": address,
            "types": ["Pilha usada"],
            "origem": "empresa",
        }
        for name, address in PRIVATE_POINTS
    ]
    for point in points:
        point.setdefault("origem", "publico")

    print(f"Geocodificando {len(points)} endereços. Isso pode levar cerca de 30 segundos.")
    geocode_all(geolocator, points)

    connection = get_connection()
    try:
        with connection.transaction():
            with connection.cursor() as cursor:
                cursor.execute("SELECT id, nome FROM waste_types WHERE ativo = TRUE")
                waste_ids = {name.strip().casefold(): wid for wid, name in cursor.fetchall()}

                aliases = {
                    "garrafa pet": ["garrafa pet"],
                    "papelão": ["papelão", "papelao"],
                    "garrafa de vidro": ["garrafa de vidro"],
                    "lata de alumínio": ["lata de alumínio", "lata de aluminio"],
                    "pilha usada": ["pilha usada"],
                }
                resolved_types = {}
                for display_name, variants in aliases.items():
                    found = next((waste_ids[v] for v in variants if v in waste_ids), None)
                    if found is not None:
                        resolved_types[display_name] = found

                required = {
                    name.strip().casefold()
                    for point in points
                    for name in point["types"]
                }
                missing = sorted(required - set(resolved_types))
                if missing:
                    raise RuntimeError(
                        "Tipos de resíduos ativos não encontrados no banco: "
                        + ", ".join(missing)
                        + ". Nenhuma alteração foi confirmada."
                    )

                # Remove somente os registros fictícios conhecidos e os registros
                # de mesmo nome/endereço do seed, preservando os demais pontos.
                managed_names = [p["nome"] for p in points]
                cursor.execute(
                    """
                    DELETE FROM waste_collection_point_types wcpt
                    USING collection_points cp
                    WHERE wcpt.collection_point_id = cp.id
                      AND (
                        cp.nome IN ('Ponto de Coleta Central', 'Ponto de Coleta 2', 'Ponto de Coleta 3')
                        OR cp.nome = ANY(%s)
                      )
                    """,
                    (managed_names,),
                )
                cursor.execute(
                    """
                    DELETE FROM collection_points
                    WHERE nome IN ('Ponto de Coleta Central', 'Ponto de Coleta 2', 'Ponto de Coleta 3')
                       OR nome = ANY(%s)
                    """,
                    (managed_names,),
                )

                for point in points:
                    display_types = point["types"]
                    cursor.execute(
                        """
                        INSERT INTO collection_points
                            (nome, endereco, tipos_residuos, latitude, longitude, origem)
                        VALUES (%s, %s, %s, %s, %s, %s)
                        RETURNING id
                        """,
                        (
                            point["nome"],
                            point["endereco"],
                            display_types,
                            point["latitude"],
                            point["longitude"],
                            point["origem"],
                        ),
                    )
                    point_id = cursor.fetchone()[0]
                    for display_type in display_types:
                        cursor.execute(
                            """
                            INSERT INTO waste_collection_point_types
                                (waste_type_id, collection_point_id)
                            VALUES (%s, %s)
                            ON CONFLICT DO NOTHING
                            """,
                            (resolved_types[display_type.casefold()], point_id),
                        )

        print(f"Cadastro concluído: {len(points)} pontos inseridos.")
        print("Os três pontos fictícios foram removidos dentro da mesma transação.")
        print("Observação: os endereços são candidatos da listagem municipal; confirme o funcionamento presencialmente.")
    finally:
        connection.close()


if __name__ == "__main__":
    main()
