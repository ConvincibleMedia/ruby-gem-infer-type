# frozen_string_literal: true

require_relative '../spec_helper'

RSpec.describe InferType::Parsers::TimeParser do
	subject(:parser) { described_class.new }

	it "parses ISO8601 datetime strings with T separator" do
		result = parser.parse("2024-03-15T12:30:45")

		expect(result.parsed).to be(true)
		expect(result.value).to eq(Time.new(2024, 3, 15, 12, 30, 45, "+00:00"))
		expect(result.value.utc_offset).to eq(0)
	end

	it "parses datetime strings with space separator and offset" do
		result = parser.parse("2024-03-15 12:30:00+02:00")

		expect(result.parsed).to be(true)
		expect(result.value).to eq(Time.new(2024, 3, 15, 12, 30, 0, "+02:00"))
		expect(result.value.utc_offset).to eq(7200)
	end

	it "parses offsets without colon" do
		result = parser.parse("2024-03-15T12:30+0200")

		expect(result.parsed).to be(true)
		expect(result.value).to eq(Time.new(2024, 3, 15, 12, 30, 0, "+02:00"))
		expect(result.value.utc_offset).to eq(7200)
	end

	it "parses Zulu or UTC suffixes as UTC" do
		result = parser.parse("2024-03-15T12:30:00Z")

		expect(result.parsed).to be(true)
		expect(result.value).to eq(Time.new(2024, 3, 15, 12, 30, 0, "+00:00"))
	end

	it "parses sub-second precision with dot or comma separators" do
		nano_result = parser.parse("2024-03-15T12:30:45.123456789+00:00")

		expect(nano_result.parsed).to be(true)
		expect(nano_result.value.nsec).to eq(123_456_789)

		comma_result = parser.parse("2024-03-15T12:30:45,5Z")

		expect(comma_result.parsed).to be(true)
		expect(comma_result.value.subsec).to be_within(1e-9).of(0.5)
	end

	it "trims surrounding whitespace and accepts UTC suffix" do
		result = parser.parse("\n2024-03-15 12:30 UTC\t")

		expect(result.parsed).to be(true)
		expect(result.value).to eq(Time.new(2024, 3, 15, 12, 30, 0, "+00:00"))
	end

	it "falls back to local timezone when default UTC is disabled and no offset is provided" do
		stub_const("InferType::Parsers::TimeParser::DEFAULT_UTC", false)
		expected_offset = Time.new(2024, 3, 15, 12, 30).utc_offset

		result = parser.parse("2024-03-15T12:30:00")

		expect(result.parsed).to be(true)
		expect(result.value.utc_offset).to eq(expected_offset)
	end

	it "rejects strings missing time information" do
		expect(parser.parse("2024-03-15").parsed).to be(false)
	end

	it "rejects strings with invalid month or day" do
		expect(parser.parse("2024-13-01T00:00").parsed).to be(false)
	end

	it "rejects strings with invalid hour" do
		expect(parser.parse("2024-03-15T24:00").parsed).to be(false)
	end

	it "rejects offsets beyond limits or with missing digits" do
		[
			"2024-03-15T12:30+14:01",
			"2024-03-15T12:30+15:00",
			"2024-03-15T12:30+2:00",
			"2024-03-15T12:30+2400",
			"2024-03-15T12:30-12:99"
		].each do |input|
			expect(parser.parse(input).parsed).to be(false)
		end
	end

	it "rejects a batch of malformed time strings without raising (monkey test)" do
		bad_inputs = [
			"    ",
			"not-a-time",
			"2024-03-15",
			"2024-03-15T12",
			"2024-03-15T12:30:70Z",
			"2024-00-01T00:00Z",
			"2024-03-15T12:30:30+25:00",
			"2024-03-15T12:30:30Zextra",
			"2024-03-15T12:60Z",
			"2024-03-15T12:30:30.abcdef+00:00",
			"2024-03-15T12:30:00Z\njunk"
		]

		bad_inputs.each do |input|
			expect do
				result = parser.parse(input)
				expect(result.parsed).to be(false), "expected '#{input}' to be rejected"
			end.not_to raise_error
		end
	end
end