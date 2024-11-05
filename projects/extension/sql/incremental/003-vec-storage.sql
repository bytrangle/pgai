
-- switch the vector columns from storage external to storage plain
do language plpgsql $block$
declare
    _sql text;
begin
    set local search_path = pg_catalog, pg_temp;
    for _sql in
    (
        select pg_catalog.format
        ( $sql$alter table %I.%I alter column embedding set storage plain$sql$
        , v.target_schema
        , v.target_table
        )
        from ai.vectorizer v
        inner join pg_catalog.pg_class k on (k.relname = v.target_table)
        inner join pg_catalog.pg_namespace n on (k.relnamespace = n.oid and n.nspname = v.target_schema)
        inner join pg_catalog.pg_attribute a on (k.oid = a.attrelid)
        where a.attname = 'embedding'
        and a.attstorage != 'p' -- not plain
        and a.atttypmod <= 2000
    )
    loop
        raise info '%', _sql;
        execute _sql;
        commit;
        set local search_path = pg_catalog, pg_temp;
    end loop;
end;
$block$;
