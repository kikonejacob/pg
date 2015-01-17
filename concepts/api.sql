-- USAGE: SELECT mime, js FROM get_concept(123);
-- JSON format for all *_concept functions below:
-- {"id":1,"created_at":"2015-01-17","concept":"roses are red","tags":("flower","color")}
CREATE FUNCTION get_concept(integer, OUT mime text, OUT js text) AS $$
BEGIN
	mime := 'application/json';
	SELECT row_to_json(co) INTO js FROM
		(SELECT id, created_at, concept,
			(SELECT array_to_json(array(
				SELECT tag FROM tags WHERE concept_id = $1)) AS tags)
		FROM concepts WHERE id = $1) co;
_NOTFOUND
END;
$$ LANGUAGE plpgsql;

-- USAGE: SELECT mime, js FROM create_concept('some text here');
CREATE FUNCTION create_concept(text, OUT mime text, OUT js text) AS $$
DECLARE
	new_id integer;
_ERRVARS
BEGIN
	INSERT INTO concepts(concept) VALUES ($1) RETURNING id INTO new_id;
	SELECT x.mime, x.js INTO mime, js FROM get_concept(new_id) x;
_ERRCATCH
END;
$$ LANGUAGE plpgsql;

-- USAGE: SELECT mime, js FROM update_concept(123, 'new text here');
CREATE FUNCTION update_concept(integer, text, OUT mime text, OUT js text) AS $$
DECLARE
_ERRVARS
BEGIN
	UPDATE concepts SET concept = $2 WHERE id = $1;
	SELECT x.mime, x.js INTO mime, js FROM get_concept($1) x;
_ERRCATCH
END;
$$ LANGUAGE plpgsql;

-- USAGE: SELECT mime, js FROM delete_concept(123);
CREATE FUNCTION delete_concept(integer, OUT mime text, OUT js text) AS $$
BEGIN
	SELECT x.mime, x.js INTO mime, js FROM get_concept($1) x;
	DELETE FROM concepts WHERE id = $1;
END;
$$ LANGUAGE plpgsql;


