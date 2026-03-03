#!/usr/bin/env bash

# ============================================================
#  django-boiler  —  Django 5+ · Tailwind · HTMX scaffold
# ============================================================

set -euo pipefail

# ── self-permission (supports: bash <(curl ...) or curl | sh) ─
SCRIPT_PATH="${BASH_SOURCE[0]:-}"
if [[ -n "$SCRIPT_PATH" && -f "$SCRIPT_PATH" && ! -x "$SCRIPT_PATH" ]]; then
  if chmod +x "$SCRIPT_PATH" 2>/dev/null; then
    : # chmod succeeded without sudo
  else
    echo "This script needs execute permission. Requesting sudo chmod +x..."
    sudo chmod +x "$SCRIPT_PATH"
  fi
fi

# ── colours ─────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; RESET='\033[0m'

info()    { echo -e "${CYAN}${BOLD}  ➜  $*${RESET}"; }
success() { echo -e "${GREEN}${BOLD}  ✔  $*${RESET}"; }
warn()    { echo -e "${YELLOW}${BOLD}  ⚠  $*${RESET}"; }
error()   { echo -e "${RED}${BOLD}  ✖  $*${RESET}"; exit 1; }
ask()     { echo -e "${BOLD}$*${RESET}"; }

# ── banner ───────────────────────────────────────────────────
clear
echo -e "${CYAN}${BOLD}"
cat << 'EOF'
 ██████╗ ██╗ █████╗ ███╗   ██╗ ██████╗  ██████╗
 ██╔══██╗██║██╔══██╗████╗  ██║██╔════╝ ██╔═══██╗
 ██║  ██║██║███████║██╔██╗ ██║██║  ███╗██║   ██║
 ██║  ██║██║██╔══██║██║╚██╗██║██║   ██║██║   ██║
 ██████╔╝██║██║  ██║██║ ╚████║╚██████╔╝╚██████╔╝
 ╚═════╝ ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝ ╚═════╝  ╚═════╝
      + Tailwind CSS  +  HTMX  +  Alpine.js
EOF
echo -e "${RESET}"
echo -e "${BOLD}  django-boiler  —  v1.0.0${RESET}"
echo -e "  ${CYAN}Django · Tailwind CSS · HTMX scaffold${RESET}"
echo ""
echo -e "  ${YELLOW}Press Ctrl+C at any time to cancel.${RESET}"
echo ""
echo "──────────────────────────────────────────────────────────"
echo ""

# ── helpers ──────────────────────────────────────────────────
prompt_required() {
  # prompt_required <varname> <question> [default]
  local __var="$1" question="$2" default="${3:-}"
  local value=""
  while [[ -z "$value" ]]; do
    if [[ -n "$default" ]]; then
      read -rp "$(echo -e "${BOLD}${question}${RESET} (${CYAN}${default}${RESET}): ")" value
      value="${value:-$default}"
    else
      read -rp "$(echo -e "${BOLD}${question}${RESET}: ")" value
    fi
    [[ -z "$value" ]] && warn "This field is required."
  done
  printf -v "$__var" '%s' "$value"
}

prompt_optional() {
  local __var="$1" question="$2" default="${3:-}"
  local value=""
  if [[ -n "$default" ]]; then
    read -rp "$(echo -e "${BOLD}${question}${RESET} (${CYAN}${default}${RESET}): ")" value
    value="${value:-$default}"
  else
    read -rp "$(echo -e "${BOLD}${question}${RESET} ${YELLOW}[optional]${RESET}: ")" value
  fi
  printf -v "$__var" '%s' "$value"
}

