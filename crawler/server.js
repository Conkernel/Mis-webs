// /var/www/crawler/server.js
const express = require("express");
const path = require("path");
const { crawl } = require("./crawler");

const app = express();
app.use(express.json());
app.use(express.static(path.join(__dirname, "public")));

app.post("/search", async (req, res) => {
  const { url, keyword, maxPages } = req.body;
  if (!url || !keyword)
    return res.status(400).json({ error: "url and keyword required" });
  try {
    const results = await crawl(
      url,
      keyword,
      Math.min(Number(maxPages) || 200, 1000),
    );
    res.json({ results });
  } catch (e) {
    res.status(500).json({ error: e.message || "internal error" });
  }
});



const PORT = process.env.PORT || 3000;

app.listen(PORT, '0.0.0.0', () => {
  console.log(`Servidor corriendo en http://0.0.0.0:${PORT}`);
});
