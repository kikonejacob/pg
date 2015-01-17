require 'pg'
require 'minitest/autorun'

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
end

