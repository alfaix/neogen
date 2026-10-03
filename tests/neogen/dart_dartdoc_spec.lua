--- Test cases for dartdoc
---
--- @module 'tests.neogen.dart_spec'

local specs = require("tests.utils.specs")

local function make_dartdoc(source, type)
    return specs.make_docstring(source, "dart", { type = type, annotation_convention = { dart = "dartdoc" } })
end

-- Older Neovim versions do not ship a dart ftplugin, so we use the indentation from the Dart style guide
vim.o.expandtab = true

describe("dart: dartdoc", function()
    describe("func", function()
        it("works with an empty function", function()
            local source = [[
void foo() {|cursor|}
        ]]

            local expected = [[
/// [TODO:description]
void foo() {}
        ]]

            local result = make_dartdoc(source)

            assert.equal(expected, result)
        end)

        it("works with arguments", function()
            local source = [[
int add(int a, [int b = 0]) {
  return |cursor|a + b;
}
        ]]

            local expected = [[
/// [TODO:description]
///
/// * [a]: [TODO:parameter]
/// * [b]: [TODO:parameter]
int add(int a, [int b = 0]) {
  return a + b;
}
        ]]

            local result = make_dartdoc(source)

            assert.equal(expected, result)
        end)

        it("works with named arguments and arrow functions", function()
            local source = [[
void greet({required String name, int? age}) => print(|cursor|name);
        ]]

            local expected = [[
/// [TODO:description]
///
/// * [name]: [TODO:parameter]
/// * [age]: [TODO:parameter]
void greet({required String name, int? age}) => print(name);
        ]]

            local result = make_dartdoc(source)

            assert.equal(expected, result)
        end)

        it("skips wildcard arguments", function()
            local source = [[
void foo(int _, int bar, int _) {|cursor|}
        ]]

            local expected = [[
/// [TODO:description]
///
/// * [bar]: [TODO:parameter]
void foo(int _, int bar, int _) {}
        ]]

            local result = make_dartdoc(source)

            assert.equal(expected, result)
        end)

        it("works with methods and annotations", function()
            local source = [[
class Foo {
  @override
  static int bar(int a) {
    return |cursor|a;
  }
}
        ]]

            local expected = [[
class Foo {
  /// [TODO:description]
  ///
  /// * [a]: [TODO:parameter]
  @override
  static int bar(int a) {
    return a;
  }
}
        ]]

            local result = make_dartdoc(source)

            assert.equal(expected, result)
        end)

        it("works with constructors", function()
            local source = [[
class Foo extends Bar {
  Foo(super.key, this.a, int b) : |cursor|super();
}
        ]]

            local expected = [[
class Foo extends Bar {
  /// [TODO:description]
  ///
  /// * [key]: [TODO:parameter]
  /// * [a]: [TODO:parameter]
  /// * [b]: [TODO:parameter]
  Foo(super.key, this.a, int b) : super();
}
        ]]

            local result = make_dartdoc(source)

            assert.equal(expected, result)
        end)
    end)

    describe("class", function()
        it("works with a class", function()
            local source = [[
class Foo {
  void bar() {|cursor|}
}
        ]]

            local expected = [[
/// [TODO:description]
class Foo {
  void bar() {}
}
        ]]

            local result = make_dartdoc(source, "class")

            assert.equal(expected, result)
        end)

        it("works with an enum", function()
            local source = [[
enum Color { |cursor|red, green }
        ]]

            local expected = [[
/// [TODO:description]
enum Color { red, green }
        ]]

            local result = make_dartdoc(source)

            assert.equal(expected, result)
        end)
    end)
end)
