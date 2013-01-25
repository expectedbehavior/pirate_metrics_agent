$:.push File.expand_path("../lib", __FILE__)
require "pirate_metrics/version"

Gem::Specification.new do |s|
  s.name        = "pirate_metrics_agent"
  s.version     = PirateMetrics::VERSION
  s.authors     = ["Fastest Forward", "Expected Behavior"]
  s.email       = ["support@piratemetrics.com"]
  s.homepage    = "http://piratemetrics.com"
  s.summary     = %q{Agent for reporting data to piratemetrics.com}
  s.description = %q{Get to know your customers.}

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
  s.add_dependency(%q<faraday>, ["~> 0.8"])
  s.add_development_dependency(%q<rake>, [">= 0"])
  s.add_development_dependency(%q<rack>, [">= 0"])
  s.add_development_dependency(%q<rspec>, ["~> 2.0"])
  s.add_development_dependency(%q<fuubar>, [">= 0"])
  if RUBY_VERSION >= "1.8.7"
    s.add_development_dependency(%q<pry>, ["~> 0.9"])
    s.add_development_dependency(%q<guard>, [">= 0"])
    s.add_development_dependency(%q<guard-rspec>, [">= 0"])
    s.add_development_dependency(%q<growl>, [">= 0"])
    s.add_development_dependency(%q<rb-fsevent>, [">= 0"])
  end
end
