#!/usr/bin/env bash
# Debian 12, Bash, Git e GitHub CLI 2.23. Eseguire, NON usare source o sudo.
# Tenere github-fine.sh nella stessa directory di questo file.
# Usa la configurazione gh dell'utente (rispetta GH_CONFIG_DIR, se impostata).
set +x
if [[ ${BASH_SOURCE[0]} != "$0" ]]; then
    printf 'Esegui questo file con bash, senza source.\n' >&2
    return 1
fi
set -euo pipefail
umask 077

if (( EUID == 0 )); then
    printf 'Esegui come utente del laboratorio, senza sudo.\n' >&2
    exit 1
fi
case ":$PATH:" in
    *":$HOME/.local/bin:"*) ;;
    *) export PATH="$HOME/.local/bin:$PATH" ;;
esac
for programma in gh git; do
    command -v "$programma" >/dev/null || {
        printf 'Manca %s. Esegui prima install.sh (oppure installa-gh.sh per gh).\n' "$programma" >&2
        exit 1
    }
done
gh --version >/dev/null

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
fine="$script_dir/github-fine.sh"
[[ -r "$fine" ]] || {
    printf 'Manca github-fine.sh nella directory dello script.\n' >&2
    exit 1
}

# Sempre, anche se il token precedente e' scaduto o non c'e' rete.
# Se la pulizia fallisce, set -e impedisce di proseguire al login.
bash "$fine"

printf '\nUsername GitHub dello studente (non email): '
IFS= read -r studente
[[ "$studente" =~ ^[[:alnum:]][[:alnum:]-]*$ ]] || {
    printf 'Username vuoto o non valido.\n' >&2
    exit 1
}

completato=0
pulizia_in_caso_di_errore() {
    local codice=$?
    trap - EXIT INT TERM HUP
    if (( completato == 0 )); then
        printf '\nAccesso non completato: rimuovo le credenziali locali.\n' >&2
        bash "$fine" || printf 'Pulizia fallita: riesegui github-fine.sh.\n' >&2
    fi
    exit "$codice"
}
trap pulizia_in_caso_di_errore EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
trap 'exit 129' HUP

printf 'Autorizza il TUO account nel browser, controllando il nome visualizzato.\n'
gh auth login --hostname github.com --git-protocol https --web
account=$(gh api --hostname github.com user --jq '.login')
if [[ "${account,,}" != "${studente,,}" ]]; then
    printf 'Account errato: autenticato %s, atteso %s.\n' "$account" "$studente" >&2
    printf 'Esci dal vecchio account nel browser e riprova.\n' >&2
    exit 1
fi
gh auth setup-git --hostname github.com
completato=1

printf '\nAccesso GitHub pronto per %s. Usa repository con URL HTTPS.\n' "$account"
printf 'A fine sessione esegui: bash "%s"\n' "$fine"
printf 'Nome/email dei commit si configurano separatamente nel repository.\n'
