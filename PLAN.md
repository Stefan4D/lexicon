# Project Lexicon: Development Plan

## 1. Project Overview

Project Lexicon is a cross-platform application designed to help authors analyze word and phrase frequency within their literary works. It aims to provide insights into writing patterns, potential overuse of words/phrases, and offer a way to compare usage across single or multiple book projects.

## 2. Core Objectives

- **Manuscript Ingestion:** Allow authors to import book projects from various file formats and popular writing software.
- **Structured Data Storage:** Parse and store manuscript content (text, chapters, scenes) into individual SQLite databases for each project, maintaining the original structure.
- **Centralized Project Management:** Implement a master SQLite database to manage and list all imported book projects.
- **Word & Phrase Frequency Analysis:**
  - Analyze word frequency within a single book.
  - Analyze n-gram (groups of words) frequency within a single book.
  - Compare word and n-gram frequency across a user-defined series of books or an arbitrary selection of books.
- **Usage Pinpointing:** Enable authors to identify the specific location (chapter/scene) of frequent words or phrases.
- **Data Visualization:** Present analysis results in a visually compelling manner (e.g., word clouds, bar charts, line graphs).
- **Project Refresh:** Allow authors to reload/rescan their projects to reflect updates made in their source manuscripts (read-only access).
- **Cross-Platform Compatibility:** Ensure the application runs smoothly on Windows, Linux, macOS, Android, and iOS.

## 3. Key Features

### 3.1. Project Management

- **Import Project:**
  - Support for `.txt`, `.docx`, `.scrivx` (Scrivener), `.md` (Markdown for Ulysses output) file formats.
  - Ability to select a single file or a folder (for multi-file projects like Scrivener).
  - Automatic detection of project structure (chapters, scenes) based on common conventions or metadata (if available).
- **Project Listing:** Display all imported projects, possibly with metadata like title, author (if extractable), and last analyzed date.
- **Project Database:** Each imported project will have its own dedicated SQLite database.
- **Master Database:** A central SQLite database will store a list of all projects and paths to their individual databases.
- **Refresh Project:** Option to re-parse the source files for an existing project to update the analysis.
- **Delete Project:** Remove a project and its associated database.

### 3.2. Text Parsing & Storage

- **File Format Parsers:** Implement robust parsers for each supported file format.
  - `.txt`: Plain text.
  - `.docx`: Utilize libraries to extract text content. (Primary MS Word format)
  - `.scrivx`: Parse Scrivener's XML-based project file and associated RTF/text files.
  - `.md`: Parse Markdown files (Common for Ulysses).
- **Structural Mapping:**
  - Identify chapter and scene breaks. **Initially, this will be primarily focused on Scrivener projects.** For other formats (`.txt`, `.docx`, `.md`), the entire text will be stored as a single content block per file for the MVP. Future enhancements can explore pattern matching for chapter/scene detection in these formats.
  - Store content in a relational schema:
    - `projects` (in master DB): `project_id`, `project_name`, `source_path`, `db_path`, `last_updated`
    - `chapters` (in project DB): `chapter_id`, `chapter_title`, `chapter_order`
    - `scenes` (in project DB): `scene_id`, `scene_title`, `scene_order`, `chapter_id` (FK)
    - `content_blocks` (in project DB): `block_id`, `text_content`, `scene_id` (FK), `chapter_id` (FK), `block_type` (e.g., paragraph, heading)
- **SQLite Integration:**
  - Use `sqflite` for mobile and `sqlite3_flutter_libs` (or a similar factory pattern like `sqflite_common_ffi`) for bundling SQLite on desktop platforms (Windows, Linux, macOS). **Direct SQLite methods will be preferred over ORMs like Drift for simplicity in early stages.**

### 3.3. Analysis Engine

- **Word Tokenization & Normalization:**
  - Split text into individual words (tokens).
  - Handle punctuation, case-insensitivity (configurable), and possibly stemming/lemmatization (advanced).
- **Stop Word Filtering:** Allow users to use a default list of common stop words. Users can also provide their own custom lists. **Stop word lists can be managed globally and on a per-project basis. Per-project lists can be applied during cross-project comparisons (e.g., to exclude character names specific to a series).**
- **Frequency Counting:**
  - Count occurrences of each word.
  - Count occurrences of n-grams. **Default n-gram patterns will include 3, 4, and 5-word sequences. Users will also be able to configure custom 'n' values.**
- **Cross-Project Analysis:**
  - Ability to select multiple projects for comparative analysis.
  - Aggregate word/n-gram counts across selected projects.
- **Contextual Location:** Link word/phrase occurrences back to their original chapter and scene.

### 3.4. Visualization & Reporting

