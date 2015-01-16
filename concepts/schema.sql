SET client_min_messages TO ERROR;
BEGIN;
DROP SCHEMA IF EXISTS sivers CASCADE;
CREATE SCHEMA sivers;

CREATE TABLE concepts (
	id serial primary key,
	concept text
);

COMMIT;

