-- http://www.postgresql.org/message-id/14658.1175879477@sss.pgh.pa.us
SET client_min_messages=WARNING;

--CREATE TABLE solr_temp_projects(
--    project text, gene_id int, status text, pipeline text, vproject text, vstatus text, vpipeline text
--);
--
--CREATE OR REPLACE FUNCTION solr_mi_attempt_in_progress_id (in int)
--RETURNS int AS $$
--DECLARE
--    tmp RECORD;
--BEGIN
--    FOR tmp IN SELECT id from mi_attempt_status_stamps where mi_attempt_id = $1 and status_id = 1
--    LOOP
--        return tmp.id;
--    END LOOP;
--END;
--$$ LANGUAGE plpgsql;
--
---- http://stackoverflow.com/questions/18987650/postgresql-select-only-the-first-record-per-id-based-on-sort-order
--
--CREATE OR REPLACE FUNCTION solr_phenotype_attempt_in_progress_id (in int)
--RETURNS int AS $$
--DECLARE
--    tmp RECORD;
--BEGIN
--    FOR tmp IN SELECT id from phenotype_attempt_status_stamps where phenotype_attempt_id = $1 and status_id = 1
--    LOOP
--        return tmp.id;
--    END LOOP;
--END;
--$$ LANGUAGE plpgsql;


-- see http://stackoverflow.com/questions/7605126/how-to-include-files-relative-to-the-current-executing-script-in-psql


\i drop.sql

\i mi_attempts.sql

\i phenotype_attempts.sql

\i alleles.sql

\i genes3.sql
