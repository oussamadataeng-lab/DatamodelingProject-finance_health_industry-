# Data modeling — finance, santé, industrie

Six petits projets de modélisation de données, un peu comme des exercices pratiques. Le point de départ : prendre trois domaines qui n'ont rien à voir (une banque, un hôpital, une usine) et, pour chacun, construire deux bases qui ne se ressemblent pas du tout — une base "métier" qui encaisse les opérations du quotidien (OLTP), et un entrepôt fait pour analyser tout ça après coup (OLAP).

Pour chaque projet j'ai suivi la même démarche en trois temps, la méthode Merise si on veut lui donner un nom : d'abord repérer les entités et comment elles se relient (le conceptuel), ensuite traduire ça en tables avec clés primaires et étrangères (le logique), et enfin écrire le vrai SQL avec les types, contraintes et index (le physique, dans `schema.sql`, testé sur PostgreSQL).

L'objectif n'est pas d'avoir un système prêt pour la prod, mais de montrer sur des cas concrets pourquoi une base qui enregistre des transactions ne se modélise pas du tout comme une base faite pour repérer des tendances sur plusieurs années.

## Projets

| Domaine | Type | Dossier | Sujet |
|---|---|---|---|
| Finance | OLTP | [`finance/oltp-comptes-bancaires`](finance/oltp-comptes-bancaires) | comptes, cartes, transactions |
| Finance | OLAP | [`finance/olap-risque-credit`](finance/olap-risque-credit) | entrepôt risque de crédit |
| Santé | OLTP | [`sante/oltp-dossier-patient`](sante/oltp-dossier-patient) | dossier patient, consultations, prescriptions |
| Santé | OLAP | [`sante/olap-epidemiologie`](sante/olap-epidemiologie) | entrepôt de surveillance épidémiologique |
| Industrie | OLTP | [`industrie/oltp-gestion-production`](industrie/oltp-gestion-production) | suivi de production type MES |
| Industrie | OLAP | [`industrie/olap-performance-industrielle`](industrie/olap-performance-industrielle) | entrepôt TRS/OEE |

Voir [`docs/methodologie.md`](docs/methodologie.md) pour le détail de la démarche (Merise + OLTP vs OLAP).

## Structure d'un projet

```
<projet>/
├── README.md    # contexte, MCD, MLD (diagrammes Mermaid + cardinalités)
└── schema.sql    # DDL exécutable (volet physique)
```

## Tester un schéma

Chaque `schema.sql` a été validé sur PostgreSQL 16.

```bash
createdb demo
psql -d demo -f finance/oltp-comptes-bancaires/schema.sql
```

## Licence

MIT, voir [LICENSE](LICENSE).
