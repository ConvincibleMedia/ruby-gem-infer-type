# frozen_string_literal: true

require_relative '../spec_helper'

RSpec.describe InferType::Parsers::ArrayParser do
	before do
		InferType.register(described_class)
	end

	it "parses arrays containing allowed literals" do
		result = InferType.parse('[-1, 2.5, "three", true, false, nil]', Array)

		expect(result).to eq([-1, 2.5, "three", true, false, nil])
	end

	it "rejects arrays containing disallowed literals" do
		input = '[:symbol]'

		expect(InferType.parse(input, Array)).to eq(input)
	end

	it "requires brackets by default" do
		input = '1, 2, 3'

		expect(InferType.parse(input, Array)).to eq(input)
	end

	it "parses without brackets when configured" do
		stub_const("InferType::Parsers::ArrayParser::REQUIRES_BRACKETS", false)

		expect(InferType.parse('1, 2, 3', Array)).to eq([1, 2, 3])
	end

	it "supports nesting when allowed and respects max depth" do
		stub_const(
			"InferType::Parsers::ArrayParser::ALLOWED_TYPES",
			[String, Integer, Float, TrueClass, FalseClass, NilClass, Array, Hash]
		)
		stub_const("InferType::Parsers::ArrayParser::MAX_DEPTH", 2)

		expect(InferType.parse('[[1]]', Array)).to eq([[1]])

		too_deep = '[[[1]]]'
		expect(InferType.parse(too_deep, Array)).to eq([[nil]])
	end
end
