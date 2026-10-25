import ffi/ffi
import gleam/dict
import gleam/list
import gleam/result
import gleam/string
import gleam/uri
import plinth/browser/location
import plinth/browser/window
import utils

pub fn get_url_params() -> dict.Dict(String, String) {
  let win = window.self()
  let hashs = win |> window.location |> location.hash |> result.unwrap("")
  let querys = win |> window.location |> location.search |> result.unwrap("")

  // 第1个版本 参数直接写在querys
  let raw_params = get_query_params(querys)
  let hash_params = case hashs |> string.contains("=") {
    // 第2个版本 参数直接改为写在hash中, 用k=v的形式
    True -> get_query_params(hashs)
    // 第3个版本 参数仍然在hash中，但是使用/type/src/key的形式
    False -> get_path_params(hashs)
  }

  // merge to hash_params
  let ret = hash_params |> dict.merge(raw_params)
  // wrap src
  let next_src =
    ret |> dict.get("src") |> result.unwrap("unknown") |> utils.wrap_src
  ret |> dict.insert("src", next_src)
}

// old version
//
// pub fn param_dict_to_hashed_url(params: dict.Dict(String, String)) {
//   window.self() |> window.location |> location.pathname()
//   <> "#"
//   <> {
//     params
//     |> dict.to_list
//     |> uri.query_to_string
//   }
// }

pub fn param_dict_to_hashed_href(params: dict.Dict(String, String)) {
  let d = params |> dict.get("d") |> result.unwrap("md")
  let src = params |> dict.get("src") |> result.unwrap("")
  let key = params |> dict.get("key") |> result.unwrap("")

  let src = unwrap_src(src)
  let c_location = window.self() |> window.location
  c_location |> location.origin
  <> c_location |> location.pathname
  <> "#/"
  <> case d {
    "md" | "markdown" -> [src, key]
    _ -> [d, src, key]
  }
  |> string.join("/")
}

pub fn try_render_html(content: String) {
  case
    {
      use flag <- list.any(["<!DOCTYPE html", "<!doctype html", "<html"])
      content |> string.trim_start |> string.starts_with(flag)
    }
  {
    False -> Nil
    True -> {
      let next_href =
        get_url_params()
        |> dict.insert("d", "html")
        |> param_dict_to_hashed_href
      // window.set_location(window.self(), next_href)
      ffi.window_location_replace(window.self(), next_href)
    }
  }
}

fn get_query_params(queries: String) -> dict.Dict(String, String) {
  queries
  |> uri.parse_query
  |> result.unwrap([])
  |> dict.from_list
}

fn get_path_params(path: String) -> dict.Dict(String, String) {
  let sps = path |> string.split("/") |> list.filter(fn(x) { x != "" })
  case sps {
    [d, src, key] -> [#("d", d), #("src", src), #("key", key)]
    [src, key] -> [#("d", "md"), #("src", src), #("key", key)]
    _ -> []
  }
  |> dict.from_list
}

fn unwrap_src(src: String) -> String {
  src
  |> string.remove_suffix(".x")
  |> string.remove_suffix(".x.png")
  |> string.remove_prefix("bin/")
}
