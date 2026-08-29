# Méthodologie

## Merise : conceptuel, logique, physique

**MCD (conceptuel)** — on liste les entités du métier, leurs associations et les cardinalités, sans penser au SGBD. C'est la vue "métier".

**MLD (logique)** — on traduit le MCD en tables relationnelles : les associations n,n deviennent des tables associatives, les 1,n deviennent des clés étrangères. Pour un système OLTP on vise la 3ème forme normale (pas de redondance). Pour un entrepôl OLAP on part directement sur un schéma en étoile (table de faits + dimensions), volontairement dénormalisé.

**MPD (physique)** — on choisit les types concrets, les contraintes, les index, le partitionnement, et on écrit le DDL pour un SGBD précis (PostgreSQL ici).

## OLTP vs OLAP

| | OLTP | OLAP |
|---|---|---|
| Rôle | enregistrer l'activité au fil de l'eau | analyser l'historique |
| Modèle | normalisé (3FN) | étoile / flocon (dénormalisé) |
| Opérations | beaucoup d'INSERT/UPDATE, transactions courtes | gros SELECT avec agrégations |
| Volumétrie par requête | quelques lignes | millions de lignes |
| Historique | souvent juste l'état courant | historisé (SCD, dimension temps) |
| Alimentation | saisie utilisateur en direct | ETL/ELT batch depuis les sources OLTP |

Dans les projets ci-dessus, chaque paire OLTP/OLAP porte sur le même domaine : le système transactionnel capture l'activité, l'entrepôt l'agrège pour le pilotage. Concrètement, l'entrepôt finance se nourrit (entre autres) du système bancaire OLTP, l'entrepôt santé des données hospitalières, l'entrepôt industriel du MES.

## Notation

Les diagrammes sont en Mermaid (`erDiagram`), lisibles directement sur GitHub. Comme Mermaid ne distingue pas nativement 0,n de 1,n, chaque README détaille les cardinalités Merise dans un tableau à côté du diagramme.
