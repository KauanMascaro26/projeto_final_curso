from app.database import get_connection

connection = get_connection()

print("Conexão com PostgreSQL realizada com sucesso!")

connection.close()