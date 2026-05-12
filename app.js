const udyamRegex = /UDYAM-[A-Z]{2}-\d{2}-\d{7}/g;
const inputArea = document.getElementById("inputArea");
const fileInput = document.getElementById("fileInput");
const startBtn = document.getElementById("startBtn");
const clearBtn = document.getElementById("clearBtn");
const dropZone = document.getElementById("dropZone");
const queueList = document.getElementById("queueList");
const tbody = document.querySelector("#resultTable tbody");
const insights = document.getElementById("insights");

const counters = {
  total: document.getElementById("totalCount"),
  processed: document.getElementById("processedCount"),
  success: document.getElementById("successCount"),
  failed: document.getElementById("failedCount")
};
const progressBar = document.getElementById("progressBar");

let state = { total: 0, processed: 0, success: 0, failed: 0, rows: [] };

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
const mask = (value) => value ? value.slice(0, 3) + "****" + value.slice(-2) : "N/A";

function updateStats() {
  counters.total.textContent = state.total;
  counters.processed.textContent = state.processed;
  counters.success.textContent = state.success;
  counters.failed.textContent = state.failed;
  const pct = state.total ? (state.processed / state.total) * 100 : 0;
  progressBar.style.width = `${pct.toFixed(1)}%`;
}

function addQueueStatus(text, cls = "") {
  const li = document.createElement("li");
  li.textContent = text;
  li.className = cls;
  queueList.prepend(li);
}

async function parseFiles(files) {
  let aggregate = "";
  for (const file of files) {
    const text = await file.text();
    aggregate += `\n${text}`;
  }
  inputArea.value = `${inputArea.value}\n${aggregate}`.trim();
}

function extractUdyamNumbers(text) {
  return [...new Set((text.match(udyamRegex) || []).map((x) => x.trim()))];
}

async function fetchUdyamData(udyamNo, attempt = 1) {
  await sleep(300 + Math.random() * 800);
  const transientFail = Math.random() < 0.15;
  if (transientFail && attempt < 3) throw new Error("Transient lookup error");

  const states = ["Gujarat/Ahmedabad", "Maharashtra/Mumbai", "Delhi/New Delhi", "Karnataka/Bengaluru"];
  const types = ["Micro", "Small", "Medium"];
  const activities = ["Manufacturing", "Services", "Trading"];
  const i = Math.floor(Math.random() * states.length);

  return {
    udyamNo,
    businessName: `Enterprise ${udyamNo.slice(-4)}`,
    ownerName: `Owner ${udyamNo.slice(-3)}`,
    enterpriseType: types[Math.floor(Math.random() * types.length)],
    registrationDate: `202${Math.floor(Math.random() * 6)}-${String(1 + Math.floor(Math.random() * 12)).padStart(2, "0")}-15`,
    udyamStatus: Math.random() < 0.9 ? "Active" : "Inactive",
    stateDistrict: states[i],
    address: `${100 + i}, Industrial Area, Sector ${i + 1}`,
    nicCodes: `10${i}2, 20${i}4`,
    businessActivities: activities[i % activities.length],
    investmentRange: ["<10L", "10L-1Cr", "1Cr-10Cr"][Math.floor(Math.random() * 3)],
    turnoverRange: ["<50L", "50L-5Cr", "5Cr-50Cr"][Math.floor(Math.random() * 3)],
    mfgServiceType: activities[i % activities.length],
    employeeCount: 5 + Math.floor(Math.random() * 250),
    gstPanMasked: `${mask("27ABCDE1234F1Z5")}/${mask("ABCDE1234F")}`
  };
}

