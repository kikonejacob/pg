-- SELECT * FROM concept_tags WHERE id = 1;
--id| created_at |    concept    |      tags      
----+------------+---------------+----------------
--1 | 2015-01-18 | roses are red | {flower,color}
CREATE VIEW concept_tags AS
	SELECT id, created_at, concept,
		array(SELECT tag FROM tags WHERE concept_id = concepts.id) AS tags
	FROM concepts;

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

