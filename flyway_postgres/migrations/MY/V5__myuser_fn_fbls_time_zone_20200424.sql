DROP FUNCTION IF EXISTS myuser.fbls_time_zone();

CREATE OR REPLACE FUNCTION myuser.fbls_time_zone(
	)
    RETURNS character varying
    LANGUAGE 'plpgsql'

    COST 100
    VOLATILE 
AS $BODY$
DECLARE 
 print_date_time VARCHAR;
 print_date VARCHAR;
 print_time VARCHAR;
 
BEGIN

SELECT substring(timezone('Asia/Kuala_Lumpur'::text, now())::text, 1, 16) INTO print_date_time;
print_date = substring(print_date_time,9,2) ||'/'||substring(print_date_time,6,2)||'/'||substring(print_date_time,1,4);
print_time = substring(print_date_time,11,6);
print_date_time = CONCAT(print_date,' ',print_time);			 
				 
 RETURN print_date_time;
END;
$BODY$;