# Tools — Laboratorio di fisica computazionale

## Installazione

Dal terminale della macchina su cui lavorerai copia, incolla ed esegui questo comando in una shell:

```bash
lab_installer=$(if command -v curl >/dev/null; then curl -fsSL https://raw.githubusercontent.com/Laboratorio-di-fisica-computazionale/tools/main/install.sh; elif command -v wget >/dev/null; then wget -qO- https://raw.githubusercontent.com/Laboratorio-di-fisica-computazionale/tools/main/install.sh; else printf 'Serve curl oppure wget.\n' >&2; exit 1; fi) && /bin/bash -c "$lab_installer"
```

In alternativa, per scaricare l'installer direttamente con `wget`:

```bash
lab_installer=$(wget -qO- https://raw.githubusercontent.com/Laboratorio-di-fisica-computazionale/tools/main/install.sh) && /bin/bash -c "$lab_installer"
```

Questo installer:

1. Crea `~/.local/bin`, se manca.
2. Scarica `installa-gh.sh`, `github-inizio.sh` e `github-fine.sh` con `curl`, oppure con `wget` se `curl` non è disponibile. La stessa scelta vale per il download della release ufficiale di `gh`, quando necessario.
3. Verifica tutti i download e la sintassi Bash prima di installare i tre file con permessi `755`.
4. Esegue `installa-gh.sh`, che controlla se `gh` e' installato, altrimenti scarica il pacchetto Debian e ne copia l'eseguibile in `~/.local/bin/gh`.
5. Configura `~/.bashrc` per includere `~/.local/bin` nel `PATH`, se non è già presente in una comune assegnazione di `PATH`.

Dopo l'installazione aggiungi la directory `~/.local/bin` al `PATH`, ovvero l'elenco delle directory in cui Bash cerca i comando:

```bash
export PATH="$HOME/.local/bin:$PATH"
```
Oppure apri una nuova finestra del terminale.
Le nuove sessioni interattive Bash leggeranno `.bashrc`. 

## I quattro file

| File | Quando usarlo | Funzione |
| --- | --- | --- |
| `install.sh` | Prima installazione o aggiornamento degli script | Scarica i tre strumenti nella home ed esegue l'installazione di `gh`. |
| `installa-gh.sh` | Preparazione dell'ambiente | Crea `~/.local/bin`, rende disponibile `gh` e configura `.bashrc`. |
| `github-inizio.sh` | Inizio di ogni sessione | Pulisce l'accesso precedente, avvia il login HTTPS e verifica l'account. |
| `github-fine.sh` | Fine di ogni sessione | Rimuove l'autenticazione locale di `gh` e richiede la pulizia delle credenziali Git HTTPS. |


## Guida per gli studenti per ottenere le credenziali GitHub e cancellarle alla fine dell'esercitazione

### 1. Inizio della sessione

```bash
github-inizio.sh
```

Se il comando non viene ancora trovato, usa `~/.local/bin/github-inizio.sh`.

Lo script chiama **sempre** `github-fine.sh` prima del login, anche per rimuovere credenziali precedenti scadute. Se la pulizia fallisce, si ferma.

Il terminale e il browser hanno ruoli diversi: **lascia aperto il terminale per tutta la procedura** e passa da una finestra all'altra quando serve.

1. **Nel terminale**, inserisci il tuo username GitHub, non l'email né il nome dell'utente Linux. Se viene chiesto di autenticare anche Git, rispondi `Yes`.
2. **Prendi il codice dal terminale.** Prima di aprire il browser, `gh` mostra una riga simile a questa:

   ```text
   First copy your one-time code: XXXX-XXXX
   ```

   Copia o annota il codice effettivamente mostrato, poi premi Invio se richiesto per aprire il browser. `XXXX-XXXX` è solo un esempio del formato, non un codice da usare.
3. **Nel browser, accedi al tuo account GitHub.** Se non sei già autenticato, inserisci le tue credenziali. **Quando GitHub chiede il codice di autenticazione a due fattori (2FA), devi inserire anche quello:** prendilo dall'app di autenticazione configurata per il tuo account, oppure dal metodo che hai impostato, per esempio SMS. Se usi una passkey o una chiave di sicurezza, segui la relativa richiesta. Se la sessione del browser è già autenticata, questo passaggio potrebbe non comparire.
4. **Nella pagina “Device Activation” / “Authorize your device”**, inserisci il codice `XXXX-XXXX` che hai preso **dal terminale** e premi **Continue**. Controlla che “Signed in as” mostri il tuo username.
5. Conferma l'autorizzazione a **GitHub CLI**, seguendo il pulsante mostrato nella pagina.
6. **Torna al terminale** e attendi `Accesso GitHub pronto per ...`. Verifica il nome prima di iniziare a lavorare.

