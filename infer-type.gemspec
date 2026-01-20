lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
	spec.name        = 'infer-type'
	spec.version     = '0.1.1'
	spec.authors     = ["Convincible"]
	spec.email       = ["development@convincible.media"]

	spec.summary     = "Convert strings to other classes by inference, e.g. \"1\" to Integer."
	spec.description = "If a string is a representation of another class, such as \"1\", converts it to that other class. Works for basic Ruby types and can be extended."
	spec.homepage    = "https://github.com/ConvincibleMedia/ruby-gem-infer-type"
	spec.license     = "MIT"

	spec.files       = Dir['lib/**/*.rb']

	spec.required_ruby_version = ">= 2.1.0"

	# Dependencies
	

	# Development dependencies
	spec.add_development_dependency "bundler", "~> 1.17", ">= 1.17.3"
	spec.add_development_dependency "pry", "~> 0.14", ">= 0.14.1"
	spec.add_development_dependency "pry-byebug", "~> 3.4", ">= 3.4.0"
	spec.add_development_dependency "rspec", "~> 3.11", ">= 3.11.0"
end