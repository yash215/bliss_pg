
drop VIEW IF EXISTS vbls_uob_deal_entries;
drop VIEW IF EXISTS vbls_deal_search_view;
drop VIEW IF EXISTS vbls_bkn_deal_entries ;
drop VIEW IF EXISTS vbls_commission_entries ;
drop VIEW IF EXISTS vbls_ctc_entries ;
drop VIEW IF EXISTS vbls_discrepancy_entries;
drop VIEW IF EXISTS vbls_fx_deal_entries ;
drop VIEW IF EXISTS vbls_fx_position_dealentries;
drop VIEW IF EXISTS vbls_mtm_entries;
drop view IF EXISTS vbls_inv_pos_grp_physical ;

ALTER TABLE tbls_regions drop column IF EXISTS time_zone;
ALTER TABLE tbls_regions ADD time_zone varchar(50);


-- 2019-12-09-MultipleVault_TableChanges_RegionDB.sql

ALTER TABLE TBLS_VAULTS drop column IF EXISTS VAULT_TYPE;
alter table TBLS_VAULTS add VAULT_TYPE varchar(30);

ALTER TABLE TBLS_VAULTS drop column IF EXISTS REPOSITORIES_ID;
alter table TBLS_VAULTS add REPOSITORIES_ID varchar(60);

ALTER TABLE TBLS_VAULTS drop column IF EXISTS VAULT_STATUS;
alter table TBLS_VAULTS add VAULT_STATUS VARCHAR(60);

ALTER TABLE TBLS_REPOSITORIES_USERS_INT drop column IF EXISTS IS_DEFAULT;
alter table TBLS_REPOSITORIES_USERS_INT add IS_DEFAULT VARCHAR(1);	

ALTER TABLE TBLS_REPOSITORIES drop column IF EXISTS GLBRANCH_CODE;
alter table TBLS_REPOSITORIES add GLBRANCH_CODE VARCHAR(30);

ALTER TABLE TBLS_discrepancy_records drop column IF EXISTS disc_vault_id;
alter table TBLS_discrepancy_records add disc_vault_id varchar(60);



create or replace view vbls_inv_pos_grp_physical
            (fin_id, currency, productscode, denomination, denomcode, denomid, banknotestype, vaultid, main_vault_name,
             sub_vault_name, vaultdate, datediff, dateflag, inventory)
as

with all_vaults_inventory_position as (
    select (((((((((((((invpos.currency::text || '_'::text) || invpos.productscode::text) || '_'::text) ||
                     invpos.denomid::text) || '_'::text) || invpos.banknotestypeid::text) || '_'::text) ||
                 'All Regional Vaults'::text) || '_'::text) ||
               invpos.sub_vault_name::text) || '_'::text) || invpos.vaultdate) || '_'::text) || invpos.systemdate
                                                                       as fin_id,
           invpos.currency,
           invpos.productscode,
           invpos.denomid,
           invpos.denomination,
           invpos.denomcode,
           invpos.banknotestypeid,
           invpos.banknotestype,
           'All Regional Vaults_'::text || invpos.sub_vault_name::text AS vaultid,
           'All Regional Vaults'::text                                 AS main_vault_name,
           invpos.sub_vault_name,
           invpos.vaultdate,
           invpos.systemdate,
           invpos.datediff,
           invpos.dateflag,
           sum(amount)                                                 as amount
    from vbls_inventory_position invpos,
         tbls_vaults v
    where invpos.vaultid = v.fin_id
      AND v.vault_type::text = 'Regional Vault'::text
    group by invpos.currency,
             invpos.productscode,
             invpos.denomid,
             invpos.denomination,
             invpos.denomcode,
             invpos.banknotestypeid,
             invpos.banknotestype,
             invpos.sub_vault_name,
             invpos.vaultdate,
             invpos.systemdate,
             invpos.datediff,
             invpos.dateflag
)

SELECT (((((((a.dateflag || a.currency::text) || a.productscode::text) ||
            substr('000000000'::text, 0, length('000000000'::text) - length(a.denomination::text))) ||
           a.denomination::text) || COALESCE(a.denomcode::text, ''::text)) || a.banknotestype::text) ||
        a.vaultid::text) || a.vaultdate AS fin_id,
       a.currency,
       a.productscode,
       a.denomination,
       a.denomcode,
       a.denomid,
       a.banknotestype,
       a.vaultid,
       a.main_vault_name,
       a.sub_vault_name,
       a.vaultdate,
       a.datediff,
       a.dateflag,
       sum(b.amount)                    AS inventory
FROM all_vaults_inventory_position a,
     all_vaults_inventory_position b
WHERE (a.dateflag = 'HOLDING'::text AND a.dateflag = b.dateflag OR
       a.dateflag = 'OPEN'::text AND a.vaultdate >= b.vaultdate)
  AND a.currency::text = b.currency::text
  AND a.productscode::text = b.productscode::text
  AND a.denomination::text = b.denomination::text
  AND COALESCE(a.denomcode, ' '::character varying)::text = COALESCE(b.denomcode, ' '::character varying)::text
  AND a.banknotestype::text = b.banknotestype::text
  AND a.vaultid::text = b.vaultid::text
GROUP BY a.currency, a.productscode, a.denomination, a.denomcode, a.denomid, a.banknotestype, a.vaultid,
         a.main_vault_name, a.sub_vault_name, a.vaultdate, a.datediff, a.dateflag
ORDER BY a.currency, a.productscode, a.denomination, a.denomcode, a.denomid, a.banknotestype, a.vaultid,
         a.main_vault_name, a.sub_vault_name, a.vaultdate, a.dateflag
;

----------------------------------------------------------------------------------------------------------------------------




create or replace view vbls_inventory_position
            (fin_id, currency, productscode, denomid, denomination, denomcode, banknotestypeid, banknotestype, vaultid,
             main_vault_name, sub_vault_name, vaultdate, systemdate, datediff, dateflag, amount)
as
SELECT (((((((((((((((invprojection.currency::text || '_'::text) || invprojection.productscode::text) || '_'::text) ||
                   invprojection.denomid::text) || '_'::text) || invprojection.banknotestypeid::text) || '_'::text) ||
               invprojection.vaultid::text) || '_'::text) || vaults.main_vault_name::text) || '_'::text) ||
           vaults.sub_vault_name::text) || '_'::text) || to_char(invprojection.vaultdate, 'YYYYMMDD'::text)) ||
        '_'::text) || to_char(invprojection.systemdate, 'YYYYMMDD'::text)             AS fin_id,
       invprojection.currency,
       invprojection.productscode,
       invprojection.denomid,
       invprojection.denomination,
       invprojection.denomcode,
       invprojection.banknotestypeid,
       invprojection.banknotestype,
       invprojection.vaultid,
       vaults.main_vault_name                                                         AS main_vault_name,
       vaults.sub_vault_name                                                          AS sub_vault_name,
       to_char(invprojection.vaultdate, 'YYYYMMDD'::text)                             AS vaultdate,
       to_char(invprojection.systemdate, 'YYYYMMDD'::text)                            AS systemdate,
       to_date(to_char(invprojection.vaultdate, 'YYYYMMDD'::text), 'YYYYMMDD'::text) -
       to_date(to_char(invprojection.systemdate, 'YYYYMMDD'::text), 'YYYYMMDD'::text) AS datediff,
       invprojection.dateflag,
       sum(invprojection.amount)                                                      AS amount
FROM (SELECT deals.deal_no        AS dealno,
             legs.leg_number      AS legnumber,
             legs.currencies_id   AS currency,
             denoms.fin_id        AS denomid,
             denoms.products_code AS productscode,
             denoms.multiplier    AS denomination,
             denoms.code          AS denomcode,
             bntypes.fin_id       AS banknotestypeid,
             bntypes.code         AS banknotestype,
             CASE
                 WHEN legs.buy_sell::text = 'B'::text THEN abs(legs.amount)
                 ELSE abs(legs.amount) * '-1'::integer::numeric
                 END              AS amount,
             legs.vault_status_id AS vaultstatus,
             CASE
                 WHEN (deals.products_id::text = ANY
                       (ARRAY ['BKN_DISC'::character varying::text, 'BKN_DISN'::character varying::text, 'BKN_CAEX'::character varying::text, 'BKN_DISW'::character varying::text, 'TCQ_DISC'::character varying::text, 'TCQ_DISW'::character varying::text, 'TCQ_DISN'::character varying::text])) AND
                      legs.buy_sell::text <> deals.buy_sell::text THEN bndeals.vault2_date
                 ELSE bndeals.vault_date
                 END              AS vaultdate,
             CASE
                 WHEN (deals.products_id::text = ANY
                       (ARRAY ['BKN_DISC'::character varying::text, 'BKN_DISN'::character varying::text, 'BKN_CAEX'::character varying::text, 'BKN_DISW'::character varying::text, 'TCQ_DISC'::character varying::text, 'TCQ_DISW'::character varying::text, 'TCQ_DISN'::character varying::text])) AND
                      legs.buy_sell::text <> deals.buy_sell::text THEN bndeals.vault2_id
                 ELSE bndeals.vault1_id
                 END              AS vaultid,
             'OPEN'::text         AS dateflag,
             dates.system_date    AS systemdate
      FROM tbls_bank_notes_deals_legs legs,
           tbls_bank_notes_deals bndeals,
           tbls_deal_versions versions,
           tbls_deals deals,
           tbls_workflow_states wfstates,
           tbls_bank_notes_denoms denoms,
           tbls_bank_notes_types bntypes,
           tbls_dates_master dates
      WHERE legs.is_deleted::text = 'N'::text
        AND legs.maker_checker_status::text = 'COMMITTED'::text
        AND bndeals.is_deleted::text = 'N'::text
        AND bndeals.maker_checker_status::text = 'COMMITTED'::text
        AND versions.is_deleted::text = 'N'::text
        AND versions.maker_checker_status::text = 'COMMITTED'::text
        AND deals.is_deleted::text = 'N'::text
        AND deals.maker_checker_status::text = 'COMMITTED'::text
        AND wfstates.is_deleted::text = 'N'::text
        AND wfstates.maker_checker_status::text = 'COMMITTED'::text
        AND denoms.is_deleted::text = 'N'::text
        AND denoms.maker_checker_status::text = 'COMMITTED'::text
        AND bntypes.is_deleted::text = 'N'::text
        AND bntypes.maker_checker_status::text = 'COMMITTED'::text
        AND (deals.products_id::text <> ALL
             (ARRAY [
                 'BKN_UNRR'::character varying::text,
                 'BKN_COLS'::character varying::text,
                 'BKN_EFTSETTLE'::character varying::text]))--exclude eft settlement from inventory forecast
        AND legs.bank_notes_deals_id::text = bndeals.fin_id::text
        AND bndeals.fin_id::text = versions.fin_id::text
        AND versions.deals_id::text = deals.fin_id::text
        AND deals.version_no = versions.version_no
        AND legs.vault_status_id::text = wfstates.fin_id::text
        AND denoms.fin_id::text = legs.bank_notes_denoms_id::text
        AND bntypes.fin_id::text = legs.bank_notes_types_id::text
        AND to_char(
                    CASE
                        WHEN (deals.products_id::text = ANY
                              (ARRAY ['BKN_DISC'::character varying::text, 'BKN_DISN'::character varying::text, 'BKN_CAEX'::character varying::text, 'BKN_DISW'::character varying::text, 'TCQ_DISC'::character varying::text, 'TCQ_DISW'::character varying::text, 'TCQ_DISN'::character varying::text])) AND
                             legs.buy_sell::text <> deals.buy_sell::text THEN bndeals.vault2_date
                        ELSE bndeals.vault_date
                        END, 'YYYYMMDD'::text) >= to_char(dates.system_date, 'YYYYMMDD'::text)
        AND (deals.status::text = ANY (ARRAY ['LIVE'::character varying::text, 'INCOMPLETE'::character varying::text]))
        AND wfstates.workflow_module::text = 'VAULT'::text
        AND (wfstates.update_main_inv <> 'Y'::bpchar OR wfstates.update_other_inv <> 'Y'::bpchar)
        AND COALESCE(legs.vault_inventory_updated, 'N'::character varying)::text <> 'Y'::text
      UNION ALL
      SELECT deals.deal_no        AS dealno,
             legs.leg_number      AS legnumber,
             legs.currencies_id   AS currency,
             denoms.fin_id        AS denomid,
             denoms.products_code AS productscode,
             denoms.multiplier    AS denomination,
             denoms.code          AS denomcode,
             bntypes.fin_id       AS banknotestypeid,
             bntypes.code         AS banknotestype,
             CASE
                 WHEN legs.buy_sell::text = 'B'::text THEN '-1'::integer::numeric * abs(legs.amount)
                 ELSE abs(legs.amount)
                 END              AS amount,
             legs.vault_status_id AS vaultstatus,
             bndeals.vault2_date  AS vaultdate,
             bndeals.vault2_id    AS vaultid,
             'OPEN'::text         AS dateflag,
             dates.system_date    AS systemdate
      FROM tbls_bank_notes_deals_legs legs,
           tbls_bank_notes_deals bndeals,
           tbls_deal_versions versions,
           tbls_deals deals,
           tbls_workflow_states wfstates,
           tbls_bank_notes_denoms denoms,
           tbls_bank_notes_types bntypes,
           tbls_dates_master dates
      WHERE legs.is_deleted::text = 'N'::text
        AND legs.maker_checker_status::text = 'COMMITTED'::text
        AND bndeals.is_deleted::text = 'N'::text
        AND bndeals.maker_checker_status::text = 'COMMITTED'::text
        AND versions.is_deleted::text = 'N'::text
        AND versions.maker_checker_status::text = 'COMMITTED'::text
        AND deals.is_deleted::text = 'N'::text
        AND deals.maker_checker_status::text = 'COMMITTED'::text
        AND wfstates.is_deleted::text = 'N'::text
        AND wfstates.maker_checker_status::text = 'COMMITTED'::text
        AND denoms.is_deleted::text = 'N'::text
        AND denoms.maker_checker_status::text = 'COMMITTED'::text
        AND bntypes.is_deleted::text = 'N'::text
        AND bntypes.maker_checker_status::text = 'COMMITTED'::text
        AND (deals.products_id::text = ANY
             (ARRAY ['BKN_ECIB'::character varying::text, 'BKN_ECIS'::character varying::text, 'BKN_CONT'::character varying::text, 'BKN_CONR'::character varying::text, 'BKN_CONS'::character varying::text]))
        AND legs.bank_notes_deals_id::text = bndeals.fin_id::text
        AND bndeals.fin_id::text = versions.fin_id::text
        AND versions.deals_id::text = deals.fin_id::text
        AND deals.version_no = versions.version_no
        AND legs.vault_status_id::text = wfstates.fin_id::text
        AND denoms.fin_id::text = legs.bank_notes_denoms_id::text
        AND bntypes.fin_id::text = legs.bank_notes_types_id::text
        AND to_char(COALESCE(bndeals.vault_date, COALESCE(bndeals.vault2_date, dates.system_date)), 'YYYYMMDD'::text) >=
            to_char(dates.system_date, 'YYYYMMDD'::text)
        AND (deals.status::text = ANY (ARRAY ['LIVE'::character varying::text, 'INCOMPLETE'::character varying::text]))
        AND wfstates.workflow_module::text = 'VAULT'::text
        AND (wfstates.update_main_inv <> 'Y'::bpchar OR wfstates.update_other_inv <> 'Y'::bpchar)
        AND COALESCE(legs.vault_inventory_updated, 'N'::character varying)::text <> 'Y'::text
      UNION ALL
      SELECT 'Holding'::character varying AS dealno,
             0                            AS legnumber,
             inventory.currencies_id      AS currency,
             denoms.fin_id                AS denomid,
             denoms.products_code         AS productscode,
             denoms.multiplier            AS denomination,
             denoms.code                  AS denomcode,
             bntypes.fin_id               AS banknotestypeid,
             bntypes.code                 AS banknotestype,
             inventory.amount,
             'HOLDING'::character varying AS vaultstatus,
             dates.system_date            AS vaultdate,
             inventory.vaults_id          AS vaultid,
             'HOLDING'::text              AS dateflag,
             dates.system_date            AS systemdate
      FROM tbls_vaults_inv_cash inventory,
           tbls_bank_notes_denoms denoms,
           tbls_bank_notes_types bntypes,
           tbls_dates_master dates
      WHERE inventory.is_deleted::text = 'N'::text
        AND inventory.maker_checker_status::text = 'COMMITTED'::text
        AND denoms.is_deleted::text = 'N'::text
        AND denoms.maker_checker_status::text = 'COMMITTED'::text
        AND bntypes.is_deleted::text = 'N'::text
        AND bntypes.maker_checker_status::text = 'COMMITTED'::text
        AND bntypes.fin_id::text = inventory.bank_notes_types_id::text
        AND denoms.fin_id::text = inventory.bank_notes_denoms_id::text) invprojection,
     tbls_vaults vaults
