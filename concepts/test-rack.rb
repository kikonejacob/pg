require 'minitest/autorun'
require 'rack/test'
require 'json'

require_relative 'routes.rb'
class ConceptsAPITest < Minitest::Test
  include Rack::Test::Methods
	def app
		ConceptsAPI.new
	end

	def test_get_concept
		get '/concepts/1'
		js = JSON.load(last_response.body)
		assert_equal 'roses are red', js['concept']
	end
end
