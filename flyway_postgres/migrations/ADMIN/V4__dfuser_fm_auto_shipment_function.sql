

DELETE FROM dfuser.tbls_functions where fin_id='Auto_Shipment_EndUser_Vault_EndUser';

INSERT INTO dfuser.tbls_functions (fin_id, name, group_id, maker_checker_required, parent_id, display_name, is_deleted, created, created_by, last_updated, last_updated_by, last_checked_by, last_maked, last_updated_db, mod_id, maker_checker_status, shadow_id, process_method, sort_order, hot_key, display_menu) VALUES ('Auto_Shipment_EndUser_Vault_EndUser', 'Auto Shipment', 'EndUser', 'N', 'Vaults Processing_ROOT_EndUser', 'Auto Shipment', 'N', '2011-10-25 07:30:20.000000', 'System', '2011-10-25 07:30:20.000000', 'System', 'System', '2011-10-25 07:30:20.000000', '2011-10-25 07:30:20.000000', 1, 'COMMITTED', '-1', 'deals/dealsSearch.do?method=searchDeals&shipmentDealList=Y', 8051.00000, null, 'Y')
;