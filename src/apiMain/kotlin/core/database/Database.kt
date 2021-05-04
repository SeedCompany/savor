package core.database

import java.io.BufferedReader
import java.io.FileReader
import java.io.Reader
import java.sql.Connection
import java.sql.DriverManager
import java.util.*
import org.apache.ibatis.jdbc.ScriptRunner;
import java.io.File

class Database {
    private val url = "jdbc:postgresql://savor-1.cluster-cx8uefm35nis.us-east-2.rds.amazonaws.com/da1"
    private val props = Properties()
    var conn: Connection

    init {
        props.setProperty("port", "5432")
        props.setProperty("user", "postgres")
        props.setProperty("password", "QJ6ILFY6z7c9hpH2vj9V")
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

    fun getConnection(): Connection {
        return this.conn
    }
}