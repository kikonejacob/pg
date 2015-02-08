SET client_min_messages TO ERROR;
BEGIN;
DROP SCHEMA IF EXISTS sivers CASCADE;
CREATE SCHEMA sivers;

CREATE TABLE people (
	id serial primary key,
	name text,
	address text,
	city text,
	phone text
);

-- This should:
-- copy phone (since old is longer)
-- skip city (since new is longer)
-- skip address (since equal)
INSERT INTO people (name, address, city, phone) VALUES ('Old Person', 'Address 1', '?', '1-312-920-1566');
INSERT INTO people (name, address, city, phone) VALUES ('New Person', 'Address 2', 'Singapore', 'n/a');

CREATE FUNCTION copylong1(old_id integer, new_id integer) RETURNS SETOF people AS $$
DECLARE
	old_person people;
	new_person people;
BEGIN
	SELECT * INTO old_person FROM people WHERE id = old_id;
	SELECT * INTO new_person FROM people WHERE id = new_id;
	IF LENGTH(old_person.address) > LENGTH(new_person.address) THEN
		UPDATE people SET address = old_person.address WHERE id = new_id;
	END IF;
	IF LENGTH(old_person.city) > LENGTH(new_person.city) THEN
		UPDATE people SET city = old_person.city WHERE id = new_id;
	END IF;
	IF LENGTH(old_person.phone) > LENGTH(new_person.phone) THEN
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
	FOREACH colname IN ARRAY ARRAY['address','city','phone'] LOOP
	-- TODO: how to make dynamic version of copylong1 here?
	END LOOP;
	RETURN QUERY SELECT * FROM people WHERE id = new_id;
END;
$$ LANGUAGE plpgsql;


COMMIT;
