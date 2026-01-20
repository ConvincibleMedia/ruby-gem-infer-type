# frozen_string_literal: true

require_relative 'spec_helper'

RSpec.describe InferType::Parser do
	it "stores and returns the detected type" do
		custom_type = Class.new
		parser_class = Class.new(described_class) do
			detects custom_type
		end

		expect(parser_class.detects).to eq(custom_type)
	end

	it "rejects String as a detected type" do
		expect do
			Class.new(described_class) do
				detects String
			end
		end.to raise_error(ArgumentError, /detects cannot be String/)
	end

	it "rejects non-class detected types" do
		expect do
			Class.new(described_class) do
				detects :symbol
			end
		end.to raise_error(ArgumentError, /detects must be a Class/)
	end
end