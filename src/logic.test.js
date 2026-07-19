const { greet, add, isPalindrome } = require("./logic");

describe("greet", () => {
  test("greets a given name", () => {
    expect(greet("Rishabh")).toBe("Hello, Rishabh!");
  });

  test("falls back to World when no name given", () => {
    expect(greet()).toBe("Hello, World!");
    expect(greet("")).toBe("Hello, World!");
    expect(greet("   ")).toBe("Hello, World!");
  });

  test("trims whitespace around the name", () => {
    expect(greet("  Priya  ")).toBe("Hello, Priya!");
  });
});

describe("add", () => {
  test("adds two positive numbers", () => {
    expect(add(2, 3)).toBe(5);
  });

  test("handles negative numbers", () => {
    expect(add(-2, 5)).toBe(3);
  });

  test("throws on non-number input", () => {
    expect(() => add("2", 3)).toThrow(TypeError);
    expect(() => add(2, undefined)).toThrow(TypeError);
  });
});

describe("isPalindrome", () => {
  test("detects simple palindromes", () => {
    expect(isPalindrome("racecar")).toBe(true);
    expect(isPalindrome("hello")).toBe(false);
  });

  test("ignores case and spaces", () => {
    expect(isPalindrome("A man a plan a canal Panama")).toBe(true);
  });

  test("returns false for non-string input", () => {
    expect(isPalindrome(12321)).toBe(false);
  });
});
