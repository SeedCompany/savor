# Savor

Experiment in a common Postgres DB for DA/DevOps

# API

- Create an application.conf file in the apiMain resources folder. Look at the Config service for its structure. Here is a sample:

savor {
postgres {
url = ""
database = ""
user = ""
password = ""
}
neo4j {
url = ""
database = ""
user = ""
password = ""
}
}

## Todo

Currently using the blocking JDBC driver for Postgres. Need to upgrade to a non-blocking lib.

## Database Design Principles

1. Multi-tenancy first. There are system tables (`sys_*`) that share common entities/properties between orgs and org-specific tables (e.g. `sc_*`) that are used by just one org.
2. Tenants extend system tables when able. System tables store columns shared by multiple orgs. When a single org needs more data associated with a system entity, it's new table should extend/reference the system table and not duplicate columns.
3. The system security concept should be the only concept used by all orgs. It enables field-level permissions but requires each role to only have one set of column + row definition per role.
4. Read performance is an important design principle. Where possible, materialized views or denormalized data tables should be used to increase read performance.
5. The database must have a schema-ed record of all changes to it. The schema must be configured in such a way that queries can be written to search for historical data on any column. `*_history` tables are used for this.
6. ID fields are verbosely named and must carry there long name whenever another table references them. For example, if another table references a partner org, instead of calling the field 'partner', or 'partner_id', it must be called 'partner_sys_group_id', because the 'sys_group_id' is the name of the field on the referenced table. This only applies to ID fields.
7. Security is accomplished by using the org, role, and project memberhsip tables and grants tables to populate `*_security` tables. The `*_security` tables are then combined with the data tables to populate the `*_secure_view` tables. The `*_secure_view` tables provide secure read access when a `user_id` is provided.
