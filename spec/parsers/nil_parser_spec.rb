# frozen_string_literal: true

require_relative '../spec_helper'

RSpec.describe InferType::Parsers::NilParser do
	subject(:parser) { described_class.new }

	it "parses 'nil' case-insensitively in strict mode" do
		result = parser.parse(" NiL ")

		expect(result.parsed).to be(true)
		expect(result.value).to be_nil
	end

	it "rejects other nil-like words in strict mode" do
		expect(parser.parse("null").parsed).to be(false)
	end

	it "accepts additional nil-like words when STRICT is false" do
		stub_const("#{described_class}::STRICT", false)

		result = parser.parse("undefined")

		expect(result.parsed).to be(true)
		expect(result.value).to be_nil
	end

	it "honours CASE_SENSITIVE when enabled" do
		stub_const("#{described_class}::CASE_SENSITIVE", true)

		expect(parser.parse("Nil").parsed).to be(false)
		expect(parser.parse("nil").parsed).to be(true)
	end
end