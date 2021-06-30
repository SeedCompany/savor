package org.seedcompany.savor.core

import org.springframework.beans.factory.annotation.Autowired
import org.springframework.beans.factory.annotation.Qualifier
import org.springframework.boot.context.properties.ConfigurationProperties
import org.springframework.boot.jdbc.DataSourceBuilder
import org.springframework.context.annotation.Bean
import org.springframework.context.annotation.Configuration
import org.springframework.stereotype.Component
import java.io.File
import java.nio.file.Files
import java.nio.file.Path
import javax.sql.DataSource

@Component("Postgres")
class Postgres(
    @Autowired
    @Qualifier("writerDataSource")
    val writerDS: DataSource,
    // example for reader datasource:
    @Autowired
    @Qualifier("readerDataSource")
    val readerDS: DataSource,
) {

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

        statement.close()
    }

    @Configuration
    class WriterDataSourceConfiguration {
        @Bean
        @ConfigurationProperties("spring.writer-datasource")
        fun writerDataSource(): DataSource {
            return DataSourceBuilder.create().build()
        }
        
    }

    @Configuration
    class ReaderDataSourceConfiguration {
        @Bean
        @ConfigurationProperties("spring.reader-datasource")
        fun readerDataSource(): DataSource {
            return DataSourceBuilder.create().build()
        }
    }

}