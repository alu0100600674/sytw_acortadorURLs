ENV['RACK_ENV'] = 'test'
require 'minitest/autorun'
require 'rack/test'
require_relative '../app.rb'
 
include Rack::Test::Methods
 
def app
  Sinatra::Application
end

describe "Contenido de la web" do
	
	it "Carga de la web" do
		get '/'
		assert last_response.ok?
	end
	
	it "Imagen de título de la web" do
		get '/'
		assert last_response.body.include?("<title>AcortadorURLs</title>")
	end
	
	it "Imagen título de la web mostrada" do
		get '/'
		assert last_response.body.include?("logo.png")
	end
	
	it "Campo para la inserción de una url" do
		get '/'
		assert last_response.body.include?("URL")
	end
	
	it "Campo para la inserción de una url corta" do
		get '/'
		assert last_response.body.include?("URL corta")
	end
	
end