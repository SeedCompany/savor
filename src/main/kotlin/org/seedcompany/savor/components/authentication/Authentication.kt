package org.seedcompany.savor.components.authentication

import org.seedcompany.savor.common.ErrorType
import org.seedcompany.savor.common.Utility
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.beans.factory.annotation.Qualifier
import org.springframework.context.ApplicationEventPublisher
import org.springframework.context.annotation.DependsOn
import org.springframework.context.event.EventListener
import org.springframework.stereotype.Component
import javax.sql.DataSource

@Component
class Authentication

@Component
@DependsOn("Postgres")
class Register(
    @Autowired
    @Qualifier("writerDataSource")
    val ds: DataSource,
    @Autowired
    val util: Utility,
    @Autowired
    val publisher: ApplicationEventPublisher
)  {
    //language=SQL
    val registerProc = """
        CREATE OR REPLACE PROCEDURE register(
            IN p_email VARCHAR(255),
            IN p_password VARCHAR(50),
            IN p_token VARCHAR(512),
            in p_session_id varchar(64),
            INOUT error_type VARCHAR(32)
        )
        LANGUAGE PLPGSQL
        AS ${'$'}${'$'}
        DECLARE
            t_email VARCHAR(255);
            t_id INT;
        BEGIN
            SELECT email 
            FROM users
            INTO t_email
            WHERE users.email = p_email;
            IF NOT FOUND THEN
                INSERT INTO users("email", "password")
                VALUES (p_email, p_password)
                RETURNING user_id
                INTO t_id;
                INSERT INTO tokens("token", "user_id")
                VALUES (p_token, t_id);
                insert into sessions("token", "user_id", "session_id")
                values (p_token, t_id, p_session_id);
                error_type := 'NoError';
            ELSE
                error_type := 'DuplicateEmail';
            END IF;
        END; ${'$'}${'$'}
    """.trimIndent()

    init {
        this.ds.connection.use {conn ->

            val statement = conn.createStatement()
            try {
//                statement.execute("DROP PROCEDURE register;")
            } catch (e:Exception) {

            }
//            statement.execute(this.registerProc)
            statement.close()
        }
    }

    @EventListener
    fun register(event: UserRegisterRequest) {
        var errorType = ErrorType.UnknownError
        var token: String? = util.createToken(event.email)

        //language=SQL
        val registerUserSql = """
            CALL register(?, ?, ?, ?, ?);
        """.trimIndent()

        this.ds.connection.use {conn ->

            val statement = conn.prepareCall(registerUserSql);
            statement.setString(1, event.email)
            statement.setString(2, event.password)
            statement.setString(3, token)
            statement.setString(4, event.sessionId)
            statement.setString(5, errorType.name)
            statement.registerOutParameter(5, java.sql.Types.VARCHAR)

            val result = statement.execute()

            errorType = ErrorType.valueOf(statement.getString(5))

            if (errorType == ErrorType.NoError) {
            } else if (errorType == ErrorType.DuplicateEmail){
                token = null
            }
            else {
                println("register query failed")
                token = null
            }
            statement.close()
        }

        publisher.publishEvent(UserRegisterResponse(
            error = errorType,
            token = token,
            sessionId = event.sessionId,
        ))
    }
}
