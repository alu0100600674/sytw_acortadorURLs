class ShortenedUrl
  include DataMapper::Resource

  property :id, Serial
  property :url, Text
  property :url_corta, Text
  property :usuario, Text
end

class Visitas
  include DataMapper::Resource

  property :url_corta, Text
  property :n_visitas, Serial
end