WHERE vaults.fin_id::text = invprojection.vaultid::text
GROUP BY invprojection.currency, invprojection.productscode, invprojection.denomid, invprojection.denomination,
         invprojection.denomcode, invprojection.banknotestypeid, invprojection.banknotestype, invprojection.vaultid,
         vaults.main_vault_name, vaults.sub_vault_name, invprojection.vaultdate, invprojection.dateflag,
         invprojection.systemdate
ORDER BY invprojection.vaultdate, invprojection.vaultid, invprojection.productscode, invprojection.currency,
         invprojection.denomid, invprojection.denomination, invprojection.denomcode, invprojection.banknotestypeid,
         invprojection.banknotestype;


---------------------------------------------------------------------------------------------------------------------------------


drop view IF EXISTS vbls_deal_search_view ;
CREATE OR REPLACE VIEW vbls_deal_search_view
 AS
 SELECT banknotesdeals.fin_id::text || COALESCE(settlements.version_no, 0::bigint::double precision) AS fin_id,
    COALESCE(banknotesdeals.fully_funded, ' '::bpchar) AS fully_funded,
    banknotesdeals.vault_date,
        CASE
            WHEN products.deal_type_name::text = 'ECI Repatriation'::text THEN banknotesdeals.depo_withdraw_date
            WHEN products.deal_type_name::text = 'ECI Top-up'::text THEN banknotesdeals.depo_withdraw_date
            ELSE banknotesdeals.release_date
        END AS release_date,
    banknotesdeals.net_setl_amt,
    banknotesdeals.setl_cur_id AS setl_currency,
    dealversions.fin_id AS deals_versions_fin_id,
    dealversions.version_no AS deals_version_no,
    dealversions.link_deal_no,
    dealversions.action,
    dealversions.action_date,
    COALESCE(dealversions.external_comments, ' '::character varying) AS external_comments,
    COALESCE(dealversions.internal_comments, ' '::character varying) AS internal_comments,
    products.name AS products_name,
    products.deal_type_name AS dealtype_name,
    products.code AS products_code,
    uddealtypes.name AS ud_type_name,
    deals.deal_no AS deal_number,
    deals.buy_sell,
    deals.repositories_id,
    deals.entry_date,
    deals.trade_date,
    deals.value_date,
    deals.products_id,
    deals.customers_id AS customer_id,
    deals.branches_id,
    deals.ud_deal_types_id,
    deals.status,
    deals.users_id AS user_id,
    customers.name AS customers_name,
    customers.short_name AS customers_short_name,
    customers.ctp_no AS customers_ctp_no,
    branches.name AS branches_name,
    branches.short_name AS branches_short_name,
    sdis.sdi_code,
    COALESCE(dealssi.nv_code, ' '::character varying) AS nv_code,
    COALESCE(dealssi.ssi_type, ' '::character varying) AS ssi_type,
    COALESCE(dealssi.pay_receive, ' '::bpchar) AS pay_receive,
    COALESCE(dealssi.bic_code, ' '::character varying) AS bic_code,
    COALESCE(dealssi.gl_code, ' '::character varying) AS gl_code,
    COALESCE(dealssi.account_no, ' '::character varying) AS account_no,
    COALESCE(dealssi.ssi_code, ' '::character varying) AS ssi_code,
    COALESCE(dealssi.ssi_rules_id, ' '::character varying) AS ssi_rules_id,
    COALESCE(dealssi.cust_agent_name1, ' '::character varying) AS agent_name1,
    COALESCE(dealssi.cust_agent_name2, ' '::character varying) AS agent_name2,
    COALESCE(dealssi.cust_agent_name3, ' '::character varying) AS agent_name3,
    COALESCE(dealssi.cust_agent_name4, ' '::character varying) AS agent_name4,
    COALESCE(dealssi.cust_agent_swift_code, ' '::character varying) AS agent_swift_code,
    COALESCE(dealssi.cust_agent_account, ' '::character varying) AS agent_account,
    COALESCE(dealssi.beneficiary_acc_no, ' '::character varying) AS bene_account,
    COALESCE(dealssi.bene_name1, ' '::character varying) AS int_name1,
    COALESCE(dealssi.bene_name2, ' '::character varying) AS int_name2,
    COALESCE(dealssi.bene_name3, ' '::character varying) AS int_name3,
    COALESCE(dealssi.bene_name4, ' '::character varying) AS int_name4,
    COALESCE(dealssi.int_swift_code, ' '::character varying) AS int_swift_code,
    COALESCE(dealssi.int_account, ' '::character varying) AS int_account,
    COALESCE(dealssi.additional_info1, ' '::character varying) AS additional_info1,
    COALESCE(dealssi.additional_info2, ' '::character varying) AS additional_info2,
    COALESCE(dealssi.additional_info3, ' '::character varying) AS additional_info3,
    COALESCE(dealssi.bene_swift_code, ' '::character varying) AS additional_info4,
    COALESCE(dealssi.msg_template_id, ' '::character varying) AS message_template_id,
    COALESCE(dealssi.setl_mode_id, ' '::character varying) AS setl_mode_id,
    COALESCE(dealssi.fin_id, ' '::character varying) AS ssi_fin_id,
    COALESCE(settlements.fin_id, ' '::character varying) AS settlement_fin_id,
    COALESCE(settlements.setl_no, '0'::character varying) AS setl_no,
    COALESCE(settlements.version_no, 0::bigint::double precision) AS setl_version_no,
    COALESCE(settlements.setl_amount, 0::numeric) AS setl_amt,
    COALESCE(settlements.setl_origin, ' '::character varying) AS setl_origin,
    COALESCE(settlements.pay_receive, ' '::bpchar) AS setl_pay_receive,
    COALESCE(to_char(settlements.setl_date, 'DD/MM/YYYY'::text), ' '::text) AS setl_date,
    COALESCE(to_char(settlements.setl_release_date, 'DD/MM/YYYY'::text), '01/01/1970'::text) AS setl_release_date,
        CASE
            WHEN COALESCE(settlements.is_deleted, 'N'::character varying)::text = 'Y'::text AND COALESCE(workflowstatessetl.name, ' '::character varying)::text = 'NETTEDC'::text THEN 'N'::character varying
            ELSE COALESCE(settlements.is_deleted, 'N'::character varying)
        END AS setl_deleted,
    workflowstatesdeals.name AS deal_status,
    COALESCE(dealstatus.operations_userid, ' '::character varying) AS deal_status_validator,
    workflowstatesdeals.workflow_level AS deal_status_level,
    workflowstatesshipment.name AS shipment_status,
    workflowstatesvault.name AS vault_status,
    COALESCE(workflowstatessetl.name, ' '::character varying) AS setl_status,
    COALESCE(workflowstatessetl.workflow_level, '-1'::integer::bigint::double precision) AS setl_status_level,
    COALESCE(ssinv.ssi_type, ' '::character varying) AS ssi_nv_type,
    COALESCE(dealstatus.fo_remarks, ' '::character varying) AS fo_remarks,
    COALESCE(dealstatus.bo_remarks, ' '::character varying) AS setl_remarks,
    COALESCE(banknotesdeals.vault1_id, ''::character varying) AS vault1_id,
    COALESCE(banknotesdeals.vault2_id, ''::character varying) AS vault2_id
   FROM TBLS_bank_notes_deals banknotesdeals
     LEFT JOIN TBLS_sdis sdis ON banknotesdeals.sdi_id::text = sdis.fin_id::text,
    TBLS_deal_versions dealversions
     LEFT JOIN TBLS_deal_ssi dealssi ON dealversions.fin_id::text = dealssi.deal_versions_id::text
     LEFT JOIN TBLS_ssis_nv ssinv ON dealssi.nv_code::text = ssinv.fin_id::text
     LEFT JOIN TBLS_settlements settlements ON dealversions.fin_id::text = settlements.deal_versions_id::text AND (settlements.is_deleted::text = 'N'::text OR settlements.status_id::text = 'PAYMENTS_CANCELLED'::text OR settlements.status_id::text = 'PAYMENTS_NETTEDP'::text OR settlements.status_id::text = 'PAYMENTS_NETTEDC'::text)
     LEFT JOIN TBLS_workflow_states workflowstatessetl ON workflowstatessetl.fin_id::text = settlements.status_id::text,
    TBLS_deals deals,
    TBLS_products products,
    TBLS_ud_deal_types uddealtypes,
    TBLS_ud_dt_mapping uddtmapping,
    TBLS_customers customers,
    TBLS_branches branches,
    TBLS_deals_status dealstatus,
    TBLS_workflow_states workflowstatesdeals,
    TBLS_workflow_states workflowstatesshipment,
    TBLS_workflow_states workflowstatesvault
  WHERE (deals.version_no = dealversions.version_no OR settlements.status_id::text = 'PAYMENTS_CANCELLED'::text) AND banknotesdeals.fin_id::text = dealversions.fin_id::text AND dealversions.deals_id::text = deals.fin_id::text AND banknotesdeals.fin_id::text = dealversions.fin_id::text AND dealversions.customers_id::text = customers.fin_id::text AND banknotesdeals.fin_id::text = dealversions.fin_id::text AND dealversions.branches_id::text = branches.fin_id::text AND banknotesdeals.fin_id::text = dealversions.fin_id::text AND dealversions.products_id::text = products.fin_id::text AND banknotesdeals.fin_id::text = dealversions.fin_id::text AND dealstatus.fin_id::text = deals.deal_no::text AND dealstatus.deal_status_id::text = workflowstatesdeals.fin_id::text AND uddealtypes.fin_id::text = uddtmapping.ud_deal_types_id::text AND uddtmapping.fin_id::text = deals.ud_deal_types_id::text AND workflowstatesshipment.fin_id::text = dealstatus.shipping_status_id::text AND workflowstatesvault.fin_id::text = dealstatus.vault_status_id::text
  
  ;
  
 
 -----------------------------------------------------------------------------------------------------------------------------------------
 
 
 drop view IF EXISTS vbls_deal_search_view ;
 CREATE OR REPLACE VIEW vbls_deal_search_view
 AS
 SELECT banknotesdeals.fin_id::text || COALESCE(settlements.version_no, 0::bigint::double precision) AS fin_id,
    COALESCE(banknotesdeals.fully_funded, ' '::bpchar) AS fully_funded,
    banknotesdeals.vault_date,
        CASE
            WHEN products.deal_type_name::text = 'ECI Repatriation'::text THEN banknotesdeals.depo_withdraw_date
            WHEN products.deal_type_name::text = 'ECI Top-up'::text THEN banknotesdeals.depo_withdraw_date
            ELSE banknotesdeals.release_date
        END AS release_date,
    banknotesdeals.net_setl_amt,
    banknotesdeals.setl_cur_id AS setl_currency,
    dealversions.fin_id AS deals_versions_fin_id,
    dealversions.version_no AS deals_version_no,
    dealversions.link_deal_no,
    dealversions.action,
    dealversions.action_date,
    COALESCE(dealversions.external_comments, ' '::character varying) AS external_comments,
    COALESCE(dealversions.internal_comments, ' '::character varying) AS internal_comments,
    products.name AS products_name,
    products.deal_type_name AS dealtype_name,
    products.code AS products_code,
    uddealtypes.name AS ud_type_name,
    deals.deal_no AS deal_number,
    deals.buy_sell,
    deals.repositories_id,
    deals.entry_date,
    deals.trade_date,
    deals.value_date,
    deals.products_id,
    deals.customers_id AS customer_id,
    deals.branches_id,
    deals.ud_deal_types_id,
    deals.status,
    deals.users_id AS user_id,
    customers.name AS customers_name,
    customers.short_name AS customers_short_name,
    customers.ctp_no AS customers_ctp_no,
    branches.name AS branches_name,
    branches.short_name AS branches_short_name,
    sdis.sdi_code,
    COALESCE(dealssi.nv_code, ' '::character varying) AS nv_code,
    COALESCE(dealssi.ssi_type, ' '::character varying) AS ssi_type,
    COALESCE(dealssi.pay_receive, ' '::bpchar) AS pay_receive,
    COALESCE(dealssi.bic_code, ' '::character varying) AS bic_code,
    COALESCE(dealssi.gl_code, ' '::character varying) AS gl_code,
    COALESCE(dealssi.account_no, ' '::character varying) AS account_no,
    COALESCE(dealssi.ssi_code, ' '::character varying) AS ssi_code,
    COALESCE(dealssi.ssi_rules_id, ' '::character varying) AS ssi_rules_id,
    COALESCE(dealssi.cust_agent_name1, ' '::character varying) AS agent_name1,
    COALESCE(dealssi.cust_agent_name2, ' '::character varying) AS agent_name2,
    COALESCE(dealssi.cust_agent_name3, ' '::character varying) AS agent_name3,
    COALESCE(dealssi.cust_agent_name4, ' '::character varying) AS agent_name4,
    COALESCE(dealssi.cust_agent_swift_code, ' '::character varying) AS agent_swift_code,
    COALESCE(dealssi.cust_agent_account, ' '::character varying) AS agent_account,
    COALESCE(dealssi.beneficiary_acc_no, ' '::character varying) AS bene_account,
    COALESCE(dealssi.bene_name1, ' '::character varying) AS int_name1,
    COALESCE(dealssi.bene_name2, ' '::character varying) AS int_name2,
    COALESCE(dealssi.bene_name3, ' '::character varying) AS int_name3,
    COALESCE(dealssi.bene_name4, ' '::character varying) AS int_name4,
    COALESCE(dealssi.int_swift_code, ' '::character varying) AS int_swift_code,
    COALESCE(dealssi.int_account, ' '::character varying) AS int_account,
    COALESCE(dealssi.additional_info1, ' '::character varying) AS additional_info1,
    COALESCE(dealssi.additional_info2, ' '::character varying) AS additional_info2,
    COALESCE(dealssi.additional_info3, ' '::character varying) AS additional_info3,
    COALESCE(dealssi.bene_swift_code, ' '::character varying) AS additional_info4,
    COALESCE(dealssi.msg_template_id, ' '::character varying) AS message_template_id,
    COALESCE(dealssi.setl_mode_id, ' '::character varying) AS setl_mode_id,
    COALESCE(dealssi.fin_id, ' '::character varying) AS ssi_fin_id,
    COALESCE(settlements.fin_id, ' '::character varying) AS settlement_fin_id,
    COALESCE(settlements.setl_no, '0'::character varying) AS setl_no,
    COALESCE(settlements.version_no, 0::bigint::double precision) AS setl_version_no,
    COALESCE(settlements.setl_amount, 0::numeric) AS setl_amt,
    COALESCE(settlements.setl_origin, ' '::character varying) AS setl_origin,
    COALESCE(settlements.pay_receive, ' '::bpchar) AS setl_pay_receive,
    COALESCE(to_char(settlements.setl_date, 'DD/MM/YYYY'::text), ' '::text) AS setl_date,
    COALESCE(to_char(settlements.setl_release_date, 'DD/MM/YYYY'::text), '01/01/1970'::text) AS setl_release_date,
        CASE
            WHEN COALESCE(settlements.is_deleted, 'N'::character varying)::text = 'Y'::text AND COALESCE(workflowstatessetl.name, ' '::character varying)::text = 'NETTEDC'::text THEN 'N'::character varying
            ELSE COALESCE(settlements.is_deleted, 'N'::character varying)
        END AS setl_deleted,
    workflowstatesdeals.name AS deal_status,
    COALESCE(dealstatus.operations_userid, ' '::character varying) AS deal_status_validator,
    workflowstatesdeals.workflow_level AS deal_status_level,
    workflowstatesshipment.name AS shipment_status,
    workflowstatesvault.name AS vault_status,
    COALESCE(workflowstatessetl.name, ' '::character varying) AS setl_status,
    COALESCE(workflowstatessetl.workflow_level, '-1'::integer::bigint::double precision) AS setl_status_level,
    COALESCE(ssinv.ssi_type, ' '::character varying) AS ssi_nv_type,
    COALESCE(dealstatus.fo_remarks, ' '::character varying) AS fo_remarks,
    COALESCE(dealstatus.bo_remarks, ' '::character varying) AS setl_remarks,
    COALESCE(banknotesdeals.vault1_id, ''::character varying) AS vault1_id,
    COALESCE(banknotesdeals.vault2_id, ''::character varying) AS vault2_id
   FROM tbls_bank_notes_deals banknotesdeals
     LEFT JOIN tbls_sdis sdis ON banknotesdeals.sdi_id::text = sdis.fin_id::text,
    tbls_deal_versions dealversions
     LEFT JOIN tbls_deal_ssi dealssi ON dealversions.fin_id::text = dealssi.deal_versions_id::text
     LEFT JOIN tbls_ssis_nv ssinv ON dealssi.nv_code::text = ssinv.fin_id::text
     LEFT JOIN tbls_settlements settlements ON dealversions.fin_id::text = settlements.deal_versions_id::text AND (settlements.is_deleted::text = 'N'::text OR settlements.status_id::text = 'PAYMENTS_CANCELLED'::text OR settlements.status_id::text = 'PAYMENTS_NETTEDP'::text OR settlements.status_id::text = 'PAYMENTS_NETTEDC'::text)
     LEFT JOIN tbls_workflow_states workflowstatessetl ON workflowstatessetl.fin_id::text = settlements.status_id::text,
    tbls_deals deals,
    tbls_products products,
    tbls_ud_deal_types uddealtypes,
    tbls_ud_dt_mapping uddtmapping,
    tbls_customers customers,
    tbls_branches branches,
    tbls_deals_status dealstatus,
    tbls_workflow_states workflowstatesdeals,
    tbls_workflow_states workflowstatesshipment,
    tbls_workflow_states workflowstatesvault
  WHERE (deals.version_no = dealversions.version_no OR settlements.status_id::text = 'PAYMENTS_CANCELLED'::text) AND banknotesdeals.fin_id::text = dealversions.fin_id::text AND dealversions.deals_id::text = deals.fin_id::text AND banknotesdeals.fin_id::text = dealversions.fin_id::text AND dealversions.customers_id::text = customers.fin_id::text AND banknotesdeals.fin_id::text = dealversions.fin_id::text AND dealversions.branches_id::text = branches.fin_id::text AND banknotesdeals.fin_id::text = dealversions.fin_id::text AND dealversions.products_id::text = products.fin_id::text AND banknotesdeals.fin_id::text = dealversions.fin_id::text AND dealstatus.fin_id::text = deals.deal_no::text AND dealstatus.deal_status_id::text = workflowstatesdeals.fin_id::text AND uddealtypes.fin_id::text = uddtmapping.ud_deal_types_id::text AND uddtmapping.fin_id::text = deals.ud_deal_types_id::text AND workflowstatesshipment.fin_id::text = dealstatus.shipping_status_id::text AND workflowstatesvault.fin_id::text = dealstatus.vault_status_id::text
  
  ;