prompt_select() {
  # prompt_select <varname> <question> <opt1> <opt2> ...
  local __var="$1"; shift
  local question="$1"; shift
  local options=("$@")
  echo -e "${BOLD}${question}${RESET}"
  for i in "${!options[@]}"; do
    echo -e "  ${CYAN}$((i+1))${RESET}) ${options[$i]}"
  done
  local choice=""
  while true; do
    read -rp "$(echo -e "${BOLD}Choice${RESET} [1-${#options[@]}]: ")" choice
    if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= ${#options[@]} )); then
      printf -v "$__var" '%s' "${options[$((choice-1))]}"
      break
    fi
    warn "Please enter a number between 1 and ${#options[@]}."
  done
}

prompt_yn() {
  # prompt_yn <varname> <question> <default y|n>
  local __var="$1" question="$2" default="${3:-y}"
  local hint; [[ "$default" == "y" ]] && hint="Y/n" || hint="y/N"
  local answer=""
  read -rp "$(echo -e "${BOLD}${question}${RESET} [${hint}]: ")" answer
  answer="${answer:-$default}"
  if [[ "$answer" =~ ^[Yy] ]]; then
    printf -v "$__var" '%s' "yes"
  else
    printf -v "$__var" '%s' "no"
  fi
}

slugify() {
  echo "$1" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/_/g' | sed 's/__*/_/g' | sed 's/^_//;s/_$//'
}

# ── gather project metadata ──────────────────────────────────
echo -e "${BOLD}  ○  Project Info${RESET}"
echo ""

prompt_required PROJECT_NAME     "Project name"            "my_project"
SLUG=$(slugify "$PROJECT_NAME")
if [[ "$SLUG" != "$PROJECT_NAME" ]]; then
  warn "Name will be slugified to: ${SLUG}"
  PROJECT_NAME="$SLUG"
fi

prompt_optional PROJECT_VERSION  "Version"                  "0.1.0"
prompt_optional PROJECT_DESC     "Short description"        "A Django project"
prompt_optional AUTHOR_NAME      "Author name"
prompt_optional AUTHOR_EMAIL     "Author email"
prompt_optional PROJECT_URL      "Project URL / website"
prompt_optional PROJECT_REPO     "Repository URL"

echo ""
echo -e "${BOLD}  ○  Django Settings${RESET}"
echo ""

prompt_required DJANGO_APP_NAME  "Main Django app name"    "core"
DJANGO_APP_NAME=$(slugify "$DJANGO_APP_NAME")

prompt_select   DB_ENGINE        "Database engine" \
  "SQLite (default, no setup needed)" \
  "PostgreSQL" \
  "MySQL"

case "$DB_ENGINE" in
  "PostgreSQL")
    prompt_required DB_NAME     "  DB name"     "$PROJECT_NAME"
    prompt_required DB_USER     "  DB user"     "postgres"
    prompt_optional DB_PASSWORD "  DB password" ""
    prompt_required DB_HOST     "  DB host"     "localhost"
    prompt_required DB_PORT     "  DB port"     "5432"
    ;;
  "MySQL")
    prompt_required DB_NAME     "  DB name"     "$PROJECT_NAME"
    prompt_required DB_USER     "  DB user"     "root"
    prompt_optional DB_PASSWORD "  DB password" ""
    prompt_required DB_HOST     "  DB host"     "localhost"
    prompt_required DB_PORT     "  DB port"     "3306"
    ;;
esac

echo ""
echo -e "${BOLD}  ○  Frontend Stack${RESET}"
echo ""

prompt_yn USE_ALPINEJS  "Include Alpine.js?"     "y"
prompt_yn USE_WHITENOISE "Use WhiteNoise (static files for production)?" "y"

echo ""
echo -e "${BOLD}  ○  Extra Packages${RESET}"
echo ""

prompt_yn USE_CRISPY    "Include django-crispy-forms + crispy-tailwind?" "y"
prompt_yn USE_ALLAUTH   "Include django-allauth (authentication)?"        "n"
prompt_yn USE_CELERY    "Include Celery + Redis task queue?"               "n"
prompt_yn USE_DEBUG_TOOLBAR "Include django-debug-toolbar?"              "y"

echo ""
echo -e "${BOLD}  ○  Tooling${RESET}"
echo ""

prompt_yn USE_RUFF      "Use Ruff (fast linter/formatter)?"  "y"
prompt_yn USE_PRECOMMIT "Set up pre-commit hooks?"           "n"
prompt_yn USE_DOCKER    "Generate Dockerfile + compose?"     "n"
prompt_yn USE_GIT       "Initialise git repository?"         "y"

echo ""
echo "──────────────────────────────────────────────────────────"
echo ""
echo -e "${BOLD}  Summary${RESET}"
echo ""
echo -e "  Project    : ${CYAN}${PROJECT_NAME}${RESET}"
echo -e "  Version    : ${PROJECT_VERSION}"
echo -e "  App        : ${CYAN}${DJANGO_APP_NAME}${RESET}"
echo -e "  Database   : ${DB_ENGINE}"
echo -e "  Alpine.js  : ${USE_ALPINEJS}"
echo -e "  Crispy     : ${USE_CRISPY}"
echo -e "  Allauth    : ${USE_ALLAUTH}"
echo -e "  Celery     : ${USE_CELERY}"
echo -e "  Debug TB   : ${USE_DEBUG_TOOLBAR}"
echo -e "  WhiteNoise : ${USE_WHITENOISE}"
echo -e "  Ruff       : ${USE_RUFF}"
echo -e "  Docker     : ${USE_DOCKER}"
echo -e "  Git init   : ${USE_GIT}"
echo ""
echo "──────────────────────────────────────────────────────────"
echo ""
prompt_yn CONFIRMED "Scaffold project?" "y"
[[ "$CONFIRMED" == "no" ]] && { warn "Cancelled."; exit 0; }
echo ""

# ── prerequisites check ──────────────────────────────────────
info "Checking prerequisites..."
command -v python3 >/dev/null 2>&1 || error "python3 not found. Install Python 3.10+ first."
command -v node    >/dev/null 2>&1 && warn "Node.js detected but not required — django-boiler uses pytailwindcss (standalone binary)."
[[ "$USE_GIT" == "yes" ]] && { command -v git >/dev/null 2>&1 || error "git not found."; }

# ── detect package manager: uv preferred, pip fallback ───────
if command -v uv >/dev/null 2>&1; then
  PKG_MANAGER="uv"
  success "Package manager: uv $(uv --version 2>/dev/null | awk '{print $2}')"
elif command -v pip3 >/dev/null 2>&1; then
  PKG_MANAGER="pip"
  PIP_BIN="pip3"
  success "Package manager: pip3 (uv not found — install it for faster builds)"
elif command -v pip >/dev/null 2>&1; then
  PKG_MANAGER="pip"
  PIP_BIN="pip"
  success "Package manager: pip (uv not found — install it for faster builds)"
else
  # last resort: try python3 -m pip
  if python3 -m pip --version >/dev/null 2>&1; then
    PKG_MANAGER="pip"
    PIP_BIN="python3 -m pip"
    warn "pip not on PATH — using 'python3 -m pip' as fallback"
  else
    error "No Python package manager found (uv, pip3, pip). Install uv: https://docs.astral.sh/uv/getting-started/installation/"
  fi
fi
success "All prerequisites found."
echo ""

# ── create project directory ─────────────────────────────────
ROOT_DIR="$(pwd)/${PROJECT_NAME}"
[[ -d "$ROOT_DIR" ]] && error "Directory '${PROJECT_NAME}' already exists."
mkdir -p "$ROOT_DIR"
cd "$ROOT_DIR"
info "Created project directory: ${ROOT_DIR}"

# ── virtual environment ──────────────────────────────────────
info "Creating Python virtual environment..."
if [[ "$PKG_MANAGER" == "uv" ]]; then
  uv venv .venv --quiet
else
  python3 -m venv .venv
fi
source .venv/bin/activate
success "Virtual environment ready (.venv)"

# ── build package list ────────────────────────────────────────
PIP_PKGS=("django>=5.0" "django-htmx" "python-decouple" "pytailwindcss")

[[ "$DB_ENGINE" == "PostgreSQL" ]] && PIP_PKGS+=("psycopg[binary]")
[[ "$DB_ENGINE" == "MySQL"      ]] && PIP_PKGS+=("mysqlclient")
[[ "$USE_WHITENOISE" == "yes"   ]] && PIP_PKGS+=("whitenoise")
[[ "$USE_CRISPY"     == "yes"   ]] && PIP_PKGS+=("django-crispy-forms" "crispy-tailwind")
[[ "$USE_ALLAUTH"    == "yes"   ]] && PIP_PKGS+=("django-allauth")
[[ "$USE_CELERY"     == "yes"   ]] && PIP_PKGS+=("celery[redis]" "django-celery-results")
[[ "$USE_DEBUG_TOOLBAR" == "yes" ]] && PIP_PKGS+=("django-debug-toolbar")
[[ "$USE_RUFF"       == "yes"   ]] && PIP_PKGS+=("ruff")
[[ "$USE_PRECOMMIT"  == "yes"   ]] && PIP_PKGS+=("pre-commit")

info "Installing Python packages via ${PKG_MANAGER}..."
if [[ "$PKG_MANAGER" == "uv" ]]; then
  uv pip install "${PIP_PKGS[@]}" --quiet
else
  $PIP_BIN install --upgrade pip --quiet
  $PIP_BIN install "${PIP_PKGS[@]}" --quiet
fi
success "Python packages installed."

# ── django project + app ─────────────────────────────────────
info "Creating Django project..."
django-admin startproject config .
python manage.py startapp "$DJANGO_APP_NAME"
success "Django project created."

# ── Node / Tailwind ──────────────────────────────────────────
# ── Tailwind CSS (pytailwindcss — no Node required) ──────────
info "Setting up Tailwind CSS via pytailwindcss..."
# pytailwindcss downloads the standalone Tailwind binary on first run
tailwindcss init 2>/dev/null || true
success "Tailwind CSS ready (standalone binary, no Node.js needed)."

# ── directory structure ──────────────────────────────────────
mkdir -p \
  static/src \
  static/dist \
  templates/base \
  templates/"$DJANGO_APP_NAME" \
  "${DJANGO_APP_NAME}/templatetags"

# ── .env ─────────────────────────────────────────────────────
info "Writing .env / .env.example..."
SECRET=$(python3 -c "import secrets; print(secrets.token_urlsafe(50))")

cat > .env << EOF
# Django
SECRET_KEY=${SECRET}
DEBUG=True
ALLOWED_HOSTS=localhost,127.0.0.1

EOF

case "$DB_ENGINE" in
  "PostgreSQL")
    cat >> .env << EOF
