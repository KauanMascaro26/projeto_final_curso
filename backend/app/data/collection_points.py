from app.models.collection_point import CollectionPoint


collection_points = [
    CollectionPoint(
        id=1,
        nome="Ponto de Coleta Central",
        endereco="São Carlos - SP",
        tipos_residuos=["papel", "plastico", "vidro", "metal"],
        latitude=-22.0174,
        longitude=-47.8908,
    ),
    CollectionPoint(
        id=2,
        nome="Ponto de Coleta 2",
        endereco="São Carlos - SP",
        tipos_residuos=["eletronicos", "pilhas", "baterias"],
        latitude=-22.0080,
        longitude=-47.8950,
    ),
    CollectionPoint(
        id=3,
        nome="Ponto de Coleta 3",
        endereco="São Carlos - SP",
        tipos_residuos=["plastico", "metal"],
        latitude=-22.0250,
        longitude=-47.8820,
    ),
]