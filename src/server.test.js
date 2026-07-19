const request = require("supertest");
const app = require("./server");

describe("GET /health", () => {
  test("returns 200 and status ok", async () => {
    const res = await request(app).get("/health");
    expect(res.statusCode).toBe(200);
    expect(res.body).toEqual({ status: "ok" });
  });
});

describe('GET /api/greet', () => {
  test('greets with a query name', async () => {
    const res = await request(app).get('/api/greet?name=Rishabh');
    expect(res.statusCode).toBe(200);
    expect(res.body).toEqual({ message: 'Hello, Rishabh!' });
  });

  test('defaults to World with no name', async () => {
    const res = await request(app).get('/api/greet');
    expect(res.statusCode).toBe(200);
    expect(res.body).toEqual({ message: 'Hello, World!' });
  });
});

  test("defaults to World with no name", async () => {
    const res = await request(app).get("/api/greet");
    expect(res.statusCode).toBe(200);
    expect(res.text).toBe("Hello, World!");
  });
});
describe("GET /api/info", () => {
  test("returns build info with local defaults", async () => {
    const res = await request(app).get("/api/info");
    expect(res.statusCode).toBe(200);
    expect(res.body).toHaveProperty("environment");
    expect(res.body).toHaveProperty("buildNumber");
    expect(res.body).toHaveProperty("commit");
    expect(res.body).toHaveProperty("deployedAt");
  });
});

describe("POST /add", () => {
  test("adds two numbers", async () => {
    const res = await request(app).post("/add").send({ a: 4, b: 6 });
    expect(res.statusCode).toBe(200);
    expect(res.body).toEqual({ result: 10 });
  });

  test("returns 400 on invalid input", async () => {
    const res = await request(app).post("/add").send({ a: "x", b: 6 });
    expect(res.statusCode).toBe(400);
  });
});

describe("GET /palindrome/:word", () => {
  test("identifies a palindrome", async () => {
    const res = await request(app).get("/palindrome/racecar");
    expect(res.statusCode).toBe(200);
    expect(res.body).toEqual({ word: "racecar", isPalindrome: true });
  });

  test("identifies a non-palindrome", async () => {
    const res = await request(app).get("/palindrome/hello");
    expect(res.statusCode).toBe(200);
    expect(res.body).toEqual({ word: "hello", isPalindrome: false });
  });
});
