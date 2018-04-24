# Blockchain

La blockchain è una struttura dati autenticata e distribuita. Generalmente una struttura dati permette due tipologie di operazioni:

- interrogazioni
- aggiornamenti

In un'ADS le interrogazioni forniscono assieme alla risposta una prova verificabile dell'integrità della soluzione fornita[@tamassia2003authenticated].
Cosa significa questo? Sia L una lista posseduta da Alice:

```
L = { L1 -> L2 -> L3 -> L4 }
```

Partendo da questa lista, costruiamo un albero di questo tipo: per ciascun elemento della lista calcoliamo l'hash; poi per ciascuna coppia di hash calcoliamo l'hash della concatenazione, fino ad arrivare alla radice di quest'albero (vedi figura \ref{merkle-tree}).

![Merkle tree\label{merkle-tree}](./figure/merkle.png){width=450}

Alice possiede la lista L e l'intero albero, Bob invece possiede esclusivamente il nodo radice. 
Ipotizziamo che Bob voglia sapere se L3 sia contenuto in L; fa una query di questo tipo:

```
query: L contains L3
```

Alice riceve questa query e risponde così:

```
result: true
proof: Hash(0), Hash(1-1), Hash(1)
```

Bob ottiene una risposta e oltre a questo ottiene una prova di essa. Infatti concatenando ed effettuando l'hash della prova fornita, coerentemente alla costruzione dell'albero, può facilmente ricostruire la root dell'albero, verificando che coincida con quanto posseduto[@merkle1989certified].
Questa struttura dati autenticata prende il nome di Merkle Tree ed è uno degli elementi fondanti della blockchain. In particolare la blockchain è per l'appunto una catena di blocchi con un ordine definito. Ciascun blocco contiene un certo numero di transazioni, le quali a loro volta hanno un certo ordine. Per ciascun blocco viene costruito uno di questi alberi.
Che utilità ha tutto questo? Sia B una blockchain con 500K blocchi e sia il peso di ciascun blocco pari a 1MB; il peso dell'intera blockchain sarà di 500GB.
Bob vuole sapere se $tx_n$ sia contenuta nel blocco $B_m$, ma non ha a disposizione un nodo di calcolo con 500GB di archivio, cosa può fare? Semplicemente memorizza esclusivamente l'hash root di ciascun blocco. Ipotizzando che un hash abbia peso di 1 byte, lo spazio d'archiviazione necessario a Bob è minore di un 1MB.
Bob avendo a disposizione l'hash root di ciascun blocco e la possibilità di contattare un full node^[nodo di calcolo che possiede l'intera blockchain], può verificare che una certa transazione sia contenuta in un certo blocco interrogando quest'ultimo. Il full node fornirà oltre alla risposta, la prova della risposta, il che garantisce a Bob che il risultato sia integro e che non sia stato manomesso da una terza parte.
Per quanto riguarda gli aggiornamenti, generalmente devono rispettare determinate convenzioni. Come detto precedentemente la blockchain è una struttura dati distribuita; questo significa che non è memorizzata in un unico nodo, ma in più nodi che prendono il nome di peer. La distribuzione può essere effettuata con due diversi approcci:

- replicazione: ciascun peer possiede una copia della stessa struttura dati

- sharding: ciascun peer possiede una porzione della struttura dati

- replicazione/sharding: il mix delle due tecniche precedenti

