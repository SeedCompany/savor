# Savor

Experiment in a common Postgres DB for DA/DevOps  

## Todo

Currently using the blocking JDBC driver for Postgres. Need to upgrade to a non-blocking lib.  

## Database Design Principles

1. Multi-tenancy first. There are system tables (sys_*) that share common entities/properties between orgs and org-specific tables (e.g. 'sc-*') that are used by just one org.
2. Tenants extend system tables when able. System tables store columns shared by multiple orgs. When a single org needs more data associated with a system entity, it's new table should extend/reference the system table and not duplicate columns.
3. The system security concept should be the only concept used by all orgs. It enables field-level permissions but requires each role to only have one set of column + row definition per role.
4. Read performance is an important design principle. Where possible, views should be used to increase read performance.
5. The database must have a schema-ed record of all changes to it. The schema must be configured in such a way that queries can be written to search for historical data on any column. Worse case scenario we have a log table. 