async function geminiSummary(record) {
  const cfg = window.APP_CONFIG || {};
  if (!cfg.GEMINI_API_KEY) {
    const issues = [];
    if (record.udyamStatus !== "Active") issues.push("Inactive status");
    if (record.employeeCount < 10) issues.push("Very low employee count");
    return {
      summary: `${record.businessName} is a ${record.enterpriseType.toLowerCase()} ${record.businessActivities.toLowerCase()} business in ${record.stateDistrict}. Estimated turnover ${record.turnoverRange}.`,
      alerts: issues.length ? issues.join(", ") : "No critical anomalies"
    };
  }

  const prompt = `Summarize and risk-check this Udyam business in 2 lines JSON keys: summary,alerts. Data: ${JSON.stringify(record)}`;
  const resp = await fetch(`https://generativelanguage.googleapis.com/v1beta/models/${cfg.GEMINI_MODEL}:generateContent?key=${cfg.GEMINI_API_KEY}`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ contents: [{ parts: [{ text: prompt }] }] })
  });
  const data = await resp.json();
  const text = data?.candidates?.[0]?.content?.parts?.[0]?.text || "";
  try {
    return JSON.parse(text);
  } catch {
    return { summary: text || "AI summary unavailable", alerts: "Review manually" };
  }
}

function appendRow(r) {
  const tr = document.createElement("tr");
  tr.innerHTML = `
    <td>${r.udyamNo}</td><td>${r.businessName}</td><td>${r.ownerName}</td><td>${r.enterpriseType}</td><td>${r.registrationDate}</td>
    <td>${r.udyamStatus}</td><td>${r.stateDistrict}</td><td>${r.address}</td><td>${r.nicCodes}</td><td>${r.businessActivities}</td>
    <td>${r.investmentRange}</td><td>${r.turnoverRange}</td><td>${r.mfgServiceType}</td><td>${r.employeeCount}</td><td>${r.gstPanMasked}</td>
    <td>${r.aiSummary || ""}</td><td>${r.aiAlerts || ""}</td>
  `;
  tbody.appendChild(tr);
}

async function processOne(udyamNo) {
  for (let attempt = 1; attempt <= 3; attempt++) {
    try {
      addQueueStatus(`Processing ${udyamNo} (attempt ${attempt})`, "warn");
      const record = await fetchUdyamData(udyamNo, attempt);
      const ai = await geminiSummary(record);
      record.aiSummary = ai.summary;
      record.aiAlerts = ai.alerts;
      state.success++;
      state.rows.push(record);
      addQueueStatus(`Success: ${udyamNo}`, "ok");
      appendRow(record);
      return;
    } catch (err) {
      if (attempt === 3) {
        state.failed++;
        addQueueStatus(`Failed: ${udyamNo} (${err.message})`, "bad");
      } else {
        await sleep(400);
      }
    } finally {
      if (attempt === 3 || state.rows.some((x) => x.udyamNo === udyamNo)) {
        state.processed++;
        updateStats();
      }
    }
  }
}

async function processQueue(numbers) {
  state = { total: numbers.length, processed: 0, success: 0, failed: 0, rows: [] };
  tbody.innerHTML = "";
  queueList.innerHTML = "";
  updateStats();

  const concurrency = 4;
  let idx = 0;
  const workers = Array.from({ length: concurrency }, async () => {
    while (idx < numbers.length) {
      const current = numbers[idx++];
      await processOne(current);
    }
  });

  await Promise.all(workers);
  insights.innerHTML = `
    <b>Portfolio Insights:</b><br/>
    Active ratio: ${((state.success / state.total) * 100 || 0).toFixed(1)}%<br/>
    High-level note: ${state.failed ? "Some records require manual re-check." : "All records processed with no hard failures."}
  `;
}

startBtn.addEventListener("click", async () => {
  const numbers = extractUdyamNumbers(inputArea.value.toUpperCase());
  if (!numbers.length) {
    alert("Please provide valid Udyam numbers.");
    return;
  }
  await processQueue(numbers);
});

clearBtn.addEventListener("click", () => {
  inputArea.value = "";
  tbody.innerHTML = "";
  queueList.innerHTML = "";
  insights.textContent = "";
  state = { total: 0, processed: 0, success: 0, failed: 0, rows: [] };
  updateStats();
});

fileInput.addEventListener("change", async (e) => parseFiles(e.target.files));
["dragenter", "dragover"].forEach((evt) => dropZone.addEventListener(evt, (e) => {
  e.preventDefault();
  dropZone.classList.add("dragging");
}));
["dragleave", "drop"].forEach((evt) => dropZone.addEventListener(evt, (e) => {
  e.preventDefault();
  dropZone.classList.remove("dragging");
}));
dropZone.addEventListener("drop", async (e) => {
  const files = e.dataTransfer.files;
  if (files?.length) await parseFiles(files);
});