--Acc entry related View Changes To pick GL BranchCode from repository instead from Subledger - 29 Nov 2019
drop VIEW IF EXISTS vbls_bkn_deal_entries;
CREATE OR REPLACE VIEW vbls_bkn_deal_entries AS
 SELECT (((deals.deal_no::text || '_'::text) || deals.version_no) || '_'::text) || bn_legs.leg_number AS fin_id,
    'DEAL'::text AS rule_type,
    ''::text AS external_no,
    deals.deal_no,
    deals.version_no,
    bn_legs.leg_number AS leg_no,
    prd.code AS product_type,
    prd.deal_type_code AS deal_type,
        CASE
            WHEN bn_legs.currencies_id::text = bn.setl_cur_id::text THEN
            CASE
                WHEN bn_legs.currencies_id::text = ((( SELECT tbls_regions.currencies_id
                   FROM tbls_regions
                  WHERE tbls_regions.fin_id::text = ((( SELECT tbls_dates_master.region_id
                           FROM tbls_dates_master))::text)))::text) THEN 'LIKE_BASE'::text
                ELSE 'LIKE'::text
            END
            ELSE 'UNLIKE'::text
        END AS deal_sub_type,
    deals.buy_sell,
    deals.entry_date,
        CASE
            WHEN deals.trade_date < deals.action_date THEN deals.action_date
            ELSE deals.trade_date
        END AS trade_date,
        CASE
            WHEN deals.value_date < deals.action_date THEN deals.action_date
            ELSE deals.value_date
        END AS value_date,
        CASE
            WHEN bn.release_date < deals.action_date THEN deals.action_date
            ELSE bn.release_date
        END AS release_date,
        CASE
            WHEN bn.vault_date < deals.action_date THEN deals.action_date
            ELSE bn.vault_date
        END AS vault_date,
        CASE
            WHEN (deals.products_id::text = ANY (ARRAY['BKN_CAEX'::character varying::text, 'BKN_CONT'::character varying::text, 'BKN_CONR'::character varying::text, 'BKN_DISC'::character varying::text, 'TCQ_DISC'::character varying::text])) AND bn.vault2_date < deals.action_date THEN deals.action_date
            WHEN (deals.products_id::text = ANY (ARRAY['BKN_CAEX'::character varying::text, 'BKN_CONT'::character varying::text, 'BKN_CONR'::character varying::text, 'BKN_DISC'::character varying::text, 'TCQ_DISC'::character varying::text])) AND bn.vault2_date >= deals.action_date THEN bn.vault2_date
            ELSE NULL::timestamp without time zone
        END AS vault2_date,
        CASE
            WHEN (deals.products_id::text = ANY (ARRAY['BKN_CAEX'::character varying::text, 'BKN_OFFS'::character varying::text, 'BKN_DISC'::character varying::text, 'TCQ_DISC'::character varying::text])) AND bn.release2_date < deals.action_date THEN deals.action_date
            WHEN (deals.products_id::text = ANY (ARRAY['BKN_CAEX'::character varying::text, 'BKN_OFFS'::character varying::text, 'BKN_DISC'::character varying::text, 'TCQ_DISC'::character varying::text])) AND bn.release2_date >= deals.action_date THEN bn.release2_date
            ELSE NULL::timestamp without time zone
        END AS release2_date,
    ( SELECT tbls_dates_master.system_date
           FROM tbls_dates_master) AS accounting_date,
        CASE
            WHEN bn.release_date < deals.value_date THEN
            CASE
                WHEN bn.release_date < deals.action_date THEN deals.action_date
                ELSE bn.release_date
            END
            ELSE
            CASE
                WHEN deals.value_date < deals.action_date THEN deals.action_date
                ELSE deals.value_date
            END
        END AS memo_rev_date,
        CASE
            WHEN deals.buy_sell::text = 'B'::text THEN bn_legs.currencies_id
            ELSE bn.setl_cur_id
        END AS buy_currency,
        CASE
            WHEN deals.buy_sell::text = 'S'::text THEN bn_legs.currencies_id
            ELSE bn.setl_cur_id
        END AS sell_currency,
        CASE
            WHEN deals.buy_sell::text = 'B'::text THEN bn_legs.amount
            ELSE bn_legs.setl_amount
        END AS buy_amount,
        CASE
            WHEN deals.buy_sell::text = 'S'::text THEN bn_legs.amount
            ELSE bn_legs.setl_amount
        END AS sell_amount,
    bn_legs.setl_amount AS settlement_amount,
    deals.repositories_id,
    rp.corp_code,
    rp.cost_center,
    cust.short_name AS customers_id,
    cust.country_incorporation_id AS customer_country,
    cust.is_resident,
    ct.type_code AS customer_type,
    bn_legs.deal_rate,
    bn_legs.market_rate,
    bn.usd_rate_vs_setl_cur,
    bn.usd_rate_vs_base_cur,
    0 AS usd_rate_vs_sell_cur,
    0 AS usd_rate_vs_buy_cur,
    bn_legs.md,
    bn_legs.spotfactor,
    deals.ud_deal_types_id,
    uddealtypes.fin_id AS ud_deal_types_id2,
    branch.branch_id,
    COALESCE(
        CASE
            WHEN deals.buy_sell::text = 'B'::text THEN bn_legs.leg_ccy_vs_lcu_spotrate
            ELSE bn_legs.leg_ccy_vs_lcu_dealrate
        END, 0::numeric) AS leg_ccy_vs_lcu_spotrate,
    COALESCE(bn_legs.lcu_eqv_amount, 0::numeric) AS lcu_eqv_amount,
    COALESCE(bn_legs.lcu_setl_eqv_amount, 0::numeric) AS lcu_setl_eqv_amount,
    rp.glbranch_code
   FROM tbls_deals deals,
    tbls_deal_versions versions,
    tbls_bank_notes_deals bn,
    tbls_bank_notes_deals_legs bn_legs,
    tbls_repositories rp,
    tbls_customers cust,
    tbls_customer_types ct,
    tbls_products prd,
    tbls_ud_dt_mapping uddt,
    tbls_ud_deal_types uddealtypes,
    tbls_branches branch
  WHERE deals.fin_id::text = versions.deals_id::text AND deals.version_no = versions.version_no AND versions.fin_id::text = bn.fin_id::text AND bn.fin_id::text = bn_legs.bank_notes_deals_id::text AND deals.buy_sell::text = bn_legs.buy_sell::text AND deals.repositories_id::text = rp.fin_id::text AND deals.customers_id::text = cust.fin_id::text AND cust.type_id::text = ct.fin_id::text AND deals.products_id::text = prd.fin_id::text AND deals.ud_deal_types_id::text = uddt.fin_id::text AND uddt.ud_deal_types_id::text = uddealtypes.fin_id::text AND deals.action::text <> 'CANCEL'::text AND to_char(deals.action_date, 'YYYYMMDD'::text) <= (( SELECT to_char(tbls_dates_master.accounting_date, 'YYYYMMDD'::text) AS to_char
           FROM tbls_dates_master)) AND deals.maker_checker_status::text = 'COMMITTED'::text AND deals.is_deleted::text = 'N'::text AND versions.maker_checker_status::text = 'COMMITTED'::text AND versions.is_deleted::text = 'N'::text AND bn.maker_checker_status::text = 'COMMITTED'::text AND bn.is_deleted::text = 'N'::text AND bn_legs.maker_checker_status::text = 'COMMITTED'::text AND bn_legs.is_deleted::text = 'N'::text AND rp.maker_checker_status::text = 'COMMITTED'::text AND rp.is_deleted::text = 'N'::text AND ct.maker_checker_status::text = 'COMMITTED'::text AND ct.is_deleted::text = 'N'::text AND cust.maker_checker_status::text = 'COMMITTED'::text AND cust.is_deleted::text = 'N'::text AND (deals.products_id::text IN ( SELECT tbls_products.fin_id
           FROM tbls_products
          WHERE tbls_products.code::text = ANY (ARRAY['BKN'::character varying::text, 'TCQ'::character varying::text]))) AND deals.branches_id::text = branch.fin_id::text;


