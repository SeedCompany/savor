-- DELETE EVERYTHING

-- TABLES -------------------------------------------------------------------------------

DO $$ DECLARE
    r RECORD;
BEGIN
    -- if the schema you operate on is not "current", you will want to
    -- replace current_schema() in query with 'schematodeletetablesfrom'
    -- *and* update the generate 'DROP...' accordingly.
    FOR r IN (SELECT tablename FROM pg_tables WHERE schemaname = current_schema()) LOOP
        EXECUTE 'DROP TABLE IF EXISTS ' || quote_ident(r.tablename) || ' CASCADE';
    END LOOP;
END $$;

-- ENUMs -------------------------------------------------------------------------------

drop type if exists enum_table_name cascade;
drop type if exists enum_column_name cascade;
drop type if exists enum_location_type cascade;
drop type if exists sc_enum_involvements cascade;
drop type if exists sc_enum_people_transitions cascade;
drop type if exists sc_enum_org_transitions cascade;
drop type if exists sc_enum_sensitivity cascade;

-- FUNCTIONS ---------------------------------------------------------------------------

-- Authentication
drop function if exists sc_add_user cascade;

-- Organization
drop function if exists sc_add_org cascade;

-- Authorization
drop function if exists sys_add_member cascade;
drop function if exists sys_add_column_access_for_user cascade;
drop function if exists sys_add_column_access_for_group cascade;
drop function if exists sys_add_row_access_for_user cascade;
drop function if exists sys_add_row_access_for_group cascade;