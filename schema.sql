-- Suivi de production type MES : ordres de fabrication, arrêts machine, mesures capteurs.
-- Beaucoup d'écritures fréquentes et de petite taille (flux IoT côté capteurs).

CREATE TABLE atelier (
    id_atelier   SERIAL PRIMARY KEY,
    nom_atelier  VARCHAR(100) NOT NULL,
    localisation VARCHAR(150)
);

CREATE TABLE machine (
    id_machine        SERIAL PRIMARY KEY,
    nom_machine       VARCHAR(100) NOT NULL,
    type_machine      VARCHAR(80) NOT NULL,
    date_mise_service DATE,
    statut            VARCHAR(20) NOT NULL DEFAULT 'en_service'
                          CHECK (statut IN ('en_service', 'en_panne', 'en_maintenance', 'arretee')),
    id_atelier        INT NOT NULL REFERENCES atelier(id_atelier)
);

CREATE TABLE operateur (
    id_operateur SERIAL PRIMARY KEY,
    nom          VARCHAR(80) NOT NULL,
    prenom       VARCHAR(80) NOT NULL,
    poste        VARCHAR(50),
    id_atelier   INT NOT NULL REFERENCES atelier(id_atelier)
);

CREATE TABLE produit (
    id_produit  SERIAL PRIMARY KEY,
    reference   VARCHAR(30) NOT NULL UNIQUE,
    designation VARCHAR(150) NOT NULL,
    unite       VARCHAR(10) NOT NULL DEFAULT 'unite'
);

CREATE TABLE ordre_fabrication (
    id_of               SERIAL PRIMARY KEY,
    numero_of           VARCHAR(30) NOT NULL UNIQUE,
    date_debut_prevue   TIMESTAMP NOT NULL,
    date_fin_prevue     TIMESTAMP,
    quantite_a_produire INT NOT NULL CHECK (quantite_a_produire > 0),
    statut              VARCHAR(20) NOT NULL DEFAULT 'planifie'
                            CHECK (statut IN ('planifie', 'en_cours', 'termine', 'annule')),
    id_produit          INT NOT NULL REFERENCES produit(id_produit),
    id_machine          INT NOT NULL REFERENCES machine(id_machine)
);

CREATE TABLE lot_production (
    id_lot            SERIAL PRIMARY KEY,
    quantite_produite INT NOT NULL DEFAULT 0,
    quantite_rebut    INT NOT NULL DEFAULT 0,
    date_production   TIMESTAMP NOT NULL DEFAULT now(),
    id_of             INT NOT NULL REFERENCES ordre_fabrication(id_of),
    id_operateur      INT NOT NULL REFERENCES operateur(id_operateur)
);

CREATE TABLE arret_machine (
    id_arret         SERIAL PRIMARY KEY,
    date_heure_debut TIMESTAMP NOT NULL,
    date_heure_fin   TIMESTAMP,
    cause            VARCHAR(30) NOT NULL
                         CHECK (cause IN ('panne', 'changement_serie', 'maintenance_preventive', 'pause', 'autre')),
    id_machine       INT NOT NULL REFERENCES machine(id_machine)
);

-- flux capteur à fort volume : clé composite + partitionnement par jour/mois
CREATE TABLE mesure_capteur (
    id_mesure   BIGSERIAL,
    date_heure  TIMESTAMP NOT NULL DEFAULT now(),
    type_mesure VARCHAR(30) NOT NULL CHECK (type_mesure IN ('temperature', 'vibration', 'pression', 'vitesse')),
    valeur      NUMERIC(10,3) NOT NULL,
    id_machine  INT NOT NULL REFERENCES machine(id_machine),
    PRIMARY KEY (id_mesure, date_heure)
) PARTITION BY RANGE (date_heure);

CREATE TABLE mesure_capteur_2026_08 PARTITION OF mesure_capteur
    FOR VALUES FROM ('2026-08-01') TO ('2026-09-01');

CREATE INDEX idx_of_machine_statut ON ordre_fabrication(id_machine, statut);
CREATE INDEX idx_lot_of ON lot_production(id_of);
CREATE INDEX idx_arret_machine_periode ON arret_machine(id_machine, date_heure_debut);
CREATE INDEX idx_mesure_machine_date ON mesure_capteur(id_machine, date_heure);
