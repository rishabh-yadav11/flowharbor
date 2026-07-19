const path = require("path");
const express = require("express");
const { greet, add, isPalindrome, getBuildInfo } = require("./logic");

const app = express();
app.use(express.json());
app.use(express.static(path.join(__dirname, "public")));

// Health check — useful for load balancers, uptime checks, and later
// pipeline improvements (e.g. "wait for healthy" before promoting a deploy).
app.get("/health", (req, res) => {
  res.status(200).json({ status: "ok" });
});

app.get("/api/info", (req, res) => {
  res.status(200).json(getBuildInfo(process.env));
});

app.get("/api/greet", (req, res) => {
  res.status(200).send(greet(req.query.name));
});

app.post("/add", (req, res) => {
  const { a, b } = req.body || {};
  try {
    const result = add(Number(a), Number(b));
    res.status(200).json({ result });
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
});

app.get("/palindrome/:word", (req, res) => {
  res.status(200).json({
    word: req.params.word,
    isPalindrome: isPalindrome(req.params.word),
  });
});

// Only start listening if this file is run directly (not when required by tests)
if (require.main === module) {
  const PORT = process.env.PORT || 3000;
  app.listen(PORT, () => {
    console.log(`FlowHarbor app listening on port ${PORT}`);
  });
}

module.exports = app;
