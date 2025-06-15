pub opaque type LineNumber {
  LineNumber(line_number: Int)
}

pub fn from_int(line_number: Int) -> LineNumber {
  case line_number > 0 {
    True -> LineNumber(line_number)
    False -> panic as "Line number should never be negative!"
  }
}

pub fn to_int(line_number: LineNumber) -> Int {
  line_number.line_number
}
