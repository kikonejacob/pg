SET client_min_messages TO ERROR;
BEGIN;
DROP SCHEMA IF EXISTS sivers CASCADE;
CREATE SCHEMA sivers;

CREATE TABLE people (
	id serial primary key,
	name text,
	address text,
	city text,
	state text,
	postalcode text,
	phone text
);

-- This should:
-- copy phone (since old is longer)
-- skip city (since new is longer)
-- skip address (since equal)
-- skip state (since old is NULL)
-- copy postalcode (since new is NULL)
INSERT INTO people (name, address, city, state, postalcode, phone) VALUES ('Old Person', 'Address 1', '?', NULL, '02121', '1-312-920-1566');
INSERT INTO people (name, address, city, state, postalcode, phone) VALUES ('New Person', 'Address 2', 'Singapore', 'SG', NULL, 'n/a');

CREATE FUNCTION copylong1(old_id integer, new_id integer) RETURNS SETOF people AS $$
DECLARE
	old_person people;
	new_person people;
BEGIN
	SELECT * INTO old_person FROM people WHERE id = old_id;
	SELECT * INTO new_person FROM people WHERE id = new_id;
	IF COALESCE(LENGTH(old_person.address), 0) > COALESCE(LENGTH(new_person.address), 0) THEN
		UPDATE people SET address = old_person.address WHERE id = new_id;
	END IF;
	IF COALESCE(LENGTH(old_person.city), 0) > COALESCE(LENGTH(new_person.city), 0) THEN
		UPDATE people SET city = old_person.city WHERE id = new_id;
	END IF;
	IF COALESCE(LENGTH(old_person.state), 0) > COALESCE(LENGTH(new_person.state), 0) THEN
		UPDATE people SET state = old_person.state WHERE id = new_id;
	END IF;
	IF COALESCE(LENGTH(old_person.postalcode), 0) > COALESCE(LENGTH(new_person.postalcode), 0) THEN
		UPDATE people SET postalcode = old_person.postalcode WHERE id = new_id;
	END IF;
	IF COALESCE(LENGTH(old_person.phone), 0) > COALESCE(LENGTH(new_person.phone), 0) THEN
		UPDATE people SET phone = old_person.phone WHERE id = new_id;
	END IF;
	RETURN QUERY SELECT * FROM people WHERE id = new_id;
END;
$$ LANGUAGE plpgsql;


CREATE FUNCTION copylong2(old_id integer, new_id integer) RETURNS SETOF people AS $$
DECLARE
	old_person people;
	new_person people;
	colname text;
BEGIN
	SELECT * INTO old_person FROM people WHERE id = old_id;
	SELECT * INTO new_person FROM people WHERE id = new_id;
	FOREACH colname IN ARRAY ARRAY['address','city','state','postalcode','phone'] LOOP
	-- TODO: how to make dynamic version of copylong1 here?
	END LOOP;
	RETURN QUERY SELECT * FROM people WHERE id = new_id;
END;
$$ LANGUAGE plpgsql;


COMMIT;
