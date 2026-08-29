# Comptes bancaires — OLTP

Base transactionnelle d'une banque : ouverture de comptes (parfois joints), cartes associées, et chaque mouvement (dépôt, retrait, virement, paiement) enregistré en temps réel. Le point sensible : un virement doit débiter et créditer dans la même transaction, sans jamais perdre de cohérence.

## MCD

```mermaid
erDiagram
    CLIENT ||--o{ CLIENT_COMPTE : possède
    COMPTE ||--o{ CLIENT_COMPTE : "est possédé par"
    AGENCE ||--o{ COMPTE : gère
    AGENCE ||--o{ EMPLOYE : emploie
    EMPLOYE |o--o{ CLIENT : conseille
    COMPTE ||--o{ CARTE : possède
    COMPTE ||--o{ TRANSACTION : "est source de"
    COMPTE |o--o{ TRANSACTION : "est destinataire de"
```

| Entité 1 | Association | Entité 2 | Card. E1 | Card. E2 |
|---|---|---|---|---|
| CLIENT | POSSEDE | COMPTE | 0,n | 1,n |
| AGENCE | GERE | COMPTE | 1,n | 1,1 |
| AGENCE | EMPLOIE | EMPLOYE | 1,n | 1,1 |
| EMPLOYE | CONSEILLE | CLIENT | 0,n | 0,1 |
| COMPTE | EMET_CARTE | CARTE | 1,1 | 0,n |
| COMPTE | EST_SOURCE | TRANSACTION | 1,1 | 0,n |
| COMPTE | EST_DESTINATAIRE | TRANSACTION | 0,1 | 0,n |

CLIENT–COMPTE est une association porteuse (many-to-many, avec `role_titulaire`) : elle donnera une table à part entière au niveau logique.

## MLD

```mermaid
erDiagram
    CLIENT {
        int id_client PK
        string nom
        string prenom
        date date_naissance
        string email
        int id_employe_conseiller FK
    }
    CLIENT_COMPTE {
        int id_client PK,FK
        int id_compte PK,FK
        string role_titulaire
    }
    COMPTE {
        int id_compte PK
        string numero_compte
        string type_compte
        decimal solde
        int id_agence FK
    }
    AGENCE {
        int id_agence PK
        string code_agence
        string nom_agence
    }
    EMPLOYE {
        int id_employe PK
        string nom
        int id_agence FK
    }
    CARTE {
        int id_carte PK
        string numero_carte
        string type_carte
        int id_compte FK
    }
    TRANSACTION {
        int id_transaction PK
        datetime date_heure
        decimal montant
        string type_transaction
        int id_compte_source FK
        int id_compte_destination FK
    }

    CLIENT ||--o{ CLIENT_COMPTE : ""
    COMPTE ||--o{ CLIENT_COMPTE : ""
    AGENCE ||--o{ COMPTE : ""
    AGENCE ||--o{ EMPLOYE : ""
    EMPLOYE |o--o{ CLIENT : ""
    COMPTE ||--o{ CARTE : ""
    COMPTE ||--o{ TRANSACTION : source
```

Schéma normalisé (3FN) : `client_compte` absorbe le many-to-many, `transaction` porte deux FK vers `compte` (source obligatoire, destination optionnelle pour les virements internes).

## MPD

→ [`schema.sql`](schema.sql), testé sur PostgreSQL 16.

Points notables du physique :
- `transaction` est partitionnée par mois (`date_heure`) — le volume d'écritures y est le plus élevé, et ça facilite l'archivage/l'extraction vers l'entrepôt du projet `finance/olap-risque-credit`.
- Index limités aux besoins opérationnels réels (numéro de compte, historique par compte) plutôt qu'à tout ce qui pourrait servir un jour — chaque index a un coût à l'écriture.
- Les `CHECK` sur `statut` et `type_*` remplacent des tables de référence pour rester simple ; à faire évoluer en tables si la liste des valeurs grandit.