I due codici non sono intercambiabili:

| Codice richiesto | Dove prenderlo | Dove inserirlo |
| --- | --- | --- |
| Codice di autenticazione a due fattori (2FA), se richiesto | Dall'app di autenticazione o dal metodo configurato per il tuo account | Nella schermata di accesso a GitHub che richiede il codice di autenticazione |
| Codice di autorizzazione del dispositivo, nel formato `XXXX-XXXX` | Dal terminale in cui hai avviato `github-inizio.sh` | Nella pagina “Device Activation” / “Authorize your device” |

**Se il browser copre il terminale:** usa `Alt+Tab` oppure clicca la finestra del terminale nella barra in basso (per esempio `studente@labcalc: ~`). Cerca la riga `First copy your one-time code`, copia il codice e torna al browser. Non chiudere il terminale e non avviare una seconda procedura mentre la prima è in attesa.

**Se il codice del dispositivo è scaduto o la procedura è fallita:** torna al terminale, interrompi l'eventuale attesa con `Ctrl+C` e riesegui `github-inizio.sh`. Usa il nuovo codice mostrato; quello precedente non va riutilizzato.

**Se il browser usa l'account di un altro studente:** esci da quell'account e accedi con il tuo prima di autorizzare. Lo script verifica lo username inserito e, se non corrisponde, rifiuta l'accesso e tenta la pulizia.

**Da una VM via SSH:** apri l'indirizzo mostrato da `gh` nel browser del tuo computer o telefono e inserisci il codice del terminale remoto. Non serve un browser grafico sulla VM. L'eventuale codice 2FA resta quello del tuo account GitHub.

Esegui gli script normalmente: non usare `source` o `sudo`.


#### Alternative al codice dell'app di autenticazione

Se GitHub richiede la verifica a due fattori, devi completarla con uno dei metodi configurati sul tuo account. Non è necessario usare sempre un codice TOTP.

| Metodo | Cosa fai nel browser |
| --- | --- |
| App di autenticazione (TOTP) | Inserisci il codice temporaneo generato dall'app configurata per GitHub. |
| Passkey | Confermi con il dispositivo personale, il PIN o la biometria. La passkey soddisfa password e secondo fattore in un unico accesso. |
| Chiave di sicurezza registrata come secondo fattore | Dopo la password, colleghi o attivi la chiave seguendo la richiesta del browser. Una chiave configurata come passkey può invece consentire l'accesso senza password. |
| GitHub Mobile | Approvi la richiesta nell'app; potrebbe essere richiesto di confermare un numero mostrato nel browser. |
| SMS, se disponibile e consentito | Inserisci il codice ricevuto al numero configurato sul tuo account. |

Nella documentazione attuale GitHub richiede di configurare prima TOTP o SMS per abilitare la 2FA, poi permette di aggiungere passkey, chiavi di sicurezza e GitHub Mobile. Una passkey già registrata può evitare di digitare password e codice a ogni accesso: non elimina la protezione del secondo fattore.

Se GitHub o l'organizzazione richiedono la 2FA, la sola password non basta. **Un codice ricevuto via email per verificare un dispositivo non equivale alla 2FA.** Anche il codice `XXXX-XXXX` prodotto da `gh` serve ad autorizzare il dispositivo e non sostituisce il secondo fattore dell'account.

Per il laboratorio puoi completare l'accesso e l'autorizzazione di `gh` nel browser del tuo telefono o computer personale, usando il metodo già configurato. Non occorre creare una passkey sulla macchina condivisa. Se non usi uno smartphone, esistono anche applicazioni TOTP per computer personale; evita di conservare il segreto TOTP nell'account Linux condiviso.

