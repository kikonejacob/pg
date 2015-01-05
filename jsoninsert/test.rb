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
	def test_regular_insert
		res = DB.exec_params("SELECT jsoninsert($1, $2)", ['legends', '{"name": "Dude", "alive": true}'])
		assert_equal 'Dude', res[0]['name']
		assert_equal 't', res[0]['alive']
		assert_equal Time.now.to_s[0,10], res[0]['birth_date']
	end

	def test_null
		res = DB.exec_params("SELECT jsoninsert($1, $2)", ['legends', '{"name": "Mystery", "alive": "NULL"}'])
		assert_nil res[0]['alive']
	end

	def test_now
		res = DB.exec_params("SELECT jsoninsert($1, $2)", ['legends', '{"name": "Baby", "birth_date": "NOW()"}'])
		assert_equal Time.now.to_s[0,10], res[0]['birth_date']
	end
end

