SET client_min_messages TO ERROR;
BEGIN;
DROP SCHEMA IF EXISTS sivers CASCADE;
CREATE SCHEMA sivers;

-- constraints to play with: named, unique, length, value type, & foreign key

CREATE TABLE countries (
	id serial primary key,
	code char(2) not null unique CONSTRAINT charcode (code ~ '[A-Z][A-Z]'),
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

COMMIT;

