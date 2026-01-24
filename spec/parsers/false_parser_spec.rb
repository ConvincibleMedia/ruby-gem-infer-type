# frozen_string_literal: true

require_relative '../spec_helper'

RSpec.describe InferType::Parsers::FalseParser do
	it "parses 'false' case-insensitively in strict mode" do
		result = InferType.parse(" False ", FalseClass)

		expect(result).to eq(false)
	end

	it "rejects other falsy words in strict mode" do
		expect(InferType.parse("no", FalseClass)).to eq("no")
	end

	it "accepts additional falsy words when STRICT is false" do
		stub_const("#{described_class}::STRICT", false)

		result = InferType.parse("off", FalseClass)

		expect(result).to eq(false)
	end

	it "honours CASE_SENSITIVE when enabled" do
		stub_const("#{described_class}::CASE_SENSITIVE", true)

		expect(InferType.parse("False", FalseClass)).to eq("False")
		expect(InferType.parse("false", FalseClass)).to eq(false)
	end
end
