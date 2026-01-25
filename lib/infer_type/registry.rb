# frozen_string_literal: true

module InferType
	class Registry
		# Represents a parser slot in the registry, optionally loading the parser class lazily.
		# Build entries via Registry methods rather than instantiating directly.
		class ParserEntry
			# Creates an entry from an eager parser class.
			def self.from_class(parser_class, validator: nil)
				validator.call(parser_class) if validator
				type = parser_class.detects
				type_name = (type.respond_to?(:name) && type.name)
				new(
					type: type,
					type_name: type_name,
					parser_class: parser_class,
					loader: nil,
					validator: validator
				)
			end

			# Creates an entry that loads the parser class only when needed.
			def self.for_lazy(type:, type_name:, loader:, validator:)
				resolved_type_name = type_name || (type.respond_to?(:name) && type.name)
				raise ArgumentError, "Lazy parser requires a type or type name" if resolved_type_name.nil?
				new(
					type: type,
					type_name: resolved_type_name,
					parser_class: nil,
					loader: loader,
					validator: validator
				)
			end

			# Initialises a parser entry with optional lazy loading.
			def initialize(type:, type_name:, parser_class:, loader:, validator:)
				@type = type
				@type_name = type_name
				@parser_class = parser_class
				@loader = loader
				@validator = validator
			end

			# Returns the detected type class when it is known.
			def type
				@type
			end

			# Returns the detected type name, even if the class has not yet been loaded.
			def type_name
				@type_name
			end

			# Returns true when this entry refers to the given detected type.
			def matches_type?(type)
				return false unless type.is_a?(Class)
				return true if @type && @type == type
				return false if @type_name.nil? || type.name.nil?

				@type_name == type.name
			end

			# Returns true when this entry's type name matches the given name.
			def matches_type_name?(type_name)
				return false if @type_name.nil? || type_name.nil?

				@type_name == type_name
			end

			# Returns true when this entry refers to the given parser class.
			def matches_parser_class?(parser_class)
				return true if @parser_class && @parser_class == parser_class

				matches_type?(parser_class.detects)
			end

			# Loads and returns the parser class, validating it if needed.
			def parser_class
				return @parser_class if @parser_class

				@parser_class = @loader.call
				@validator.call(@parser_class) if @validator

				loaded_type = @parser_class.detects
				loaded_name = loaded_type.respond_to?(:name) && loaded_type.name

				if @type_name && loaded_name && loaded_name != @type_name
					raise ArgumentError, "Lazy parser detects #{loaded_name}, expected #{@type_name}"
				end

				@type = loaded_type
				@type_name = loaded_name if loaded_name
				@loader = nil
				@parser_class
			end
		end

		# Initialises a new registry with no parsers registered.
		def initialize
			@parsers = []
		end

		# Returns parser entries without forcing any lazy loads.
		def parser_entries
			@parsers.dup
		end

		# Returns parser classes in priority order, loading lazy parsers as needed.
		def parsers
			@parsers.map(&:parser_class)
		end

		# Returns the parser class registered for the given detected type.
		def parser_for_type(type)
			entry = parser_entry_for_type(type)
			entry ? entry.parser_class : nil
		end

		# Returns the registry entry for the given detected type.
		def parser_entry_for_type(type)
			@parsers.find { |parser| parser.matches_type?(type) }
		end

		# Registers a parser class, replacing any existing parser for the same type.
		def register(parser_class)
			validate_parser_class!(parser_class)

			type = parser_class.detects
			existing_index = @parsers.index { |parser| parser.matches_type?(type) }

			if existing_index
				old = @parsers[existing_index]
				@parsers[existing_index] = ParserEntry.from_class(parser_class)
				return old.parser_class
			end

			@parsers << ParserEntry.from_class(parser_class)
			nil
		end

		# Registers a lazy parser entry that will be loaded only when used.
		def register_lazy_parser(type: nil, type_name: nil, &loader)
			raise ArgumentError, "A loader block is required" unless block_given?

			entry = ParserEntry.for_lazy(
				type: type,
				type_name: type_name,
				loader: loader,
				validator: method(:validate_parser_class!)
			)

			existing = @parsers.find do |parser|
				if entry.type
					parser.matches_type?(entry.type)
				else
					parser.matches_type_name?(entry.type_name)
				end
			end
			return nil if existing

			@parsers << entry
			entry
		end

		# Deregisters parser classes by class reference.
		def deregister(parser_classes)
			Array(parser_classes).each do |klass|
				next unless klass.is_a?(Class) && klass < InferType::Parser

				@parsers.delete_if { |parser| parser.matches_parser_class?(klass) }
			end
		end

		# Moves parsers to the front in the given order.
		def prioritize(*items)
			reorder(items, to_front: true)
		end

		# Moves parsers to the back in the given order.
		def deprioritize(*items)
			reorder(items, to_front: false)
		end

		private

		# Ensures a parser class meets the expected interface.
		def validate_parser_class!(parser_class)
			unless parser_class.is_a?(Class) && parser_class < InferType::Parser
				raise ArgumentError, "Parser must subclass InferType::Parser"
			end

			type = parser_class.detects
			raise ArgumentError, "Parser must declare the type it detects" if type.nil?

			unless type.is_a?(Class) && !type.is_a?(String)
				raise ArgumentError, "Parser must detect a Class (other than String)"
			end

			unless parser_class.instance_methods(false).include?(:parse)
				raise ArgumentError, "Parser must define #parse(str)"
			end

			arity = parser_class.instance_method(:parse).arity
			unless arity == 1 || arity == -2
				raise ArgumentError, "#parse must accept exactly one argument"
			end
		end

		# Normalises parser classes or types into registry entries.
		def normalize(items)
			Array(items).map do |item|
				if item.is_a?(Class) && item < InferType::Parser
					parser_entry_for_parser_class(item) || ParserEntry.from_class(item)
				elsif item.is_a?(Class)
					parser = parser_entry_for_type(item)
					raise KeyError, "No parser registered for type #{item}" if parser.nil?
					parser
				else
					raise ArgumentError, "Expected parser class or type class"
				end
			end
		end

		# Finds an entry for a parser class without forcing lazy loads.
		def parser_entry_for_parser_class(parser_class)
			@parsers.find { |parser| parser.matches_parser_class?(parser_class) }
		end

		# Reorders parsers to the front or back.
		def reorder(items, to_front:)
			targets = normalize(items)
			remaining = @parsers.reject { |p| targets.include?(p) }

			@parsers =
				if to_front
					targets + remaining
				else
					remaining + targets
				end
		end
	end
end
