# frozen_string_literal: true

require_relative '../spec_helper'

RSpec.describe InferType::Parsers::IntegerParser do
	it "parses positive integers" do
		result = InferType.parse("123", Integer)

		expect(result).to eq(123)
	end

	it "parses negative integers" do
		result = InferType.parse("-42", Integer)

		expect(result).to eq(-42)
	end

	it "strips surrounding whitespace" do
		result = InferType.parse(" 7 ", Integer)

		expect(result).to eq(7)
	end

	it "supports leading plus signs" do
		result = InferType.parse("+5", Integer)

		expect(result).to eq(5)
	end

	it "removes leading zeros" do
		result = InferType.parse("00018", Integer)

		expect(result).to eq(18)
	end

	it "parses zero and preserves sign if present" do
		result = InferType.parse("0", Integer)

		expect(result).to eq(0)

		negative_zero = InferType.parse("-0", Integer)

		expect(negative_zero).to eq(0)
	end

	it "returns failure for non-integer formats" do
		["", "abc", "1.2", "--1", "3-"].each do |input|
			expect(InferType.parse(input, Integer)).to eq(input)
		end
	end
end
