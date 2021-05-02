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
            vEmail VARCHAR(255);
            vId INT;
        begin
            SELECT email 
            FROM users
            INTO vEmail
            WHERE users.email = pEmail;
            IF NOT found THEN
                INSERT INTO users("email", "password")
                VALUES (pEmail, pPassword)
                RETURNING id
                INTO vId;
                INSERT INTO tokens("token", "user_id")
                VALUES (pToken, vId);
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
            vRow users%ROWTYPE;
            vId INT;
        begin
            SELECT * 
            FROM users
            INTO vRow
            WHERE users.email = pEmail AND users.password = pPassword;
            IF found THEN
                INSERT INTO tokens("token", "user_id")
                VALUES (pToken, vRow.id);
                vResponseCode := 0;
            ELSE
                vResponseCode := 2;
            END IF;
                return vResponseCode;
        end; ${'$'}${'$'}
    """.trimIndent()
    
    init {
        val statement = conn.createStatement()

//        statement.execute(this.loginProc)

        statement.close()
    }
}