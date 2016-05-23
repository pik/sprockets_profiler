$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "sprockets_profiler/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "sprockets_profiler"
  s.version     = SprocketsProfiler::VERSION
  s.authors     = ["pik"]
  s.email       = ["alexander.maznev@gmail.com"]
#  s.homepage    = "TODO"
  s.summary     = ""
#  s.description = "TODO: Description of SprocketsProfiler."
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.rdoc"]
  s.test_files = Dir["test/**/*"]

  s.add_dependency "rails", "~> 4.2.6"

  s.add_development_dependency "sqlite3"
end
