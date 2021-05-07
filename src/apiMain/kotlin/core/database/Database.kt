package core.database

import core.Config
import java.io.BufferedReader
import java.io.FileReader
import java.io.Reader
import java.sql.Connection
import java.sql.DriverManager
import java.util.*
import org.apache.ibatis.jdbc.ScriptRunner;
import java.io.File

class Database(
    val config: Config
) {
    private val url = "${config.postgresUrl}/${config.postgresDatabase}"
    private val props = Properties()
    var conn: Connection

    init {
        props.setProperty("port", config.postgresPort)
        props.setProperty("user", config.postgresUser)
        props.setProperty("password", config.postgresPassword)
        props.setProperty("ssl", "false")
        this.conn = DriverManager.getConnection(url, props)

        val statement = conn.createStatement()

        // load schema and initial data - commands are idempotent
        val sysSchema = File("./src/apiMain/kotlin/core/database/sql/sys-schema.sql").readText()
        val scSchema = File("./src/apiMain/kotlin/core/database/sql/sc-schema.sql").readText()
        val data = File("./src/apiMain/kotlin/core/database/sql/sys-schema.sql").readText()

        statement.execute(sysSchema)
        statement.execute(scSchema)
        statement.execute(data)

        statement.close()
    }

}