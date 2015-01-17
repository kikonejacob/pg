CREATE FUNCTION get_concept(integer, OUT mime text, OUT js text) AS $$
BEGIN
	mime := 'application/json';
	SELECT row_to_json(co) INTO js FROM
		(SELECT id, created_at, concept, (SELECT array_to_json(t) FROM
			(SELECT tag FROM tags WHERE concept_id = $1) t) AS tags
		FROM concepts WHERE id = $1) co;
END;
$$ LANGUAGE plpgsql;

