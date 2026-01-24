# frozen_string_literal: true

module InferType
	module Parsers
		class FalseParser < InferType::Parser
			detects FalseClass

			FALSE_STRINGS = ['false', 'no', 'off', 'n'].freeze

			# If true, only use the first false string
			STRICT = true

			# If true, case sensitive
			CASE_SENSITIVE = false

			def parse(str)
				candidate = str
				candidate = candidate.downcase if !CASE_SENSITIVE

				if STRICT
					return success(false) if candidate == FALSE_STRINGS.first
				else
					return success(false) if FALSE_STRINGS.include?(candidate)
				end

				failure
			end
		end
	end
end
