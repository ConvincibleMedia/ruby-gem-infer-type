# frozen_string_literal: true

require_relative '../spec_helper'

RSpec.describe InferType::Parsers::NilParser do
	it "parses 'nil' case-insensitively in strict mode" do
		result = InferType.parse(" NiL ", NilClass)

		expect(result).to be_nil
	end

	it "rejects other nil-like words in strict mode" do
		expect(InferType.parse("null", NilClass)).to eq("null")
	end

	it "accepts additional nil-like words when STRICT is false" do
		stub_const("#{described_class}::STRICT", false)

		result = InferType.parse("undefined", NilClass)

		expect(result).to be_nil
	end

	it "honours CASE_SENSITIVE when enabled" do
		stub_const("#{described_class}::CASE_SENSITIVE", true)

		expect(InferType.parse("Nil", NilClass)).to eq("Nil")
		expect(InferType.parse("nil", NilClass)).to be_nil
	end
end
