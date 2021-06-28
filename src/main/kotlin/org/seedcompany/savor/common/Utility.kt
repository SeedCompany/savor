package org.seedcompany.savor.common

import com.auth0.jwt.JWT
import com.auth0.jwt.algorithms.Algorithm
import org.seedcompany.savor.core.AppConfig
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.beans.factory.annotation.Qualifier
import org.springframework.jdbc.core.JdbcTemplate
import org.springframework.stereotype.Component
import java.nio.charset.Charset
import java.time.Instant
import java.util.*
import javax.sql.DataSource

@Component
class Utility (
    @Autowired
    val appConfig: AppConfig,
    @Autowired
    @Qualifier("writerDataSource")
    val writerDS: DataSource,
) {
    val jdbcTemplate: JdbcTemplate = JdbcTemplate(writerDS)

    private var algo: Algorithm? = null

    init {
        try {
            algo = Algorithm.HMAC256(appConfig.jwtSecret)
        } catch (ex: Exception) {
            ex.printStackTrace()
        }
    }

    // todo
    fun getBearer(): String {
        return "todo"
    }

    fun getRandomString(length: Int): String {
        val array = ByteArray(length)
        Random().nextBytes(array)
        return String(array, Charset.forName("UTF-8"))
    }

    fun createToken(key: String): String {
        val randString = getRandomString(32)
        val token: String = JWT.create()
            .withClaim("key", key)
            .withClaim("random", randString)
            .withClaim("timestamp", Instant.now().toEpochMilli())
            .sign(algo)
        return token
    }

    fun getUserIdFromSessionId(sessionId: String): Int? {
        val person_id = jdbcTemplate.queryForObject(
            //language=SQL
            """
                select person from public.sessions where session = ?;
            """.trimIndent(),
            Int::class.java,
            sessionId,
        )

        return person_id
    }


}
