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
	def test_project_status
		res = DB.exec_params("SELECT project_status(1)");
		assert_equal 'created', res[0]['project_status']
		res = DB.exec_params("SELECT project_status(2)");
		assert_equal 'quoted', res[0]['project_status']
		res = DB.exec_params("SELECT project_status(3)");
		assert_equal 'approved', res[0]['project_status']
		res = DB.exec_params("SELECT project_status(4)");
		assert_equal 'started', res[0]['project_status']
		res = DB.exec_params("SELECT project_status(5)");
		assert_equal 'finished', res[0]['project_status']
	end
end

