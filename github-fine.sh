#!/usr/bin/env bash
# Debian 12, Bash, Git e GitHub CLI 2.23. Eseguire, NON usare source o sudo.
# Rimuove l'autenticazione gh per github.com e chiede ai credential helper
# Git di cancellare le credenziali HTTPS per github.com. Ripetibile/offline.
# NON revoca token su GitHub, non chiude il browser, non elimina chiavi SSH.
# Non cerca token in file arbitrari, URL remoti, cronologia o altri processi.
# Eseguire nel repository per includerne gli eventuali helper locali.
# Presuppone un solo studente attivo per home Linux (non home condivisa NFS
# tra studenti contemporanei). La pulizia non crea isolamento tra utenti.
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
for programma in gh git; do
    command -v "$programma" >/dev/null || {
        printf 'Manca %s: pulizia non eseguita.\n' "$programma" >&2
        exit 1
    }
done

esito=0
# Uno script figlio non puo' cancellare variabili nella shell che lo avvia.
# Le escludiamo qui per poter pulire comunque la configurazione su disco.
if [[ -n ${GH_TOKEN:-} || -n ${GITHUB_TOKEN:-} ]]; then
    printf 'Sono presenti token nella shell. Dopo lo script esegui:\n' >&2
    printf '  unset GH_TOKEN GITHUB_TOKEN\n' >&2
    printf 'Rimuovili anche dagli eventuali file di avvio, poi riprova.\n' >&2
    esito=1
fi
unset GH_TOKEN GITHUB_TOKEN

credenziale() {
    printf 'protocol=https\nhost=github.com\n\n'
}

# Configurazione effettiva, compresi gli helper del repository corrente.
if ! credenziale | GIT_TERMINAL_PROMPT=0 git credential reject; then
    printf 'Errore durante la pulizia dei credential helper Git.\n' >&2
    esito=1
fi
# Anche store/cache standard, se un precedente setup-git li ha mascherati.
# Non svuota cache di altri servizi e non cancella interi file credenziali.
if ! credenziale | git credential-store erase; then
    printf 'Errore durante la pulizia di Git credential-store.\n' >&2
    esito=1
fi
if ! credenziale | git credential-cache erase; then
    printf 'Errore durante la pulizia di Git credential-cache.\n' >&2
    esito=1
fi

# Controllo LOCALE: auth status fallirebbe anche per un token scaduto.
# Il token, se presente, non viene mai mostrato ne' memorizzato dallo script.
ha_autenticazione() {
    gh config get user --host github.com >/dev/null 2>&1 ||
        gh auth token --hostname github.com >/dev/null 2>&1
}
if ha_autenticazione; then
    # Su gh 2.23 non esiste --user. stdin chiuso evita richieste interattive.
    if ! gh auth logout --hostname github.com </dev/null; then
        printf 'Logout gh fallito.\n' >&2
        esito=1
    fi
fi
if ha_autenticazione; then
    printf 'Restano credenziali gh per github.com: pulizia incompleta.\n' >&2
    esito=1
fi

if (( esito == 0 )); then
    printf 'Autenticazione locale gh rimossa; pulizia Git HTTPS richiesta.\n'
    printf 'Esci anche da GitHub nel browser o chiudi tutte le finestre private.\n'
else
    printf 'Pulizia incompleta: risolvi gli errori prima di un nuovo accesso.\n' >&2
fi
exit "$esito"
