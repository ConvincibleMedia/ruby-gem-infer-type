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

	# Autoload paths for built-in parsers, including optional ones.
	PARSER_AUTOLOAD_PATHS = {
		IntegerParser: File.join(__dir__, "infer_type/parsers/integer"),
		FloatParser: File.join(__dir__, "infer_type/parsers/float"),
		TrueParser: File.join(__dir__, "infer_type/parsers/true"),
		FalseParser: File.join(__dir__, "infer_type/parsers/false"),
		NilParser: File.join(__dir__, "infer_type/parsers/nil"),
		DateParser: File.join(__dir__, "infer_type/parsers/date"),
		TimeParser: File.join(__dir__, "infer_type/parsers/time"),
		HashParser: File.join(__dir__, "infer_type/parsers/hash"),
		ArrayParser: File.join(__dir__, "infer_type/parsers/array")
	}.freeze

	class << self

		# Primary method to parse a string into a type
		def parse(_input, *allowed_types)
			raise ArgumentError, "Can only parse Strings" unless _input.is_a?(String)

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

		# Sets up autoloads and lazy registration for built-in parsers.
		def initialise_builtin_parsers
			register_parser_autoloads
			register_default_parsers
		end

		# Registers autoloads so parser constants load their files on first use.
		def register_parser_autoloads
			PARSER_AUTOLOAD_PATHS.each do |constant, path|
				next if Parsers.const_defined?(constant, false)
				next if Parsers.autoload?(constant)

				Parsers.autoload(constant, path)
			end
		end

		# Registers default parsers lazily so they load only when used.
		def register_default_parsers
			registry.register_lazy_parser(type: Integer) { Parsers::IntegerParser }
			registry.register_lazy_parser(type: Float) { Parsers::FloatParser }
			registry.register_lazy_parser(type: TrueClass) { Parsers::TrueParser }
			registry.register_lazy_parser(type: FalseClass) { Parsers::FalseParser }
			registry.register_lazy_parser(type: NilClass) { Parsers::NilParser }
			registry.register_lazy_parser(type: Date) { Parsers::DateParser }
			registry.register_lazy_parser(type: Time) { Parsers::TimeParser }
			registry.register_lazy_parser(type: Hash) { Parsers::HashParser }
			registry.register_lazy_parser(type: Array) { Parsers::ArrayParser }
		end

		# Returns the registry instance backing InferType.
		def registry
			@registry ||= InferType::Registry.new
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

InferType.send(:initialise_builtin_parsers)

