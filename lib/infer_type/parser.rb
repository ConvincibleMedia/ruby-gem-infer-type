# frozen_string_literal: true

module InferType
	# Base class for parsers
	class Parser
		class << self
			# Method to specify or retrieve the type this parser detects
			def detects(type = nil)
				if type
					raise ArgumentError, "detects cannot be String" if type == String
					raise ArgumentError, "detects must be a Class" unless type.is_a?(Class)
					@detects = type
				end

				@detects
			end
		end

		# Subclasses must implement this method
		def parse(_str)
			raise NotImplementedError
		end

		private

		# Methods to create success and failure results
		def success(value)
			InferType::Success.new(
				value: value,
				parser: self.class
			)
		end

		def failure
			InferType::Failure.new(parser: self.class)
		end
	end
end

