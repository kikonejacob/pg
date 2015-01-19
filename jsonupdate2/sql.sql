SET client_min_messages TO ERROR;
BEGIN;
DROP SCHEMA IF EXISTS sivers CASCADE;
CREATE SCHEMA sivers;

-- example table for testing setting boolean, NULL, and NOW()

CREATE TABLE legends (
	id serial primary key,
	name varchar(32),
	birth_date date,
	alive boolean
);

INSERT INTO legends (name, birth_date, alive) VALUES ('Aesop', NULL, false);

CREATE FUNCTION update_legends(integer, json) RETURNS SETOF legends AS $$
DECLARE
	col record;
BEGIN
	FOR col IN SELECT name FROM json_object_keys($2) AS name LOOP
		CONTINUE WHEN col.name = 'id';
		EXECUTE 'UPDATE legends SET '
		|| quote_ident(col.name)
		|| ' = (SELECT ' || quote_ident(col.name)
		|| ' FROM json_populate_record(null::legends, $2)) WHERE id = $1'
		USING $1, $2;
	END LOOP;
	RETURN QUERY SELECT * FROM legends WHERE id = $1;
END;
$$ LANGUAGE plpgsql;

COMMIT;
