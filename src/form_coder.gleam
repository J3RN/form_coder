import gleam/dynamic.{Dynamic}
import gleam/list
import gleam/map.{Map}
import gleam/uri
import gleam/result
import gleam/string

pub type Query {
  QStr(String)
  QList(List(Query))
  QMap(Map(String, Query))
}

/// Encode a list of pairs into a URL query string
///
/// The values of these pairs should be of the `Query` type.
///
/// ## Examples
///
///    > encode([#("foo", QStr("bar")), #("baz", QStr("qux"))])
///    "foo=bar&baz=qux"
///
///    > encode([#("foo", QList([QStr("bar"), QStr("baz")]))])
///    "foo[]=bar&foo[]=baz"
///
///    > encode([#("foo", QMap(map.from_list([#("bar", "baz")])))])
///    "foo[bar]=baz"
///
pub fn encode(contents: List(#(String, Query))) -> String {
  contents
  |> list.flat_map(fn(pair) {
    let #(key, value) = pair
    encode_query(key, value)
  })
  |> string.join(with: "&")
}

fn encode_query(key, query) {
  case query {
    QStr(str) -> encode_string(key, str)
    QList(values) -> encode_list(key, values)
    QMap(pairs) -> encode_map(key, pairs)
  }
}

fn encode_string(key, str) {
  [string.concat([key, "=", str])]
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

pub type DecodeError {
  InvalidQuery
  DynamicError(List(dynamic.DecodeError))
}

/// Decode the URL query string into a data structure as specified by `decoder`
/// (likely a function from `gleam/dynamic`).
pub fn decode(
  from encoded: String,
  using decoder: fn(Dynamic) -> Result(a, List(dynamic.DecodeError)),
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
  Ok(#(key, value))
}

fn undynamicize(list, decoder) {
  list
  |> dynamic.from()
  |> decoder()
  |> result.map_error(fn(decode_errors) { DynamicError(decode_errors) })
}
