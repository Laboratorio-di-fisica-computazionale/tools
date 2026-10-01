#!/usr/bin/env bash
# Installa i tre script per l'utente corrente. Non avvia il login GitHub.
set +x
# Compatibile anche con /bin/bash -c "$(curl ...)".
if [[ -n ${BASH_SOURCE[0]:-} && ${BASH_SOURCE[0]} != "$0" ]]; then
    printf 'Esegui lo script con bash, senza source.\n' >&2
    return 1
fi
set -euo pipefail
umask 077

if (( EUID == 0 )); then
    printf 'Esegui come utente del laboratorio, senza sudo o su.\n' >&2
    exit 1
fi
for programma in bash git mktemp install mv; do
    command -v "$programma" >/dev/null || {
        printf 'Manca %s. Chiedi all’amministratore di installare i requisiti.\n' "$programma" >&2
        exit 1
    }
done
if command -v curl >/dev/null; then
    downloader=(curl --fail --silent --show-error --location --proto '=https' --proto-redir '=https'
        --connect-timeout 20 --max-time 180 --output)
elif command -v wget >/dev/null; then
    downloader=(wget --https-only --quiet --show-progress --timeout=20 --tries=1 --output-document)
else
    printf 'Mancano curl e wget. Chiedi all’amministratore di installarne uno.\n' >&2
    exit 1
fi

# Per una versione specifica: LAB_TOOLS_REF=<tag-o-SHA> bash install.sh
ref=${LAB_TOOLS_REF:-main}
if [[ ! "$ref" =~ ^[[:alnum:]][[:alnum:]_.-]*$ ]]; then
    printf 'LAB_TOOLS_REF deve essere main, un tag o uno SHA, senza slash.\n' >&2
    exit 1
fi
base_url="https://raw.githubusercontent.com/Laboratorio-di-fisica-computazionale/tools/$ref"
install_user_home="$HOME"
bin_dir="$install_user_home/.local/bin"
mkdir -p -- "$bin_dir"
# Il temporaneo e' sullo stesso filesystem per sostituire ogni file con rename.
staging=$(mktemp -d "$bin_dir/.lab-tools.XXXXXXXX")
trap 'rm -rf -- "$staging"' EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
trap 'exit 129' HUP

script=(installa-gh.sh github-inizio.sh github-fine.sh)
for nome in "${script[@]}"; do
    printf 'Scarico %s...\n' "$nome"
    "${downloader[@]}" "$staging/$nome" "$base_url/$nome"
    [[ -s "$staging/$nome" ]] || { printf 'File vuoto: %s\n' "$nome" >&2; exit 1; }
    bash -n "$staging/$nome"
done

# Installa solo dopo che tutti e tre i download sono riusciti.
for nome in "${script[@]}"; do
    install -m 0755 "$staging/$nome" "$staging/$nome.ready"
    mv -fT -- "$staging/$nome.ready" "$bin_dir/$nome"
done

bash "$bin_dir/installa-gh.sh"
printf '\nInstallazione completata in %s. Nessun login GitHub eseguito.\n' "$bin_dir"
printf 'Inizia una sessione con: ~/.local/bin/github-inizio.sh\n'
printf 'Termina una sessione con: ~/.local/bin/github-fine.sh\n'
