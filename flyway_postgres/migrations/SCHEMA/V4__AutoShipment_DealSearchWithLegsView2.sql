drop view vbls_deal_search_w_legs_view;

create or replace view vbls_deal_search_w_legs_view
            (fin_id, fully_funded, vault_date, release_date, net_setl_amt, setl_currency, deals_versions_fin_id,
             deals_version_no, link_deal_no, action, action_date, external_comments, internal_comments, products_name,
             dealtype_name, products_code, ud_type_name, deal_number, buy_sell, repositories_id, entry_date, trade_date,
             value_date, products_id, customer_id, branches_id, ud_deal_types_id, status, user_id, customers_name,
             customers_short_name, customers_ctp_no, branches_name, branches_short_name, sdi_code, nv_code, ssi_type,
             pay_receive, bic_code, gl_code, account_no, ssi_code, ssi_rules_id, agent_name1, agent_name2, agent_name3,
             agent_name4, agent_swift_code, agent_account, bene_account, int_name1, int_name2, int_name3, int_name4,
             int_swift_code, int_account, additional_info1, additional_info2, additional_info3, additional_info4,
             message_template_id, setl_mode_id, ssi_fin_id, settlement_fin_id, setl_no, setl_version_no, setl_amt,
             setl_origin, setl_pay_receive, setl_date, setl_release_date, setl_deleted, deal_status,
             deal_status_validator, deal_status_level, shipment_status, vault_status, setl_status, setl_status_level,
             fo_remarks, leg_currencies, shipment_record_id, sr_shipment_status, sr_vault_status, sr_shipment_type, shipment_remarks,
             ssi_nv_type, setl_remarks)
