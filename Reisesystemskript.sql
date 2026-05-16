-- Tabellen erstellen
CREATE TABLE Adresse
    (Adress_Id      INTEGER PRIMARY KEY,
    Straße          VARCHAR(30) NOT NULL, 
    Hausnummer      VARCHAR(30) NOT NULL,
    PLZ             INTEGER NOT NULL,
    Stadt           VARCHAR(30) NOT NULL);

CREATE TABLE Person
    (Person_Id      VARCHAR(10) PRIMARY KEY,
    Name            VARCHAR(30) NOT NULL,
    Vorname         VARCHAR(30) NOT NULL,
    Email           VARCHAR(30) NOT NULL,
    TelefonNr       INTEGER,
    Adress_Id       INTEGER,
    FOREIGN KEY (Adress_Id) REFERENCES Adresse(Adress_Id) 
        ON DELETE CASCADE
        ON UPDATE CASCADE);

CREATE TABLE Kunden
    (Person_Id      VARCHAR(10) PRIMARY KEY,
    FOREIGN KEY (Person_Id) REFERENCES PERSON(Person_Id) 
        ON DELETE CASCADE 
        ON UPDATE CASCADE);

CREATE TABLE Mitarbeiter 
    (Person_Id VARCHAR(10) PRIMARY KEY,
    Sachgebiet VARCHAR(30) NOT NULL,
    FOREIGN KEY (Person_Id) REFERENCES PERSON(Person_Id) 
        ON DELETE CASCADE
        ON UPDATE CASCADE);

CREATE TABLE Land
	(Land_Id		    VARCHAR(2) PRIMARY KEY,
	Staat			    VARCHAR(30)	NOT NULL,
	Sprache		        VARCHAR(30)	NOT NULL,
	Waehrung		    VARCHAR(30)	NOT NULL,
	Preisklasse	        INTEGER	NOT NULL);
	
CREATE TABLE Unterkunft
	(Unterkunfts_Id	 	INTEGER	PRIMARY KEY,
	Unterkunftskosten 	FLOAT NOT NULL,
	Unterkunftsart		VARCHAR(30) NOT NULL,
	Klassifizierung		VARCHAR(8) NOT NULL,
	Verpflegung		    BOOLEAN	NOT NULL,
    Zimmer			    INTEGER	NOT NULL);  

CREATE TABLE Reise
	(Reise_Id			INTEGER PRIMARY KEY,
	Teilnehmerzahl		INTEGER NOT NULL,
	Buchungsdatum		TIMESTAMP NOT NULL,
	Versicherung		BOOLEAN	NOT NULL,
	Gesamtpreis			FLOAT,
	Person_Id 			VARCHAR(30),
	FOREIGN KEY (Person_Id) REFERENCES Person(Person_Id) 
        ON DELETE CASCADE
        ON UPDATE CASCADE);

CREATE TABLE Etappe
	(Etappen_Id		    INTEGER	PRIMARY KEY,
	Startdatum		    DATE NOT NULL,
	Enddatum		    DATE NOT NULL,
	Etappenkosten	    FLOAT,
	Reiseziel		    VARCHAR(30)	NOT NULL,
	Transfer		    BOOLEAN NOT NULL,
	Land_Id 		    VARCHAR(2),
	Unterkunfts_Id		INTEGER,
    Reise_Id            INTEGER,
    FOREIGN KEY (Land_Id) REFERENCES Land(Land_Id) 
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    FOREIGN KEY (Unterkunfts_Id) REFERENCES Unterkunft(Unterkunfts_Id)
        ON DELETE SET NULL
        ON UPDATE CASCADE,
    FOREIGN KEY (Reise_Id) REFERENCES Reise(Reise_Id)
        ON DELETE CASCADE
        ON UPDATE CASCADE);  

CREATE TABLE Transport
	(Transport_Id		INTEGER	PRIMARY KEY,
	Transportmittel		VARCHAR	NOT NULL,
	Start				DATE NOT NULL,
	Ende				DATE NOT NULL,
	Dauer				TIME NOT NULL,
	Zwischenstopp		INTEGER	NOT NULL,
	Transportkosten	 	FLOAT NOT NULL,
    Etappen_Id		    INTEGER,
    FOREIGN KEY (Etappen_Id) REFERENCES Etappe(Etappen_Id) 
        ON DELETE CASCADE
        ON UPDATE CASCADE); 

