SET client_min_messages TO ERROR;
BEGIN;
DROP SCHEMA IF EXISTS sivers CASCADE;
CREATE SCHEMA sivers;

CREATE TABLE countries (
	id serial primary key,
	code char(2) not null unique CONSTRAINT charcode CHECK (code ~ '[A-Z][A-Z]'),
	name varchar(64) not null unique,
	sqkm integer
);

CREATE TABLE cities (
	id serial primary key,
	country_id integer REFERENCES countries(id),
	name text
);

INSERT INTO countries (code, name, sqkm) VALUES ('TH', 'Thailand', 513120);
INSERT INTO cities (country_id, name) VALUES (1, 'Chiang Mai');

-- include(`defs.m4')

CREATE FUNCTION get_country(integer, OUT mime text, OUT js text) AS $$
BEGIN
	mime := 'application/json';
	SELECT row_to_json(co) INTO js FROM
		(SELECT id, code, name, sqkm, (SELECT json_agg(ci) FROM
			(SELECT id, name FROM cities WHERE country_id = $1) ci) AS cities
		FROM countries WHERE id = $1) co;
_NOTFOUND
END;
$$ LANGUAGE plpgsql;

CREATE FUNCTION get_city(integer, OUT mime text, OUT js text) AS $$
BEGIN
	mime := 'application/json';
	SELECT row_to_json(ci) INTO js FROM
		(SELECT id, country_id, name FROM cities WHERE id = $1) ci;
_NOTFOUND
END;
$$ LANGUAGE plpgsql;

CREATE FUNCTION update_country(integer, json, OUT mime text, OUT js text) AS $$
DECLARE
	keyval record;
	tempval text;
_ERRVARS
BEGIN
	FOR keyval IN SELECT key, value FROM json_each($2) LOOP
		tempval := btrim(keyval.value::text, '"');
		EXECUTE 'UPDATE countries SET ' || quote_ident(keyval.key)
		|| ' = ' || quote_literal(tempval) || ' WHERE id=' || $1;
	END LOOP;
	SELECT x.mime, x.js INTO mime, js FROM get_country($1) x;
_ERRCATCH
END;
$$ LANGUAGE plpgsql;

CREATE FUNCTION update_city(integer, json, OUT mime text, OUT js text) AS $$
DECLARE
	keyval record;
	tempval text;
_ERRVARS
BEGIN
	FOR keyval IN SELECT key, value FROM json_each($2) LOOP
		tempval := btrim(keyval.value::text, '"');
		EXECUTE 'UPDATE cities SET ' || quote_ident(keyval.key)
		|| ' = ' || quote_literal(tempval) || ' WHERE id=' || $1;
	END LOOP;
	SELECT x.mime, x.js INTO mime, js FROM get_city($1) x;
_ERRCATCH
END;
$$ LANGUAGE plpgsql;

CREATE FUNCTION delete_country(integer, OUT mime text, OUT js text) AS $$
DECLARE
_ERRVARS
BEGIN
	SELECT x.mime, x.js INTO mime, js FROM get_country($1) x;
	EXECUTE 'DELETE FROM countries WHERE id=' || $1;
_ERRCATCH
END;
$$ LANGUAGE plpgsql;

CREATE FUNCTION delete_city(integer, OUT mime text, OUT js text) AS $$
DECLARE
_ERRVARS
BEGIN
	SELECT x.mime, x.js INTO mime, js FROM get_city($1) x;
	EXECUTE 'DELETE FROM cities WHERE id=' || $1;
_ERRCATCH
END;
$$ LANGUAGE plpgsql;

COMMIT;
