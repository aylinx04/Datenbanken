-- einfache Select-Statements zum Anzeigen der Tabellen
SELECT * FROM Adresse;
SELECT * FROM Person;
SELECT * FROM Kunden;
SELECT * FROM Mitarbeiter;
SELECT * FROM Land;
SELECT * FROM Etappe; 
SELECT * FROM Reise;
SELECT * FROM buchen;
SELECT * FROM Unterkunft;
SELECT * FROM Transport;

-- Update: Sachgebiet der Mitarbeiter füllen
UPDATE Mitarbeiter
SET Sachgebiet = CASE
    WHEN Person_Id = 'M002' THEN 'Asienreisen'
    WHEN Person_Id = 'M004' THEN 'Europareise'
    WHEN Person_Id = 'M006' THEN 'Afrikareisen'
    WHEN Person_Id = 'M008' THEN 'Nordamerikareisen'
    ELSE Sachgebiet  -- Falls keine Übereinstimmung gefunden wird, bleibt der Wert unverändert
END
WHERE Person_Id IN ('M002', 'M004', 'M006', 'M008');

SELECT * FROM Mitarbeiter;

-- alle Reisen mit Teilnehmerzahl und Gesamtkosten anzeigen
SELECT Reise.Reise_Id, Reise.Teilnehmerzahl, Reise.Gesamtpreis
FROM Reise;

-- Joins

-- Reisen mit zugehörigen Etappen
SELECT R.Reise_Id, R.Teilnehmerzahl, E.Reiseziel, E.Startdatum, E.Enddatum
FROM Reise R
INNER JOIN Etappe E ON R.Reise_Id = E.Reise_Id;

-- Etappen mit Reiseziel und zugehörigem Land
SELECT E.Etappen_Id, E.Reiseziel, L.Staat AS Land
FROM Etappe E
INNER JOIN Land L ON E.Land_Id = L.Land_Id;

-- alle Personen und ihre Buchungen, auch wenn keine Buchung existiert
SELECT P.Person_Id, P.Name, P.Vorname, B.Reise_Id, B.Buchungsstatus
FROM Person P
LEFT JOIN buchen B ON P.Person_Id = B.Person_Id;

-- alle Etappen und ihre Transportmittel und Transportkosten, auch wenn kein Transport existiert
SELECT E.Etappen_Id, E.Reiseziel, T.Transportmittel, T.Transportkosten
FROM Etappe E
LEFT JOIN Transport T ON E.Etappen_Id = T.Etappen_Id;

-- Löschen einer Person
-- vor dem Löschen 
--SELECT * FROM Person WHERE Person_Id = 'K003';
SELECT * FROM Kunden WHERE Person_Id = 'K003';
SELECT * FROM Reise WHERE Person_Id = 'K003';
--SELECT * FROM buchen WHERE Person_Id = 'K003';
-- Löschen
DELETE FROM Person
WHERE Person_Id = 'K003';
-- nach dem Löschen
--SELECT * FROM Person WHERE Person_Id = 'K003';
SELECT * FROM Kunden WHERE Person_Id = 'K003';
SELECT * FROM Reise WHERE Person_Id = 'K003';
--SELECT * FROM buchen WHERE Person_Id = 'K003';

-- Aggregat
SELECT AVG (Teilnehmerzahl) FROM Reise;
SELECT COUNT (*) FROM Reise;
SELECT MAX (Unterkunftskosten) FROM Unterkunft;
SELECT MIN (Transportkosten) FROM Transport;
SELECT SUM (Etappenkosten) FROM Etappe;

-- Group By Beispiel, Sachgebiet mit Mitarbeiteranzahl
SELECT Sachgebiet, COUNT(Person_Id) AS Anzahl_Mitarbeiter
FROM Mitarbeiter
GROUP BY Sachgebiet;

--  geschachteltes Select-Statement, Reise mit höchstem Gesamtpreis
SELECT Reise_Id, Teilnehmerzahl, Gesamtpreis, 
       (SELECT Name FROM Person WHERE Person.Person_Id = Reise.Person_Id) AS Kunde
FROM Reise
WHERE Gesamtpreis = (SELECT MAX(Gesamtpreis) FROM Reise);

-- Erfolgreiche Transaktion
-- 444 hatte vorher eine Versicherung gebucht: hier wird es geändert
BEGIN Transaction;
UPDATE Reise SET Versicherung = FALSE WHERE Reise_Id = 444;
COMMIT;
SELECT * FROM Reise;

-- Abgebrochene Transaktion
-- Fehlerhafte Aktion: Vertauschte Werte für Hausnummer und PLZ
BEGIN Transaction;
INSERT INTO Adresse (Adress_Id, Straße, Hausnummer, PLZ, Stadt)
VALUES (9, 'Hauptstraße', 12345, '10', 'Berlin'); 
SELECT * FROM Adresse;
ROLLBACK;
SELECT * FROM Adresse;