# Database — PostgreSQL
DATABASE_URL=postgresql://${DB_USER}:${DB_PASSWORD}@${DB_HOST}:${DB_PORT}/${DB_NAME}
EOF
    ;;
  "MySQL")
    cat >> .env << EOF
# Database — MySQL
DATABASE_URL=mysql://${DB_USER}:${DB_PASSWORD}@${DB_HOST}:${DB_PORT}/${DB_NAME}
EOF
    ;;
  *)
    cat >> .env << EOF
# Database — SQLite
DATABASE_URL=sqlite:///db.sqlite3
EOF
    ;;
esac

[[ "$USE_CELERY" == "yes" ]] && cat >> .env << EOF

# Celery
CELERY_BROKER_URL=redis://localhost:6379/0
CELERY_RESULT_BACKEND=django-db
EOF

# .env.example (no secrets)
sed 's/SECRET_KEY=.*/SECRET_KEY=your-secret-key-here/' .env > .env.example

# ── Tailwind v4: config is CSS-only, no tailwind.config.js ───
info "Configuring Tailwind v4..."

# ── main CSS (Tailwind v4 syntax) ────────────────────────────
cat > static/src/main.css << EOF
/* ── Tailwind v4 ───────────────────────────────────────────── */
@import "tailwindcss";

/* Tell Tailwind where to scan for class usage */
@source "../../templates/**/*.html";
@source "../../../${DJANGO_APP_NAME}/templates/**/*.html";
@source "./main.js";

/* ── custom design tokens ──────────────────────────────────── */
@theme {
  --color-primary-50:  #f0f9ff;
  --color-primary-100: #e0f2fe;
  --color-primary-500: #0ea5e9;
  --color-primary-600: #0284c7;
  --color-primary-700: #0369a1;
  --color-primary-900: #0c4a6e;
}

