-- strip all line breaks, tabs, and spaces around concept before storing
CREATE FUNCTION clean_concept() RETURNS TRIGGER AS $$
BEGIN
	NEW.concept = btrim(regexp_replace(NEW.concept, '\s+', ' ', 'g'));
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;
CREATE TRIGGER clean_concept BEFORE INSERT OR UPDATE OF concept ON concepts FOR EACH ROW EXECUTE PROCEDURE clean_concept();

