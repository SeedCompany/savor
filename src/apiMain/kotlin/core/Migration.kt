package core

import core.database.Neo4j
import core.database.scripts.*
import java.sql.Connection
import java.sql.Types


import java.time.ZonedDateTime


class Migration (
    val config: Config,
    val neo4j: Neo4j,
    val connection: Connection,
) {

    fun migrate() {
//        MigrateOrgs(config, neo4j,connection).migrateOrganizations()
//        MigrateUsers(config, neo4j,connection).migrateUsers()
//        MigrateRoles(config, neo4j,connection).migrateRoles()
//        MigrateEthnologue(config, neo4j,connection).migrateEthnologue()
//        MigrateLanguages(config, neo4j,connection).migrateLanguages()
//        MigratePartners(config, neo4j,connection).migratePartners()
//        MigrateDirectories(config, neo4j,connection).migrateDirectories()
//        MigratePartnerships(config, neo4j,connection).migratePartnerships()
//        MigrateFieldZones(config, neo4j,connection).migrateFieldZones()
//        MigrateFieldRegions(config, neo4j,connection).migrateFieldRegions()
//        MigrateLocations(config, neo4j,connection).migrateLocations()
//        MigrateFiles(config, neo4j,connection).migrateFiles() - 3000 file counts in db.devcordfield neo4j database do not run unless absolutely crucial
//        MigrateFileVersions(config, neo4j,connection).migrateFileVersions()
//        MigratePlanChanges(config,neo4j, connection).migratePlanChange()
//        MigrateProjects(config, neo4j, connection).migrateProjects()
//        MigrateProjectMembers(config, neo4j, connection).migrateProjectMembers()
//        MigrateBudgets(config, neo4j, connection).migrateBudgets()
        MigrateBudgetRecords(config,neo4j,connection).migrateBudgetRecords()
    }

}