Riferimenti ufficiali: [accesso con 2FA](https://docs.github.com/en/authentication/securing-your-account-with-two-factor-authentication-2fa/accessing-github-using-two-factor-authentication), [configurazione dei metodi](https://docs.github.com/en/authentication/securing-your-account-with-two-factor-authentication-2fa/configuring-two-factor-authentication), [passkey](https://docs.github.com/en/authentication/authenticating-with-a-passkey/about-passkeys) e [2FA obbligatoria](https://docs.github.com/en/authentication/securing-your-account-with-two-factor-authentication-2fa/about-mandatory-two-factor-authentication).

### 2. Il proprio repository

Accetta l'esercitazione in Classroom 50 secondo le indicazioni del docente e copia l'URL **HTTPS** del repository assegnato a te. Sostituisci i segnaposto:

```bash
git clone https://github.com/ORGANIZZAZIONE/REPOSITORY.git laboratorio-MIO_USERNAME
cd laboratorio-MIO_USERNAME
git config user.name "Nome Cognome"
git config user.email "EMAIL_ASSOCIATA_A_GITHUB"
```

Puoi usare l'indirizzo `noreply` indicato nelle impostazioni GitHub. Non usare `--global` per nome ed email su un account Linux condiviso: questi dati identificano l'autore dei commit e sono distinti dal login.

Nelle sessioni successive entra nella tua copia, evitando quella lasciata da un altro studente. Controlla `git status` e `git remote -v`. Se il remoto usa SSH, impostalo su HTTPS:

```bash
git remote set-url origin https://github.com/ORGANIZZAZIONE/REPOSITORY.git
```

### 3. Salvare e inviare il lavoro

Per esempio, dopo aver modificato `soluzione.py`:

```bash
git status
git add soluzione.py
git commit -m "Completa esercizio"
git push
```

Un commit salva il lavoro localmente. Attendi che il push termini senza errori, verifica sul sito GitHub che i file siano aggiornati e controlla l'esito della correzione secondo le indicazioni del docente.

### 4. Fine della sessione

Dopo il push, dalla directory del repository:

```bash
github-fine.sh
```

Oppure usa `~/.local/bin/github-fine.sh`. Eseguirlo nel repository include nella richiesta di pulizia anche gli eventuali credential helper locali. Puoi ripeterlo; la pulizia locale non richiede Internet.

Esci anche da GitHub e Classroom 50 nei browser del computer condiviso, oppure chiudi tutte le finestre private. Solo dopo chiudi la connessione SSH con `exit`.

**Chiudere il terminale o la connessione SSH non esegue automaticamente il logout GitHub.**

## Problemi comuni e limiti

- **Download APT fallito:** verificare la rete. Se gli indici sono assenti o obsoleti, chiedere all'amministratore di eseguire `apt update`.
- **Comando non trovato:** eseguire `export PATH="$HOME/.local/bin:$PATH"` o usare il percorso completo. La configurazione automatica riguarda Bash.
- **Token nell'ambiente:** se vengono segnalati `GH_TOKEN` o `GITHUB_TOKEN`, eseguire `unset GH_TOKEN GITHUB_TOKEN` nella shell, eliminare eventuali definizioni nei file di avvio e ripetere la pulizia. Uno script figlio non può cancellare le variabili della shell chiamante.
- **Configurazione alternativa:** se si usa `GH_CONFIG_DIR`, mantenerne lo stesso valore all'inizio e alla fine della sessione.
- **Pulizia:** il logout locale non revoca il token sul server e non chiude il browser. Lo script chiede la cancellazione ai credential helper Git attivi e ai gestori standard `store` e `cache`; non garantisce la pulizia di gestori personalizzati o configurazioni locali in altri repository.
- **Ambito:** vengono gestite le credenziali per `github.com` via HTTPS. Non vengono eliminate chiavi SSH, file del lavoro, credenziali di altri servizi o token copiati in URL, cronologia, file arbitrari e altri processi.
- **Interruzioni:** un login fallito o interrotto attiva un tentativo di pulizia, ma uno spegnimento o una terminazione forzata possono impedirlo. Lo script iniziale ripete comunque la pulizia alla sessione successiva.

Gli script presuppongono **un solo studente attivo per home Linux**. Non isolano gli utenti dell'account condiviso e non sono adatti alla stessa home di rete usata contemporaneamente da più studenti: un logout può rimuovere l'accesso dell'altro. Per separare le sessioni servono account Linux o ambienti individuali.

## Verifiche

Sintassi Bash:

```bash
bash -n install.sh
bash -n installa-gh.sh
bash -n github-inizio.sh
bash -n github-fine.sh
```

Test automatici con download e comandi GitHub simulati, senza account reali:

```bash
python3 -m unittest discover -s tests -v
```

