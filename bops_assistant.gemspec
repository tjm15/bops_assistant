Gem::Specification.new do |s|
  s.name        = "bops_assistant"
  s.version     = File.read(File.expand_path("lib/bops_assistant/version.rb", __dir__)).match(/"(.+)"/)[1]
  s.authors     = ["you"]
  s.summary     = "BOPS Assistant engine"
  s.files       = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "README.md"]
  s.add_dependency "rails", ">= 7.0"
  s.add_dependency "kramdown", ">= 2.4"
end