CREATE TABLE buchen
    (Reise_Id 		    INTEGER NOT NULL, 
    Buchungsstatus      VARCHAR(15) NOT NULL, 
    Person_Id 	        VARCHAR(30) NOT NULL, 
    PRIMARY KEY (Reise_Id, Person_Id), 
    FOREIGN KEY (Reise_Id) REFERENCES Reise(Reise_Id) 
        ON DELETE CASCADE
        ON UPDATE CASCADE, 
    FOREIGN KEY (Person_Id) REFERENCES Person(Person_Id) 
        ON DELETE CASCADE
        ON UPDATE CASCADE);

-- Trigger 1: Aktuelles Datum erstellen
CREATE OR REPLACE FUNCTION set_buchungsdatum()
RETURNS TRIGGER AS
$$
BEGIN
    NEW.Buchungsdatum := CURRENT_TIMESTAMP;  
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER t_set_buchungsdatum
BEFORE INSERT ON Reise
FOR EACH ROW
EXECUTE FUNCTION set_buchungsdatum();

-- Trigger 2: IDs Fallunterscheidung
CREATE OR REPLACE FUNCTION insert_customer_or_employee()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.Person_Id LIKE 'K%' THEN
        INSERT INTO Kunden (Person_Id) VALUES (NEW.Person_Id);
    ELSIF NEW.Person_Id LIKE 'M%' THEN
        INSERT INTO Mitarbeiter (Person_Id, Sachgebiet) 
        VALUES (NEW.Person_Id, 'Unbestimmt'); 
    END IF;
        RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER insert_customer_or_employee_trigger
AFTER INSERT ON Person
FOR EACH ROW
EXECUTE FUNCTION insert_customer_or_employee();

-- Trigger 3: Aktualisierung der Etappenkosten bei Änderungen an Transport
CREATE OR REPLACE FUNCTION update_etappenkosten_transport() RETURNS TRIGGER AS $$
BEGIN
    UPDATE Etappe
    SET Etappenkosten = (
        SELECT 
            COALESCE((SELECT SUM(T.Transportkosten) FROM Transport T WHERE T.Etappen_Id = Etappe.Etappen_Id), 0) 
            + COALESCE((SELECT U.Unterkunftskosten FROM Unterkunft U WHERE U.Unterkunfts_Id = Etappe.Unterkunfts_Id), 0)
    )
    WHERE Etappe.Etappen_Id = COALESCE(NEW.Etappen_Id, OLD.Etappen_Id);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_etappenkosten_transport
AFTER INSERT OR UPDATE OR DELETE ON Transport
FOR EACH ROW EXECUTE FUNCTION update_etappenkosten_transport();

-- Trigger 4: Aktualisierung der Etappenkosten bei Änderungen an Unterkunft
CREATE OR REPLACE FUNCTION update_etappenkosten_unterkunft() RETURNS TRIGGER AS $$
BEGIN
    UPDATE Etappe
    SET Etappenkosten = (
        SELECT 
            COALESCE((SELECT SUM(T.Transportkosten) FROM Transport T WHERE T.Etappen_Id = Etappe.Etappen_Id), 0) 
            + COALESCE((SELECT U.Unterkunftskosten FROM Unterkunft U WHERE U.Unterkunfts_Id = Etappe.Unterkunfts_Id), 0)
    )
    WHERE Etappe.Unterkunfts_Id = COALESCE(NEW.Unterkunfts_Id, OLD.Unterkunfts_Id);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_etappenkosten_unterkunft
AFTER INSERT OR UPDATE OR DELETE ON Unterkunft
FOR EACH ROW EXECUTE FUNCTION update_etappenkosten_unterkunft();

