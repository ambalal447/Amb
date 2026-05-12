# UdyamBulk AI

A lightweight advanced AI-powered bulk Udyam verification and business intelligence dashboard.

## Features
- Paste multiple Udyam numbers.
- Upload CSV/XLSX/TXT files.
- Drag-and-drop input.
- Asynchronous queue processing with progress, retries, and per-item status.
- Rich data extraction fields for each Udyam record.
- Gemini AI integration for per-business summaries and anomaly alerts (with local fallback mode).

## Run locally
```bash
python3 -m http.server 8080
```
Open: `http://localhost:8080`

## Gemini setup
Edit `config.js` and set:
- `GEMINI_API_KEY`
- `GEMINI_MODEL` (default: `gemini-1.5-flash`)

If API key is empty, the app uses deterministic fallback summarization.
