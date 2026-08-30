-- Surveillance épidémiologique régionale.
-- Données déjà agrégées et anonymisées à l'ETL (aucune ligne patient ici, RGPD/santé oblige).
-- Grain : nombre de cas pour une pathologie, une région, une tranche d'âge, un jour donné.

CREATE TABLE dim_temps (
    id_temps_sk      SERIAL PRIMARY KEY,
    date_complete    DATE NOT NULL UNIQUE,
    semaine_epidemio SMALLINT NOT NULL,
    mois             SMALLINT NOT NULL,
    trimestre        SMALLINT NOT NULL,
    annee            SMALLINT NOT NULL
);

-- population_totale sert à calculer le taux d'incidence directement en requête
CREATE TABLE dim_region (
    id_region_sk      SERIAL PRIMARY KEY,
    code_region       VARCHAR(10) NOT NULL,
    nom_region        VARCHAR(100) NOT NULL,
    departement       VARCHAR(100),
    population_totale INT NOT NULL
);

CREATE TABLE dim_pathologie (
    id_pathologie_sk SERIAL PRIMARY KEY,
    code_cim10       VARCHAR(10) NOT NULL,
    nom_pathologie   VARCHAR(150) NOT NULL,
    categorie        VARCHAR(80)
);

CREATE TABLE dim_tranche_age (
    id_tranche_age_sk SERIAL PRIMARY KEY,
    libelle_tranche   VARCHAR(20) NOT NULL,
    age_min           SMALLINT NOT NULL,
    age_max           SMALLINT
);

CREATE TABLE dim_etablissement (
    id_etablissement_sk SERIAL PRIMARY KEY,
    nom_etablissement   VARCHAR(150) NOT NULL,
    type_etablissement  VARCHAR(50),
    region               VARCHAR(100)
);

CREATE TABLE fait_surveillance_epidemio (
    id_temps_sk           INT NOT NULL REFERENCES dim_temps(id_temps_sk),
    id_region_sk          INT NOT NULL REFERENCES dim_region(id_region_sk),
    id_pathologie_sk      INT NOT NULL REFERENCES dim_pathologie(id_pathologie_sk),
    id_tranche_age_sk     INT NOT NULL REFERENCES dim_tranche_age(id_tranche_age_sk),
    id_etablissement_sk   INT NOT NULL REFERENCES dim_etablissement(id_etablissement_sk),
    nombre_cas             INT NOT NULL DEFAULT 0,
    nombre_hospitalisations INT NOT NULL DEFAULT 0,
    nombre_deces            INT NOT NULL DEFAULT 0,
    nombre_vaccinations     INT NOT NULL DEFAULT 0,
    taux_incidence          NUMERIC(10,3),
    PRIMARY KEY (id_temps_sk, id_region_sk, id_pathologie_sk, id_tranche_age_sk, id_etablissement_sk)
) PARTITION BY RANGE (id_temps_sk);

CREATE TABLE fait_surveillance_epidemio_defaut PARTITION OF fait_surveillance_epidemio DEFAULT;

CREATE INDEX idx_fait_epidemio_region_temps ON fait_surveillance_epidemio(id_region_sk, id_temps_sk);
CREATE INDEX idx_fait_epidemio_pathologie_temps ON fait_surveillance_epidemio(id_pathologie_sk, id_temps_sk);
CREATE INDEX idx_fait_epidemio_tranche_age ON fait_surveillance_epidemio(id_tranche_age_sk);
