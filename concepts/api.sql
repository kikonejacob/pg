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
NOTFOUND
END;
$$ LANGUAGE plpgsql;

-- USAGE: SELECT mime, js FROM create_concept('some text here');
CREATE FUNCTION create_concept(text, OUT mime text, OUT js text) AS $$
DECLARE
	new_id integer;
ERRVARS
BEGIN
	INSERT INTO concepts(concept) VALUES ($1) RETURNING id INTO new_id;
	SELECT x.mime, x.js INTO mime, js FROM get_concept(new_id) x;
ERRCATCH
END;
$$ LANGUAGE plpgsql;

-- USAGE: SELECT mime, js FROM update_concept(123, 'new text here');
CREATE FUNCTION update_concept(integer, text, OUT mime text, OUT js text) AS $$
DECLARE
ERRVARS
BEGIN
	UPDATE concepts SET concept = $2 WHERE id = $1;
	SELECT x.mime, x.js INTO mime, js FROM get_concept($1) x;
ERRCATCH
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
ERRVARS
BEGIN
	INSERT INTO tags (concept_id, tag) VALUES ($1, $2);
	SELECT x.mime, x.js INTO mime, js FROM get_concept($1) x;
ERRCATCH
END;
$$ LANGUAGE plpgsql;

-- USAGE: SELECT mime, js FROM tag_concepts(13, 24, 'newtag');
CREATE FUNCTION tag_concepts(integer, integer, text, OUT mime text, OUT js text) AS $$
DECLARE
ERRVARS
BEGIN
	INSERT INTO tags (concept_id, tag) VALUES ($1, $3);
	INSERT INTO tags (concept_id, tag) VALUES ($2, $3);
	-- TODO: probably don't need tag_both
ERRCATCH
END;
$$ LANGUAGE plpgsql;

