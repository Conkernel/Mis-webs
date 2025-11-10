const form = document.getElementById("form");
const results = document.getElementById("results");
const status = document.getElementById("status");

// 1. Declarar y obtener el elemento una sola vez
const urlInput = document.getElementById("url");

// 2. Establecer el valor predeterminado inmediatamente (fuera del listener)
urlInput.value = "https://elhacker.info";

form.addEventListener("submit", async (e) => {
  e.preventDefault();
  results.innerHTML = "";
  status.textContent = "Iniciando búsqueda...";

  // 3. Usar el elemento ya declarado para obtener su valor actual
  const url = urlInput.value.trim(); 
  const keyword = document.getElementById("keyword").value.trim();
  const maxPages = document.getElementById("maxPages").value || 200;

  try {
    const resp = await fetch("/search", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ url, keyword, maxPages }),
    });
    const data = await resp.json();
    if (data.error) {
      status.textContent = "Error: " + data.error;
      return;
    }

    status.textContent = `Encontrados ${data.results.length} coincidencias`;
    if (!data.results.length) {
      results.textContent = "No se encontraron ficheros con esa palabra clave.";
      return;
    }

    const ul = document.createElement("ul");
    data.results.forEach((r) => {
      const li = document.createElement("li");
      const a = document.createElement("a");
      a.href = r.url;
      a.textContent = r.name;
      a.target = "_blank";
      li.appendChild(a);
      const span = document.createElement("span");
      span.textContent = " — " + r.url;
      span.style.marginLeft = "8px";
      span.className = "small";
      li.appendChild(span);
      ul.appendChild(li);
    });
    results.appendChild(ul);
  } catch (err) {
    status.textContent = "Error: " + err.message;
  }
});