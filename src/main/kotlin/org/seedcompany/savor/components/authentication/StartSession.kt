package org.seedcompany.savor.components.authentication

import org.seedcompany.savor.common.ErrorType
import org.seedcompany.savor.common.Utility
import org.seedcompany.savor.core.AppConfig
import org.springframework.context.event.EventListener
import org.springframework.stereotype.Component
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.beans.factory.annotation.Qualifier
import org.springframework.context.ApplicationEventPublisher
import org.springframework.context.annotation.DependsOn
import org.springframework.jdbc.core.JdbcTemplate
import javax.sql.DataSource

@Component
@DependsOn("Postgres")
class StartSession(
    @Autowired
    @Qualifier("writerDataSource")
    val ds: DataSource,
    @Autowired
    val appConfig: AppConfig,
    @Autowired
    val util: Utility,
    @Autowired
    val publisher: ApplicationEventPublisher,
    @Autowired
    @Qualifier("writerDataSource")
    val writerDS: DataSource,
    @Autowired
    @Qualifier("readerDataSource")
    val readerDS: DataSource,
)  {

    val jdbcWriter: JdbcTemplate = JdbcTemplate(writerDS)
    val jdbcReader: JdbcTemplate = JdbcTemplate(readerDS)

    //language=SQL
    val startSessionProc = """
        CREATE OR REPLACE PROCEDURE start_session(
            IN p_token VARCHAR(512),
            IN p_session_id VARCHAR(64),
            INOUT error_type VARCHAR(32)
        )
        LANGUAGE PLPGSQL
        AS ${'$'}${'$'}
        DECLARE
            vToken VARCHAR(512);
            vUserId int;
            vSessionId varchar(64);
        BEGIN
            SELECT token, user_id 
            FROM tokens
            INTO vToken, vUserId
            WHERE tokens.token = p_token;
            IF FOUND THEN
                select session_id
                from sessions
                into vSessionId
                where sessions.session_id = p_session_id and sessions.token = p_token;
                if not found then
                    insert into sessions("token", "user_id", "session_id")
                    values (vToken, vUserId, p_session_id)
                    returning sessions.session_id
                    into vSessionId;
                    error_type := 'NoError';
                else
                    error_type := 'NoError';
                end if;
            ELSE
                error_type := 'TokenNotFound';
            END IF;
        END; ${'$'}${'$'}
    """.trimIndent()

    init {
        this.ds.connection.use {conn ->

            val statement = conn.createStatement()
            try {
//                statement.execute("DROP PROCEDURE start_session;")
            } catch (e:Exception) {

            }
//            statement.execute(this.startSessionProc)
            statement.close()
        }
    }

    @EventListener
    fun register(event: StartSessionRequest) {
        var errorType = ErrorType.UnknownError

        //language=SQL
        val startSessionSQL = """
            CALL start_session(?, ?, ?);
        """.trimIndent()

        this.ds.connection.use {conn ->

            val statement = conn.prepareCall(startSessionSQL);
            statement.setString(1, event.token)
            statement.setString(2, event.sessionId)
            statement.setString(3, errorType.name)
            statement.registerOutParameter(3, java.sql.Types.VARCHAR)

            val result = statement.execute()

            errorType = ErrorType.valueOf(statement.getString(3))

            if (errorType == ErrorType.NoError) {
                publisher.publishEvent(StartSessionResponse(true, event.sessionId))
            } else if (errorType == ErrorType.TokenNotFound){
                println("token not found")
                publisher.publishEvent(StartSessionResponse(false, event.sessionId))
            }
            else {
                println("register query failed")
            }
            statement.close()
        }
    }
}