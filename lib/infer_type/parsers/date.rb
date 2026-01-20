# frozen_string_literal: true

require "date"

module InferType
	module Parsers
		class DateParser < InferType::Parser
			detects Date

			DATE_FORMAT = %r<
				\A
				(?<date>
					(?<year>  \d{4}   ) -
					(?<month> [0-1]\d ) -
					(?<day>   [0-3]\d )
				)
				\z
			>x.freeze

			def parse(str)
				candidate = str.strip
				return failure if candidate.empty?
				
				# Looks like a Date
				return failure unless match = candidate.match(DATE_FORMAT)

				# Pre-validate to avoid Date.new being too lax

				# Attempt to parse the date
				year = match['year'].to_i
				month = match['month'].to_i
				day = match['day'].to_i
				return failure unless Date.valid_date?(year, month, day)

				# Attempt conversion
				begin
					value = Date.new(year, month, day)
					return failure unless value.year == year && value.month == month && value.day == day
				rescue ArgumentError
					return failure
				end

				success(value)
			end
		end
	end
end

