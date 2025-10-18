#!/usr/bin/env bash
# =============================================================================
# PostgreSQL Aliases
# Managed by dotfiles: ~/dev/projects/dotfiles
# =============================================================================

# =============================================================================
# Service Control
# =============================================================================

alias pgstart='brew services start postgresql@17'
alias pgstop='brew services stop postgresql@17'
alias pgrestart='brew services restart postgresql@17'
alias pgstatus='brew services list | grep postgresql'

# =============================================================================
# Database Connections
# =============================================================================

alias pgconnect='psql -U adlimen -h localhost -d adlimen_business'
alias pgbusiness='psql -U adlimen -h localhost -d adlimen_business'
alias pgrag='psql -U adlimen -h localhost -d adlimen_rag'
alias pgfamily='psql -U adlimen -h localhost -d family'
alias pgdev='psql -U adlimen -h localhost -d adlimen_dev'
alias pganalytics='psql -U adlimen -h localhost -d adlimen_analytics'
alias pginfrastructure='psql -U adlimen -h localhost -d infrastructure'
alias pginfra='psql -U adlimen -h localhost -d infrastructure'
alias pgmonitoring='psql -U adlimen -h localhost -d monitoring'
alias pgsu='psql -U matteocervelli -h localhost -d postgres'

# =============================================================================
# Monitoring and Maintenance
# =============================================================================

alias pgmonitor='/Users/matteocervelli/dev/infrastructure/db/postgres/native/scripts/monitor-postgres.sh'
alias pgmonitorquick='/Users/matteocervelli/dev/infrastructure/db/postgres/native/scripts/monitor-postgres.sh quick'
alias pgmonitorperf='/Users/matteocervelli/dev/infrastructure/db/postgres/native/scripts/monitor-postgres.sh performance'
alias pgmonitorvector='/Users/matteocervelli/dev/infrastructure/db/postgres/native/scripts/monitor-postgres.sh vector'

# =============================================================================
# Backup and Restore
# =============================================================================

alias pgbackup='/Users/matteocervelli/dev/infrastructure/db/postgres/native/scripts/backup-postgres.sh'
alias pgverify='/Users/matteocervelli/dev/infrastructure/db/postgres/native/scripts/verify-pgvector.sh'
alias pgmigrate='/Users/matteocervelli/dev/infrastructure/db/postgres/native/scripts/migrate-from-docker.sh'

# =============================================================================
# Logs and Debugging
# =============================================================================

alias pglogs='tail -f /opt/homebrew/var/log/postgresql@17.log'
alias pglogsgrep='grep -i error /opt/homebrew/var/log/postgresql@17.log | tail -20'
alias pgconfig='code /opt/homebrew/var/postgresql@17/postgresql.conf'

# =============================================================================
# Quick Queries
# =============================================================================

alias pgsize="psql -U adlimen -h localhost -d postgres -c \"SELECT datname, pg_size_pretty(pg_database_size(datname)) as size FROM pg_database WHERE datname NOT IN ('template0', 'template1') ORDER BY pg_database_size(datname) DESC;\""
alias pgactivity="psql -U adlimen -h localhost -d postgres -c \"SELECT datname, usename, state, query_start, left(query, 50) as query FROM pg_stat_activity WHERE state = 'active';\""
alias pgconnections="psql -U adlimen -h localhost -d postgres -c \"SELECT datname, count(*) as connections FROM pg_stat_activity WHERE datname IS NOT NULL GROUP BY datname ORDER BY count(*) DESC;\""

# =============================================================================
# Vector Database Specific
# =============================================================================

alias pgvector="psql -U adlimen -h localhost -d adlimen_rag -c \"SELECT count(*) as embeddings FROM vectors.embeddings;\""
alias pgvectortest="psql -U adlimen -h localhost -d adlimen_rag -c \"CREATE TEMP TABLE test_vec (id serial, v vector(3)); INSERT INTO test_vec (v) VALUES ('[1,2,3]'), ('[4,5,6]'); SELECT v <=> '[1,2,3]'::vector as distance FROM test_vec; DROP TABLE test_vec;\""

# =============================================================================
# Development Helpers
# =============================================================================

alias pgsetup='/Users/matteocervelli/dev/infrastructure/db/postgres/native/scripts/setup-postgres.sh'
alias pgreset="pgstop && rm -rf /opt/homebrew/var/postgresql@17/* && initdb /opt/homebrew/var/postgresql@17 && pgstart && pgsetup"

# =============================================================================
# End of PostgreSQL aliases
# =============================================================================
