class EnforceError {
  construct new(message) {
    _message = message
  }
  message { _message }
  toString { _message }
  throw() { Fiber.abort(this) }
}

class Enforce {
  static error(msg) {
    var err = EnforceError.new(msg)
    err.throw()
  }

  static num(v, name) {
    if (!(v is Num)) error("Expected 'Num' for '%(name)'")
  }

  static int(v, name) {
    if (!(v is Num) || !v.isInteger) error("Expected integer for '%(name)'")
  }

  static positiveNum(v, name) {
    if (!(v is Num) || v < 0) error("Expected positive integer for '%(name)'")
  }

  static positiveInt(v, name) {
    if (!(v is Num) || !v.isInteger || v < 0) error("Expected positive integer for '%(name)'")
  }

  static string(v, name) {
    if (!(v is String)) error("Expected 'String' for '%(name)'")
  }

  static bool(v, name) {
    if (!(v is bool)) error("Expected 'Bool' for '%(name)'")
  }

  static fn(v, arity, name) {
    if (!(v is Fn) || v.arity != arity) error("Expected 'Fn' with %(arity) parameters for '%(name)'")
  }

  static type(v, type, name) {
    if (!(v is type)) error("Expected '%(type)' for '%(name)'")
  }
}
