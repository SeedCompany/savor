create or replace function sys_register(
    in pEmail VARCHAR(255),
    in pPassword VARCHAR(50),
    in pOrgName VARCHAR(255)
)
returns INT
language plpgsql
as $$
declare
    vResponseCode INT;
    vSysPersonId INT;
    vOrgId INT;
begin
    SELECT person_id
    FROM public.users
    INTO vSysPersonId
    WHERE users.email = pEmail;
    IF NOT found THEN
        SELECT id
        FROM public.organizations
        INTO vOrgId
        WHERE organizations.name = pOrgName;
        IF found THEN
            INSERT INTO public.people VALUES (DEFAULT)
            RETURNING id
            INTO vSysPersonId;
            INSERT INTO public.users("person_id", "email", "password", "owning_org_id")
            VALUES (vSysPersonId, pEmail, pPassword, vOrgId);
            vResponseCode := 0;
        ELSE
            vResponseCode := 1;
        END IF;
    ELSE
        vResponseCode := 1;
    END IF;
    return vResponseCode;
end; $$;

create or replace function sys_login(
    in pEmail VARCHAR ( 255 ),
    in pPassword VARCHAR ( 50 ),
    in pToken VARCHAR ( 512 )
)
returns INT
language plpgsql
as $$
declare
    vResponseCode INT;
    vRow public.users%ROWTYPE;
    vId INT;
begin
    SELECT *
    FROM public.users
    INTO vRow
    WHERE users.email = pEmail AND users.password = pPassword;
    IF found THEN
        INSERT INTO public.tokens("token", "person_id")
        VALUES (pToken, vRow.person_id);
        vResponseCode := 0;
    ELSE
        vResponseCode := 2;
    END IF;
        return vResponseCode;
end; $$;