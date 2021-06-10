# Security

Security Grant Contexts:
1. Organization membership
1. Global role membership
1. Project membership  
1. Project role membership
1. Sensitivity clearance

Concepts:
1. `*_security` table(s) need to be updated whenever:
    1. A member is added or removed from a(n):
        1. Organization
        1. Role
        1. Project
        1. Project role
    1. When a user has their `sensitivity_clearance` modified.
    1. When a `_grants` table is updated in any way.  
    1. When an entry is added to any data table.
1. `*_secure_view` tables should be concurrently refreshed after a `_security` table is updated.  
1. A user should not have access to a data entry that has a higher sensitivity then the user's `sensitivity_clearance`