as
WITH bkn_deal_leg_shipment AS (
    SELECT bkndeal.fin_id,
           string_agg(leg.currencies_id::text, '|'::text ORDER BY leg.bank_notes_deals_id) AS leg_currs,
           max(leg.shipment_records_id::text)                                              AS shipment_rec_id,
           max(shiprec.shipment_status_id::text)                                           AS shipment_status,
           max(shiprec.vault_status_id::text)                                              AS vault_status,
           max(shiprec.shipment_type_id::text)                                             AS shipment_type,
           max(shiprec.remarks::text)                                             AS shipment_remarks
    FROM tbls_bank_notes_deals bkndeal,
         tbls_bank_notes_deals_legs leg
             LEFT JOIN tbls_shipment_records shiprec ON leg.shipment_records_id::text = shiprec.fin_id::text
    WHERE leg.bank_notes_deals_id::text = bkndeal.fin_id::text
    GROUP BY bkndeal.fin_id
)
SELECT banknotesdeals.fin_id::text ||
       COALESCE(settlements.version_no::double precision, 0::bigint::double precision) AS fin_id,
       COALESCE(banknotesdeals.fully_funded, ' '::bpchar)                              AS fully_funded,
       banknotesdeals.vault_date,
       CASE
           WHEN products.deal_type_name::text = 'ECI Repatriation'::text THEN banknotesdeals.depo_withdraw_date
           WHEN products.deal_type_name::text = 'ECI Top-up'::text THEN banknotesdeals.depo_withdraw_date
           ELSE banknotesdeals.release_date
           END                                                                         AS release_date,
       banknotesdeals.net_setl_amt,
       banknotesdeals.setl_cur_id                                                      AS setl_currency,
       dealversions.fin_id                                                             AS deals_versions_fin_id,
       dealversions.version_no                                                         AS deals_version_no,
       dealversions.link_deal_no,
       dealversions.action,
       dealversions.action_date,
       COALESCE(dealversions.external_comments, ' '::character varying)                AS external_comments,
       COALESCE(dealversions.internal_comments, ' '::character varying)                AS internal_comments,
       products.name                                                                   AS products_name,
       products.deal_type_name                                                         AS dealtype_name,
       products.code                                                                   AS products_code,
       uddealtypes.name                                                                AS ud_type_name,
       deals.deal_no                                                                   AS deal_number,
       deals.buy_sell,
       deals.repositories_id,
       deals.entry_date,
       deals.trade_date,
       deals.value_date,
       deals.products_id,
       deals.customers_id                                                              AS customer_id,
       deals.branches_id,
       deals.ud_deal_types_id,
       deals.status,
       deals.users_id                                                                  AS user_id,
       customers.name                                                                  AS customers_name,
       customers.short_name                                                            AS customers_short_name,
       customers.ctp_no                                                                AS customers_ctp_no,
       branches.name                                                                   AS branches_name,
       branches.short_name                                                             AS branches_short_name,
       sdis.sdi_code,
       COALESCE(dealssi.nv_code, ' '::character varying)                               AS nv_code,
       COALESCE(dealssi.ssi_type, ' '::character varying)                              AS ssi_type,
       COALESCE(dealssi.pay_receive, ' '::bpchar)                                      AS pay_receive,
       COALESCE(dealssi.bic_code, ' '::character varying)                              AS bic_code,
       COALESCE(dealssi.gl_code, ' '::character varying)                               AS gl_code,
       COALESCE(dealssi.account_no, ' '::character varying)                            AS account_no,
       COALESCE(dealssi.ssi_code, ' '::character varying)                              AS ssi_code,
       COALESCE(dealssi.ssi_rules_id, ' '::character varying)                          AS ssi_rules_id,
       COALESCE(dealssi.cust_agent_name1, ' '::character varying)                      AS agent_name1,
       COALESCE(dealssi.cust_agent_name2, ' '::character varying)                      AS agent_name2,
       COALESCE(dealssi.cust_agent_name3, ' '::character varying)                      AS agent_name3,
       COALESCE(dealssi.cust_agent_name4, ' '::character varying)                      AS agent_name4,
       COALESCE(dealssi.cust_agent_swift_code, ' '::character varying)                 AS agent_swift_code,
       COALESCE(dealssi.cust_agent_account, ' '::character varying)                    AS agent_account,
       COALESCE(dealssi.beneficiary_acc_no, ' '::character varying)                    AS bene_account,
       COALESCE(dealssi.bene_name1, ' '::character varying)                            AS int_name1,
       COALESCE(dealssi.bene_name2, ' '::character varying)                            AS int_name2,
       COALESCE(dealssi.bene_name3, ' '::character varying)                            AS int_name3,
       COALESCE(dealssi.bene_name4, ' '::character varying)                            AS int_name4,
       COALESCE(dealssi.int_swift_code, ' '::character varying)                        AS int_swift_code,
       COALESCE(dealssi.int_account, ' '::character varying)                           AS int_account,
       COALESCE(dealssi.additional_info1, ' '::character varying)                      AS additional_info1,
       COALESCE(dealssi.additional_info2, ' '::character varying)                      AS additional_info2,
       COALESCE(dealssi.additional_info3, ' '::character varying)                      AS additional_info3,
       COALESCE(dealssi.bene_swift_code, ' '::character varying)                       AS additional_info4,
       COALESCE(dealssi.msg_template_id, ' '::character varying)                       AS message_template_id,
       COALESCE(dealssi.setl_mode_id, ' '::character varying)                          AS setl_mode_id,
       COALESCE(dealssi.fin_id, ' '::character varying)                                AS ssi_fin_id,
       COALESCE(settlements.fin_id, ' '::character varying)                            AS settlement_fin_id,
       COALESCE(settlements.setl_no, '0'::character varying)                           AS setl_no,
       COALESCE(settlements.version_no::double precision,
                0::bigint::double precision)                                           AS setl_version_no,
       COALESCE(settlements.setl_amount, 0::numeric)                                   AS setl_amt,
       COALESCE(settlements.setl_origin, ' '::character varying)                       AS setl_origin,
       COALESCE(settlements.pay_receive, ' '::bpchar)                                  AS setl_pay_receive,
       COALESCE(to_char(settlements.setl_date, 'DD/MM/YYYY'::text),
                ' '::text)                                                             AS setl_date,
       COALESCE(to_char(settlements.setl_release_date, 'DD/MM/YYYY'::text),
                '01/01/1970'::text)                                                    AS setl_release_date,
       CASE
           WHEN COALESCE(settlements.is_deleted, 'N'::character varying)::text = 'Y'::text AND
                COALESCE(workflowstatessetl.name, ' '::character varying)::text = 'NETTEDC'::text
               THEN 'N'::character varying
           ELSE COALESCE(settlements.is_deleted, 'N'::character varying)
           END                                                                         AS setl_deleted,
       workflowstatesdeals.name                                                        AS deal_status,
       COALESCE(dealstatus.operations_userid, ' '::character varying)                  AS deal_status_validator,
       workflowstatesdeals.workflow_level                                              AS deal_status_level,
       workflowstatesshipment.name                                                     AS shipment_status,
       workflowstatesvault.name                                                        AS vault_status,
       COALESCE(workflowstatessetl.name, ' '::character varying)                       AS setl_status,
       COALESCE(workflowstatessetl.workflow_level::double precision,
                '-1'::integer::bigint::double precision)                               AS setl_status_level,
       COALESCE(dealstatus.fo_remarks, ' '::character varying)                         AS fo_remarks,
       legshipment.leg_currs                                                           AS leg_currencies,
       legshipment.shipment_rec_id                                                     AS shipment_record_id,
       legshipment.shipment_status                                                     AS sr_shipment_status,
       legshipment.vault_status                                                        AS sr_vault_status,
       legshipment.shipment_type                                                       AS sr_shipment_type,
       legshipment.shipment_remarks                                                    AS shipment_remarks,
       COALESCE(ssinv.ssi_type, ' '::character varying)                                AS ssi_nv_type,
       COALESCE(dealstatus.bo_remarks, ' '::character varying)                         AS setl_remarks