/* ── base styles ───────────────────────────────────────────── */
@layer base {
  html { -webkit-font-smoothing: antialiased; }
  body { color: var(--color-gray-900, #111827); background: #fff; }
  h1   { font-size: 1.875rem; font-weight: 700; letter-spacing: -0.025em; }
  h2   { font-size: 1.5rem;   font-weight: 600; }
  h3   { font-size: 1.25rem;  font-weight: 600; }
  a    { color: var(--color-primary-600); transition: color 150ms; }
  a:hover { color: var(--color-primary-700); }
}

/* ── component utilities ───────────────────────────────────── */
@utility btn {
  display: inline-flex;
  align-items: center;
  gap: 0.5rem;
  padding: 0.5rem 1rem;
  border-radius: 0.5rem;
  font-size: 0.875rem;
  font-weight: 500;
  transition: all 150ms;
  outline-offset: 2px;
}

@utility btn-primary {
  composes: btn;
  background-color: var(--color-primary-600);
  color: #fff;
  &:hover { background-color: var(--color-primary-700); }
  &:focus-visible { outline: 2px solid var(--color-primary-500); }
}

@utility btn-secondary {
  composes: btn;
  background-color: #fff;
  color: #374151;
  border: 1px solid #d1d5db;
  &:hover { background-color: #f9fafb; }
  &:focus-visible { outline: 2px solid var(--color-primary-500); }
}

@utility btn-danger {
  composes: btn;
  background-color: #dc2626;
  color: #fff;
  &:hover { background-color: #b91c1c; }
  &:focus-visible { outline: 2px solid #ef4444; }
}

@utility card {
  background-color: #fff;
  border-radius: 0.75rem;
  border: 1px solid #e5e7eb;
  box-shadow: 0 1px 2px 0 rgb(0 0 0 / 0.05);
  padding: 1.5rem;
}

@utility input {
  display: block;
  width: 100%;
  border-radius: 0.5rem;
  border: 1px solid #d1d5db;
  box-shadow: 0 1px 2px 0 rgb(0 0 0 / 0.05);
  font-size: 0.875rem;
  &:focus { border-color: var(--color-primary-500); outline: 2px solid var(--color-primary-500); }
}

@utility badge {
  display: inline-flex;
  align-items: center;
  padding: 0.125rem 0.625rem;
  border-radius: 9999px;
  font-size: 0.75rem;
  font-weight: 500;
}

/* ── HTMX loading indicator ────────────────────────────────── */
.htmx-indicator          { opacity: 0; transition: opacity 300ms; }
.htmx-request .htmx-indicator,
.htmx-request.htmx-indicator { opacity: 1; }
EOF

# ── build scripts written to Makefile ────────────────────────
cat > Makefile << 'MKEOF'
.PHONY: css-build css-watch

css-build:
	tailwindcss -i ./static/src/main.css -o ./static/dist/main.css --minify

css-watch:
	tailwindcss -i ./static/src/main.css -o ./static/dist/main.css --watch
MKEOF

# ── pre-compute Django AppConfig class name ─────────────────
# Converts e.g. "my_app" → "MyAppConfig" (matches what django startapp generates)
APP_CONFIG_CLASS=$(python3 -c "
s='${DJANGO_APP_NAME}'
print(''.join(w.title() for w in s.split('_')) + 'Config')
")

# ── Django settings ───────────────────────────────────────────
info "Writing Django settings..."
cat > config/settings.py << PYEOF
"""
${PROJECT_NAME} — Django settings
Generated by create-django-app on $(date +%Y-%m-%d)
"""
from pathlib import Path
from decouple import config, Csv

BASE_DIR = Path(__file__).resolve().parent.parent

# ── security ─────────────────────────────────────────────────
SECRET_KEY = config('SECRET_KEY')
DEBUG       = config('DEBUG', default=False, cast=bool)
ALLOWED_HOSTS = config('ALLOWED_HOSTS', default='localhost', cast=Csv())

# ── applications ─────────────────────────────────────────────
DJANGO_APPS = [
    'django.contrib.admin',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles',
]

THIRD_PARTY_APPS = [
    'django_htmx',
PYEOF

[[ "$USE_CRISPY"  == "yes"   ]] && echo "    'crispy_forms'," >> config/settings.py
[[ "$USE_CRISPY"  == "yes"   ]] && echo "    'crispy_tailwind'," >> config/settings.py
[[ "$USE_ALLAUTH" == "yes"   ]] && echo "    'allauth'," >> config/settings.py
[[ "$USE_ALLAUTH" == "yes"   ]] && echo "    'allauth.account'," >> config/settings.py
[[ "$USE_CELERY"  == "yes"   ]] && echo "    'django_celery_results'," >> config/settings.py
[[ "$USE_DEBUG_TOOLBAR" == "yes" ]] && echo "    'debug_toolbar'," >> config/settings.py

cat >> config/settings.py << PYEOF
]

LOCAL_APPS = [
    '${DJANGO_APP_NAME}.apps.${APP_CONFIG_CLASS}',
]

INSTALLED_APPS = DJANGO_APPS + THIRD_PARTY_APPS + LOCAL_APPS

# ── middleware ────────────────────────────────────────────────
MIDDLEWARE = [
PYEOF

[[ "$USE_DEBUG_TOOLBAR" == "yes" ]] && echo "    'debug_toolbar.middleware.DebugToolbarMiddleware'," >> config/settings.py

cat >> config/settings.py << PYEOF
    'django.middleware.security.SecurityMiddleware',
PYEOF

[[ "$USE_WHITENOISE" == "yes" ]] && echo "    'whitenoise.middleware.WhiteNoiseMiddleware'," >> config/settings.py

cat >> config/settings.py << PYEOF
    'django.contrib.sessions.middleware.SessionMiddleware',
    'django.middleware.common.CommonMiddleware',
    'django.middleware.csrf.CsrfViewMiddleware',
    'django.contrib.auth.middleware.AuthenticationMiddleware',
    'django.contrib.messages.middleware.MessageMiddleware',
    'django.middleware.clickjacking.XFrameOptionsMiddleware',
    'django_htmx.middleware.HtmxMiddleware',
PYEOF

[[ "$USE_ALLAUTH" == "yes" ]] && echo "    'allauth.account.middleware.AccountMiddleware'," >> config/settings.py

cat >> config/settings.py << PYEOF
]

ROOT_URLCONF = 'config.urls'

TEMPLATES = [
    {
        'BACKEND': 'django.template.backends.django.DjangoTemplates',
        'DIRS': [BASE_DIR / 'templates'],
        'APP_DIRS': True,
        'OPTIONS': {
            'context_processors': [
                'django.template.context_processors.debug',
                'django.template.context_processors.request',
                'django.contrib.auth.context_processors.auth',
                'django.contrib.messages.context_processors.messages',
            ],
        },
    },
]

WSGI_APPLICATION = 'config.wsgi.application'

# ── database ──────────────────────────────────────────────────
PYEOF

case "$DB_ENGINE" in
  "PostgreSQL")
    cat >> config/settings.py << PYEOF
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql',
        'NAME':     config('DB_NAME',     default='${DB_NAME}'),
        'USER':     config('DB_USER',     default='${DB_USER}'),
        'PASSWORD': config('DB_PASSWORD', default=''),
        'HOST':     config('DB_HOST',     default='${DB_HOST}'),
        'PORT':     config('DB_PORT',     default='${DB_PORT}'),
    }
}
PYEOF
    ;;
  "MySQL")
    cat >> config/settings.py << PYEOF
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.mysql',
        'NAME':     config('DB_NAME',     default='${DB_NAME}'),
        'USER':     config('DB_USER',     default='${DB_USER}'),
        'PASSWORD': config('DB_PASSWORD', default=''),
        'HOST':     config('DB_HOST',     default='${DB_HOST}'),
        'PORT':     config('DB_PORT',     default='${DB_PORT}'),
    }
}
PYEOF
    ;;
  *)
    cat >> config/settings.py << PYEOF
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.sqlite3',
        'NAME': BASE_DIR / 'db.sqlite3',
    }
}
PYEOF
    ;;
esac

cat >> config/settings.py << PYEOF

# ── password validation ───────────────────────────────────────
AUTH_PASSWORD_VALIDATORS = [
    {'NAME': 'django.contrib.auth.password_validation.UserAttributeSimilarityValidator'},
    {'NAME': 'django.contrib.auth.password_validation.MinimumLengthValidator'},
    {'NAME': 'django.contrib.auth.password_validation.CommonPasswordValidator'},
    {'NAME': 'django.contrib.auth.password_validation.NumericPasswordValidator'},
]

# ── i18n ──────────────────────────────────────────────────────
LANGUAGE_CODE = 'en-us'
TIME_ZONE     = 'UTC'
USE_I18N      = True
USE_TZ        = True

# ── static & media ────────────────────────────────────────────
STATIC_URL  = '/static/'
STATIC_ROOT = BASE_DIR / 'staticfiles'
STATICFILES_DIRS = [BASE_DIR / 'static' / 'dist']

PYEOF

[[ "$USE_WHITENOISE" == "yes" ]] && cat >> config/settings.py << PYEOF
STATICFILES_STORAGE = 'whitenoise.storage.CompressedManifestStaticFilesStorage'
PYEOF

cat >> config/settings.py << PYEOF

MEDIA_URL  = '/media/'
MEDIA_ROOT = BASE_DIR / 'media'

DEFAULT_AUTO_FIELD = 'django.db.models.BigAutoField'

# ── crispy forms ──────────────────────────────────────────────
PYEOF

if [[ "$USE_CRISPY" == "yes" ]]; then
  cat >> config/settings.py << 'PYEOF'
