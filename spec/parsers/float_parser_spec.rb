# frozen_string_literal: true

require_relative '../spec_helper'

RSpec.describe InferType::Parsers::FloatParser do
	it "parses decimal numbers" do
		result = InferType.parse("1.5", Float)

		expect(result).to eq(1.5)
	end

	it "parses integers as floats when allowed" do
		result = InferType.parse("2", Float)

		expect(result).to eq(2.0)
	end

	it "parses exponent notation" do
		result = InferType.parse("1.5e2", Float)

		expect(result).to eq(150.0)
	end

	it "handles uppercase exponent notation with sign" do
		result = InferType.parse("2E-1", Float)

		expect(result).to eq(0.2)
	end

	it "trims surrounding whitespace" do
		result = InferType.parse(" 0.75 ", Float)

		expect(result).to eq(0.75)
	end

	it "returns failure for special values when not allowed" do
		expect(InferType.parse("NaN", Float)).to eq("NaN")
		expect(InferType.parse("Infinity", Float)).to eq("Infinity")
	end

	it "returns failure for invalid formats" do
		["", "abc", "1e", "1.", "1,0"].each do |input|
			expect(InferType.parse(input, Float)).to eq(input)
		end
	end

	it "parses zero (with or without sign) when integers are allowed" do
		expect(InferType.parse("0", Float)).to eq(0.0)
		expect(InferType.parse("-0", Float)).to eq(0.0)
	end
end
