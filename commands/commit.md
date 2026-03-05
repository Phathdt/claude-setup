# Git Commit Message Generation Prompt

Please review all changed and new files shown in `git status`, then generate a concise and clear commit message following these guidelines:

## Format Requirements:

- Start with conventional commit type: `feat`, `fix`, `chore`, `docs`, `style`, `refactor`, `test`, etc.
- Include an appropriate emoji icon
- Keep the message concise but descriptive
- Use present tense, imperative mood
- Maximum 50 characters for the subject line

## Conventional Commit Types:

- `feat` ✨ - New feature
- `fix` 🐛 - Bug fix
- `chore` 🔧 - Maintenance tasks
- `docs` 📝 - Documentation changes
- `style` 💄 - Code style/formatting
- `refactor` ♻️ - Code refactoring
- `test` 🧪 - Adding/updating tests
- `perf` ⚡ - Performance improvements
- `ci` 👷 - CI/CD changes
- `build` 📦 - Build system changes

## Example Format:

```
feat: ✨ add user authentication system
fix: 🐛 resolve memory leak in data processing
chore: 🔧 update dependencies to latest versions
docs: 📝 add API documentation for user endpoints
```

## Instructions:

1. Analyze all files in git status (both modified and new files)
2. Use the user's hint/suggestion as the main message content
3. Identify the appropriate commit type based on file changes
4. Choose appropriate emoji and commit type
5. Format the user's hint into a proper commit message
6. Keep it concise and follow conventional commit format

## Usage:

**User provides:** Main message hint/description
**AI generates:** Properly formatted commit with type + emoji + user's message

**Example:**

- User hint: "add login validation"
- Generated: `feat: ✨ add login validation`

- User hint: "memory leak in parser"
- Generated: `fix: 🐛 resolve memory leak in parser`

Please generate the commit message using:

- File changes from git status (for determining commit type)
- User's hint/message (for the main content)
