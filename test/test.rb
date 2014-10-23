ENV['RACK_ENV'] = 'test'
require 'minitest/autorun'
require 'rack/test'
require 'data_mapper'
require_relative '../model.rb'
 
include Rack::Test::Methods
 
def app
  Sinatra::Application
end

DataMapper.setup( :default, ENV['DATABASE_URL'] ||
                            "sqlite3://#{Dir.pwd}/pruebas.db" )

DataMapper::Logger.new($stdout, :debug)
DataMapper::Model.raise_on_save_failure = true

DataMapper.finalize

#DataMapper.auto_migrate!
DataMapper.auto_upgrade!


describe "Probando la base de datos" do
	
	before :all do
		@in1 = ShortenedUrl.first_or_create(:url => 'http://github.com', :url_corta => 'github', :usuario => '')
		@in2 = ShortenedUrl.first_or_create(:url => 'http://www.google.es', :url_corta => 'google', :usuario => 'prueba@prueba.com')
		
		@id1 = 1
		@url1 = 'http://github.com'
		@url_corta1 = 'github'
		@usuario1 = ''
		
		@id2 = 2
		@url2 = 'http://www.google.es'
		@url_corta2 = 'google'
		@usuario2 = 'prueba@prueba.com'
	end
	
	it "Comprobar que los valores insertados son correctos" do
		assert @id1, @in1.id
		assert @url1, @in1.url
		assert @url_corta1, @in1.url_corta
		assert @usuario1, @in1.usuario
		
		assert @id2, @in2.id
		assert @url2, @in2.url
		assert @url_corta2, @in2.url_corta
		assert @usuario2, @in2.usuario
	end
	
	it "Comprobar que no usa la misma id para dos entradas" do
		refute_equal @in1.id, @in2.id
	end
	
	it "Comprobar que se ha introducido un usuario en una entrada de la bd" do
		refute_equal @in2.usuario, @usuario1
	end
	
end