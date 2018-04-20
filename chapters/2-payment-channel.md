# Payment channel

Un payment channel è un canale virtuale che permette a due entità di scambiare valore facendo un uso limitato della blockchain.

In particolare ad eccezione di alcune operazioni atte a mettere in piedi questo canale, tutte le altre avvengono off-chain, ovvero senza far uso della blockchain.

Un payment channel eredita tutte le proprietà di sicurezza della blockchain e inoltre garantisce:

- maggiore riservatezza: mentre le operazioni effettuate su blockchain sono pubbliche, quelle off-chain non lo sono.
- maggiore scalabilità: la blockchain per sua natura permette di effettuare un numero limitato di operazioni al secondo 
- pagamenti istantanei: mentre nella blockchain le transazioni devono essere minate e successivamente confermate, in un payment channel le transazioni sono pressocché istantantee.

In questo lavoro è stato implementato un payment channel basato su smart contract. Di seguito vengono analizzati gli approcci presi in considerazione e quelli infine adottati.

## Deploy dello smart contract
La prima azione che occorre effettuare per instaurare un payment channel tra due entità consiste nel deploy del relativo smart contract su mainet. Questa operazione permetterà di ottenere il relativo indirizzo del contatto, che nelle successive fasi verrà adottato per richiamare le varie operazioni on-chain che si intende adottare. Il payment channel può trovarsi in uno di $N$ stati; in fase di deploy lo stato è $INIT$.

## Apertura del canale
La seconda operazione che è necessario effettuare consiste nell'apertura del canale. Alice apre il canale e blocca un quantitativo arbitrario di fondi all'interno dello smart contract; questo valore rappresenterà il suo bilancio iniziale nel canale corrente. Oltre a bloccare i fondi vengono fornite le informazioni necessarie all'apertura del canale, in particolare:

- **ethereumAddressB**: ovvero l'indirizzo ethereum della controparte, (E.G Bob).
- **host**: un host associato all'utente corrente, successivamente questo aspetto verrà chiarito.
- **gp**: ovvero il grace period, anche questo aspetto verrà chiarito successivamente.

L'apertura del canale può essere effettuata esclusivamente quando il payment channel si trova in stato di $INIT$, in qualunque altro caso verrà sollevata un'eccezione.

Terminata l'esecuzione della procedura di open, lo stato del payment channel passerà da $INIT$ a $OPENED$.

## Join del canale
La terza e ultima operazione necessaria a instaurare un payment channel tra due entità consiste nel join del canale. Chiaramente questa operazione può essere effettuata dall'utente con public address uguale a **ethereumAddressB** espresso da Alice in fase di apertura. Inoltre questa operazione può essere effettuata esclusivamente quando lo stato del canale è $OPENED$.