drop VIEW IF EXISTS vbls_commission_entries;
CREATE OR REPLACE VIEW vbls_commission_entries AS
 SELECT DISTINCT bn.fin_id::text || '_CHARGE'::text AS fin_id,
    deals.deal_no,
    deals.version_no,
    'CHARGE_COMMISSION'::text AS rule_type,
    prd.code AS product_type,
    deals.products_id AS deal_type,
    versions.ud_deal_types_id,
    uddealtypes.fin_id AS ud_deal_types_id2,
    'NA'::text AS deal_sub_type,
    deals.buy_sell,
        CASE
            WHEN deals.trade_date < deals.action_date THEN deals.action_date
            ELSE deals.trade_date
        END AS trade_date,
        CASE
            WHEN deals.value_date < deals.action_date THEN deals.action_date
            ELSE deals.value_date
        END AS value_date,
        CASE
            WHEN bn.release_date < deals.action_date THEN deals.action_date
            ELSE bn.release_date
        END AS release_date,
        CASE
            WHEN bn.vault_date < deals.action_date THEN deals.action_date
            ELSE bn.vault_date
        END AS vault_date,
    NULL::timestamp without time zone AS commission_date,
        CASE
            WHEN bn.release_date < deals.value_date THEN
            CASE
                WHEN bn.release_date < deals.action_date THEN deals.action_date
                ELSE bn.release_date
            END
            ELSE
            CASE
                WHEN deals.value_date < deals.action_date THEN deals.action_date
                ELSE deals.value_date
            END
        END AS memo_rev_date,
    abs(bn.charge_amount) AS charge_amount,
    bn.setl_cur_id AS charge_currency,
    NULL::numeric AS commission_amount,
    ''::text AS commission_currency,
    'CHARGES'::text AS charges_commissions,
        CASE
            WHEN bn.charge_amount > 0::numeric THEN 'INCOME'::text
            WHEN bn.charge_amount = 0::numeric THEN ''::text
            ELSE 'EXPENSE'::text
        END AS income_exp,
    ''::text AS comm_setl_type,
    deals.repositories_id,
    rp.corp_code,
    rp.cost_center,
    cust.short_name AS customers_id,
    cust.is_resident,
    ct.type_code AS customer_type,
    rp.glbranch_code
   FROM tbls_deals deals,
    tbls_deal_versions versions,
    tbls_bank_notes_deals bn,
    tbls_bank_notes_deals_legs bn_legs,
    tbls_repositories rp,
    tbls_customers cust,
    tbls_customer_types ct,
    tbls_products prd,
    tbls_ud_dt_mapping uddt,
    tbls_ud_deal_types uddealtypes
  WHERE deals.fin_id::text = versions.deals_id::text AND deals.version_no = versions.version_no AND versions.fin_id::text = bn.fin_id::text AND bn.fin_id::text = bn_legs.bank_notes_deals_id::text AND deals.repositories_id::text = rp.fin_id::text AND deals.customers_id::text = cust.fin_id::text AND deals.products_id::text = prd.fin_id::text AND versions.ud_deal_types_id::text = uddt.fin_id::text AND uddt.ud_deal_types_id::text = uddealtypes.fin_id::text AND deals.action::text <> 'CANCEL'::text AND cust.type_id::text = ct.fin_id::text AND deals.maker_checker_status::text = 'COMMITTED'::text AND deals.is_deleted::text = 'N'::text AND versions.maker_checker_status::text = 'COMMITTED'::text AND versions.is_deleted::text = 'N'::text AND bn.maker_checker_status::text = 'COMMITTED'::text AND bn.is_deleted::text = 'N'::text AND bn_legs.maker_checker_status::text = 'COMMITTED'::text AND bn_legs.is_deleted::text = 'N'::text AND rp.maker_checker_status::text = 'COMMITTED'::text AND rp.is_deleted::text = 'N'::text AND ct.maker_checker_status::text = 'COMMITTED'::text AND ct.is_deleted::text = 'N'::text AND cust.maker_checker_status::text = 'COMMITTED'::text AND cust.is_deleted::text = 'N'::text AND bn.charge_amount <> 0::numeric AND (deals.products_id::text IN ( SELECT tbls_products.fin_id
           FROM tbls_products
          WHERE tbls_products.code::text = ANY (ARRAY['BKN'::character varying::text, 'TCQ'::character varying::text]))) AND to_char(deals.action_date, 'YYYYMMDD'::text) <= (( SELECT to_char(tbls_dates_master.accounting_date, 'YYYYMMDD'::text) AS to_char
           FROM tbls_dates_master))
UNION ALL
 SELECT DISTINCT bn.fin_id::text || '_COMMISSION'::text AS fin_id,
    deals.deal_no,
    deals.version_no,
    'CHARGE_COMMISSION'::text AS rule_type,
    prd.code AS product_type,
    deals.products_id AS deal_type,
    versions.ud_deal_types_id,
    uddealtypes.fin_id AS ud_deal_types_id2,
    'NA'::text AS deal_sub_type,
    deals.buy_sell,
        CASE
            WHEN deals.trade_date < deals.action_date THEN deals.action_date
            ELSE deals.trade_date
        END AS trade_date,
        CASE
            WHEN deals.value_date < deals.action_date THEN deals.action_date
            ELSE deals.value_date
        END AS value_date,
        CASE
            WHEN bn.release_date < deals.action_date THEN deals.action_date
            ELSE bn.release_date
        END AS release_date,
        CASE
            WHEN bn.vault_date < deals.action_date THEN deals.action_date
            ELSE bn.vault_date
        END AS vault_date,
        CASE
            WHEN bn.commission_setl_date < deals.action_date THEN deals.action_date
            ELSE bn.commission_setl_date
        END AS commission_date,
        CASE
            WHEN bn.release_date < deals.value_date THEN
            CASE
                WHEN bn.release_date < deals.action_date THEN deals.action_date
                ELSE bn.release_date
            END
            ELSE
            CASE
                WHEN deals.value_date < deals.action_date THEN deals.action_date
                ELSE deals.value_date
            END
        END AS memo_rev_date,
    NULL::numeric AS charge_amount,
    ''::text AS charge_currency,
    abs(bn.commission_amount) AS commission_amount,
    bn.commission_cur_id AS commission_currency,
    'COMMISSION'::text AS charges_commissions,
        CASE
            WHEN bn.commission_amount > 0::numeric THEN 'INCOME'::text
            WHEN bn.commission_amount = 0::numeric THEN ''::text
            ELSE 'EXPENSE'::text
        END AS income_exp,
        CASE
            WHEN bn.commission_setl_type::text = 'cash'::text THEN 'CASH'::text
            WHEN bn.commission_setl_type::text = 'tt'::text THEN 'SETTLE A/C'::text
            ELSE ''::text
        END AS comm_setl_type,
    deals.repositories_id,
    rp.corp_code,
    rp.cost_center,
    cust.short_name AS customers_id,
    cust.is_resident,
    ct.type_code AS customer_type,
    rp.glbranch_code
   FROM tbls_deals deals,
    tbls_deal_versions versions,
    tbls_bank_notes_deals bn,
    tbls_bank_notes_deals_legs bn_legs,
    tbls_repositories rp,
    tbls_customers cust,
    tbls_customer_types ct,
    tbls_products prd,
    tbls_ud_dt_mapping uddt,
    tbls_ud_deal_types uddealtypes
  WHERE deals.fin_id::text = versions.deals_id::text AND deals.version_no = versions.version_no AND versions.fin_id::text = bn.fin_id::text AND bn.fin_id::text = bn_legs.bank_notes_deals_id::text AND deals.repositories_id::text = rp.fin_id::text AND deals.customers_id::text = cust.fin_id::text AND deals.products_id::text = prd.fin_id::text AND versions.ud_deal_types_id::text = uddt.fin_id::text AND uddt.ud_deal_types_id::text = uddealtypes.fin_id::text AND deals.action::text <> 'CANCEL'::text AND cust.type_id::text = ct.fin_id::text AND deals.maker_checker_status::text = 'COMMITTED'::text AND deals.is_deleted::text = 'N'::text AND versions.maker_checker_status::text = 'COMMITTED'::text AND versions.is_deleted::text = 'N'::text AND bn.maker_checker_status::text = 'COMMITTED'::text AND bn.is_deleted::text = 'N'::text AND bn_legs.maker_checker_status::text = 'COMMITTED'::text AND bn_legs.is_deleted::text = 'N'::text AND rp.maker_checker_status::text = 'COMMITTED'::text AND rp.is_deleted::text = 'N'::text AND ct.maker_checker_status::text = 'COMMITTED'::text AND ct.is_deleted::text = 'N'::text AND cust.maker_checker_status::text = 'COMMITTED'::text AND cust.is_deleted::text = 'N'::text AND bn.commission_amount <> 0::numeric AND (deals.products_id::text IN ( SELECT tbls_products.fin_id
           FROM tbls_products
          WHERE tbls_products.code::text = ANY (ARRAY['BKN'::character varying::text, 'TCQ'::character varying::text]))) AND to_char(deals.action_date, 'YYYYMMDD'::text) <= (( SELECT to_char(tbls_dates_master.accounting_date, 'YYYYMMDD'::text) AS to_char
           FROM tbls_dates_master));
		   
		   
drop VIEW IF EXISTS vbls_ctc_entries;		   
CREATE OR REPLACE VIEW vbls_ctc_entries AS
 SELECT
        CASE
            WHEN deals.buy_sell::text = 'B'::text THEN ((deals.deal_no::text || '_'::text) || deals.version_no) || 'N'::text
            ELSE ((deals.deal_no::text || '_'::text) || deals.version_no) || 'P'::text
        END AS fin_id,
    'CTC'::text AS rule_type,
    ''::character varying AS external_no,
    deals.deal_no,
    deals.version_no,
    prd.code AS product_type,
    deals.products_id AS deal_type,
    'ALL'::text AS deal_sub_type,
    deals.ud_deal_types_id AS ud_deal_type,
    uddealtypes.fin_id AS ud_deal_types_id2,
        CASE
            WHEN deals.trade_date < deals.action_date THEN deals.action_date
            ELSE deals.trade_date
        END AS trade_date,
        CASE
            WHEN deals.value_date < deals.action_date THEN deals.action_date
            ELSE deals.value_date
        END AS value_date,
    bkn.release_date,
    bkn.vault_date,
    deals.maturity_date AS memo_rev_date,
    ( SELECT max(tbls_dates_master.accounting_date) AS max
           FROM tbls_dates_master) AS accounting_date,
        CASE
            WHEN deals.buy_sell::text = 'B'::text THEN 'DEAL_SETL_AMT_NEGATIVE'::text
            ELSE 'DEAL_SETL_AMT_POSITIVE'::text
        END AS ctc_mtm_sign,
    bkn.setl_cur_id AS currency,
    bkn.net_setl_amt AS amount,
    deals.repositories_id,
    rp.corp_code,
    rp.cost_center,
    cust.short_name AS customers_id,
    cust.country_incorporation_id AS customer_country,
    cust.is_resident,
    ct.type_code AS customer_type,
    ''::text AS funding_position_sign,
    rp.glbranch_code
   FROM tbls_deals deals,
    tbls_deal_versions versions,
    tbls_bank_notes_deals bkn,
    tbls_repositories rp,
    tbls_customers cust,
    tbls_customer_types ct,
    tbls_products prd,
    tbls_ud_dt_mapping uddt,
    tbls_ud_deal_types uddealtypes
  WHERE deals.fin_id::text = versions.deals_id::text AND deals.version_no = versions.version_no AND versions.fin_id::text = bkn.fin_id::text AND deals.repositories_id::text = rp.fin_id::text AND btrim(deals.customers_id::text) = btrim(cust.fin_id::text) AND cust.type_id::text = ct.fin_id::text AND deals.products_id::text = prd.fin_id::text AND deals.ud_deal_types_id::text = uddt.fin_id::text AND uddt.ud_deal_types_id::text = uddealtypes.fin_id::text AND deals.maker_checker_status::text = 'COMMITTED'::text AND deals.is_deleted::text = 'N'::text AND versions.maker_checker_status::text = 'COMMITTED'::text AND versions.is_deleted::text = 'N'::text AND bkn.maker_checker_status::text = 'COMMITTED'::text AND bkn.is_deleted::text = 'N'::text AND rp.maker_checker_status::text = 'COMMITTED'::text AND rp.is_deleted::text = 'N'::text AND ct.maker_checker_status::text = 'COMMITTED'::text AND ct.is_deleted::text = 'N'::text AND cust.maker_checker_status::text = 'COMMITTED'::text AND cust.is_deleted::text = 'N'::text AND (deals.products_id::text IN ( SELECT tbls_products.fin_id
           FROM tbls_products
          WHERE tbls_products.code::text = ANY (ARRAY['BKN'::character varying::text, 'TCQ'::character varying::text]))) AND deals.action::text <> 'CANCEL'::text AND (deals.products_id::text <> ALL (ARRAY['BKN_CAEX'::character varying::text, 'BKN_DISC'::character varying::text, 'BKN_DISW'::character varying::text, 'TCQ_DISC'::character varying::text, 'TCQ_DISW'::character varying::text])) AND to_char(deals.action_date, 'YYYYMMDD'::text) <= (( SELECT to_char(tbls_dates_master.accounting_date, 'YYYYMMDD'::text) AS to_char
           FROM tbls_dates_master))
