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

-- 

CREATE FUNCTION get_country(integer, OUT mime text, OUT js text) AS $$
BEGIN
	mime := 'application/json';
	SELECT row_to_json(co) INTO js FROM
		(SELECT id, code, name, sqkm, (SELECT json_agg(ci) FROM
			(SELECT id, name FROM cities WHERE country_id = $1) ci) AS cities
		FROM countries WHERE id = $1) co;

	IF js IS NULL THEN
		mime := 'application/problem+json';
		js := '{"type": "about:blank", "title": "Not Found", "status": 404}';
	END IF;

END;
$$ LANGUAGE plpgsql;

CREATE FUNCTION get_city(integer, OUT mime text, OUT js text) AS $$
BEGIN
	mime := 'application/json';
	SELECT row_to_json(ci) INTO js FROM
		(SELECT id, country_id, name FROM cities WHERE id = $1) ci;

	IF js IS NULL THEN
		mime := 'application/problem+json';
		js := '{"type": "about:blank", "title": "Not Found", "status": 404}';
	END IF;

END;
$$ LANGUAGE plpgsql;

CREATE FUNCTION update_country(integer, json, OUT mime text, OUT js text) AS $$
DECLARE
	keyval record;
	tempval text;

	err_code text;
	err_msg text;
	err_detail text;
	err_context text;

BEGIN
	FOR keyval IN SELECT key, value FROM json_each($2) LOOP
		tempval := btrim(keyval.value::text, '"');
		EXECUTE 'UPDATE countries SET ' || quote_ident(keyval.key)
		|| ' = ' || quote_literal(tempval) || ' WHERE id=' || $1;
	END LOOP;
	SELECT x.mime, x.js INTO mime, js FROM get_country($1) x;

EXCEPTION
	WHEN OTHERS THEN GET STACKED DIAGNOSTICS
		err_code = RETURNED_SQLSTATE,
		err_msg = MESSAGE_TEXT,
		err_detail = PG_EXCEPTION_DETAIL,
		err_context = PG_EXCEPTION_CONTEXT;
	mime := 'application/problem+json';
	js := '{"type": ' || to_json('http://www.postgresql.org/docs/9.3/static/errcodes-appendix.html#' || err_code)
		|| ', "title": ' || to_json(err_msg)
		|| ', "detail": ' || to_json(err_detail || err_context) || '}';

END;
$$ LANGUAGE plpgsql;

CREATE FUNCTION update_city(integer, json, OUT mime text, OUT js text) AS $$
DECLARE
	keyval record;
	tempval text;

	err_code text;
	err_msg text;
	err_detail text;
	err_context text;

BEGIN
	FOR keyval IN SELECT key, value FROM json_each($2) LOOP
		tempval := btrim(keyval.value::text, '"');
		EXECUTE 'UPDATE cities SET ' || quote_ident(keyval.key)
		|| ' = ' || quote_literal(tempval) || ' WHERE id=' || $1;
	END LOOP;
	SELECT x.mime, x.js INTO mime, js FROM get_city($1) x;

EXCEPTION
	WHEN OTHERS THEN GET STACKED DIAGNOSTICS
		err_code = RETURNED_SQLSTATE,
		err_msg = MESSAGE_TEXT,
		err_detail = PG_EXCEPTION_DETAIL,
		err_context = PG_EXCEPTION_CONTEXT;
	mime := 'application/problem+json';
	js := '{"type": ' || to_json('http://www.postgresql.org/docs/9.3/static/errcodes-appendix.html#' || err_code)
		|| ', "title": ' || to_json(err_msg)
		|| ', "detail": ' || to_json(err_detail || err_context) || '}';

END;
$$ LANGUAGE plpgsql;

CREATE FUNCTION delete_country(integer, OUT mime text, OUT js text) AS $$
DECLARE

	err_code text;
	err_msg text;
	err_detail text;
	err_context text;

BEGIN
	SELECT x.mime, x.js INTO mime, js FROM get_country($1) x;
	EXECUTE 'DELETE FROM countries WHERE id=' || $1;

EXCEPTION
	WHEN OTHERS THEN GET STACKED DIAGNOSTICS
		err_code = RETURNED_SQLSTATE,
		err_msg = MESSAGE_TEXT,
		err_detail = PG_EXCEPTION_DETAIL,
		err_context = PG_EXCEPTION_CONTEXT;
	mime := 'application/problem+json';
	js := '{"type": ' || to_json('http://www.postgresql.org/docs/9.3/static/errcodes-appendix.html#' || err_code)
		|| ', "title": ' || to_json(err_msg)
		|| ', "detail": ' || to_json(err_detail || err_context) || '}';

END;
$$ LANGUAGE plpgsql;

CREATE FUNCTION delete_city(integer, OUT mime text, OUT js text) AS $$
DECLARE

	err_code text;
	err_msg text;
	err_detail text;
	err_context text;

BEGIN
	SELECT x.mime, x.js INTO mime, js FROM get_city($1) x;
	EXECUTE 'DELETE FROM cities WHERE id=' || $1;

EXCEPTION
	WHEN OTHERS THEN GET STACKED DIAGNOSTICS
		err_code = RETURNED_SQLSTATE,
		err_msg = MESSAGE_TEXT,
		err_detail = PG_EXCEPTION_DETAIL,
		err_context = PG_EXCEPTION_CONTEXT;
	mime := 'application/problem+json';
	js := '{"type": ' || to_json('http://www.postgresql.org/docs/9.3/static/errcodes-appendix.html#' || err_code)
		|| ', "title": ' || to_json(err_msg)
		|| ', "detail": ' || to_json(err_detail || err_context) || '}';

END;
$$ LANGUAGE plpgsql;

COMMIT;
