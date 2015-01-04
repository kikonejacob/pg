SET client_min_messages TO ERROR;
BEGIN;
DROP SCHEMA IF EXISTS jsonupdate CASCADE;
CREATE SCHEMA jsonupdate;
SET search_path = jsonupdate;

-- example table for testing setting boolean, NULL, and NOW()

CREATE TABLE legends (
	id serial primary key,
	name varchar(32),
	birth_date date,
	alive boolean
);

INSERT INTO legends (name, birth_date, alive) VALUES ('Aesop', NULL, false);

-- yes, primary_key will always be integer
CREATE FUNCTION jsonupdate(table_name text, primary_key integer, new_values json) RETURNS void AS $$
DECLARE
	keyval record;
	tempval text;
BEGIN
	FOR keyval IN SELECT key, value FROM json_each(new_values) LOOP
		tempval := btrim(keyval.value::text, '"'); -- better way to remove the quotes JSON adds?
		IF tempval != 'NULL' THEN -- better way to handle NULL?
			tempval := quote_literal(tempval);
		END IF;
		-- benefits to making multi-column UPDATE statement, instead of many separate ones?
		EXECUTE 'UPDATE ' || quote_ident(table_name)
		|| ' SET ' || quote_ident(keyval.key) || ' = ' || tempval
		|| ' WHERE id=' || primary_key;
	END LOOP;
END;
$$ LANGUAGE plpgsql;

COMMIT;

