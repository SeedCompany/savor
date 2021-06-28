package org.seedcompany.savor.core

import org.springframework.beans.factory.annotation.Autowired
import org.springframework.beans.factory.annotation.Qualifier
import org.springframework.boot.context.properties.ConfigurationProperties
import org.springframework.boot.jdbc.DataSourceBuilder
import org.springframework.context.annotation.Bean
import org.springframework.context.annotation.Configuration
import org.springframework.stereotype.Component
import java.io.File
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

        writerDS.connection.use {
            val statement = it.createStatement()
            // load schema and initial data - commands are idempotent
            statement.execute(File("./src/main/kotlin/org/seedcompany/savor/core/data/sql/sys.schema.sql").readText())
            statement.execute(File("./src/main/kotlin/org/seedcompany/savor/core/data/sql/sc.schema.sql").readText())
            statement.execute(File("./src/main/kotlin/org/seedcompany/savor/core/data/sql/sys.authen.fn.sql").readText())
            statement.execute(File("./src/main/kotlin/org/seedcompany/savor/core/data/sql/sys.roles.fn.sql").readText())
            statement.execute(File("./src/main/kotlin/org/seedcompany/savor/core/data/sql/bootstrap.data.sql").readText())

            statement.close()
        }
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