UNION ALL
 SELECT ((deals.deal_no::text || '_'::text) || deals.version_no) || 'P'::text AS fin_id,
    'CTC'::text AS rule_type,
    fx_deals.external_no,
    deals.deal_no,
    deals.version_no,
    'IFX'::character varying AS product_type,
    deals.products_id AS deal_type,
    'ALL'::text AS deal_sub_type,
    deals.ud_deal_types_id AS ud_deal_type,
    uddealtypes.fin_id AS ud_deal_types_id2,
        CASE
            WHEN deals.trade_date < deals.action_date THEN deals.action_date
            ELSE deals.trade_date
        END AS trade_date,
        CASE
            WHEN deals.value_date < deals.action_date THEN deals.action_date
            ELSE deals.value_date
        END AS value_date,
    NULL::timestamp without time zone AS release_date,
    NULL::timestamp without time zone AS vault_date,
    NULL::timestamp without time zone AS memo_rev_date,
    ( SELECT max(tbls_dates_master.accounting_date) AS max
           FROM tbls_dates_master) AS accounting_date,
    'DEAL_SETL_AMT_POSITIVE'::text AS ctc_mtm_sign,
    fx_deals.buy_currency_id AS currency,
    fx_deals.buy_amount AS amount,
    deals.repositories_id,
    rp.corp_code,
    rp.cost_center,
    cust.short_name AS customers_id,
    cust.country_incorporation_id AS customer_country,
    cust.is_resident,
    ct.type_code AS customer_type,
    ''::text AS funding_position_sign,
    rp.glbranch_code
   FROM tbls_deals deals,
    tbls_deal_versions versions,
    tbls_fx_deals fx_deals,
    tbls_repositories rp,
    tbls_customers cust,
    tbls_customer_types ct,
    tbls_ud_dt_mapping uddt,
    tbls_ud_deal_types uddealtypes
  WHERE deals.fin_id::text = versions.deals_id::text AND deals.version_no = versions.version_no AND versions.fin_id::text = fx_deals.deal_versions_id::text AND deals.repositories_id::text = rp.fin_id::text AND btrim(deals.customers_id::text) = btrim(cust.fin_id::text) AND cust.type_id::text = ct.fin_id::text AND deals.maker_checker_status::text = 'COMMITTED'::text AND deals.is_deleted::text = 'N'::text AND deals.ud_deal_types_id::text = uddt.fin_id::text AND uddt.ud_deal_types_id::text = uddealtypes.fin_id::text AND versions.maker_checker_status::text = 'COMMITTED'::text AND versions.is_deleted::text = 'N'::text AND fx_deals.maker_checker_status::text = 'COMMITTED'::text AND fx_deals.is_deleted::text = 'N'::text AND rp.maker_checker_status::text = 'COMMITTED'::text AND rp.is_deleted::text = 'N'::text AND ct.maker_checker_status::text = 'COMMITTED'::text AND ct.is_deleted::text = 'N'::text AND cust.maker_checker_status::text = 'COMMITTED'::text AND cust.is_deleted::text = 'N'::text AND (deals.products_id::text IN ( SELECT tbls_products.fin_id
           FROM tbls_products
          WHERE tbls_products.code::text = 'IFX'::text)) AND deals.action::text <> 'CANCEL'::text AND to_char(deals.action_date, 'YYYYMMDD'::text) <= (( SELECT to_char(tbls_dates_master.accounting_date, 'YYYYMMDD'::text) AS to_char
           FROM tbls_dates_master))
UNION ALL
 SELECT ((deals.deal_no::text || '_'::text) || deals.version_no) || 'N'::text AS fin_id,
    'CTC'::text AS rule_type,
    fx_deals.external_no,
    deals.deal_no,
    deals.version_no,
    'IFX'::character varying AS product_type,
    deals.products_id AS deal_type,
    'ALL'::text AS deal_sub_type,
    deals.ud_deal_types_id AS ud_deal_type,
    uddealtypes.fin_id AS ud_deal_types_id2,
        CASE
            WHEN deals.trade_date < deals.action_date THEN deals.action_date
            ELSE deals.trade_date
        END AS trade_date,
        CASE
            WHEN deals.value_date < deals.action_date THEN deals.action_date
            ELSE deals.value_date
        END AS value_date,
    NULL::timestamp without time zone AS release_date,
    NULL::timestamp without time zone AS vault_date,
    NULL::timestamp without time zone AS memo_rev_date,
    ( SELECT max(tbls_dates_master.accounting_date) AS max
           FROM tbls_dates_master) AS accounting_date,
    'DEAL_SETL_AMT_NEGATIVE'::text AS ctc_mtm_sign,
    fx_deals.sell_currency_id AS currency,
    fx_deals.sell_amount AS amount,
    deals.repositories_id,
    rp.corp_code,
    rp.cost_center,
    cust.short_name AS customers_id,
    cust.country_incorporation_id AS customer_country,
    cust.is_resident,
    ct.type_code AS customer_type,
    ''::text AS funding_position_sign,
    rp.glbranch_code
   FROM tbls_deals deals,
    tbls_deal_versions versions,
    tbls_fx_deals fx_deals,
    tbls_repositories rp,
    tbls_customers cust,
    tbls_customer_types ct,
    tbls_ud_dt_mapping uddt,
    tbls_ud_deal_types uddealtypes
  WHERE deals.fin_id::text = versions.deals_id::text AND deals.version_no = versions.version_no AND versions.fin_id::text = fx_deals.deal_versions_id::text AND deals.repositories_id::text = rp.fin_id::text AND btrim(deals.customers_id::text) = btrim(cust.fin_id::text) AND cust.type_id::text = ct.fin_id::text AND deals.ud_deal_types_id::text = uddt.fin_id::text AND uddt.ud_deal_types_id::text = uddealtypes.fin_id::text AND deals.maker_checker_status::text = 'COMMITTED'::text AND deals.is_deleted::text = 'N'::text AND versions.maker_checker_status::text = 'COMMITTED'::text AND versions.is_deleted::text = 'N'::text AND fx_deals.maker_checker_status::text = 'COMMITTED'::text AND fx_deals.is_deleted::text = 'N'::text AND rp.maker_checker_status::text = 'COMMITTED'::text AND rp.is_deleted::text = 'N'::text AND ct.maker_checker_status::text = 'COMMITTED'::text AND ct.is_deleted::text = 'N'::text AND cust.maker_checker_status::text = 'COMMITTED'::text AND cust.is_deleted::text = 'N'::text AND (deals.products_id::text IN ( SELECT tbls_products.fin_id
           FROM tbls_products
          WHERE tbls_products.code::text = 'IFX'::text)) AND deals.action::text <> 'CANCEL'::text AND to_char(deals.action_date, 'YYYYMMDD'::text) <= (( SELECT to_char(tbls_dates_master.accounting_date, 'YYYYMMDD'::text) AS to_char
           FROM tbls_dates_master))
UNION ALL
 SELECT
        CASE
            WHEN bkn.commission_amount < 0::numeric THEN ((deals.deal_no::text || '_'::text) || deals.version_no) || 'COMM_N'::text
            ELSE ((deals.deal_no::text || '_'::text) || deals.version_no) || 'COMM_P'::text
        END AS fin_id,
    'CTC'::text AS rule_type,
    ''::character varying AS external_no,
    deals.deal_no,
    deals.version_no,
    prd.code AS product_type,
    deals.products_id AS deal_type,
    'ALL'::text AS deal_sub_type,
    deals.ud_deal_types_id AS ud_deal_type,
    uddealtypes.fin_id AS ud_deal_types_id2,
        CASE
            WHEN deals.trade_date < deals.action_date THEN deals.action_date
            ELSE deals.trade_date
        END AS trade_date,
        CASE
            WHEN deals.value_date < deals.action_date THEN deals.action_date
            ELSE deals.value_date
        END AS value_date,
    bkn.release_date,
    bkn.vault_date,
    deals.maturity_date AS memo_rev_date,
    ( SELECT max(tbls_dates_master.accounting_date) AS max
           FROM tbls_dates_master) AS accounting_date,
        CASE
            WHEN bkn.commission_amount < 0::numeric THEN 'COMMISSION_AMOUNT_NEGATIVE'::text
            ELSE 'COMMISSION_AMOUNT_POSITIVE'::text
        END AS ctc_mtm_sign,
    bkn.commission_cur_id AS currency,
    bkn.commission_amount AS amount,
    deals.repositories_id,
    rp.corp_code,
    rp.cost_center,
    cust.short_name AS customers_id,
    cust.country_incorporation_id AS customer_country,
    cust.is_resident,
    ct.type_code AS customer_type,
    ''::text AS funding_position_sign,
    rp.glbranch_code
   FROM tbls_deals deals,
    tbls_deal_versions versions,
    tbls_bank_notes_deals bkn,
    tbls_repositories rp,
    tbls_customers cust,
    tbls_customer_types ct,
    tbls_products prd,
    tbls_ud_dt_mapping uddt,
    tbls_ud_deal_types uddealtypes
  WHERE bkn.commission_amount <> 0::numeric AND bkn.commission_setl_type::text = 'tt'::text AND deals.fin_id::text = versions.deals_id::text AND deals.version_no = versions.version_no AND versions.fin_id::text = bkn.fin_id::text AND deals.repositories_id::text = rp.fin_id::text AND btrim(deals.customers_id::text) = btrim(cust.fin_id::text) AND cust.type_id::text = ct.fin_id::text AND deals.products_id::text = prd.fin_id::text AND deals.ud_deal_types_id::text = uddt.fin_id::text AND uddt.ud_deal_types_id::text = uddealtypes.fin_id::text AND deals.maker_checker_status::text = 'COMMITTED'::text AND deals.is_deleted::text = 'N'::text AND versions.maker_checker_status::text = 'COMMITTED'::text AND versions.is_deleted::text = 'N'::text AND bkn.maker_checker_status::text = 'COMMITTED'::text AND bkn.is_deleted::text = 'N'::text AND rp.maker_checker_status::text = 'COMMITTED'::text AND rp.is_deleted::text = 'N'::text AND ct.maker_checker_status::text = 'COMMITTED'::text AND ct.is_deleted::text = 'N'::text AND cust.maker_checker_status::text = 'COMMITTED'::text AND cust.is_deleted::text = 'N'::text AND (deals.products_id::text IN ( SELECT tbls_products.fin_id
           FROM tbls_products
          WHERE tbls_products.code::text = ANY (ARRAY['BKN'::character varying::text, 'TCQ'::character varying::text]))) AND deals.action::text <> 'CANCEL'::text AND (deals.products_id::text <> ALL (ARRAY['BKN_CAEX'::character varying::text, 'BKN_DISC'::character varying::text, 'BKN_DISW'::character varying::text, 'TCQ_DISC'::character varying::text, 'TCQ_DISW'::character varying::text])) AND to_char(deals.action_date, 'YYYYMMDD'::text) <= (( SELECT to_char(tbls_dates_master.accounting_date, 'YYYYMMDD'::text) AS to_char
           FROM tbls_dates_master))
UNION ALL
 SELECT (((((((ctc.repository_id::text || '_'::text) || ctc.native_ccy_id::text) || '_'::text) || 'ALL'::text) || '_'::text) || to_char(ctc.reference_date, 'YYYYMMDD'::text)) || '_'::text) || ctc.interest_amount_sign::text AS fin_id,
    'CTC'::text AS rule_type,
    ''::character varying AS external_no,
    ''::character varying AS deal_no,
    0 AS version_no,
    'ALL'::character varying AS product_type,
    'ALL'::character varying AS deal_type,
    'ALL'::text AS deal_sub_type,
    'ALL'::character varying AS ud_deal_type,
    'ALL'::character varying AS ud_deal_types_id2,
    NULL::timestamp without time zone AS trade_date,
    ctc.reference_date AS value_date,
    NULL::timestamp without time zone AS release_date,
    NULL::timestamp without time zone AS vault_date,
    NULL::timestamp without time zone AS memo_rev_date,
    ctc.entry_date AS accounting_date,
    ctc.interest_amount_sign AS ctc_mtm_sign,
    ctc.native_ccy_id AS currency,
    abs(sum(ctc.native_ctc)) AS amount,
    ctc.repository_id AS repositories_id,
    rp.corp_code,
    rp.cost_center,
    ''::character varying AS customers_id,
    ''::character varying AS customer_country,
    ''::character varying AS is_resident,
    'ALL'::character varying AS customer_type,
    ctc.interest_amount_sign AS funding_position_sign,
    rp.glbranch_code
   FROM tbls_cost_to_carry ctc,
    tbls_repositories rp
  WHERE ctc.repository_id::text = rp.fin_id::text AND ctc.maker_checker_status::text = 'COMMITTED'::text AND ctc.is_deleted::text = 'N'::text AND rp.maker_checker_status::text = 'COMMITTED'::text AND rp.is_deleted::text = 'N'::text AND ctc.entry_date = (( SELECT tbls_dates_master.accounting_date
           FROM tbls_dates_master))
  GROUP BY ctc.reference_date, ctc.entry_date, ctc.interest_amount_sign, ctc.native_ccy_id, ctc.repository_id, rp.corp_code, rp.cost_center, rp.glbranch_code;
  
  
