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


## Security and History

All tables in the schema suffixed with `_data` will have auto-generated `_history` and `_security` tables built from the schema provided in the `_data` table.
1. The `_history` table:
    1. The corresponding `_history` table will have the same columns as the `_data` table with the following modifications:
        1. The `_history` columns that track the `_data` columns will have the same name.
        1. They will not have `not null` constraints. Other columns in the `_history` table will, just not those from the `_data` table.
        1. They will not have foreign key constraints. Inserts into the `_history` table should never fail. The `_id` is the only primary key and it is auto-generated. The timestamp also has a default.
    1. The `_history` table will have additional columns that are unique to the `*_history` tables:
        1. An `_history_id serial primary key` column. This will keep track of the different versions of a `*_data` entry and is the only column that makes up the primary key.
        1. An `_history_created_at timestamp not null default CURRENT_TIMESTAMP` column. This keeps track of when thie history entry is added. It should not be modified, only the default value should be used.
1. The `_security` table:
    1. Will all have the columns of the `_data` table but the names will be prefaced with an underscore. So `name` becomes `_name`.
    1. Each column from the `_data` table will have the type `access_level`.
    1. There will two additional columns. One called `__person_id` and one called `__id` (double underscore).
    1. The `__person_id` column is `int not null` and represent the specific person that is being given access. It should have a foreign key constraint to `public.people(id)`.
    1. The `__id` column refers directly to the `id` column in the `_data` table and should have a foreign key constraint to that table (must be created dynamically based on the `_data` table).