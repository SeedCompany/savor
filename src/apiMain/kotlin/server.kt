import components.authentication.Authentication
import components.authorization.Authorization
import components.organization.Organization
import components.user.User
import core.Config
import core.Migration
import core.database.Database
import core.database.Neo4j
import io.ktor.application.call
import io.ktor.html.respondHtml
import io.ktor.http.HttpStatusCode
import io.ktor.routing.get
import io.ktor.routing.routing
import io.ktor.server.engine.embeddedServer
import io.ktor.server.netty.Netty
import io.ktor.http.content.resources
import io.ktor.http.content.static
import io.ktor.response.*
import kotlinx.html.*
import java.lang.Exception

fun HTML.index() {
    head {
        title("Hello from Ktor!")
    }
    body {
        div {
            +"Hello from Ktor"
        }
        div {
            id = "root"
        }
        script(src = "/static/frontend.js") {}
    }
}

fun main() {
    val config = Config()
    val db = Database(config)
    val neo4j = Neo4j(config)
    val migration = Migration(config, neo4j, db.conn)

    Authentication(db.conn)
    Authorization(db.conn)
    Organization(db.conn)
    User(db.conn)


    embeddedServer(Netty, port = 8080, host = "127.0.0.1") {
        routing {
            get("/") {

                call.respondHtml(HttpStatusCode.OK, HTML::index)
            }
            get("/migrate"){
                try {
                    migration.migrate()
                } catch (e: Exception){
                    println(e.localizedMessage)
                }
                call.respond(HttpStatusCode.OK, "Migration Done.")
            }
            static("/static") {
                resources()
            }
        }
    }.start(wait = true)
}