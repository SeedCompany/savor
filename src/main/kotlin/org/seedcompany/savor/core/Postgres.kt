package org.seedcompany.savor.core

import org.springframework.beans.factory.annotation.Autowired
import org.springframework.boot.context.properties.ConfigurationProperties
import org.springframework.boot.jdbc.DataSourceBuilder
import org.springframework.context.annotation.Bean
import org.springframework.context.annotation.Configuration
import org.springframework.stereotype.Component
import java.sql.Connection
import java.sql.DriverManager
import java.util.*
import java.io.File
import javax.sql.DataSource

@Component
class Postgres(
    @Autowired
    val config: PostgresConfig,
    @Autowired
    val ds: DataSource,
) {

    init {

        ds.connection.use {
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
    class DataSourceConfiguration {
        @Bean
        @ConfigurationProperties("spring.datasource")
        fun customDataSource(): DataSource {
            return DataSourceBuilder.create().build()
        }
    }

}