# SCHEMA

## Principles
1. DBA friendly: We want as much logic as possible to be in `.sql` files  
2. Performance: We want to do whatever it takes to make secure reads as fast as possible. Number of intermediate tables and the size of tables is not a concern if they make secure reads faster.
## Security

1. We are using triggers on org, role, and project tables to update the `*_security` tables.
   1. Triggers need to exist for every operation on the source tables. For example, when a role is updated with a new grant, everyone with that role needs to have entries added to the security table for the new grant. When a grant is removed, the users need that permission removed.
2. `*_security` tables are combined with their data counterparts in a materialized view to facilitate the secure reads by users.
