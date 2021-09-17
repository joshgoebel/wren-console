class Enforce {
  static num(v, name) {
    if (!(v is Num)) Fiber.abort("Expected 'Num' for '%(name)'")
  }

  static int(v, name) {
    if (!(v is Num) || !v.isInteger) Fiber.abort("Expected integer for '%(name)'")
  }

  static positiveInt(v, name) {
    if (!(v is Num) || !v.isInteger || v < 0) Fiber.abort("Expected positive integer for '%(name)'")
  }

  static string(v, name) {
    if (!(v is String)) Fiber.abort("Expected 'String' for '%(name)'")
  }

  static bool(v, name) {
    if (!(v is bool)) Fiber.abort("Expected 'Bool' for '%(name)'")
  }

  static fn(v, arity, name) {
    if (!(v is Fn) || v.arity != arity) Fiber.abort("Expected 'Fn' with %(arity) parameters for '%(name)'")
  }

  static type(v, type, name) {
    if (!(v is type)) Fiber.abort("Expected '%(type)' for '%(name)'")
  }
}
