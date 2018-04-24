# Payment channel

In questo capitolo viene descritta una possibile implementazione di payment channel basata su smart contract, analizzando e mettendo a confronto vari approcci e motivando le scelte infine adottate.

Un payment channel è un canale virtuale che permette a due entità di scambiare valore facendo un uso limitato della blockchain, esso eredita tutte le proprietà di sicurezza della blockchain e inoltre garantisce:

- maggiore riservatezza: mentre le operazioni effettuate su blockchain sono pubbliche, quelle off-chain non lo sono
- maggiore scalabilità: la blockchain per sua natura permette di effettuare un numero limitato di operazioni al secondo, cosa non vera per le operazioni off-chain
- pagamenti istantanei: mentre nella blockchain le transazioni devono essere minate e successivamente confermate, in un payment channel le transazioni sono pressoché istantanee

## Deploy dello smart contract
La prima azione che occorre effettuare per instaurare un payment channel tra due entità consiste nel deploy del relativo smart contract sulla blockchain. Questa operazione permette di ottenere il relativo indirizzo del contratto, che nelle successive fasi verrà adottato per richiamare le varie operazioni on-chain che si intende adottare. Il payment channel può trovarsi in uno di $N$ stati; in fase di deploy lo stato è $INIT$.

## Apertura del canale
La seconda operazione che è necessario effettuare consiste nell'apertura del canale. Alice apre il canale e blocca un quantitativo arbitrario di fondi all'interno dello smart contract; questo valore rappresenta il suo bilancio iniziale nel canale corrente. Oltre a bloccare i fondi, vengono fornite le informazioni necessarie all'apertura del canale, in particolare:

- **ethereumAddressB**: ovvero l'indirizzo ethereum della controparte, (E.G Bob)
- **host**: un host associato all'utente corrente, successivamente questo aspetto verrà chiarito
- **gp**: ovvero il grace period, anche questo aspetto verrà chiarito successivamente

L'apertura del canale può essere effettuata esclusivamente quando il payment channel si trova in stato di $INIT$, in qualunque altro caso verrà sollevata un'eccezione.
Terminata l'esecuzione della procedura di open, lo stato del payment channel passerà da $INIT$ a $OPENED$.

