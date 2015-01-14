SET client_min_messages TO ERROR;
BEGIN;
DROP SCHEMA IF EXISTS sivers CASCADE;
CREATE SCHEMA sivers;

-- constraints to make errors with: named, unique, length, value type, & foreign key

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

-- Really I'm just making these functions so I can get errors out of them.

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

-- SELECT mime, js FROM update_country(1, '{"name":"ประเทศไทย", "sqkm":1234}');
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
	-- Instead of UPDATE returning "not found" for 0 update, this will do it:
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

-- NOTE how it's almost identical to update_country, with so much repetition,
-- especially error catching. Now imagine 50+ more functions similar to this!
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

-- etc…
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

-- etc…
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
