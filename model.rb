require 'dm-core'
require 'dm-migrations'
require 'restclient'
require 'xmlsimple'
require 'dm-timestamps'

class ShortenedUrl
  include DataMapper::Resource

  property :id, Serial
  property :url, Text
  property :url_corta, Text
  property :usuario, Text
  property :n_visits, Integer

  has n, :visits
end

class Visit
  include DataMapper::Resource

  property :id, Serial
  property :created_at, DateTime
  property :ip, IPAddress
  property :country, String

  belongs_to :shortened_url

  before :create, :set_country

  def set_country
    xml = RestClient.get "http://ip-api.com/xml/#{self.ip}"
    self.country = XmlSimple.xml_in(xml.to_s, { 'ForceArray' => false })['country'].to_s
    self.save
  end

  def self.contador_fecha(id)
    repository(:default).adapter.select("SELECT date(created_at) AS date, count(*) AS count FROM visits WHERE shortened_url_id = '#{id}' GROUP BY date(created_at)")
  end

  def self.contador_pais(id)
    repository(:default).adapter.select("SELECT country, count(*) as count FROM visits where shortened_url_id= '#{id}' group by country")
  end

end
