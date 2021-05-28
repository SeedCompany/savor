create or replace function sys_register(
    in pEmail VARCHAR ( 255 ),
    in pPassword VARCHAR ( 50 ),
    in pToken VARCHAR ( 512 ),
    in pOrgId INT
)
returns INT
language plpgsql
as $$
declare
    vResponseCode INT;
    vSysPersonId INT;
begin
    SELECT sys_person_id
    FROM sys_users
    INTO vSysPersonId
    WHERE sys_users.email = pEmail;
    IF NOT found THEN
        INSERT INTO sys_people VALUES (DEFAULT)
        RETURNING sys_person_id
        INTO vSysPersonId;
        INSERT INTO sys_users("sys_person_id", "email", "password", "owning_sys_org_id")
        VALUES (vSysPersonId, pEmail, pPassword, pOrgId);
        INSERT INTO sys_tokens("token", "sys_person_id")
        VALUES (pToken, vSysPersonId);
        vResponseCode := 0;
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
    vRow sys_users%ROWTYPE;
    vId INT;
begin
    SELECT *
    FROM sys_users
    INTO vRow
    WHERE sys_users.email = pEmail AND sys_users.password = pPassword;
    IF found THEN
        INSERT INTO sys_tokens("token", "sys_person_id")
        VALUES (pToken, vRow.sys_person_id);
        vResponseCode := 0;
    ELSE
        vResponseCode := 2;
    END IF;
        return vResponseCode;
end; $$;