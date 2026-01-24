# Design choices

## A parser detects a single type

This keeps things simple and predictable. If two parsers have shared logic, put that logic in a supporting module and reference it from each parser.

## Don't strip within parsers

We use a global strip setting and strip *before* parsers see the string. This is predictable. Parsers should be implemented without additional stripping. Thus if the developer wants to turn off the pre-strip, parsers will fail for strings like `"  2  "` which is what turning off pre-stripping intends.

## Don't be lenient

Parsers detect when a string *unambiguously* is intended as a representation of another class. This keeps the inference predictable. It's intentional that `2006-12` doesn't parse as a date, for instance.