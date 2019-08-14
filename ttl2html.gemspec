Gem::Specification.new do |s|
  s.name        = 'ttl2html'
  s.version     = '0.0.1'
  s.date        = '2010-04-28'
  s.summary     = "ttl2html"
  s.description = "Static site generator for RDF/Turtle"
  s.authors     = ["Masao Takaku"]
  s.email       = 'tmasao@acm.org'
  s.files       = [ "lib/ttl2html.rb" ]
  s.files       += Dir["templates/*"]
  s.executables << "ttl2html"
  s.homepage    = 'https://github.org/masao/ttl2html'
  s.license     = 'MIT'
  s.add_dependency "nokogiri"
  s.add_dependency "rdf-turtle"
  s.add_dependency "ruby-progressbar"
  s.add_development_dependency "rspec"
  s.add_development_dependency "rake"
  s.add_development_dependency "capybara"
end
