# Savor

Experiment in a common Postgres DB for DA/DevOps

## API Setup

- Create src/main/resources/application.yml with the following structure. Replace values as needed.

```
postgres:
    url: jdbc:postgresql://localhost
    database: postgres
    user: postgres
    password: admin
    port: 5432
neo4j:
  url: bolt://localhost:7687
  database: neo4j
  user: neo4j
  password: test
```

## Database Design Principles

1. Multi-tenancy first. There are system tables (`sys_*`) that share common entities/properties between orgs and org-specific tables (e.g. `sc_*`) that are used by just one org.
1. Tenants extend system tables when able. System tables store columns shared by multiple orgs. When a single org needs more data associated with a system entity, it's new table should extend/reference the system table and not duplicate columns.
1. The system security concept should be the only concept used by all orgs. It enables field-level permissions on any data table.  
1. Read performance is an important design principle. Where possible, materialized views or denormalized data tables should be used to increase read performance.
1. The database must have a schema-ed record of all changes to it. The schema must be configured in such a way that queries can be written to search for historical data on any column. `*_history` tables are used for this.
1. Security is accomplished by using the org, role, sensitivity clearance, and project membership tables and grants tables to populate `*_security` tables. The `*_security` tables are then combined with the data tables to populate the `*_secure_view` tables. The `*_secure_view` tables provide secure read access when a `user_id` is provided.
