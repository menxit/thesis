# Blockchain

La blockchain è una struttura dati autenticata e distribuita. Generalmente una struttura dati permette due tipologie di operazioni:

- interrogazioni
- aggiornamenti

In un'ADS le interrogazioni forniscono assieme alla risposta una prova verificabile dell'integrità della soluzione fornita.

Cosa significa questo? Ipotizziamo che Alice possegga una lista L:

```
L = { L1 -> L2 -> L3 -> L4 }
```

Partendo da questa lista, si costruisce un albero di questo tipo: per ciascun elemento della lista calcoliamo l'hash. Poi per ciascuna coppia di hash calcoliamo l'hash della concatenazione, fino ad arrivare alla radice di quest'albero.

![Merkle tree](./figure/merkle.png){width=400}

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

Bob ottiene una risposta e oltre a questo ottiene una prova di essa. Infatti concatenando ed effettuando l'hash della prova fornita, coerentemente alla costruzione dell'albero, può facilmente ricostruire la root dell'albero, verificando che coincida con quanto posseduto.

Questa struttura dati autenticata prende il nome di Merkle Tree ed è uno degli elementi fondanti della blockchain. In particolare la blockchain è per l'appunto una catena di blocchi con un ordine definito. Ciascun blocco contiene un certo numero di transazioni, le quali a loro volta hanno un certo ordine. Per ciascun blocco viene costruito uno di questi alberi.

Che utilità ha tutto questo? Ipotizziamo che esista una blockchain B con 500000 blocchi e che ciascun blocco abbia un peso di 1MB; il peso dell'intera blockchain sarà di 500GB.

Bob vuole sapere se $tx_n$ sia contenuta nel blocco $B_m$, ma non ha a disposizione un nodo di calcolo con 500GB di archivio, cosa può fare? Semplicemente memorizzerà solo l'hash root di ciascun blocco. Ipotizzando che un hash abbia un peso di 1MB e che il numero di blocchi sia 500000, lo spazio d'archiviazione necessario a Bob è minore di un 1MB.

Bob avendo a disposizione l'hash root di ciascun blocco e la possibilità di contattare un fullnode^[nodo di calcolo che possiede l'intera blockchain], può verificare che una certa transazione sia contenuta in un certo blocco, interrogando quest'ultimo. Il full node fornirà oltre alla risposta, la prova della risposta, il che garantisce a Bob che il risultato sia integro e che non sia stato manomesso da una terza parte.

Per quanto riguarda gli aggiornamenti, generalmente in una struttura dati essi devono rispettare determinate convenzioni. Come detto precedentemente la blockchain è una struttura dati distribuita; questo significa che la struttura dati in questione non è memorizzata in un unico nodo, ma in più nodi che prendono il nome di peer. La distribuzione può essere effettuata con due diversi approcci:

- replicazione: ciascun peer possiede una copia della stessa struttura dati

- sharding: ciascun peer possiede una porzione della struttura dati

- replicazione/sharding: il mix delle due tecniche precedenti

Attualmente la tecnologia blockchain si basa sul primo approccio, ovvero la replicazione. Questo significa che esistono N nodi e che ciascun nodo possiede una copia della stessa struttura dati.

Come detto gli aggiornamenti di una struttura dati devono seguire determinate convenzioni, una di queste convenzione è la seguente: una volta inserito un blocco, questo blocco non può essere modificato.

Come è possibile garantire una condizione simile in un sistema distribuito? Bada bene, questo problema non è risolto dal merkle tree, perché nel merkle tree si da per scontato che Bob abbia quanto meno i root hash di ciascun blocco. In questo caso Bob deve ancora ottenere i root hash, quindi l'uso esclusivo del merkle tree non ci garantisce molto in tal senso.

In altre parole ciò di cui abbiamo bisogno è un consenso della rete, ovvero, abbiamo bisogno che la rete possa confermare a Bob che la struttura dati da lui posseduta non sia stata manomessa.

Un possibile approccio è il seguente: Bob sceglie un nodo casuale, scarica da esso l'intera blockchain e ne effettua l'hash. Poi chiede a ciascun nodo del sistema di votare per la validità della struttura dati. Ciascun nodo vota fornendo a Bob l'hash dello della struttura dati nello stato corrente. Se il risultato coincide con quanto posseduto da Bob per un valore maggiore al 50% Bob prende per buona la struttura dati posseduta, altrimenti no.

Qui sorge il primo problema di questa soluzione. Come facciamo ad essere certi in un sistema distribuito che un nodo fornisca un unico voto? Ovvero come facciamo ad evitare che un nodo possa votare più volte?

