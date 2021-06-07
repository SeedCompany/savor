CREATE OR REPLACE FUNCTION populate_securtity_on_grant_fn()
  RETURNS TRIGGER
  LANGUAGE PLPGSQL
  AS $$
  declare
  role_membership_count bigint;
  table_name_ident text;
  rec record;
begin
	table_name_ident := quote_ident(new.table_name);
	select count(*) from sys_role_memberships
	into role_membership_count
	where sys_role_id = new.sys_role_id;
	if role_membership_count > 0 then
		for rec in (select sys_person_id from sys_role_memberships
				    where sys_role_id = new.sys_role_id) loop
					raise info '%', rec.sys_person_id;
					execute procedure('insert into '|| table_name_ident
					|| '( ' || quote_ident(new.column_name) || ' ) values ('
					|| new.access_level ')')
	end if;
	RETURN NEW;
end; $$;