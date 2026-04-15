package com.betaup.config;

import java.sql.Connection;
import java.sql.DatabaseMetaData;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.HashSet;
import java.util.List;
import java.util.Locale;
import java.util.Set;
import javax.sql.DataSource;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.core.annotation.Order;
import org.springframework.stereotype.Component;

@Slf4j
@Component
@Order(0)
@RequiredArgsConstructor
public class PostSchemaCompatibilityInitializer implements ApplicationRunner {

    private final DataSource dataSource;

    @Override
    public void run(ApplicationArguments args) {
        try (Connection connection = dataSource.getConnection()) {
            DatabaseMetaData metaData = connection.getMetaData();
            if (!hasTable(metaData, connection.getCatalog(), "posts")) {
                return;
            }

            Set<String> columns = getColumns(metaData, connection.getCatalog(), "posts");
            try (Statement statement = connection.createStatement()) {
                ensureColumn(statement, columns, "media_path", "ALTER TABLE posts ADD COLUMN media_path TEXT");
                ensureColumn(statement, columns, "media_kind", "ALTER TABLE posts ADD COLUMN media_kind VARCHAR(20)");
                ensureColumn(statement, columns, "media_count", "ALTER TABLE posts ADD COLUMN media_count INTEGER DEFAULT 0 NOT NULL");

                if (columns.contains("media_count")) {
                    statement.executeUpdate("""
                        UPDATE posts
                        SET media_count = CASE
                            WHEN media_path IS NULL OR TRIM(media_path) = '' OR TRIM(media_path) = '[]' THEN 0
                            WHEN TRIM(media_path) LIKE '[%' THEN LENGTH(TRIM(media_path)) - LENGTH(REPLACE(TRIM(media_path), ',', '')) + 1
                            ELSE 1
                        END
                        WHERE media_count IS NULL OR media_count = 0
                        """);
                }
            }
        } catch (SQLException exception) {
            log.warn("[PostSchemaCompatibility] Failed to reconcile posts table schema.", exception);
        }
    }

    private void ensureColumn(Statement statement, Set<String> columns, String columnName, String sql) throws SQLException {
        if (columns.contains(columnName)) {
            return;
        }

        statement.execute(sql);
        columns.add(columnName);
        log.info("[PostSchemaCompatibility] Added missing column posts.{}", columnName);
    }

    private boolean hasTable(DatabaseMetaData metaData, String catalog, String tableName) throws SQLException {
        for (String candidate : tableNameCandidates(tableName)) {
            try (ResultSet resultSet = metaData.getTables(catalog, null, candidate, new String[] {"TABLE"})) {
                if (resultSet.next()) {
                    return true;
                }
            }
        }
        return false;
    }

    private Set<String> getColumns(DatabaseMetaData metaData, String catalog, String tableName) throws SQLException {
        Set<String> columns = new HashSet<>();
        for (String candidate : tableNameCandidates(tableName)) {
            try (ResultSet resultSet = metaData.getColumns(catalog, null, candidate, "%")) {
                while (resultSet.next()) {
                    columns.add(resultSet.getString("COLUMN_NAME").toLowerCase(Locale.ROOT));
                }
            }
            if (!columns.isEmpty()) {
                break;
            }
        }
        return columns;
    }

    private List<String> tableNameCandidates(String tableName) {
        return List.of(
            tableName,
            tableName.toLowerCase(Locale.ROOT),
            tableName.toUpperCase(Locale.ROOT)
        );
    }
}
