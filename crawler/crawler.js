const axios = require("axios");
const cheerio = require("cheerio");
const { URL } = require("url");
const path = require("path");

function isSameOrigin(a, b) {
  try {
    return new URL(a).origin === new URL(b).origin;
  } catch (e) {
    return false;
  }
}

function isFileLink(href) {
  try {
    const u = new URL(href);
    const basename = path.basename(u.pathname);
    // consider it a file if pathname contains a dot and it is not an html page
    return (
      basename &&
      basename.includes(".") &&
      !basename.endsWith(".html") &&
      !basename.endsWith(".htm")
    );
  } catch (e) {
    return false;
  }
}

async function crawl(startUrl, keyword, maxPages = 200) {
  const results = [];
  const visited = new Set();
  const queue = [startUrl];
  visited.add(startUrl);

  while (queue.length && visited.size <= maxPages) {
    const current = queue.shift();
    try {
      const res = await axios.get(current, {
        timeout: 10000,
        headers: { "User-Agent": "Node.js crawler" },
      });
      const contentType = (res.headers["content-type"] || "").toLowerCase();
      if (!contentType.includes("text/html")) continue;

      const $ = cheerio.load(res.data);
      $("a[href]").each((i, el) => {
        let href = $(el).attr("href");
        if (!href) return;
        href = href.trim();
        try {
          const absolute = new URL(href, current).toString();

          if (isFileLink(absolute)) {
            const name = decodeURIComponent(
              path.basename(new URL(absolute).pathname),
            );
            if (name.toLowerCase().includes(keyword.toLowerCase())) {
              results.push({ name, url: absolute });
            }
          } else {
            if (isSameOrigin(startUrl, absolute)) {
              const normalized = absolute.split("#")[0];
              if (!visited.has(normalized)) {
                visited.add(normalized);
                queue.push(normalized);
              }
            }
          }
        } catch (e) {
          // ignore malformed URLs
        }
      });
    } catch (e) {
      // ignore fetch errors and continue
    }
  }

  // deduplicate
  const seen = new Set();
  return results.filter((r) => {
    if (seen.has(r.url)) return false;
    seen.add(r.url);
    return true;
  });
}

module.exports = { crawl };
