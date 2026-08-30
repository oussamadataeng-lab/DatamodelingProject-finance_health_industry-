-- Entrepôt de performance industrielle (TRS/OEE).
-- Alimenté par ETL depuis le MES (industrie/oltp-gestion-production) : arrêts, lots, mesures capteurs
-- sont agrégés ici en indicateurs de pilotage, par machine/équipe/poste de travail.

CREATE TABLE dim_temps (
    id_temps_sk   SERIAL PRIMARY KEY,
    date_complete DATE NOT NULL,
    poste_shift   VARCHAR(15) NOT NULL CHECK (poste_shift IN ('matin', 'apres_midi', 'nuit')),
    semaine       SMALLINT NOT NULL,
    mois          SMALLINT NOT NULL,
    annee         SMALLINT NOT NULL,
    UNIQUE (date_complete, poste_shift)
);

CREATE TABLE dim_machine (
    id_machine_sk        SERIAL PRIMARY KEY,
    nom_machine          VARCHAR(100) NOT NULL,
    type_machine         VARCHAR(80),
    capacite_nominale_h  NUMERIC(10,2) NOT NULL
);

CREATE TABLE dim_atelier (
    id_atelier_sk SERIAL PRIMARY KEY,
    nom_atelier   VARCHAR(100) NOT NULL,
    localisation  VARCHAR(150)
);

CREATE TABLE dim_produit (
    id_produit_sk SERIAL PRIMARY KEY,
    reference     VARCHAR(30) NOT NULL,
    designation   VARCHAR(150) NOT NULL
);

CREATE TABLE dim_equipe (
    id_equipe_sk SERIAL PRIMARY KEY,
    nom_equipe   VARCHAR(50) NOT NULL,
    responsable  VARCHAR(100)
);

CREATE TABLE dim_cause_arret (
    id_cause_arret_sk SERIAL PRIMARY KEY,
    code_cause        VARCHAR(20) NOT NULL,
    libelle_cause     VARCHAR(150) NOT NULL,
    categorie         VARCHAR(50)
);

CREATE TABLE fait_performance_machine (
    id_temps_sk                  INT NOT NULL REFERENCES dim_temps(id_temps_sk),
    id_machine_sk                INT NOT NULL REFERENCES dim_machine(id_machine_sk),
    id_atelier_sk                INT NOT NULL REFERENCES dim_atelier(id_atelier_sk),
    id_produit_sk                INT NOT NULL REFERENCES dim_produit(id_produit_sk),
    id_equipe_sk                 INT NOT NULL REFERENCES dim_equipe(id_equipe_sk),
    id_cause_arret_sk            INT REFERENCES dim_cause_arret(id_cause_arret_sk),
    temps_ouverture_min          INT NOT NULL,
    temps_arret_planifie_min     INT NOT NULL DEFAULT 0,
    temps_arret_non_planifie_min INT NOT NULL DEFAULT 0,
    temps_fonctionnement_min     INT NOT NULL,
    quantite_produite             INT NOT NULL DEFAULT 0,
    quantite_conforme             INT NOT NULL DEFAULT 0,
    quantite_rebut                INT NOT NULL DEFAULT 0,
    taux_disponibilite            NUMERIC(5,2),
    taux_performance               NUMERIC(5,2),
    taux_qualite                    NUMERIC(5,2),
    trs                              NUMERIC(5,2),
    PRIMARY KEY (id_temps_sk, id_machine_sk, id_equipe_sk)
) PARTITION BY RANGE (id_temps_sk);

CREATE TABLE fait_performance_machine_defaut PARTITION OF fait_performance_machine DEFAULT;

CREATE INDEX idx_fait_perf_machine_temps ON fait_performance_machine(id_machine_sk, id_temps_sk);
CREATE INDEX idx_fait_perf_atelier_temps ON fait_performance_machine(id_atelier_sk, id_temps_sk);
CREATE INDEX idx_fait_perf_cause_arret ON fait_performance_machine(id_cause_arret_sk);