drop VIEW IF EXISTS vbls_discrepancy_entries;		   
CREATE OR REPLACE VIEW vbls_discrepancy_entries AS
 SELECT (record.discrepancy_number::text || '_'::text) || leg.leg_number AS fin_id,
    'DISCREPANCY RECORD'::text AS rule_type,
    record.discrepancy_number,
    leg.leg_number AS leg_no,
    record.products_id AS product_type,
    'ALL'::text AS deal_type,
        CASE
            WHEN rectype.plus_minus = 'M'::bpchar THEN 'EXCESS'::text
            ELSE 'SHORTAGE'::text
        END AS buy_sell,
    leg.currency_id AS currency,
    leg.amount,
    record.repository_id,
    repositories.corp_code,
    repositories.cost_center,
    cust.short_name AS customers_id,
    cust.country_incorporation_id AS customer_country,
    cust.is_resident,
    ct.type_code AS customer_type,
    record.verification_date AS validation_date,
    record.sdi_id AS discrepancy_sdi,
    repositories.glbranch_code
   FROM tbls_discrepancy_records record,
    tbls_discrepancy_record_legs leg,
    tbls_discrepancy_types rectype,
    tbls_customers cust,
    tbls_customer_types ct,
    tbls_repositories repositories,
    tbls_dates_master datesmaster,
    tbls_regions regions
  WHERE record.fin_id::text = leg.discrepancy_record_id::text AND record.discrepancy_type_id::text = rectype.fin_id::text AND record.customers_id::text = cust.fin_id::text AND cust.type_id::text = ct.fin_id::text AND regions.fin_id::text = datesmaster.region_id::text AND repositories.fin_id::text = record.repository_id::text AND record.action::text <> 'CANCEL'::text;

  drop VIEW IF EXISTS vbls_fx_deal_entries;	
 CREATE OR REPLACE VIEW vbls_fx_deal_entries AS
 SELECT (deals.deal_no::text || '_'::text) || deals.version_no AS fin_id,
    'DEAL'::text AS rule_type,
        CASE
            WHEN fx_deals.external_no IS NULL THEN fx_deals.external_other_no
            ELSE fx_deals.external_no
        END AS external_no,
    deals.deal_no,
    deals.version_no,
    0 AS leg_no,
    prd.code AS product_type,
    prd.deal_type_code AS deal_type,
    'UNLIKE'::text AS deal_sub_type,
    fx_deals.buy_sell,
    deals.entry_date,
        CASE
            WHEN deals.trade_date < deals.action_date THEN deals.action_date
            ELSE deals.trade_date
        END AS trade_date,
        CASE
            WHEN deals.value_date < deals.action_date THEN deals.action_date
            ELSE deals.value_date
        END AS value_date,
    ( SELECT tbls_dates_master.system_date
           FROM tbls_dates_master) AS accounting_date,
    NULL::timestamp without time zone AS release_date,
    NULL::timestamp without time zone AS vault_date,
    NULL::timestamp without time zone AS vault2_date,
    NULL::timestamp without time zone AS release2_date,
    NULL::timestamp without time zone AS memo_rev_date,
    fx_deals.buy_currency_id AS buy_currency,
    fx_deals.sell_currency_id AS sell_currency,
    fx_deals.buy_amount,
    fx_deals.sell_amount,
    0 AS settlement_amount,
    deals.repositories_id,
    rp.corp_code,
    rp.cost_center,
    cust.short_name AS customers_id,
    cust.country_incorporation_id AS customer_country,
    cust.is_resident,
    ct.type_code AS customer_type,
    fx_deals.deal_rate,
    COALESCE(fx_deals.spot_rate, 0::numeric) AS market_rate,
    0 AS usd_rate_vs_setl_cur,
    fx_deals.usd_rate_vs_base_cur,
    fx_deals.usd_rate_vs_sell_cur,
    fx_deals.usd_rate_vs_buy_cur,
    'NA'::text AS md,
    1 AS spotfactor,
    deals.ud_deal_types_id,
    uddealtypes.fin_id AS ud_deal_types_id2,
    branch.branch_id,
    0 AS leg_ccy_vs_lcu_spotrate,
    0 AS lcu_eqv_amount,
    0 AS lcu_setl_eqv_amount,
    rp.glbranch_code
   FROM tbls_deals deals,
    tbls_deal_versions versions,
    tbls_fx_deals fx_deals,
    tbls_repositories rp,
    tbls_customers cust,
    tbls_customer_types ct,
    tbls_ud_dt_mapping uddt,
    tbls_ud_deal_types uddealtypes,
    tbls_products prd,
    tbls_branches branch
  WHERE deals.fin_id::text = versions.deals_id::text AND deals.version_no = versions.version_no AND versions.fin_id::text = fx_deals.deal_versions_id::text AND deals.repositories_id::text = rp.fin_id::text AND deals.customers_id::text = cust.fin_id::text AND cust.type_id::text = ct.fin_id::text AND deals.products_id::text = prd.fin_id::text AND deals.ud_deal_types_id::text = uddt.fin_id::text AND uddt.ud_deal_types_id::text = uddealtypes.fin_id::text AND deals.action::text <> 'CANCEL'::text AND to_char(deals.trade_date, 'YYYYMMDD'::text) <= (( SELECT to_char(tbls_dates_master.accounting_date, 'YYYYMMDD'::text) AS to_char
           FROM tbls_dates_master)) AND deals.maker_checker_status::text = 'COMMITTED'::text AND deals.is_deleted::text = 'N'::text AND versions.maker_checker_status::text = 'COMMITTED'::text AND versions.is_deleted::text = 'N'::text AND fx_deals.maker_checker_status::text = 'COMMITTED'::text AND fx_deals.is_deleted::text = 'N'::text AND rp.maker_checker_status::text = 'COMMITTED'::text AND rp.is_deleted::text = 'N'::text AND ct.maker_checker_status::text = 'COMMITTED'::text AND ct.is_deleted::text = 'N'::text AND cust.maker_checker_status::text = 'COMMITTED'::text AND cust.is_deleted::text = 'N'::text AND (deals.products_id::text IN ( SELECT tbls_products.fin_id
           FROM tbls_products
          WHERE tbls_products.code::text = 'IFX'::text)) AND deals.branches_id::text = branch.fin_id::text;
		  
drop VIEW IF EXISTS vbls_fx_position_dealentries;
CREATE OR REPLACE VIEW vbls_fx_position_dealentries AS
 SELECT versions.fin_id,
    versions.deals_id AS deal_no,
    versions.version_no,
    prd.code AS product_type,
    versions.buy_sell,
        CASE
            WHEN versions.trade_date < versions.action_date THEN versions.action_date
            ELSE versions.trade_date
        END AS trade_date,
    bn.setl_cur_id AS settlement_ccy,
    bn.net_setl_amt AS settlement_amount,
    versions.repositories_id,
    cust.short_name AS customers_id,
    cust.country_incorporation_id AS customer_country,
    cust.is_resident,
    ct.type_code AS customer_type,
    versions.ud_deal_types_id,
    uddt.is_mis_included,
    rp.glbranch_code
   FROM tbls_deal_versions versions,
    tbls_bank_notes_deals bn,
    tbls_repositories rp,
    tbls_customers cust,
    tbls_customer_types ct,
    tbls_products prd,
    tbls_ud_dt_mapping uddt
  WHERE versions.fin_id::text = bn.fin_id::text AND versions.repositories_id::text = rp.fin_id::text AND versions.customers_id::text = cust.fin_id::text AND cust.type_id::text = ct.fin_id::text AND versions.products_id::text = prd.fin_id::text AND versions.ud_deal_types_id::text = uddt.fin_id::text AND versions.maker_checker_status::text = 'COMMITTED'::text AND versions.is_deleted::text = 'N'::text AND bn.maker_checker_status::text = 'COMMITTED'::text AND bn.is_deleted::text = 'N'::text AND rp.maker_checker_status::text = 'COMMITTED'::text AND rp.is_deleted::text = 'N'::text AND ct.maker_checker_status::text = 'COMMITTED'::text AND ct.is_deleted::text = 'N'::text AND cust.maker_checker_status::text = 'COMMITTED'::text AND cust.is_deleted::text = 'N'::text AND (versions.products_id::text IN ( SELECT tbls_products.fin_id
           FROM tbls_products
          WHERE tbls_products.code::text = ANY (ARRAY['BKN'::character varying::text, 'TCQ'::character varying::text])))
UNION ALL
 SELECT versions.fin_id,
    versions.deals_id AS deal_no,
    versions.version_no,
    'IFX'::character varying AS product_type,
    fx_deals.buy_sell,
        CASE
            WHEN versions.trade_date < versions.action_date THEN versions.action_date
            ELSE versions.trade_date
        END AS trade_date,
    ''::character varying AS settlement_ccy,
    0 AS settlement_amount,
    versions.repositories_id,
    cust.short_name AS customers_id,
    cust.country_incorporation_id AS customer_country,
    cust.is_resident,
    ct.type_code AS customer_type,
    versions.ud_deal_types_id,
    uddt.is_mis_included,
    rp.glbranch_code
   FROM tbls_deal_versions versions,
    tbls_fx_deals fx_deals,
    tbls_repositories rp,
    tbls_customers cust,
    tbls_customer_types ct,
    tbls_ud_dt_mapping uddt
  WHERE versions.fin_id::text = fx_deals.deal_versions_id::text AND versions.repositories_id::text = rp.fin_id::text AND versions.customers_id::text = cust.fin_id::text AND versions.ud_deal_types_id::text = uddt.fin_id::text AND cust.type_id::text = ct.fin_id::text AND versions.maker_checker_status::text = 'COMMITTED'::text AND versions.is_deleted::text = 'N'::text AND fx_deals.maker_checker_status::text = 'COMMITTED'::text AND fx_deals.is_deleted::text = 'N'::text AND rp.maker_checker_status::text = 'COMMITTED'::text AND rp.is_deleted::text = 'N'::text AND ct.maker_checker_status::text = 'COMMITTED'::text AND ct.is_deleted::text = 'N'::text AND cust.maker_checker_status::text = 'COMMITTED'::text AND cust.is_deleted::text = 'N'::text AND (versions.products_id::text IN ( SELECT tbls_products.fin_id
           FROM tbls_products
          WHERE tbls_products.code::text = 'IFX'::text));
		  
drop VIEW IF EXISTS vbls_mtm_entries;		  
CREATE OR REPLACE VIEW vbls_mtm_entries AS
 SELECT eodpl.fin_id,
    (eodpl.deal_no::text || '_'::text) || eodpl.leg_no AS trans_ref,
    ''::text AS external_no,
    eodpl.deal_no,
    eodpl.leg_no::character varying AS leg_no,
    deals.version_no,
    'MTM'::text AS rule_type,
    'MTM_TODAY'::text AS deal_flag,
        CASE
            WHEN deals.maturity_date >= deals.action_date AND deals.maturity_date <= datesmaster.accounting_date THEN 'REALISED'::text
            WHEN deals.maturity_date <= deals.action_date AND deals.action_date <= datesmaster.accounting_date THEN 'REALISED'::text
            WHEN deals.maturity_date >= deals.action_date AND deals.maturity_date > datesmaster.accounting_date THEN 'UNREALISED'::text
            WHEN deals.maturity_date <= deals.action_date AND deals.action_date > datesmaster.accounting_date THEN 'UNREALISED'::text
            ELSE NULL::text
        END AS realised_flag,
    cust.short_name AS customers_id,
    ct.type_code AS customer_type,
    eodpl.product_code AS product_type,
    legs.currencies_id AS currency,
    products.deal_type_code AS deal_type,
    uddeals.fin_id AS ud_deal_type,
    uddealtypes.fin_id AS ud_deal_types_id2,
        CASE
            WHEN legs.currencies_id::text = bndeals.setl_cur_id::text THEN
            CASE
                WHEN legs.currencies_id::text = regions.currencies_id::text THEN 'LIKE_BASE'::text
                ELSE 'LIKE'::text
            END
            ELSE 'UNLIKE'::text
        END AS deal_sub_type,
        CASE
            WHEN (eodpl.unrealized_pl * eodpl.discount_factor_base_ccy + eodpl.realised_pl_today) > 0::numeric THEN 'MTM_POSITIVE'::text
            ELSE 'MTM_NEGATIVE'::text
        END AS ctc_mtm_sign_today,
        CASE
            WHEN (eodpl.unrealized_pl * eodpl.discount_factor_base_ccy + eodpl.realised_pl_today) > 0::numeric THEN abs(eodpl.unrealized_pl * eodpl.discount_factor_base_ccy + eodpl.realised_pl_today)
            ELSE 0::numeric
        END AS mtm_gain,
        CASE
            WHEN (eodpl.unrealized_pl * eodpl.discount_factor_base_ccy + eodpl.realised_pl_today) <= 0::numeric THEN abs(eodpl.unrealized_pl * eodpl.discount_factor_base_ccy + eodpl.realised_pl_today)
            ELSE 0::numeric
        END AS mtm_loss,
    eodpl.repository_id AS repository,
    repositories.corp_code,
    repositories.cost_center,
        CASE
            WHEN deals.trade_date < deals.action_date THEN deals.action_date
            ELSE deals.trade_date
        END AS trade_date,
        CASE
            WHEN deals.value_date < deals.action_date THEN deals.action_date
            ELSE deals.value_date
        END AS value_date,
        CASE
            WHEN deals.maturity_date < deals.action_date THEN deals.action_date
            ELSE deals.maturity_date
        END AS memo_rev_date,
    datesmaster.accounting_date,
    cust.is_resident,
    repositories.glbranch_code
   FROM tbls_dealwise_eod_pl eodpl,
    tbls_ud_dt_mapping uddeals,
    tbls_ud_deal_types uddealtypes,
    tbls_deals deals,
    tbls_deal_versions versions,
    tbls_bank_notes_deals bndeals,
    tbls_bank_notes_deals_legs legs,
    tbls_customers cust,
    tbls_customer_types ct,
    tbls_products products,
    tbls_repositories repositories,
    tbls_dates_master datesmaster,
    tbls_regions regions
  WHERE uddeals.fin_id::text = eodpl.ud_deal_type_id::text AND uddeals.ud_deal_types_id::text = uddealtypes.fin_id::text AND eodpl.product_id::text = products.fin_id::text AND deals.deal_no::text = eodpl.deal_no::text AND deals.repositories_id::text = repositories.fin_id::text AND versions.fin_id::text = bndeals.fin_id::text AND legs.bank_notes_deals_id::text = bndeals.fin_id::text AND legs.leg_number = eodpl.leg_no AND deals.version_no = eodpl.version_no AND deals.fin_id::text = versions.deals_id::text AND deals.version_no = versions.version_no AND deals.customers_id::text = cust.fin_id::text AND cust.type_id::text = ct.fin_id::text AND deals.action::text <> 'CANCEL'::text AND to_char(deals.action_date, 'YYYYMMDD'::text) <= (( SELECT to_char(tbls_dates_master.accounting_date, 'YYYYMMDD'::text) AS to_char
           FROM tbls_dates_master)) AND to_char(eodpl.pl_date, 'YYYYMMDD'::text) = to_char(datesmaster.accounting_date, 'YYYYMMDD'::text) AND to_char(eodpl.deal_value_date, 'YYYYMMDD'::text) >= to_char(datesmaster.accounting_date, 'YYYYMMDD'::text) AND regions.fin_id::text = datesmaster.region_id::text
