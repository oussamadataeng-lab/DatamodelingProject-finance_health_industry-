-- Comptes bancaires, cartes et transactions.
-- OLTP : normalisé, transactions courtes, index ciblés pour des lookups ponctuels.

CREATE TABLE agence (
    id_agence     SERIAL PRIMARY KEY,
    code_agence   VARCHAR(10) NOT NULL UNIQUE,
    nom_agence    VARCHAR(100) NOT NULL,
    ville         VARCHAR(80) NOT NULL
);

CREATE TABLE employe (
    id_employe     SERIAL PRIMARY KEY,
    nom            VARCHAR(80) NOT NULL,
    prenom         VARCHAR(80) NOT NULL,
    poste          VARCHAR(50) NOT NULL,
    date_embauche  DATE NOT NULL,
    id_agence      INT NOT NULL REFERENCES agence(id_agence)
);

CREATE TABLE client (
    id_client             SERIAL PRIMARY KEY,
    nom                   VARCHAR(80) NOT NULL,
    prenom                VARCHAR(80) NOT NULL,
    date_naissance        DATE NOT NULL,
    email                 VARCHAR(120) UNIQUE,
    telephone             VARCHAR(20),
    adresse               TEXT,
    id_employe_conseiller INT REFERENCES employe(id_employe)
);

CREATE TABLE compte (
    id_compte      SERIAL PRIMARY KEY,
    numero_compte  VARCHAR(34) NOT NULL UNIQUE,  -- IBAN
    type_compte    VARCHAR(20) NOT NULL CHECK (type_compte IN ('courant', 'epargne', 'professionnel')),
    solde          NUMERIC(14,2) NOT NULL DEFAULT 0,
    devise         CHAR(3) NOT NULL DEFAULT 'EUR',
    date_ouverture DATE NOT NULL DEFAULT CURRENT_DATE,
    statut         VARCHAR(15) NOT NULL DEFAULT 'actif' CHECK (statut IN ('actif', 'bloque', 'cloture')),
    id_agence      INT NOT NULL REFERENCES agence(id_agence)
);

-- compte joint : un compte peut avoir plusieurs titulaires
CREATE TABLE client_compte (
    id_client        INT NOT NULL REFERENCES client(id_client),
    id_compte        INT NOT NULL REFERENCES compte(id_compte),
    role_titulaire   VARCHAR(20) NOT NULL CHECK (role_titulaire IN ('principal', 'cotitulaire')),
    date_association DATE NOT NULL DEFAULT CURRENT_DATE,
    PRIMARY KEY (id_client, id_compte)
);

CREATE TABLE carte (
    id_carte        SERIAL PRIMARY KEY,
    numero_carte    VARCHAR(20) NOT NULL UNIQUE,  -- à tokeniser en prod
    type_carte      VARCHAR(15) NOT NULL CHECK (type_carte IN ('debit', 'credit')),
    date_expiration DATE NOT NULL,
    plafond         NUMERIC(10,2) NOT NULL,
    statut          VARCHAR(15) NOT NULL DEFAULT 'active' CHECK (statut IN ('active', 'bloquee', 'expiree')),
    id_compte       INT NOT NULL REFERENCES compte(id_compte)
);

-- id_compte_destination reste vide sauf pour les virements internes
CREATE TABLE transaction (
    id_transaction         BIGSERIAL,
    date_heure             TIMESTAMP NOT NULL DEFAULT now(),
    montant                NUMERIC(14,2) NOT NULL CHECK (montant > 0),
    type_transaction       VARCHAR(20) NOT NULL CHECK (type_transaction IN ('depot', 'retrait', 'virement', 'paiement')),
    libelle                VARCHAR(150),
    statut                 VARCHAR(15) NOT NULL DEFAULT 'validee' CHECK (statut IN ('en_attente', 'validee', 'rejetee')),
    id_compte_source       INT NOT NULL REFERENCES compte(id_compte),
    id_compte_destination  INT REFERENCES compte(id_compte),
    PRIMARY KEY (id_transaction, date_heure)  -- postgres exige la clé de partition dans la PK
) PARTITION BY RANGE (date_heure);

CREATE TABLE transaction_2026_08 PARTITION OF transaction
    FOR VALUES FROM ('2026-08-01') TO ('2026-09-01');
CREATE TABLE transaction_2026_09 PARTITION OF transaction
    FOR VALUES FROM ('2026-09-01') TO ('2026-10-01');

CREATE INDEX idx_compte_numero ON compte(numero_compte);
CREATE INDEX idx_transaction_compte_source ON transaction(id_compte_source, date_heure);
CREATE INDEX idx_transaction_compte_dest ON transaction(id_compte_destination, date_heure);
CREATE INDEX idx_client_email ON client(email);
