# frozen_string_literal: true

require_relative '../spec_helper'

RSpec.describe InferType::Parsers::FloatParser do
	subject(:parser) { described_class.new }

	it "parses decimal numbers" do
		result = parser.parse("1.5")

		expect(result.parsed).to be(true)
		expect(result.value).to eq(1.5)
	end

	it "parses integers as floats when allowed" do
		result = parser.parse("2")

		expect(result.parsed).to be(true)
		expect(result.value).to eq(2.0)
	end

	it "parses exponent notation" do
		result = parser.parse("1.5e2")

		expect(result.parsed).to be(true)
		expect(result.value).to eq(150.0)
	end

	it "handles uppercase exponent notation with sign" do
		result = parser.parse("2E-1")

		expect(result.parsed).to be(true)
		expect(result.value).to eq(0.2)
	end

	it "trims surrounding whitespace" do
		result = parser.parse(" 0.75 ")

		expect(result.parsed).to be(true)
		expect(result.value).to eq(0.75)
	end

	it "returns failure for special values when not allowed" do
		expect(parser.parse("NaN").parsed).to be(false)
		expect(parser.parse("Infinity").parsed).to be(false)
	end

	it "returns failure for invalid formats" do
		["", "abc", "1e", "1.", "1,0"].each do |input|
			expect(parser.parse(input).parsed).to be(false)
		end
	end

	it "parses zero (with or without sign) when integers are allowed" do
		expect(parser.parse("0").value).to eq(0.0)
		expect(parser.parse("-0").value).to eq(0.0)
	end
end