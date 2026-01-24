# frozen_string_literal: true

module InferType
	module Parsers
		class NilParser < InferType::Parser
			detects NilClass

			NIL_STRINGS = ['nil', 'null', 'nothing', 'undefined', 'none'].freeze

			# If true, only use the first nil string
			STRICT = true

			# If true, case sensitive
			CASE_SENSITIVE = false

			def parse(str)
				candidate = str
				candidate = candidate.downcase if !CASE_SENSITIVE

				if STRICT
					return success(nil) if candidate == NIL_STRINGS.first
				else
					return success(nil) if NIL_STRINGS.include?(candidate)
				end

				failure
			end
		end
	end
end
