# Introduzione {-}


# State channel e payment channel

## State channel

### Payment channel

### Progetti esistenti

#### Lightning Network

#### Spirites

#### Perun

#### Nocust

##### Descrizione dell'architettura

##### Analisi della sicurezza

##### Interruzione del servizio da parte dell'hub

##### Hub compromesso porta in catena root hash errato 


# Inextinguishable payment channel

## Introduzione

### Schema propose/accept

#### Introduzione

#### Transazioni off-chain

### Schema detach/attach

#### Introduzione

#### Hot withdraw

#### Hot refill

### Threat model

#### Double spending di un token

#### Token non speso

#### Gestione della free-option

#### Threat modeling tool


# Fulgur Hub

## Introduzione

## Obiettivi di progettazione

### Pagamenti ibridi

### Trustless

### Non censurabile

### Anonimato

### Scalabilità

## Schema detach/attach esteso

### Pagamenti omogenei

### Pagamenti misti

### Pagamenti esterni

### Chiusura di un canale


# Threat model

## Introduzione

## Recoverable exception paths

### B does not send a receipt back to Alice

### Myriad of tokens generation

## Unrecoverable exception paths

### The hub is not cooperative in token attachment

### The hub is not cooperative in token detachment

### Payment attempt via expired token

### Alice refuse to settle the transfer

### Malicious pending token redemption attempt

### Non-cooperation in payment reception

## Modello di incentivi


# Proof of concept

## Introduzione

## Scopi della PoC

## Apertura di un canale

## Transazioni OnChain-OnChain

## Transazioni OffChain-OffChain

## Transazioni OffChain-OnChain

## Transazioni OnChain-OffChain

## Riscossione di un pending token

## Chiusura di un canale

## Tecnologie

### Linguaggi di programmazione

#### TypeScript

#### Solidity

### Database

#### Redis

#### LevelDB


# Prove sperimentali

## Introduzione

## Transazioni OffChain-OffChain seriali

## Transazioni OffChain-OffChain concorrenti


# Conclusioni e sviluppi futuri {-}
![Blockchain con blocchi non manomessi\label{blocchi-manomessi}](./figure/blocks-green.pdf){width=400}