CRISPY_ALLOWED_TEMPLATE_PACKS = "tailwind"
CRISPY_TEMPLATE_PACK = "tailwind"
PYEOF
fi

if [[ "$USE_DEBUG_TOOLBAR" == "yes" ]]; then
  cat >> config/settings.py << 'PYEOF'

# ── debug toolbar ────────────────────────────────────────────
INTERNAL_IPS = ['127.0.0.1']
PYEOF
fi

if [[ "$USE_CELERY" == "yes" ]]; then
  cat >> config/settings.py << 'PYEOF'

# ── celery ───────────────────────────────────────────────────
CELERY_BROKER_URL         = config('CELERY_BROKER_URL', default='redis://localhost:6379/0')
CELERY_RESULT_BACKEND     = config('CELERY_RESULT_BACKEND', default='django-db')
CELERY_ACCEPT_CONTENT     = ['json']
CELERY_TASK_SERIALIZER    = 'json'
CELERY_RESULT_SERIALIZER  = 'json'
CELERY_TIMEZONE           = TIME_ZONE
PYEOF
fi

if [[ "$USE_ALLAUTH" == "yes" ]]; then
  cat >> config/settings.py << 'PYEOF'

# ── allauth ──────────────────────────────────────────────────
AUTHENTICATION_BACKENDS = [
    'django.contrib.auth.backends.ModelBackend',
    'allauth.account.auth_backends.AuthenticationBackend',
]
SITE_ID = 1
LOGIN_REDIRECT_URL  = '/'
LOGOUT_REDIRECT_URL = '/'
ACCOUNT_EMAIL_VERIFICATION = 'none'
PYEOF
fi

# ── urls ─────────────────────────────────────────────────────
info "Writing URLs..."
cat > config/urls.py << PYEOF
from django.contrib import admin
from django.urls import path, include
from django.conf import settings
from django.conf.urls.static import static

urlpatterns = [
    path('admin/', admin.site.urls),
    path('', include('${DJANGO_APP_NAME}.urls')),
PYEOF

[[ "$USE_ALLAUTH" == "yes" ]] && echo "    path('accounts/', include('allauth.urls'))," >> config/urls.py

cat >> config/urls.py << PYEOF
]

if settings.DEBUG:
PYEOF

[[ "$USE_DEBUG_TOOLBAR" == "yes" ]] && cat >> config/urls.py << 'PYEOF'
    import debug_toolbar
    urlpatterns = [path('__debug__/', include(debug_toolbar.urls))] + urlpatterns
PYEOF

cat >> config/urls.py << 'PYEOF'
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
PYEOF

# ── app urls ─────────────────────────────────────────────────
cat > "${DJANGO_APP_NAME}/urls.py" << PYEOF
from django.urls import path
from . import views

app_name = '${DJANGO_APP_NAME}'

urlpatterns = [
    path('', views.index, name='index'),
    # HTMX endpoints
    path('htmx/ping/', views.htmx_ping, name='htmx_ping'),
]
PYEOF

# ── app views ─────────────────────────────────────────────────
cat > "${DJANGO_APP_NAME}/views.py" << PYEOF
from django.shortcuts import render
from django.http import HttpResponse
from django_htmx.http import trigger_client_event


def index(request):
    context = {
        'title': '${PROJECT_NAME}',
        'description': '${PROJECT_DESC}',
    }
    return render(request, '${DJANGO_APP_NAME}/index.html', context)


def htmx_ping(request):
    """Example HTMX endpoint — returns a partial."""
    if request.htmx:
        response = HttpResponse('<span class="text-green-600 font-semibold">🟢 HTMX is working!</span>')
        return trigger_client_event(response, 'ping-success', {})
    return HttpResponse(status=400)
PYEOF

# ── templatetags ─────────────────────────────────────────────
touch "${DJANGO_APP_NAME}/templatetags/__init__.py"
cat > "${DJANGO_APP_NAME}/templatetags/${DJANGO_APP_NAME}_tags.py" << 'PYEOF'
from django import template

register = template.Library()


@register.simple_tag
def active_class(request, url_name, css_class='active'):
    """Add a CSS class when the current URL matches url_name."""
    from django.urls import reverse, NoReverseMatch
    try:
        url = reverse(url_name)
        if request.path == url:
            return css_class
    except NoReverseMatch:
        pass
    return ''
PYEOF

# ── base template ─────────────────────────────────────────────
info "Writing templates..."
ALPINE_CDN=""
[[ "$USE_ALPINEJS" == "yes" ]] && ALPINE_CDN='    <script defer src="https://unpkg.com/alpinejs@3.x.x/dist/cdn.min.js"></script>'

cat > templates/base/base.html << PYEOF
<!DOCTYPE html>
<html lang="en" class="h-full">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <meta name="description" content="{% block meta_description %}${PROJECT_DESC}{% endblock %}" />
  <title>{% block title %}${PROJECT_NAME}{% endblock %}</title>

  {% load static %}
  <link rel="stylesheet" href="{% static 'main.css' %}" />

  <!-- HTMX -->
  <script src="https://unpkg.com/htmx.org@2.0.0/dist/htmx.min.js"></script>
  <script src="https://unpkg.com/htmx-ext-loading-states@2.0.0/loading-states.js"></script>
${ALPINE_CDN}

  {% block extra_head %}{% endblock %}
</head>
<body class="h-full bg-gray-50" hx-headers='{"X-CSRFToken": "{{ csrf_token }}"}'>

  <!-- Navigation -->
  <nav class="bg-white border-b border-gray-200">
    <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
      <div class="flex items-center justify-between h-16">
        <a href="/" class="flex items-center gap-2 font-bold text-gray-900 no-underline hover:text-primary-600">
          <span class="text-xl">⚡</span>
          <span>${PROJECT_NAME}</span>
        </a>
        <div class="flex items-center gap-4">
          {% block nav_items %}{% endblock %}
        </div>
      </div>
    </div>
  </nav>

  <!-- Messages -->
  {% if messages %}
  <div id="messages" class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 mt-4">
    {% for message in messages %}
    <div class="mb-2 px-4 py-3 rounded-lg text-sm font-medium
      {% if message.tags == 'error' %}bg-red-50 text-red-700 border border-red-200
      {% elif message.tags == 'success' %}bg-green-50 text-green-700 border border-green-200
      {% elif message.tags == 'warning' %}bg-yellow-50 text-yellow-700 border border-yellow-200
      {% else %}bg-blue-50 text-blue-700 border border-blue-200{% endif %}">
      {{ message }}
    </div>
    {% endfor %}
  </div>
  {% endif %}

  <!-- Main content -->
  <main id="main-content" class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
    {% block content %}{% endblock %}
  </main>

  <!-- HTMX global loading bar -->
  <div id="loading-bar"
       class="htmx-indicator fixed top-0 left-0 h-1 bg-primary-500 w-full z-50
              transition-all duration-300 opacity-0"
       hx-indicator="body">
  </div>

  {% block extra_scripts %}{% endblock %}
