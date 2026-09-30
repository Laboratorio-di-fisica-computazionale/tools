# github-lab-session

Script per gestire l'autenticazione GitHub durante le esercitazioni su macchine Linux con un account condiviso, usando HTTPS e GitHub CLI (`gh`).

Pensati per Debian 12 e `gh` 2.23.0. Ogni studente utilizza il **proprio account GitHub**, anche se accede a Linux con l'utente comune `studente`.

| Script | Funzione |
| --- | --- |
| `github-inizio.sh` | Esegue prima la pulizia, avvia il login nel browser, verifica lo username e configura Git per usare `gh`. |
| `github-fine.sh` | Rimuove l'autenticazione locale di `gh` per `github.com` e richiede la cancellazione delle credenziali Git HTTPS corrispondenti. |

## Installazione per l'amministratore

L'installazione si esegue una volta su ciascuna macchina o nell'immagine della VM usata dal laboratorio. I privilegi amministrativi servono per installare i programmi e gli script; gli studenti non ne hanno bisogno per usarli.

### 1. Installare i requisiti

Su Debian 12:

```bash
sudo apt update
sudo apt install git gh
gh --version
```

La versione `2.23.0+dfsg1-1` di Debian 12 dispone dei comandi usati dagli script.

Se l'account `studente` non ha accesso a `sudo`, queste operazioni devono essere svolte dall'amministratore: non è necessario concedere `sudo` agli studenti.

### 2. Procurarsi i due script

Scaricare `github-inizio.sh` e `github-fine.sh`, oppure clonare questo repository. Eseguire i comandi di installazione dalla directory che contiene entrambi i file.

Se i file sono sul proprio computer e si accede alla VM attraverso un server intermedio, copiarli dal computer locale con:

```bash
scp -J UTENTE@SERVER_INTERMEDIO -P 2222 \
  github-inizio.sh github-fine.sh \
  studente@127.0.0.1:~/
```

Sostituire `UTENTE@SERVER_INTERMEDIO` con il proprio accesso al server. La porta `2222` è quella della VM in questo esempio; `scp` usa `-P` maiuscola.

### 3. Installare in `/usr/local/bin`

La directory consigliata è **`/usr/local/bin`**, destinata ai comandi installati dall'amministratore locale. Con questo `PATH` è già disponibile, senza modificare `.bashrc`:

```text
/usr/local/bin:/usr/bin:/bin:/usr/local/games:/usr/games
```

Dalla directory contenente i due script, eseguire:

```bash
sudo install -o root -g root -m 0755 \
  github-inizio.sh github-fine.sh /usr/local/bin/
```

Il comando copia i file e imposta direttamente proprietario, gruppo e permessi.

Se l'amministratore opera già in una shell **root**, dalla directory contenente i due script può usare invece:

```bash
apt update
apt install git gh
install -o root -g root -m 0755 \
  github-inizio.sh github-fine.sh /usr/local/bin/
```

Per provare il login, aprire poi una normale sessione come `studente`: gli script rifiutano l'esecuzione come root. Il collaudo va fatto fuori dalle lezioni, perché la pulizia rimuove l'eventuale autenticazione precedente dell'account condiviso.

| Impostazione | Valore | Significato |
| --- | --- | --- |
| Proprietario | `root` | L'amministratore può modificare gli script. |
| Gruppo | `root` | I file non appartengono al gruppo degli studenti. |
| Permessi | `0755` (`rwxr-xr-x`) | Tutti possono leggerli ed eseguirli; solo il proprietario può modificarli. |

Anche `/usr/local/bin` deve essere gestita dall'amministratore e non scrivibile dall'account condiviso. Non usare permessi `777`. I due script devono restare nella **stessa directory**, con i nomi originali: quello iniziale cerca `github-fine.sh` accanto a sé.

Verificare:

```bash
ls -ld /usr/local/bin
ls -l /usr/local/bin/github-inizio.sh /usr/local/bin/github-fine.sh
command -v github-inizio.sh
command -v github-fine.sh
```

Gli ultimi due comandi devono indicare i file in `/usr/local/bin`. Gli script restano di proprietà di root, ma **vengono eseguiti con i permessi dello studente**, senza privilegi aggiuntivi.

## Guida per gli studenti

### 1. All'inizio di ogni sessione

Nel terminale della macchina di laboratorio o della VM:

```bash
github-inizio.sh
```

Non usare `sudo`, `source` o `. github-inizio.sh`.

Lo script esegue sempre `github-fine.sh` prima del nuovo accesso, anche quando non risultano credenziali precedenti. Se la pulizia segnala un errore, si ferma.

Quando richiesto:

1. Inserisci il tuo **username GitHub**, non l'email e non il nome dell'utente Linux.
2. Segui le istruzioni di `gh`: apri l'indirizzo indicato e inserisci il codice mostrato nel terminale.
3. Controlla che il browser stia usando il **tuo account**, quindi autorizza GitHub CLI. Se viene chiesto di autenticare anche Git, rispondi `Yes`.
4. Attendi il messaggio `Accesso GitHub pronto per ...` e verifica il nome visualizzato.

