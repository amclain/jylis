use "ponytest"
use ".."

class TestAddress is UnitTest
  fun name(): String => "jylis.Address"
  
  fun apply(h: TestHelper) =>
    let addr = Address("127.0.0.1", "19999", "alpha")
    h.assert_eq[String](addr.string(), "127.0.0.1:19999:alpha")
