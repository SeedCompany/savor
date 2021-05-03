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

drop type if exists e_table_name cascade;
drop type if exists e_column_name cascade;

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