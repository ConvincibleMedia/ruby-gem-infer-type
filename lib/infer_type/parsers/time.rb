# frozen_string_literal: true

require "time"
require "date"

module InferType
	module Parsers
		class TimeParser < InferType::Parser
			detects Time

			# If timezone offset is missing from a Time string, assume UTC
			# If false, the system's local timezone will be used
			DEFAULT_UTC = true

			TIME_FORMAT = %r<
				\A
				(?<date>
					(?<year>   \d{4}   ) -
					(?<month>  [0-1]\d ) -
					(?<day>    [0-3]\d )
				)
				(T|\s)
				(?<time>
					(?<hour>     [0-2]\d ) \:
					(?<minute>   [0-5]\d )
					(\:
						(?<second> [0-5]\d )
						([\.,]
							(?<subs> \d{1,9} )
						)?
					)?
				)
				(?<offset>
					(?<sign>   [+\-]   )
					(?<offh>   [0-2]\d ) \:?
					(?<offm>   [0-5]\d )
					|
					(?<offz>  Z | \s?UTC )
				)?
				\z
			>x.freeze

			def parse(str)
				candidate = str.strip
				return failure if candidate.empty?
				
				# Looks like a Time
				return failure unless match = candidate.match(TIME_FORMAT)
				
				# Pre-validate to avoid Time.new being too lax

				# Attempt to parse date
				year = match['year'].to_i
				month = match['month'].to_i
				day = match['day'].to_i
				return failure unless Date.valid_date?(year, month, day)

				# Attempt to parse time
				hour = match['hour'].to_i
				minute = match['minute'].to_i
				return failure unless hour.between?(0, 23) && minute.between?(0, 59)
				if match['second']
					second = match['second'].to_i
					return failure unless second.between?(0, 59)
				else
					second = 0
				end

				# Add on subseconds if they were present
				if match['subs']
					begin
						subs = ("0." + match['subs']).to_f
						second += subs
					rescue ArgumentError
						return failure
					end
				end

				# Was there an offset?
				if match['offset'] && !match['offz']	
					sign = match['sign']
					offh = match['offh'].to_i
					offm = match['offm'].to_i
					return failure unless (offh.between?(0, 13) && offm.between?(0, 59)) || (offh == 14 && offm == 0) # maximum 14 hour offsets
				else
					if DEFAULT_UTC || match['offz']
						sign = "+"
						offh = 0
						offm = 0
					end
				end
				if sign && offh && offm
					offset = format("%<sign>s%<offh>02d:%<offm>02d", sign: sign, offh: offh, offm: offm)
				else
					offset = nil
				end

				# Attempt conversion
				begin
					args = [year, month, day, hour, minute, second]
					args << offset if offset
					value = Time.new(*args)
					return failure unless value.year == year && value.mon == month && value.day == day
					return failure unless value.hour == hour && value.min == minute
					return failure unless second.to_r == value.sec + value.subsec
					return failure unless value.utc_offset == (offh * 3600 + offm * 60) * (sign == "-" ? -1 : 1) if offset
				rescue ArgumentError
					return failure
				end

				success(value)
			end
		end
	end
end

