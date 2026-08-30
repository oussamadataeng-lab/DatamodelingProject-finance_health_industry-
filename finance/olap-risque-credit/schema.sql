-- Entrepôt d'analyse du risque de crédit.
-- Schéma en étoile alimenté par ETL depuis les systèmes OLTP (dont finance/oltp-comptes-bancaires).
-- Grain : un prêt, un jour d'observation.

CREATE TABLE dim_temps (
    id_temps_sk    SERIAL PRIMARY KEY,
    date_complete  DATE NOT NULL UNIQUE,
    jour           SMALLINT NOT NULL,
    mois           SMALLINT NOT NULL,
    nom_mois       VARCHAR(15) NOT NULL,
    trimestre      SMALLINT NOT NULL,
    annee          SMALLINT NOT NULL
);

CREATE TABLE dim_agence (
    id_agence_sk SERIAL PRIMARY KEY,
    code_agence  VARCHAR(10) NOT NULL,
    nom_agence   VARCHAR(100) NOT NULL,
    ville        VARCHAR(80),
    region       VARCHAR(80)
);

CREATE TABLE dim_produit (
    id_produit_sk SERIAL PRIMARY KEY,
    code_produit  VARCHAR(15) NOT NULL,
    nom_produit   VARCHAR(100) NOT NULL,
    categorie     VARCHAR(50) NOT NULL
);

CREATE TABLE dim_segment_risque (
    id_segment_sk   SERIAL PRIMARY KEY,
    code_rating     CHAR(1) NOT NULL,
    libelle_rating  VARCHAR(50) NOT NULL,
    seuil_provision NUMERIC(5,2) NOT NULL
);

-- SCD type 2 : on garde l'historique des changements de segment client
CREATE TABLE dim_client (
    id_client_sk         SERIAL PRIMARY KEY,
    id_client_source     INT NOT NULL,  -- clé métier côté OLTP
    segment_clientele    VARCHAR(50),
    tranche_revenu       VARCHAR(30),
    region                VARCHAR(80),
    date_debut_validite   DATE NOT NULL,
    date_fin_validite     DATE,
    est_version_courante  BOOLEAN NOT NULL DEFAULT TRUE
);
CREATE INDEX idx_dim_client_source ON dim_client(id_client_source, est_version_courante);

CREATE TABLE fait_pret (
    id_client_sk        INT NOT NULL REFERENCES dim_client(id_client_sk),
    id_temps_sk         INT NOT NULL REFERENCES dim_temps(id_temps_sk),
    id_agence_sk        INT NOT NULL REFERENCES dim_agence(id_agence_sk),
    id_produit_sk        INT NOT NULL REFERENCES dim_produit(id_produit_sk),
    id_segment_sk         INT NOT NULL REFERENCES dim_segment_risque(id_segment_sk),
    montant_initial       NUMERIC(14,2) NOT NULL,
    montant_restant_du    NUMERIC(14,2) NOT NULL,
    montant_en_defaut     NUMERIC(14,2) NOT NULL DEFAULT 0,
    provision             NUMERIC(14,2) NOT NULL DEFAULT 0,
    score_risque          SMALLINT NOT NULL,
    indicateur_defaut     BOOLEAN NOT NULL DEFAULT FALSE,
    taux_interet          NUMERIC(5,3) NOT NULL,
    PRIMARY KEY (id_client_sk, id_temps_sk, id_produit_sk)
) PARTITION BY RANGE (id_temps_sk);

CREATE TABLE fait_pret_defaut PARTITION OF fait_pret DEFAULT;

CREATE INDEX idx_fait_pret_temps ON fait_pret(id_temps_sk);
CREATE INDEX idx_fait_pret_segment_temps ON fait_pret(id_segment_sk, id_temps_sk);
CREATE INDEX idx_fait_pret_agence_temps ON fait_pret(id_agence_sk, id_temps_sk);
