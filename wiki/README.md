# Lab Wiki

This directory is the source for the repository's GitHub Pages site. The
workflow at `.github/workflows/pages.yml` publishes its static files whenever a
wiki file changes on `main`.

Preview locally from the repository root:

```bash
python3 -m http.server 8000 --directory wiki
```

Then open `http://localhost:8000/`.

The public site is documentation, not runtime evidence. Keep secrets, raw logs,
packet captures, subscriber data, and generated OAI configuration out of this
directory.