FROM tbls_bank_notes_deals banknotesdeals
         LEFT JOIN tbls_sdis sdis ON banknotesdeals.sdi_id::text = sdis.fin_id::text
         LEFT JOIN bkn_deal_leg_shipment legshipment ON legshipment.fin_id::text = banknotesdeals.fin_id::text,
     tbls_deal_versions dealversions
         LEFT JOIN tbls_deal_ssi dealssi ON dealversions.fin_id::text = dealssi.deal_versions_id::text
         LEFT JOIN tbls_ssis_nv ssinv ON dealssi.nv_code::text = ssinv.fin_id::text
         LEFT JOIN tbls_settlements settlements ON dealversions.fin_id::text = settlements.deal_versions_id::text AND
                                                   (settlements.is_deleted::text = 'N'::text OR
                                                    settlements.status_id::text = 'PAYMENTS_CANCELLED'::text OR
                                                    settlements.status_id::text = 'PAYMENTS_NETTEDP'::text OR
                                                    settlements.status_id::text = 'PAYMENTS_NETTEDC'::text)
         LEFT JOIN tbls_workflow_states workflowstatessetl
                   ON workflowstatessetl.fin_id::text = settlements.status_id::text,
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
WHERE (deals.version_no = dealversions.version_no OR settlements.status_id::text = 'PAYMENTS_CANCELLED'::text)
  AND banknotesdeals.fin_id::text = dealversions.fin_id::text
  AND dealversions.deals_id::text = deals.fin_id::text
  AND banknotesdeals.fin_id::text = dealversions.fin_id::text
  AND dealversions.customers_id::text = customers.fin_id::text
  AND banknotesdeals.fin_id::text = dealversions.fin_id::text
  AND dealversions.branches_id::text = branches.fin_id::text
  AND banknotesdeals.fin_id::text = dealversions.fin_id::text
  AND dealversions.products_id::text = products.fin_id::text
  AND banknotesdeals.fin_id::text = dealversions.fin_id::text
  AND dealstatus.fin_id::text = deals.deal_no::text
  AND dealstatus.deal_status_id::text = workflowstatesdeals.fin_id::text
  AND uddealtypes.fin_id::text = uddtmapping.ud_deal_types_id::text
  AND uddtmapping.fin_id::text = deals.ud_deal_types_id::text
  AND workflowstatesshipment.fin_id::text = dealstatus.shipping_status_id::text
  AND workflowstatesvault.fin_id::text = dealstatus.vault_status_id::text
 ;