## Join del canale
La terza e ultima operazione necessaria a instaurare un payment channel tra due entità consiste nel join del canale. Questa operazione può essere effettuata solo dall'utente con public address uguale a **ethereumAddressB** espresso da Alice in fase di apertura. Inoltre questa operazione può essere effettuata esclusivamente quando lo stato del canale è $OPENED$.
Anche in questo caso l'utente richiamando la procedura bloccherà un numero arbitrario di fondi, che rappresenterà il bilancio iniziale dell'utente che ha effettuato il join, ovvero Bob. Inoltre Bob in fase di join fornirà il proprio **host** (anche qui, l'utilità di questa informazione verrà espressa successivamente). Una volta eseguita questa procedura, lo stato del canale passerà da $OPENED$ ad $ESTABLISHED$.

## Modello propose-accept
Quelle descritte fino a questo punto sono delle azioni che devono essere svolte in catena, necessarie a mettere in piedi un canale. Da questo punto in poi Alice e Bob possono scambiarsi dei pagamenti istantanei senza toccare la catena.
L'approccio adottato è detto di propose-accept e si basa su due endpoint http pubblici esposti.
Questi endpoint sono rispettivamente disponibili sotto l'host dichiarato in fase di apertura del canale.

- **/propose**: questo endpoint permette a uno delle due entità di richiedere alla controparte di concordare una nuova propose Una propose è un'entità che propone di spostare una certa quantità di valore dall'entità richiedente alla controparte
- **/accept**: questo endpoint permette a una delle due entità di accettare una propose precedentemente ricevuta sull'endpoint /propose

### Struttura di una propose
Una propose, ovvero una proposta di pagamento contiene essenzialmente quattro informazioni:

- **seq**: è il numero di sequenza, anche detto nonce; esso è un numero progressivo che parte da zero
- **contract_address**: l'indirizzo di riferimento del contratto che si sta utilizzando
- **balance_a**: il bilancio che si sta concordando per chi ha aperto il canale (E.G. Alice)
- **balance_b**: il bilancio che si sta concordando per chi ha fatto join del canale (E.G. Bob)

Poniamoci in una situazione d'esempio. Alice deploya e apre il canale, bloccando 1 eth. Bob effettua il join del canale e anche lui blocca 1 eth. Attualmente il bilancio di Alice e Bob è per entrambi di 1 eth e i fondi complessivi bloccati nel payment channel sono pari a 2 eth.
Ora Alice vuole inviare 0.2 eth a Bob; per farlo:

1. Costruisce un'opportuna propose (vedi figura \ref{propose-firmata-da-alice})
2. Effettua l'hash di quest'ultima
3. Firma l'hash della propose
4. Invia hash firmato e i valori in chiaro della propose

![Propose firmata da Alice\label{propose-firmata-da-alice}](figure/propose-primo-esempio.pdf){width=150}

Bob riceve la propose e:

1. Verifica di essere d'accordo con il contenuto
2. Verifica che la firma di Alice sia valida
3. Se decide di accettare la propose, in maniera speculare ad Alice effettua l'hash del contenuto della propose e lo firma con la sua di chiave privata
4. Infine invia la propose controfirmata ad Alice, tramite il suo endpoint pubblico /accept (vedi figura \ref{propose-firmata-da-bob})

![Propose firmata da Bob\label{propose-firmata-da-bob}](figure/propose-primo-esempio-bob.pdf){width=150}

A questo punto il bilancio off-chain di Alice e Bob è aggiornato, in particolare è rispettivamente di 0.8 ether per Alice e 1.2 ether per Bob.
Seguendo lo stesso principio Alice e Bob possono concordare un numero arbitrario di propose (quindi di pagamenti), avendo sempre l'accortezza di aumentare il numero di sequenza; per esempio una successiva propose valida sarà:

```
seq=2; contract_address=0xe78...; a=0.9; b=1.1
```

In questa propose Bob ha inviato 0.1 eth ad Alice.

## Chiusura di un canale
Come detto con questo modello di propose e accept Alice e Bob possono concordare un numero arbitrario di pagamenti. Questi pagamenti sono pressoché istantanei e aggiornano il bilancio off-chain delle controparti. Ma cosa significa aggiornare il bilancio off-chain? Quando Alice invia una propose firmata e Bob l'accetta, non avviene un vero e proprio pagamento sulla rete ethereum, ma le due parti stipulano un accordo che firmano e che non possono rescindere. In fase di chiusura del contratto Alice o Bob potranno presentare l'ultima propose concordata e ritirare quanto gli spetta.
Entrambe le parti possono chiudere il canale in qualsiasi momento (basta che il canale si trovi in stato $ESTABLISHED$).
Vediamo in particolare come avviene la chiusura. Ipotizziamo che Alice voglia chiudere il canale e ritirare dunque 0.9 ether. Alice eseguirà la procedura close dello smart contract. I parametri formali della procedura close sono:

- seq
- balanceA
- balanceB
- sig: propose corrente firmata da Bob

Il contratto verificherà la propose firmata da Bob e presentata da Alice e in caso positivo aggiornerà lo stato del canale in $CLOSED$. Quando Alice presenta una propose valida e porta lo stato del canale in $CLOSED$ non ritira ancora i suoi ether, ma inizializza un timer. Questo timer ha la durata di gracePeriod, la variabile presentata in fase di apertura del canale.

## Ritirare denaro da un canale
Come detto nel paragrafo precedente la close di un payment channel porta il canale in uno stato di $CLOSED$ e inizializza un timer di durata pari a gracePeriod. Quando un canale si trova in $CLOSED$ e il timer è scaduto, entrambe le parti possono ritirare quanto riportato nella propose riportata in chiusura. Il ritiro del denaro avviene mediante una procedura denominata withdraw.

## Argue di una propose
Prima di andare in chiusura lo stato corrente del payment channel è quello illustrato in figura \ref{stato-corrente}.

![Stato corrente del payment channel\label{stato-corrente}](figure/descrizione-stato-corrente.pdf){width=250}

Ovvero Alice e Bob hanno concordato rispettivamente 2 propose. Nella prima propose Alice ha inviato un pagamento di 0.2 ether a Bob e nella seconda Bob ha inviato un pagamento di 0.1 ether ad Alice.
A questo punto se Bob volesse chiudere il canale e fosse onesto, dovrebbe presentare in chiusura la propose con seq=2.
Ipotizziamo però che Bob sia malevolo e presenti in chiusura la propose con seq=1; dal suo punto di vista questa propose è  più vantaggiosa, in quanto gli vedrebbe accreditati 0.1 ether in più.
Per come è congegnata la close dello smart contract presentato nessuno impedisce a Bob di presentare questa propose e portare lo stato del canale in $CLOSED$.
Questo chiaramente non va bene, l'unica propose valida è l'ultima proposta. A questo punto si propose un meccanismo di arguing per contrastare questa tipologia di attacco.
In particolare, quando una controparte presenta una propose in chiusura, essa produce un evento pubblico, che indica il sequence number della propose. Quando Alice riceve un evento di close relativo a un suo canale di interesse, deve controllare il sequence number della propose presentata e verificare che coincida con il sequence number dell'ultima propose concordata. In caso questo non fosse vero, Alice deve presentare tramite una procedura dello smart contract denominata $argue$, l'ultima propose valida.
I parametri della procedura argue sono gli stessi della procedura close, il comportamento chiaramente è diverso. La procedura argue infatti verifica che la propose presentata sia valida e che il sequence number sia maggiore rispetto a quello dell'ultima propose presentata.
Nel caso in cui questo fosse vero, il contratto punirebbe la controparte malevola inviando tutti i fondi del payment channel ad Alice, ovvero a chi ha richiamato $argue$.
La procedura di argue può essere effettuata solo quando il canale è in $CLOSED$ e il timer di durata pari al gracePeriod non è  scaduto.
Questo meccanismo permette di essere certi che le due parti siano oneste e presentino sempre e solo l'ultima propose valida.

## Free-option, controparte passiva e challenge close
Un altro tipo di attacco al quale potrebbe essere soggetto il payment channel così proposto è il seguente.

| seq | balance_a | balance_b| firma |
|-----|-----------|----------|-------|
| 1	  | 0.8		  | 1.2		 | A/B   |
| 2   | 0.9		  | 1.1		 | A 	 |

Come è possibile notare sono presenti due propose. La prima propose è stata firmata sia da A che da B. La seconda propose è stata proposta e firmata da Alice, che rimane in attesa della risposta di Bob. Questa situazione è particolarmente pericolosa per due motivi:

1. Bob è in una condizione più vantaggiosa, infatti ha la possibilità di presentare in chiusura due propose, sia quella con seq=1 che quella con seq=2. Questo è possibile in quanto Alice non possiede ancora la propose con seq=2 firmata da Bob e non può sfruttare la procedura argue.

2. Alice non può chiudere il canale fin tanto che Bob non risponde; se Alice dovesse decidere di chiudere il canale, dovrebbe presentare la propose con seq=1; in quel caso Bob potrebbe richiamare la procedura argue e presentando la propose con seq=2 e punendo ingiustamente la controparte.

Per quanto riguarda il primo problema, ovvero la free-option, è vero che Bob ha questa scelta, ma è anche vero che le propose rappresentano dei pagamenti, quindi anche se Bob presentasse in chiusura seq=1 andrebbe contro i suoi interessi, in quanto si priverebbe di 0.1 ether.
Riguarda lo stato di stallo in cui si trova Alice, si propone un approccio basato su sfida. In particolare è possibile prevedere una nuova procedura dello smart contract denominata $challengeClose$.
Quando Alice non riceve risposta da Bob e intende chiudere il canale, invece di presentare una propose più vecchia rischiando di essere punita, sfida Bob a chiudere. Nel momento in cui questa funzione viene richiamata, lo stato del canale viene aggiornato in $CHALLENGED$ e inoltre viene inizializzato un timer di durata **gracePeriod**. Fin tanto che lo stato del canale è $CHALLENGED$ e il timer non è scaduto, Bob può presentare in chiusura una propose. Quando il timer scade, Alice può richiamare il metodo $withdraw$ e ritirare tutti i fondi del payment channel.
Per chiarezza riportiamo in figura \ref{primo-automa-temporizzato}, un automa temporizzato che descrive i cambiamenti di stato dello smart contract di cui ci siamo serviti.

![Primo automa temporizzato\label{primo-automa-temporizzato}](figure/automa-temporizzato-1.pdf)

Ritorniamo alla situazione precedentemente descritta, ovvero quella in cui Alice ha inviato la propose con seq=2 a Bob e Bob si trova in una situazione di vantaggio. Come abbiamo già detto, Bob potrebbe irrazionalmente non controfirmare più alcuna propose di Alice, lasciando quest'ultima in uno stato di stallo. Abbiamo detto di aver superato questo problema introducendo la $challengeClose$ di cui Alice può servirsi per sbloccare la situazione. In questa situazione però cosa accadrebbe se fosse Bob a richiamare la $challengeClose$? Alice sarebbe costretta a chiudere e presentare una propose con un vecchio stato e a quel punto Bob potrebbe richiamare la procedura $argue$ e punire ingiustamente Alice.
Questo problema è facilmente superabile raffinando la procedura di argue. Attualmente essa verifica che sia stata presentata una propose con numero di sequenza maggiore rispetto a quella presentata per punire la controparte; un approccio diverso potrebbe essere questo: se la propose presentata ha un numero di sequenza maggiore almeno di 2 allora la controparte viene punita, in caso contrario semplicemente viene aggiornata l'ultima propose con quella presentata.

## Un approccio non punitivo
La combinazione di $challengeClose$ e $argue$ permette di parare entrambe le controparti da vari attacchi di cui abbiamo discusso nei precedenti paragrafi; questo ci ha portati ad aumentare sensibilmente la complessità dello smart contract, introducendo due nuove funzioni e due nuovi stati ($ARGUED$ e $CHALLENGED$). In questo paragrafo presentiamo una soluzione alternativa, che non si basa su un approccio punitivo e che ci permette di ridurre drasticamente la complessità dello smart contract; questa soluzione prevede di eliminare le procedure argue, challengeClose e i relativi stati, modificando però il comportamento della close.
Nel approccio precedente la close era una procedura che poteva essere richiamata un unica volta; quanto affermato con la $close$ poteva essere discusso con la procedura $argue$ entro lo scadere di un timer. In questa soluzione alternativa invece, la $close$ può essere richiama più volte prima dello scadere del timer; in particolare può essere utilizzata fin tanto che viene portata in chiusura una propose valida e con numero seq maggiore rispetto all'ultima propose presentata, vedi figura \ref{secondo-automa-temporizzato}.
In questo modo se una controparte malevola propone una propose vecchia, la controparte vittima può sempre presentarne una più nuova andando a sovrascrivere la precedente. Per quanto riguarda la fase di stallo descritta nel precedente paragrafo, questa non si verifica, in quanto chiunque può sempre portare in chiusura una propose valida, senza dover temere di essere eventualmente punito dalla controparte.

![Secondo automa temporizzato\label{secondo-automa-temporizzato}](figure/automa-temporizzato-2.pdf){width=250}

## Inextinguishable Payment Channel
Il tipo di payment channel che abbiamo descritto fino ad ora permette a due entità di scambiare del valore; questo valore però può essere effettivamente ritirato (off-chain) solo chiudendo il payment channel.
Inoltre spesso i canali sono sbilanciati, ovvero un'entità spende più di quanto riceve in cambio e questo può portare ad una situazione in cui una delle due entità abbia 0 ether; se questa stessa entità con 0 ether volesse effettuare un ulteriore nuovo pagamento, sarebbe costretta a dover instaurare un nuovo payment channel, perdendo tempo e denaro in fee per il deploy di un nuovo canale e l'operazione di apertura associata ad esso.
In questo paragrafo proponiamo un payment channel da quale possa essere effettuato un $hotRefill$ e un $hotWithdraw$, ovvero delle procedure off-chain che ci permettano di ricaricare un canale o ritirare dei soldi, senza però essere costretti a chiudere il payment channel.

### Hot withdraw
Ipotizziamo di avere un canale $ESTABLISHED$ tra Alice e Bob, il cui stato è sintetizzato di seguito:

| Alice | Bob | Seq |
|-------|-----|-----|
|1      |1    |     |
|0.2    |1.8  |seq=1|

Ora Bob vuole ritirare 0.8 ether e comunica questa sua volontà ad Alice. Alice in cambio invia un token a Bob di questo tipo:

```
t = [hash(seq=1, amount=0.8)]_a
```

Il token non è altro che l'hash della concatenazione del numero di sequenza dell'ultima propose firmata da entrambe le controparti e il quantitativo di ether che Bob intende ritirare, il tutto firmato con la chiave privata di Alice.
A questo punto si introduce una nuova procedura all'interno dello smart contract la cui interfaccia è di seguito esposta:

```hotWithdraw(seq, amount, t)```

A questo punto Bob esegue in catena questo metodo, passando come parametri rispettivamente:

- seq: il numero di sequenza codificato nel token precedentemente realizzato
- amount: il quantitativo di ether che Bob intende ritirare
- t: il token firmato da Alice

La procedura verifica la validità del token e in caso positivo sposta il quantitativo di ether concordato nel balance off-chain di Bob.
Le successive proposte che Alice e Bob concorderanno, dovranno prendere in considerazione il fatto che è stato rilasciato un token per effettuare questo hotWithdraw e che quindi il bilancio on-chain di Bob è diminuito.

Per chiarezza questa propose non sarà valida:

| Alice | Bob |
|-------|-----|
|0.3    |1.7  |

Questa invece sarà valida:

| Alice | Bob |
|-------|-----|
|0.3    |0.9  |

### Double spending di un token
Per come è descritto l'uso del token e dello smart contract, nessuno impedisce a Bob di eseguire più di una volta la procedura $hotWithdraw$ ritirando più volte 0.8 ether pur non avendo l'autorizzazione da parte di Alice; chiaramente questo non va bene. Per evitare il fenomeno del double spending occorre memorizzare all'interno dello smart contract l'uso di questo token. In particolare si propone di associare a ciascuna controparte una mappa del tipo:

```js
mapping (uint256 => uint256) proofOfDetachment;
```

Dove la chiave corrisponde al numero di sequenza al quale si riferisce il particolare token che si sta utilizzando e il valore è relativo all'amount che si è ritirato.
A questo punto $hotWithdraw$ oltre a verificare la validità del token, verificherà che non sia stato già utilizzato.

```js
require(currentCounterpart.proofOfDetachment[seq] == 0);
currentCounterpart.proofOfDetachment[seq] = amount;
```

### Token speso in ritardo
Un possibile problema introdotto da questo modello è il seguente: Bob riceve il token, ma non lo spende; a questo punto presenta sulla blockchain una propose con seq=1 e prima che Alice effettui il withdraw, fa il withdraw e poi spende il token. In questo modo Bob presenta legittimamente una propose in cui non gli è stato ancora stato sottratto il token. Per gestire il problema, si limita l'uso della procedura $hotWithdraw$ solo in stato $ESTABLISHED$.

