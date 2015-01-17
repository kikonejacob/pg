SET client_min_messages TO ERROR;
BEGIN;
DROP SCHEMA IF EXISTS sivers CASCADE;
CREATE SCHEMA sivers;

CREATE TABLE concepts (
	id serial primary key,
	created_at date not null default current_date,
	concept text not null constraint not_empty check (length(concept) > 0)
);

CREATE TABLE tags(
	concept_id integer not null references concepts(id),
	tag varchar(32) not null constraint not_empty check (length(tag) > 0),
	primary key (concept_id, tag)
);

CREATE TABLE pairings (
	id serial primary key,
	created_at date not null default current_date,
	concept1_id integer not null references concepts(id),
	concept2_id integer not null references concepts(id),
	unique (concept1_id, concept2_id),
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

