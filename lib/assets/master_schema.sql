-- Master Database Schema
CREATE TABLE IF NOT EXISTS series (
    series_id INTEGER PRIMARY KEY AUTOINCREMENT,
    series_name TEXT NOT NULL UNIQUE
);
CREATE TABLE IF NOT EXISTS projects (
    project_id INTEGER PRIMARY KEY AUTOINCREMENT,
    project_name TEXT NOT NULL,
    source_path TEXT NOT NULL UNIQUE,
    -- Path to the original manuscript file/folder
    db_path TEXT NOT NULL UNIQUE,
    -- Path to the project's dedicated SQLite database
    series_id INTEGER,
    -- FK to series(series_id), NULLABLE
    last_imported_at TEXT NOT NULL,
    -- ISO 8601 timestamp of last import/refresh
    created_at TEXT NOT NULL,
    -- ISO 8601 timestamp of initial import
    word_count INTEGER NOT NULL DEFAULT 0,
    -- Added column
    FOREIGN KEY (series_id) REFERENCES series(series_id) ON DELETE
    SET NULL
);