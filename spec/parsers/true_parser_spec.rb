# frozen_string_literal: true

require_relative '../spec_helper'

RSpec.describe InferType::Parsers::TrueParser do
	it "parses 'true' case-insensitively in strict mode" do
		result = InferType.parse(" TRUE ", TrueClass)

		expect(result).to eq(true)
	end

	it "rejects other truthy words in strict mode" do
		expect(InferType.parse("yes", TrueClass)).to eq("yes")
	end

	it "accepts additional truthy words when STRICT is false" do
		stub_const("#{described_class}::STRICT", false)

		result = InferType.parse("on", TrueClass)

		expect(result).to eq(true)
	end

	it "honours CASE_SENSITIVE when enabled" do
		stub_const("#{described_class}::CASE_SENSITIVE", true)

		expect(InferType.parse("True", TrueClass)).to eq("True")
		expect(InferType.parse("true", TrueClass)).to eq(true)
	end
end
