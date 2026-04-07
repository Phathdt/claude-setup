---
name: prisma
description: 'Prisma ORM operations: migrations (create, dev, deploy, reset), schema management, seeding, studio. Use when working with Prisma schema changes, database migrations, or Prisma CLI tasks.'
argument-hint: 'migrate|generate|studio|seed|reset [args]'
---

# Prisma Skill

Handles Prisma ORM operations with correct CLI commands — especially migrations with proper naming.

## When to Use

- Creating or applying database migrations
- Modifying `schema.prisma` and syncing with DB
- Generating Prisma Client after schema changes
- Seeding database
- Resetting database
- Opening Prisma Studio

## Default (No Arguments)

If invoked without arguments, use `AskUserQuestion` to present available operations:

| Operation  | Description                                    |
| ---------- | ---------------------------------------------- |
| `migrate`  | Create & apply migration (dev or deploy)       |
| `generate` | Regenerate Prisma Client                       |
| `studio`   | Open Prisma Studio                             |
| `seed`     | Run database seed script                       |
| `reset`    | Reset database (destructive)                   |
| `status`   | Check migration status                         |
| `diff`     | Show schema diff without applying              |
| `drift`    | Detect & fix schema drift (DB vs schema.prisma)|

## Arguments

### `migrate` — Create & Apply Migration

**CRITICAL: Always use real `prisma migrate dev` to create migrations. NEVER fabricate migration folder names or timestamps manually.**

#### Workflow

1. **Detect schema changes** — Read `schema.prisma`, compare with current DB state
2. **Ask for migration name** — If not provided, ask user for a descriptive kebab-case name
3. **Run migration** — Execute the appropriate command based on environment

#### Commands

```bash
# Development: create + apply migration (interactive, generates SQL)
npx prisma migrate dev --name <descriptive-kebab-name>

# Production: apply pending migrations (non-interactive)
npx prisma migrate deploy

# Check migration status
npx prisma migrate status

# Show diff without applying
npx prisma migrate diff --from-schema-datamodel prisma/schema.prisma --to-schema-datasource prisma/schema.prisma

# Reset database (destructive — confirm with user first)
npx prisma migrate reset
```

#### Migration Naming Convention

Use descriptive kebab-case names that describe the change:

- `add-user-email-field`
- `create-orders-table`
- `add-draft-status-to-posts`
- `rename-modified-by-column`
- `add-index-on-created-at`

**BAD examples (never do this):**
- `20260407000000_add_draft_status` — fabricated timestamp
- `migration` — too generic
- `fix` — not descriptive

### `generate` — Regenerate Prisma Client

```bash
npx prisma generate
```

Run after any schema change to update the generated client types.

### `studio` — Open Prisma Studio

```bash
npx prisma studio
```

### `seed` — Run Database Seed

```bash
npx prisma db seed
```

### `reset` — Reset Database

**DESTRUCTIVE: Always confirm with user before running.**

```bash
npx prisma migrate reset
```

### `status` — Migration Status

```bash
npx prisma migrate status
```

### `diff` — Schema Diff

```bash
npx prisma migrate diff \
  --from-schema-datamodel prisma/schema.prisma \
  --to-schema-datasource prisma/schema.prisma
```

### `drift` — Detect & Fix Schema Drift

Schema drift happens when the database schema diverges from `schema.prisma` — e.g., manual SQL changes, failed migrations, or direct DB edits.

#### Diagnosis

```bash
# Step 1: Check migration status — shows failed or pending migrations
npx prisma migrate status

# Step 2: Diff DB state against schema.prisma
npx prisma migrate diff \
  --from-schema-datasource prisma/schema.prisma \
  --to-schema-datamodel prisma/schema.prisma
```

Read the diff output carefully. It shows what SQL would be needed to bring the DB in sync with `schema.prisma`.

#### Fix Strategies (choose based on situation)

**A. DB has extra changes not in schema (most common)**
Someone ran manual SQL or another tool modified the DB.

```bash
# Option 1: Baseline — mark current DB state as already migrated
# Use when DB is correct and you want schema.prisma to catch up
npx prisma db pull        # Update schema.prisma from DB
npx prisma generate       # Regenerate client

# Option 2: If schema.prisma is the source of truth, create migration to fix DB
npx prisma migrate dev --name fix-drift-<description>
```

**B. Migration history is out of sync**
The `_prisma_migrations` table doesn't match the migration files.

```bash
# Mark a migration as applied without running it (DB already has the changes)
npx prisma migrate resolve --applied <migration-name>

# Mark a migration as rolled back
npx prisma migrate resolve --rolled-back <migration-name>
```

**C. Development environment — nuclear option**
Only for dev environments. **NEVER in production.**

```bash
# Reset everything: drop DB, replay all migrations, re-seed
npx prisma migrate reset
```

#### Decision Tree

1. Run `prisma migrate status` → any failed migrations?
   - Yes → `prisma migrate resolve --rolled-back <name>`, fix schema, create new migration
   - No → continue
2. Run `prisma migrate diff` → any differences?
   - DB has extra stuff → `prisma db pull` to sync schema, or create migration to revert
   - DB is missing stuff → `prisma migrate dev --name fix-<description>`
   - No diff → drift resolved
3. Always run `prisma generate` after fixing

**IMPORTANT:** Always confirm with user before applying any drift fix. Show them the diff first.

## Important Rules

1. **NEVER fabricate migration folders or timestamps** — Always use `prisma migrate dev --name` which generates the correct timestamped folder
2. **NEVER write SQL migration files manually** unless explicitly asked — Prisma generates them
3. **Always run `prisma generate`** after schema changes
4. **Confirm destructive operations** (`reset`, `migrate dev` on production data) with user
5. **Check `prisma migrate status`** before deploying to understand pending migrations
6. **Use `--create-only`** flag when you want to create migration SQL without applying:
   ```bash
   npx prisma migrate dev --name <name> --create-only
   ```

## Schema Change Workflow

Standard workflow when modifying Prisma schema:

1. Edit `prisma/schema.prisma`
2. Run `npx prisma migrate dev --name <descriptive-name>` to create + apply migration
3. Run `npx prisma generate` (usually auto-runs after migrate dev)
4. Update application code to use new schema
5. Commit both schema and migration files

## Resources

- Prisma Docs: https://www.prisma.io/docs
- Prisma Migrate: https://www.prisma.io/docs/orm/prisma-migrate
- Prisma CLI Reference: https://www.prisma.io/docs/orm/reference/prisma-cli-reference
