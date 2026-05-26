# Datenbanken

## Übersicht

In diesem Modul, wurde in Gruppenarbeit eine Datenbank für ein Reisesystem realisiert. Hierfür wurde mit einem ER-Modul, Entitäten, Beziehungstypen und Triggern. 

## ER-Modell
[ER_Modell_Reisesystem.pdf](https://github.com/user-attachments/files/28256491/ER_Modell_Reisesystem.pdf)

In diesem ER-Modell sieht man in den Rechtecken die Entitäten, in den Kreisen die Attribute, wobei die dickgedruckten Attribute die Primärschlüssel sind und die Linien die Beziehungen zwischen den Entitäten darstellt.


## Das Relationale Modell

Hier sieht man das Relationale Modell, welches zeigt wie die Tabellen in der Datenbank aussehen würde.

### Person

| Person-Id | Name       | Vorname | Email                                                 | TelefonNr | Adress-Id |
| --------- | ---------- | ------- | ----------------------------------------------------- | --------- | --------- |
| K001      | Müller     | Klaus   | [muellerchen@gmail.com](mailto:muellerchen@gmail.com) | 12345     | 1         |
| M002      | Mustermann | Max     | [m.Mueller@gmail.com](mailto:m.Mueller@gmail.com)     | 678910    | 2         |
| K003      | Kruse      | Otto    | [kruOtto@gmail.com](mailto:kruOtto@gmail.com)         | 111213    | 3         |
| M004      | Lampe      | Hannah  | [h.Lampe@gmail.com](mailto:h.Lampe@gmail.com)         | 141516    | 3         |
| K005      | Parker     | Lisa    | [LiParker@gmail.com](mailto:LiParker@gmail.com)       | 171819    | 4         |
| M006      | Can        | Selina  | [S.Can@gmail.com](mailto:S.Can@gmail.com)             | 202123    | 5         |
| K007      | Choi       | Kai     | [choi.kai@gmail.com](mailto:choi.kai@gmail.com)       | 242526    | 6         |
| M008      | Lomberg    | Mareike | [m.Lomberg@gmail.com](mailto:m.Lomberg@gmail.com)     | 282930    | 7         |


### Adresse

| Adress-Id | Straße           | Hausnummer | PLZ   | Ort      |
| --------- | ---------------- | ---------- | ----- | -------- |
| 1         | Knochenstraße    | 3          | 24111 | Bremen   |
| 2         | Sandstraße       | 29         | 29141 | Bremen   |
| 3         | Palaststraße     | 16         | 20221 | Bremen   |
| 4         | Schulstraße      | 8          | 22222 | Hamburg  |
| 5         | Taunusstraße     | 7          | 41321 | Muenchen |
| 6         | Spandauer Straße | 5          | 33123 | Berlin   |
| 7         | Baumstraße       | 106        | 52675 | Essen    |

### Kunde

| Person-Id |
| --------- |
| K209      |
| K001      |
| K003      |
| K005      |
| K007      |


### Mitarbeiter

| Person-Id | Sachgebiet         |
| --------- | ------------------ |
| M2010     | Unbestimmt         |
| M002      | Asienreisen        |
| M004      | Europareisen       |
| M006      | Afrikareisen       |
| M008      | Nordamerika Reisen |


### buchen

| Reise-Id | Buchungsstatus | Person-Id |
| -------- | -------------- | --------- |
| 444      | laeuft         | K001      |
| 444      | laeuft         | M002      |
| 445      | in Bearbeitung | M002      |
| 445      | in Bearbeitung | K003      |
| 446      | storniert      | K005      |
| 447      | laeuft         | K007      |


### Reise

| Reise-Id | Teilnehmerzahl | Buchungsdatum              | Versicherung | Gesamtpreis | Person-Id |
| -------- | -------------- | -------------------------- | ------------ | ----------- | --------- |
| 444      | 3              | 2025-02-12 17:55:09:804981 | true         | 1530.79     | K001      |
| 445      | 1              | 2025-02-12 17:55:09:804981 | false        | 650.50      | K003      |
| 446      | 2              | 2025-02-12 17:55:09:804981 | true         | 745.89      | K005      |
| 447      | 2              | 2025-02-12 17:55:09:804981 | true         | 459.50      | K007      |


### Land

| Land-Id | Staat                   | Sprache          | Waehrung             | Preisklasse |
| ------- | ----------------------- | ---------------- | -------------------- | ----------- |
| AT      | Oesterreich             | deutsch          | Euro                 | 2           |
| FR      | Frankreich              | franzoesisch     | Euro                 | 2           |
| ES      | Spanien                 | spanisch         | Euro                 | 1           |
| DE      | Deutschland             | deutsch          | Euro                 | 2           |
| GB      | Vereinigtes Koenigreich | englisch         | Pfund                | 3           |
| NL      | Niederlande             | niederlaendlisch | Euro                 | 3           |
| TR      | Tuerkei                 | tuerkisch        | Lira                 | 1           |
| VN      | Vietnam                 | vietnamesisch    | Vietnamesischer Dong | 1           |


### Etappe

| Etappen-Id | Startdatum | Enddatum   | Reiseziel | Etappenkosten | Transfer | Land-Id | Unterkunfts-Id | Reise-Id |
| ---------- | ---------- | ---------- | --------- | ------------- | -------- | ------- | -------------- | -------- |
| 301        | 2025-04-01 | 2025-04-12 | Wien      | 853           | true     | AT      | 4              | 444      |
| 302        | 2025-04-13 | 2025-04-16 | Paris     | 450           | false    | FR      | 5              | 444      |
| 303        | 2025-04-17 | 2025-04-30 | Madrid    | 227.79        | true     | ES      | 3              | 444      |
| 401        | 2025-07-01 | 2025-07-12 | Berlin    | 370.5         | true     | DE      | 1              | 445      |
| 402        | 2025-07-13 | 2025-07-18 | London    | 280           | false    | GB      | 2              | 445      |
| 501        | 2025-06-01 | 2025-06-08 | Amsterdam | 300           | false    | NL      | 6              | 446      |
| 502        | 2025-06-09 | 2025-06-20 | Istanbul  | 445.89        | false    | TR      | 7              | 446      |
| 601        | 2025-07-01 | 2025-07-12 | Hanoi     | 459.5         | true     | VN      | 8              | 447      |


### Transport

| Transport-Id | Transportmittel | Start      | Ende       | Dauer    | Zwischenstopp | Transportkosten | Etappen-Id |
| ------------ | --------------- | ---------- | ---------- | -------- | ------------- | --------------- | ---------- |
| 010          | Bus             | 2025-04-01 | 2025-04-01 | 04:30:00 | 0             | 23.00           | 301        |
| 011          | Bus             | 2025-04-16 | 2025-04-17 | 06:30:00 | 2             | 27.79           | 303        |
| 012          | Zug             | 2025-07-01 | 2025-07-01 | 07:50:00 | 2             | 120.50          | 401        |
| 013          | Flugzeug        | 2025-06-09 | 2025-06-09 | 05:27:00 | 0             | 245.89          | 502        |
| 014          | Zug             | 2025-07-01 | 2025-07-01 | 06:07:00 | 2             | 99.50           | 601        |

## Benotung

Für dieses Projekt wurde die Note 1,7 erreicht.

