# Risque de crédit — OLAP

Entrepôt pour la direction des risques : évolution du portefeuille de prêts, taux de défaut par segment/produit/agence/période, calcul des provisions. Alimenté par ETL nocturne depuis les systèmes OLTP (dont `finance/oltp-comptes-bancaires`) — aucune écriture interactive ici, que des lectures agrégées.

Grain retenu : **un prêt, un jour d'observation**.

## Modèle conceptuel (étoile)

```mermaid
erDiagram
    FAIT_PRET }o--|| DIM_CLIENT : concerne
    FAIT_PRET }o--|| DIM_TEMPS : "observé le"
    FAIT_PRET }o--|| DIM_AGENCE : origine
    FAIT_PRET }o--|| DIM_PRODUIT : "type de produit"
    FAIT_PRET }o--|| DIM_SEGMENT_RISQUE : "classé en"
```

Toutes les dimensions sont en 1,n vers le fait. On modélise ici des axes d'analyse, pas des règles de gestion — c'est la différence avec un MCD côté OLTP.

## Modèle logique

```mermaid
erDiagram
    FAIT_PRET {
        int id_client_sk FK
        int id_temps_sk FK
        int id_agence_sk FK
        int id_produit_sk FK
        int id_segment_sk FK
        decimal montant_restant_du
        decimal provision
        int score_risque
        boolean indicateur_defaut
    }
    DIM_CLIENT {
        int id_client_sk PK
        int id_client_source
        string segment_clientele
        date date_debut_validite
        date date_fin_validite
        boolean est_version_courante
    }
    DIM_TEMPS {
        int id_temps_sk PK
        date date_complete
        int mois
        int trimestre
        int annee
    }
    DIM_AGENCE {
        int id_agence_sk PK
        string code_agence
        string region
    }
    DIM_PRODUIT {
        int id_produit_sk PK
        string code_produit
        string categorie
    }
    DIM_SEGMENT_RISQUE {
        int id_segment_sk PK
        string code_rating
        decimal seuil_provision
    }

    FAIT_PRET }o--|| DIM_CLIENT : ""
    FAIT_PRET }o--|| DIM_TEMPS : ""
    FAIT_PRET }o--|| DIM_AGENCE : ""
    FAIT_PRET }o--|| DIM_PRODUIT : ""
    FAIT_PRET }o--|| DIM_SEGMENT_RISQUE : ""
```

Deux choix qui font la différence avec le modèle OLTP :

- **clés de substitution** (`*_sk`) plutôt que les clés métier, pour pouvoir historiser sans dépendre du système source ;
- **`dim_client` en SCD2** — on garde la trace du segment de risque du client à chaque date d'observation, ce qui serait inutile (et coûteux) côté transactionnel où seul l'état courant compte.

## Physique

→ [`schema.sql`](schema.sql).

`fait_pret` est partitionnée par `id_temps_sk`, avec les dimensions de référence (agence, produit, segment) volontairement petites et dénormalisées pour rester bon marché à joindre. Le schéma est délibérément redondant par rapport au 3FN du système source : ici on optimise la lecture, pas l'espace disque.
