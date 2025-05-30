-- Project Database Schema
CREATE TABLE IF NOT EXISTS chapters (
    chapter_id INTEGER PRIMARY KEY AUTOINCREMENT,
    chapter_title TEXT,
    chapter_order INTEGER,
    -- To maintain the original sequence
    word_count INTEGER DEFAULT 0,
    -- Added word_count
    created_date TEXT,
    -- Added created_date
    last_modified_date TEXT -- Added last_modified_date
);
CREATE TABLE IF NOT EXISTS scenes (
    scene_id INTEGER PRIMARY KEY AUTOINCREMENT,
    scene_title TEXT,
    scene_order INTEGER,
    chapter_id INTEGER,
    word_count INTEGER DEFAULT 0,
    -- Added word_count
    created_date TEXT,
    -- Added created_date
    last_modified_date TEXT,
    -- Added last_modified_date
    -- FK to chapters(chapter_id)
    FOREIGN KEY (chapter_id) REFERENCES chapters(chapter_id) ON DELETE CASCADE
);
CREATE TABLE IF NOT EXISTS content_blocks (
    block_id INTEGER PRIMARY KEY AUTOINCREMENT,
    text_content TEXT NOT NULL,
    block_order INTEGER NOT NULL,
    -- Order of the block within its parent (scene/chapter/document)
    block_type TEXT,
    -- e.g., 'paragraph', 'heading', 'full_text_import', 'scrivener_document'
    scene_id INTEGER,
    -- FK to scenes(scene_id), NULLABLE
    chapter_id INTEGER,
    -- FK to chapters(chapter_id), NULLABLE
    word_count INTEGER DEFAULT 0,
    -- Added word_count
    created_date TEXT,
    -- Added created_date
    last_modified_date TEXT,
    -- Added last_modified_date
    FOREIGN KEY (scene_id) REFERENCES scenes(scene_id) ON DELETE CASCADE,
    FOREIGN KEY (chapter_id) REFERENCES chapters(chapter_id) ON DELETE CASCADE
);
-- Note: For MVP, for .txt, .docx, .md files, we might initially store all content
-- in a single content_block with a specific block_type like 'full_text_import'
-- and NULL chapter_id and scene_id, or a single dummy chapter/scene.
-- Scrivener projects will populate chapters and potentially scenes more granularly.