UNION ALL
 SELECT eodpl.fin_id,
    eodpl.deal_no AS trans_ref,
    ''::text AS external_no,
    eodpl.deal_no,
    '0'::character varying AS leg_no,
    deals.version_no,
    'MTM'::text AS rule_type,
    'MTM_TODAY'::text AS deal_flag,
        CASE
            WHEN deals.value_date >= deals.trade_date AND deals.value_date <= datesmaster.accounting_date THEN 'REALISED'::text
            WHEN deals.value_date <= deals.trade_date AND deals.trade_date <= datesmaster.accounting_date THEN 'REALISED'::text
            WHEN deals.value_date >= deals.trade_date AND deals.value_date > datesmaster.accounting_date THEN 'UNREALISED'::text
            WHEN deals.value_date <= deals.trade_date AND deals.trade_date > datesmaster.accounting_date THEN 'UNREALISED'::text
            ELSE NULL::text
        END AS realised_flag,
    cust.short_name AS customers_id,
    ct.type_code AS customer_type,
    eodpl.product_code AS product_type,
    fxdeals.sell_currency_id AS currency,
    products.deal_type_code AS deal_type,
    uddeals.fin_id AS ud_deal_type,
    uddealtypes.fin_id AS ud_deal_types_id2,
        CASE
            WHEN fxdeals.buy_currency_id::text = fxdeals.sell_currency_id::text THEN
            CASE
                WHEN fxdeals.buy_currency_id::text = regions.currencies_id::text THEN 'LIKE_BASE'::text
                ELSE 'LIKE'::text
            END
            ELSE 'UNLIKE'::text
        END AS deal_sub_type,
        CASE
            WHEN (eodpl.unrealized_pl * eodpl.discount_factor_base_ccy + eodpl.realised_pl_today) > 0::numeric THEN 'MTM_POSITIVE'::text
            ELSE 'MTM_NEGATIVE'::text
        END AS ctc_mtm_sign_today,
        CASE
            WHEN (eodpl.unrealized_pl * eodpl.discount_factor_base_ccy + eodpl.realised_pl_today) > 0::numeric THEN abs(eodpl.unrealized_pl * eodpl.discount_factor_base_ccy + eodpl.realised_pl_today)
            ELSE 0::numeric
        END AS mtm_gain,
        CASE
            WHEN (eodpl.unrealized_pl * eodpl.discount_factor_base_ccy + eodpl.realised_pl_today) <= 0::numeric THEN abs(eodpl.unrealized_pl * eodpl.discount_factor_base_ccy + eodpl.realised_pl_today)
            ELSE 0::numeric
        END AS mtm_loss,
    eodpl.repository_id AS repository,
    repositories.corp_code,
    repositories.cost_center,
    deals.trade_date,
        CASE
            WHEN deals.value_date < deals.trade_date THEN deals.trade_date
            ELSE deals.value_date
        END AS value_date,
        CASE
            WHEN deals.value_date < deals.trade_date THEN deals.trade_date
            ELSE deals.value_date
        END AS memo_rev_date,
    datesmaster.accounting_date,
    cust.is_resident,
    repositories.glbranch_code
   FROM tbls_dealwise_eod_pl eodpl,
    tbls_ud_dt_mapping uddeals,
    tbls_ud_deal_types uddealtypes,
    tbls_deals deals,
    tbls_deal_versions versions,
    tbls_fx_deals fxdeals,
    tbls_customers cust,
    tbls_customer_types ct,
    tbls_products products,
    tbls_repositories repositories,
    tbls_dates_master datesmaster,
    tbls_regions regions
  WHERE uddeals.fin_id::text = eodpl.ud_deal_type_id::text AND uddeals.ud_deal_types_id::text = uddealtypes.fin_id::text AND eodpl.product_id::text = products.fin_id::text AND deals.deal_no::text = eodpl.deal_no::text AND deals.repositories_id::text = repositories.fin_id::text AND deals.version_no = eodpl.version_no AND deals.fin_id::text = versions.deals_id::text AND deals.version_no = versions.version_no AND deals.customers_id::text = cust.fin_id::text AND cust.type_id::text = ct.fin_id::text AND fxdeals.deal_versions_id::text = versions.fin_id::text AND deals.action::text <> 'CANCEL'::text AND to_char(deals.trade_date, 'YYYYMMDD'::text) <= (( SELECT to_char(tbls_dates_master.accounting_date, 'YYYYMMDD'::text) AS to_char
           FROM tbls_dates_master)) AND to_char(eodpl.pl_date, 'YYYYMMDD'::text) = to_char(datesmaster.accounting_date, 'YYYYMMDD'::text) AND to_char(eodpl.deal_value_date, 'YYYYMMDD'::text) >= to_char(datesmaster.accounting_date, 'YYYYMMDD'::text) AND regions.fin_id::text = datesmaster.region_id::text
UNION ALL
 SELECT (((((innerq.product_id || '_'::text) || innerq.repository_id::text) || '_'::text) || innerq.currency_id::text) || '_'::text) || 'FXPOSITION_TODAY'::text AS fin_id,
    ''::text AS trans_ref,
    ''::text AS external_no,
    ''::character varying AS deal_no,
    ''::character varying AS leg_no,
    0 AS version_no,
    'MTM'::text AS rule_type,
    'FXPOSITION_TODAY'::text AS deal_flag,
    'REALISED'::text AS realised_flag,
    ''::character varying AS customers_id,
    'ALL'::character varying AS customer_type,
    innerq.product_id AS product_type,
    innerq.currency_id AS currency,
    'ALL'::character varying AS deal_type,
    'ALL'::character varying AS ud_deal_type,
    'ALL'::character varying AS ud_deal_types_id2,
    'ALL'::text AS deal_sub_type,
        CASE
            WHEN sum(innerq.total_pl) > 0::numeric THEN 'MTM_POSITIVE'::text
            ELSE 'MTM_NEGATIVE'::text
        END AS ctc_mtm_sign_today,
        CASE
            WHEN sum(innerq.total_pl) > 0::numeric THEN abs(sum(innerq.total_pl))
            ELSE 0::numeric
        END AS mtm_gain,
        CASE
            WHEN sum(innerq.total_pl) <= 0::numeric THEN abs(sum(innerq.total_pl))
            ELSE 0::numeric
        END AS mtm_loss,
    innerq.repository_id AS repository,
    innerq.corp_code,
    innerq.cost_center,
    innerq.pl_date AS trade_date,
    innerq.pl_date AS value_date,
    innerq.pl_date AS memo_rev_date,
    innerq.reference_date AS accounting_date,
    'Y'::character varying AS is_resident,
    innerq.glbranch_code
   FROM ( SELECT 'ALL'::text AS product_id,
            dailypl.repository_id,
            repositories.corp_code,
            repositories.cost_center,
            regions.currencies_id AS currency_id,
            dailypl.pl_date,
            datesmaster.accounting_date AS reference_date,
            dailypl.total_pl,
            repositories.glbranch_code
           FROM tbls_daily_pl dailypl,
            tbls_repositories repositories,
            tbls_dates_master datesmaster,
            tbls_regions regions
          WHERE dailypl.repository_id::text = repositories.fin_id::text AND to_char(dailypl.pl_date, 'YYYYMMDD'::text) = to_char(datesmaster.accounting_date, 'YYYYMMDD'::text) AND to_char(dailypl.reference_date, 'YYYYMMDD'::text) = to_char(datesmaster.accounting_date, 'YYYYMMDD'::text) AND regions.fin_id::text = datesmaster.region_id::text) innerq
  GROUP BY innerq.product_id, innerq.repository_id, innerq.cost_center, innerq.corp_code, innerq.currency_id, innerq.pl_date, innerq.reference_date, innerq.glbranch_code;
		  
	drop VIEW IF EXISTS vbls_uob_deal_entries;		  
	CREATE OR REPLACE VIEW vbls_uob_deal_entries AS
 SELECT vbls_bkn_deal_entries.fin_id,
    vbls_bkn_deal_entries.rule_type,
    vbls_bkn_deal_entries.external_no,
    vbls_bkn_deal_entries.deal_no,
    vbls_bkn_deal_entries.version_no,
    vbls_bkn_deal_entries.leg_no,
    vbls_bkn_deal_entries.product_type,
    vbls_bkn_deal_entries.deal_type,
    vbls_bkn_deal_entries.deal_sub_type,
    vbls_bkn_deal_entries.buy_sell,
    vbls_bkn_deal_entries.entry_date,
    vbls_bkn_deal_entries.trade_date,
    vbls_bkn_deal_entries.value_date,
    vbls_bkn_deal_entries.release_date,
    vbls_bkn_deal_entries.vault_date,
    vbls_bkn_deal_entries.vault2_date,
    vbls_bkn_deal_entries.release2_date,
    vbls_bkn_deal_entries.accounting_date,
    vbls_bkn_deal_entries.memo_rev_date,
    vbls_bkn_deal_entries.buy_currency,
    vbls_bkn_deal_entries.sell_currency,
    vbls_bkn_deal_entries.buy_amount,
    vbls_bkn_deal_entries.sell_amount,
    vbls_bkn_deal_entries.settlement_amount,
    vbls_bkn_deal_entries.repositories_id,
    vbls_bkn_deal_entries.corp_code,
    vbls_bkn_deal_entries.cost_center,
    vbls_bkn_deal_entries.customers_id,
    vbls_bkn_deal_entries.customer_country,
    vbls_bkn_deal_entries.is_resident,
    vbls_bkn_deal_entries.customer_type,
    vbls_bkn_deal_entries.deal_rate,
    vbls_bkn_deal_entries.market_rate,
    vbls_bkn_deal_entries.usd_rate_vs_setl_cur,
    vbls_bkn_deal_entries.usd_rate_vs_base_cur,
    vbls_bkn_deal_entries.usd_rate_vs_sell_cur,
    vbls_bkn_deal_entries.usd_rate_vs_buy_cur,
    vbls_bkn_deal_entries.md,
    vbls_bkn_deal_entries.spotfactor,
    vbls_bkn_deal_entries.ud_deal_types_id,
    vbls_bkn_deal_entries.ud_deal_types_id2,
    vbls_bkn_deal_entries.branch_id,
    vbls_bkn_deal_entries.leg_ccy_vs_lcu_spotrate,
    vbls_bkn_deal_entries.lcu_eqv_amount,
    vbls_bkn_deal_entries.lcu_setl_eqv_amount,
    vbls_bkn_deal_entries.glbranch_code
   FROM vbls_bkn_deal_entries
