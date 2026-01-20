# frozen_string_literal: true

require_relative 'spec_helper'

RSpec.describe InferType::Registry do
	let(:registry) { InferType.send(:registry) }

	describe "#register" do
		it "appends a new parser and returns nil" do
			custom_type = Class.new
			custom_parser = Class.new(InferType::Parser) do
				detects custom_type

				define_method(:parse) { |_str| failure }
			end

			expect(registry.register(custom_parser)).to be_nil
			expect(registry.parsers.last).to eq(custom_parser)
		end

		it "replaces an existing parser for the same type and returns the old parser" do
			original_index = registry.parsers.index(InferType::Parsers::IntegerParser)

			replacement = Class.new(InferType::Parser) do
				detects Integer

				define_method(:parse) { |_str| failure }
			end

			old = registry.register(replacement)

			expect(old).to eq(InferType::Parsers::IntegerParser)
			expect(registry.parsers[original_index]).to eq(replacement)
		end

		it "raises when the parser does not subclass InferType::Parser" do
			invalid_parser = Class.new

			expect { registry.register(invalid_parser) }.to raise_error(ArgumentError, /Parser must subclass InferType::Parser/)
		end

		it "raises when the parser does not declare a detected type" do
			parser_class = Class.new(InferType::Parser) do
				define_method(:parse) { |_str| failure }
			end

			expect { registry.register(parser_class) }.to raise_error(ArgumentError, /Parser must declare the type it detects/)
		end

		it "raises when the parser does not define #parse" do
			parser_class = Class.new(InferType::Parser) do
				detects Class.new
			end

			expect { registry.register(parser_class) }.to raise_error(ArgumentError, /Parser must define #parse/)
		end

		it "raises when #parse accepts more than one argument" do
			parser_class = Class.new(InferType::Parser) do
				detects Class.new

				define_method(:parse) { |_str, _other| failure }
			end

			expect { registry.register(parser_class) }.to raise_error(ArgumentError, /#parse must accept exactly one argument/)
		end
	end

	describe "#parser_for_type" do
		it "returns the parser registered for the given type" do
			expect(registry.parser_for_type(Integer)).to eq(InferType::Parsers::IntegerParser)
		end

		it "returns nil when no parser is registered for the type" do
			unregistered = Class.new

			expect(registry.parser_for_type(unregistered)).to be_nil
		end
	end

	describe "#deregister" do
		it "removes parsers by class" do
			registry.deregister(InferType::Parsers::FloatParser)

			expect(registry.parsers).not_to include(InferType::Parsers::FloatParser)
		end
	end

	describe "#prioritize" do
		it "moves parser classes to the front in the given order" do
			registry.prioritize(InferType::Parsers::TimeParser, InferType::Parsers::DateParser)

			expect(registry.parsers.first(2)).to eq([InferType::Parsers::TimeParser, InferType::Parsers::DateParser])
		end

		it "accepts types and moves their parsers to the front" do
			registry.prioritize(Date)

			expect(registry.parsers.first).to eq(InferType::Parsers::DateParser)
		end

		it "raises when a given type has no parser" do
			unregistered = Class.new

			expect { registry.prioritize(unregistered) }.to raise_error(KeyError, /No parser registered/)
		end
	end

	describe "#deprioritize" do
		it "moves parser classes to the back" do
			registry.deprioritize(InferType::Parsers::IntegerParser)

			expect(registry.parsers.last).to eq(InferType::Parsers::IntegerParser)
		end

		it "accepts types when moving parsers to the back" do
			registry.deprioritize(Float)

			expect(registry.parsers.last).to eq(InferType::Parsers::FloatParser)
		end
	end
end