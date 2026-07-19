/**
 * A few small utility functions that represent "real" business logic.
 * Kept pure (no I/O) so they're trivial to unit test.
 */

/**
 * Returns a greeting for a given name. Falls back to "World" if no name given.
 */
function greet(name) {
  const trimmed = (name || '').trim();
  if (!trimmed) return 'Hello, World!';
  return `Hello, ${trimmed}!`;
}

/**
 * Adds two numbers. Throws if inputs aren't numbers.
 */
function add(a, b) {
  if (typeof a !== 'number' || typeof b !== 'number' || Number.isNaN(a) || Number.isNaN(b)) {
    throw new TypeError('add() requires two numbers');
  }
  return a + b;
}

/**
 * Returns true if the given string is a palindrome (ignoring case and spaces).
 */
function isPalindrome(str) {
  if (typeof str !== 'string') return false;
  const cleaned = str.toLowerCase().replace(/[^a-z0-9]/g, '');
  return cleaned === cleaned.split('').reverse().join('');
}

module.exports = { greet, add, isPalindrome };
