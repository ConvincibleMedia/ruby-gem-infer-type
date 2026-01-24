# frozen_string_literal: true

require_relative '../spec_helper'

RSpec.describe InferType::Parsers::TimeParser do
	it "parses ISO8601 datetime strings with T separator" do
		result = InferType.parse("2024-03-15T12:30:45", Time)

		expect(result).to eq(Time.new(2024, 3, 15, 12, 30, 45, "+00:00"))
		expect(result.utc_offset).to eq(0)
	end

	it "parses datetime strings with space separator and offset" do
		result = InferType.parse("2024-03-15 12:30:00+02:00", Time)

		expect(result).to eq(Time.new(2024, 3, 15, 12, 30, 0, "+02:00"))
		expect(result.utc_offset).to eq(7200)
	end

	it "parses offsets without colon" do
		result = InferType.parse("2024-03-15T12:30+0200", Time)

		expect(result).to eq(Time.new(2024, 3, 15, 12, 30, 0, "+02:00"))
		expect(result.utc_offset).to eq(7200)
	end

	it "parses Zulu or UTC suffixes as UTC" do
		result = InferType.parse("2024-03-15T12:30:00Z", Time)

		expect(result).to eq(Time.new(2024, 3, 15, 12, 30, 0, "+00:00"))
	end

	it "parses sub-second precision with dot or comma separators" do
		nano_result = InferType.parse("2024-03-15T12:30:45.123456789+00:00", Time)

		expect(nano_result.nsec).to eq(123_456_789)

		comma_result = InferType.parse("2024-03-15T12:30:45,5Z", Time)

		expect(comma_result.subsec).to be_within(1e-9).of(0.5)
	end

	it "trims surrounding whitespace and accepts UTC suffix" do
		result = InferType.parse("\n2024-03-15 12:30 UTC\t", Time)

		expect(result).to eq(Time.new(2024, 3, 15, 12, 30, 0, "+00:00"))
	end

	it "falls back to local timezone when default UTC is disabled and no offset is provided" do
		stub_const("InferType::Parsers::TimeParser::DEFAULT_UTC", false)
		expected_offset = Time.new(2024, 3, 15, 12, 30).utc_offset

		result = InferType.parse("2024-03-15T12:30:00", Time)

		expect(result.utc_offset).to eq(expected_offset)
	end

	it "rejects strings missing time information" do
		expect(InferType.parse("2024-03-15", Time)).to eq("2024-03-15")
	end

	it "rejects strings with invalid month or day" do
		expect(InferType.parse("2024-13-01T00:00", Time)).to eq("2024-13-01T00:00")
	end

	it "rejects strings with invalid hour" do
		expect(InferType.parse("2024-03-15T24:00", Time)).to eq("2024-03-15T24:00")
	end

	it "rejects offsets beyond limits or with missing digits" do
		[
			"2024-03-15T12:30+14:01",
			"2024-03-15T12:30+15:00",
			"2024-03-15T12:30+2:00",
			"2024-03-15T12:30+2400",
			"2024-03-15T12:30-12:99"
		].each do |input|
			expect(InferType.parse(input, Time)).to eq(input)
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
				result = InferType.parse(input, Time)
				expect(result).to eq(input), "expected '#{input}' to be rejected"
			end.not_to raise_error
		end
	end
end