</body>
</html>
PYEOF

# ── app index template ────────────────────────────────────────
cat > "templates/${DJANGO_APP_NAME}/index.html" << PYEOF
{% extends "base/base.html" %}

{% block title %}{{ title }} — Home{% endblock %}

{% block content %}
<div class="text-center py-16">

  <div class="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-primary-50 text-primary-700 text-sm font-medium mb-6">
    <span>⚡</span> Django + Tailwind + HTMX
  </div>

  <h1 class="text-5xl font-bold text-gray-900 mb-4">{{ title }}</h1>
  <p class="text-xl text-gray-500 mb-10 max-w-xl mx-auto">{{ description }}</p>

  <div class="flex items-center justify-center gap-4 flex-wrap">
    <button
      hx-get="{% url '${DJANGO_APP_NAME}:htmx_ping' %}"
      hx-target="#htmx-result"
      hx-swap="innerHTML"
      class="btn-primary">
      Test HTMX
    </button>
    <a href="/admin/" class="btn-secondary">Admin →</a>
  </div>

  <div id="htmx-result" class="mt-6 h-6 text-base"></div>

</div>

<!-- Feature cards -->
<div class="grid grid-cols-1 md:grid-cols-3 gap-6 mt-12">
  <div class="card">
    <div class="text-3xl mb-3">🎨</div>
    <h3 class="text-lg font-semibold mb-1">Tailwind CSS</h3>
    <p class="text-gray-500 text-sm">Utility-first CSS with custom components pre-configured in <code class="text-xs bg-gray-100 px-1 py-0.5 rounded">static/src/main.css</code>.</p>
  </div>
  <div class="card">
    <div class="text-3xl mb-3">⚡</div>
    <h3 class="text-lg font-semibold mb-1">HTMX</h3>
    <p class="text-gray-500 text-sm">Server-side interactivity without a SPA. CSRF header injected globally via <code class="text-xs bg-gray-100 px-1 py-0.5 rounded">hx-headers</code>.</p>
  </div>
  <div class="card">
    <div class="text-3xl mb-3">🐍</div>
    <h3 class="text-lg font-semibold mb-1">Django 5+</h3>
    <p class="text-gray-500 text-sm">Settings split by environment via <code class="text-xs bg-gray-100 px-1 py-0.5 rounded">python-decouple</code>. Secrets stay in <code class="text-xs bg-gray-100 px-1 py-0.5 rounded">.env</code>.</p>
  </div>
</div>
{% endblock %}
PYEOF

# ── htmx partial template ─────────────────────────────────────
mkdir -p "templates/${DJANGO_APP_NAME}/partials"
cat > "templates/${DJANGO_APP_NAME}/partials/_empty.html" << 'PYEOF'
{# Base partial — extend for HTMX fragments #}
{% if request.htmx %}
  {% block partial_content %}{% endblock %}
{% else %}
  {# Graceful degradation for non-HTMX requests #}
  {% extends "base/base.html" %}
  {% block content %}{% block partial_content %}{% endblock %}{% endblock %}
{% endif %}
PYEOF

# ── Celery ────────────────────────────────────────────────────
if [[ "$USE_CELERY" == "yes" ]]; then
  cat > config/celery.py << PYEOF
import os
from celery import Celery

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')

app = Celery('${PROJECT_NAME}')
app.config_from_object('django.conf:settings', namespace='CELERY')
app.autodiscover_tasks()


@app.task(bind=True, ignore_result=True)
def debug_task(self):
    print(f'Request: {self.request!r}')
PYEOF

  cat >> config/__init__.py << 'PYEOF'
from .celery import app as celery_app

__all__ = ('celery_app',)
PYEOF
fi

# ── ruff config ───────────────────────────────────────────────
if [[ "$USE_RUFF" == "yes" ]]; then
  cat > ruff.toml << 'PYEOF'
line-length = 88
target-version = "py312"

[lint]
select = ["E", "F", "I", "N", "UP", "B", "C4", "DJ"]
ignore = ["E501"]

[lint.per-file-ignores]
"*/migrations/*.py" = ["E501", "F401"]
"config/settings.py" = ["F401"]
PYEOF
fi

# ── pre-commit ────────────────────────────────────────────────
if [[ "$USE_PRECOMMIT" == "yes" ]]; then
  cat > .pre-commit-config.yaml << 'PYEOF'
repos:
  - repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v4.5.0
    hooks:
      - id: trailing-whitespace
      - id: end-of-file-fixer
      - id: check-yaml
      - id: check-merge-conflict
      - id: debug-statements
  - repo: https://github.com/astral-sh/ruff-pre-commit
    rev: v0.3.0
    hooks:
      - id: ruff
        args: [--fix]
      - id: ruff-format
PYEOF
  pre-commit install --quiet 2>/dev/null || true
fi

# ── Dockerfile ────────────────────────────────────────────────
if [[ "$USE_DOCKER" == "yes" ]]; then
  cat > Dockerfile << PYEOF
FROM python:3.12-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .
# pytailwindcss is installed via pip — no Node.js needed
RUN tailwindcss -i ./static/src/main.css -o ./static/dist/main.css --minify
RUN python manage.py collectstatic --noinput

EXPOSE 8000
CMD ["gunicorn", "config.wsgi:application", "--bind", "0.0.0.0:8000"]
PYEOF

  cat > compose.yaml << PYEOF
services:
  web:
    build: .
    ports: ["8000:8000"]
    env_file: .env
    volumes:
      - .:/app
      - static_volume:/app/staticfiles
    depends_on:
      - db

PYEOF

  case "$DB_ENGINE" in
    "PostgreSQL")
      cat >> compose.yaml << PYEOF
  db:
    image: postgres:16-alpine
    environment:
      POSTGRES_DB: ${DB_NAME}
      POSTGRES_USER: ${DB_USER}
      POSTGRES_PASSWORD: \${DB_PASSWORD:-postgres}
    volumes:
      - pg_data:/var/lib/postgresql/data
    ports: ["5432:5432"]

volumes:
  pg_data:
  static_volume:
PYEOF
      ;;
    "MySQL")
      cat >> compose.yaml << PYEOF
  db:
    image: mysql:8-debian
    environment:
      MYSQL_DATABASE: ${DB_NAME}
      MYSQL_USER: ${DB_USER}
      MYSQL_PASSWORD: \${DB_PASSWORD:-mysql}
      MYSQL_ROOT_PASSWORD: root
    volumes:
      - mysql_data:/var/lib/mysql
    ports: ["3306:3306"]

