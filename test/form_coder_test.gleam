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

  should.equal(form_coder.encode(data), "foo=bar&baz=qux")
}

pub fn encode_lists_test() {
  let data = [
    #("user_ids", QList([QStr("1"), QStr("2")])),
    #("product_ids", QList([QStr("5"), QStr("7")])),
  ]

  should.equal(
    form_coder.encode(data),
    "user_ids%5B%5D=1&user_ids%5B%5D=2&product_ids%5B%5D=5&product_ids%5B%5D=7",
  )
}

pub fn encode_maps_test() {
  let data = [
    #(
      "person",
      QMap(map.from_list([#("age", QStr("71")), #("name", QStr("Joe"))])),
    ),
    #(
      "cat",
      QMap(map.from_list([#("age", QStr("5")), #("name", QStr("Nubi"))])),
    ),
  ]

  should.equal(
    form_coder.encode(data),
    "person%5Bage%5D=71&person%5Bname%5D=Joe&cat%5Bage%5D=5&cat%5Bname%5D=Nubi",
  )
}

pub fn encode_mixed_nonsense_test() {
  let data = [
    #(
      "person",
      QMap(map.from_list([#("age", QStr("71")), #("name", QStr("Joe"))])),
    ),
    #("user_ids", QList([QStr("1"), QStr("2")])),
    #("foo", QStr("bar")),
  ]

  should.equal(
    form_coder.encode(data),
    "person%5Bage%5D=71&person%5Bname%5D=Joe&user_ids%5B%5D=1&user_ids%5B%5D=2&foo=bar",
  )
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
        #("count", QStr("3")),
        #("names", QList([QStr("Joe"), QStr("Robert"), QStr("Mike")])),
      ])),
    ),
  ]

  should.equal(
    form_coder.encode(data),
    "products%5B%5D%5Bname%5D=Toaster&products%5B%5D%5Bprice%5D=15&products%5B%5D%5Bname%5D=Microwave&products%5B%5D%5Bprice%5D=50&people%5Bcount%5D=3&people%5Bnames%5D%5B%5D=Joe&people%5Bnames%5D%5B%5D=Robert&people%5Bnames%5D%5B%5D=Mike",
  )
}

pub fn encode_spaces_test() {
  let data = [#("can I have some spaces", QStr("please enjoy these spaces"))]

  should.equal(
    form_coder.encode(data),
    "can+I+have+some+spaces=please+enjoy+these+spaces",
  )
}

pub fn encode_chars_test() {
  let data = [#("äöå", QStr("!$'()+~"))]

  should.equal(
    form_coder.encode(data),
    "%C3%A4%C3%B6%C3%A5=%21%24%27%28%29%2B%7E",
  )
}

pub fn keep_chars_test() {
  let data = [#("ok_chars", QStr("_-*."))]

  should.equal(form_coder.encode(data), "ok_chars=_-*.")
}

// Decoding
pub fn decode_strings_test() {
  let query = "foo=bar&baz=qux"

  form_coder.decode(
    query,
    dynamic.list(of: dynamic.tuple2(dynamic.string, dynamic.string)),
  )
  |> should.be_ok()
  |> should.equal([#("foo", "bar"), #("baz", "qux")])
}

pub fn decode_spaces_test() {
  let query = "foo+space=bar+bar"

  form_coder.decode(
    query,
    dynamic.list(of: dynamic.tuple2(dynamic.string, dynamic.string)),
  )
  |> should.be_ok()
  |> should.equal([#("foo space", "bar bar")])
}

pub fn decode_chars_test() {
  let query = "*%C3%B6ljy*=%C3%A5ngstr%C3%B6m%21"

  form_coder.decode(
    query,
    dynamic.list(of: dynamic.tuple2(dynamic.string, dynamic.string)),
  )
  |> should.be_ok()
  |> should.equal([#("*öljy*", "ångström!")])
}
