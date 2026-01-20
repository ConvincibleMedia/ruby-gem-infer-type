# frozen_string_literal: true

require_relative '../spec_helper'

RSpec.describe InferType::Parsers::IntegerParser do
	subject(:parser) { described_class.new }

	it "parses positive integers" do
		result = parser.parse("123")

		expect(result.parsed).to be(true)
		expect(result.value).to eq(123)
		expect(result.parser).to eq(described_class)
	end

	it "parses negative integers" do
		result = parser.parse("-42")

		expect(result.parsed).to be(true)
		expect(result.value).to eq(-42)
	end

	it "strips surrounding whitespace" do
		result = parser.parse(" 7 ")

		expect(result.parsed).to be(true)
		expect(result.value).to eq(7)
	end

	it "supports leading plus signs" do
		result = parser.parse("+5")

		expect(result.parsed).to be(true)
		expect(result.value).to eq(5)
	end

	it "removes leading zeros" do
		result = parser.parse("00018")

		expect(result.parsed).to be(true)
		expect(result.value).to eq(18)
	end

	it "parses zero and preserves sign if present" do
		result = parser.parse("0")

		expect(result.parsed).to be(true)
		expect(result.value).to eq(0)

		negative_zero = parser.parse("-0")

		expect(negative_zero.parsed).to be(true)
		expect(negative_zero.value).to eq(0)
	end

	it "returns failure for non-integer formats" do
		["", "abc", "1.2", "--1", "3-"].each do |input|
			expect(parser.parse(input).parsed).to be(false)
		end
	end
end