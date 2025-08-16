import gleam/dict
import lustre/element.{type Element}

pub type PageProps =
  dict.Dict(String, String)

pub type Page(msg) =
  fn(PageProps) -> Element(msg)

pub type EncryptedPage(msg) =
  fn(String, PageProps) -> Element(msg)
