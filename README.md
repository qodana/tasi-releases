# TASI - Ticket Analysis and Statistics Inspector

## Your Task

This is a test application for Git commit analysis. **Your task is to test important scenarios (from your perspective) and report the results.**

If you have questions, we'll discuss them during the interview.

## About the Application

TASI is a command-line tool that analyzes Git commit history and generates statistics based on ticket references in commit messages.

**Supported platforms:** macOS, Linux, Windows

### Features

- Extracts ticket IDs from commit messages (e.g., QD-123, IDEA-456)
- Calculates commit counts per ticket
- Provides lines of code statistics
- Shows author information per ticket
- Analyzes file changes
- Identifies commits not yet in master/main

## Usage

```bash
tasi --from <start-commit> --to <end-commit>
```

### Example

```bash
tasi --from HEAD~10 --to HEAD
```

### Output

Generates JSON file at `.tasi/tasi-report-YYYY-MM-DD-HHmmss.json`

### Command-Line Options

**Required:**
- `-f, --from <commit>` - Starting commit (hash, tag, or branch)
- `-t, --to <commit>` - Ending commit (hash, tag, or branch)

**Optional:**
- `-r, --repo <path>` - Repository path (default: current directory)
- `-c, --console` - Print to console instead of saving file
- `--create-config` - Create configuration file

---

**Good luck with testing!**
