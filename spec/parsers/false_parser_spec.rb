# frozen_string_literal: true

require_relative '../spec_helper'

RSpec.describe InferType::Parsers::FalseParser do
	subject(:parser) { described_class.new }

	it "parses 'false' case-insensitively in strict mode" do
		result = parser.parse(" False ")

		expect(result.parsed).to be(true)
		expect(result.value).to eq(false)
	end

	it "rejects other falsy words in strict mode" do
		expect(parser.parse("no").parsed).to be(false)
	end

	it "accepts additional falsy words when STRICT is false" do
		stub_const("#{described_class}::STRICT", false)

		result = parser.parse("off")

		expect(result.parsed).to be(true)
		expect(result.value).to eq(false)
	end

	it "honours CASE_SENSITIVE when enabled" do
		stub_const("#{described_class}::CASE_SENSITIVE", true)

		expect(parser.parse("False").parsed).to be(false)
		expect(parser.parse("false").parsed).to be(true)
	end
end