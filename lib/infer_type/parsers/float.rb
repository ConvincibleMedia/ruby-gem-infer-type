# frozen_string_literal: true

module InferType
	module Parsers
		class FloatParser < InferType::Parser
			detects Float

			# If false, "1" is NOT considered a Float (must be "1.0" etc.)
			ALLOW_INTEGER = true

			# Allow exponential notation like 1e3 or 1.5E-2
			ALLOW_EXPONENTIAL = true

			# Allow special values: NaN, Infinity
			ALLOW_SPECIAL_VALUES = false

			FLOAT_NO_EXP_REGEX = /\A[+-]?(?:\d+\.\d*|\.\d+)\z/
			FLOAT_WITH_EXP_REGEX = /\A[+-]?(?:\d+(?:\.\d*)?|\.\d+)[eE][+-]?\d+\z/

			def parse(str)
				candidate = str.strip
				return failure if candidate.empty?

				# Check for exact special value string
				if ["NaN", "Infinity", "-Infinity"].include?(candidate)
					if ALLOW_SPECIAL_VALUES
						return success(Float(candidate))
					else
						return failure
					end
				end

				# Check for integer if allowed
				if ALLOW_INTEGER
					InferType::Parsers::IntegerParser.new.parse(candidate).tap do |result|
						if result.parsed
							# Return it as a float
							return success(result.value.to_f)
						end
					end
				end

				# Check for float format
				looks_float_no_exp = !candidate.match(FLOAT_NO_EXP_REGEX).nil?
				looks_float_with_exp = ALLOW_EXPONENTIAL && !candidate.match(FLOAT_WITH_EXP_REGEX).nil?
				looks_float = looks_float_no_exp || looks_float_with_exp

				return failure unless looks_float

				# Attempt conversion
				begin
					value = Float(candidate)
				rescue ArgumentError
					return failure
				end

				success(value)
			end
		end
	end
end