- **Word Clouds:** Generate dynamic word clouds based on frequency.
- **Frequency Charts:** Bar charts or tables showing top N words/phrases.
- **Trend Graphs (for series):** Show usage of specific words/phrases across books in a series.
- **Interactive Reports:** Allow users to click on a word/phrase in a visualization to see its locations within the manuscript(s).
- **Export Options:** (Optional) Export analysis results (e.g., CSV, PDF).

### 3.5. User Interface (Flutter)

- **Intuitive Navigation:** Easy-to-use interface for managing projects, initiating analysis, and viewing results.
- **Responsive Design:** Adapt to different screen sizes across desktop and mobile.
- **Platform-Specific UI Considerations:** Adhere to platform UI guidelines where appropriate.

## 4. Technical Architecture

- **Language:** Dart
- **Framework:** Flutter
- **Database:** SQLite
  - Mobile: `sqflite`
  - Desktop: `sqlite3_flutter_libs` (or equivalent for bundling) + `sqflite_common_ffi` for a common API. **Direct SQLite methods will be used.**
- **File Parsing Libraries:**
  - `.docx`: `docx_template` or similar for text extraction.
  - (Support for `.doc` is deferred)
  - `.scrivx`: XML parsing (e.g., `xml` package) and RTF parsing (if content is in RTF).
  - `.md`: `markdown` package (for Ulysses etc.).
- **State Management:** **Riverpod.**
- **UI Components:** Standard Flutter widgets, potentially with custom components for visualizations (or using charting libraries like `fl_chart`).

## 5. Platform Considerations

- **Desktop (Windows, Linux, macOS):**
  - SQLite bundling is critical. Need to ensure the native SQLite library is correctly packaged with the application.
  - File system access for project import.
- **Mobile (Android, iOS):**
  - SQLite is natively available via `sqflite`.
  - File system access will use platform-specific file pickers.
  - Permissions for storage access.

## 6. Development Phases (High-Level)

1.  **Phase 1: Core Setup & Project Ingestion (MVP 1)**
    - Basic Flutter app structure.
    - SQLite setup for desktop (factory pattern) and mobile.
    - Implement master DB and project DB creation.
    - Implement `.txt` file parsing and storage (chapters/scenes based on simple delimiters or whole file as one block).
    - Basic UI for importing a `.txt` file and listing it.
2.  **Phase 2: Basic Word Frequency Analysis (MVP 2)**
    - Implement word tokenization and frequency counting for a single project.
    - Display top N words for an imported `.txt` project.
    - Basic UI for showing frequency results.
3.  **Phase 3: Expanded File Format Support**
    - Add parsers for `.md`.
    - Research and implement parsers for `.docx`.
    - Research and implement parsers for Scrivener (`.scrivx`).
    - Refine chapter/scene detection for these formats.
4.  **Phase 4: Advanced Analysis & Visualization**
    - Implement n-gram analysis.
    - Implement stop word filtering.
    - Develop initial visualizations (e.g., word cloud, bar chart).
    - Implement functionality to show word location (chapter/scene).
5.  **Phase 5: Cross-Project Analysis**
    - Allow selection of multiple projects for comparison.
    - Implement comparative frequency analysis.
    - Visualizations for comparative data.
6.  **Phase 6: UI/UX Refinement & Polish**
    - Improve UI/UX based on testing and feedback.
    - Add more sophisticated visualizations.
    - Implement project refresh functionality.
7.  **Phase 7: Testing, Packaging & Deployment**
    - Thorough testing on all target platforms.
    - Set up build and deployment pipelines for each platform.

## 7. Open Questions & Discussion Points

- **Detailed Chapter/Scene Detection:** How will chapters/scenes be reliably detected across different formats and ad-hoc user files? **(Initial focus on Scrivener. For others, full text import as MVP. Later, explore regex patterns, specific markers for `.txt`, `.docx`, `.md`).**
- **N-gram Configuration:** How configurable should n-gram analysis be? **(Defaults of 3, 4, 5 words provided. User can define other 'n' values).**
- **Stop Word Management:** Default lists vs. user-customizable lists? Per-project or global? **(Both default and user-configurable. Global and per-project, with per-project applicable to cross-project comparisons).**
- **Advanced Text Processing:** Is stemming/lemmatization required for initial versions, or can it be a future enhancement?
- **Performance:** How to handle very large manuscripts efficiently, both during parsing and analysis? (Background processing, isolates).
- **Error Handling:** Robust error handling for file parsing and database operations.
- **Scrivener Project Complexity:** Scrivener projects can be complex (nested folders, metadata, notes, snapshots). What is the scope of data to be extracted? (Focus on main manuscript text first).
- **Ulysses Support:** Ulysses can export to `.docx`, `.md`, and plain text. `.md` seems like a good primary target. Text bundles (zipped `.textbundle`) might also be considered later if `.md` is insufficient.

This plan provides a foundational roadmap. We can refine and add details as the project progresses.
