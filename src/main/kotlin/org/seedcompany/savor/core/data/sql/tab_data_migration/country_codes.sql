-- you need to remove the header of the tsv files 
create or replace function migrate_country_codes_data()
returns INT 
language plpgsql
as $$
declare 
	responseCode INT;
begin
	set schema 'public';
	create table if not exists sil_country_codes (
		country_id char(2) not null,
		name varchar(75) not null,
		area varchar(10) not null 
	);
	perform * from sil_country_codes 
	where country_id = 'AA';
	if not found then
		copy sil_country_codes 
		from '/home/vivek/savor-rnd/src/apiMain/kotlin/core/data/dumps/CountryCodes.tab' delimiter '	';
		responseCode := 0;
	else 
		responseCode := 1;
	end if;
	return responseCode;
end; $$
