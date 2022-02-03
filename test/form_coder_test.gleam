import gleeunit
import gleeunit/should
import gleam/map
import gleam/dynamic
import form_coder.{QList, QMap, QStr}

pub fn main() {
  gleeunit.main()
}

// Encoding
pub fn encode_strings_test() {
  let data = [#("foo", QStr("bar")), #("baz", QStr("qux"))]

  assert "foo=bar&baz=qux" = form_coder.encode(data)
}

pub fn encode_lists_test() {
  let data = [
    #("user_ids", QList([QStr("1"), QStr("2")])),
    #("product_ids", QList([QStr("5"), QStr("7")])),
  ]

  assert "user_ids[]=1&user_ids[]=2&product_ids[]=5&product_ids[]=7" =
    form_coder.encode(data)
}

pub fn encode_maps_test() {
  let data = [
    #(
      "person",
      QMap(map.from_list([#("name", QStr("Joe")), #("age", QStr("71"))])),
    ),
    #(
      "cat",
      QMap(map.from_list([#("name", QStr("Nubi")), #("age", QStr("5"))])),
    ),
  ]

  assert "person[age]=71&person[name]=Joe&cat[age]=5&cat[name]=Nubi" =
    form_coder.encode(data)
}

pub fn encode_mixed_nonsense_test() {
  let data = [
    #(
      "person",
      QMap(map.from_list([#("name", QStr("Joe")), #("age", QStr("71"))])),
    ),
    #("user_ids", QList([QStr("1"), QStr("2")])),
    #("foo", QStr("bar")),
  ]

  assert "person[age]=71&person[name]=Joe&user_ids[]=1&user_ids[]=2&foo=bar" =
    form_coder.encode(data)
}

pub fn encode_nested_nonsense_test() {
  let data = [
    #(
      "products",
      QList([
        QMap(map.from_list([#("name", QStr("Toaster")), #("price", QStr("15"))])),
        QMap(map.from_list([
          #("name", QStr("Microwave")),
          #("price", QStr("50")),
        ])),
      ]),
    ),
    #(
      "people",
      QMap(map.from_list([
        #("names", QList([QStr("Joe"), QStr("Robert"), QStr("Mike")])),
        #("count", QStr("3")),
      ])),
    ),
  ]

  assert "products[][name]=Toaster&products[][price]=15&products[][name]=Microwave&products[][price]=50&people[count]=3&people[names][]=Joe&people[names][]=Robert&people[names][]=Mike" =
    form_coder.encode(data)
}

// Decoding
pub fn decode_strings_test() {
  let query = "foo=bar&baz=qux"

  assert Ok([#("foo", "bar"), #("baz", "qux")]) =
    form_coder.decode(
      query,
      dynamic.list(of: dynamic.tuple2(dynamic.string, dynamic.string)),
    )
}
