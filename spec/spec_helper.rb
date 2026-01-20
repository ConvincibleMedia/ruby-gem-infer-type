# frozen_string_literal: true

require_relative 'spec_helper'

ENV['RACK_ENV'] ||= 'test'
require 'rspec'
require_relative '../lib/infer_type'

module RegistryHelpers
	def reset_registry(parsers)
		new_registry = InferType::Registry.new
		parsers.each { |parser| new_registry.register(parser) }
		InferType.instance_variable_set(:@registry, new_registry)
		new_registry
	end
end

RSpec.configure do |config|
	config.color     = true
	config.formatter = :documentation
	config.expect_with :rspec do |c|
		c.syntax = :expect
	end

	config.include RegistryHelpers

	config.around do |example|
		original_parsers = InferType.send(:registry).parsers
		example.run
		reset_registry(original_parsers)
	end
end

