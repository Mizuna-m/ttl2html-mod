Gem::Specification.new do |s|
  s.name        = 'ttl2html'
  s.version     = '1.3.3'
  s.date        = '2021-12-29'
  s.summary     = "ttl2html"
  s.description = "Static site generator for RDF/Turtle"
  s.authors     = ["Masao Takaku"]
  s.email       = 'tmasao@acm.org'
  s.files       = [
    "lib/ttl2html.rb", "lib/ttl2html/version.rb", "lib/ttl2html/template.rb",
    "lib/xlsx2shape.rb",
  ]
  s.files       += Dir["templates/*", "locales/*"]
  s.executables += ["ttl2html", "xlsx2shape", "catttl"]
  s.homepage    = 'https://github.com/masao/ttl2html'
  s.license     = 'MIT'
  s.add_dependency "nokogiri"
  s.add_dependency "rdf-turtle"
  s.add_dependency "roo"
  s.add_dependency "i18n"
  s.add_dependency "ruby-progressbar"
  s.add_dependency "actionview"
  s.add_development_dependency "rspec"
  s.add_development_dependency "rake"
  s.add_development_dependency "capybara"
end