Anche in questo caso l'utente richiamando la procedura bloccherà un numero arbitrario di fondi, che rappresenterà il bilancio iniziale dell'utente che ha effettuato il join, ovvero Bob. Inoltre Bob in fase di join fornirà il proprio **host** (anche qui, l'utilità di questa informazione verrà espressa successivamente). Una volta eseguita questa procedura, lo stato del canale passerà da $OPENED$ ad $ESTABLISHED$.

## Modello propose-accept
Quelle descritte fino a questo punto sono delle azioni che devono essere svolte in catena, necessarie a mettere in piedi un canale. Da questo punto in poi Alice e Bob possono scambiarsi dei pagamenti istantanei senza toccare la catena.

L'approccio adottato è detto di propose-accept e si basa su due endpoint http pubblici esposti.

Questi endpoint sono rispettivamente disponibili sotto l'host dichiarato in fase di apertura del canale.

- **/propose**: questo endpoint permette a uno delle due entità di richiedere alla controparte di concordare una nuova propose Una propose è un'entità che propose di spostare una certa quantità di valore dall'entità richiedente alla controparte
- **/accept**: questo endpoint permette a una delle due entità di accettare una propose precedentemente ricevuta sull'endpoint /propose

### Struttura di una propose
Una propose, ovvero una proposta di pagamento contiene essenzialmente quattro informazioni:

- **seq**: è il numero di sequenza, anche detto nonce; esso è un numero progressivo che parte da zero
- **contract_address**: l'indirizzo di riferimento del contratto che si sta utilizzando
- **balance_a**: il bilancio che si sta concordando per chi ha aperto il canale (E.G. Alice)
- **balance_b**: il bilancio che si sta concordando per chi ha fatto join del canale (E.G. Bob)

Poniamoci in una situazione d'esempio. Alice deploya e apre il canale, bloccando 1 eth. Bob effettua il join del canale e anche lui blocca 1 eth. Attualmente il bilancio di Alice e Bob è per entrambi di 1 eth e i fondi complessivi bloccati nel payment channel sono pari a 2 eth.

Ora Alice vuole inviare 0.2 eth a Bob; per farlo:

1. Costruisce un'opportuna propose
2. Effettua l'hash di quest'ultima
3. Firma l'hash della propose
4. Invia hash firmato e i valori in chiaro della propose

![Propose firmata da Alice](figure/propose-primo-esempio.pdf)

Bob riceve la propose e:

1. Verifica di essere d'accordo con il contenuto
2. Verifica che la firma di Alice sia valida
3. Se decide di accettare la propose, in maniera speculare ad Alice effettua l'hash del contenuto della propose e lo firma con la sua di chiave privata
4. Infine invia la propose controfirmata ad Alice, tramite il suo endpoint pubblico /accept

![Propose firmata da Bob](figure/propose-primo-esempio-bob.pdf)

A questo punto il bilancio off-chain di Alice e Bob è aggiornato, in particolare è rispettivamente di 0.8 ether per Alice e 1.2 ethere per Bob.

Seguendo lo stesso principio Alice e Bob possono concordare un numero arbitrario di propose (quindi di pagamenti), avendo sempre l'accortezza di aumentare il numero di sequenza; per esempio una successiva propose valida sarà:

```
seq=2; contract_address=0xe78...; a=0.9; b=1.1
```

In questa propose Bob ha inviato 0.1 eth ad Alice.

## Chiudere un canale
Come detto con questo modello di propose e accept Alice e Bob possono concordare un numero arbitrario di pagamenti. Questi pagamenti sono pressochè istantanei e aggiornano il bilancio off-chain delle controparti. Ma cosa significa aggiornare il bilancio off-chain? Quando Alice invia una propose firmata e Bob l'accetta, non avviene un vero e proprio pagamento sulla rete ethereum, ma le due parti stipolano un accordo che firmano e che non possono rescindere. In fase di chiusura del contratto Alice o Bob potranno presentare l'ultima propose concordata e ritirare quanto gli spetta.

Entrambe le parti possono chiudere il canale in qualsiasi momento (basta che il canale si trovi in stato $ESTABLISHED$).

Vediamo in particolare come avviene la chiusura. Ipotizziamo che Alice voglia chiudere il canale e ritirare dunque 0.9 ether. Alice eseguirà la procedura close dello smart contract. I parametri formali della procedura close sono:

- seq
- balanceA
- balanceB
- sig: propose corrente firmata da Bob

Il contratto verificherà la propose firmata da Bob e presentata da Alice e in caso positivo aggiornerà lo stato del canale in $CLOSED$.

Quando Alice presenta una propose valida e porta lo stato del canale in $CLOSED$ non ritira ancora i suoi ether, ma inizializza un timer.

Questo timer ha la durata di gracePeriod, la variabile presentata in fase di apertura del canale.

## Ritirare denaro da un canale
Come detto precedentemente la close di un payment channel porta il canale in uno stato di $CLOSED$ e inizializza un timer di durata pari a gracePeriod. Quando un canale si trova in $CLOSED$ e il timer è scaduto, entrambe le parti possono ritirare quanto riportato nella propose riportata in chiusura. Il ritiro del denaro avviene mediante una procedura denominata withdraw.

## Argue di una propose
Prima di andare in chiusura lo stato corrente del payment channel è quello illustrato in figura.

![Stato corrente del payment channel](figure/descrizione-stato-corrente.pdf){width=250}

Ovvero Alice e Bob hanno concordato rispettivamente 2 propose. Nella prima propose Alice ha inviato un pagamento di 0.2 ether a Bob e nella seconda Bob ha inviato un pagamento di 0.1 ether ad Alice.

A questo punto se Bob volesse chiudere il canale e fosse onesto, dovrebbe presentare in chiusura la propose con seq=2.

Ipotizziamo però che Bob sia malevolo e presenti in chiusura la propose con seq=1; dal suo punto di vista questa propose è sicuramente più vantaggiosa, in quanto gli vedrebbe accreditati non 0.1 ether in più.

Per come è congegnata la close dello smart contract presentato nessuno impedisce a Bob di presentare questa propose e portare lo stato del canale in $CLOSED$.

Questo chiaramente non va bene, l'unica propose valida è l'ultima proposta. A questo punto si propose un meccanismo di arguing per contrastare questa tipologia di attacco.

In particolare, quando una controparte presenta una propose in chiusura, essa produce un evento pubblico, che indica il sequence number della propose. Quando Alice riceve un evento di close relativo a un suo canale di interesse, deve controllare il sequence number della propose presentata e verificare che coincida con il sequence number dell'ultima propose concordata. In caso questo non fosse vero, Alice deve presentare tramite una procedura denominata **argue** dello smart contract l'ultima propose valida.

I parametri della procedura argue sono gli stessi della procedura close, il comportamento chiaramente è diverso. La procedura argue infatti verifica che la propose presentata sia valida e che il sequence number sia maggiore rispetto a quello dell'ultima propose presentata.

Nel caso in cui questo fosse vero il contratto punisce la controparte malevola inviando tutti i fondi del payment channel ad Alice.

La procedura di argue può essere effettuata solo quando il canale è in $CLOSED$ e il timer di durata pari al gracePeriod non è ancora scaduto.

Questo meccanismo permette di essere certi che le due parti siano oneste e presentino sempre e solo l'ultima propose valida.