UNION ALL
 SELECT vbls_fx_deal_entries.fin_id,
    vbls_fx_deal_entries.rule_type,
    vbls_fx_deal_entries.external_no,
    vbls_fx_deal_entries.deal_no,
    vbls_fx_deal_entries.version_no,
    vbls_fx_deal_entries.leg_no,
    vbls_fx_deal_entries.product_type,
    vbls_fx_deal_entries.deal_type,
    vbls_fx_deal_entries.deal_sub_type,
    vbls_fx_deal_entries.buy_sell,
    vbls_fx_deal_entries.entry_date,
    vbls_fx_deal_entries.trade_date,
    vbls_fx_deal_entries.value_date,
    vbls_fx_deal_entries.accounting_date AS release_date,
    vbls_fx_deal_entries.release_date AS vault_date,
    vbls_fx_deal_entries.vault_date AS vault2_date,
    vbls_fx_deal_entries.vault2_date AS release2_date,
    vbls_fx_deal_entries.release2_date AS accounting_date,
    vbls_fx_deal_entries.memo_rev_date,
    vbls_fx_deal_entries.buy_currency,
    vbls_fx_deal_entries.sell_currency,
    vbls_fx_deal_entries.buy_amount,
    vbls_fx_deal_entries.sell_amount,
    vbls_fx_deal_entries.settlement_amount,
    vbls_fx_deal_entries.repositories_id,
    vbls_fx_deal_entries.corp_code,
    vbls_fx_deal_entries.cost_center,
    vbls_fx_deal_entries.customers_id,
    vbls_fx_deal_entries.customer_country,
    vbls_fx_deal_entries.is_resident,
    vbls_fx_deal_entries.customer_type,
    vbls_fx_deal_entries.deal_rate,
    vbls_fx_deal_entries.market_rate,
    vbls_fx_deal_entries.usd_rate_vs_setl_cur,
    vbls_fx_deal_entries.usd_rate_vs_base_cur,
    vbls_fx_deal_entries.usd_rate_vs_sell_cur,
    vbls_fx_deal_entries.usd_rate_vs_buy_cur,
    vbls_fx_deal_entries.md,
    vbls_fx_deal_entries.spotfactor,
    vbls_fx_deal_entries.ud_deal_types_id,
    vbls_fx_deal_entries.ud_deal_types_id2,
    vbls_fx_deal_entries.branch_id,
    vbls_fx_deal_entries.leg_ccy_vs_lcu_spotrate,
    vbls_fx_deal_entries.lcu_eqv_amount,
    vbls_fx_deal_entries.lcu_setl_eqv_amount,
    vbls_fx_deal_entries.glbranch_code
   FROM vbls_fx_deal_entries;
   
   
   
   ------------------------------------------------------------------------------------------------------------------------------------------
   
   
   
   drop VIEW IF EXISTS vbls_inv_pos_grp_physical;		
   CREATE OR REPLACE VIEW vbls_inv_pos_grp_physical AS
 WITH all_vaults_inventory_position AS (
         SELECT (((((((((((((invpos.currency::text || '_'::text) || invpos.productscode::text) || '_'::text) || invpos.denomid::text) || '_'::text) || invpos.banknotestypeid::text) || '_'::text) || 'All Regional Vaults'::text) || '_'::text) || invpos.sub_vault_name::text) || '_'::text) || invpos.vaultdate) || '_'::text) || invpos.systemdate AS fin_id,
            invpos.currency,
            invpos.productscode,
            invpos.denomid,
            invpos.denomination,
            invpos.denomcode,
            invpos.banknotestypeid,
            invpos.banknotestype,
            'All Regional Vaults_'::text || invpos.sub_vault_name::text AS vaultid,
            'All Regional Vaults'::text AS main_vault_name,
            invpos.sub_vault_name,
            invpos.vaultdate,
            invpos.systemdate,
            invpos.datediff,
            invpos.dateflag,
            sum(invpos.amount) AS amount
           FROM vbls_inventory_position invpos,
            tbls_vaults v
          WHERE invpos.vaultid::text = v.fin_id::text AND v.vault_type::text = 'Regional Vault'::text
          GROUP BY invpos.currency, invpos.productscode, invpos.denomid, invpos.denomination, invpos.denomcode, invpos.banknotestypeid, invpos.banknotestype, invpos.sub_vault_name, invpos.vaultdate, invpos.systemdate, invpos.datediff, invpos.dateflag
        )
 SELECT (((((((a.dateflag || a.currency::text) || a.productscode::text) || substr('000000000'::text, 0, length('000000000'::text) - length(a.denomination::text))) || a.denomination::text) || COALESCE(a.denomcode::text, ''::text)) || a.banknotestype::text) || a.vaultid) || a.vaultdate AS fin_id,
    a.currency,
    a.productscode,
    a.denomination,
    a.denomcode,
    a.denomid,
    a.banknotestype,
    a.vaultid,
    a.main_vault_name,
    a.sub_vault_name,
    a.vaultdate,
    a.datediff,
    a.dateflag,
    sum(b.amount) AS inventory
   FROM all_vaults_inventory_position a,
    all_vaults_inventory_position b
  WHERE (a.dateflag = 'HOLDING'::text AND a.dateflag = b.dateflag OR a.dateflag = 'OPEN'::text AND a.vaultdate >= b.vaultdate) AND a.currency::text = b.currency::text AND a.productscode::text = b.productscode::text AND a.denomination::text = b.denomination::text AND COALESCE(a.denomcode, ' '::character varying)::text = COALESCE(b.denomcode, ' '::character varying)::text AND a.banknotestype::text = b.banknotestype::text AND a.vaultid = b.vaultid
  GROUP BY a.currency, a.productscode, a.denomination, a.denomcode, a.denomid, a.banknotestype, a.vaultid, a.main_vault_name, a.sub_vault_name, a.vaultdate, a.datediff, a.dateflag
  ORDER BY a.currency, a.productscode, a.denomination, a.denomcode, a.denomid, a.banknotestype, a.vaultid, a.main_vault_name, a.sub_vault_name, a.vaultdate, a.dateflag;



--------------------------------------------------------------------------------------------------------------------------


drop VIEW IF EXISTS vbls_inv_pos_buysell_cumul;
CREATE OR REPLACE VIEW vbls_inv_pos_buysell_cumul
            (fin_id, currency, buy_sell, seq, productscode, denomination, denomcode, denomid, banknotestype, vaultid,
             main_vault_name, sub_vault_name, vaultdate, datediff, dateflag, inventory)
as
SELECT ((((((((a.dateflag || a.currency::text) || a.productscode::text) ||
             substr('000000000'::text, 0, length('000000000'::text) - length(a.denomination::text))) ||
            a.denomination::text) || COALESCE(a.denomcode::text, ''::text)) || a.banknotestype::text) || a.vaultid::text) || a.vaultdate) ||
       a.buy_sell    AS fin_id,
       a.currency,
       a.buy_sell,
       a.seq,
       a.productscode,
       a.denomination,
       a.denomcode,
       a.denomid,
       a.banknotestype,
       a.vaultid,
       a.main_vault_name,
       a.sub_vault_name,
       a.vaultdate,
       a.datediff,
       a.dateflag,
       sum(b.amount) AS inventory
FROM vbls_inventory_pos_buysell a,
     vbls_inventory_pos_buysell b
WHERE (a.dateflag = 'HOLDING'::text AND a.dateflag = b.dateflag OR
       a.dateflag = 'OPEN'::text AND a.vaultdate >= b.vaultdate)
  AND a.currency::text = b.currency::text
  AND a.productscode::text = b.productscode::text
  AND a.denomination::text = b.denomination::text
  AND COALESCE(a.denomcode, ' '::character varying)::text = COALESCE(b.denomcode, ' '::character varying)::text
  AND a.banknotestype::text = b.banknotestype::text
  AND a.vaultid::text = b.vaultid::text
  AND a.seq = b.seq
  AND a.buy_sell = b.buy_sell
GROUP BY a.currency, a.productscode, a.denomination, a.denomcode, a.denomid, a.banknotestype, a.vaultid,
         a.main_vault_name, a.sub_vault_name, a.buy_sell, a.seq, a.vaultdate, a.datediff, a.dateflag
ORDER BY a.currency, a.productscode, a.denomination, a.banknotestype, a.vaultid, a.vaultdate, a.seq;

--alter table vbls_inv_pos_buysell_cumul
--    owner to hkuser;



----------------------------------------------------------------------------------------------------------------------



drop VIEW IF EXISTS vbls_packing_list_search_view;

CREATE OR REPLACE VIEW vbls_packing_list_search_view
            (fin_id, shipment_method, shipper, consignee, packing_list_no, shipment_type_id, shipment_date,
             arrival_date, shipment_status, vault_status, last_updated_date, repositories_id)
as
SELECT          alias2.fin_id,
                alias2.shipment_method,
                alias2.shipper,
                alias2.consignee,
                alias2.packing_list_no,
                alias2.shipment_type_id,
                alias2.shipment_date,
                alias2.arrival_date,
                alias2.shipment_status,
                alias2.vault_status,
                alias2.last_updated_date,
                string_agg(distinct alias2.repositories_id, ',') as repositories_id

FROM (SELECT shipmentrecords.fin_id,
             shipmentrecords.shipment_method_id                            AS shipment_method,
             shipmentrecords.shipper_id                                    AS shipper,
             shipmentrecords.consignees_id                                 AS consignee,
             COALESCE(packinglist.packing_list_no, ' '::character varying) AS packing_list_no,
             shipmentrecords.shipment_type_id,
             shipmentrecords.shipment_date,
             shipmentrouting.arrival_date,
             workflowstatesshipment.name                                   AS shipment_status,
             workflowstatesvault.name                                      AS vault_status,
             shipmentrecords.last_updated                                  AS last_updated_date,
            dv.repositories_id as repositories_id
      FROM tbls_shipment_records shipmentrecords
               LEFT JOIN tbls_packing_list packinglist
                         ON packinglist.shipment_record_id::text = shipmentrecords.fin_id::text
                             AND packinglist.is_deleted::text = 'N'::text
           LEFT JOIN tbls_bank_notes_deals_legs bnklegs on bnklegs.shipment_records_id = shipmentrecords.fin_id
           LEFT JOIN tbls_bank_notes_deals bnkdeals on bnkdeals.fin_id = bnklegs.bank_notes_deals_id
           LEFT JOIN tbls_deal_versions dv on dv.fin_id = bnkdeals.fin_id,
           tbls_workflow_states workflowstatesshipment,
           tbls_workflow_states workflowstatesvault,
           tbls_shipment_record_routing shipmentrouting
      WHERE workflowstatesshipment.fin_id::text = shipmentrecords.shipment_status_id::text
        AND workflowstatesvault.fin_id::text = shipmentrecords.vault_status_id::text
        AND shipmentrouting.shipment_record_id::text = shipmentrecords.fin_id::text
        AND shipmentrouting.leg_no = 1::double precision
        AND shipmentrecords.is_deleted::text = 'N'::text) alias2
GROUP BY        alias2.fin_id,
                alias2.shipment_method,
                alias2.shipper,
                alias2.consignee,
                alias2.packing_list_no,
                alias2.shipment_type_id,
                alias2.shipment_date,
                alias2.arrival_date,
                alias2.shipment_status,
                alias2.vault_status,
                alias2.last_updated_date
ORDER BY alias2.shipment_date DESC, alias2.fin_id DESC
;




---------------------------------------------------------------------------------------------------------------------------------------------




drop VIEW IF EXISTS vbls_discrepancy_search;
create or replace view vbls_discrepancy_search(fin_id, user_id, shipment_records_id, products_id, action, repository_id, discrepancy_type,
                                    incurrence_date, discrepancy_claim, discrepancy_status, sdi, customers_id,
                                    customers_name, customers_short_name, customers_ctp_no, branches_id, branches_name,
                                    branches_short_name, settled_flag, airway_bill_no, shipmentdate, version_no) as
SELECT discinfo.fin_id,
       discinfo.user_id,
       discinfo.shipment_records_id,
       discinfo.products_id,
       discinfo.action,
	   discinfo.repository_id,
       discinfo.discrepancy_type,
       discinfo.incurrence_date,
       discinfo.discrepancy_claim,
       discinfo.discrepancy_status,
       discinfo.sdi,
       discinfo.customers_id,
       discinfo.customers_name,
       discinfo.customers_short_name,
       discinfo.customers_ctp_no,
       discinfo.branches_id,
       discinfo.branches_name,
       discinfo.branches_short_name,
       discinfo.settled_flag,
       COALESCE(discrecord2.airway_bill_no, ''::character varying) AS airway_bill_no,
       discrecord2.shipment_date                                   AS shipmentdate,
       discinfo.version_no
FROM tbls_discrepancy_records discrecord2,
     (SELECT discrecord.fin_id,
             discrecord.last_updated_by AS user_id,
             discrecord.shipment_records_id,
             discrecord.products_id,
             discrecord.action,
			 discrecord.repository_id,
             disctype.name              AS discrepancy_type,
             discrecord.incurrence_date,
             discrecord.discrepancy_claim,
             states.name                AS discrepancy_status,
             sdis.sdi_code              AS sdi,
             discrecord.customers_id,
             customers.name             AS customers_name,
             customers.short_name       AS customers_short_name,
             customers.ctp_no           AS customers_ctp_no,
             discrecord.branches_id,
             branches.name              AS branches_name,
             branches.short_name        AS branches_short_name,
             CASE
                 WHEN (sum(discreclegs.outstanding_amount) = (0)::numeric) THEN 'SETTLED'::text
                 ELSE 'UNSETTLED'::text
                 END                    AS settled_flag,
             discrecord.version_no
      FROM tbls_discrepancy_records discrecord,
           tbls_workflow_states states,
           tbls_customers customers,
           tbls_branches branches,
           tbls_discrepancy_types disctype,
           tbls_discrepancy_record_legs discreclegs,
           tbls_dates_master datesmaster,
           tbls_sdis sdis
      WHERE (((discrecord.discrepancy_type_id)::text = (disctype.fin_id)::text) AND
             ((discrecord.status_id)::text = (states.fin_id)::text) AND
             ((discrecord.customers_id)::text = (customers.fin_id)::text) AND
             ((discrecord.branches_id)::text = (branches.fin_id)::text) AND
             ((discreclegs.discrepancy_record_id)::text = (discrecord.fin_id)::text) AND
             (((discrecord.action)::text = ANY
               (ARRAY [('INSERT'::character varying)::text, ('UPDATE'::character varying)::text, ('AMEND'::character varying)::text])) OR
              (((discrecord.action)::text = 'CANCEL'::text) AND (discrecord.action_date = datesmaster.system_date))) AND
             ((discrecord.sdi_id)::text = (sdis.fin_id)::text))
      GROUP BY discrecord.fin_id, disctype.name, discrecord.incurrence_date, discrecord.discrepancy_claim, states.name,
               sdis.sdi_code, customers.name, customers.short_name, customers.ctp_no, branches.name,
               branches.short_name, discrecord.shipment_records_id, discrecord.last_updated_by, discrecord.customers_id,
               discrecord.branches_id, discrecord.products_id, discrecord.action, discrecord.version_no) discinfo
WHERE ((discrecord2.fin_id)::text = (discinfo.fin_id)::text)
ORDER BY discrecord2.fin_id DESC;


