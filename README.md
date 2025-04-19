# Lexicon Word Frequency Analyser

A new Flutter project.

## What is Lexicon?

Lexicon is a word frequency analyzer that allows users to analyze the frequency of words in a given text. It provides a user-friendly interface for loading text files and visualizing the word frequency data in various formats.

Lexicon supports the following file formats:

- `.txt` (plain text files)
- `.doc` and `.docx` (Microsoft Word documents)
- `.pdf` (Portable Document Format)
- `.rtf` (Rich Text Format)
- `.odt` (Open Document Text)
- `.scriv` (Scrivener files)
- `.md` (Markdown files)

This means Lexicon supports most text file formats from popular writing applications such as Microsoft Word, Google Docs, Ulysses, and Scrivener.

## How does it work?

Lexicon uses the `flutter` framework to provide a cross-platform application that can run on Mac OS, Windows, and Linux devices. The application allows users to load text files from their device storage, analyse the frequency of words in the text, and visualise the data in various formats such as bar charts and pie charts.

When the user loads a text file, Lexicon processes the text to extract the words and their frequencies. The application then displays the data in a user-friendly interface, allowing users to explore the word frequency data in detail.

The text content itself is stored in a local SQLite database, which allows for efficient storage and retrieval of the text data. The application also provides a search feature that allows users to search for specific words or phrases in the text.

### Loading text files

Lexicon will load text files on the following assumptions:

- A project consists of 1 or more chapters
- A chapter consists of 1 or more scenes
- If there is only a single file, it is assumed to be a single chapter with a single scene

In practice this means that all text content is stored in the Scene table. Based on the parent ID of the scene (chapter ID) the application will be able to determine the chapter and project.

This has been designed so as to support the split chapters and scenes functionality of Scrivener and Ulysses.

### Limitations

Lexicon is currently in development and may have some limitations. Some of the known limitations include:

- The application may not support all text file formats or may have limited support for certain features in some formats.
- The application may not handle very large text files efficiently.
- The application may have some bugs or issues that need to be resolved.
- The application may not have all the features or functionality that users expect from a word frequency analyser.
- The application may not have a comprehensive user guide or documentation.
- The application may not have a fully responsive design for all screen sizes and devices.
- The application may not have all the accessibility features that some users may need.
- The application may not have all the performance optimizations that are possible.
- The application is currently limited to English text files and does not yet support other languages or character sets (planned future improvement).
- The application does not yet implement an "exclude" feature to ignore common words (e.g. "the", "and", "is") in the word frequency analysis (planned future improvement).

### Future Improvements

- Add custom word exclusion lists e.g. to ignore character names or common words in the book "universe"
- Add support for additional file formats
- Add support for additional languages and character sets
- Improve performance for large text files
- Improve the user interface and user experience
- Add more visualisation options for the word frequency data
- Add more features and functionality based on user feedback and requests
- Add a comprehensive user guide and documentation
- Add more accessibility features for users with disabilities
- Add more performance optimisations for better speed and efficiency
- Add more testing and quality assurance to ensure the application is stable and reliable
- Add ability for users to save their settings e.g. word exclusion lists, visualisation options, etc. for use on other devices
- Add ability to save overall application state and settings to system / cloud storage e.g. iCloud, Google Drive, Dropbox, Onedrive, etc.
- Add ability for users to export their word frequency data in various formats (e.g. CSV, JSON, etc.)

## Project Structure

| Directory       | Purpose                                                                               |
| --------------- | ------------------------------------------------------------------------------------- |
| `lib/`          | Contains the main code for the application.                                           |
| `lib/assets/`   | Contains the assets used in the application, such as images and fonts.                |
| `lib/db/`       | Contains the database helpers and access layer used in the application.               |
| `lib/screens/`  | Contains the UI screens of the application.                                           |
| `lib/services/` | Contains the services used in the application, such as API calls and data processing. |
| `lib/utils/`    | Contains utility functions and constants used in the application.                     |
| `lib/widgets/`  | Contains reusable widgets used in the application.                                    |
| `test/`         | Contains the test files for the application.                                          |
