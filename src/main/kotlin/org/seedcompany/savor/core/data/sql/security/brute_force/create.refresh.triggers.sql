CREATE OR REPLACE FUNCTION create_refresh_triggers(p_schema_name text, p_table_name text)
RETURNS VOID
LANGUAGE PLPGSQL
AS $$
declare 
	 insert_trigger_name text;
	 update_trigger_name text;
	 delete_trigger_name text;
begin


	insert_trigger_name := quote_ident(p_table_name||'_refresh_insert_trigger');
	update_trigger_name := quote_ident(p_table_name||'_refresh_update_trigger');
	delete_trigger_name := quote_ident(p_table_name||'_refresh_delete_trigger');

	p_schema_name := quote_literal(p_schema_name);
	
	execute format('DROP TRIGGER IF EXISTS '|| insert_trigger_name || ' ON ' ||p_table_name);
	execute format('DROP TRIGGER IF EXISTS '|| update_trigger_name || ' ON ' ||p_table_name);
	execute format('DROP TRIGGER IF EXISTS '|| delete_trigger_name || ' ON ' ||p_table_name);

	execute format('CREATE TRIGGER ' || insert_trigger_name
	|| ' AFTER INSERT ON ' || p_table_name || ' FOR EACH ROW EXECUTE PROCEDURE refresh_security_tables('|| p_schema_name || ')'); 

	execute format('CREATE TRIGGER ' || update_trigger_name
	|| ' AFTER update ON ' || p_table_name || ' FOR EACH ROW EXECUTE PROCEDURE refresh_security_tables('|| p_schema_name || ')'); 

	execute format('CREATE TRIGGER ' || delete_trigger_name
	|| ' AFTER delete ON ' || p_table_name || ' FOR EACH ROW EXECUTE PROCEDURE refresh_security_tables('|| p_schema_name || ')'); 


end; $$;

CREATE TRIGGER projects_data_refresh_insert_trigger 
AFTER INSERT ON projects_data 
FOR EACH ROW 
EXECUTE PROCEDURE refresh_security_tables('public');

select create_refresh_triggers('public','project_member_roles_data');
select create_refresh_triggers('public', 'project_role_grants_data');
select create_refresh_triggers('public', 'global_role_column_grants_data');
select create_refresh_triggers('public', 'global_role_memberships_data')
select create_refresh_triggers('public', 'projects_data');
