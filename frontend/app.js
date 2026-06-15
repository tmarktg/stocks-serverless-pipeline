// window.API_URL is set by config.js, which Terraform generates at deploy time.

async function fetchMovers() {
  try {
    const res = await fetch(window.API_URL);
    if (!res.ok) {
      const err = await res.json().catch(() => ({}));
      throw new Error(err.error || `HTTP ${res.status}`);
    }
    const data = await res.json();
    render(data.movers);
  } catch (err) {
    showError(err.message);
  }
}

function render(movers) {
  setStatus(null);

  if (!movers || movers.length === 0) {
    showError("No data available yet. Check back after market close (5 PM ET).");
    return;
  }

  const tbody = document.getElementById("movers-body");
  tbody.innerHTML = movers.map((m) => {
    const pct = parseFloat(m.pct_change);
    const cls = pct >= 0 ? "gain" : "loss";
    const sign = pct >= 0 ? "+" : "";
    const close = parseFloat(m.close_price).toLocaleString("en-US", {
      style: "currency",
      currency: "USD",
    });
    return `
      <tr class="${cls}">
        <td>${m.date}</td>
        <td class="ticker">${m.ticker}</td>
        <td class="pct">${sign}${pct.toFixed(2)}%</td>
        <td>${close}</td>
      </tr>`;
  }).join("");

  document.getElementById("movers-table").classList.remove("hidden");

  const updated = document.getElementById("updated");
  updated.textContent = `Updated ${new Date().toLocaleString()}`;
  updated.classList.remove("hidden");
}

function setStatus(msg) {
  const el = document.getElementById("status");
  if (msg === null) {
    el.classList.add("hidden");
  } else {
    el.textContent = msg;
    el.classList.remove("hidden", "error");
  }
}

function showError(msg) {
  const el = document.getElementById("status");
  el.textContent = msg;
  el.classList.remove("hidden");
  el.classList.add("error");
}

document.addEventListener("DOMContentLoaded", fetchMovers);
