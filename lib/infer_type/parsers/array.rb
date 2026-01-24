# frozen_string_literal: true

require_relative "support/ripper"

module InferType
	module Parsers
		class ArrayParser < InferType::Parser
			include InferType::Parsers::Support::Ripper
			detects Array

			ALLOWED_TYPES = [String, Integer, Float, TrueClass, FalseClass, NilClass].freeze
			MAX_DEPTH = 2
			REQUIRES_BRACKETS = true

			def parse(str)
				parsed = parse_array_literal(
					str,
					allowed_types: ALLOWED_TYPES,
					max_depth: MAX_DEPTH,
					requires_brackets: REQUIRES_BRACKETS
				)

				return failure if parsed.nil?

				success(parsed)
			end
		end
	end
end
