SET client_min_messages TO ERROR;
BEGIN;
DROP SCHEMA IF EXISTS sivers CASCADE;
CREATE SCHEMA sivers;

CREATE TABLE concepts (
	id serial primary key,
	created_at date not null default current_date,
	concept text not null unique constraint not_empty check (length(concept) > 0)
);

CREATE TABLE tags(
	concept_id integer not null references concepts(id) on delete cascade,
	tag varchar(32) not null constraint not_empty check (length(tag) > 0),
	primary key (concept_id, tag)
);

-- TODO: check concept1_id and concept2_id are not equal
-- TODO: How to make 1/2 unique in any order?
-- TODO: concept1_id < concept2_id ?  whole 'nother structure?
CREATE TABLE pairings (
	id serial primary key,
	created_at date not null default current_date,
	concept1_id integer not null references concepts(id) on delete cascade,
	concept2_id integer not null references concepts(id) on delete cascade,
	-- unique (concept1_id, concept2_id),
	thoughts text
);

COMMIT;

-- strip all line breaks, tabs, and spaces around concept before storing
CREATE FUNCTION clean_concept() RETURNS TRIGGER AS $$
BEGIN
	NEW.concept = btrim(regexp_replace(NEW.concept, '\s+', ' ', 'g'));
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;
CREATE TRIGGER clean_concept BEFORE INSERT OR UPDATE OF concept ON concepts FOR EACH ROW EXECUTE PROCEDURE clean_concept();

-- lowercase and strip all line breaks, tabs, and spaces around tag before storing
CREATE FUNCTION clean_tag() RETURNS TRIGGER AS $$
BEGIN
	NEW.tag = lower(btrim(regexp_replace(NEW.tag, '\s+', ' ', 'g')));
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;
CREATE TRIGGER clean_tag BEFORE INSERT OR UPDATE OF tag ON tags FOR EACH ROW EXECUTE PROCEDURE clean_tag();

-- create a new pairing that hasn't been done yet
-- one way is to just randomly try some numbers until no match found
-- another way is a left join where pairings.*_id is null, then select from those
-- how to make sure it isn't just a pairing that's done in another 2<1 order?
CREATE FUNCTION new_pairing() RETURNS SETOF pairings AS $$
DECLARE
	id1 integer;
	id2 integer;
BEGIN
	-- TODO: not a good query yet! not sure how to fix
	SELECT c1.id, c2.id INTO id1, id2 FROM concepts c1, concepts c2, pairings WHERE (c1.id != pairings.concept1_id AND c2.id != pairings.concept2_id) AND c1.id < c2.id ORDER BY RANDOM();
	RETURN QUERY INSERT INTO pairings (concept1_id, concept2_id) VALUES (id1, id2) RETURNING *;
END;
$$ LANGUAGE plpgsql;

-- SELECT * FROM pairing_concepts WHERE id=1;
--id| created_at |      thoughts      |                             concepts                              
----+------------+--------------------+-------------------------------------------------------------------
--1 | 2015-01-18 | describing flowers | [{"id":1,"concept":"roses are red","tags":["flower","color"]},   +
--  |            |                    |  {"id":2,"concept":"violets are blue","tags":["flower","color"]}]
CREATE VIEW pairing_concepts AS
	SELECT id, created_at, thoughts,
		(SELECT json_agg(t) FROM
			(SELECT concepts.id, concept,
				ARRAY(SELECT tag FROM tags WHERE concept_id=concepts.id) AS tags
			FROM concepts WHERE id IN (concept1_id, concept2_id)
			ORDER BY id ASC)
		t) AS concepts
	FROM pairings;

BEGIN;
INSERT INTO concepts (concept) VALUES ('roses are red');
INSERT INTO concepts (concept) VALUES ('violets are blue');
INSERT INTO concepts (concept) VALUES ('sugar is sweet');
INSERT INTO tags VALUES (1, 'flower');
INSERT INTO tags VALUES (2, 'flower');
INSERT INTO tags VALUES (1, 'color');
INSERT INTO tags VALUES (2, 'color');
INSERT INTO tags VALUES (3, 'flavor');
INSERT INTO pairings (concept1_id, concept2_id, thoughts) VALUES (1, 2, 'describing flowers');
COMMIT;

-- USAGE: SELECT mime, js FROM get_concept(123);
-- JSON format for all *_concept functions below:
-- {"id":1,"created_at":"2015-01-17","concept":"roses are red","tags":("flower","color")}
CREATE FUNCTION get_concept(integer, OUT mime text, OUT js text) AS $$
BEGIN
	mime := 'application/json';
	SELECT row_to_json(co) INTO js FROM
		(SELECT id, created_at, concept,
			(SELECT array_to_json(array(
				SELECT tag FROM tags WHERE concept_id = concepts.id)) AS tags)
		FROM concepts WHERE id = $1) co;

	IF js IS NULL THEN
		mime := 'application/problem+json';
		js := '{"type": "about:blank", "title": "Not Found", "status": 404}';
	END IF;

END;
$$ LANGUAGE plpgsql;

