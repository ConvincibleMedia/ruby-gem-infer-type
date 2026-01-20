# frozen_string_literal: true

require_relative '../spec_helper'

RSpec.describe InferType::Parsers::TrueParser do
	subject(:parser) { described_class.new }

	it "parses 'true' case-insensitively in strict mode" do
		result = parser.parse(" TRUE ")

		expect(result.parsed).to be(true)
		expect(result.value).to eq(true)
	end

	it "rejects other truthy words in strict mode" do
		expect(parser.parse("yes").parsed).to be(false)
	end

	it "accepts additional truthy words when STRICT is false" do
		stub_const("#{described_class}::STRICT", false)

		result = parser.parse("on")

		expect(result.parsed).to be(true)
		expect(result.value).to eq(true)
	end

	it "honours CASE_SENSITIVE when enabled" do
		stub_const("#{described_class}::CASE_SENSITIVE", true)

		expect(parser.parse("True").parsed).to be(false)
		expect(parser.parse("true").parsed).to be(true)
	end
end