Estremizzando questo ragionamento, sia $N$ il numero di nodi, un nodo $x$ potrebbe votare $N/2+1$ volte, inducendo Bob a credere che una struttura dati manomessa in realtà non lo sia.

Questo attacco prende il nome di sybil attack o pseudospoofing e l'approccio di voto democratico basato sull'entità del nodo non è immune ad esso.

Un approccio alternativo è basato sulla proof of work. L'idea è questa: abbiamo detto di dover garantire che la blockchain fornita a Bob non sia stata manomessa, ovvero che non sia possibile fornire a Bob una blockchain con blocchi precedente modificati. Ciò che possiamo fare è rendere difficile l'aggiunta di nuovi blocchi alla catena.

In particolare per aggiungere un nuovo blocco, occorrerà fornire una "prova di lavoro", ovvero la prova che per inserire questo blocco sia stato effettuato del lavoro; questa prova è rappresentata da un nonce. Infatti per poter aggiungere un blocco alla catena, occorrerà fornire un nonce, che se concatenato alle transazioni e successivamente hashato, deve restituire un hash che abbia un numero $D$ di zero.

Questa operazione prende il nome di mining. $D$ rappresenta la difficoltà corrente di mining e può variare, in particolare il valore di $D$ viene calibrato sulla base del tempo impiegato dalla rete per minare un blocco.

Di seguito lo pseudocodice di quello che potrebbe essere un algoritmo di proof of work.

```python
def proofOfWork (block, D):
	nonce = 0
	do
		nonce++
		result = hash(nonce | block)
	while (result.substring(0, D) == ('0' * D))
```

Andiamo a vedere nel dettaglio il contenuto di block:

- nonce: come già detto è il valore che permette di variare il risultato dell'hash per far si che rispetti una determinata proprietà
- roothash: il nodo root del merkle tree costruito sulla base delle transazioni che si vuole aggiungere al blocco corrente
- prev_hash: l'hash del precedente blocco

Perché tutto questo dovrebbe risolvere il problema della manomissione di blocchi precedenti? Di seguito in figura è descritto lo stato corrente della blockchain $B$:

![Blockchain con blocchi non manomessi](./figure/blocks-green.pdf){width=400}

Immaginiamo ora che un nodo malevolo voglia manomettere il blocco numero due della catena:

![Blockchain con blocchi manomessi](./figure/blocks-red.pdf){width=400}

Come è possibile vedere dalla figura, manomettere il blocco numero due, implica invalidare i blocchi 2, 3 e 4; infatti variando il valore del merkel root, varia anche il valore dell'hash, che con tutta probabilità non avrà più i primi D caratteri uguali a zero. Questo significa che il nodo malevolo dovrà calcolare un nuovo nonce per validare il blocco numero due.

Immaginiamo che il nodo malevolo si imbarchi in questa impresa, il risultato finale sarà questo:

![Blockchain con blocchi manomessi](./figure/blocks-red-2.pdf){width=400}

Ovvero avrà validato il blocco numero 2, ma i blocchi numero 3 e 4 saranno ancora invalidi, questo perché essi codificano al loro interno l'hash del blocco precedente, che a questo punto sarà chiaramente diverso.

Ciò che dovrà fare dunque il nodo malevolo è ricalcolare un nonce corretto per ciascun blocco successivo a quello manomesso. Questa operazione porterà via un gran quantitativo di tempo, durante il quale la rete avrà calcolato nuovi blocchi, di cui il nodo malevolo dovrà calcolare un nuovo nonce; è chiaro che in questa corsa contro il tempo, si ha qualche possibilità di vincere solo se si è in possesso di un gran quantitativo di potenza computazionale.

In particolare sarà possibile riuscire a disfare un blocco confermato e ricalcolare il nonce dei successivi, solo se si possiede più del 50% della potenza computazionale dell'intera rete, cosa decisamente più complessa e onerosa rispetto a generare una manciata di indirizzi ip.

Portiamo all'estremo questo ragionamento e ipotizziamo che esista un nodo con potenza computazionale maggiore del 50%, come possiamo evitare che il nodo disfi anche in questa situazione blocchi precedenti?

L'idea qui è di assegnare a ogni miner capace di calcolare il nonce correto dell'ultimo blocco una ricompensa. A questo punto, un nodo con tutta questa potenza computazionale, preferirà minare e ottenere i reward di ciascun blocco invece che manomettere blocchi passati, minando in questo modo la bontà del network del quale è padrone indiscusso.