ALTER TABLE dfuser.tbls_regions drop column IF EXISTS time_zone;
ALTER TABLE dfuser.tbls_regions ADD time_zone varchar(50);

UPDATE dfuser.tbls_regions set time_zone = 'Asia/Hong_Kong' where fin_id = 'HK'
;
UPDATE dfuser.tbls_regions set time_zone = 'Asia/Singapore' where fin_id = 'SG'
;
UPDATE dfuser.tbls_regions set time_zone = 'Asia/Kuala_Lumpur' where fin_id = 'MY'
;
UPDATE dfuser.tbls_regions set time_zone = 'Asia/Singapore' where fin_id = 'DF'
;



--2019-12-09-MultipleVault_PhysicalVaultsFunction_DFUserDB.sql
DELETE FROM dfuser.tbls_functions where fin_id='Multiple Vaults_EndUser';
INSERT INTO dfuser.tbls_functions(
	fin_id, name, group_id, maker_checker_required, parent_id, display_name, is_deleted, created, created_by, last_updated, last_updated_by, last_checked_by, last_maked, last_updated_db, mod_id, maker_checker_status, shadow_id, process_method, sort_order, hot_key, display_menu)
	VALUES ('Multiple Vaults_EndUser', 'Physical Vaults', 'EndUser', 'Y', 'Vaults_Static_EndUser', 
	'Physical Vaults', 'N','2011-12-13 07:36:10', 'System', '2011-12-13 07:36:10', 'System', 'System',
	'2011-12-13 07:36:10','2011-12-13 07:36:10', 1, 'COMMITTED', '-1', 'vault/vaultDataAction.do?method=viewVaultList',
	300514, null, 'Y');



--2019-12-12-UserDefaultVaultFunction-DFUserDB.sql	 
DELETE FROM dfuser.tbls_functions where fin_id='RepositoriesDefault_EndUser_RepositoriesDefault_EndUser';
INSERT INTO dfuser.tbls_functions(
	fin_id, name, group_id, maker_checker_required, parent_id, display_name, is_deleted, created, created_by, last_updated, last_updated_by,
	last_checked_by, last_maked, last_updated_db, mod_id, maker_checker_status, shadow_id, process_method, sort_order, hot_key, display_menu)
	VALUES ('RepositoriesDefault_EndUser_RepositoriesDefault_EndUser', 'Assign User Default Vault', 'EndUser', 'N', 'Vaults Processing_ROOT_EndUser', 
	'Assign User Default Vault', 'N','2011-12-13 07:36:10', 'System', '2011-12-13 07:36:10', 'System', 'System',
	'2011-12-13 07:36:10','2011-12-13 07:36:10', 1, 'COMMITTED', '-1', 'repositoriesSetDefaultAction.do?method=viewRepositoriesDefaultForUser',
	8050, null, 'Y');


--2020-01-03-BLISM134-StockTransferFunctionInsert_DFUserDB.sql
DELETE FROM dfuser.tbls_functions where fin_id='INTERVAULT_Deals_EndUser';
INSERT INTO dfuser.tbls_functions (fin_id, name, group_id, maker_checker_required, parent_id, display_name, is_deleted, created, created_by, last_updated, last_updated_by, last_checked_by, last_maked, last_updated_db, mod_id, maker_checker_status, shadow_id, process_method, sort_order, hot_key, display_menu) VALUES ('INTERVAULT_Deals_EndUser', 'Stock Transfer Deal', 'EndUser', 'N', 'Deals_EndUser', 'Stock Transfer Deal', 'N', '2011-09-15 18:04:34.000000', 'System', '2011-09-15 18:04:34.000000', 'System', 'System', '2011-09-15 18:04:34.000000', '2011-09-15 18:04:50.000000', 1, 'COMMITTED', '-1', 'deals/dealsFOffice.do?method=createDealTransferleg', 50020, null, 'Y');



--2020-01-30-StockTransferShipmentFunctions_DFUserDB.SQL
DELETE FROM dfuser.tbls_functions where fin_id='StockTransfer_ShipmentRecords_EndUser_Shipment Processing_ROOT_EndUser';
INSERT INTO dfuser.tbls_functions (fin_id, name, group_id, maker_checker_required, parent_id, display_name, is_deleted, created, created_by, last_updated, last_updated_by, last_checked_by, last_maked, last_updated_db, mod_id, maker_checker_status, shadow_id, process_method, sort_order, hot_key, display_menu) VALUES ('StockTransfer_ShipmentRecords_EndUser_Shipment Processing_ROOT_EndUser', 'Stock Transfer', 'EndUser', 'N', 'ShipmentRecords_EndUser_Shipment Processing_ROOT_EndUser', 'Stock Transfer', 'N', '2020-01-06 08:29:24.827531', 'System', '2020-01-06 08:29:24.827531', 'System', 'System', '2020-01-06 08:29:24.827531', '2020-01-06 08:29:24.827531', 1, 'COMMITTED', '-1', 'shipping/ShipmentAction.do?method=createStockTransferShipment', 900118, null, 'Y');


DELETE FROM dfuser.tbls_functions where fin_id='StockTransfer_EndUser_BankNotesDealsLegs_EndUser_Vaults Processing_ROOT_EndUser';
INSERT INTO dfuser.tbls_functions (fin_id, name, group_id, maker_checker_required, parent_id, display_name, is_deleted, created, created_by, last_updated, last_updated_by, last_checked_by, last_maked, last_updated_db, mod_id, maker_checker_status, shadow_id, process_method, sort_order, hot_key, display_menu) VALUES ('StockTransfer_EndUser_BankNotesDealsLegs_EndUser_Vaults Processing_ROOT_EndUser', 'StockTransfer Queue', 'EndUser', 'N', 'BankNotesDealsLegs_EndUser_Vaults Processing_ROOT_EndUser', 'StockTransfer Queue', 'N', '2011-12-13 07:34:55.000000', 'System', '2011-12-13 07:34:55.000000', 'System', 'System', '2011-12-13 07:34:55.000000', '2011-12-13 07:34:55.000000', 1, 'COMMITTED', '-1', 'vault/outBoundView.do?method=viewStockTransferQueues', 801104, null, 'Y');

