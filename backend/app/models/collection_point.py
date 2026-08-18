from pydantic import BaseModel


class CollectionPoint(BaseModel):
    id: int
    nome: str
    endereco: str
    tipos_residuos: list[str]
    latitude: float
    longitude: float