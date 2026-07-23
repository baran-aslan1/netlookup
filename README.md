# netlookup

A `whois` wrapper for network engineers. One command for ASN / IP / prefix
summaries, RPKI validation, IRR/RADB prefixes, BGP neighbours, PeeringDB
profiles, and as-set expansion — with inline RPKI badges, name resolution,
colored output, and a TTL name cache. Falls back to the system `whois` for
RIR/RPSL and domain queries.

> English below · [Türkçe için aşağıya bakın](#türkçe)

---

## Features

- **ASN / IP / prefix summary** via Team Cymru, with an inline **RPKI badge**
  on IP/prefix lookups (VALID / INVALID / UNKNOWN, with the origin shown).
- **`-r` RPKI validation** (RIPEstat) — ROA status and records; origin AS is
  auto-derived if you don't pass it.
- **`-p` IRR/RADB prefixes** — every registered `route`/`route6` object.
- **`-n` neighbours** (RIPEstat) — upstream / downstream, grouped and named.
- **`-i` PeeringDB** — type, scope, policy, ratio, suggested max-prefix, and
  IX connections.
- **`-s` as-set members** — direct member ASNs and nested as-sets (IRRd `!i`).
- **`-x` as-set → prefix list** (bgpq4) — for building filters.
- **Batch**: every command accepts multiple comma/space-separated targets.
- **Name cache** with a 1-day TTL (rate-limit friendly; auto-refreshes stale).
- **Bilingual** (English / Turkish), auto-detected from your locale.

## Requirements

- macOS with `zsh`, `curl`, `whois` (built-in)
- [`jq`](https://jqlang.github.io/jq/) — for RPKI, neighbours, PeeringDB
- [`bgpq4`](https://github.com/bgp/bgpq4) — for `-x` prefix lists

The installer sets these up for you (including Homebrew if missing).

## Install

```sh
curl -fsSL https://raw.githubusercontent.com/baran-aslan1/netlookup/main/install.sh | zsh
```

Then open a new terminal (or `source ~/.zshrc`).

Manual install: copy `netlookup.zsh` to `~/.config/zsh/`, then add
`source ~/.config/zsh/netlookup.zsh` to your `~/.zshrc`, and
`brew install jq bgpq4`.

## Usage

```
whois 64496                       ASN summary
whois 192.0.2.0/24                prefix → origin AS + RPKI
whois 192.0.2.1                   IP → origin AS + RPKI
whois 64496 64497 192.0.2.0/24    multiple / mixed

whois -r 192.0.2.0/24             RPKI validation (origin auto)
whois -r 192.0.2.0/24 64496       RPKI with explicit origin
whois -p 64496                    IRR/RADB prefixes
whois -n 64496                    upstream/downstream neighbours
whois -i 64496                    PeeringDB profile + IX
whois -s AS-EXAMPLE               as-set members
whois -x AS-EXAMPLE               as-set → prefix list
whois -n 64496 64497              bulk (comma/space)

whois example.com                 domain (system whois)
whois -h whois.ripe.net AS64496   raw RIR/RPSL query
whois --clear-cache               reset name cache
```

Run `whois --help` for the full list. Example values above use the
documentation ranges from RFC 5398 (AS64496) and RFC 5737 (192.0.2.0/24).

## Language

Auto-detected from `$LANG`. Force it with:

```sh
export _WH_LANG=en   # or: tr
```

## Data sources

Team Cymru (ASN/IP/prefix + names), RIPEstat (RPKI, neighbours), PeeringDB
(profile, IX), RADB/IRR (registered prefixes, as-set members), bgpq4 (prefix
lists). Only public ASN→name mappings are cached locally
(`~/.cache/netlookup/asn-names.tsv`, 1-day TTL); operational data is always
fetched live.

## Uninstall

Remove the `source ~/.config/zsh/netlookup.zsh` line from `~/.zshrc`, then
`rm -rf ~/.config/zsh/netlookup.zsh ~/.cache/netlookup`.

## License

MIT — see [LICENSE](LICENSE).

---

## Türkçe

Network mühendisleri için bir `whois` sarmalayıcısı. Tek komutla ASN / IP /
prefix özeti, RPKI doğrulama, IRR/RADB prefix'leri, BGP komşuları, PeeringDB
profilleri ve as-set açılımı — satır içi RPKI rozetleri, isim çözümleme, renkli
çıktı ve TTL'li isim cache'i ile. RIR/RPSL ve domain sorgularında yerleşik
`whois`'e döner.

### Özellikler

- **ASN / IP / prefix özeti** (Team Cymru); IP/prefix sorgularında satır içi
  **RPKI rozeti** (VALID / INVALID / UNKNOWN, origin gösterilir).
- **`-r` RPKI doğrulama** (RIPEstat) — ROA durumu ve kayıtları; origin AS
  verilmezse otomatik bulunur.
- **`-p` IRR/RADB prefix'leri** — kayıtlı tüm `route`/`route6` objeleri.
- **`-n` komşular** (RIPEstat) — upstream / downstream, gruplu ve isimli.
- **`-i` PeeringDB** — tip, kapsam, policy, ratio, önerilen max-prefix ve IX
  bağlantıları.
- **`-s` as-set üyeleri** — doğrudan üye ASN'ler ve alt as-set'ler (IRRd `!i`).
- **`-x` as-set → prefix listesi** (bgpq4) — filtre üretmek için.
- **Toplu**: her komut virgül/boşlukla ayrılmış çoklu hedef alır.
- **İsim cache'i**, 1 günlük TTL (rate-limit dostu; bayat olanı tazeler).
- **İki dilli** (İngilizce / Türkçe), locale'den otomatik seçilir.

### Gereksinimler

macOS'ta `zsh`, `curl`, `whois` (hazır) + `jq` ve `bgpq4`. Kurulum betiği
bunları (gerekirse Homebrew dahil) sizin için kurar.

### Kurulum

```sh
curl -fsSL https://raw.githubusercontent.com/baran-aslan1/netlookup/main/install.sh | zsh
```

Sonra yeni bir terminal açın (ya da `source ~/.zshrc`).

### Kullanım

Yukarıdaki İngilizce örneklerin aynısı geçerli; tam liste için `whois --help`.
Örnek değerler dokümantasyon aralıklarındandır (RFC 5398 / RFC 5737).

### Dil

`$LANG`'dan otomatik. Zorlamak için: `export _WH_LANG=tr` (ya da `en`).

### Kaldırma

`~/.zshrc`'den `source ~/.config/zsh/netlookup.zsh` satırını silin, ardından
`rm -rf ~/.config/zsh/netlookup.zsh ~/.cache/netlookup`.

### Lisans

MIT — [LICENSE](LICENSE).
