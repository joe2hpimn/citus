/* citus--6.1-14--6.1-15.sql */

SET search_path TO 'pg_catalog';

CREATE OR REPLACE FUNCTION citus_truncate_trigger()
    RETURNS trigger
    LANGUAGE C STRICT
    AS 'MODULE_PATHNAME', $$citus_truncate_trigger$$;
COMMENT ON FUNCTION citus_truncate_trigger()
    IS 'trigger function called when truncating the distributed table';

RESET search_path;
