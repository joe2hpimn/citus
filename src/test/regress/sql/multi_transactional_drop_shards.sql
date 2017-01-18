--
-- MULTI_TRANSACTIONAL_DROP_SHARDS
--
-- Tests that check the metadata returned by the master node.


ALTER SEQUENCE pg_catalog.pg_dist_shardid_seq RESTART 1410000;
ALTER SEQUENCE pg_catalog.pg_dist_jobid_seq RESTART 1410000;

SET citus.shard_count TO 4;


-- test DROP TABLE(ergo master_drop_all_shards) in transaction, then ROLLBACK
CREATE TABLE transactional_drop_shards(column1 int);
SELECT create_distributed_table('transactional_drop_shards', 'column1');

BEGIN;
DROP TABLE transactional_drop_shards;
ROLLBACK;

-- verify metadata is not deleted
SELECT shardid FROM pg_dist_shard WHERE logicalrelid = 'transactional_drop_shards'::regclass ORDER BY shardid;
SELECT
    shardid, shardstate, nodename, nodeport
FROM
    pg_dist_shard_placement
WHERE
    shardid IN (SELECT shardid FROM pg_dist_shard WHERE logicalrelid = 'transactional_drop_shards'::regclass ORDER BY shardid)
ORDER BY
    shardid;

-- verify table is not dropped
\d transactional_drop_shards;

-- verify shards are not dropped
\c - - - :worker_1_port
\d transactional_drop_shards_*;
\c - - - :master_port


-- test DROP TABLE(ergo master_drop_all_shards) in transaction, then COMMIT
BEGIN;
DROP TABLE transactional_drop_shards;
COMMIT;

-- verify metadata is deleted
SELECT shardid FROM pg_dist_shard WHERE shardid IN (1410000, 1410001, 1410002, 1410003) ORDER BY shardid;
SELECT
    shardid, shardstate, nodename, nodeport
FROM
    pg_dist_shard_placement
WHERE
    shardid IN (1410000, 1410001, 1410002, 1410003)
ORDER BY
    shardid;

-- verify table is dropped
\d transactional_drop_shards;

-- verify shards are dropped
\c - - - :worker_1_port
\d transactional_drop_shards_*;
\c - - - :master_port


-- test master_delete_protocol in transaction, then ROLLBACK
CREATE TABLE transactional_drop_shards(column1 int);
SELECT create_distributed_table('transactional_drop_shards', 'column1', 'append');
SELECT master_create_empty_shard('transactional_drop_shards');

BEGIN;
SELECT master_apply_delete_command('DELETE FROM transactional_drop_shards');
ROLLBACK;

-- verify metadata is not deleted
SELECT shardid FROM pg_dist_shard WHERE logicalrelid = 'transactional_drop_shards'::regclass ORDER BY shardid;
SELECT
    shardid, shardstate, nodename, nodeport
FROM
    pg_dist_shard_placement
WHERE
    shardid IN (SELECT shardid FROM pg_dist_shard WHERE logicalrelid = 'transactional_drop_shards'::regclass ORDER BY shardid)
ORDER BY
    shardid;

-- verify shards are not dropped
\c - - - :worker_1_port
\d transactional_drop_shards_*;
\c - - - :master_port


-- test master_delete_protocol in transaction, then COMMIT
BEGIN;
SELECT master_apply_delete_command('DELETE FROM transactional_drop_shards');
COMMIT;

-- verify metadata is deleted
SELECT shardid FROM pg_dist_shard WHERE logicalrelid = 'transactional_drop_shards'::regclass ORDER BY shardid;
SELECT
    shardid, shardstate, nodename, nodeport
FROM
    pg_dist_shard_placement
WHERE
    shardid IN (SELECT shardid FROM pg_dist_shard WHERE logicalrelid = 'transactional_drop_shards'::regclass ORDER BY shardid)
ORDER BY
    shardid;

