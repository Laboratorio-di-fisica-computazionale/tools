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
    # L'estrazione non installa dipendenze: controlla il binario prima di copiarlo.
    estratto/usr/bin/gh --version >/dev/null
    gh_stage=$(mktemp "$bin_dir/.gh-install.XXXXXXXX")
    install -m 0755 estratto/usr/bin/gh "$gh_stage"
    mv -fT -- "$gh_stage" "$bin_dir/gh"
    printf 'Installato: %s/gh\n' "$bin_dir"
)

if command -v gh >/dev/null && gh --version >/dev/null 2>&1; then
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
