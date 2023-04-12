CREATE OR REPLACE FUNCTION search_all_tables(search_str text)
RETURNS TABLE(table_name text, table_column_name text, table_column_value text) AS $$
DECLARE
    t_name text;
    col_name text;
    search_str2 text;
BEGIN
    CREATE TEMPORARY TABLE search_results(table_name text, column_name text, column_value text) ON COMMIT DROP;
    search_str2 := '%' || search_str || '%';
    FOR t_name, col_name IN
        SELECT table_schema || '.' || table_name, column_name
        FROM information_schema.columns
        WHERE table_schema = 'public' AND data_type IN ('character varying', 'text')
    LOOP
        EXECUTE format('INSERT INTO search_results SELECT %1$L, %2$L, LEFT(%3$I, 3630) FROM %1$I WHERE %3$I ILIKE %4$L', t_name, col_name, col_name, search_str2);
    END LOOP;
    RETURN QUERY SELECT table_name, column_name AS table_column_name, column_value AS table_column_value
                 FROM search_results;
END;
$$ LANGUAGE plpgsql;





CREATE OR REPLACE FUNCTION search_all_tables(search_str text) RETURNS TABLE(table_name text, table_column_name text, table_column_value text) AS $$ DECLARE t_name text; col_name text; search_str2 text; BEGIN CREATE TEMPORARY TABLE search_results(table_name text, column_name text, column_value text) ON COMMIT DROP; search_str2 := '%' || search_str || '%'; FOR t_name, col_name IN SELECT table_schema || '.' || table_name, column_name FROM information_schema.columns WHERE table_schema = 'public' AND data_type IN ('character varying', 'text') LOOP EXECUTE format('INSERT INTO search_results SELECT %1$L, %2$L, LEFT(%3$I, 3630) FROM %1$I WHERE %3$I ILIKE %4$L', t_name, col_name, col_name, search_str2); END LOOP; RETURN QUERY SELECT table_name, column_name AS table_column_name, column_value AS table_column_value FROM search_results; END; $$ LANGUAGE plpgsql;