volumes:
  mysql_data:
  static_volume:
PYEOF
      ;;
    *)
      cat >> compose.yaml << PYEOF
volumes:
  static_volume:
PYEOF
      ;;
  esac

  [[ "$USE_CELERY" == "yes" ]] && cat >> compose.yaml << 'PYEOF'

  redis:
    image: redis:7-alpine
    ports: ["6379:6379"]

  worker:
    build: .
    command: celery -A config worker -l info
    env_file: .env
    depends_on:
      - redis
PYEOF
fi

# ── requirements.txt ─────────────────────────────────────────
info "Generating requirements.txt..."
if [[ "$PKG_MANAGER" == "uv" ]]; then
  uv pip freeze > requirements.txt
else
  $PIP_BIN freeze > requirements.txt
fi

# ── .gitignore ───────────────────────────────────────────────
cat > .gitignore << 'PYEOF'
# Python
__pycache__/
*.py[cod]
*.pyo
*.egg-info/
dist/
build/
.eggs/
.mypy_cache/
.ruff_cache/
.pytest_cache/

# Virtual environment
.venv/
venv/
env/

# Django
*.log
local_settings.py
db.sqlite3
db.sqlite3-journal
media/
staticfiles/

# Tailwind standalone binary (downloaded by pytailwindcss)
.pytailwindcss/
static/dist/

# Env
.env
!.env.example

# Editor
.vscode/
.idea/
*.swp
*.swo
.DS_Store
Thumbs.db
PYEOF

# ── dev script ───────────────────────────────────────────────
info "Writing dev.sh..."
cat > dev.sh << 'DEVEOF'
#!/usr/bin/env bash
# ============================================================
#  dev.sh  —  django-boiler development server
#  Django + Tailwind CSS + HTMX
# ============================================================
set -euo pipefail

RESET='\033[0m'; CYAN='\033[0;36m'; GREEN='\033[0;32m'
YELLOW='\033[1;33m'; RED='\033[0;31m'; BOLD='\033[1m'

info()    { echo -e "${CYAN}${BOLD}  ➜  $*${RESET}"; }
success() { echo -e "${GREEN}${BOLD}  ✔  $*${RESET}"; }
warn()    { echo -e "${YELLOW}${BOLD}  ⚠  $*${RESET}"; }
error()   { echo -e "${RED}${BOLD}  ✖  $*${RESET}"; exit 1; }

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT"

# ── banner ───────────────────────────────────────────────────
echo -e "${CYAN}${BOLD}"
echo "  ⚡  django-boiler — Dev Server"
echo -e "${RESET}"

# ── activate venv ────────────────────────────────────────────
if [[ -f ".venv/bin/activate" ]]; then
  source .venv/bin/activate
  info "Virtual environment: .venv"
elif [[ -f "venv/bin/activate" ]]; then
  source venv/bin/activate
  info "Virtual environment: venv"
else
  warn "No virtual environment found — using system Python."
fi

# ── parse flags ──────────────────────────────────────────────
MIGRATE=false
COLLECTSTATIC=false
SUPERUSER=false
PORT=8000
OPEN_BROWSER=false

for arg in "$@"; do
  case $arg in
    --migrate)         MIGRATE=true ;;
    --collectstatic)   COLLECTSTATIC=true ;;
    --createsuperuser) SUPERUSER=true ;;
    --open)            OPEN_BROWSER=true ;;
    --port=*)          PORT="${arg#*=}" ;;
    --help|-h)
      echo ""
      echo -e "${BOLD}Usage:${RESET} ./dev.sh [options]"
      echo ""
      echo "Options:"
      echo "  --migrate            Run django migrations before starting"
      echo "  --collectstatic      Run collectstatic before starting"
      echo "  --createsuperuser    Create a superuser interactively"
      echo "  --open               Open browser after starting"
      echo "  --port=<PORT>        Django port (default: 8000)"
      echo "  --help               Show this help"
      echo ""
      exit 0 ;;
    *)
      warn "Unknown option: $arg  (use --help for usage)"
      ;;
  esac
done

# ── pre-flight checks ────────────────────────────────────────
[[ ! -f "manage.py" ]] && error "manage.py not found. Run from the project root."
command -v tailwindcss >/dev/null 2>&1 || error "tailwindcss not found. Is .venv active? Run: source .venv/bin/activate"

if [[ ! -f ".env" ]]; then
  warn ".env not found — copying from .env.example..."
  cp .env.example .env 2>/dev/null || warn "No .env.example either — create .env manually before running again."
fi

# ── optional pre-steps ───────────────────────────────────────
$MIGRATE && {
  info "Running migrations..."
  python manage.py migrate
  success "Migrations done."
}

$SUPERUSER && {
  info "Creating superuser..."
  python manage.py createsuperuser
}

$COLLECTSTATIC && {
  info "Collecting static files..."
  python manage.py collectstatic --noinput
  success "Static files collected."
}

# ── clean up on exit ─────────────────────────────────────────
DJANGO_PID=""
TAILWIND_PID=""

cleanup() {
  echo ""
  info "Shutting down..."
  [[ -n "$DJANGO_PID"   ]] && kill "$DJANGO_PID"   2>/dev/null || true
  [[ -n "$TAILWIND_PID" ]] && kill "$TAILWIND_PID" 2>/dev/null || true
  wait 2>/dev/null || true
  success "Stopped cleanly. Goodbye!"
}
trap cleanup INT TERM EXIT

# ── start Tailwind CSS watcher ───────────────────────────────
info "Starting Tailwind CSS watcher..."
tailwindcss -i ./static/src/main.css -o ./static/dist/main.css --watch 2>&1 | sed 's/^/  [tw] /' &
TAILWIND_PID=$!

# Give Tailwind time to compile once before Django starts
sleep 1

# Verify CSS was built
if [[ ! -f "static/dist/main.css" ]]; then
  warn "CSS not built yet — forcing initial build..."
  tailwindcss -i ./static/src/main.css -o ./static/dist/main.css --minify
