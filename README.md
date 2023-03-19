# KEVN

KEVN ("Key Equals Value, Newline") is a basic, INI-like file parser for Lua (LÖVE).


```
; Comment
key=value
website=https://www.example.com/

[group_id]
foo=bar
bar=foo
```

## INI Format(s)

INI files are similar to a Lua hash table with one level of nesting. They're comprised of key-value pairs (`foo=bar`) that belong to groups (`[config]`). The groups and keys are unordered. All groups have unique names, and all keys have unique names within their group.

That's the gist. There is no official INI specification that I'm aware of, and you can find [any number of implementations with differing features](https://en.wikipedia.org/wiki/INI_file). If you are evaluating KEVN for use in your project, be aware that it is case-sensitive and strict about whitespace.


## Use Cases

INI files are suitable for storage and retrieval of basic configuration, and they can also be used for basic metadata. While not pretty, they are human-readable, and can be modified with a simple text editor.


### Bad Use Cases

KEVN is not well suited for ordered sequences of data, or text that spans multiple lines.

While KEVN imposes no limit on the size of lines, very long stretches of text without a break can be difficult for users to read.

For more complex use cases, consider [json.lua by rxi](https://github.com/rxi/json.lua) or [serpent by Paul Kulchenko](https://github.com/pkulchenko/serpent)


## I Need Some Examples

See the [kevn_test](https://github.com/rabbitboots/kevn_test) repo for testing. *(It will eventually have some LÖVE-specific demos once I get around to writing them.)*


## Parsing Details

* Empty lines, lines containing only whitespace, and lines beginning with a semicolon (comments) are ignored.

* Line feeds (`\n`) Are used to split lines, and therefore cannot be part of any group ID, key or value.
  * On Windows, when loading files from disk, you may need to convert `\r\n` pairs to just `\n`. LÖVE's `filesystem` module does this automatically.

* With one exception, as far as the parser is concerned, **all other whitespace is significant.** `foo = bar` will result in the key "foo " and the value " bar". The group declaration `[con fig ]` becomes "con fig ".
  * The one exception is that trailing whitespace after the `]` in a group declaration is ignored: `[config]    `

* Keys cannot contain `=`, and they cannot have `;` or `[` as their first character.

* Keys and values can be empty. A single `=` is equivalent to a key of `""` with a value of `""`.

* Group IDs cannot contain `]`.

* Any duplicate groups or duplicate keys within the same group are treated as an error.

* The group `[]` is automatically created for any key-value pairs which appear before the first group declaration. It can be declared explicitly at the top of the file to ensure that the empty-string group is always created. Declaring it *after* this implicit creation is treated as an error.

* By default, all groups, keys and values are returned from the parser as strings. You can pass in *modifier* callbacks to perform additional processing and validity checks on group IDs and key+value pairs. (See *API: Modifiers* for more on that.) Or you can edit the table after it has been returned.


## Output Table Format


Without modifiers, the resulting output table looks something like this:

```lua
local tbl = {
    [""] = {                   --; (The default / global group)
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


# API: Main

## kevn.str2Table

Converts a KEVN string to a Lua table.

`local tbl = kevn.str2Table(str, fn_group, fn_key)`

* `str`: The KEVN string to parse.

* `fn_group`: An optional group ID modifier function. (See *API: Modifiers*)

* `fn_key`: An optional key+value modifier function. (See *API: Modifiers*)

**Returns:** A Lua table, or false and error string if parsing failed.


## kevn.table2Str

Converts a table to a KEVN string. The output is unordered, comments are not supported, and all group names, keys and values must be strings. For more control over output, see *API: Writer Functions*.

`local str = kevn.table2Str(tbl)`

* `tbl` The table to convert.

**Returns:** A string based on the table.


# API: Writer Functions

Use these functions to construct an INI string in pieces.


```lua
-- Create an empty table
local tmp = {}

-- Write some lines
kevn.appendGroupID(tmp, "the_group")
kevn.appendKey(tmp, "hello", "world")

-- Finalize
local str = table.concat(tmp, "\n")

-- Output:
--[[
[the_group]
hello=world
--]]
```

Note that it's possible to create an invalid KEVN string by writing duplicate group or key names. You can reload the string with `kevn.str2Table` to test it.


## kevn.appendGroupID

Appends a group ID to the writing table.

`kevn.appendGroupID(temp, group_id)`

* `temp` The WIP table of strings.

* `group_id` The group ID to write. Cannot contain `\n` or `]`.


## kevn.appendKey

Appends a key-value pair to the writing table.

`kevn.appendKey(temp, key, value)`

* `temp` The WIP table of strings.

* `key` *(string)* The key to write. Cannot contain `\n` or `=`, and cannot have `;` as its first character.

* `value` *(string)* The value to write. Cannot contain `\n`.



## kevn.appendComment

Appends a comment to the writing table. Line feeds (`\n`) are permitted, and will split the string into multiple comment lines.

`kevn.appendComment(temp, comment)`

* `temp` The WIP table of strings.

* `comment` *(string)* The comment to write.


## kevn.appendEmpty

Appends one or more empty lines for spacing.

`kevn.appendEmpty(temp, n)`

* `temp`: The WIP table of strings.

* `n` *(Number)* The number of empty lines to append. Default: 1



# API: Modifiers

Modifiers are optional callbacks that allow you to verify and mess with group IDs, keys and values while parsing. Use cases include:

* Implementation of type conversion or escape sequences, like converting the string `"true"` to boolean `true`.

* Checking that a key+value pair is valid in context.

You can skip this entirely and check the returned table after the fact, but using modifiers does allow including the line number of an offending section in your error messages.


## fn_group

Modifier callback for group IDs.

`local result, new_group_id = fn_group(tbl, group_id)`

* `tbl`: The work-in-progress table. (Be careful about modifying this during parsing.)

* `group_id`: The parsed group ID.

**Returns:** 1) true or false/nil, indicating success or failure, 2) A replacement group ID with no type restrictions, or an error string in the event of failure.


## fn_key

Modifier callback for key+value pairs.

`local result, new_key, new_value = fn_key(tbl, group_id, key, value)`

* `tbl`: The work-in-progress table. (Be careful about modifying this during parsing.)

* `group_id`: The group ID this key belongs to. Note that it may have been modified (changed type) by `fn_group`.

* `key`: The parsed key.

* `value`: The parsed value.

**Returns**: 1) true or false/nil, indicating success or failure, 2) a replacement key with no type restrictions, or an error string in the event of failure, and 3) a replacement value with no type restrictions.


# MIT License

Copyright (c) 2023 RBTS

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

