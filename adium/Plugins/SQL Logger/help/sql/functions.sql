create or replace function scramble(text) returns text as '
declare
    do_scramble     text := ''false'';
    entry_text      alias for $1;
    alternate_text  text;
    final_text      text;
    entry_length    int;
begin

    select value
    into   do_scramble
    from   im.preferences
    where  rule = ''scramble'';

    entry_length = length(entry_text);

    if (do_scramble <> ''true'') then
        return entry_text;
    else
        alternate_text := trim(''1345689'' from substring(entry_text,
        entry_length / 2, entry_length));
        if mod(entry_length, 3) = 0 then
            final_text := initcap(alternate_text || bit_length(entry_text));
        else
            final_text := initcap(alternate_text);
        end if;
        return final_text;
    end if;

end;
' language plpgsql;