fi

# ── open browser ─────────────────────────────────────────────
if $OPEN_BROWSER; then
  (sleep 2 && {
    if command -v xdg-open &>/dev/null; then
      xdg-open "http://127.0.0.1:${PORT}/"
    elif command -v open &>/dev/null; then
      open "http://127.0.0.1:${PORT}/"
    fi
  }) &
fi

# ── start Django ─────────────────────────────────────────────
info "Starting Django development server..."
echo ""
echo -e "${GREEN}${BOLD}"
echo "  ┌─────────────────────────────────────────────┐"
echo "  │                                             │"
echo -e "  │   🌐  http://127.0.0.1:${PORT}/                 │"
echo "  │   ⚡  Tailwind CSS watching…               │"
echo "  │                                             │"
echo "  │   Press Ctrl+C to stop                     │"
echo "  │                                             │"
echo "  └─────────────────────────────────────────────┘"
echo -e "${RESET}"

python manage.py runserver "0.0.0.0:${PORT}" &
DJANGO_PID=$!

wait "$DJANGO_PID"
DEVEOF

# make dev.sh executable — try without sudo first, fall back gracefully
if chmod +x dev.sh 2>/dev/null; then
  : # success
else
  sudo chmod +x dev.sh 2>/dev/null || warn "Could not set dev.sh as executable. Run: chmod +x dev.sh"
fi

# ── README ───────────────────────────────────────────────────
cat > README.md << PYEOF
# ${PROJECT_NAME}

${PROJECT_DESC}

| Field       | Value |
|-------------|-------|
| Version     | ${PROJECT_VERSION} |
| Author      | ${AUTHOR_NAME} ${AUTHOR_EMAIL:+<${AUTHOR_EMAIL}>} |
| Site        | ${PROJECT_URL} |
| Repository  | ${PROJECT_REPO} |

## Stack

- **Django 5+** — web framework
- **Tailwind CSS** — utility-first CSS (via pytailwindcss — no Node.js required)
- **HTMX** — HTML-over-the-wire interactivity
$([ "$USE_ALPINEJS" == "yes" ] && echo "- **Alpine.js** — lightweight reactive JS")
$([ "$USE_CRISPY" == "yes" ] && echo "- **django-crispy-forms** — styled forms")
$([ "$USE_ALLAUTH" == "yes" ] && echo "- **django-allauth** — authentication")
$([ "$USE_CELERY"  == "yes" ] && echo "- **Celery + Redis** — task queue")

## Quick start

\`\`\`bash
# 1. Copy and fill in your environment variables
cp .env.example .env

# 2. Activate virtual environment
source .venv/bin/activate

# 3. Run migrations
python manage.py migrate

# 4. Create a superuser
python manage.py createsuperuser

# 5. Start the dev servers (Django + Tailwind CSS watcher)
./dev.sh
\`\`\`

> **Tip:** This project was scaffolded with [uv](https://docs.astral.sh/uv/) if it was available, otherwise pip.
> To add packages: \`uv pip install <pkg>\` or \`pip install <pkg>\`, then re-run \`pip freeze > requirements.txt\`.

Open **http://127.0.0.1:8000/**

### Dev flags

\`\`\`
./dev.sh --migrate          # run migrations before starting
./dev.sh --collectstatic    # collectstatic before starting
./dev.sh --createsuperuser  # create superuser interactively
./dev.sh --open             # open browser automatically
./dev.sh --port=9000        # custom port
\`\`\`

## Project structure

\`\`\`
${PROJECT_NAME}/
├── config/                 # Django project config
│   ├── settings.py
│   ├── urls.py
│   └── wsgi.py
├── ${DJANGO_APP_NAME}/     # Main app
│   ├── templatetags/       # Custom template tags
│   ├── views.py
│   └── urls.py
├── templates/
│   ├── base/base.html      # Base layout
│   └── ${DJANGO_APP_NAME}/ # App templates
├── static/
│   ├── src/main.css        # Tailwind source
│   └── dist/               # Compiled output (git-ignored)
├── .env                    # Environment variables (git-ignored)
├── .env.example            # Template for .env
├── dev.sh                  # Development server script
├── Makefile                # css-build / css-watch shortcuts
└── requirements.txt
\`\`\`

## HTMX usage

CSRF is automatically injected for all HTMX requests via \`hx-headers\` on \`<body>\`.
The \`django-htmx\` middleware adds \`request.htmx\` to every view.

\`\`\`python
def my_view(request):
    if request.htmx:
        return render(request, 'partials/_fragment.html', context)
    return render(request, 'full_page.html', context)
\`\`\`

## Tailwind components

Pre-built classes in \`static/src/main.css\`:

| Class            | Description            |
|------------------|------------------------|
| \`.btn-primary\`   | Primary action button  |
| \`.btn-secondary\` | Secondary button       |
| \`.btn-danger\`    | Destructive action     |
| \`.card\`          | White content card     |
| \`.input\`         | Styled form input      |
| \`.badge\`         | Pill badge             |
PYEOF

# ── git init ─────────────────────────────────────────────────
if [[ "$USE_GIT" == "yes" ]]; then
  info "Initialising git repository..."
  git init --quiet
  git add -A
  git commit --quiet -m "chore: initial scaffold by create-django-app"
  success "Git repository initialised."
fi

# ── initial migrations ────────────────────────────────────────
info "Running initial migrations..."
python manage.py migrate --run-syncdb --verbosity=0
success "Database ready."

# ── build initial CSS ─────────────────────────────────────────
info "Building initial Tailwind CSS..."
tailwindcss -i ./static/src/main.css -o ./static/dist/main.css --minify
success "CSS built → static/dist/main.css"

# ── done ─────────────────────────────────────────────────────
echo ""
echo -e "${GREEN}${BOLD}"
echo "  ╔══════════════════════════════════════════════╗"
echo "  ║   ✔  Project '${PROJECT_NAME}' is ready!   ║"
echo "  ╚══════════════════════════════════════════════╝"
echo -e "${RESET}"
echo -e "  ${CYAN}Next steps:${RESET}"
echo ""
echo -e "  ${BOLD}cd ${PROJECT_NAME}${RESET}"
echo -e "  ${BOLD}source .venv/bin/activate${RESET}"
echo -e "  ${BOLD}python manage.py createsuperuser${RESET}"
echo -e "  ${BOLD}./dev.sh${RESET}"
echo ""
echo -e "  Open → ${CYAN}http://127.0.0.1:8000/${RESET}"
echo ""