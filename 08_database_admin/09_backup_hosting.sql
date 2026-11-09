-- ============================================================================
-- 09_backup_hosting.sql — Backup, Restore, and Hosting Notes
-- ============================================================================
-- SKILL LEVEL : Intermediate
-- TOPICS      : mysqldump, mysqlpump, point-in-time recovery, binary log,
--               replication basics, hosting options, snapshot backups.
-- ----------------------------------------------------------------------------
-- TEXTBOOK DEPTH
--   Backups are the single most important operational discipline for any
--   production database. A "backup" is a copy you have TESTED RESTORING
--   FROM. Untested backups are wishes, not backups.
--
--   MySQL backup strategies:
--     1. LOGICAL BACKUP  — export SQL statements that recreate the schema
--        and data. Tools: mysqldump, mysqlpump. Portable but slow on
--        large datasets (replays every INSERT).
--     2. PHYSICAL BACKUP — copy the InnoDB data files. Tools: Percona
--        XtraBackup, MySQL Enterprise Backup, file-system snapshots (LVM,
--        ZFS, EBS). Fast restore; not portable across versions/engines.
--     3. POINT-IN-TIME RECOVERY — restore from the last full backup, then
--        replay the binary log up to a chosen timestamp.
--     4. REPLICATION — maintain a hot standby that streams changes from
--        the master asynchronously. Not a backup by itself but useful for
--        failover and offsite reads.
--
--   3-2-1 rule: keep at least 3 copies of your data, on 2 different media,
--   with 1 offsite. Test restores quarterly.
-- ============================================================================

USE ecom;

-- ============================================================================
-- mysqldump — the standard logical backup tool (run from the shell, NOT mysql)
-- ============================================================================

-- Backup a single database:
--   mysqldump -u root -p ecom > ecom_backup.sql

-- Backup with stored procedures, functions, triggers, events:
--   mysqldump -u root -p --routines --triggers --events ecom > ecom_full.sql

-- Backup ALL databases:
--   mysqldump -u root -p --all-databases > all_dbs.sql

-- Backup schema only (no data):
--   mysqldump -u root -p --no-data ecom > ecom_schema.sql

-- Backup data only (no schema):
--   mysqldump -u root -p --no-create-info ecom > ecom_data.sql

-- Backup with extended insert (one INSERT per table — faster restore):
--   mysqldump -u root -p --extended-insert ecom > ecom_ext.sql

-- Backup in a single transaction (consistent snapshot for InnoDB):
--   mysqldump -u root -p --single-transaction ecom > ecom_consistent.sql

-- Compressed backup (gzip):
--   mysqldump -u root -p ecom | gzip > ecom.sql.gz

-- Backup specific tables:
--   mysqldump -u root -p ecom customers orders > cust_orders.sql

-- ============================================================================
-- Restore from a dump
-- ============================================================================

-- Restore a database:
--   mysql -u root -p ecom < ecom_backup.sql
-- Or inside the mysql client:
--   SOURCE /path/to/ecom_backup.sql;

-- ============================================================================
-- mysqlpump — parallel dump tool (MySQL 5.7+)
-- ============================================================================

-- Parallel dump (faster on multi-core servers):
--   mysqlpump -u root -p --default-parallelism=4 ecom > ecom_pump.sql

-- ============================================================================
-- Point-in-time recovery
-- ============================================================================

-- 1. Restore the last full backup:
--      mysql -u root -p ecom < ecom_backup.sql
-- 2. Identify the binlog position from the backup (mysqldump writes it
--    in the header when --master-data is used).
-- 3. Replay the binlog up to the chosen time:
--      mysqlbinlog --stop-datetime="2024-06-15 12:00:00" \
--                  /var/lib/mysql/mysql-bin.000123 | mysql -u root -p

-- ============================================================================
-- Binary log (binlog) — required for replication + PITR
-- ============================================================================

-- Check if binlog is enabled:
SHOW VARIABLES LIKE 'log_bin';
SHOW VARIABLES LIKE 'binlog_format';

-- Show current binlog files:
SHOW BINARY LOGS;

-- Show events in the current binlog:
-- SHOW BINLOG EVENTS IN 'mysql-bin.000123' LIMIT 10;

-- Purge old binlogs (be careful!):
-- PURGE BINARY LOGS BEFORE NOW() - INTERVAL 7 DAY;

-- ============================================================================
-- Replication basics
-- ============================================================================

-- On the master, log_bin must be enabled and a replication user created:
-- CREATE USER 'repl'@'%' IDENTIFIED BY 'strongpassword';
-- GRANT REPLICATION SLAVE ON *.* TO 'repl'@'%';

-- On the slave:
-- CHANGE REPLICATION SOURCE TO
--     SOURCE_HOST='master.example.com',
--     SOURCE_USER='repl',
--     SOURCE_PASSWORD='strongpassword',
--     SOURCE_LOG_FILE='mysql-bin.000123',
--     SOURCE_LOG_POS=12345;
-- START REPLICA;
-- SHOW REPLICA STATUS\G

-- ============================================================================
-- Hosting options
-- ============================================================================

-- When choosing where to host MySQL:
--   * Self-managed on VM / dedicated server (most control, most work)
--   * AWS RDS for MySQL (managed backups, patching, scaling, multi-AZ)
--   * Google Cloud SQL for MySQL
--   * Azure Database for MySQL
--   * PlanetScale (Vitess-based MySQL, serverless branching)
--   * DigitalOcean Managed MySQL
--   * Aiven for MySQL (multi-cloud)

-- Considerations:
--   * High availability: multi-AZ, automatic failover
--   * Backups: automated daily + point-in-time recovery (binlog retention)
--   * Read replicas: scale reads horizontally
--   * Encryption: at rest (TDE) and in transit (TLS)
--   * Connection pooling: ProxySQL, RDS Proxy
--   * Cost: storage, IOPS, network egress

-- ============================================================================
-- Snapshot-style backup using SELECT INTO OUTFILE (data export)
-- ============================================================================

-- Export a table to a CSV file on the server (requires FILE privilege and
-- secure_file_priv set appropriately):
-- SELECT * FROM customers
-- INTO OUTFILE '/var/lib/mysql-files/customers.csv'
-- FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
-- LINES TERMINATED BY '\n';

-- Import from a CSV:
-- LOAD DATA INFILE '/var/lib/mysql-files/customers.csv'
-- INTO TABLE customers
-- FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
-- LINES TERMINATED BY '\n'
-- IGNORE 1 LINES;

-- ============================================================================
-- EXERCISES
-- ============================================================================

-- EASY
-- E1.  Write the mysqldump command to back up the ecom database to a file
--      named ecom_backup.sql.
-- E2.  Write the mysqldump command to back up ONLY the schema (no data).

-- MEDIUM
-- E3.  Write a mysqldump command that produces a consistent backup using a
--      single transaction, including routines and triggers, compressed.
-- E4.  Write the command to restore ecom from ecom_backup.sql.

-- HARD
-- E5.  Describe in a comment the steps to perform point-in-time recovery
--      to 2024-06-15 14:00:00. What two pieces of input do you need?

-- EXPERT
-- E6.  Compare logical vs physical backups. When would you choose each?
--      Provide a concrete example of when mysqldump would be too slow
--      and what you'd use instead.

-- End of file 09_backup_hosting.sql
