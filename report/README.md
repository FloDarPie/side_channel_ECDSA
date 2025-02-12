# Attaque par canal auxiliaire sur la signature ECDSA et réduction de réseau

## Missions

Amélioration de l'attaque, couvrir le cas des blocs discontinu et le cas des blocs non initié à zéro => /!\ des lambda mu /!\

Convertir le programme à ECDSA.

Application au processus de l'ANSSI

Redaction section DSA

Redaction section ECDSA

Redaction autres

---
## Lattice Attacks on Digital Signature Schemes

### 1st ref - Summary

> We describe a lattice attack on the Digital Signature
Algorithm (DSA) when used to sign many messages,
mi , under the assumption that a proportion of the bits of
each of the associated ephemeral keys, yi , can be
recovered by alternative techniques.

## A Tale of Three Signatures: practical attack of ECDSA with wNAF

### 2nd ref - Abstract (part)

> Attacking ECDSA with wNAF... we reinvestigate the construction of the lattice used in one of
these methods, the Extended Hidden Number Problem (EHNP). We find
the secret key with only 3 signatures thus reaching a known theoretical bound...

## Fast Practical Lattice Reduction through Iterated Compression

### 3nd ref - Abstract (part)

> We introduce a new lattice basis reduction algorithm with
approximation guarantees analogous to the LLL algorithm and practical
performance that far exceeds the current state of the art...
This yields a running time of O(n^ω*(C+n)^(1+ε))
for precision p = O(log ∥B∥) in common applications...
we have published our implementation.