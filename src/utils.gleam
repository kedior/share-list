import ffi/ffi
import gleam/dict
import gleam/dynamic/decode
import gleam/javascript/promise
import gleam/json
import gleam/list
import gleam/result
import gleam/string
import gleam/uri
import plinth/browser/window
import types.{type PageProps}

pub fn get_url_params() -> dict.Dict(String, String) {
  let parser = fn(res) {
    let str = res |> result.unwrap("")
    case str |> string.contains("=") {
      True -> str
      False -> ""
    }
    |> uri.parse_query
    |> result.unwrap([])
    |> dict.from_list
  }

  let hash_params = window.get_hash() |> parser
  let params_list = window.get_search() |> parser |> dict.to_list

  // filter out kv that not in hash_params
  {
    use #(k, v) <- list.filter_map(params_list)
    case hash_params |> dict.has_key(k) {
      True -> Error(Nil)
      False -> Ok(#(k, v))
    }
  }
  // merge to hash_params
  |> dict.from_list
  |> dict.merge(hash_params)
}

pub fn param_dict_to_hashed_url(params: dict.Dict(String, String)) {
  window.pathname()
  <> "#"
  <> {
    params
    |> dict.to_list
    |> uri.query_to_string
  }
}

pub fn page_props_to_json(d: PageProps, keys: List(String)) -> json.Json {
  let vals = {
    use k <- list.map(keys)
    d |> dict.get(k) |> result.unwrap("")
  }

  {
    use k, v <- list.map2(keys, vals)
    #(k, json.string(v))
  }
  |> json.object
}

pub fn json_decode_by_keys(keys: List(String)) {
  keys |> list.reverse |> do_json_decode_by_keys([])
}

fn do_json_decode_by_keys(reversed_keys: List(String), vals: List(String)) {
  case reversed_keys {
    [tail, ..others] -> {
      use val <- decode.field(tail, decode.string)
      // prepend
      do_json_decode_by_keys(others, [val, ..vals])
    }
    [] -> decode.success(vals)
  }
}

fn fetch_content(src: String, key: String) {
  use bit <- promise.try_await(ffi.decode_data_from_img(src))
  use content <- promise.try_await(ffi.decrypt_data(bit, key))
  promise.resolve(Ok(content))
}

pub fn await_get_content(
  src: String,
  key: String,
  callback: fn(Result(String, Nil)) -> Nil,
) {
  {
    use content <- promise.await(fetch_content(src, key))
    callback(content)
    promise.resolve(Nil)
  }
  Nil
}

pub fn guess_title(content: String) -> String {
  let tags = ["h1", "h2", "h3", "h4", "h5", "h6"]
  case
    {
      use tag <- list.find_map(tags)
      let open_tag = "<" <> tag <> ">"
      let close_tag = "</" <> tag <> ">"

      let trimd = string.trim_start(content)
      case string.starts_with(trimd, open_tag) {
        False -> Error(Nil)
        True -> {
          case
            open_tag
            |> string.length
            |> string.drop_start(trimd, _)
            |> string.split_once(close_tag)
          {
            Ok(#(title, _)) -> Ok(title)
            Error(Nil) -> Error(Nil)
          }
        }
      }
    }
  {
    Ok(title) -> title
    Error(Nil) -> "Awesome page"
  }
}

pub fn try_render_html(content: String) {
  case
    {
      use flag <- list.any(["<!DOCTYPE html", "<!doctype html"])
      content |> string.trim_start |> string.starts_with(flag)
    }
  {
    False -> Nil
    True -> {
      let next_href =
        get_url_params()
        |> dict.insert("d", "html")
        |> param_dict_to_hashed_url
      window.set_location(window.self(), next_href)
    }
  }
}
