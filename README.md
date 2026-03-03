<div align="center">

# DJANGO-BOILER

**One command. A production-ready Django stack.**

[![License: MIT](https://img.shields.io/badge/License-MIT-black.svg?style=flat-square)](LICENSE)
![Django](https://img.shields.io/badge/Django-5%2B-092E20?style=flat-square&logo=django)
![Tailwind CSS](https://img.shields.io/badge/Tailwind-v4-06B6D4?style=flat-square&logo=tailwindcss)
![HTMX](https://img.shields.io/badge/HTMX-2.x-3D72D7?style=flat-square)
![uv](https://img.shields.io/badge/uv-ready-DE5FE9?style=flat-square)

</div>

---

## What is this?

**django-boiler** is an interactive CLI scaffolder that sets up a complete Django project in under a minute — with Tailwind CSS v4, HTMX, and all the tooling you actually need, already wired together.

No manual config. No copy-pasting boilerplate. No Node.js.

---

## Quick Install

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/andbmarques/django-boiler/refs/heads/master/script.sh)
```

The script will walk you through a step-by-step setup — like `npm create vite@latest`, but for Django.

---

## What you get

After answering a few questions, you have a fully wired project:

```
my_project/
├── config/                  # Django project settings
│   ├── settings.py          # Env-based config via python-decouple
│   ├── urls.py
│   └── wsgi.py
├── core/                    # Your main app (name is up to you)
│   ├── templatetags/        # Custom template tags pre-wired
│   ├── views.py             # Example view with request.htmx check
│   └── urls.py
├── templates/
│   ├── base/base.html       # Base layout — CSRF injected globally for HTMX
│   └── core/
│       ├── index.html
│       └── partials/        # Ready for HTMX fragments
├── static/
│   ├── src/main.css         # Tailwind v4 source — @theme, @utility
│   └── dist/                # Compiled output (git-ignored)
├── .env                     # Secrets — never committed
├── .env.example             # Safe template to share
├── dev.sh                   # Start everything with one command
├── Makefile                 # css-build / css-watch shortcuts
└── requirements.txt
```

---

## The Setup Flow

```
  ○  Project Info
     Project name, version, description, author, site, repo

  ○  Django Settings
     App name · Database engine

  ○  Frontend Stack
     Alpine.js?

  ○  Extra Packages
     Crispy Forms · django-allauth · Celery · Debug Toolbar

  ○  Tooling
     Ruff · Pre-commit hooks · Docker · Git init
```

---

## Stack

### Core

| Package | Role |
|---|---|
| **Django 5+** | Web framework |
| **Tailwind CSS v4** | Utility-first CSS — standalone binary, no Node.js |
| **HTMX 2.x** | HTML-over-the-wire — CSRF pre-configured globally |
| **python-decouple** | Environment variable management |
| **django-htmx** | `request.htmx` middleware + helpers |

### Package Manager

django-boiler uses **[uv](https://docs.astral.sh/uv/)** by default — the fast Rust-based Python package manager. Falls back to `pip3` / `pip` / `python3 -m pip` automatically if uv is not found.

> **No Node.js required.** Tailwind CSS is installed as a Python package via [`pytailwindcss`](https://github.com/timonweb/pytailwindcss), which ships a standalone binary — zero npm, zero node_modules.

---

## Options

### Database

Choose your backend during setup:

| Option | Driver |
|---|---|
| **SQLite** | Built-in (default, zero config) |
| **PostgreSQL** | `psycopg[binary]` |
| **MySQL** | `mysqlclient` |

### Optional Add-ons

| Flag | What it adds |
|---|---|
| **Alpine.js** | Lightweight reactive JS via CDN |
| **WhiteNoise** | Static file serving for production |
| **django-crispy-forms** | Form rendering with `crispy-tailwind` |
| **django-allauth** | Full authentication system |
| **Celery + Redis** | Async task queue with `django-celery-results` |
| **django-debug-toolbar** | Query inspector for development |
| **Ruff** | Fast Python linter and formatter |
| **Pre-commit hooks** | Auto-lint on every commit |
| **Docker** | `Dockerfile` + `compose.yaml` (no Node in the image) |
| **Git init** | First commit created automatically |

---

## Development

Once scaffolded, start everything with a single command:

```bash
source .venv/bin/activate
./dev.sh
```

This starts **Django** and the **Tailwind CSS watcher** in parallel. Both stop cleanly on `Ctrl+C`.

```
./dev.sh                    # Start Django + Tailwind watcher
./dev.sh --migrate          # Run migrations first
./dev.sh --createsuperuser  # Create superuser interactively
./dev.sh --collectstatic    # Collect static files first
./dev.sh --open             # Open browser automatically
./dev.sh --port=9000        # Use a custom port
```

---

## Tailwind v4

django-boiler generates a `main.css` using the **Tailwind v4 API** — no `tailwind.config.js` needed.

```css
@import "tailwindcss";

@source "../../templates/**/*.html";

@theme {
  --color-primary-600: #0284c7;
  --color-primary-700: #0369a1;
}

@utility btn-primary {
  background-color: var(--color-primary-600);
  color: #fff;
}
```

Pre-built utilities included: `.btn-primary`, `.btn-secondary`, `.btn-danger`, `.card`, `.input`, `.badge`, and HTMX loading indicator styles.

---

## HTMX

CSRF is injected globally — every HTMX request works out of the box:

```html
<body hx-headers='{"X-CSRFToken": "{{ csrf_token }}"}'>
```

Check for HTMX requests in any view:

```python
def my_view(request):
    if request.htmx:
        return render(request, "partials/_fragment.html", context)
    return render(request, "full_page.html", context)
```

---

## Prerequisites

| Tool | Required | Notes |
|---|---|---|
| Python 3.10+ | ✅ | |
| uv | Recommended | Falls back to pip automatically |
| git | Optional | Only if "Git init" is selected |

---

## License

MIT © [Anderson Marques](https://github.com/andbmarques)