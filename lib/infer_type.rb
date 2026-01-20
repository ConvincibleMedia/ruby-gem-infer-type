# frozen_string_literal: true

require_relative "infer_type/result"
require_relative "infer_type/parser"
require_relative "infer_type/registry"

module InferType
	class << self

		# Whether to strip input strings before parsing
		STRIP = true

		# Primary method to parse a string into a type
		def parse(_input, *allowed_types)
			raise ArgumentError, "Can only parse Strings" unless _input.is_a?(String)

			# Prepare the string
			str = _input.dup
			str = str.strip if STRIP

			# Select appropriate parsers
			parsers = select_parsers(allowed_types)

			# Try each parser
			parsers.each do |parser_class|
				result = parser_class.new.parse(str)
				raise TypeError, "Parser (#{parser_class}) must return a Result object using success(value) or failure() methods" unless result.is_a?(InferType::Result)
				# Return as soon as one succeeds
				return result.value if result.parsed
			end

			# All parsers failed: return the original input
			_input
		end

		# Parser registration methods
		def register(parser_class)
			registry.register(parser_class)
		end

		def deregister(parser_classes)
			registry.deregister(parser_classes)
		end
		alias unregister deregister

		def prioritise(*items)
			registry.prioritize(*items)
		end
		alias prioritize prioritise

		def deprioritise(*items)
			registry.deprioritize(*items)
		end
		alias deprioritize deprioritise
		alias unprioritise deprioritise
		alias unprioritize deprioritise

		private

		def registry
			@registry ||= InferType::Registry.new
		end

		# Select parsers in priority order
		def select_parsers(allowed_types)
			all = registry.parsers
			return all if allowed_types.empty?

			# Allowed types have been specified
			allowed_types = allowed_types.flatten
			type_priority = {}

			allowed_types.each_with_index do |type, index|
				parser = registry.parser_for_type(type)
				raise KeyError, "No parser registered for class #{type}" if parser.nil?
				type_priority[type] = index
			end

			selected = all.select { |parser| type_priority.key?(parser.detects) }

			# Override registry priority using allowed_types order
			selected.sort_by { |parser| type_priority[parser.detects] }
		end
	end
end

# Load all built-in parsers
Dir.glob(File.join(__dir__, "infer_type/parsers/*.rb")).each do |file|
	require_relative file
end

InferType.register(InferType::Parsers::IntegerParser)
InferType.register(InferType::Parsers::FloatParser)
InferType.register(InferType::Parsers::TrueParser)
InferType.register(InferType::Parsers::FalseParser)
InferType.register(InferType::Parsers::NilParser)
InferType.register(InferType::Parsers::DateParser)
InferType.register(InferType::Parsers::TimeParser)

