- element weise komprimieren
- günstige Daten, mittelgünstige Daten und ungünstige Daten erzeugen
- unkomprimiert -> komprimiert -> auf GPU -> auslesen -> Operation -> komprimiert zurückschreiben (kann auch neue Variable sein)

Ziele:
-> Verfahren kombinieren?
-> Berechnungen auf GPU
-> Abstraktion für erweiterte Berechnungen

18.01
für günstigen Fall: ruhig 10 mal gleiche Zahl nehmen
metadaten: struct, Funktionsparameter, array
-> schauen was schneller ist 

1.02.
Konzept + Implementierung für Load/store, Abstraktion:
auch zero-suppression möglich
innerhalb eines Arrays, statische bit-size
bit-packing,

Evulation mit beiden Schemata
Vergleich mit beiden und unkomprimiert 

8.2.
evaluation:
beide algorithmen
zero: von 1 bis 64 bit (größe der einzelnen Elemente)
run-length: nicht gute, okaye, sehr gute Daten

Abstraktion:
idee ist wichtig, implementierung nicht unbedingt 

22.2
Bitsize gleich für alle Werte


101010101011111000001010101010111110000010101010101111100000
000000000000000000001111111111000000000000000000000000000000
000000000000000000001010101010000000000000000000000000000000
000000000000000000000000000000000000000000000000001010101010
000000000000000000000000000000000000000000000000001010101011
000000000000000000001010101011000000000000000000000000000000

000000000000000000000000000000000000000000000000000000000000
000000000000000000001010101011000000000000000000000000000000

-atomic
-ein thread macht den rest

für addition:
outputbit gleich inputbit

uint64 in shared memory machen
Vergleich: shared vs global

__device functions
load/store
array operator [] =[]

welche funktionen, was brauchen Funktionen, welche Parameter