-- give it an array of concept.ids.  Keep JSON format same as get_concept, but in array.
-- If none found, js is empty array
CREATE FUNCTION get_concepts(integer[], OUT mime text, OUT js text) AS $$
BEGIN
	mime := 'application/json';
	SELECT json_agg(co) INTO js FROM
		(SELECT id, created_at, concept,
			(SELECT array_to_json(array(
				SELECT tag FROM tags WHERE concept_id = concepts.id)) AS tags)
		FROM concepts WHERE id = ANY($1) ORDER BY id ASC) co;
	IF js IS NULL THEN
		js := array_to_json(array[]::text[]);
	END IF;
END;
$$ LANGUAGE plpgsql;

-- USAGE: SELECT mime, js FROM create_concept('some text here');
CREATE FUNCTION create_concept(text, OUT mime text, OUT js text) AS $$
DECLARE
	new_id integer;

	err_code text;
	err_msg text;
	err_detail text;
	err_context text;

BEGIN
	INSERT INTO concepts(concept) VALUES ($1) RETURNING id INTO new_id;
	SELECT x.mime, x.js INTO mime, js FROM get_concept(new_id) x;

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

-- USAGE: SELECT mime, js FROM update_concept(123, 'new text here');
CREATE FUNCTION update_concept(integer, text, OUT mime text, OUT js text) AS $$
DECLARE

	err_code text;
	err_msg text;
	err_detail text;
	err_context text;

BEGIN
	UPDATE concepts SET concept = $2 WHERE id = $1;
	SELECT x.mime, x.js INTO mime, js FROM get_concept($1) x;

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

-- USAGE: SELECT mime, js FROM delete_concept(123);
CREATE FUNCTION delete_concept(integer, OUT mime text, OUT js text) AS $$
BEGIN
	SELECT x.mime, x.js INTO mime, js FROM get_concept($1) x;
	DELETE FROM concepts WHERE id = $1;
END;
$$ LANGUAGE plpgsql;

-- USAGE: SELECT mime, js FROM tag_concept(123, 'newtag');
CREATE FUNCTION tag_concept(integer, text, OUT mime text, OUT js text) AS $$
DECLARE

	err_code text;
	err_msg text;
	err_detail text;
	err_context text;

BEGIN
	INSERT INTO tags (concept_id, tag) VALUES ($1, $2);
	SELECT x.mime, x.js INTO mime, js FROM get_concept($1) x;

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

-- USAGE: SELECT mime, js FROM tag_concepts(13, 24, 'newtag');
CREATE FUNCTION tag_concepts(integer, integer, text, OUT mime text, OUT js text) AS $$
DECLARE

	err_code text;
	err_msg text;
	err_detail text;
	err_context text;

BEGIN
	INSERT INTO tags (concept_id, tag) VALUES ($1, $3);
	INSERT INTO tags (concept_id, tag) VALUES ($2, $3);
	SELECT x.mime, x.js INTO mime, js FROM get_concepts(array[$1, $2]) x;

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

-- USAGE: SELECT mime, js FROM concepts_tagged('tagname');
-- Returns array of concepts or empty array if none found.
CREATE FUNCTION concepts_tagged(text, OUT mime text, OUT js text) AS $$
DECLARE
	ids integer[];
BEGIN
	SELECT array(SELECT concept_id FROM tags WHERE tag=$1) INTO ids;
	SELECT x.mime, x.js INTO mime, js FROM get_concepts(ids) x;
END;
$$ LANGUAGE plpgsql;

-- USAGE: SELECT mime, js FROM get_pairing(123);
-- {"id":1,"created_at":"2015-01-17","thoughts":"paired thoughts here","concepts":[{array of concepts with keys: id, concept, tags}]}
CREATE FUNCTION get_pairing(integer, OUT mime text, OUT js text) AS $$
BEGIN
	mime := 'application/json';
	SELECT row_to_json(r) INTO js FROM
		(SELECT * FROM pairing_concepts WHERE id = $1) r;

	IF js IS NULL THEN
		mime := 'application/problem+json';
		js := '{"type": "about:blank", "title": "Not Found", "status": 404}';
	END IF;

END;
$$ LANGUAGE plpgsql;

-- USAGE: SELECT mime, js FROM create_pairing();
CREATE FUNCTION create_pairing(OUT mime text, OUT js text) AS $$
DECLARE
	pid integer;
BEGIN
	SELECT id INTO pid FROM new_pairing();
	SELECT x.mime, x.js INTO mime, js FROM get_pairing(pid) x;
END;
$$ LANGUAGE plpgsql;

-- USAGE: SELECT mime, js FROM update_pairing(3, 'new thoughts here');
CREATE FUNCTION update_pairing(integer, text, OUT mime text, OUT js text) AS $$
DECLARE

	err_code text;
	err_msg text;
	err_detail text;
	err_context text;

BEGIN
	UPDATE pairings SET thoughts = $2 WHERE id = $1;
	SELECT x.mime, x.js INTO mime, js FROM get_pairing($1) x;

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

-- USAGE: SELECT mime, js FROM delete_pairing(123);
CREATE FUNCTION delete_pairing(integer, OUT mime text, OUT js text) AS $$
BEGIN
	SELECT x.mime, x.js INTO mime, js FROM get_pairing($1) x;
	DELETE FROM pairings WHERE id = $1;
END;
$$ LANGUAGE plpgsql;


