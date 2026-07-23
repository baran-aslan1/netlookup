#!/bin/zsh
# ============================================================================
#  netlookup installer — Homebrew + jq + bgpq4 + the netlookup module.
#  One-liner:
#    curl -fsSL https://raw.githubusercontent.com/baran-aslan1/netlookup/main/install.sh | zsh
#  Re-running is safe (idempotent). Homebrew's first install may ask for your
#  password — that is expected.
# ============================================================================

REPO="baran-aslan1/netlookup"
BRANCH="main"
RAW="https://raw.githubusercontent.com/${REPO}/${BRANCH}/netlookup.zsh"

# ── language (EN default, TR for Turkish locale) ──
case "${LC_ALL:-${LC_MESSAGES:-${LANG:-}}}" in (tr*|TR*) L=tr ;; (*) L=en ;; esac
say() { # say <en> <tr>
  if [[ "$L" == tr ]]; then print -r -- "$2"; else print -r -- "$1"; fi
}

print ""
say "\033[1;37m▶ Installing netlookup...\033[0m" "\033[1;37m▶ netlookup kuruluyor...\033[0m"
print ""

# ── 1) base tools (present on macOS) ──
for t in zsh curl whois awk; do
  command -v "$t" >/dev/null 2>&1 || say \
    "\033[0;31m✗ $t not found — unexpected on macOS.\033[0m" \
    "\033[0;31m✗ $t bulunamadı — macOS'ta beklenmedik.\033[0m"
done

# ── 2) Homebrew ──
if ! command -v brew >/dev/null 2>&1; then
  if   [[ -x /opt/homebrew/bin/brew ]]; then eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -x /usr/local/bin/brew   ]]; then eval "$(/usr/local/bin/brew shellenv)"
  else
    say "\033[1;37m▶ Installing Homebrew (may ask for your password)...\033[0m" \
        "\033[1;37m▶ Homebrew kuruluyor (parola isteyebilir)...\033[0m"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    [[ -x /opt/homebrew/bin/brew ]] && eval "$(/opt/homebrew/bin/brew shellenv)"
    [[ -x /usr/local/bin/brew   ]] && eval "$(/usr/local/bin/brew shellenv)"
  fi
fi
if ! command -v brew >/dev/null 2>&1; then
  say "\033[0;31m✗ Homebrew missing. Install it from https://brew.sh then re-run.\033[0m" \
      "\033[0;31m✗ Homebrew yok. https://brew.sh adresinden kurup tekrar çalıştırın.\033[0m"
  return 1 2>/dev/null || exit 1
fi

# keep brew on PATH permanently (Apple Silicon: /opt/homebrew)
BREW_PREFIX="$(brew --prefix)"
touch ~/.zshrc
grep -q 'brew shellenv' ~/.zshrc || print "eval \"\$(${BREW_PREFIX}/bin/brew shellenv)\"" >> ~/.zshrc

# ── 3) dependencies ──
for pkg in jq bgpq4; do
  if command -v "$pkg" >/dev/null 2>&1; then
    say "\033[0;32m✓ $pkg already installed\033[0m" "\033[0;32m✓ $pkg zaten kurulu\033[0m"
  else
    say "\033[1;37m▶ Installing $pkg...\033[0m" "\033[1;37m▶ $pkg kuruluyor...\033[0m"
    brew install "$pkg"
  fi
done

# ── 4) module ──
mkdir -p ~/.config/zsh
if ! curl -fsSL "$RAW" -o ~/.config/zsh/netlookup.zsh; then
  say "\033[0;31m✗ Could not download netlookup.zsh from ${RAW}\033[0m" \
      "\033[0;31m✗ netlookup.zsh indirilemedi: ${RAW}\033[0m"
  return 1 2>/dev/null || exit 1
fi

# clean any previous netlookup block / source line, then add one source line
cp ~/.zshrc ~/.zshrc.bak.$(date +%Y%m%d-%H%M%S) 2>/dev/null
awk '/whois override|netlookup —/{exit} !/netlookup\.zsh/{print}' ~/.zshrc > ~/.zshrc.new && mv ~/.zshrc.new ~/.zshrc
grep -q 'netlookup.zsh' ~/.zshrc || print 'source ~/.config/zsh/netlookup.zsh' >> ~/.zshrc
source ~/.config/zsh/netlookup.zsh 2>/dev/null

print ""
say "\033[0;32m✓ netlookup installed.\033[0m  Open a new iTerm tab (or: source ~/.zshrc), then try:" \
    "\033[0;32m✓ netlookup kuruldu.\033[0m  Yeni bir iTerm sekmesi aç (ya da: source ~/.zshrc), sonra dene:"
print "    \033[0;36mwhois 1.1.1.0/24\033[0m   \033[0;36mwhois -n 13335\033[0m   \033[0;36mwhois --help\033[0m"
print ""
