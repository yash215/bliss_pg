
delete from "tbls_reports_config" where fin_id = 'BLSVA017B'
;
INSERT INTO "tbls_reports_config" ("fin_id", "report_code", "report_name", "report_group", "filename", "location", "is_deleted", "created", "created_by", "last_updated", "last_updated_by", "last_checked_by", "last_maked", "last_updated_db", "mod_id", "maker_checker_status", "shadow_id", "report_description", "report_type", "output_format") VALUES ('BLSVA017B', 'BLSVA017B', 'Purchase Receipt', 'Vault', 'BLSVA017B_O_PurchaseReceipt.rpt', null, 'N', '2020-02-25 18:47:12.000000', 'System', '2020-02-25 18:47:12.000000', 'System', 'System', '2020-02-25 18:47:12.000000', '2020-02-25 18:47:12.000000', 0, 'COMMITTED', '-1', 'Purchase Receipt', 'O', 'pdf')
;

delete from "tbls_reports_config" where fin_id = 'BLSVA017S'
;
INSERT INTO "tbls_reports_config" ("fin_id", "report_code", "report_name", "report_group", "filename", "location", "is_deleted", "created", "created_by", "last_updated", "last_updated_by", "last_checked_by", "last_maked", "last_updated_db", "mod_id", "maker_checker_status", "shadow_id", "report_description", "report_type", "output_format") VALUES ('BLSVA017S', 'BLSVA017S', 'Sales Advice', 'Vault', 'BLSVA017S_O_SalesAdvice.rpt', null, 'N', '2020-02-25 18:47:12.000000', 'System', '2020-02-25 18:47:12.000000', 'System', 'System', '2020-02-25 18:47:12.000000', '2020-02-25 18:47:12.000000', 0, 'COMMITTED', '-1', 'Sales Advice', 'O', 'pdf')
;