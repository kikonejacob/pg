require 'sinatra/base'
require 'pg'
require 'json'
DB = PG::Connection.new(dbname: 'sivers', user: 'sivers')

class ConceptsAPI < Sinatra::Base
	
	after do
		content_type @res[0]['mime']
		body @res[0]['js']
		if @res[0]['mime'].include? 'problem'
			if @res[0]['js'].include? '"status": 404'
				status 404
			else
				status 400
			end
		end
	end

	get %r{\A/concepts/([0-9]+)\Z} do |id|
		@res = DB.exec_params("SELECT mime, js FROM get_concept($1)", [id])
	end
	
	post '/concepts' do
		@res = DB.exec_params("SELECT mime, js FROM create_concept($1)", [params[:concept]])
	end
	
	put %r{\A/concepts/([0-9]+)\Z} do |id|
		@res = DB.exec_params("SELECT mime, js FROM update_concept($1, $2)", [id, params[:concept]])
	end
	
	delete %r{\A/concepts/([0-9]+)\Z} do |id|
		@res = DB.exec_params("SELECT mime, js FROM delete_concept($1)", [id])
	end

	post %r{\A/concepts/([0-9]+)/tag\Z} do |id|
		@res = DB.exec_params("SELECT mime, js FROM tag_concept($1, $2)", [id, params[:tag]])
	end
	
	get '/concepts/tag' do
		@res = DB.exec_params("SELECT mime, js FROM concepts_tagged($1)", [params[:tag]])
	end
	
	get %r{\A/pairings/([0-9]+)\Z} do |id|
		@res = DB.exec_params("SELECT mime, js FROM get_pairing($1)", [id])
	end
	
	post '/pairings' do
		@res = DB.exec("SELECT mime, js FROM create_pairing()")
	end
	
	put %r{\A/pairings/([0-9]+)\Z} do |id|
		@res = DB.exec_params("SELECT mime, js FROM update_pairing($1, $2)", [id, params[:thoughts]])
	end
	
	delete %r{\A/pairings/([0-9]+)\Z} do |id|
		@res = DB.exec_params("SELECT mime, js FROM delete_pairing($1)", [id])
	end

	post %r{\A/pairings/([0-9]+)/tag\Z} do |id|
		@res = DB.exec_params("SELECT mime, js FROM tag_pairing($1, $2)", [id, params[:tag]])
	end
	
end

