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


12.2., 12:30 Treffen