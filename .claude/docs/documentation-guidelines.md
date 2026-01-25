# Documentation Guidelines

## File Organization

| Location              | Language | Examples                                              |
| --------------------- | -------- | ----------------------------------------------------- |
| Project root (`*.md`) | English  | README.md, CONTRIBUTING.md, CHANGELOG.md, CLAUDE.md   |
| `./docs/*.ja.md`      | Japanese | README.ja.md, CONTRIBUTING.ja.md, architecture.ja.md  |

## Best Practices

- Use English as the standard for main project documentation
- Japanese documentation serves a complementary role within `./docs/`
- Maintain clear and consistent file naming
- Keep corresponding language versions synchronized when updating
- Create locale-specific subdirectories within `./docs/` as needed

## Development Diary

### Purpose

- Record major changes and their rationale
- Document technical decisions and implementation details
- Track issues encountered and solutions
- Provide context for future developers

### Creation Rules

- Create entry when there are uncommitted changes or undocumented work
- File naming: `docs/dev-diary/YYYY-MM-DD.md`
- Auto-create file if today's date doesn't exist
- Document all work since last diary entry

### Format Requirements

Each diary entry should include:

1. Overview of work
2. Implementation details
3. Test results
4. Issues and solutions
5. Future considerations
6. Developer's mood and reflections
7. Potential refactoring opportunities

### Timing

Create the diary entry at the end of a development session or when requested.
