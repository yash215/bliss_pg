DELETE from tbls_vaults where fin_id = 'CONSIGNMENT_OTHERS'
;
INSERT INTO tbls_vaults (fin_id, main_vault_code, main_vault_name, sub_vault_code, sub_vault_name, cust_id, brch_id, product_id, region_id, is_deleted, created, created_by, last_updated, last_updated_by, last_checked_by, last_maked, last_updated_db, mod_id, maker_checker_status, shadow_id, vault_status, vault_type, repositories_id)
VALUES
('CONSIGNMENT_OTHERS', 'CONSIGNMENT', 'CONSIGNMENT VAULT', 'OTHERS', 'OTHERS', 'MOBV', 'MOBV_MOBV', 'BKN', null, 'N', '2020-01-07 16:08:35.852000', 'System', '2020-01-07 16:08:43.902000', 'System', 'System', '2020-01-07 16:07:36.082000', '2020-01-07 16:08:35.855438', 1, 'COMMITTED', '-1', 'ACTIVE', null, null)
;