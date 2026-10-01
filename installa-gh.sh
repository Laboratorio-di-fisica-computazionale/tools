#!/usr/bin/env bash
# Debian 12: prepara ~/.local/bin, gh e il PATH di Bash senza sudo.
set +x
if [[ ${BASH_SOURCE[0]} != "$0" ]]; then
    printf 'Esegui lo script con bash, senza source.\n' >&2
    return 1
fi
set -euo pipefail
umask 077

if (( EUID == 0 )); then
    printf 'Esegui come utente del laboratorio, senza sudo o su.\n' >&2
    exit 1
fi

gh_user_home="$HOME"
bin_dir="$gh_user_home/.local/bin"
bashrc="$gh_user_home/.bashrc"
mkdir -p -- "$bin_dir"
case ":$PATH:" in
    *":$bin_dir:"*) ;;
    *) export PATH="$bin_dir:$PATH" ;;
esac

# 2.17.0 introduce auth token; 2.23.0 e' la soglia prudenziale gia
# provata nel laboratorio. Non e' una garanzia futura delle API GitHub.
gh_min_version='2.2.3'
gh_fallback_version='2.2.3'

gh_verifica_comando() {
    local output
    if output=$("$@" 2>&1); then
        return 0
    fi
    printf 'Verifica gh fallita:' >&2
    printf ' %q' "$@" >&2
    printf '\n%s\n' "$output" >&2
    return 1
}

gh_compatibile() {
    local binario="$1" versione_output versione
    if ! versione_output=$("$binario" --version 2>&1); then
        printf 'Impossibile eseguire %s --version:\n%s\n' "$binario" "$versione_output" >&2
        return 1
    fi
    if [[ ! "$versione_output" =~ ^gh\ version\ ([0-9]+\.[0-9]+\.[0-9]+)([[:space:]]|$) ]]; then
        printf 'Versione gh non riconosciuta (%s):\n%s\n' "$binario" "$versione_output" >&2
        return 1
    fi
    versione=${BASH_REMATCH[1]}
    if ! dpkg --compare-versions "$versione" ge "$gh_min_version"; then
        printf 'Versione gh %s troppo vecchia (%s): serve almeno %s.\n' "$versione" "$binario" "$gh_min_version" >&2
        return 1
    fi
    # --help verifica comandi e opzioni senza login o richieste di rete.
    gh_verifica_comando "$binario" auth login --hostname github.com --git-protocol https --web --help || return 1
    gh_verifica_comando "$binario" auth logout --hostname github.com --help || return 1
    gh_verifica_comando "$binario" auth token --hostname github.com --help || return 1
    gh_verifica_comando "$binario" auth setup-git --hostname github.com --help || return 1
    gh_verifica_comando "$binario" config get user --host github.com --help || return 1
    # In gh 2.23.0 l'help di api fallisce se --help non segue subito api.
    gh_verifica_comando "$binario" api --help --hostname github.com user --jq '.login' || return 1
}

command -v dpkg >/dev/null || { printf 'Manca dpkg: questo script richiede Debian.\n' >&2; exit 1; }

