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

-- TODO: check concept1_id and concept2_id are not equal
-- TODO: How to make 1/2 unique in any order?
-- TODO: concept1_id < concept2_id ?  whole 'nother structure?
CREATE TABLE pairings (
	id serial primary key,
	created_at date not null default current_date,
	concept1_id integer not null references concepts(id),
	concept2_id integer not null references concepts(id),
	-- unique (concept1_id, concept2_id),
	thoughts text
);

COMMIT;