-- verify shards are dropped
\c - - - :worker_1_port
\d transactional_drop_shards_*;
\c - - - :master_port


-- test DROP table in a transaction after insertion
SELECT master_create_empty_shard('transactional_drop_shards');

BEGIN;
INSERT INTO transactional_drop_shards VALUES (1);
DROP TABLE transactional_drop_shards;
ROLLBACK;

-- verify metadata is not deleted
SELECT shardid FROM pg_dist_shard WHERE logicalrelid = 'transactional_drop_shards'::regclass ORDER BY shardid;
SELECT
    shardid, shardstate, nodename, nodeport
FROM
    pg_dist_shard_placement
WHERE
    shardid IN (SELECT shardid FROM pg_dist_shard WHERE logicalrelid = 'transactional_drop_shards'::regclass ORDER BY shardid)
ORDER BY
    shardid;

-- verify table is not dropped
\d transactional_drop_shards;

-- verify shards are not dropped
\c - - - :worker_1_port
\d transactional_drop_shards_*;
\c - - - :master_port


-- test master_apply_delete_command in a transaction after insertion
BEGIN;
INSERT INTO transactional_drop_shards VALUES (1);
SELECT master_apply_delete_command('DELETE FROM transactional_drop_shards');
ROLLBACK;

-- verify metadata is not deleted
SELECT shardid FROM pg_dist_shard WHERE logicalrelid = 'transactional_drop_shards'::regclass ORDER BY shardid;
SELECT
    shardid, shardstate, nodename, nodeport
FROM
    pg_dist_shard_placement
WHERE
    shardid IN (SELECT shardid FROM pg_dist_shard WHERE logicalrelid = 'transactional_drop_shards'::regclass ORDER BY shardid)
ORDER BY
    shardid;

-- verify shards are not dropped
\c - - - :worker_1_port
\d transactional_drop_shards_*;


-- test DROP table with failing worker
CREATE FUNCTION fail_drop_table() RETURNS event_trigger AS $fdt$
    BEGIN
        RAISE 'illegal value';
    END;
$fdt$ LANGUAGE plpgsql;

CREATE EVENT TRIGGER fail_drop_table ON sql_drop EXECUTE PROCEDURE fail_drop_table();

\c - - - :master_port

\set VERBOSITY terse
DROP TABLE transactional_drop_shards;
\set VERBOSITY default

-- verify metadata is not deleted
SELECT shardid FROM pg_dist_shard WHERE logicalrelid = 'transactional_drop_shards'::regclass ORDER BY shardid;
SELECT
    shardid, shardstate, nodename, nodeport
FROM
    pg_dist_shard_placement
WHERE
    shardid IN (SELECT shardid FROM pg_dist_shard WHERE logicalrelid = 'transactional_drop_shards'::regclass ORDER BY shardid)
ORDER BY
    shardid;

-- verify table is not dropped
\d transactional_drop_shards;

-- verify shards are not dropped
\c - - - :worker_1_port
\d transactional_drop_shards_*;
\c - - - :master_port


-- test master_apply_delete_command table with failing worker
\set VERBOSITY terse
SELECT master_apply_delete_command('DELETE FROM transactional_drop_shards');
\set VERBOSITY default

-- verify metadata is not deleted
SELECT shardid FROM pg_dist_shard WHERE logicalrelid = 'transactional_drop_shards'::regclass ORDER BY shardid;
SELECT
    shardid, shardstate, nodename, nodeport
FROM
    pg_dist_shard_placement
WHERE
    shardid IN (SELECT shardid FROM pg_dist_shard WHERE logicalrelid = 'transactional_drop_shards'::regclass ORDER BY shardid)
ORDER BY
    shardid;

-- verify shards are not dropped
\c - - - :worker_1_port
\d transactional_drop_shards_*;
\c - - - :master_port

-- clean the workspace
\c - - - :worker_1_port
DROP EVENT TRIGGER fail_drop_table;
\c - - - :master_port
DROP TABLE transactional_drop_shards;
