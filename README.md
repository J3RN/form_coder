# `form_coder`

A Gleam library to encode and decode `x-www-form-urlencoded` data.

This data is a superset of your traditional GET query parameter format;
e.g. `foo=bar&baz=qux`. While there's no established standard for conveying data
structures such as lists and maps, `form_coder` follows the format used by both
Rails and Plug. Namely:

- A list like `[#("foo", ["bar", "baz"])]` is encoded to `foo[]=bar&foo[]=baz`
- A map like `[#("foo", %{"bar" => "qux"})]` (map in Elixir syntax for brevity) is
  encoded as `foo[bar]=qux`.

## Examples

### Encoding

```gleam
> form_coder.encode([#("foo", QStr("bar")), #("baz", QStr("qux"))])
"foo=bar&baz=qux"
```

```gleam
> form_coder.encode(#("user_ids", QList([QStr("1"), QStr("2")])))
"user_ids[]=1&user_ids[]=2"
```

```gleam
> form_coder.encode(#("person", QMap(map.from_list([#("name", QStr("Joe")), #("age", QStr("71"))]))))
"person[age]=71&person[name]=Joe"
```

**What's with `QStr`, `QList`, and `QMap`?**

Well, in the type specification, the argument must take the form
`List(#(String, _))`, where I can choose what to replace `_` with. Choosing
any one of `String`, `List`, or `Map` would make using the other two very
inconvenient. Using some type variable `a` is would enforce that all "values"
have the same type (i.e. you can't have some values as strings and others as
lists) and `form_coder` would have to know how to encode your arbitrary `a` and
that doesn't seem possible.

Since Gleam doesn't have union types, I created an algebraic type with variants
to wrap each supported type; hence `QStr`, `QList`, and `QMap`.

### Decoding

```gleam
> form_coder.decode("foo=bar&baz=qux", dynamic.list(of: dynamic.tuple2(dynamic.string, dynamic.string)))
[#("foo", "bar"), #("baz", "qux")]
```

Support for decoding the more sophisticated types (List, Map) is planned, but
not yet implemented.

## Quick start

```sh
gleam build # Compile the project
gleam test  # Run the tests
gleam shell # Run an Erlang shell
```

## Installation

```sh
gleam add form_coder
```
