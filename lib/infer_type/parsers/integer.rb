# frozen_string_literal: true

module InferType
	module Parsers
		class IntegerParser < InferType::Parser
			detects Integer

			# Allow numbers with leading zeros like "00001" = 1
			ALLOW_LEADING_ZERO = true

			# Allow leading plus sign
			ALLOW_LEADING_PLUS = true

			INTEGER_REGEX = /\A-?\d+\z/

			def parse(str)
				candidate = str.strip
				return failure if candidate.empty?

				# Prepare the candidate for parsing
				candidate = clean(candidate)

				# Should now match integer format
				return failure unless !candidate.match(INTEGER_REGEX).nil?

				# Attempt conversion
				begin
					value = Integer(candidate, 10)
					return failure unless value.to_s == candidate
				rescue ArgumentError
					return failure
				end

				success(value)
			end

			private

			def clean(str)
				clean = str.dup.strip
				return clean if clean.empty?

				# Remove leading +
				if ALLOW_LEADING_PLUS
					clean = clean.sub(/\A\+/, '')
				end

				# Preserve a single zero when the string is all zeros
				if !clean.match(/\A-?0+\z/).nil?
					return '0' # -0 is equivalent to 0
				end

				# Remove leading zeros
				if ALLOW_LEADING_ZERO
					clean = clean.sub(/\A(-)?0+/, '\1')
				end

				clean
			end
		end
	end
end

