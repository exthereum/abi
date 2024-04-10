# 1.0.0-bravo1
* Fix ABI tuple encoding for nested inlined tuples
# 1.0.0-alpha9
* Add Names to Event Signatures
# 1.0.0-alpha8
* Add Event Signature check to ABI.Event.decode_event
* Change `decode_event` to return an {:ok, event_name, event_params} tuple.
* Add ability to add `"indexed"` keyword to ABI canonicals
# 1.0.0-alpha7
* Bugfix for event decoding with dynamic parameters
# 1.0.0-alpha6
* Bugfix for is_dynamic
# 0.1.15
* Properly treat all function encodes as tuple encodings
# 0.1.14
* Fix 0-length `type[]` encoding
# 0.1.13
* Drop dependency on exth crypto and move in functionality
# 0.1.12
* Fix `string` decoding to truncate on encountering NUL
* Fix some edge-cases in `tuple` encoding/decoding
# 0.1.11
* Add support for method ID calculation of all standard types
# 0.1.10
* Fix parsing of function names containing uppercase letters/digits/underscores
* Add support for `bytes<M>`
# 0.1.9
* Add support for parsing ABI specification documents (`.abi.json` files)
* Reimplement function signature parsing using a BNF grammar
* Fix potential stack overflow during encoding/decoding
# 0.1.8
* Fix ordering of elements in tuples
# 0.1.7
* Fix support for arrays of uint types
# 0.1.6
* Add public interface to raw function versions.
# 0.1.5
* Bugfix so that addresses are still left padded.
# 0.1.4
* Bugfix for tuples to properly handle tail pointer poisition.
# 0.1.3
* Bugfix for tuples to properly handle head/tail encoding
# 0.1.2
* Add support for tuples, fixed-length and variable length arrays