**Se lavori via SSH:** apri l'indirizzo e inserisci il codice nel browser del tuo computer o telefono. Non è necessario avere un browser grafico sulla VM. Se `gh` termina con un errore, riesegui lo script e usa il nuovo codice.

Se il browser autorizza un account diverso dallo username inserito, lo script rifiuta l'accesso e tenta la pulizia. Esci dall'account errato nel browser e riprova.

### 2. Aprire il proprio repository

Accetta l'esercitazione in Classroom 50 secondo le istruzioni del docente e copia l'URL **HTTPS** del repository assegnato a te.

La prima volta, sostituisci i segnaposto nell'esempio:

```bash
git clone https://github.com/ORGANIZZAZIONE/REPOSITORY.git laboratorio-MIO_USERNAME
cd laboratorio-MIO_USERNAME
```

Nelle sessioni successive entra nella tua copia già esistente. Non lavorare nella directory lasciata da un altro studente. Prima di riprendere puoi controllare:

```bash
git status
git remote -v
```

Se il repository è stato clonato via SSH, cambia l'indirizzo usando l'URL HTTPS corretto:

```bash
git remote set-url origin https://github.com/ORGANIZZAZIONE/REPOSITORY.git
```

### 3. Impostare il nome per i commit

Dentro ogni tuo repository, configura nome ed email:

```bash
git config user.name "Nome Cognome"
git config user.email "EMAIL_ASSOCIATA_A_GITHUB"
```

Puoi usare anche l'indirizzo `noreply` indicato nelle impostazioni email del tuo account GitHub. **Non aggiungere `--global`**: sull'account Linux condiviso cambierebbe l'impostazione comune. Nome ed email dei commit sono distinti dall'autenticazione.

### 4. Salvare e inviare il lavoro

Per esempio, dopo aver modificato `soluzione.py`:

```bash
git status
git add soluzione.py
git commit -m "Completa esercizio"
git push
```

Sostituisci il nome del file con quelli che vuoi consegnare. Un commit salva il lavoro localmente: **attendi che il push termini senza errori** e verifica sul sito GitHub che i file siano aggiornati. Controlla poi l'esito della correzione secondo le indicazioni del docente.

### 5. Alla fine di ogni sessione

Dopo aver salvato e inviato il lavoro, dalla directory del repository:

```bash
github-fine.sh
```

Eseguirlo nel repository consente di includere nella richiesta di pulizia anche gli eventuali credential helper configurati per quel repository. Puoi ripeterlo; la pulizia locale non richiede l'accesso a Internet.

Esci anche da GitHub e Classroom 50 nei browser usati sul computer condiviso, oppure chiudi tutte le finestre private della sessione. Se stai lavorando via SSH, chiudi infine la connessione con `exit`.

**La chiusura del terminale o della connessione SSH non esegue automaticamente `github-fine.sh`.**

## Ambito e limiti della pulizia

- Gli script gestiscono `github.com` via HTTPS. Non eliminano chiavi SSH, file del lavoro o credenziali di altri servizi.
- Il logout di `gh` rimuove l'autenticazione locale; **non revoca il token su GitHub** e non disconnette il browser.
- Lo script finale invia una richiesta di cancellazione ai credential helper Git attivi e ai gestori standard `store` e `cache`. Non può garantire la pulizia di ogni gestore personalizzato o di configurazioni locali presenti in altri repository.
- Non cerca token inseriti manualmente in URL remoti, cronologia, file arbitrari o altri processi. Non inserire token negli URL dei repository o negli script.
- Se sono presenti le variabili `GH_TOKEN` o `GITHUB_TOKEN`, viene segnalato un errore: uno script non può cancellarle dalla shell che lo ha avviato. Nella shell esegui `unset GH_TOKEN GITHUB_TOKEN`, elimina eventuali definizioni nei file di avvio e ripeti la pulizia.
- Se usi `GH_CONFIG_DIR`, mantieni lo stesso valore all'inizio e alla fine della sessione: gli script agiscono sulla configurazione selezionata da quella variabile.
- Il login interrotto o fallito attiva un tentativo di pulizia. Un arresto della VM o una terminazione forzata possono impedirlo: all'accesso successivo lo script iniziale ripete comunque la pulizia.

**Questi script non isolano studenti che usano lo stesso account Linux.** Sono pensati per un solo studente attivo alla volta per home. Non usarli con la stessa home di rete condivisa da studenti contemporaneamente attivi: un logout può rimuovere l'autenticazione dell'altro. Per separare davvero le sessioni servono account Linux o ambienti individuali.

## Aggiornamento degli script

L'amministratore scarica le nuove versioni, ne verifica il contenuto e ripete il comando `sudo install` dalla directory che le contiene. Pianificare l'aggiornamento fuori dalle sessioni di laboratorio e sostituire entrambi i file insieme.

## Verifiche effettuate

Verificati la sintassi Bash e i principali percorsi di esecuzione con `gh` e Git simulati: accesso iniziale, credenziali precedenti/scadute, pulizia fallita, token nell'ambiente, login parziale, account errato, logout e rifiuto dell'esecuzione come root. Il login reale va provato su una macchina del laboratorio prima della distribuzione agli studenti.
