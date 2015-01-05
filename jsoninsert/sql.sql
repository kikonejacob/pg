SET client_min_messages TO ERROR;
BEGIN;
DROP SCHEMA IF EXISTS sivers CASCADE;
CREATE SCHEMA sivers;

CREATE TABLE legends (
	id serial primary key,
	name varchar(32),
	birth_date date DEFAULT current_date,
	alive boolean
);

CREATE FUNCTION jsoninsert(table_name text, new_values json) RETURNS void AS $$
DECLARE
BEGIN
END;
$$ LANGUAGE plpgsql;

COMMIT;

