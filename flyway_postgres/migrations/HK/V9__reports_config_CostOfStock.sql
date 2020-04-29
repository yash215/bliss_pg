delete from "tbls_reports_config" where fin_id = 'BLSVA018A'
;
INSERT INTO "tbls_reports_config" ("fin_id", "report_code", "report_name", "report_group", "filename", "location", "is_deleted", "created", "created_by", "last_updated", "last_updated_by", "last_checked_by", "last_maked", "last_updated_db", "mod_id", "maker_checker_status", "shadow_id", "report_description", "report_type", "output_format")
VALUES
('BLSVA018A', 'BLSVA018A', 'Inventory Holding with Cost of Cash Rates', 'Vault', 'BLSVA018A_InventoryHoldingwCostOfCash.rpt', null, 'N', '2020-02-25 18:47:12.000000', 'System', '2020-02-25 18:47:12.000000', 'System', 'System', '2020-02-25 18:47:12.000000', '2020-02-25 18:47:12.000000', 0, 'COMMITTED', '-1', 'Inventory Holding with Cost of Cash Rates', 'O', 'pdf')
;

delete from "tbls_reports_config" where fin_id = 'BLSVA018E'
;
INSERT INTO "tbls_reports_config" ("fin_id", "report_code", "report_name", "report_group", "filename", "location", "is_deleted", "created", "created_by", "last_updated", "last_updated_by", "last_checked_by", "last_maked", "last_updated_db", "mod_id", "maker_checker_status", "shadow_id", "report_description", "report_type", "output_format")
VALUES
('BLSVA018E', 'BLSVA018E', 'Inventory Holding with Cost of Cash Rates(History)', 'Vault', 'BLSVA018E_InventoryHoldingwCostOfCash.rpt', null, 'N', '2020-02-25 18:47:12.000000', 'System', '2020-02-25 18:47:12.000000', 'System', 'System', '2020-02-25 18:47:12.000000', '2020-02-25 18:47:12.000000', 0, 'COMMITTED', '-1', 'Inventory Holding with Cost of Cash Rates(His)', 'B', 'pdf')
;
