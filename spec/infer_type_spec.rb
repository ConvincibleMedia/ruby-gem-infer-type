# frozen_string_literal: true

require_relative 'spec_helper'

RSpec.describe InferType do
	describe ".parse" do
		it "raises ArgumentError when input is not a String" do
			expect { described_class.parse(123) }.to raise_error(ArgumentError, "Can only parse Strings")
		end

		it "parses trimmed strings without mutating the original input" do
			input = " 42 "

			expect(described_class.parse(input)).to eq(42)
			expect(input).to eq(" 42 ")
		end

		it "parses zero as Integer by default and as Float when prioritised" do
			expect(described_class.parse("0")).to eq(0)
			expect(described_class.parse("-0", Float, Integer)).to eq(0.0)
		end

		it "returns the original input when no parser matches" do
			input = "  not-a-match  "

			result = described_class.parse(input)

			expect(result).to equal(input)
			expect(result).to eq("  not-a-match  ")
		end

		it "respects allowed type priority" do
			expect(described_class.parse("1", Float, Integer)).to eq(1.0)
			expect(described_class.parse("1", Integer, Float)).to eq(1)
		end

		it "flattens nested allowed type arguments" do
			expect(described_class.parse("true", [FalseClass, [TrueClass]])).to eq(true)
		end

		it "raises KeyError when an allowed type has no registered parser" do
			unregistered_type = Class.new

			expect { described_class.parse("1", unregistered_type) }.to raise_error(KeyError, /No parser registered/)
		end

		it "raises TypeError when a parser does not return a Result" do
			custom_type = Class.new
			raw_return_parser = Class.new(InferType::Parser) do
				detects custom_type

				define_method(:parse) do |_str|
					custom_type.new
				end
			end

			InferType.register(raw_return_parser)

			expect { described_class.parse("unparseable") }.to raise_error(TypeError, /must return a Result object/)
		end

		it "raises TypeError when a parser returns a value of the wrong type" do
			invalid_integer_parser = Class.new(InferType::Parser) do
				detects Integer

				define_method(:parse) do |_str|
					success("not an integer")
				end
			end

			InferType.register(invalid_integer_parser)

			expect { described_class.parse("123", Integer) }.to raise_error(TypeError, /Parser returned a type other than the type it detects/)
		end
	end
end