installa_gh() (
    set -e
    for programma in apt-get dpkg-deb mktemp install mv; do
        command -v "$programma" >/dev/null || {
            printf 'Manca %s: installazione automatica non disponibile.\n' "$programma" >&2
            exit 1
        }
    done
    gh_tmp=$(mktemp -d)
    gh_stage=''
    pulisci() {
        rm -rf -- "$gh_tmp"
        if [[ -n "$gh_stage" ]]; then rm -f -- "$gh_stage"; fi
    }
    trap pulisci EXIT
    trap 'exit 130' INT
    trap 'exit 143' TERM
    trap 'exit 129' HUP
    cd -- "$gh_tmp"
    printf 'Scarico gh dai repository Debian configurati, senza sudo...\n'
    if ! apt-get download gh; then
        printf 'Download fallito. Verifica rete e indici APT con l’amministratore.\n' >&2
        exit 1
    fi
    dpkg-deb -x gh_*.deb estratto
    candidato='estratto/usr/bin/gh'
    if ! gh_compatibile "$candidato"; then
        printf 'WARNING: il gh scaricato con APT e troppo vecchio, non eseguibile o privo dei comandi richiesti (minimo %s).\n' "$gh_min_version" >&2
        printf 'Scarico la release ufficiale gh %s come fallback, senza sudo.\n' "$gh_fallback_version" >&2
        for programma in tar sha256sum; do
            command -v "$programma" >/dev/null || {
                printf 'Manca %s: fallback non disponibile.\n' "$programma" >&2
                exit 1
            }
        done
        if command -v curl >/dev/null; then
            downloader=(curl --fail --silent --show-error --location --proto '=https' --proto-redir '=https'
                --connect-timeout 20 --max-time 180 --output)
        elif command -v wget >/dev/null; then
            downloader=(wget --https-only --quiet --show-progress --timeout=20 --tries=1 --output-document)
        else
            printf 'Mancano curl e wget: fallback non disponibile.\n' >&2
            exit 1
        fi
        case "$(dpkg --print-architecture)" in
            amd64) arch=amd64 ;;
            arm64) arch=arm64 ;;
            i386) arch=386 ;;
            armhf) arch=armv6 ;;
            *) printf 'Architettura Debian non supportata dal fallback.\n' >&2; exit 1 ;;
        esac
        nome="gh_${gh_fallback_version}_linux_${arch}"
        archivio="$nome.tar.gz"
        base_url="https://github.com/cli/cli/releases/download/v${gh_fallback_version}"
        for file in "$archivio" "gh_${gh_fallback_version}_checksums.txt"; do
            "${downloader[@]}" "$file" "$base_url/$file"
        done
        checksum=''
        while read -r hash file extra; do
            if [[ "$file" == "$archivio" && "$hash" =~ ^[[:xdigit:]]{64}$ && -z "$extra" ]]; then
                checksum="$hash"
                break
            fi
        done < "gh_${gh_fallback_version}_checksums.txt"
        if [[ -z "$checksum" ]]; then
            printf 'Checksum ufficiale assente o non valido: installazione interrotta.\n' >&2
            exit 1
        fi
        printf '%s  %s\n' "$checksum" "$archivio" | sha256sum --check --status || {
            printf 'Checksum non corrispondente: installazione interrotta.\n' >&2
            exit 1
        }
        # Estrai soltanto l'eseguibile previsto, dopo aver verificato l'archivio.
        tar -xzf "$archivio" "$nome/bin/gh"
        candidato="$nome/bin/gh"
        if ! gh_compatibile "$candidato"; then
            printf 'Anche il fallback non e compatibile con questa macchina: installazione interrotta.\n' >&2
            exit 1
        fi
    fi
    gh_stage=$(mktemp "$bin_dir/.gh-install.XXXXXXXX")
    install -m 0755 "$candidato" "$gh_stage"
    mv -fT -- "$gh_stage" "$bin_dir/gh"
    printf 'Installato: %s/gh\n' "$bin_dir"
)

if command -v gh >/dev/null && gh_compatibile "$(command -v gh)"; then
    printf 'gh gia disponibile: %s\n' "$(command -v gh)"
else
    installa_gh
    hash -r
fi
gh --version

# Riconosce le forme comuni in una riga che assegna PATH. Non esegue .bashrc
# e ignora commenti e directory con lo stesso prefisso (es. .local/bin-old).
path_presente=0
if [[ -e "$bashrc" && ! -r "$bashrc" ]]; then
    printf 'Impossibile leggere %s.\n' "$bashrc" >&2
    exit 1
fi
if [[ -f "$bashrc" ]]; then
    while IFS= read -r riga || [[ -n "$riga" ]]; do
        riga=${riga%%#*}
        if [[ "$riga" =~ (^|[[:space:];])(export[[:space:]]+)?PATH= ]]; then
            for forma in '$HOME/.local/bin' '${HOME}/.local/bin' '~/.local/bin' "$bin_dir"; do
                if [[ "$riga" == *"$forma"* ]]; then
                    coda=${riga#*"$forma"}
                    case "$coda" in
                        ''|:*|\"*|\'*|\;*|\ *|$'\t'*) path_presente=1; break ;;
                    esac
                fi
            done
        fi
        if (( path_presente )); then break; fi
    done < "$bashrc"
fi

if (( ! path_presente )); then
    cat >> "$bashrc" <<'BASHRC'

# Laboratorio di fisica computazionale: comandi installati nella home
if [ -d "$HOME/.local/bin" ]; then
    case ":$PATH:" in
        *":$HOME/.local/bin:"*) ;;
        *) export PATH="$HOME/.local/bin:$PATH" ;;
    esac
fi
BASHRC
    printf 'Configurato ~/.local/bin in %s.\n' "$bashrc"
else
    printf '%s contiene gia ~/.local/bin nel PATH.\n' "$bashrc"
fi

printf '\nPer aggiornare anche il terminale corrente, esegui:\n'
printf '  export PATH="$HOME/.local/bin:$PATH"\n'
printf 'Le nuove sessioni interattive Bash leggeranno la configurazione da .bashrc.\n'
