# Payment Channel

## Blockchain

La blockchain [@hendrick1988generic;@atzeni2009basi] è una struttura dati autenticata (ADS) e distribuita. Una struttura dati permette due tipologie di operazioni:

- interrogazioni
- aggiornamenti

In una struttura dati autenticata le interrogazioni forniscono assieme alla risposta una prova verificabile dell'integrità della soluzione fornita.

Cosa significa questo? Ipotizziamo che Alice possegga una lista L:

```
L = { L1 -> L2 -> L3 -> L4 }
```

Partendo da questa lista, si costruisce un albero di questo tipo: per ciascun elemento della lista calcoliamo l'hash. Poi per ciascuna coppia di hash calcoliamo l'hash della concatenazione, fino ad arrivare alla radice di quest'albero.

![Merkle tree](./figure/merkle.png){width=500}

Alice possiede la lista L e l'intero albero, Bob invece possiede esclusivamente il nodo radice. 

Ipotizziamo che Bob voglia sapere se L3 sia contenuto in L; farà una query di questo tipo:

```
query: L contains L3
```

Alice riceve questa query e risponde così:

```
result: true
proof: Hash(0), Hash(1-1), Hash(1)
```

Bob ottiene una risposta e oltre a questo ottiene una prova della risposta. Concatenando ed effettuando l'hash della prova coerentemente alla costruzione dell'albero, Bob può facilmente ricostruire la root dell'albero, verificando che coincida con quanto posseduto.

Questa struttura dati autenticata prende il nome di Merkle Tree ed è uno degli elementi fondanti della blockchain. In particolare la blockchain è per l'appunto una catena di blocchi con un ordine definito. Ciascun blocco contiene un certo numero di transazioni, le quali a loro volta hanno un certo ordine. Per ciascun blocco viene costruito uno di questi alberi.

Che utilità ha tutto questo? Ipotizziamo che esista una blockchain B con 500000 blocchi e che ciascun blocco abbia un peso di 1MB. Il peso dell'intera blockchain sarà di 500GB.

Bob vuole sapere se $tx_n$ sia contenuta nel blocco $B_m$, ma non ha a disposizione un nodo di calcolo con 500GB di archivio, cosa può fare? Semplicemente memorizzerà solo l'hash root di ciascun blocco. Ipotizzando che un hash abbia un peso di 1MB e che il numero di blocchi sia 500000, lo spazio d'archiviazione necessario a Bob è minore di un 1MB.

Bob avendo a disposizione l'hash root di ciascun blocco e un full node, ovvero un nodo di calcolo che possiede l'intera blockchain può verificare che una certa transazione sia contenuta in un certo blocco, interrogando un full node. Il full node fornirà oltre alla risposta, la prova della risposta, il che garantisce a Bob che il risultato sia integro e che non sia stato manomesso da una terza parte.

Per quanto riguarda gli aggiornamenti, generalmente in una struttura dati essi devono rispettare determinate convenzioni. Come detto precedentemente la blockchain è una struttura dati distribuita; questo significa che la struttura dati in questione non è memorizzata in un unico nodo, ma in più nodi che prendono il nome di peer. La distribuzione può essere effettuata con due diversi approcci:

- replicazione: ciascun peer possiede una copia della stessa struttura dati

- sharding: ciascun peer possiede una porzione della struttura dati

- replicazione/sharding: il mix delle due tecniche precedenti.

Attualmente la tecnologia blockchain si basa sul primo approccio, ovvero la replicazione. Questo significa che esistono N nodi e che ciascun nodo possiede una copia della stessa struttura dati.

Come detto gli aggiornamenti di una struttura dati devono seguire determinate convenzioni. Una di queste convenzione della blockchain è la seguente: una volta inserito un blocco, questo blocco non può essere modificato.

Come è possibile garantire una condizione simile in un sistema distribuito? Bada bene, questo problema non è risolto da una struttura dati autenticata come il merkle tree, perché nel merkle tree si da per scontato che Bob abbia quanto meno i root hash di ciascun blocco. In questo caso Bob deve ancora ottenere i root hash. 

In altre parole ciò di cui abbiamo bisogno è un consenso della rete, ovvero, abbiamo bisogno che la rete possa confermare a Bob che la struttura dati da lui posseduta non sia stata manomessa.

Un possibile approccio è il seguente: Bob sceglie un nodo casuale, scarica da esso l'intera blockchain e ne effettua l'hash. Poi chiede a ciascun nodo del sistema di votare per la validità della struttura dati. In particolare ciascun nodo vota fornendo a Bob l'hash dello stato della struttura dati corrente. Se il risultato coincide con quanto posseduto da Bob per un valore maggiore al 50% Bob prende per buona la struttura dati posseduta. 

Qui sorge il primo problema di questa soluzione. Come facciamo ad essere certi in un sistema distribuito che un nodo fornisca un unico voto? Ovvero come facciamo ad evitare che un nodo possa votare più volte?

Estremizzando questo ragionamento, sia $N$ il numero di nodi, un nodo $X$ potrebbe votare $N/2+1$ volte, inducendo Bob a credere che una struttura dati manomessa in realtà non lo sia.

Questo attacco prende il nome di sybil attack o pseudospoofing e questo approccio di voto democratico basato sull'entità del nodo non è immune ad esso.

Un approccio alternativo è basato sulla proof of work. L'idea è questa: abbiamo detto di dover garantire che la blockchain fornita a Bob non sia stata manomessa, ovvero che non sia possibile fornire a Bob una blockchain con blocchi precedente modificati.