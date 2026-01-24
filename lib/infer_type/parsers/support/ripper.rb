# frozen_string_literal: true
require "ripper"

module InferType
	module Parsers
		module Support

			module Ripper

				ALLOWED_NODES = %i[
					program stmts_add stmts_new
					hash assoclist_from_args assoc_new
					symbol_literal symbol
					@ident @label
					string_literal string_content @tstring_content
					@int @float
					array
					var_ref @kw
					unary
				]

				ALLOWED_KEYWORDS = %w[true false nil].freeze
				PERMITTED_TYPES = [
					String, Integer, Float, TrueClass, FalseClass, NilClass, Hash, Array
				].freeze

				private

				def literal_only?(sexp)
					return true if location_literal?(sexp)
					return true unless sexp.is_a?(Array)
					return sexp.all? { |child| literal_only?(child) } unless sexp[0].is_a?(Symbol)
					return false unless ALLOWED_NODES.include?(sexp[0])

					case sexp[0]
					when :var_ref
						return keyword_ref?(sexp)
					when :@kw
						return ALLOWED_KEYWORDS.include?(sexp[1])
					when :unary
						return false unless %i[+@ -@].include?(sexp[1])
					end

					sexp.all? { |child| literal_only?(child) }
				end

				def stringify_keys(obj)
					case obj
					when Hash
						obj.each_with_object({}) do |(key, value), acc|
							new_key = key.is_a?(Symbol) ? key.to_s : key
							acc[new_key] = stringify_keys(value)
						end
					when Array
						obj.map { |v| stringify_keys(v) }
					else
						obj
					end
				end

				def parse_hash_literal(str, allowed_types:, max_depth:, requires_brackets:)
					parse_literal(
						str,
						expected: Hash,
						open: "{",
						close: "}",
						allowed_types: allowed_types,
						max_depth: max_depth,
						requires_brackets: requires_brackets
					)
				end

				def parse_array_literal(str, allowed_types:, max_depth:, requires_brackets:)
					parse_literal(
						str,
						expected: Array,
						open: "[",
						close: "]",
						allowed_types: allowed_types,
						max_depth: max_depth,
						requires_brackets: requires_brackets
					)
				end

				def parse_literal(str, expected:, open:, close:, allowed_types:, max_depth:, requires_brackets:)
					return nil unless settings_valid?(allowed_types, max_depth, requires_brackets)

					candidate = ensure_brackets(str, open, close, requires_brackets)
					return nil if candidate.nil?

					value = safe_eval_literal(candidate)
					return nil unless value.is_a?(expected)

					value = stringify_keys(value) if value.is_a?(Hash)
					if value.is_a?(Hash)
						normalize_hash(value, allowed_types, max_depth, depth: 1, root: true)
					else
						normalize_array(value, allowed_types, max_depth, depth: 1, root: true)
					end
				rescue StandardError
					nil
				end

				def safe_eval_literal(str)
					sexp = ::Ripper.sexp(str)
					raise ArgumentError, "Invalid Ruby syntax" unless sexp
					raise ArgumentError, "Unsafe input" unless literal_only?(sexp)

					Kernel.eval(str) # safe after validation
				end

				def ensure_brackets(str, open, close, requires_brackets)
					if str.start_with?(open) && str.end_with?(close)
						str
					else
						return nil if requires_brackets
						return nil if str.start_with?(open) || str.end_with?(close)

						"#{open}#{str}#{close}"
					end
				end

				def settings_valid?(allowed_types, max_depth, requires_brackets)
					return false unless allowed_types.is_a?(Array)
					return false unless allowed_types.all? { |type| PERMITTED_TYPES.include?(type) }
					return false unless max_depth.is_a?(Integer)
					return false unless requires_brackets == true || requires_brackets == false

					true
				end

				def normalize_hash(hash, allowed_types, max_depth, depth:, root:)
					return nil if depth_exceeded?(depth, max_depth)
					raise ArgumentError, "Hash not allowed" unless root || allowed_types.include?(Hash)

					hash.each_with_object({}) do |(key, value), acc|
						normalized_key = normalize_key(key, allowed_types, max_depth, depth)
						normalized_value = normalize_value(value, allowed_types, max_depth, depth)
						acc[normalized_key] = normalized_value
					end
				end

				def normalize_array(array, allowed_types, max_depth, depth:, root:)
					return nil if depth_exceeded?(depth, max_depth)
					raise ArgumentError, "Array not allowed" unless root || allowed_types.include?(Array)

					array.map { |value| normalize_value(value, allowed_types, max_depth, depth) }
				end

				def normalize_key(key, allowed_types, max_depth, depth)
					if key.is_a?(Symbol)
						raise ArgumentError, "String keys not allowed" unless allowed_types.include?(String)
						return key.to_s
					end

					normalize_value(key, allowed_types, max_depth, depth)
				end

				def normalize_value(value, allowed_types, max_depth, depth)
					case value
					when Hash
						return nil if depth_exceeded?(depth + 1, max_depth)
						normalize_hash(value, allowed_types, max_depth, depth: depth + 1, root: false)
					when Array
						return nil if depth_exceeded?(depth + 1, max_depth)
						normalize_array(value, allowed_types, max_depth, depth: depth + 1, root: false)
					when Symbol
						raise ArgumentError, "Symbols are not allowed"
					else
						# Use is_a? to allow pre-2.4 Fixnum/Bignum when Integer is permitted.
						raise ArgumentError, "Type not allowed" unless allowed_types.any? { |type| value.is_a?(type) }
						value
					end
				end

				def depth_exceeded?(depth, max_depth)
					return false if max_depth <= 0
					depth > max_depth
				end

				def location_literal?(sexp)
					sexp.is_a?(Array) && sexp.all? { |item| item.is_a?(Integer) }
				end

				def keyword_ref?(sexp)
					node = sexp[1]
					node.is_a?(Array) && node[0] == :@kw && ALLOWED_KEYWORDS.include?(node[1])
				end

			end

		end
	end
end
