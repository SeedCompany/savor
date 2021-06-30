package org.seedcompany.savor.core

import org.springframework.beans.factory.annotation.Autowired
import org.springframework.context.annotation.Bean
import org.springframework.stereotype.Component
import java.sql.Connection
import java.sql.DriverManager
import java.util.*
import java.io.File
import java.nio.file.Files
import java.nio.file.Path

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
        val fileNamesList = mutableListOf<String>()
        val sqlFileRegex = Regex(pattern = "^((?!bootstrap).)*.sql\$")
        File("./src/main/kotlin/org/seedcompany/savor/core/data/sql/").walk().filter{item-> Files.isRegularFile(item.toPath())}.forEach{
            val matched = sqlFileRegex.containsMatchIn(input = it.toString())
            if(matched)
                fileNamesList.add(it.toString());
        }
        fileNamesList.sort();
        for(i in fileNamesList.indices){
            println(fileNamesList[i])
            statement.execute(File(fileNamesList[i]).readText())
        }
        // load schema and initial data - commands are idempotent
        // statement.execute(File("./src/main/kotlin/org/seedcompany/savor/core/data/sql/sys.schema.sql").readText())
        // statement.execute(File("./src/main/kotlin/org/seedcompany/savor/core/data/sql/sc.schema.sql").readText())
        // statement.execute(File("./src/main/kotlin/org/seedcompany/savor/core/data/sql/sys.authen.fn.sql").readText())
        // statement.execute(File("./src/main/kotlin/org/seedcompany/savor/core/data/sql/sys.roles.fn.sql").readText())
//        statement.execute(File("./src/main/kotlin/org/seedcompany/savor/core/data/sql/bootstrap.data.sql").readText())

        statement.close()
    }

    @Bean
    fun getConnection(): Connection {
        return this.conn
    }

}