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
        val schema = File("./src/apiMain/kotlin/core/database/sql/schema.sql").readText()
        val statement = conn.createStatement()
        statement.execute(schema)
        statement.close()
    }

    fun getConnection(): Connection {
        return this.conn
    }
}