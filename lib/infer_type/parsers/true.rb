# frozen_string_literal: true

module InferType
	module Parsers
		class TrueParser < InferType::Parser
			detects TrueClass

			TRUE_STRINGS = ['true', 'yes', 'on', 'y'].freeze

			# If true, only use the first true string
			STRICT = true

			# If true, case sensitive
			CASE_SENSITIVE = false

			def parse(str)
				candidate = str
				candidate = candidate.downcase if !CASE_SENSITIVE

				if STRICT
					return success(true) if candidate == TRUE_STRINGS.first
				else
					return success(true) if TRUE_STRINGS.include?(candidate)
				end

				failure
			end
		end
	end
end
