# frozen_string_literal: true

require_relative '../spec_helper'

RSpec.describe InferType::Parsers::DateParser do
	subject(:parser) { described_class.new }

	it "parses ISO8601 date strings" do
		result = parser.parse("2024-03-15")

		expect(result.parsed).to be(true)
		expect(result.value).to eq(Date.new(2024, 3, 15))
	end

	it "trims whitespace before parsing" do
		result = parser.parse(" 2024-01-01 ")

		expect(result.parsed).to be(true)
		expect(result.value).to eq(Date.new(2024, 1, 1))
	end

	it "parses leap days on leap years" do
		result = parser.parse("2020-02-29")

		expect(result.parsed).to be(true)
		expect(result.value).to eq(Date.new(2020, 2, 29))
	end

	it "rejects leap days on non-leap years" do
		expect(parser.parse("2021-02-29").parsed).to be(false)
	end

	it "rejects strings that do not match the date format" do
		["03-15-2024", "2024/03/15", ""].each do |input|
			expect(parser.parse(input).parsed).to be(false)
		end
	end

	it "rejects impossible dates even if the format matches" do
		expect(parser.parse("2024-02-30").parsed).to be(false)
	end

	it "rejects zeroed or non-padded components" do
		["2024-00-10", "2024-01-00", "2024-3-05", "2024-03-5"].each do |input|
			expect(parser.parse(input).parsed).to be(false)
		end
	end

	it "does not misinterpret strings with extra content as dates" do
		["2024-03-15T12:00", "2024-03-15 extra", "xx2024-03-15", " 2024-03-15-"].each do |input|
			expect(parser.parse(input).parsed).to be(false)
		end
	end

	it "rejects a batch of malformed date strings without raising (monkey test)" do
		bad_inputs = [
			"    ",
			"not-a-date",
			"2024-13-01",
			"2024-12-32",
			"2024-11-31",
			"20240315",
			"2024-02-30",
			"0000-00-00",
			"--2024-03-15--",
			"2024-01-01\nbad"
		]

		bad_inputs.each do |input|
			expect do
				result = parser.parse(input)
				expect(result.parsed).to be(false), "expected '#{input}' to be rejected"
			end.not_to raise_error
		end
	end
end