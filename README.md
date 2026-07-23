# netlookup

A `whois` front-end for network engineers. One command for ASN / IP / prefix
lookups, RPKI checks, IRR/RADB prefixes, BGP neighbours, PeeringDB data, and
as-set expansion. For anything it doesn't handle — RIR/RPSL objects, domains —
it just runs the normal `whois`.

> English below · [Türkçe için aşağıya bakın](#türkçe)

---

## What it does

- **ASN / IP / prefix lookup** via Team Cymru. IP and prefix lookups also show
  the RPKI state (VALID / INVALID / UNKNOWN) and the origin AS on the next line.
- **`-r` RPKI check** (RIPEstat) — ROA state and the matching ROA records. If
  you don't give an origin AS, it figures it out from the prefix.
- **`-p` IRR/RADB prefixes** — the `route`/`route6` objects registered for an AS.
- **`-n` neighbours** (RIPEstat) — upstreams and downstreams, grouped, with names.
- **`-i` PeeringDB** — type, scope, policy, ratio, suggested max-prefix, and the
  IX connections.
- **`-s` as-set members** — the ASNs and nested as-sets directly under an as-set.
- **`-x` as-set → prefix list** (bgpq4) — for building filters.
- **Multiple targets** — every command takes several ASNs/prefixes at once,
  separated by commas or spaces.
- **Name cache** — resolved AS names are kept for a day so repeated lookups
  don't hammer the name server; anything older is looked up again.
- **English / Turkish**, picked from your locale.

## Requirements

macOS ships `zsh`, `curl`, and `whois`. You also need `jq` and `bgpq4`. The
installer handles all of it (and installs Homebrew if you don't have it).

## Install

```sh
curl -fsSL https://raw.githubusercontent.com/baran-aslan1/netlookup/main/install.sh | zsh
```

Open a new terminal afterwards (or run `source ~/.zshrc`).

Prefer to do it by hand? Drop `netlookup.zsh` into `~/.config/zsh/`, add
`source ~/.config/zsh/netlookup.zsh` to your `~/.zshrc`, and
`brew install jq bgpq4`.

## Usage

```
whois 64496                       ASN
whois 192.0.2.0/24                prefix → origin AS + RPKI
whois 192.0.2.1                   IP → origin AS + RPKI
whois 64496 64497 192.0.2.0/24    multiple / mixed

whois -r 192.0.2.0/24             RPKI check (origin auto)
whois -r 192.0.2.0/24 64496       RPKI, origin given
whois -p 64496                    IRR/RADB prefixes
whois -n 64496                    upstream / downstream neighbours
whois -i 64496                    PeeringDB + IX
whois -s AS-EXAMPLE               as-set members
whois -x AS-EXAMPLE               as-set → prefix list
whois -n 64496 64497              several at once

whois example.com                 domain (normal whois)
whois -h whois.ripe.net AS64496   raw RIR/RPSL query
whois --clear-cache               clear the name cache
```

`whois --help` prints the full list. The example values are the documentation
ranges (RFC 5398 `AS64496`, RFC 5737 `192.0.2.0/24`), not real networks.

## Language

Detected from `$LANG`. To force it:

```sh
export _WH_LANG=en   # or: tr
```

## Where the data comes from

Team Cymru (ASN/IP/prefix and AS names), RIPEstat (RPKI, neighbours), PeeringDB
(profile, IX), RADB/IRR (registered prefixes, as-set members), bgpq4 (prefix
lists). Only the ASN→name map is stored locally
(`~/.cache/netlookup/asn-names.tsv`, one-day expiry) — everything else is
fetched fresh on each run.

## Uninstall

Delete the `source ~/.config/zsh/netlookup.zsh` line from `~/.zshrc`, then:

```sh
rm -rf ~/.config/zsh/netlookup.zsh ~/.cache/netlookup
```

## License

MIT — see [LICENSE](LICENSE).

---

## Türkçe

Network mühendisleri için bir `whois` ön yüzü. Tek komutla ASN / IP / prefix
sorgusu, RPKI kontrolü, IRR/RADB prefix'leri, BGP komşuları, PeeringDB verisi ve
as-set açılımı. Kendi kapsamındaki dışındaki her şeyi — RIR/RPSL objeleri,
domain'ler — normal `whois`'e bırakır.

### Ne yapar

- **ASN / IP / prefix sorgusu** (Team Cymru). IP ve prefix sorgularında bir alt
  satırda RPKI durumu (VALID / INVALID / UNKNOWN) ve origin AS de gösterilir.
- **`-r` RPKI kontrolü** (RIPEstat) — ROA durumu ve eşleşen ROA kayıtları.
  Origin AS vermezsen prefix'ten kendisi bulur.
- **`-p` IRR/RADB prefix'leri** — bir AS için kayıtlı `route`/`route6` objeleri.
- **`-n` komşular** (RIPEstat) — upstream ve downstream, gruplu, isimleriyle.
- **`-i` PeeringDB** — tip, kapsam, policy, ratio, önerilen max-prefix ve IX
  bağlantıları.
- **`-s` as-set üyeleri** — bir as-set'in altındaki ASN'ler ve alt as-set'ler.
- **`-x` as-set → prefix listesi** (bgpq4) — filtre yazmak için.
- **Çoklu hedef** — her komut virgül ya da boşlukla birden fazla ASN/prefix alır.
- **İsim cache'i** — çözülen AS adları bir gün saklanır, tekrar tekrar aynı şeyi
  sormaz; bir günden eskisini yeniden sorgular.
- **İngilizce / Türkçe**, locale'e göre seçilir.

### Gereksinimler

macOS'ta `zsh`, `curl`, `whois` hazır gelir. Ayrıca `jq` ve `bgpq4` gerekir.
Kurulum betiği hepsini (yoksa Homebrew dahil) halleder.

### Kurulum

```sh
curl -fsSL https://raw.githubusercontent.com/baran-aslan1/netlookup/main/install.sh | zsh
```

Sonrasında yeni bir terminal aç (ya da `source ~/.zshrc`).

### Kullanım

Yukarıdaki örneklerin aynısı geçerli; tam liste için `whois --help`. Örnek
değerler gerçek ağ değil, dokümantasyon aralıklarıdır (RFC 5398 / RFC 5737).

### Dil

`$LANG`'dan seçilir. Zorlamak için: `export _WH_LANG=tr` (ya da `en`).

### Kaldırma

`~/.zshrc`'den `source ~/.config/zsh/netlookup.zsh` satırını sil, sonra:

```sh
rm -rf ~/.config/zsh/netlookup.zsh ~/.cache/netlookup
```

### Lisans

MIT — [LICENSE](LICENSE).
