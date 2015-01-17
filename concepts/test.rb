require 'pg'
require 'minitest/autorun'
require 'json'

DB = PG::Connection.new(dbname: 'sivers', user: 'sivers')
SQL = File.read('sql.sql')

class Minitest::Test
	def setup
		DB.exec(SQL)
	end
end
Minitest.after_run do
	DB.exec(SQL)
end

class SqlTest < Minitest::Test
	def test_not_null
		assert_raises PG::NotNullViolation do
			DB.exec("INSERT INTO concepts (concept) VALUES (NULL)")
		end
	end

	def test_not_empty
		err = assert_raises PG::CheckViolation do
			DB.exec("INSERT INTO concepts (concept) VALUES ('')")
		end
		assert err.message.include? 'not_empty'
	end

	def test_clean_concept
		res = DB.exec_params("INSERT INTO concepts (concept) VALUES ($1) RETURNING *", ["  \t \r \n hi \n\t \r  "])
		assert_equal 'hi', res[0]['concept']
	end

	def test_clean_tag
		res = DB.exec_params("INSERT INTO tags (concept_id, tag) VALUES ($1, $2) RETURNING *", [2, " \t\r\n BaNG \n\t "])
		assert_equal 'bang', res[0]['tag']
	end

	def test_create_pairing
		res = DB.exec("SELECT * FROM create_pairing()")
		assert res[0]['id'].to_i > 1
		assert res[0]['concept1_id'].to_i > 0
		assert res[0]['concept2_id'].to_i > 0
	end

	def test_tag_both
		res = DB.exec("SELECT * FROM tag_both(2, 3, ' GREAT \t ')")
		assert_equal 5, res.ntuples
		assert res.find {|x| x['concept_id'] == '2' && x['tag'] == 'great' }
		assert res.find {|x| x['concept_id'] == '3' && x['tag'] == 'great' }
	end

	def test_get_concept
		res = DB.exec("SELECT mime, js FROM get_concept(1)")
		js = JSON.parse(res[0]['js'])
		assert_equal 'application/json', res[0]['mime']
		assert_equal %w(id created_at concept tags), js.keys
		assert_equal %w(color flower), js['tags'].sort
		assert_equal 'roses are red', js['concept']
	end

	def test_get_concept_404
		res = DB.exec("SELECT mime, js FROM get_concept(999)")
		js = JSON.parse(res[0]['js'])
		assert_equal 'application/problem+json', res[0]['mime']
		assert_equal 'about:blank', js['type']
		assert_equal 'Not Found', js['title']
		assert_equal 404, js['status']
	end

	def test_create_concept
		res = DB.exec("SELECT mime, js FROM create_concept(' River running ')")
		assert_equal 'application/json', res[0]['mime']
		js = JSON.parse(res[0]['js'])
		assert_equal 4, js['id']
		assert_equal 'River running', js['concept']
		assert_equal [], js['tags']
	end

	def test_update_concept
		res = DB.exec("SELECT mime, js FROM update_concept(3, 'sugar is sticky ')")
		assert_equal 'application/json', res[0]['mime']
		js = JSON.parse(res[0]['js'])
		assert_equal 3, js['id']
		assert_equal 'sugar is sticky', js['concept']
		assert_equal %w(flavor), js['tags']
		res = DB.exec("SELECT mime, js FROM update_concept(999, 'should return 404')")
		assert_equal 'application/problem+json', res[0]['mime']
		js = JSON.parse(res[0]['js'])
		assert_equal 'Not Found', js['title']
	end

	def test_delete_concept
		res = DB.exec("SELECT mime, js FROM delete_concept(1)")
		assert_equal 'application/json', res[0]['mime']
		js = JSON.parse(res[0]['js'])
		assert_equal 'roses are red', js['concept']
		res = DB.exec("SELECT mime, js FROM delete_concept(1)")
		assert_equal 'application/problem+json', res[0]['mime']
		js = JSON.parse(res[0]['js'])
		assert_equal 'Not Found', js['title']
	end

	def test_update_err
		res = DB.exec("SELECT mime, js FROM update_concept(1, '')")
		assert_equal 'application/problem+json', res[0]['mime']
		js = JSON.parse(res[0]['js'])
		assert_match /23514$/, js['type']
		assert_match /not_empty/, js['title']
		assert_match /^Failing row/, js['detail']
		res = DB.exec("SELECT mime, js FROM update_concept(1, NULL)")
		js = JSON.parse(res[0]['js'])
		assert_match /23502$/, js['type']
		assert_match /not-null/, js['title']
		assert_match /^Failing row/, js['detail']
	end

	def test_create_err
		res = DB.exec("SELECT mime, js FROM create_concept('roses are red')")
		js = JSON.parse(res[0]['js'])
		assert_match /23505$/, js['type']
		assert_match /unique constraint/, js['title']
		res = DB.exec("SELECT mime, js FROM create_concept(NULL)")
		js = JSON.parse(res[0]['js'])
		assert_match /23502$/, js['type']
		assert_match /not-null/, js['title']
		assert_match /^Failing row/, js['detail']
	end
end

