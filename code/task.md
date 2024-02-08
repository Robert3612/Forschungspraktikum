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

12.2 doch nicht, erst wieder 22.2.