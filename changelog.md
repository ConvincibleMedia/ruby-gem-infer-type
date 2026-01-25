# Changelog

## v0.2.0

This version is in progress.

* **Breaking**: built-in parsers explicitly leave string stripping in the control of the main `STRIP` constant. They don't strip additionally themselves.
* **Breaking**: if the input value is not a string, it is simply returned immediately rather than raising an error.
* Can now parse string representations of Hashes and Arrays, but parsers must be explicitly registered first.

## v0.1.1

Initial release.