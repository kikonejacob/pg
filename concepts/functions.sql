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

