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

	def test_strip
		res = DB.exec_params("INSERT INTO concepts (concept) VALUES ($1) RETURNING *", ["  \t \r \n hi \n\t \r  "])
		assert_equal 'hi', res[0]['concept']
	end
end

