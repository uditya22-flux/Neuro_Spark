-- Add 'discovery' vertical to all Engine 2 tables.
-- Uses an anonymous block to safely drop and recreate the auto-generated check constraints for vertical_id.

DO $$ 
DECLARE 
    r RECORD;
BEGIN 
    FOR r IN (
        SELECT conname, conrelid::regclass::text as tablename 
        FROM pg_constraint 
        WHERE contype = 'c' 
        AND conname LIKE '%vertical_id_check'
    ) LOOP
        EXECUTE 'ALTER TABLE ' || r.tablename || ' DROP CONSTRAINT ' || r.conname;
        EXECUTE 'ALTER TABLE ' || r.tablename || ' ADD CONSTRAINT ' || r.conname || 
                ' CHECK (vertical_id IN (''calendar_genius'', ''constellation_mapper'', ''discovery''))';
    END LOOP;
END $$;
