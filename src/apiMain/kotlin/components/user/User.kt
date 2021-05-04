package components.user

import java.sql.Connection

class User ( conn: Connection) {

    val scAddUserProc = """
        create or replace function sc_add_user(
        	in pEmail VARCHAR ( 255 ),
        	in pFirstName VARCHAR ( 32 ),
        	in pLastName VARCHAR ( 32 )
        )
        returns INT
        language plpgsql
        as ${'$'}${'$'}
        declare
        	vSysUserId INT;
        	vResponseCode INT;
        begin
        	SELECT sys_user_id
        	FROM sys_users
        	INTO vSysUserId
        	WHERE sys_users.email = pEmail;
        	IF found THEN
        		INSERT INTO sc_users("sys_user_id", "first_name", "last_name")
        		VALUES (vSysUserId, pFirstName, pLastName)
        		ON CONFLICT ("sys_user_id")
        		DO NOTHING;
        		vResponseCode := 0;
        	ELSE
        		vResponseCode := 1;
        	END IF;
        	return vResponseCode;
        end; ${'$'}${'$'};
    """.trimIndent()

    val secureRead = """
        
    """.trimIndent()

    init {
        val statement = conn.createStatement()

        statement.execute(this.scAddUserProc)
//        statement.execute(this.secureRead)

        statement.close()
    }
}