Attualmente le implementazioni tecnologiche più comuni della blockchain si basano sul primo approccio, ovvero la replicazione, il che significa che esistono N nodi e che ciascun nodo possiede una copia della stessa struttura dati.
Come detto gli aggiornamenti di una struttura dati devono seguire determinate convenzioni, una di queste convenzione è la seguente: una volta inserito un blocco, questo blocco non può essere modificato.
Come è possibile garantire una condizione simile in un sistema distribuito? Bada bene, questo problema non è risolto dal merkle tree, perché nel merkle tree si da per scontato che Bob abbia quanto meno i root hash di ciascun blocco. In questo caso Bob deve ancora ottenere i root hash, quindi l'uso esclusivo del merkle tree non ci garantisce molto in tal senso.
In altre parole ciò di cui abbiamo bisogno è un consenso della rete; la rete deve poter confermare a Bob che la struttura dati da lui posseduta non sia stata soggetta a manomissione.
Un possibile approccio è il seguente: Bob sceglie un nodo casuale, scarica da esso l'intera blockchain e ne effettua l'hash. Poi chiede a ciascun nodo del sistema di votare per la validità della struttura dati. Ciascun nodo vota fornendo a Bob l'hash della struttura dati nello stato corrente. Se il risultato coincide con quanto posseduto da Bob per un numero di volte maggiore alla metà dei nodi presenti in rete, Bob prende per buona la struttura dati posseduta, altrimenti no.
Qui sorge il primo problema: come facciamo ad essere certi in un sistema distribuito che un nodo fornisca un unico voto? Ovvero, come facciamo ad evitare che un nodo possa votare più volte?
Estremizzando questo ragionamento, sia $N$ il numero di nodi, un nodo $x$ potrebbe votare $N/2+1$ volte, inducendo Bob a credere che una struttura dati manomessa in realtà non lo sia.
Questo attacco prende il nome di sybil attack o pseudospoofing e l'approccio di voto democratico basato sull'entità del nodo non è immune ad esso.
Un approccio alternativo è basato sulla proof of work; l'idea è che è possibile rendere difficile l'aggiunta o la modifica di nuovi blocchi.
In particolare per aggiungere o modificare un nuovo blocco, occorre fornire una "prova di lavoro"; in altre parole bisogna dimostrare che per fare quell'aggiornamento della struttura dati si sia perso un certo quantitativo di tempo; questa prova è rappresentata da un nonce. Infatti per poter aggiungere un blocco alla catena, occorrerà fornire un numero, che se concatenato alle transazioni (o meglio al root hash) e successivamente hashato, restituisca un hash che abbia un numero $D$ di zero iniziali.
Questa operazione prende il nome di mining. $D$ rappresenta la difficoltà corrente di mining e può variare, in particolare il valore di $D$ viene calibrato sulla base del tempo impiegato dalla rete per minare gli ultimi blocchi.
Di seguito lo pseudo codice di quello che potrebbe essere un algoritmo di mining.

```python
def mining (block, D):
	nonce = 0
	do
		nonce++
		result = hash(nonce | block)
	while (result.substring(0, D) == ('0' * D))
```

Il contenuto di un blocco è il seguente:

- nonce: come già detto è il valore che permette di variare il risultato dell'hash per far si che rispetti una determinata proprietà (E.G. un certo quantitativo di zero iniziali)
- root hash: il nodo root del merkle tree costruito sulla base delle transazioni che si vuole aggiungere al blocco corrente
- prev_hash: l'hash del precedente blocco

Perché tutto questo dovrebbe risolvere il problema della manomissione di blocchi precedenti? In figura \ref{blocchi-manomessi} è riportato lo stato corrente della blockchain $B$; ci sono quattro blocchi e tutti e quattro sono stati minati.

![Blockchain con blocchi non manomessi\label{blocchi-manomessi}](./figure/blocks-green.pdf){width=400}

Immaginiamo ora che un nodo malevolo voglia manomettere il blocco numero due della catena.

![Blockchain con un blocco manomesso minato\label{blocchi-manomessi-2}](./figure/blocks-red.pdf){width=400}

Come è possibile vedere in figura \ref{blocchi-manomessi-2}, manomettere il blocco numero due, implica invalidare i blocchi 2, 3 e 4; infatti variando il valore del merkle root, varia anche il valore dell'hash, che con tutta probabilità non avrà più i primi D caratteri uguali a zero. Questo significa che il nodo malevolo dovrà calcolare un nuovo nonce per validare il blocco numero due.
Se il nodo malevolo dovesse imbarcarsi in questa impresa, il risultato finale sarebbe quello riportato in figura \ref{blocchi-manomessi-2}, ovvero avrà validato il blocco numero 2, ma i blocchi numero 3 e 4 saranno ancora invalidi, questo perché essi codificano al loro interno l'hash del blocco precedente, che a questo punto sarà chiaramente diverso.

![Blockchain con blocchi manomessi\label{blocchi-manomessi-2}](./figure/blocks-red-2.pdf){width=400}

Ciò che dovrà fare dunque il nodo malevolo è ricalcolare un nonce corretto per ciascun blocco successivo a quello manomesso. Questa operazione porterà via un gran quantitativo di tempo, durante il quale la rete avrà calcolato nuovi blocchi, di cui il nodo malevolo dovrà calcolare un nuovo nonce; è chiaro che in questa corsa contro il tempo, si ha qualche possibilità di vincere solo se si è in possesso di un gran quantitativo di potenza computazionale.
In particolare sarà possibile riuscire a disfare un blocco confermato e ricalcolare il nonce dei successivi, solo se si possiede più del 50% della potenza computazionale dell'intera rete[@nakamoto2008bitcoin].
Portiamo all'estremo questo ragionamento e ipotizziamo che esista un nodo con potenza computazionale maggiore del 50%, come possiamo evitare che il nodo disfi anche in questa situazione blocchi precedenti?
L'idea qui è di assegnare a ogni miner capace di calcolare il nonce corretto dell'ultimo blocco una ricompensa. A questo punto, un nodo con tutta questa potenza computazionale, preferirà minare e ottenere i reward di ciascun blocco invece che manomettere blocchi passati, minando in questo modo la bontà del network del quale è padrone indiscusso[@nakamoto2008bitcoin].
