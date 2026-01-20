# frozen_string_literal: true

module InferType
	class Result
		attr_reader :parsed, :value, :parser
		def initialize(parsed: nil, value: nil, parser: nil)
			@parsed = parsed
			@value = value
			@parser = parser
		end
	end

	class Success < Result
		def initialize(value: nil, parser: nil)
			raise TypeError, "Parser returned a type other than the type it detects" if !value.is_a?(parser.detects)
			super(parsed: true, value: value, parser: parser)
		end
	end

	class Failure < Result
		def initialize(parser: nil)
			super(parsed: false, parser: parser)
		end
	end
end

