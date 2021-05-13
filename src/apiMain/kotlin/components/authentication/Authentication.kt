package components.authentication

import java.sql.Connection

class Authentication ( val conn: Connection) {

    val registerProc = """
        create or replace function sys_register_proc(
            in pEmail VARCHAR ( 255 ),
            in pPassword VARCHAR ( 50 ),
            in pToken VARCHAR ( 512 )
        )
        returns INT
        language plpgsql
        as ${'$'}${'$'}
        declare
            vResponseCode INT;
            vSysPersonId INT;
        begin
            SELECT sys_person_id 
            FROM sys_users
            INTO vSysPersonId
            WHERE sys_users.email = pEmail;
            IF NOT found THEN
                INSERT INTO sys_people VALUES (null)
                RETURNING sys_person_id
                INTO vSysPersonId;
                INSERT INTO sys_users("sys_person_id", "email", "password")
                VALUES (vSysPersonId, pEmail, pPassword);
                INSERT INTO sys_tokens("token", "sys_person_id")
                VALUES (pToken, vSysPersonId);
                vResponseCode := 0;
            ELSE
                vResponseCode := 1;
            END IF;
            return vResponseCode;
        end; ${'$'}${'$'}
    """.trimIndent()

    val loginProc = """
        create or replace function sys_login_proc(
            in pEmail VARCHAR ( 255 ),
            in pPassword VARCHAR ( 50 ),
            in pToken VARCHAR ( 512 )
        )
        returns INT
        language plpgsql
        as ${'$'}${'$'}
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
        end; ${'$'}${'$'}
    """.trimIndent()
    
    init {
        val statement = conn.createStatement()

        statement.execute(this.registerProc)
        statement.execute(this.loginProc)

        statement.close()
    }
}