-- Trigger 5: Aktualisierung der Etappenkosten wenn eine Unterkunft zur Etappe hinzugefügt wird (Verknüpfung)
CREATE OR REPLACE FUNCTION update_etappenkosten_on_etappe_insert() RETURNS TRIGGER AS $$
BEGIN
    UPDATE Etappe
    SET Etappenkosten = (
        SELECT 
            COALESCE((SELECT SUM(T.Transportkosten) FROM Transport T WHERE T.Etappen_Id = Etappe.Etappen_Id), 0) 
            + COALESCE((SELECT U.Unterkunftskosten FROM Unterkunft U WHERE U.Unterkunfts_Id = Etappe.Unterkunfts_Id), 0)
    )
    WHERE Etappe.Etappen_Id = NEW.Etappen_Id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_etappenkosten_on_etappe_insert
AFTER INSERT ON Etappe
FOR EACH ROW EXECUTE FUNCTION update_etappenkosten_on_etappe_insert();

-- Trigger 6: zur Aktualisierung des Gesamtpreises einer Reise
CREATE OR REPLACE FUNCTION update_gesamtpreis() RETURNS TRIGGER AS $$
BEGIN
    UPDATE Reise
    SET Gesamtpreis = (
        SELECT SUM(E.Etappenkosten)
        FROM Etappe RE
        JOIN Etappe E ON E.Etappen_Id = RE.Etappen_Id
        WHERE RE.Reise_Id = (SELECT Reise_Id FROM Etappe WHERE Etappen_Id = NEW.Etappen_Id)
    )
    WHERE Reise.Reise_Id = (SELECT Reise_Id FROM Etappe WHERE Etappen_Id = NEW.Etappen_Id);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_gesamtpreis
AFTER UPDATE OF Etappenkosten ON Etappe
FOR EACH ROW EXECUTE FUNCTION update_gesamtpreis();

-- Inserts

-- Beispiel für einen INSERT in Adresse 
INSERT INTO Adresse(Adress_Id, Straße, Hausnummer, PLZ, Stadt)
VALUES (12, 'Kirchstrasse', '55', 2668, 'Flensburg');

INSERT INTO Adresse(Adress_Id, Straße, Hausnummer, PLZ, Stadt)
VALUES (13, 'Landstrasse', '2', 5832, 'Heidelberg');

-- Beispiel für einen INSERT in Person
INSERT INTO Person (Person_Id, Name, Vorname, Email, TelefonNr, Adress_Id)
VALUES ('K209', 'Schoeneberg', 'Valentina', 'vali@gmail.com', 777777, 12);

INSERT INTO Person (Person_Id, Name, Vorname, Email, TelefonNr, Adress_Id)
VALUES ('M2010', 'Schmidt', 'Peter', 'p.schmidt@gmail.com', 88888, 13);

INSERT INTO Adresse(Adress_Id, Straße, Hausnummer, PLZ, Stadt)
VALUES 
    (1, 'Knochenstraße', '3', 24111, 'Bremen'),
    (2, 'Sandstraße', '29', 29141, 'Bremen'),
    (3, 'Palaststraße', '16', 20221, 'Bremen'),
    (4, 'Schulstraße', '8', 22222, 'Hamburg'),
    (5, 'Taunusstraße', '7', 41321, 'Muenchen'),
    (6, 'Spandauerstraße', '5', 33123, 'Berlin'),
    (7, 'Baumstraße', '106', 52675, 'Essen');

INSERT INTO Person(Person_Id, Name, Vorname, Email, TelefonNr, Adress_Id)
VALUES 
    ('K001', 'Mueller', 'Klaus', 'muellerchen@gmail.com', 12345, 1),
    ('M002', 'Mustermann', 'Max', 'm.Mueller@gmail.com', 678910, 2),
    ('K003', 'Kruse', 'Otto', 'kruOtto@gmail.com', 111213, 3),
    ('M004', 'Lampe', 'Hannah','h.Lampe@gmail.com', 141516, 3),
    ('K005', 'Parker', 'Lisa','LiParker@gmail.com', 171819, 4),
    ('M006', 'Can','Selina', 'S.Can@gmail.com', 202123, 5),
    ('K007', 'Choi', 'Kai','choi.kai@gmail.com', 242526, 6),
    ('M008', 'Lomberg', 'Mareike','m.Lomberg@gmail.com', 282930, 7);

