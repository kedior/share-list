import gleam/dict
import gleam/dynamic/decode
import gleam/function
import gleam/json
import gleam/list
import lustre/attribute
import lustre/element

pub type PageProps =
  dict.Dict(String, String)

pub opaque type Page {
  Page(name: String, with_props: PageProps)
}

pub fn new(name) {
  Page(name, dict.new())
}

pub fn with_props(page: Page, props: List(#(String, String))) {
  Page(
    ..page,
    with_props: props |> dict.from_list |> dict.merge(page.with_props),
  )
}

pub fn to_json(page: Page) {
  json.object([
    #("name", json.string(page.name)),
    #("with_props", json.dict(page.with_props, function.identity, json.string)),
  ])
}

pub fn decoder() {
  use name <- decode.field("name", decode.string)
  use with_props <- decode.field(
    "with_props",
    decode.dict(decode.string, decode.string),
  )
  decode.success(Page(name:, with_props:))
}

pub fn create(page: Page, attr) {
  element.element(
    page.name,
    list.append(attr, {
      let kvs = page.with_props |> dict.to_list
      use kv <- list.map(kvs)
      attribute.property(kv.0, json.string(kv.1))
    }),
    [],
  )
}
