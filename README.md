# Tools — Laboratorio di fisica computazionale

Strumenti per usare GitHub sui PC e sulle VM del laboratorio, anche senza privilegi amministrativi. Pensati per **Debian 12, Bash e GitHub CLI (`gh`)**, con repository HTTPS.

Ogni studente usa il proprio account GitHub. Il login autorizza un **token di accesso**, non un certificato o una chiave SSH.

## Installazione rapida senza sudo

Dal terminale della macchina su cui lavorerai, come normale utente Linux:

```bash
lab_installer=$(curl -fsSL https://raw.githubusercontent.com/Laboratorio-di-fisica-computazionale/tools/main/install.sh) && /bin/bash -c "$lab_installer"
```

Il download deve riuscire prima dell'esecuzione. Non usare `sudo` o `su`: i file devono essere installati nella home dell'utente del laboratorio. Puoi leggere prima [install.sh](install.sh).

L'installer:

1. Crea `~/.local/bin`, se manca.
2. Scarica `installa-gh.sh`, `github-inizio.sh` e `github-fine.sh` con `curl`.
3. Verifica tutti i download e la sintassi Bash prima di installare i tre file con permessi `755`.
4. Esegue `installa-gh.sh`, che riusa un `gh` funzionante oppure scarica il pacchetto Debian e ne copia l'eseguibile in `~/.local/bin/gh`.
5. Configura `~/.bashrc` per includere `~/.local/bin` nel `PATH`, se non è già presente in una comune assegnazione di `PATH`.

**L'installazione non esegue il login e non cambia le credenziali GitHub.**

Dopo l'installazione, aggiorna anche il terminale corrente:

```bash
export PATH="$HOME/.local/bin:$PATH"
```

Le nuove sessioni interattive Bash leggeranno `.bashrc`. Uno script eseguito come processo separato non può modificare il `PATH` della shell che lo ha avviato. Puoi comunque usare subito i percorsi completi `~/.local/bin/github-inizio.sh` e `~/.local/bin/github-fine.sh`.

### Requisiti

- Bash, Git e `curl`.
- Per scaricare `gh` se manca: `apt-get`, `dpkg-deb` e i normali strumenti Debian (`mktemp`, `install`, `mv`, ecc.).
- Repository APT configurati, indici utilizzabili e accesso alla rete per download e login.

`apt-get download` scarica il pacchetto senza installarlo nel sistema; `dpkg-deb -x` lo estrae temporaneamente. Non vengono eseguiti `apt update`, installazione di dipendenze o modifiche al database dei pacchetti. Il binario viene provato prima di copiarlo. Su Debian 12 `gh` 2.23.0 dispone dei comandi necessari.

Un `gh` già funzionante viene riutilizzato, senza aggiornarlo automaticamente.

## I quattro file

| File | Quando usarlo | Funzione |
| --- | --- | --- |
| `install.sh` | Prima installazione o aggiornamento degli script | Scarica i tre strumenti nella home ed esegue l'installazione di `gh`. |
| `installa-gh.sh` | Preparazione dell'ambiente | Crea `~/.local/bin`, rende disponibile `gh` e configura `.bashrc`. |
| `github-inizio.sh` | Inizio di ogni sessione | Pulisce l'accesso precedente, avvia il login HTTPS e verifica l'account. |
| `github-fine.sh` | Fine di ogni sessione | Rimuove l'autenticazione locale di `gh` e richiede la pulizia delle credenziali Git HTTPS. |

I tre strumenti vengono copiati in `~/.local/bin`; `install.sh` rimane il punto di ingresso nel repository. I due script di sessione includono autonomamente `~/.local/bin` nel proprio `PATH` e trovano `gh` anche senza riaprire il terminale. Mantenerli nella stessa directory, con i nomi originali.

Il controllo di `.bashrc` riconosce le forme comuni `$HOME/.local/bin`, `${HOME}/.local/bin`, `~/.local/bin` e il percorso assoluto nelle assegnazioni di `PATH`, ignorando i commenti. Non esegue `.bashrc`. Il blocco eventualmente aggiunto verifica che la directory esista e non duplica la voce nel `PATH`. Configurazioni indirette o personalizzate di Bash possono richiedere un controllo manuale.

