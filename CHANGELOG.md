# KEVN Changelog

*(Date format: YYYY-MM-DD)*

# v2.0.0 2024-10-04

This is a major rewrite of KEVN.

* Renamed `kevn.str2Table()` to  `kevn.decode()`.
  * Deleted the function callbacks for groups and keys when encoding.
  * When the decoder failed, the returned error string included the line number. It is now returned separately as a third argument.
* Renamed `kevn.table2Str()` to `kevn.encode()`.
  * The encoder now sorts groups and keys alphabetically. Previously, the order was undefined.
* Renamed `kevn.appendGroupID()` to `kevn.addGroupID()`.
* Renamed `kevn.appendKey()` to `kevn.addKey()`.
* Deleted `kevn.appendComment()`. Use `table.insert(tmp, "; your comment")` instead.
* Deleted `kevn.appendEmpty()`. Use `table.insert(tmp, "")` instead.
* KEVN now has a character escape mechanism in the form of `\xx`, where `xx` is a hex byte from `00` to `ff`. The encoder escapes characters only as needed (for example, keys cannot begin with `;` or `[`, but they can appear in other positions). Refer to the README for a chart of escape codes.
* Keys and group IDs (besides the hidden default group) must now contain at least one character. Previously, keys were permitted to be empty strings, and a KEVN file could explicitly declare the default group with `[]` if it had not yet been allocated.
* Moved the test files to this repository, for ease of development.
* Started this changelog.
