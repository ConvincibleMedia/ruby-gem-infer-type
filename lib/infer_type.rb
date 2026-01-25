# frozen_string_literal: true

require_relative "infer_type/result"
require_relative "infer_type/parser"
require_relative "infer_type/registry"
require "date"

module InferType
	# Whether to strip input strings before parsing
	STRIP = true

	# Namespace for built-in parsers so they can be autoloaded on demand.
	module Parsers
	end

	# Built-in parser definitions, including optional ones.
	PARSER_DEFINITIONS = {
		IntegerParser: { path: File.join(__dir__, "infer_type/parsers/integer"), type: Integer, default: true },
		FloatParser: { path: File.join(__dir__, "infer_type/parsers/float"), type: Float, default: true },
		TrueParser: { path: File.join(__dir__, "infer_type/parsers/true"), type: TrueClass, default: true },
		FalseParser: { path: File.join(__dir__, "infer_type/parsers/false"), type: FalseClass, default: true },
		NilParser: { path: File.join(__dir__, "infer_type/parsers/nil"), type: NilClass, default: true },
		DateParser: { path: File.join(__dir__, "infer_type/parsers/date"), type: Date, default: true },
		TimeParser: { path: File.join(__dir__, "infer_type/parsers/time"), type: Time, default: true },
		HashParser: { path: File.join(__dir__, "infer_type/parsers/hash"), type: Hash, default: false },
		ArrayParser: { path: File.join(__dir__, "infer_type/parsers/array"), type: Array, default: false }
	}.freeze

	# Register autoloads up front so parser constants load when referenced.
	PARSER_DEFINITIONS.each do |constant, definition|
		next if Parsers.const_defined?(constant, false)
		next if Parsers.autoload?(constant)

		Parsers.autoload(constant, definition[:path])
	end

	class << self

		# Primary method to parse a string into a type
		def parse(_input, *allowed_types)
			# Immediate return if input is not a String
			return _input unless _input.is_a?(String)

			# Prepare the string
			str = _input.dup
			str = str.strip if InferType::STRIP

			# Empty input immediately returned
			return _input if str.empty?

			# Select appropriate parsers
			parsers = select_parsers(allowed_types)

			# Try each parser
			parsers.each do |parser_entry|
				parser_class = parser_entry.parser_class
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
		# Builds the registry with default parsers registered lazily.
		def build_registry
			registry = InferType::Registry.new
			register_default_parsers(registry)
			registry
		end

		# Registers default parsers lazily so they load only when used.
		def register_default_parsers(registry)
			PARSER_DEFINITIONS.each do |constant, definition|
				next unless definition[:default]

				registry.register_lazy_parser(type: definition[:type]) { Parsers.const_get(constant) }
			end
		end

		# Returns the registry instance backing InferType.
		def registry
			@registry ||= build_registry
		end

		# Select parsers in priority order
		def select_parsers(allowed_types)
			all = registry.parser_entries
			return all if allowed_types.empty?

			# Allowed types have been specified
			allowed_types = allowed_types.flatten
			type_priority = {}

			allowed_types.each_with_index do |type, index|
				parser = registry.parser_entry_for_type(type)
				raise KeyError, "No parser registered for class #{type}" if parser.nil?
				type_priority[type] = index
				type_priority[type.name] = index unless type.name.nil?
			end

			selected = all.select { |parser| type_priority.key?(parser.type) || type_priority.key?(parser.type_name) }

			# Override registry priority using allowed_types order
			selected.sort_by { |parser| type_priority[parser.type] || type_priority[parser.type_name] }
		end
	end
end
