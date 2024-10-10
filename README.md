# Archived and Not Supported

KEVN is no longer supported. I've reached the opinion that Lua table constructors are good enough for small configuration files, and they can be serialized out with another library like [Serpent](https://github.com/pkulchenko/serpent) or my [T2S2](https://github.com/rabbitboots/t2s2).

**Version: 2.0.0**

# KEVN

KEVN ("Key Equals Value, Newline") is an INI-like file parser for Lua 5.1 - 5.4.

A KEVN file looks like this:

```
; Comment
key=value
website=https://www.example.com/

[group_id]
foo=bar
bar=foo
```

# Package Information

`kevn.lua` is the main file.

Files and folders beginning with `test` can be deleted.

Files beginning with `pile` are required (they contain boilerplate Lua snippets).


# API: Main

## kevn.decode

Converts a KEVN string to a Lua table.

`local tbl = kevn.decode(str)`

* `str`: The KEVN string to parse.

**Returns:** A Lua table, or `nil`, an error string, and a line number if parsing failed.


## kevn.encode

Converts a table to a KEVN string. The output is sorted alphabetically. All group names, keys and values must be strings. For more control over output, see *API: Writer Functions*.

`local str = kevn.encode(tbl)`

* `tbl` The table to convert.

**Returns:** A string based on the table.


# API: Writer Functions

Use these functions to construct a KEVN string in pieces. They automatically escape characters where necessary.

Note that it's possible to create an invalid KEVN string by writing duplicate group or key names. You can reload the string with `kevn.decode` to test it.


```lua
-- Create an empty table
local tmp = {}

-- Write some lines
kevn.addGroupID(tmp, "the_group")
kevn.addItem(tmp, "hello", "world")

-- Finalize
local str = table.concat(tmp, "\n")

-- Output:
--[[
[the_group]
hello=world
--]]

-- To add comments: table.insert(tmp, "; a comment")
-- To add empty lines: table.insert(tmp, "")
```


## kevn.addGroupID

Adds a group ID to the writing table.

`kevn.addGroupID(t, group_id)`

* `t` The work-in-progress table of strings.

* `group_id` The group ID to write.


## kevn.addItem

Appends a key-value pair to the writing table.

`kevn.addItem(t, key, value)`

* `t` The work-in-progress table of strings.

* `key` *(string)* The key to write.

* `value` *(string)* The value to write.


# Notes

## INI Format(s)

INI files are made up of key-value pairs (`foo=bar`) that belong to groups (`[config]`). The groups and keys are unordered. All groups have unique names, and all keys have unique names within their group.

There is no official INI specification; you can find [any number of implementations with differing features](https://en.wikipedia.org/wiki/INI_file).


## Encoding

KEVN assumes UTF-8 encoding, but it does not perform any kind of validation. You can validate the encoding of a UTF-8 string with [Lua 5.3's utf8 library](https://www.lua.org/manual/5.3/manual.html#6.5), [kikito's UTF-8 validator](https://github.com/kikito/utf8_validator.lua), [utf8Tools](https://github.com/rabbitboots/utf8_tools), etc.


## Parsing Details

### Naming

Keys must contain at least one character. Values are allowed to be empty strings.

A hidden default group is automatically created for any key-value pairs which appear before the first group declaration. When allocated, its ID is an empty string. Besides the hidden default group, all other group IDs must contain at least one character.

Duplicate groups and duplicate keys within the same group are treated as an error.


### Ignored Content

KEVN ignores empty lines, lines containing only whitespace, and lines beginning with a semicolon (comments).


### Whitespace

Almost all whitespace is significant:

* `[ goo ber ]` -> `" goo ber "`.

* `foo = bar` -> `["foo "] = " bar"`

One exception: trailing whitespace after a group declaration is ignored: `[foo]   `


### Escape Sequences

Bytes in a KEVN string can be escaped with the form `\xx`, where `xx` is a hex value from `00` to `ff`.


#### Encoder Escape Behavior

The encoder automatically escapes characters, so you only need to worry about it if you are authoring KEVN files by hand.

|Character|Group IDs|Keys|Values|Escape Sequence|
|-|-|-|-|-|
|`\n`|Yes|Yes|Yes|`\0a`|
|`\r`|Yes|Yes|Yes|`\0d`|
|`;`|No|1st char|No|`\3b`|
|`=`|No|Yes|No|`\3d`|
|`[`|No|1st char|No|`\5b`|
|`\`|Yes|Yes|Yes|`\5c`|
|`]`|Yes|No|No|`\5d`|

Note that all backslashes need to be escaped: `path=C:\DOS` -> `path=C:\5cDOS`


#### Decoder Escape Behavior

The decoder transforms all escape sequences found in the substrings of group IDs, keys and values.


## Output Table Format

Here is an example of a table generated from kevn.decode():

```lua
local tbl = {
    [""] = {                   --; (The default / hidden group)
        this = "here",         --this=here
    },                         --
    player = {                 --[player]
        name = "Drernrern",    --name=Drernrern
        health = "100",        --health=100
        level = "1",           --level=1
    },                         --
    another_group = {          --[another_group]
        et = "cetera.",        --et=cetera.
    },
}
```


# License

```
MIT License

Copyright (c) 2023 - 2024 RBTS

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```
