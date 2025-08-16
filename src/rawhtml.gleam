import ffi/ffi
import loading
import lustre/element.{type Element}
import types.{type PageProps}

pub fn page(content: String, _props: PageProps) -> Element(msg) {
  ffi.render_raw_html(content)
  loading.element()
}
