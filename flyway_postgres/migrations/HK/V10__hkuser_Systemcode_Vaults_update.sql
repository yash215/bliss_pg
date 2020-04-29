delete from tbls_system_codes where fin_id = 'COC'
;
INSERT INTO tbls_system_codes (fin_id, code, name, description, is_deleted, created, created_by, last_updated, last_updated_by, last_checked_by, last_maked, last_updated_db, mod_id, maker_checker_status, shadow_id) 
VALUES 
('COC', 'COC', 'Cost of Cash', 'Cost of Cash', 'N', '2018-07-19 16:29:14.053000', 'System', '2018-07-19 16:29:14.053000', 'trdbth', 'System', '2018-07-19 16:28:15.514000', '2018-07-19 16:29:14.056124', 1, 'COMMITTED', '-1')
;
