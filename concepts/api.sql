-- USAGE: SELECT mime, js FROM get_concept(123);
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

