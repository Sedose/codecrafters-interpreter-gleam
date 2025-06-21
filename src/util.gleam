import gleam/string

pub fn is_alpha(ch: String) -> Bool {
  case string.to_utf_codepoints(ch) {
    [cp] -> {
      let code = string.utf_codepoint_to_int(cp)
      // 'a'..'z' or 'A'..'Z' or '_'
      code >= 97 && code <= 122
      || code >= 65 && code <= 90
      || code == 95
    }
    _ ->
      False
  }
}

pub fn is_alpha_numeric(ch: String) -> Bool {
  is_alpha(ch) || is_digit(ch)
}

pub fn is_digit(ch: String) -> Bool {
  case string.to_utf_codepoints(ch) {
    [cp] -> {
      let code = string.utf_codepoint_to_int(cp)
      // '0' is 48, '9' is 57
      code >= 48 && code <= 57
    }
    _ -> False
  }
}

pub fn is_number_char(ch: String) -> Bool {
  is_digit(ch) || ch == "."
}
