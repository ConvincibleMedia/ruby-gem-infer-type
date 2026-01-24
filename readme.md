# InferType

A simple and lightweight Ruby utility that **converts strings into their most appropriate Ruby types** using a pluggable, priority-based parser system.

* Detects common Ruby types (list below)
* You can specify a smaller list to detect when you call `parse()`
* You can define custom parsers to detect other types of any kind
* Priority order of detection is configurable


## Basic usage

```ruby
InferType.parse("123")
# => 123 # Integer

InferType.parse("1.5")
# => 1.5 # Float

InferType.parse("hello")
# => "hello" # remains a string as no other type detected
```


## Parsers

InferType runs through a series of `Parser` classes in priority order, which each get a chance to detect and parse the string into the type that they're concerned with, e.g. `Integer` or `Date`.

InferType comes with default parsers. It will detect, in order:

* Integer
* Float
* True
* False
* Nil
* Date (if valid)
* Time (if valid)

You can define your own class inheriting from `InferType::Parser` to detect other types -- see Custom Parsers below.

Parsers for Hashes and Arrays represented as strings are also available built in, but not enabled by default. To enable them, you have to explicitly register them first with `InferType.register(InferType::Parsers::HashParser)` or `ArrayParser`.


## Restricting Types

You can explicitly control which types are allowed for a parse operation:

```ruby
# Assuming a parser for BigDecimal has been registered...
InferType.parse("1000", BigDecimal, Date, Time)
# => 0.1e4 # BigDecimal. Integer parser wasn't called.
```

When specifying the types to look for explicitly like this, you are also specifying the priority order that will be used.


## Parser Priority

You can modify any parser's priority order with:

```ruby
InferType.prioritise(DateParser) # move to front
InferType.deprioritise(DateParser) # move to back
# American spellings also work
InferType.prioritize(DateParser, IntegerParser)
# moves both to front in this order
```

A parser can also be deregistered:

```ruby
InferType.deregister(IntegerParser)
# integers will no longer be parsed
```


## Parser Settings

Parsers may expose settings that let you modify how they parse. These are the settings available for built-in parsers (showing their defaults):

### Global

InferType has one global setting:

```ruby
STRIP = true
```

This controls whether inputs are stripped before parsing is attempted. It's `true` by default and we recommend you leave it that way. All the built-in parsers assume that they will receive a stripped string. As soon as you feel the need to strip within any parser, you probably ought to turn it on globally, as it will be too unpredictable if some parsers strip and others don't.

### Integer

```ruby
# Allow numbers with leading zeros like "00001" = 1
ALLOW_LEADING_ZERO = true
# Allow leading plus sign like "+2" = 2
ALLOW_LEADING_PLUS = true
```

### Float

```ruby
# If false, "1" is NOT considered a Float (must be "1.0" etc.)
ALLOW_INTEGER = true
# Allow exponential notation like 1e3 or 1.5E-2
ALLOW_EXPONENTIAL = true
# Allow special values: NaN, Infinity
ALLOW_SPECIAL_VALUES = false
```

### True, False, Nil

```ruby
# In strict mode, only accept "true", "false", "nil" to mean those respective things
# In relaxed mode, other similar terms are also allowed e.g. "on", "no", "null"
STRICT = true
# If true, case sensitive
CASE_SENSITIVE = false
```

### Time

```ruby
# If timezone offset is missing from a Time string, assume UTC
# If false, the system's local timezone will be used
DEFAULT_UTC = true
```

### Hash and Array

`HashParser` and `ArrayParser` aren't enabled by default. If you enable them, they both accept the same configuration:

```ruby
# The types that are allowed to appear in keys/values of Hashes and Arrays.
# You are only allowed to specify the types shown in the default list, plus Hash and Array.
ALLOWED_TYPES = [String, Integer, Float, TrueClass, FalseClass, NilClass]
# Hashes/arrays can be nested X levels deep (1 means no nesting, <=0 means unlimited)
# If MAX_DEPTH >= 2 the next level will never be reached unless Hash/Array are also added to ALLOWED_TYPES
MAX_DEPTH = 2
# If true, a string representing a Hash must begin/end with { } and a string representing an Array must begin/end with [ ]
# If false, strings that don't begin/end with these gain them first before type inference is attempted
REQUIRES_BRACKETS = true
```

## Custom Parsers

Custom parsers must be registered:

```ruby
InferType.register(BigDecimalParser)
InferType.register(MyCustomIntegerParser)
```

By default a newly registered parser either:

* replaces the parser already registered to deal with that type, in the same priority position; or
* goes to last place in priority order.

A parser **must**:

1. Subclass `InferType::Parser`
2. Declare exactly one class it detects with `detects <Class>`
3. Implement `#parse(str)`
4. Use `failure` or `success(value)` methods to return
5. If it parses successfully it must return the type of object declared in `detects`
6. Never raise on invalid input

### Example

```ruby
class UUIDParser < InferType::Parser
	detects MyCustomUUIDClass

	UUID_REGEX = /\A[0-9a-f\-]{36}\z/i

	def parse(str)
		return failure unless UUID_REGEX.match?(str)
		success(MyCustomUUIDClass.new(str))
	end
end

InferType.register(UUIDParser)
```