INSERT INTO Land(Land_Id, Staat, Sprache, Waehrung, Preisklasse)
VALUES
    ('AT', 'Oesterreich', 'deutsch', 'Euro', 2),
    ('FR', 'Frankreich', 'franzoesisch', 'Euro', 2),
    ('ES', 'Spanien', 'spanisch', 'Euro', 1),
    ('DE', 'Deutschland', 'deutsch', 'Euro', 2),
    ('GB', 'Vereinigtes Koenigreich', 'englisch', 'Pfund', 3),
    ('NL', 'Niederlande', 'niederlaendisch', 'Euro', 3),
    ('TR', 'Tuerkei', 'tuerkisch', 'Lira', 1),
    ('VN', 'Vietnam', 'vietnamesisch', 'Vietnamesischer Dong', 1);

INSERT INTO Unterkunft(Unterkunfts_Id, Unterkunftskosten, Unterkunftsart, Klassifizierung, Verpflegung, Zimmer)
VALUES
    (001, 250.00, 'Mietung', '3-Sterne', false, 1),
    (002, 280.00, 'Hotel', '5-Sterne', true, 1),
    (003, 200.00, 'Mietung', '2-Sterne', false, 3),
    (004, 830.00, 'Hotel', '1-Stern', true, 3),
    (005, 450.00, 'Mietung', '3-Sterne', false, 3),
    (006, 300.00, 'Hostel', '2-Sterne', false, 2),
    (007, 200, 'Hostel', '3-Sterne', false, 2),
    (008, 360, 'Hotel', '4-Sterne', true, 2);   

INSERT INTO Reise(Reise_Id, Teilnehmerzahl, Versicherung, Person_Id)
VALUES
    (444, 3, true, 'K001'),
    (445, 1, false, 'K003'),
    (446, 2, true, 'K005'),
    (447, 2, true, 'K007'); 

INSERT INTO Etappe(Etappen_Id, Startdatum, Enddatum, Reiseziel, Transfer, Land_Id, Unterkunfts_Id, Reise_Id)
VALUES
    (301, '2025-04-01', '2025-04-12', 'Wien', true, 'AT', 004, 444),
    (302, '2025-04-13', '2025-04-16', 'Paris', false, 'FR', 005, 444),
    (303, '2025-04-17', '2025-04-30', 'Madrid', true, 'ES', 003, 444),
    (401, '2025-07-01', '2025-07-12', 'Berlin', true, 'DE', 001, 445),
    (402, '2025-07-13', '2025-07-18', 'London', false, 'GB', 002, 445),
    (501, '2025-06-01', '2025-06-08', 'Amsterdam', false, 'NL', 006, 446),
    (502, '2025-06-09', '2025-06-20', 'Istanbul', false, 'TR', 007, 446),
    (601, '2025-07-01', '2025-07-12', 'Hanoi', true, 'VN', 008, 447);

INSERT INTO buchen(Reise_Id, Buchungsstatus, Person_Id)
VALUES
    (444, 'laeuft', 'K001'),
    (444, 'laeuft', 'M002'),
    (445, 'in_Bearbeitung', 'K003'),
    (445, 'in_Bearbeitung', 'M002'),
    (446, 'storniert', 'K005'),
    (447, 'laeuft', 'K007');

INSERT INTO Transport(Transport_Id, Transportmittel, Start, Ende, Dauer, Zwischenstopp, Transportkosten, Etappen_Id)
VALUES
    (010, 'Bus', '2025-04-01', '2025-04-01', '04:30:00', 0, 23.00, 301),
    (011, 'Bus', '2025-04-16', '2025-04-17', '06:30:00', 2, 27.79, 303),
    (012, 'Zug', '2025-07-01', '2025-07-01', '07:50:00', 2, 120.50, 401),
    (013, 'Flugzeug', '2025-06-09', '2025-06-09', '05:27:00', 0, 245.89, 502),
    (014, 'Zug', '2025-07-01', '2025-07-01', '06:07:00', 2, 99.50, 601);
