//// x-www-form-urlencoded codec
////
//// The codec follows the WHATWG specification available at:
//// https://url.spec.whatwg.org/#application/x-www-form-urlencoded but uses
//// UTF-8 as the only supported encoding.

import gleam/dynamic
import gleam/list
import gleam/map.{Map}
import gleam/uri
import gleam/result
import gleam/string
import gleam/string_builder
import gleam/option

pub type Query {
  QStr(String)
  QList(List(Query))
  QMap(Map(String, Query))
}

/// Characters not encoded by Gleam's percent encoding, but that we need to encode
const not_encoded_by_gleam = [
  #("!", "%21"),
  #("$", "%24"),
  #("'", "%27"),
  #("(", "%28"),
  #(")", "%29"),
  #("+", "%2B"),
  #("~", "%7E"),
]

/// Encode a list of pairs into a URL query string
///
/// The values of these pairs should be of the `Query` type.
///
/// ## Examples
///
///    > encode([#("foo", QStr("bar bar")), #("baz", QStr("qux"))])
///    "foo=bar+bar&baz=qux"
///
///    > encode([#("foo", QList([QStr("bar"), QStr("b!z")]))])
///    "foo%5B%5D=bar&foo%5B%5D=b%21z"
///
///    > encode([#("foo", QMap(map.from_list([#("bar", "baz")])))])
///    "foo%5Bbar%5D=baz"
///
pub fn encode(contents: List(#(String, Query))) -> String {
  contents
  |> list.flat_map(fn(pair) {
    let #(key, value) = pair
    encode_query(key, value)
  })
  |> string_builder.join(with: "&")
  |> string_builder.to_string()
}

fn encode_query(key, query) {
  case query {
    QStr(str) -> encode_string(key, str, option.None)
    QList(values) -> encode_list(key, values)
    QMap(pairs) -> encode_map(key, pairs)
  }
}

fn encode_string(key, str, collection_key: option.Option(String)) {
  let key = string_builder.from_string(key)
  let str = string_builder.from_string(str)

  let key = case collection_key {
    option.Some(collection_key) ->
      key
      |> string_builder.append("[")
      |> string_builder.append(collection_key)
      |> string_builder.append("]")
    option.None -> key
  }

  [
    encode_term(key)
    |> string_builder.append("=")
    |> string_builder.append_builder(encode_term(str)),
  ]
}

fn encode_list(key, values) {
  list.flat_map(values, encode_query(string.concat([key, "[]"]), _))
}

fn encode_map(key, pairs) {
  pairs
  |> map.to_list()
  |> list.flat_map(fn(pair) {
    let #(subkey, value) = pair
    encode_query(string.concat([key, "[", subkey, "]"]), value)
  })
}

fn encode_term(term: string_builder.StringBuilder) {
  term
  |> string_builder.split(" ")
  |> list.map(fn(part) {
    let encoded = uri.percent_encode(string_builder.to_string(part))

    list.fold(
      not_encoded_by_gleam,
      encoded,
      fn(acc, item) {
        let #(char, replacement) = item
        string.replace(acc, char, replacement)
      },
    )
    |> string_builder.from_string()
  })
  |> string_builder.join("+")
}

pub type DecodeError {
  InvalidQuery
  DynamicError(List(dynamic.DecodeError))
}

/// Decode the URL query string into a data structure as specified by `decoder`
/// (likely a function from `gleam/dynamic`).
pub fn decode(
  from encoded: String,
  using decoder: dynamic.Decoder(a),
) -> Result(a, DecodeError) {
  encoded
  |> string.split("&")
  |> list.fold_right(Ok([]), decode_next)
  |> result.map_error(fn(_) { InvalidQuery })
  |> result.then(undynamicize(_, decoder))
}

fn decode_next(acc, pair) {
  result.then(
    acc,
    fn(acc) {
      decode_pair(pair)
      |> result.map(fn(newpair) { [newpair, ..acc] })
    },
  )
}

fn decode_pair(pair) {
  try #(key, value) = string.split_once(pair, "=")
  try key = uri.percent_decode(key)
  try value = uri.percent_decode(value)

  let key = string.replace(key, "+", " ")
  let value = string.replace(value, "+", " ")
  Ok(#(key, value))
}

fn undynamicize(list, decoder) {
  list
  |> dynamic.from()
  |> decoder()
  |> result.map_error(fn(decode_errors) { DynamicError(decode_errors) })
}
