-- Dossier patient hospitalier : consultations, prescriptions, hospitalisations.
-- OLTP, avec des contraintes fortes vu la sensibilité du domaine.

CREATE TABLE service (
    id_service  SERIAL PRIMARY KEY,
    nom_service VARCHAR(100) NOT NULL,
    etage       SMALLINT
);

CREATE TABLE medecin (
    id_medecin   SERIAL PRIMARY KEY,
    nom          VARCHAR(80) NOT NULL,
    prenom       VARCHAR(80) NOT NULL,
    specialite   VARCHAR(80) NOT NULL,
    numero_rpps  VARCHAR(15) NOT NULL UNIQUE,
    id_service   INT NOT NULL REFERENCES service(id_service)
);

CREATE TABLE chambre (
    id_chambre     SERIAL PRIMARY KEY,
    numero_chambre VARCHAR(10) NOT NULL,
    type_chambre   VARCHAR(20) NOT NULL CHECK (type_chambre IN ('simple', 'double', 'soins_intensifs')),
    capacite       SMALLINT NOT NULL CHECK (capacite > 0),
    id_service     INT NOT NULL REFERENCES service(id_service)
);

CREATE TABLE patient (
    id_patient     SERIAL PRIMARY KEY,
    nom            VARCHAR(80) NOT NULL,
    prenom         VARCHAR(80) NOT NULL,
    date_naissance DATE NOT NULL,
    sexe           CHAR(1) CHECK (sexe IN ('M', 'F', 'X')),
    numero_secu    VARCHAR(15) NOT NULL UNIQUE,
    groupe_sanguin VARCHAR(3),
    telephone      VARCHAR(20),
    adresse        TEXT
);

CREATE TABLE consultation (
    id_consultation SERIAL PRIMARY KEY,
    date_heure      TIMESTAMP NOT NULL DEFAULT now(),
    motif           VARCHAR(200),
    diagnostic      TEXT,
    id_patient      INT NOT NULL REFERENCES patient(id_patient),
    id_medecin      INT NOT NULL REFERENCES medecin(id_medecin)
);

-- une prescription n'existe jamais sans consultation (traçabilité)
CREATE TABLE prescription (
    id_prescription   SERIAL PRIMARY KEY,
    date_prescription DATE NOT NULL DEFAULT CURRENT_DATE,
    id_consultation   INT NOT NULL REFERENCES consultation(id_consultation)
);

CREATE TABLE medicament (
    id_medicament   SERIAL PRIMARY KEY,
    nom_medicament  VARCHAR(150) NOT NULL,
    dosage_standard VARCHAR(50),
    forme           VARCHAR(30)
);

CREATE TABLE prescription_medicament (
    id_prescription INT NOT NULL REFERENCES prescription(id_prescription),
    id_medicament   INT NOT NULL REFERENCES medicament(id_medicament),
    posologie       VARCHAR(150) NOT NULL,
    duree_jours     SMALLINT NOT NULL CHECK (duree_jours > 0),
    PRIMARY KEY (id_prescription, id_medicament)
);

CREATE TABLE hospitalisation (
    id_hospitalisation    SERIAL PRIMARY KEY,
    date_entree           TIMESTAMP NOT NULL DEFAULT now(),
    date_sortie           TIMESTAMP,
    motif_hospitalisation TEXT,
    id_patient            INT NOT NULL REFERENCES patient(id_patient),
    id_chambre            INT NOT NULL REFERENCES chambre(id_chambre),
    id_service             INT NOT NULL REFERENCES service(id_service),
    CHECK (date_sortie IS NULL OR date_sortie >= date_entree)
);

CREATE INDEX idx_patient_secu ON patient(numero_secu);
CREATE INDEX idx_consultation_patient ON consultation(id_patient, date_heure);
-- chambres actuellement occupées : la requête la plus fréquente côté admissions
CREATE INDEX idx_hospitalisation_chambre_active ON hospitalisation(id_chambre) WHERE date_sortie IS NULL;
