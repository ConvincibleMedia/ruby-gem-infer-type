# frozen_string_literal: true

require_relative '../spec_helper'

RSpec.describe InferType::Parsers::HashParser do
	before do
		InferType.register(described_class)
	end

	it "parses hashes with string and symbol keys" do
		result = InferType.parse('{foo: 1, "bar" => -2}', Hash)

		expect(result).to eq({ "foo" => 1, "bar" => -2 })
	end

	it "rejects hashes containing disallowed literals" do
		input = '{foo: :bar}'

		expect(InferType.parse(input, Hash)).to eq(input)
	end

	it "requires braces by default" do
		input = 'foo: 1, bar: 2'

		expect(InferType.parse(input, Hash)).to eq(input)
	end

	it "parses without braces when configured" do
		stub_const("InferType::Parsers::HashParser::REQUIRES_BRACKETS", false)

		expect(InferType.parse('foo: 1, "bar" => 2', Hash)).to eq({ "foo" => 1, "bar" => 2 })
	end

	it "supports nesting when allowed and respects max depth" do
		stub_const(
			"InferType::Parsers::HashParser::ALLOWED_TYPES",
			[String, Integer, Float, TrueClass, FalseClass, NilClass, Array, Hash]
		)
		stub_const("InferType::Parsers::HashParser::MAX_DEPTH", 2)

		expect(InferType.parse('{foo: [1], bar: {baz: 2}}', Hash))
			.to eq({ "foo" => [1], "bar" => { "baz" => 2 } })

		too_deep = '{foo: {bar: {baz: 1}}}'
		expect(InferType.parse(too_deep, Hash)).to eq({ "foo" => { "bar" => nil } })
	end
end
