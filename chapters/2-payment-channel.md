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

## Modello request-propose
Quelle descritti fino a questo 