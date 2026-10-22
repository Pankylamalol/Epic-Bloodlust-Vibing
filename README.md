# Epic Bloodlust Vibing

Addon pro WoW Retail, který přehraje náhodně vybranou skladbu při aktivaci
Bloodlustu nebo obdobného efektu.

Rozpoznává Bloodlust, Heroism, Time Warp, Ancient Hysteria, Netherwinds,
Primal Rage, Fury of the Aspects a bubny Drums of Rage, Drums of Fury,
Drums of the Mountain, Drums of the Maelstrom, Drums of Deathly Ferocity,
Harrier's Cry a Void-Touched Drums.

## Přidání skladeb

V tomto adresáři addonu je složka `sounds` se skladbou `song1.ogg`.
Další skladby můžeš přidat do stejné složky a jejich názvy doplnit do seznamu
`tracks` v souboru `Epic Bloodlust Vibing.lua`. Použij zvukové soubory OGG.

## Testování

Příkazem `/epicbloodlustvibing test` ve hře otestuješ přehrání náhodné skladby.

## Nastavení

Příkazem `/epicbloodlustvibing` (nebo zkráceně `/ebv`) otevřeš okno nastavení.
V něm můžeš zapnout či vypnout automatické přehrávání při Bloodlustu a zvolit
zvukový kanál. Hlasitost určuje příslušný posuvník v nastavení zvuku WoW:
Master, Music, Ambience, SFX nebo Dialog.

Addon sleduje auru lustu i navazující debuffy (Sated, Exhaustion, Temporal
Displacement aj.) přímo na hráči, protože combat log je v nových patchích pro
addony omezený. Combat log se používá jen jako záloha. 40sekundová ochrana
zabrání opakovanému přehrání.