## Guida per gli studenti

### 1. Inizio della sessione

```bash
github-inizio.sh
```

Se il comando non viene ancora trovato, usa `~/.local/bin/github-inizio.sh`.

Lo script chiama **sempre** `github-fine.sh` prima del login, anche per rimuovere credenziali precedenti scadute. Se la pulizia fallisce, si ferma.

1. Inserisci il tuo username GitHub, non l'email né il nome dell'utente Linux.
2. Apri l'indirizzo mostrato da `gh` e inserisci il codice temporaneo.
3. Controlla che il browser stia usando il tuo account e autorizza GitHub CLI. Se viene chiesto di autenticare anche Git, rispondi `Yes`.
4. Attendi `Accesso GitHub pronto per ...` e verifica il nome.

Se il browser autorizza un account diverso dallo username inserito, lo script rifiuta l'accesso e tenta la pulizia. Esci dall'account errato nel browser e riprova.

**Da una VM via SSH:** apri l'indirizzo nel browser del tuo computer o telefono e inserisci il codice del terminale remoto. Non serve un browser grafico sulla VM. Se il comando termina con un errore, riesegui lo script e usa il nuovo codice.

Esegui gli script normalmente: non usare `source` o `sudo`.

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

## Istruzioni per gli amministratori

### Preparare i requisiti

Se mancano Git o `curl`, installarli una volta sulla macchina o nell'immagine della VM:

```bash
sudo apt update
sudo apt install git curl ca-certificates
```

In una shell già root, omettere `sudo`. Non è necessario concedere privilegi amministrativi agli studenti.

Eseguire poi l'installer in una normale sessione dell'utente che lavorerà in laboratorio, per esempio `studente`. L'installazione vale per quella home: su macchine o home distinte va ripetuta. Il login di collaudo va eseguito fuori dalle lezioni perché rimuove l'accesso precedente.

### Installazione da una copia del repository

In alternativa al comando rapido:

```bash
git clone https://github.com/Laboratorio-di-fisica-computazionale/tools.git
cd tools
mkdir -p "$HOME/.local/bin"
install -m 0755 installa-gh.sh github-inizio.sh github-fine.sh "$HOME/.local/bin/"
bash "$HOME/.local/bin/installa-gh.sh"
```

Questo metodo permette anche di provare i file di un branch prima della pubblicazione su `main`.

### Permessi e verifiche

I file nella home appartengono all'utente che esegue l'installer e hanno permessi **`0755` (`rwxr-xr-x`)**. Non usare `777`. Chi usa lo stesso account Linux può modificarli: per proteggerli dalle modifiche degli studenti serve un'installazione di sistema gestita separatamente dall'amministratore.

Verificare nella sessione dell'utente:

```bash
export PATH="$HOME/.local/bin:$PATH"
command -v gh
gh --version
command -v github-inizio.sh
command -v github-fine.sh
ls -l ~/.local/bin/installa-gh.sh ~/.local/bin/github-inizio.sh ~/.local/bin/github-fine.sh
```

Se esistono vecchie copie in `/usr/local/bin`, verificare con `type -a github-inizio.sh github-fine.sh` quale versione viene eseguita. Mettere `~/.local/bin` prima delle altre directory nel `PATH`, oppure usare il percorso completo.

## Aggiornamento

Ripetere il comando di installazione rapida aggiorna i tre script da `main`, senza avviare il login. Un `gh` funzionante viene mantenuto. La copia di `gh` nella home non è gestita da `apt upgrade`.

Per una distribuzione fissata, scaricare `install.sh` da un tag o commit e avviarlo con `LAB_TOOLS_REF` impostato allo stesso riferimento, per esempio `LAB_TOOLS_REF=SHA_DEL_COMMIT bash install.sh`. Il riferimento deve essere un tag senza slash oppure uno SHA. Aggiornare fuori dalle sessioni di laboratorio.

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

Il login effettivo e il push vanno collaudati su una macchina del laboratorio prima della distribuzione agli studenti.
