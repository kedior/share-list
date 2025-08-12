import lustre/attribute
import lustre/element/html

pub fn element() {
  html.div([attribute.style("text-align", "center")], [
    html.h1([], [
      html.text("Oops! This page galloped away on a unicorn."),
    ]),
    html.img([
      attribute.attribute("src", "./unicorn.png"),
      attribute.attribute("alt", "Lost Unicorn"),
      attribute.styles([
        #("max-width", "300px"),
        #("margin", "40px auto"),
        #("display", "block"),
      ]),
    ]),
  ])
}
