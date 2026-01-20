# frozen_string_literal: true

module InferType
	class Registry
		def initialize
			@parsers = []
		end

		def parsers
			@parsers.dup
		end

		def parser_for_type(type)
			@parsers.find { |parser| parser.detects == type }
		end

		# Methods to manage parser registration
		def register(parser_class)
			validate_parser_class!(parser_class)

			type = parser_class.detects
			existing_index = @parsers.index { |parser| parser.detects == type }

			if existing_index
				old = @parsers[existing_index]
				@parsers[existing_index] = parser_class
				return old
			end

			# Last registered has lowest priority
			@parsers << parser_class
			nil
		end

		def deregister(parser_classes)
			Array(parser_classes).each do |klass|
				@parsers.delete(klass)
			end
		end

		# Methods to manage parser priority
		def prioritize(*items)
			reorder(items, to_front: true)
		end

		def deprioritize(*items)
			reorder(items, to_front: false)
		end

		private

		# Ensure parser class being registered is valid
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

		# Normalize parser class or type to parser class
		def normalize(items)
			Array(items).map do |item|
				if item.is_a?(Class) && item < InferType::Parser
					item
				elsif item.is_a?(Class)
					parser = parser_for_type(item)
					raise KeyError, "No parser registered for type #{item}" if parser.nil?
					parser
				else
					raise ArgumentError, "Expected parser class or type class"
				end
			end
		end

		# Reorder parsers to front or back
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

