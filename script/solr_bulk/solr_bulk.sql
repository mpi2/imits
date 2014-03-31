-- http://www.postgresql.org/message-id/14658.1175879477@sss.pgh.pa.us
SET client_min_messages=WARNING;

-- see http://stackoverflow.com/questions/7605126/how-to-include-files-relative-to-the-current-executing-script-in-psql

BEGIN;

--\set delete_all true

\i drop_support.sql
\i drop_main.sql

\i mi_attempts.sql

\i phenotype_attempts.sql

\i alleles.sql

\i genes.sql

--\i drop_support.sql

COMMIT;
