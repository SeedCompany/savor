package org.seedcompany.api.core

import org.springframework.beans.factory.annotation.Autowired
import org.springframework.context.annotation.Bean
import org.springframework.stereotype.Component
import java.sql.Connection
import java.sql.DriverManager
import java.util.*
import java.io.File

@Component
class Postgres(
    @Autowired
    val config: PostgresConfig
) {
    private val url = "${config.url}/${config.database}"
    private val props = Properties()
    val conn: Connection

    init {
        props.setProperty("port", config.port)
        props.setProperty("user", config.user)
        props.setProperty("password", config.password)
        props.setProperty("ssl", "false")
        this.conn = DriverManager.getConnection(url, props)

        val statement = conn.createStatement()

        // load schema and initial data - commands are idempotent
        val sysSchema = File("./src/apiMain/kotlin/core/data/sql/sys-schema.sql").readText()
        val scSchema = File("./src/apiMain/kotlin/core/data/sql/sc-schema.sql").readText()
        //val data = File("./src/apiMain/kotlin/core/database/sql/sys-schema.sql").readText()

        statement.execute(sysSchema)
        statement.execute(scSchema)
        //statement.execute(data)

        statement.close()
    }

    @Bean
    fun getConnection(): Connection {
        return this.conn
    }

}