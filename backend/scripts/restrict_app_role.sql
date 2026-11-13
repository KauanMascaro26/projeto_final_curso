-- Execute conectado ao banco descarte_inteligente como usuario administrador (postgres).
-- O backend atual realiza apenas consultas; por isso descarte_app deve ser somente leitura.
-- Este script nao altera nem remove dados.

REVOKE TEMPORARY ON DATABASE descarte_inteligente FROM descarte_app;
GRANT CONNECT ON DATABASE descarte_inteligente TO descarte_app;

GRANT USAGE ON SCHEMA public TO descarte_app;
REVOKE CREATE ON SCHEMA public FROM descarte_app;

REVOKE INSERT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER
ON ALL TABLES IN SCHEMA public FROM descarte_app;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO descarte_app;

REVOKE ALL PRIVILEGES
ON ALL SEQUENCES IN SCHEMA public FROM descarte_app;

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public
REVOKE INSERT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER ON TABLES FROM descarte_app;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public
GRANT SELECT ON TABLES TO descarte_app;

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public
REVOKE ALL ON SEQUENCES FROM descarte_app;
