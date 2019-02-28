
--
--

CREATE FUNCTION blob_to_clob(bytea) RETURNS text
    LANGUAGE sql
    AS $_$

SELECT convert_from($1, current_setting('server_encoding'))

$_$;


--
--

CREATE FUNCTION fbls_constcols(name_in text, schema_in text) RETURNS character varying
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    AS $$

DECLARE



   columnNames varchar(200);

   concatenated varchar(2000);

   counter bigint;



   c1 CURSOR FOR



     SELECT COLUMN_NAME from information_schema.columns where TABLE_NAME=lower(name_in)

     and TABLE_SCHEMA=schema_in order by COLUMN_NAME;



BEGIN

   counter:=0;

   OPEN c1;

   LOOP

   FETCH c1 INTO columnNames;



    EXIT WHEN NOT FOUND; /* apply on c1 */

      IF counter<=0 THEN

      concatenated :=  columnNames;

      ELSE

      concatenated := concatenated || ',' || columnNames;

      END IF;

      counter:=counter+1;

  END LOOP;

   CLOSE c1;

/* If Upper case is not required remove UPPER() */

RETURN UPPER(concatenated);



END;

$$;


--
--

CREATE FUNCTION fbls_isdate(p_str text, p_format text) RETURNS double precision
    LANGUAGE plpgsql
    AS $$


DECLARE


    TMPVAR TIMESTAMP(0) WITHOUT TIME ZONE;


BEGIN


    TMPVAR := TO_DATE(p_str, p_format);


    RETURN 1;


    EXCEPTION


        WHEN others THEN


            RETURN 0;


END;


$$;


--
--

CREATE FUNCTION fbls_list_element(p_string text, p_element double precision, p_separator text) RETURNS text
    LANGUAGE plpgsql
    AS $$


DECLARE


    v_string CHARACTER VARYING(32767);


BEGIN


    v_string := CONCAT_WS('', p_string, p_separator);





    FOR i IN 1..p_element - 1 LOOP


        v_string := SUBSTR(v_string, aws_oracle_ext.INSTR(v_string, p_separator) + 1);


    END LOOP;


    RETURN SUBSTR(v_string, 1, aws_oracle_ext.INSTR(v_string, p_separator) - 1);


END;


$$;


--
--

CREATE FUNCTION fbls_round(amount double precision, rnd_bkn text, prec double precision) RETURNS double precision
    LANGUAGE plpgsql
    AS $$


BEGIN


    IF rnd_bkn = 'T' THEN


        RETURN TRUNC(amount, prec);


    END IF;


    RETURN ROUND(amount, prec);


    EXCEPTION


        WHEN others THEN


            RETURN 0;


END;


$$;


--
--

CREATE FUNCTION number_to_char(double precision) RETURNS character
    LANGUAGE sql IMMUTABLE
    AS $_$ select cast($1 as character); $_$;


--
--

CREATE FUNCTION set_cseq(v_table text, v_seq text) RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
    DECLARE
        m_TABLE CHARACTER VARYING(100) DEFAULT v_table;
        m_SEQUENCE CHARACTER VARYING(100) DEFAULT v_seq;
        m_value DOUBLE PRECISION;
        m_cvalue CHARACTER VARYING(100);
        m_sqlcmd CHARACTER VARYING(100);
        m_nextval DOUBLE PRECISION;
        m_sqlcmdseq CHARACTER VARYING(100);
        m_valcompute DOUBLE PRECISION;
        m_alterseq CHARACTER VARYING(100);
        m_localval DOUBLE PRECISION;
    BEGIN
        m_sqlcmd := 'select max(fin_id) from ' || m_TABLE || '';  
        
        EXECUTE m_sqlcmd into m_cvalue;
        
        m_value := SUBSTR(m_cvalue, LENGTH(m_cvalue)-4)::NUMERIC;
        m_sqlcmdseq := 'select nextval('''||m_SEQUENCE||''')';   
        
        EXECUTE m_sqlcmdseq into m_nextval;

        IF m_value >= m_nextval THEN
            m_valcompute := m_value - m_nextval + 1;
            m_alterseq := 'alter sequence ' || m_SEQUENCE || ' increment by ';
            
            EXECUTE (m_alterseq||m_valcompute);                                     
            
            
            EXECUTE m_sqlcmdseq into m_localval;
            
            
            EXECUTE (m_alterseq ||'1');
            RAISE DEBUG USING MESSAGE := CONCAT_WS('', 'Nextval set to: ', m_localval);
        ELSE
            RAISE DEBUG USING MESSAGE := 'Sequence is correct.';
            RAISE DEBUG USING MESSAGE := CONCAT_WS('', 'Table last sequence : ', m_value);
            RAISE DEBUG USING MESSAGE := CONCAT_WS('', 'Next Sequence: ', m_nextval);
        END IF;
    END;
END;
$$;


--
--

CREATE FUNCTION set_seq(v_table text, v_seq text) RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
    DECLARE
        m_TABLE CHARACTER VARYING(100) DEFAULT v_table;
        m_SEQUENCE CHARACTER VARYING(100) DEFAULT v_seq;
        m_value DOUBLE PRECISION;
        m_sqlcmd CHARACTER VARYING(100);
        m_nextval DOUBLE PRECISION;
        m_sqlcmdseq CHARACTER VARYING(100);
        m_valcompute DOUBLE PRECISION;
        m_alterseq CHARACTER VARYING(100);
        m_localval DOUBLE PRECISION;
    BEGIN
        m_sqlcmd := 'select max(to_number(fin_id, ''999999999999999'')) from ' || m_TABLE ;  /*removed concat_ws function*/
        
        EXECUTE m_sqlcmd into m_value;
        
        m_sqlcmdseq := 'select nextval('''||m_SEQUENCE||''')';      
        
        EXECUTE m_sqlcmdseq into m_nextval;
        

        IF m_value >= m_nextval THEN
            m_valcompute := m_value - m_nextval + 1;
            m_alterseq := 'alter sequence ' || m_SEQUENCE || ' increment by ';
            
            EXECUTE (m_alterseq || m_valcompute);
            
            
            EXECUTE m_sqlcmdseq into m_localval;
            
            
            
            EXECUTE (m_alterseq || '1');                        
            
            RAISE DEBUG USING MESSAGE := CONCAT_WS('', 'Nextval set to: ', m_localval);
        ELSE
            RAISE DEBUG USING MESSAGE := 'Sequence is correct.';
            RAISE DEBUG USING MESSAGE := CONCAT_WS('', 'Table last sequence : ', m_value);
            RAISE DEBUG USING MESSAGE := CONCAT_WS('', 'Next Sequence: ', m_nextval);
        END IF;
    END;
END;
$$;


--
--

CREATE FUNCTION sp_archive_audit_trail(todate timestamp without time zone) RETURNS void
    LANGUAGE plpgsql
    AS $$


DECLARE


    minNumber DOUBLE PRECISION;


    maxNumber DOUBLE PRECISION;


    vardescription CHARACTER VARYING(100);


BEGIN


    SELECT


        MIN(fin_id::NUMERIC)


        INTO STRICT minNumber


        FROM tbls_audit_trail


        WHERE TO_DATE(TO_CHAR(last_updated, 'yyyyMMdd'), 'yyyyMMdd') <= todate;


    SELECT


        MAX(fin_id::NUMERIC)


        INTO STRICT maxNumber


        FROM tbls_audit_trail


        WHERE TO_DATE(TO_CHAR(last_updated, 'yyyyMMdd'), 'yyyyMMdd') <= todate;


    INSERT INTO tbls_audit_trail_hist (fin_id, audit_trail_id, userid, entity_name, entity_id, entity_status, oldvalue, newvalue, sequence_number, updatetimestamp, fromversion, toversion, priority, source_event, source_sub_event, description, is_deleted, created, created_by, last_updated, last_updated_by, last_checked_by, last_maked, last_updated_db, mod_id, maker_checker_status, shadow_id, parameters, audit_date, region_id)


    SELECT


        nextval('sq_bls_audit_trail_hist'), fin_id, userid, entity_name, entity_id, entity_status, oldvalue, newvalue, sequence_number, updatetimestamp, fromversion, toversion, priority, source_event, source_sub_event, description, is_deleted, created, created_by, last_updated, last_updated_by, last_checked_by, last_maked, last_updated_db, mod_id, maker_checker_status, shadow_id, parameters, audit_date, region_id


        FROM (SELECT


            fin_id, userid, entity_name, entity_id, entity_status, oldvalue, newvalue, sequence_number, updatetimestamp, fromversion, toversion, priority, source_event, source_sub_event, description, is_deleted, created, created_by, last_updated, last_updated_by, last_checked_by, last_maked, last_updated_db, mod_id, maker_checker_status, shadow_id, parameters, audit_date, region_id


            FROM tbls_audit_trail


            WHERE TO_DATE(TO_CHAR(last_updated, 'yyyyMMdd'), 'yyyyMMdd') <= todate


            ORDER BY last_updated DESC) AS var_sbq;


    INSERT INTO tbls_audit_trail_hist (fin_id, archival_to_date, audit_trail_cap_id, audit_trail_floor_id, is_deleted, shadow_id)


    VALUES (nextval('sq_bls_audit_trail_hist'), todate, maxNumber, minNumber, 'N', '-1');


    SELECT


        CONCAT_WS('', 'Audit Trail perge From Rec ', (minNumber)::TEXT, 'To Rec ', (maxNumber)::TEXT)


        INTO STRICT vardescription;


    INSERT INTO tbls_audit_trail (fin_id, description, source_event, is_deleted, shadow_id, maker_checker_status)


    VALUES (nextval('sq_bls_audit_trail'), vardescription, 'AUDIT', 'N', '-1', 'COMMITTED');


    DELETE FROM tbls_audit_trail


        WHERE TO_DATE(TO_CHAR(last_updated, 'yyyyMMdd'), 'yyyyMMdd') <= todate;


END;


$$;


--
--

CREATE FUNCTION sp_gc_dm_and_eod(input_date_string text) RETURNS void
    LANGUAGE plpgsql
    AS $$


DECLARE


    INPUT_SYSTEM_DATE TIMESTAMP(0) WITHOUT TIME ZONE;


    DAY_DIFFERENCE DOUBLE PRECISION;


BEGIN


    INPUT_SYSTEM_DATE := TO_DATE(input_date_string, 'YYYY-MM-DD');


    UPDATE tbls_dates_master


    SET system_date = INPUT_SYSTEM_DATE, accounting_date = INPUT_SYSTEM_DATE, reporting_date = INPUT_SYSTEM_DATE - (1::NUMERIC || ' days')::INTERVAL, holiday_date = INPUT_SYSTEM_DATE - (1::NUMERIC || ' days')::INTERVAL;


    UPDATE tbls_eod_progress


    SET eod_date = INPUT_SYSTEM_DATE


        WHERE fin_id IN ('10', '11', '20', '25');


    UPDATE tbls_eod_progress


    SET eod_date = INPUT_SYSTEM_DATE - (1::NUMERIC || ' days')::INTERVAL


        WHERE fin_id NOT IN ('10', '11', '20', '25');


    RAISE DEBUG USING MESSAGE := INPUT_SYSTEM_DATE;


END;


$$;


--
--

CREATE FUNCTION sp_gc_limits_util(input_date_string text) RETURNS void
    LANGUAGE plpgsql
    AS $_$


DECLARE


    INPUT_SYSTEM_DATE TIMESTAMP(0) WITHOUT TIME ZONE;


    DAY_DIFFERENCE DOUBLE PRECISION;


    a TIMESTAMP(6) WITHOUT TIME ZONE;


    b TIMESTAMP(6) WITHOUT TIME ZONE;


    d TIMESTAMP(6) WITHOUT TIME ZONE;


    limitsutilisationcursor CURSOR FOR


    SELECT


        current_date1, start_date, end_date


        FROM tbls_limits_utlsation_dates


        FOR UPDATE;


    limitsutilisationcursor$FOUND BOOLEAN DEFAULT false;


/* Updating TBLS_LIMITS_UTILISATION_DATES */


BEGIN


    OPEN limitsutilisationcursor;


    INPUT_SYSTEM_DATE := TO_DATE(input_date_string, 'YYYY-MM-DD');





    LOOP


        FETCH limitsutilisationcursor INTO a, b, d;


        limitsutilisationcursor$FOUND := FOUND;


        EXIT WHEN (NOT limitsutilisationcursor$FOUND);


        DAY_DIFFERENCE := INPUT_SYSTEM_DATE - DATE(a);


        UPDATE tbls_limits_utlsation_dates


        SET current_date1 = INPUT_SYSTEM_DATE, start_date = start_date + (DAY_DIFFERENCE::NUMERIC || ' days')::INTERVAL, end_date = end_date + (DAY_DIFFERENCE::NUMERIC || ' days')::INTERVAL


            WHERE CURRENT OF LimitsUtilisationCursor;


    END LOOP;


    CLOSE limitsutilisationcursor;


    RAISE DEBUG USING MESSAGE := INPUT_SYSTEM_DATE;


    RAISE DEBUG USING MESSAGE := DAY_DIFFERENCE;


END;


$_$;


--
--

CREATE FUNCTION sp_resset_stafffinid() RETURNS void
    LANGUAGE plpgsql
    AS $_$


DECLARE


    a CHARACTER VARYING(60);


    staffcursor CURSOR FOR


    SELECT


        fin_id


        FROM tbls_staff


        FOR UPDATE;


    staffcursor$FOUND BOOLEAN DEFAULT false;


/* Updating TBLS_LIMITS_UTILISATION_DATES */


BEGIN


    OPEN staffcursor;





    LOOP


        FETCH staffcursor INTO a;


        staffcursor$FOUND := FOUND;


        EXIT WHEN (NOT staffcursor$FOUND);


        a := CONCAT_WS('', NULL, nextval('sq_bls_staff'));


        UPDATE tbls_staff


        SET fin_id = a


            WHERE CURRENT OF staffCursor;


    END LOOP;


    CLOSE staffcursor;


END;


$_$;


--
--

CREATE FUNCTION sp_sequenceupdate(v_sequencename text) RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
    DECLARE
        m_SequenceValue DOUBLE PRECISION;
        m_SQLNextVal CHARACTER VARYING(100);
        m_AlterSQL CHARACTER VARYING(100);
    BEGIN
        m_SQLNextVal := 'select nextval("'||v_SequenceName||'")';
        
        EXECUTE m_SQLNextVal into m_SequenceValue;
        
        RAISE DEBUG USING MESSAGE := CONCAT_WS('', 'Current Sequence Value is : ', m_SequenceValue);
        RAISE DEBUG USING MESSAGE := 'Setting it to 1.';
--        m_AlterSQL := 'ALTER SEQUENCE ' || v_SequenceName || ' INCREMENT BY ' || ((-1)* m_SequenceValue) || ' minvalue 0 ';
        m_AlterSQL := 'ALTER SEQUENCE ' || v_SequenceName || ' MINVALUE 1 START 1 RESTART 1 ';
        RAISE DEBUG USING MESSAGE := m_AlterSQL;
        
        EXECUTE m_AlterSQL;
        
        EXECUTE m_SQLNextVal into m_SequenceValue;
        
        RAISE DEBUG USING MESSAGE := CONCAT_WS('', 'Current Sequence Value is : ', m_SequenceValue);
--        m_AlterSQL := 'ALTER SEQUENCE ' || v_SequenceName || ' INCREMENT BY 1 ';
--        RAISE DEBUG USING MESSAGE := m_AlterSQL;        
--        EXECUTE m_AlterSQL;
--        commit;                                      
        
    END;
END;
$$;


--
--

CREATE FUNCTION sp_yearend_bkup() RETURNS void
    LANGUAGE plpgsql
    AS $$


BEGIN


    DELETE FROM tbls_ctc_tmp;


    INSERT INTO tbls_ctc_tmp (fin_id, product_id, repository_id, reference_date, native_ctc, native_ccy_id, base_ctc, base_ccy, is_deleted, created, created_by, last_updated, last_updated_by, last_checked_by, last_maked, last_updated_db, mod_id, maker_checker_status, shadow_id, nostro, next_business_date, funding_amount_sign, entry_date, rate)


    SELECT


        fin_id, product_id, repository_id, reference_date, native_ctc, native_ccy_id, base_ctc, base_ccy, is_deleted, created, created_by, last_updated, last_updated_by, last_checked_by, last_maked, last_updated_db, mod_id, maker_checker_status, shadow_id, nostro, next_business_date, funding_amount_sign, entry_date, rate


        FROM tbls_cost_to_carry;


    DELETE FROM tbls_dly_funding_op_bl_tmp;


    INSERT INTO tbls_dly_funding_op_bl_tmp (fin_id, repository_id, product_id, currency_id, past_date, funding_amount, is_deleted, created, created_by, last_updated, last_updated_by, last_checked_by, last_maked, last_updated_db, mod_id, maker_checker_status, shadow_id, nostro)


    SELECT


        fin_id, repository_id, product_id, currency_id, past_date, funding_amount, is_deleted, created, created_by, last_updated, last_updated_by, last_checked_by, last_maked, last_updated_db, mod_id, maker_checker_status, shadow_id, nostro


        FROM tbls_daily_funding_open_bal;


    DELETE FROM tbls_dly_acc_bal_tmp;


    INSERT INTO tbls_dly_acc_bal_tmp (fin_id, repository_id, account_id, sub_ledger, account_name, currency_id, credit_debit, amount, reference_date, is_deleted, created, created_by, last_updated, last_updated_by, last_checked_by, last_maked, last_updated_db, mod_id, maker_checker_status, shadow_id, nostro, ios_code, opening_balance, corp_code, branch_code, cost_center, customer_types_id, trial_balance_date, sub_ledger_id)


    SELECT


        fin_id, repository_id, account_id, sub_ledger, account_name, currency_id, credit_debit, amount, reference_date, is_deleted, created, created_by, last_updated, last_updated_by, last_checked_by, last_maked, last_updated_db, mod_id, maker_checker_status, shadow_id, nostro, ios_code, opening_balance, corp_code, branch_code, cost_center, customer_types_id, trial_balance_date, sub_ledger_id


        FROM tbls_dly_accounting_balance;


END;


$$;


--
--

CREATE FUNCTION sp_yearend_restore(input_date_string text) RETURNS void
    LANGUAGE plpgsql
    AS $$


BEGIN


    DELETE FROM tbls_cost_to_carry;


    INSERT INTO tbls_cost_to_carry (fin_id, product_id, repository_id, reference_date, native_ctc, native_ccy_id, base_ctc, base_ccy, is_deleted, created, created_by, last_updated, last_updated_by, last_checked_by, last_maked, last_updated_db, mod_id, maker_checker_status, shadow_id, nostro, next_business_date, funding_amount_sign, entry_date, rate)


    SELECT


        fin_id, product_id, repository_id, reference_date, native_ctc, native_ccy_id, base_ctc, base_ccy, is_deleted, created, created_by, last_updated, last_updated_by, last_checked_by, last_maked, last_updated_db, mod_id, maker_checker_status, shadow_id, nostro, next_business_date, funding_amount_sign, entry_date, rate


        FROM tbls_ctc_tmp;


    DELETE FROM tbls_daily_funding_open_bal;


    INSERT INTO tbls_daily_funding_open_bal (fin_id, repository_id, product_id, currency_id, past_date, funding_amount, is_deleted, created, created_by, last_updated, last_updated_by, last_checked_by, last_maked, last_updated_db, mod_id, maker_checker_status, shadow_id, nostro)


    SELECT


        fin_id, repository_id, product_id, currency_id, past_date, funding_amount, is_deleted, created, created_by, last_updated, last_updated_by, last_checked_by, last_maked, last_updated_db, mod_id, maker_checker_status, shadow_id, nostro


        FROM tbls_dly_funding_op_bl_tmp;


    DELETE FROM tbls_dly_accounting_balance;


    INSERT INTO tbls_dly_accounting_balance (fin_id, repository_id, account_id, sub_ledger, account_name, currency_id, credit_debit, amount, reference_date, is_deleted, created, created_by, last_updated, last_updated_by, last_checked_by, last_maked, last_updated_db, mod_id, maker_checker_status, shadow_id, nostro, ios_code, opening_balance, corp_code, branch_code, cost_center, customer_types_id, trial_balance_date, sub_ledger_id)


    SELECT


        fin_id, repository_id, account_id, sub_ledger, account_name, currency_id, credit_debit, amount, reference_date, is_deleted, created, created_by, last_updated, last_updated_by, last_checked_by, last_maked, last_updated_db, mod_id, maker_checker_status, shadow_id, nostro, ios_code, opening_balance, corp_code, branch_code, cost_center, customer_types_id, trial_balance_date, sub_ledger_id


        FROM tbls_dly_acc_bal_tmp;


    DELETE FROM tbls_acc_entries_table


        WHERE TO_CHAR(entry_date, 'yyyyMMdd') = input_date_string;


END;


$$;


--
--

CREATE FUNCTION timestamp_to_char(timestamp without time zone) RETURNS text
    LANGUAGE sql IMMUTABLE
    AS $_$ select to_char($1, 'YYYYMMDD'); $_$;


--
--

CREATE SEQUENCE "iseq$$_94065"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
--

CREATE SEQUENCE s
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
--

CREATE SEQUENCE sq_bls__bnc
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
--

CREATE SEQUENCE sq_bls_acc_entries
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
--

CREATE SEQUENCE sq_bls_acc_rules
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
--

CREATE SEQUENCE sq_bls_amlalercommenthis
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
--

CREATE SEQUENCE sq_bls_amlbreachalert
    START WITH 1
    INCREMENT BY 1
    MINVALUE 0
    NO MAXVALUE
    CACHE 1;


--
--

CREATE SEQUENCE sq_bls_audit_trail
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
--

CREATE SEQUENCE sq_bls_audit_trail_hist
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
--

CREATE SEQUENCE sq_bls_bank_notes_orders
    START WITH 1
    INCREMENT BY 1
    MINVALUE 0
    NO MAXVALUE
    CACHE 1;


--
--

CREATE SEQUENCE sq_bls_calendar_hols
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
--

CREATE SEQUENCE sq_bls_comms_config
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
--

CREATE SEQUENCE sq_bls_cr_limit_reporting
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
--

CREATE SEQUENCE sq_bls_deal_status_trail
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
--

CREATE SEQUENCE sq_bls_deal_upload_info
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
--

CREATE SEQUENCE sq_bls_deals
    START WITH 1
    INCREMENT BY 1
    MINVALUE 0
    NO MAXVALUE
    CACHE 1;


--
--

CREATE SEQUENCE sq_bls_discrepancy_records
    START WITH 1
    INCREMENT BY 1
    MINVALUE 0
    NO MAXVALUE
    CACHE 1;


--
--

CREATE SEQUENCE sq_bls_dly_acc_bal
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
--

CREATE SEQUENCE sq_bls_ermctc_report
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
--

CREATE SEQUENCE sq_bls_external_deal
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
--

CREATE SEQUENCE sq_bls_fxnopvolhist_finid
    START WITH 1
    INCREMENT BY 1
    MINVALUE 0
    NO MAXVALUE
    CACHE 1;


--
--

CREATE SEQUENCE sq_bls_gl_recon_input
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
--

CREATE SEQUENCE sq_bls_global_bnc
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
--

CREATE SEQUENCE sq_bls_hist_vol_aml
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
--

CREATE SEQUENCE sq_bls_hist_vol_aml_int
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
--

CREATE SEQUENCE sq_bls_intf_addr_recon_log
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
--

CREATE SEQUENCE sq_bls_intf_cust_demo_log
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
--

CREATE SEQUENCE sq_bls_irr_config
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
--

CREATE SEQUENCE sq_bls_it2_recon_input
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
--

CREATE SEQUENCE sq_bls_limits_breach
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
--

CREATE SEQUENCE sq_bls_limits_breach_data
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
--

CREATE SEQUENCE sq_bls_limits_breach_ear
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
--

CREATE SEQUENCE sq_bls_limits_exclusion
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
--

CREATE SEQUENCE sq_bls_limits_override
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
--

CREATE SEQUENCE sq_bls_maker_checker
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
--

CREATE SEQUENCE sq_bls_manual_postings
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
--

CREATE SEQUENCE sq_bls_margins
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
--

CREATE SEQUENCE sq_bls_packing_list
    START WITH 1
    INCREMENT BY 1
    MINVALUE 0
    NO MAXVALUE
    CACHE 1;


--
--

CREATE SEQUENCE sq_bls_processing_inbox
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
--

CREATE SEQUENCE sq_bls_shipment_finid
    START WITH 1
    INCREMENT BY 1
    MINVALUE 0
    NO MAXVALUE
    CACHE 1;


--
--

CREATE SEQUENCE sq_bls_staff
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
--

CREATE SEQUENCE sq_bls_turnover_pl
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
--

CREATE SEQUENCE sq_bls_wsspositions
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


SET default_tablespace = '';

SET default_with_oids = false;

--
--

CREATE TABLE tbls_acc_allocno (
    fin_id character varying(30) NOT NULL,
    deal_no character varying(30) NOT NULL,
    allocation_no character varying(15) NOT NULL,
    is_deleted character varying(1) DEFAULT 'N'::character varying NOT NULL,
    created timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    created_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_updated timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_checked_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_maked timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_db timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    mod_id double precision DEFAULT 0 NOT NULL,
    maker_checker_status character varying(10) DEFAULT 'Maked'::character varying NOT NULL,
    shadow_id character varying(60) DEFAULT ''::character varying NOT NULL
);


--
--

CREATE TABLE tbls_acc_ent_his (
    fin_id character varying(60) NOT NULL,
    corp_code character varying(10),
    branch_code character varying(10),
    major_no character varying(10),
    minor_no character varying(10),
    check_digit character varying(10),
    in_out_country_code character varying(10),
    cost_center character varying(10),
    currencies_id character varying(10),
    amount numeric(21,2),
    debit_credit character varying(10),
    trans_ref character varying(60),
    description character varying(100),
    customer_types_id character varying(60),
    acc_rules_id character varying(60),
    main_ledger_id character varying(60),
    r_account_allocation_no character varying(20),
    deal_no character varying(60),
    version_no double precision,
    region_id character varying(60),
    repositories_id character varying(60),
    is_deleted character varying(1) DEFAULT 'N'::character varying NOT NULL,
    created timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    created_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_updated timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_checked_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_maked timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_db timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    mod_id double precision DEFAULT 0 NOT NULL,
    maker_checker_status character varying(10) DEFAULT 'Maked'::character varying NOT NULL,
    shadow_id character varying(60) DEFAULT ''::character varying NOT NULL,
    is_reversal character varying(2) DEFAULT 'N'::character varying NOT NULL,
    entry_date timestamp(0) without time zone,
    event_date character varying(60),
    posting_flag character varying(1),
    allocation_no character varying(100),
    customers_id character varying(60),
    deal_type character varying(60),
    deal_sub_type character varying(60),
    ud_deal_types_id character varying(60),
    buy_sell character varying(10),
    journal_desc character varying(50),
    ctc_mtm_sign character varying(25),
    charge_commission character varying(50),
    income_expense character varying(10),
    comm_setl_type character varying(50),
    disc_setl_type character varying(50),
    nv_code character varying(60),
    leg_no character varying(25),
    sub_ledger_id character varying(162),
    gl_account_no character varying(9)
);


--
--

CREATE TABLE tbls_acc_entries_table (
    fin_id character varying(60) NOT NULL,
    corp_code character varying(10),
    branch_code character varying(10),
    major_no character varying(10),
    minor_no character varying(10),
    check_digit character varying(10),
    in_out_country_code character varying(10),
    cost_center character varying(10),
    currencies_id character varying(10),
    amount numeric(21,2),
    debit_credit character varying(10),
    trans_ref character varying(60),
    description character varying(100),
    customer_types_id character varying(60),
    acc_rules_id character varying(60),
    main_ledger_id character varying(60),
    r_account_allocation_no character varying(20),
    deal_no character varying(60),
    version_no double precision,
    region_id character varying(60),
    repositories_id character varying(60),
    is_deleted character varying(1) DEFAULT 'N'::character varying NOT NULL,
    created timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    created_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_updated timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_checked_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_maked timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_db timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    mod_id double precision DEFAULT 0 NOT NULL,
    maker_checker_status character varying(10) DEFAULT 'Maked'::character varying NOT NULL,
    shadow_id character varying(60) DEFAULT ''::character varying NOT NULL,
    is_reversal character varying(2) DEFAULT 'N'::character varying NOT NULL,
    entry_date timestamp(0) without time zone,
    event_date character varying(60),
    posting_flag character varying(1),
    allocation_no character varying(100),
    customers_id character varying(60),
    deal_type character varying(60),
    deal_sub_type character varying(60),
    ud_deal_types_id character varying(60),
    buy_sell character varying(10),
    journal_desc character varying(50),
    ctc_mtm_sign character varying(30),
    charge_commission character varying(50),
    income_expense character varying(10),
    comm_setl_type character varying(50),
    disc_setl_type character varying(50),
    nv_code character varying(60),
    leg_no character varying(25),
    sub_ledger_id character varying(162),
    gl_account_no character varying(9),
    branch_id character varying(60),
    leg_ccy_vs_lcu_spotrate numeric(21,11) DEFAULT 0.0,
    lcu_eqv_amount numeric(21,4) DEFAULT 0
);


--
--

CREATE TABLE tbls_acc_main_ledger (
    fin_id character varying(60) NOT NULL,
    main_ledger character varying(60) NOT NULL,
    main_ledger_long_name character varying(100) NOT NULL,
    ssi_yes_no character(1) NOT NULL,
    acc_type character varying(10) NOT NULL,
    cust_res_check character varying(60) NOT NULL,
    regions_id character varying(60),
    is_deleted character varying(1) DEFAULT 'N'::character varying NOT NULL,
    created timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    created_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_updated timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_checked_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_maked timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_db timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    mod_id double precision DEFAULT 0 NOT NULL,
    maker_checker_status character varying(10) DEFAULT 'Maked'::character varying NOT NULL,
    shadow_id character varying(60) DEFAULT ''::character varying NOT NULL,
    memo_nonmemo character varying(25),
    suspense_type character varying(25)
);


--
--

CREATE TABLE tbls_acc_rules (
    fin_id character varying(60) NOT NULL,
    rule_no double precision NOT NULL,
    rule_type character varying(60) NOT NULL,
    products_code character varying(60) NOT NULL,
    deal_type_code character varying(60) NOT NULL,
    deal_sub_type character varying(60) NOT NULL,
    buy_sell character varying(60),
    event_date character varying(60),
    charges_commission character varying(60),
    charges_comm_inc_exp character varying(60),
    comm_setl_type character varying(60),
    mtm_rev_yes_no character varying(60) NOT NULL,
    debit_account_id character varying(60),
    debit_currency_id character varying(60),
    debit_amount character varying(60),
    credit_account_id character varying(60),
    credit_currency_id character varying(60),
    credit_amount character varying(60),
    ud_deal_types_id character varying(60),
    disc_setl_type character varying(60),
    ctc_mtm_sign character varying(60),
    repositories_id character varying(60),
    regions_id character varying(60) NOT NULL,
    is_deleted character varying(1) DEFAULT 'N'::character varying NOT NULL,
    created timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    created_by character varying(60) DEFAULT 'System'::character varying NOT NULL,
    last_updated timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_checked_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_maked timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_db timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    mod_id double precision DEFAULT 0 NOT NULL,
    maker_checker_status character varying(10) DEFAULT 'Maked'::character varying NOT NULL,
    shadow_id character varying(60) DEFAULT ''::character varying NOT NULL
);


--
--

CREATE TABLE tbls_acc_sub_ledger (
    fin_id character varying(162) NOT NULL,
    main_ledger_id character varying(60) NOT NULL,
    customer_types_id character varying(60) NOT NULL,
    gl_subledger_shortname character varying(40) NOT NULL,
    gl_subledger_longname character varying(100) NOT NULL,
    sap_gl_ac_no character varying(40),
    gl_r_ac character(1) NOT NULL,
    glbranch_code character varying(60) NOT NULL,
    gl425_yes_no character(1) NOT NULL,
    gl_status character varying(10) NOT NULL,
    ud_deal_types_id character varying(60) NOT NULL,
    regions_id character varying(60),
    is_deleted character varying(1) DEFAULT 'N'::character varying NOT NULL,
    created timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    created_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_updated timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_checked_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_maked timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_db timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    mod_id double precision DEFAULT 0 NOT NULL,
    maker_checker_status character varying(10) DEFAULT 'Maked'::character varying NOT NULL,
    shadow_id character varying(162) DEFAULT ''::character varying NOT NULL,
    gl_corp_code character varying(60)
);


--
--

CREATE TABLE tbls_airports (
    fin_id character varying(182) NOT NULL,
    code character varying(30),
    name character varying(50),
    cities_id character varying(151),
    countries_id character varying(120),
    regions_id character varying(60),
    is_deleted character varying(1) DEFAULT 'N'::character varying NOT NULL,
    created timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    created_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_updated timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_checked_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_maked timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_db timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    mod_id double precision DEFAULT 0 NOT NULL,
    maker_checker_status character varying(10) DEFAULT 'Maked'::character varying NOT NULL,
    shadow_id character varying(182) DEFAULT ''::character varying NOT NULL,
    invoice_special_clause character varying(200)
);


--
--

CREATE TABLE tbls_allocated_limits (
    fin_id character varying(224) NOT NULL,
    regions_id character varying(60),
    cels_code character varying(20),
    products_code character varying(60),
    type character varying(20),
    tenor_buckets_id character varying(60),
    currencies_id character varying(60),
    allocated_amount numeric(21,2),
    reallocated_amount numeric(21,2),
    update_method character varying(6),
    allocated_start_date timestamp(6) without time zone DEFAULT clock_timestamp(),
    reallocated_start_date timestamp(6) without time zone DEFAULT clock_timestamp(),
    allocated_expiry_date timestamp(6) without time zone DEFAULT clock_timestamp(),
    reallocated_expiry_date timestamp(6) without time zone DEFAULT clock_timestamp(),
    remarks character varying(100),
    is_deleted character varying(1) DEFAULT 'N'::character varying NOT NULL,
    created timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    created_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_updated timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_checked_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_maked timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_db timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    mod_id double precision DEFAULT 0 NOT NULL,
    maker_checker_status character varying(10) DEFAULT 'Maked'::character varying NOT NULL,
    shadow_id character varying(224) DEFAULT ''::character varying NOT NULL,
    prev_allocated_amount numeric(21,2)
);


--
--

CREATE TABLE tbls_aml_alerts_comment_his (
    fin_id character varying(60) NOT NULL,
    alert_id character varying(60),
    status_from character varying(35),
    status_to character varying(35),
    maker_id character varying(30),
    comment_str character varying(100),
    checker_id character varying(30),
    content bytea,
    is_deleted character varying(1) NOT NULL,
    created timestamp without time zone NOT NULL,
    created_by character varying(30) NOT NULL,
    last_updated timestamp without time zone NOT NULL,
    last_updated_by character varying(30) NOT NULL,
    last_checked_by character varying(30) NOT NULL,
    last_maked timestamp without time zone NOT NULL,
    last_updated_db timestamp without time zone NOT NULL,
    mod_id numeric(38,10) NOT NULL,
    maker_checker_status character varying(10) NOT NULL,
    shadow_id character varying(60) NOT NULL
);


--
--

CREATE TABLE tbls_aml_breach_alerts (
    fin_id character varying(60) NOT NULL,
    alert_id character varying(60),
    alert_type character varying(1),
    transaction_date timestamp(6) without time zone,
    customer_id character varying(20),
    country character varying(20),
    bwcif_no character varying(20),
    risk_ranking character varying(30),
    buy_sell character varying(8),
    usd_threshold numeric(21,2) DEFAULT 0,
    volume numeric(21,2) DEFAULT 0,
    current_status character varying(60),
    is_deleted character varying(1) DEFAULT 'N'::character varying NOT NULL,
    last_maker_time timestamp(6) without time zone,
    last_checker_time timestamp(6) without time zone,
    created timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    created_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_updated timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_checked_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_maked timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_db timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    mod_id double precision DEFAULT 0 NOT NULL,
    maker_checker_status character varying(10) DEFAULT 'Maked'::character varying NOT NULL,
    shadow_id character varying(60) DEFAULT ''::character varying NOT NULL,
    last_maker character varying(30),
    last_checker character varying(30),
    currvssameqtrprevyrvar double precision,
    same_qtr_prev_yr_volume double precision,
    prev_qtr_volume double precision,
    curr_qtr_volume double precision,
    curr_vs_prev_qtr_volume double precision,
    curr_vs_same_qtr_prev_yr_vol double precision,
    curr_vs_prev_qtr_variance double precision,
    curr_vs_same_qtr_prev_yr_var double precision,
    volume_pm1 numeric(21,2) DEFAULT 0,
    volume_pm2 numeric(21,2) DEFAULT 0,
    volume_pm3 numeric(21,2) DEFAULT 0,
    volume_pm3_total numeric(21,2) DEFAULT 0,
    volume_pm3_avg numeric(21,2) DEFAULT 0,
    volume_pm3_dif numeric(21,2) DEFAULT 0,
    volume_pm3_var numeric(21,2) DEFAULT 0
);


--
--

CREATE TABLE tbls_assets (
    fin_id character varying(60) NOT NULL,
    name character varying(60) NOT NULL,
    repository character varying(60),
    region_id character varying(60) NOT NULL,
    is_deleted character varying(1) DEFAULT 'N'::character varying NOT NULL,
    created timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    created_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_updated timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_checked_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_maked timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_db timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    mod_id double precision DEFAULT 0 NOT NULL,
    maker_checker_status character varying(10) DEFAULT 'Maked'::character varying NOT NULL,
    shadow_id character varying(60) DEFAULT ''::character varying NOT NULL
);


--
--

CREATE TABLE tbls_audit_deal_numbers (
    fin_id character varying(60) NOT NULL,
    users_id character varying(60) NOT NULL,
    deal_no character varying(60) NOT NULL,
    system_date timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    type character varying(100) NOT NULL,
    status character varying(60) NOT NULL,
    module character varying(60) NOT NULL,
    source character varying(60) NOT NULL,
    comments character varying(400),
    is_deleted character varying(1) DEFAULT 'N'::character varying NOT NULL,
    created timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    created_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_updated timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_checked_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_maked timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_db timestamp(6) without time zone DEFAULT clock_timestamp(),
    mod_id double precision DEFAULT 0 NOT NULL,
    maker_checker_status character varying(10) DEFAULT 'Maked'::character varying NOT NULL,
    shadow_id character varying(60) DEFAULT ''::character varying NOT NULL
);


--
--

CREATE TABLE tbls_audit_dl_no_his (
    fin_id character varying(60) NOT NULL,
    users_id character varying(60) NOT NULL,
    deal_no character varying(60) NOT NULL,
    system_date timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    type character varying(100) NOT NULL,
    status character varying(60) NOT NULL,
    module character varying(60) NOT NULL,
    source character varying(60) NOT NULL,
    comments character varying(400),
    is_deleted character varying(1) DEFAULT 'N'::character varying NOT NULL,
    created timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    created_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_updated timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_checked_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_maked timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_db timestamp(6) without time zone DEFAULT clock_timestamp(),
    mod_id double precision DEFAULT 0 NOT NULL,
    maker_checker_status character varying(10) DEFAULT 'Maked'::character varying NOT NULL,
    shadow_id character varying(60) DEFAULT ''::character varying NOT NULL
);


--
--

CREATE TABLE tbls_audit_trail (
    fin_id character varying(161) NOT NULL,
    userid character varying(60),
    entity_name character varying(60),
    entity_id character varying(450),
    entity_status character varying(10),
    oldvalue character varying(1800),
    newvalue character varying(1800),
    sequence_number double precision,
    updatetimestamp timestamp(6) without time zone,
    fromversion double precision,
    toversion double precision,
    priority double precision,
    source_event character varying(30),
    source_sub_event character varying(30),
    description character varying(150),
    is_deleted character varying(1) DEFAULT 'N'::character varying NOT NULL,
    created timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    created_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_updated timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_checked_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_maked timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_db timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    mod_id double precision DEFAULT 0 NOT NULL,
    maker_checker_status character varying(10) DEFAULT 'Maked'::character varying NOT NULL,
    shadow_id character varying(161) DEFAULT ''::character varying NOT NULL,
    parameters character varying(1800),
    audit_date timestamp(0) without time zone,
    region_id character varying(60)
);


--
--

CREATE TABLE tbls_audit_trail_hist (
    fin_id character varying(161) NOT NULL,
    audit_trail_id character varying(161),
    userid character varying(60),
    entity_name character varying(60),
    entity_id character varying(450),
    entity_status character varying(10),
    oldvalue character varying(1800),
    newvalue character varying(1800),
    sequence_number double precision,
    updatetimestamp timestamp(6) without time zone,
    fromversion double precision,
    toversion double precision,
    priority double precision,
    source_event character varying(30),
    source_sub_event character varying(30),
    description character varying(150),
    archival_to_date timestamp(0) without time zone,
    audit_trail_cap_id character varying(161),
    audit_trail_floor_id character varying(161),
    is_deleted character varying(1) DEFAULT 'N'::character varying NOT NULL,
    created timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    created_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_updated timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_checked_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_maked timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_db timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    mod_id double precision DEFAULT 0 NOT NULL,
    maker_checker_status character varying(10) DEFAULT 'Maked'::character varying NOT NULL,
    shadow_id character varying(60) DEFAULT ''::character varying NOT NULL,
    parameters character varying(1800),
    audit_date timestamp(0) without time zone,
    region_id character varying(60)
);


--
--

CREATE TABLE tbls_bank_notes_deals (
    fin_id character varying(99) NOT NULL,
    deal_versions_id character varying(99),
    release_date timestamp(6) without time zone DEFAULT clock_timestamp(),
    vault_date timestamp(6) without time zone DEFAULT clock_timestamp(),
    release2_date timestamp(6) without time zone DEFAULT clock_timestamp(),
    vault2_date timestamp(6) without time zone DEFAULT clock_timestamp(),
    setl_cur_id character varying(60),
    net_setl_amt numeric(21,2),
    fully_funded character(1),
    vault1_id character varying(60),
    vault2_id character varying(60),
    usd_rate_vs_setl_cur numeric(21,11),
    usd_rate_vs_base_cur numeric(21,11),
    pl_amount numeric(21,2),
    margin_amount numeric(21,2),
    charge_amount numeric(21,2),
    commission_amount numeric(21,2),
    commission_cur_id character varying(60),
    commission_setl_date timestamp(6) without time zone,
    commission_rec_status character varying(20),
    commission_shipment_record_id character varying(60),
    commission_setl_type character varying(20),
    shipping_charge_cur_id character varying(25),
    shipping_charge_date timestamp(6) without time zone,
    shipping_charge_amount numeric(21,2),
    commission_rev_date timestamp(6) without time zone,
    is_deleted character varying(1) DEFAULT 'N'::character varying NOT NULL,
    created timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    created_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_updated timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_checked_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_maked timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_db timestamp(6) without time zone DEFAULT clock_timestamp(),
    mod_id double precision DEFAULT 0 NOT NULL,
    maker_checker_status character varying(10) DEFAULT 'Maked'::character varying NOT NULL,
    shadow_id character varying(99) DEFAULT ''::character varying NOT NULL,
    sdi_swap_id character varying(173),
    sdi_id character varying(173),
    order_via character varying(60),
    depo_withdraw_date timestamp(6) without time zone,
    sender_corr_acct character varying(30),
    receiver_corr_acct character varying(30),
    sender_corr_swift_code character varying(11),
    receiver_corr_swift_code character varying(11),
    gmp_consol_date timestamp(0) without time zone,
    commission_usd_amount numeric(21,2) DEFAULT 0,
    commission_base_amount numeric(21,2) DEFAULT 0,
    setl_ccy_vs_lcu_spotrate numeric(21,11) DEFAULT 0.0,
    total_turnover_in_lcu numeric(21,2) DEFAULT 0.0,
    total_pl_in_lcu numeric(21,2) DEFAULT 0.0
);


--
--

CREATE TABLE tbls_bank_notes_deals_legs (
    fin_id character varying(149) NOT NULL,
    bank_notes_deals_id character varying(99),
    leg_number double precision,
    amount numeric(21,2),
    currencies_id character varying(60),
    bank_notes_denoms_id character varying(213),
    bank_notes_types_id character varying(60),
    spotfactor numeric(10,0),
    deal_rate numeric(21,11),
    market_rate numeric(21,11),
    md character(1),
    setl_amount numeric(21,2),
    pl_amount numeric(21,2),
    margin numeric(21,11),
    buy_sell character varying(10),
    shipment_records_id character varying(60),
    attach_to_confo character(1),
    is_deleted character varying(1) DEFAULT 'N'::character varying NOT NULL,
    created timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    created_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_updated timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_checked_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_maked timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_db timestamp(6) without time zone DEFAULT clock_timestamp(),
    mod_id double precision DEFAULT 0 NOT NULL,
    maker_checker_status character varying(10) DEFAULT 'Maked'::character varying NOT NULL,
    shadow_id character varying(149) DEFAULT ''::character varying NOT NULL,
    shipping_status_id character varying(61),
    vault_status_id character varying(61),
    delivery_status character varying(61),
    delivery_time character varying(25),
    delivery_remarks character varying(25),
    vault_inventory_updated character varying(1),
    insurance_value_required character varying(1),
    shipment_value_required character varying(1),
    suggested_margin double precision DEFAULT 0,
    rates_tolerance double precision DEFAULT 0,
    leg_ccy_vs_base_dealrate numeric(21,11) DEFAULT 0,
    leg_ccy_vs_usd_dealrate numeric(21,11) DEFAULT 0,
    leg_ccy_vs_usd_parentrate numeric(21,11) DEFAULT 0 NOT NULL,
    usd_amt_open_rate numeric(21,4) DEFAULT 0,
    base_amt_open_rate numeric(21,4) DEFAULT 0,
    leg_ccy_vs_lcu_spotrate numeric(21,11) DEFAULT 0.0,
    leg_ccy_vs_lcu_dealrate numeric(21,11) DEFAULT 0.0,
    lcu_setl_eqv_amount numeric(21,4) DEFAULT 0.0,
    lcu_eqv_amount numeric(21,4) DEFAULT 0
);


--
--

CREATE TABLE tbls_bank_notes_denoms (
    fin_id character varying(213) NOT NULL,
    products_code character varying(60),
    currencies_id character varying(60),
    multiplier character varying(60),
    name character varying(30) NOT NULL,
    is_deleted character varying(1) DEFAULT 'N'::character varying NOT NULL,
    created timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    created_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_updated timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_checked_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_maked timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_db timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    mod_id double precision DEFAULT 0 NOT NULL,
    maker_checker_status character varying(10) DEFAULT 'Maked'::character varying NOT NULL,
    shadow_id character varying(213) DEFAULT ''::character varying NOT NULL,
    code character varying(30) DEFAULT ''::character varying,
    sort_order double precision DEFAULT 1
);


--
--

CREATE TABLE tbls_bank_notes_orders (
    fin_id character varying(60) NOT NULL,
    products_id character varying(60) NOT NULL,
    order_no character varying(60),
    order_status character varying(61),
    entry_date timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    trade_date timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    customers_id character varying(60),
    branches_id character varying(91),
    users_id character varying(60) NOT NULL,
    buy_sell character varying(10),
    regions_id character varying(60) NOT NULL,
    sdi_id character varying(173),
    release_date timestamp(6) without time zone DEFAULT clock_timestamp(),
    vault_date timestamp(6) without time zone DEFAULT clock_timestamp(),
    value_date timestamp(6) without time zone DEFAULT clock_timestamp(),
    setl_cur_id character varying(60),
    vault1_id character varying(60),
    vault2_id character varying(60),
    internal_comments character varying(500),
    external_comments character varying(500),
    is_deleted character varying(1) DEFAULT 'N'::character varying NOT NULL,
    created timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    created_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_updated timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_checked_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_maked timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_db timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    mod_id double precision DEFAULT 0 NOT NULL,
    maker_checker_status character varying(10) DEFAULT 'Maked'::character varying NOT NULL,
    shadow_id character varying(60) DEFAULT ''::character varying NOT NULL,
    deal_no character varying(60),
    action character varying(10),
    action_date timestamp(6) without time zone,
    input_mode character varying(10),
    vault2_date timestamp(6) without time zone DEFAULT clock_timestamp(),
    reason_custom character varying(500),
    deal_change_reason_codes_id character varying(60),
    version_no double precision
);


--
--

CREATE TABLE tbls_bank_notes_orders_legs (
    fin_id character varying(99) NOT NULL,
    bank_notes_orders_id character varying(60),
    leg_number double precision,
    currency_id character varying(60),
    denomination_id character varying(213),
    bank_notes_type_id character varying(60),
    amount numeric(21,2),
    deal_no character varying(60),
    deals_leg_number double precision,
    shipment_record_id character varying(60),
    attach_to_confo character(1),
    shipping_status character varying(61),
    vault_status character varying(61),
    is_deleted character varying(1) DEFAULT 'N'::character varying NOT NULL,
    created timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    created_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_updated timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_checked_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_maked timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_db timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    mod_id double precision DEFAULT 0 NOT NULL,
    maker_checker_status character varying(10) DEFAULT 'Maked'::character varying NOT NULL,
    shadow_id character varying(99) DEFAULT ''::character varying NOT NULL
);


--
--

CREATE TABLE tbls_bank_notes_types (
    fin_id character varying(60) NOT NULL,
    code character varying(30) NOT NULL,
    name character varying(50) NOT NULL,
    is_deleted character varying(1) DEFAULT 'N'::character varying NOT NULL,
    created timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    created_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_updated timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_checked_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_maked timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_db timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    mod_id double precision DEFAULT 0 NOT NULL,
    maker_checker_status character varying(10) DEFAULT 'Maked'::character varying NOT NULL,
    shadow_id character varying(60) DEFAULT ''::character varying NOT NULL,
    is_rate_tol_appl character varying(5) DEFAULT 'Y'::character varying NOT NULL,
    sort_order double precision DEFAULT 1
);


--
--

CREATE TABLE tbls_bls_closing_spot_rates (
    fin_id character varying(225) NOT NULL,
    mkt_date timestamp(6) without time zone DEFAULT clock_timestamp(),
    system_codes_id character varying(60),
    rate_type character varying(20),
    currencypairs_id character varying(60),
    forward_date timestamp(6) without time zone DEFAULT clock_timestamp(),
    closing_rate numeric(21,11),
    data_set_name character varying(60),
    is_deleted character varying(1),
    created timestamp(6) without time zone DEFAULT clock_timestamp(),
    created_by character varying(30),
    last_updated timestamp(6) without time zone DEFAULT clock_timestamp(),
    last_updated_by character varying(30),
    last_checked_by character varying(30),
    last_maked timestamp(6) without time zone DEFAULT clock_timestamp(),
    last_updated_db timestamp(6) without time zone DEFAULT clock_timestamp(),
    mod_id double precision,
    maker_checker_status character varying(10),
    shadow_id character varying(225) DEFAULT 0,
    currency1 character varying(60),
    currency2 character varying(60)
);


--
--

CREATE TABLE tbls_bnk_deals_his (
    fin_id character varying(99) NOT NULL,
    deal_versions_id character varying(99),
    release_date timestamp(6) without time zone DEFAULT clock_timestamp(),
    vault_date timestamp(6) without time zone DEFAULT clock_timestamp(),
    release2_date timestamp(6) without time zone DEFAULT clock_timestamp(),
    vault2_date timestamp(6) without time zone DEFAULT clock_timestamp(),
    setl_cur_id character varying(60),
    net_setl_amt numeric(21,2),
    fully_funded character(1),
    vault1_id character varying(60),
    vault2_id character varying(60),
    usd_rate_vs_setl_cur numeric(21,11),
    usd_rate_vs_base_cur numeric(21,11),
    pl_amount numeric(21,2),
    margin_amount numeric(21,2),
    charge_amount numeric(21,2),
    commission_amount numeric(21,2),
    commission_cur_id character varying(60),
    commission_setl_date timestamp(6) without time zone,
    commission_rec_status character varying(20),
    commission_shipment_record_id character varying(60),
    commission_setl_type character varying(20),
    shipping_charge_cur_id character varying(25),
    shipping_charge_date timestamp(6) without time zone,
    shipping_charge_amount numeric(21,2),
    commission_rev_date timestamp(6) without time zone,
    is_deleted character varying(1) DEFAULT 'N'::character varying NOT NULL,
    created timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    created_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_updated timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_checked_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_maked timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_db timestamp(6) without time zone DEFAULT clock_timestamp(),
    mod_id double precision DEFAULT 0 NOT NULL,
    maker_checker_status character varying(10) DEFAULT 'Maked'::character varying NOT NULL,
    shadow_id character varying(99) DEFAULT ''::character varying NOT NULL,
    sdi_swap_id character varying(173),
    sdi_id character varying(173),
    order_via character varying(60),
    depo_withdraw_date timestamp(6) without time zone
);


--
--

CREATE TABLE tbls_bnk_deals_legs_his (
    fin_id character varying(149) NOT NULL,
    bank_notes_deals_id character varying(99),
    leg_number double precision,
    amount numeric(21,2),
    currencies_id character varying(60),
    bank_notes_denoms_id character varying(213),
    bank_notes_types_id character varying(60),
    spotfactor numeric(10,0),
    deal_rate numeric(21,11),
    market_rate numeric(21,11),
    md character(1),
    setl_amount numeric(21,2),
    pl_amount numeric(21,2),
    margin numeric(21,11),
    buy_sell character varying(10),
    shipment_records_id character varying(60),
    attach_to_confo character(1),
    is_deleted character varying(1) DEFAULT 'N'::character varying NOT NULL,
    created timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    created_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_updated timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_checked_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_maked timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_db timestamp(6) without time zone DEFAULT clock_timestamp(),
    mod_id double precision DEFAULT 0 NOT NULL,
    maker_checker_status character varying(10) DEFAULT 'Maked'::character varying NOT NULL,
    shadow_id character varying(149) DEFAULT ''::character varying NOT NULL,
    shipping_status_id character varying(61),
    vault_status_id character varying(61),
    delivery_status character varying(61),
    delivery_time character varying(25),
    delivery_remarks character varying(25),
    vault_inventory_updated character varying(1),
    insurance_value_required character varying(1),
    shipment_value_required character varying(1),
    suggested_margin double precision DEFAULT 0,
    rates_tolerance double precision DEFAULT 0,
    leg_ccy_vs_base_dealrate numeric(21,11) DEFAULT 0,
    leg_ccy_vs_usd_dealrate numeric(21,11) DEFAULT 0,
    leg_ccy_vs_usd_parentrate numeric(21,11) DEFAULT 0 NOT NULL
);


--
--

CREATE TABLE tbls_box_extn (
    fin_id character varying(99) NOT NULL,
    box_types_id character varying(60),
    no_of_bags double precision,
    regions_id character varying(60),
    is_deleted character varying(1) DEFAULT 'N'::character varying NOT NULL,
    created timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    created_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_updated timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_checked_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_maked timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_db timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    mod_id double precision DEFAULT 0 NOT NULL,
    maker_checker_status character varying(10) DEFAULT 'Maked'::character varying NOT NULL,
    shadow_id character varying(99) DEFAULT ''::character varying NOT NULL
);


--
--

CREATE TABLE tbls_box_market_int (
    fin_id character varying(99) NOT NULL,
    markets_id character varying(60),
    currencies_id character varying(60),
    note_denoms_id character varying(213),
    note_type_id character varying(60),
    box_type_id character varying(60),
    max_no_of_pieces double precision,
    regions_id character varying(60),
    is_deleted character varying(1) DEFAULT 'N'::character varying NOT NULL,
    created timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    created_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_updated timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_checked_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_maked timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_db timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    mod_id double precision DEFAULT 0 NOT NULL,
    maker_checker_status character varying(10) DEFAULT 'Maked'::character varying NOT NULL,
    shadow_id character varying(99) DEFAULT ''::character varying NOT NULL
);


--
--

CREATE TABLE tbls_box_types (
    fin_id character varying(60) NOT NULL,
    box_type character varying(60),
    name character varying(60),
    code character varying(20),
    dimension character varying(50),
    regions_id character varying(60),
    is_deleted character varying(1) DEFAULT 'N'::character varying NOT NULL,
    created timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    created_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_updated timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_checked_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_maked timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_db timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    mod_id double precision DEFAULT 0 NOT NULL,
    maker_checker_status character varying(10) DEFAULT 'Maked'::character varying NOT NULL,
    shadow_id character varying(60) DEFAULT ''::character varying NOT NULL
);


--
--

CREATE TABLE tbls_branches (
    fin_id character varying(91) NOT NULL,
    cust_id character varying(60),
    short_name character varying(30),
    name character varying(100),
    add1 character varying(100),
    add2 character varying(100),
    add3 character varying(100),
    add4 character varying(100),
    contact_no character varying(30),
    fax_no character varying(30),
    telex_no character varying(50),
    contact_person character varying(50),
    title character varying(50),
    email character varying(50),
    swift_code character varying(20),
    reut_code character varying(20),
    branch_group character varying(20),
    city_operation character varying(151),
    city_incorporation character varying(151),
    wss_short_name character varying(20),
    exposure_code character varying(20),
    date_open timestamp(6) without time zone DEFAULT clock_timestamp(),
    date_effective timestamp(6) without time zone DEFAULT clock_timestamp(),
    status character varying(20),
    shipping_location character varying(25),
    shipping_contact character varying(30),
    shipping_fax character varying(30),
    shipping_swift character varying(30),
    shipping_tel character varying(30),
    aml_region character varying(30),
    is_deleted character varying(1) DEFAULT 'N'::character varying NOT NULL,
    created timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    created_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_updated timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_checked_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_maked timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_db timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    mod_id double precision DEFAULT 0 NOT NULL,
    maker_checker_status character varying(10) DEFAULT 'Maked'::character varying NOT NULL,
    shadow_id character varying(91) DEFAULT ''::character varying NOT NULL,
    margin_template_id character varying(120),
    rate_source_scheme_id character varying(100),
    shipping_email character varying(60),
    cbni_country character varying(60),
    comms_config_template_id character varying(60),
    cbni_client_name1 character varying(17),
    cbni_client_name2 character varying(17),
    cbni_client_name3 character varying(17),
    cbni_address1 character varying(17),
    cbni_address2 character varying(17),
    cbni_address3 character varying(17),
    remarks character varying(255),
    closure_reason character varying(100),
    branch_id character varying(60)
);


--
--

CREATE TABLE tbls_calendar_hols (
    fin_id character varying(71) NOT NULL,
    cal_id character varying(60),
    holiday_date timestamp(0) without time zone DEFAULT NULL::timestamp without time zone,
    holiday_desc character varying(60),
    is_weekly character varying(1),
    is_yearly character varying(1),
    is_special character varying(1),
    is_deleted character varying(1) DEFAULT 'N'::character varying NOT NULL,
    created timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    created_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_updated timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_checked_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_maked timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_db timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    mod_id double precision DEFAULT 0 NOT NULL,
    maker_checker_status character varying(10) DEFAULT 'Maked'::character varying NOT NULL,
    shadow_id character varying(71) DEFAULT ''::character varying NOT NULL
);


--
--

CREATE TABLE tbls_calendars (
    fin_id character varying(60) NOT NULL,
    code character varying(10),
    name character varying(30),
    description character varying(30),
    regions_id character varying(60),
    is_deleted character varying(1) DEFAULT 'N'::character varying NOT NULL,
    created timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    created_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_updated timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_checked_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_maked timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_db timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    mod_id double precision DEFAULT 0 NOT NULL,
    maker_checker_status character varying(10) DEFAULT 'Maked'::character varying NOT NULL,
    shadow_id character varying(60) DEFAULT ''::character varying NOT NULL
);


--
--

CREATE TABLE tbls_carrier_contacts_extn (
    fin_id character varying(60) NOT NULL,
    carriers_id character varying(60),
    name character varying(50),
    id_number character varying(50),
    contact_nos character varying(50),
    fax_nos character varying(50),
    email character varying(150),
    contact_default character(1),
    regions_id character varying(60),
    is_deleted character varying(1) DEFAULT 'N'::character varying NOT NULL,
    created timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    created_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_updated timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_checked_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_maked timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_db timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    mod_id double precision DEFAULT 0 NOT NULL,
    maker_checker_status character varying(10) DEFAULT 'Maked'::character varying NOT NULL,
    shadow_id character varying(60) DEFAULT ''::character varying NOT NULL
);


--
--

CREATE TABLE tbls_carrier_crew_extn (
    fin_id character varying(111) NOT NULL,
    carrier_id character varying(60),
    name character varying(50),
    name_in_fl character varying(50),
    id_number character varying(50),
    contact_nos character varying(50),
    email character varying(50),
    region_id character varying(60),
    is_deleted character varying(1) DEFAULT 'N'::character varying NOT NULL,
    created timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    created_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_updated timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_checked_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_maked timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_db timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    mod_id double precision DEFAULT 0 NOT NULL,
    maker_checker_status character varying(10) DEFAULT 'Maked'::character varying NOT NULL,
    shadow_id character varying(111) DEFAULT ''::character varying NOT NULL,
    dedicated_team character varying(60)
);


--
--

CREATE TABLE tbls_carriers (
    fin_id character varying(60) NOT NULL,
    code character varying(20),
    name character varying(50),
    name_in_fl character varying(50),
    carrier_types character varying(60),
    cities_id character varying(151),
    iata_code character varying(20),
    kc_code character varying(20),
    airline_acct character varying(20),
    address1 character varying(50),
    address2 character varying(50),
    address3 character varying(50),
    address4 character varying(50),
    terminal character varying(20),
    airline_agent character varying(50),
    accountinginfo character varying(50),
    import_dept character varying(50),
    import_after_office_hour character varying(50),
    import_contact character varying(50),
    import_fax character varying(50),
    import_email character varying(50),
    export_deptt character varying(50),
    export_after_office_hour character varying(50),
    export_contact character varying(50),
    export_fax character varying(50),
    import_contact_no character varying(50),
    export_contact_no character varying(50),
    export_email character varying(50),
    regions_id character varying(60),
    is_deleted character varying(1) DEFAULT 'N'::character varying NOT NULL,
    created timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    created_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_updated timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_checked_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_maked timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_db timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    mod_id double precision DEFAULT 0 NOT NULL,
    maker_checker_status character varying(10) DEFAULT 'Maked'::character varying NOT NULL,
    shadow_id character varying(60) DEFAULT ''::character varying NOT NULL,
    awb_issued_by character varying(60)
);


--
--

CREATE TABLE tbls_cif_cust_classification (
    fin_id character varying(60) NOT NULL,
    code character varying(20),
    description character varying(50),
    is_deleted character varying(1) DEFAULT 'N'::character varying NOT NULL,
    created timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    created_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_updated timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_checked_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_maked timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_db timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    mod_id double precision DEFAULT 0 NOT NULL,
    maker_checker_status character varying(10) DEFAULT 'Maked'::character varying NOT NULL,
    shadow_id character varying(60) DEFAULT ''::character varying NOT NULL
);


--
--

CREATE TABLE tbls_cif_id_types (
    fin_id character varying(60) NOT NULL,
    id_type character varying(2),
    id_desc character varying(50),
    is_deleted character varying(1) DEFAULT 'N'::character varying NOT NULL,
    created timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    created_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_updated timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_checked_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_maked timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_db timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    mod_id double precision DEFAULT 0 NOT NULL,
    maker_checker_status character varying(10) DEFAULT 'Maked'::character varying NOT NULL,
    shadow_id character varying(60) DEFAULT ''::character varying NOT NULL
);


--
--

CREATE TABLE tbls_cities (
    fin_id character varying(151) NOT NULL,
    code character varying(30),
    name character varying(30),
    countries_id character varying(120),
    is_local character varying(1) DEFAULT 'N'::character varying,
    is_deleted character varying(1) DEFAULT 'N'::character varying NOT NULL,
    created timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    created_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_updated timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_checked_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_maked timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_db timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    mod_id double precision DEFAULT 0 NOT NULL,
    maker_checker_status character varying(10) DEFAULT 'Maked'::character varying NOT NULL,
    shadow_id character varying(151) DEFAULT ''::character varying NOT NULL
);


--
--

CREATE TABLE tbls_commissions (
    fin_id character varying(204) NOT NULL,
    deal_no character varying(60),
    leg_no character varying(60),
    customers_id character varying(60),
    branches_id character varying(91),
    invoice_date timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    deal_action_date timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    commission_amount double precision DEFAULT 0 NOT NULL,
    commission_ccy character varying(60) NOT NULL,
    rate_source character varying(60),
    is_deleted character varying(1) DEFAULT 'N'::character varying NOT NULL,
    created timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    created_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_updated timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_checked_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_maked timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_db timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    mod_id double precision DEFAULT 0 NOT NULL,
    maker_checker_status character varying(10) DEFAULT 'Maked'::character varying NOT NULL,
    shadow_id character varying(204) DEFAULT ''::character varying NOT NULL,
    leg_buy_sell character varying(10),
    entry_month numeric(15,5)
);


--
--

CREATE TABLE tbls_commissions_config (
    fin_id character varying(60) NOT NULL,
    payment_ccy_id character varying(60),
    charging_method character varying(3),
    bank_notes_types_id character varying(60) NOT NULL,
    min_amt double precision DEFAULT 0 NOT NULL,
    max_amt double precision DEFAULT 0 NOT NULL,
    commission_amt double precision DEFAULT 0 NOT NULL,
    rates_sources_id character varying(60) NOT NULL,
    delivery_mode character varying(60) NOT NULL,
    priority double precision DEFAULT 0 NOT NULL,
    is_deleted character varying(1) DEFAULT 'N'::character varying NOT NULL,
    created timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    created_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_updated timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_checked_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_maked timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_db timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    mod_id double precision DEFAULT 0 NOT NULL,
    maker_checker_status character varying(10) DEFAULT 'Maked'::character varying NOT NULL,
    shadow_id character varying(60) DEFAULT ''::character varying NOT NULL,
    template_name character varying(60),
    commission_ccy character varying(60)
);


--
--

CREATE TABLE tbls_comms_cfg_template (
    fin_id character varying(60) NOT NULL,
    template_name character varying(60),
    delivery_mode character varying(60),
    is_deleted character varying(1) DEFAULT 'N'::character varying NOT NULL,
    created timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    created_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_updated timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_checked_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_maked timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_db timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    mod_id double precision DEFAULT 0 NOT NULL,
    maker_checker_status character varying(10) DEFAULT 'Maked'::character varying NOT NULL,
    shadow_id character varying(60) DEFAULT ''::character varying NOT NULL
);


--
--

CREATE TABLE tbls_cons_limit (
    fin_id character varying(150) NOT NULL,
    cels_code character varying(60) NOT NULL,
    amount numeric(21,2) DEFAULT 0,
    currencies_id character varying(60) NOT NULL,
    is_deleted character varying(1) DEFAULT 'N'::character varying NOT NULL,
    created timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    created_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_updated timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_checked_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_maked timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_db timestamp(6) without time zone DEFAULT clock_timestamp(),
    mod_id double precision DEFAULT 0 NOT NULL,
    maker_checker_status character varying(10) DEFAULT 'Maked'::character varying NOT NULL,
    shadow_id character varying(150) DEFAULT ''::character varying NOT NULL,
    remarks character varying(100),
    update_method character varying(10)
);


--
--

CREATE TABLE tbls_cons_limit_util (
    fin_id character varying(150) NOT NULL,
    posting_date timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    customers_id character varying(60) NOT NULL,
    branches_id character varying(91) NOT NULL,
    deals_id character varying(60) NOT NULL,
    leg_number character varying(60) NOT NULL,
    util_amount numeric(21,2) DEFAULT 0,
    util_currencies_id character varying(60) NOT NULL,
    is_deleted character varying(1) DEFAULT 'N'::character varying NOT NULL,
    created timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    created_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_updated timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_checked_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_maked timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_db timestamp(6) without time zone DEFAULT clock_timestamp(),
    mod_id double precision DEFAULT 0 NOT NULL,
    maker_checker_status character varying(10) DEFAULT 'Maked'::character varying NOT NULL,
    shadow_id character varying(150) DEFAULT ''::character varying NOT NULL,
    limit_amount numeric(21,2) DEFAULT 0,
    reallocated_amount numeric(21,2) DEFAULT 0,
    is_override character(1) DEFAULT 'N'::bpchar,
    split_info character varying(2000),
    util_native_amount numeric(21,2) DEFAULT 0,
    native_currencies_id character varying(60),
    is_breached character varying(1) DEFAULT 'N'::character varying,
    breach_comments character varying(100),
    total_util_amount numeric(21,2) DEFAULT 0
);


--
--

CREATE TABLE tbls_consignee_branches_int (
    fin_id character varying(152) NOT NULL,
    branches_id character varying(91),
    consignees_id character varying(60),
    regions_id character varying(60),
    is_deleted character varying(1) DEFAULT 'N'::character varying NOT NULL,
    created timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    created_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_updated timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_checked_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_maked timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_db timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    mod_id double precision DEFAULT 0 NOT NULL,
    maker_checker_status character varying(10) DEFAULT 'Maked'::character varying NOT NULL,
    shadow_id character varying(152) DEFAULT ''::character varying NOT NULL
);


--
--

CREATE TABLE tbls_consignee_contacts_extn (
    fin_id character varying(111) NOT NULL,
    consignees_id character varying(60),
    name character varying(50),
    id_number character varying(50),
    contact_nos character varying(50),
    fax_nos character varying(50),
    email character varying(50),
    contact_default character(1),
    regions_id character varying(60),
    is_deleted character varying(1) DEFAULT 'N'::character varying NOT NULL,
    created timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    created_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_updated timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_checked_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_maked timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_db timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    mod_id double precision DEFAULT 0 NOT NULL,
    maker_checker_status character varying(10) DEFAULT 'Maked'::character varying NOT NULL,
    shadow_id character varying(111) DEFAULT ''::character varying NOT NULL
);


--
--

CREATE TABLE tbls_consignees (
    fin_id character varying(60) NOT NULL,
    short_name character varying(60),
    name character varying(60),
    countries_id character varying(120),
    cities_id character varying(152),
    airports_id character varying(182),
    is_counterparty character(1),
    address1 character varying(60),
    address2 character varying(60),
    address3 character varying(60),
    address4 character varying(60),
    awb_special_clause character varying(300),
    issuing_carrier_agent_name character varying(100),
    agent_address1 character varying(100),
    agent_address2 character varying(100),
    regions_id character varying(60),
    is_deleted character varying(1) DEFAULT 'N'::character varying NOT NULL,
    created timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    created_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_updated timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_checked_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_maked timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_db timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    mod_id double precision DEFAULT 0 NOT NULL,
    maker_checker_status character varying(10) DEFAULT 'Maked'::character varying NOT NULL,
    shadow_id character varying(60) DEFAULT ''::character varying NOT NULL,
    postal_code character varying(30)
);


--
--

CREATE TABLE tbls_cost_center (
    fin_id character varying(60) NOT NULL,
    short_name character varying(10),
    long_name character varying(100),
    region_id character varying(60),
    corp_code character varying(10),
    is_deleted character varying(1) DEFAULT 'N'::character varying NOT NULL,
    created timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    created_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_updated timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_checked_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_maked timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_db timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    mod_id double precision DEFAULT 0 NOT NULL,
    maker_checker_status character varying(10) DEFAULT 'Maked'::character varying NOT NULL,
    shadow_id character varying(60) DEFAULT ''::character varying NOT NULL
);


--
--

CREATE TABLE tbls_cost_to_carry (
    fin_id character varying(286) NOT NULL,
    product_id character varying(60),
    repository_id character varying(60),
    reference_date timestamp(0) without time zone,
    native_ctc numeric(21,2),
    native_ccy_id character varying(60),
    base_ctc numeric(21,2),
    base_ccy character varying(60),
    is_deleted character varying(1) DEFAULT 'N'::character varying NOT NULL,
    created timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    created_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_updated timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_checked_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_maked timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_db timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    mod_id double precision DEFAULT 0 NOT NULL,
    maker_checker_status character varying(10) DEFAULT 'Maked'::character varying NOT NULL,
    shadow_id character varying(120) DEFAULT ''::character varying NOT NULL,
    nostro character varying(81),
    next_business_date timestamp(0) without time zone,
    funding_amount_sign character varying(30),
    entry_date timestamp(0) without time zone,
    rate numeric(21,11),
    interest_amount_sign character varying(30)
);


--
--

CREATE TABLE tbls_countries (
    fin_id character varying(120) NOT NULL,
    name character varying(60),
    code character varying(120),
    is_deleted character varying(1) DEFAULT 'N'::character varying NOT NULL,
    created timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    created_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_updated timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_checked_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_maked timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_db timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    mod_id double precision DEFAULT 0 NOT NULL,
    maker_checker_status character varying(10) DEFAULT 'Maked'::character varying NOT NULL,
    shadow_id character varying(120) DEFAULT ''::character varying NOT NULL
);


--
--

CREATE TABLE tbls_credit_limits_reporting (
    fin_id character varying(60) NOT NULL,
    limit_utilisation numeric(21,2),
    amount numeric(21,2),
    artificial character varying(5),
    tenor character varying(60),
    tenor_name character varying(60),
    tenor_buckets_id character varying(60),
    type character varying(60),
    cels_code character varying(60),
    products_code character varying(60),
    currencies_id character varying(60),
    allocated_start_date timestamp(6) without time zone NOT NULL,
    allocated_expiry_date timestamp(6) without time zone NOT NULL,
    reporting_date timestamp(6) without time zone NOT NULL,
    is_deleted character varying(1) DEFAULT 'N'::character varying NOT NULL,
    created timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    created_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_updated timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_checked_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_maked timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_db timestamp(6) without time zone DEFAULT clock_timestamp(),
    mod_id double precision DEFAULT 0 NOT NULL,
    maker_checker_status character varying(10) DEFAULT 'Maked'::character varying NOT NULL,
    shadow_id character varying(60) DEFAULT ''::character varying NOT NULL
);


--
--

CREATE TABLE tbls_credit_owner_types (
    fin_id character varying(60) NOT NULL,
    code character varying(20),
    name character varying(20),
    description character varying(50),
    is_deleted character varying(1) DEFAULT 'N'::character varying NOT NULL,
    created timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    created_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_updated timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_checked_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_maked timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_db timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    mod_id double precision DEFAULT 0 NOT NULL,
    maker_checker_status character varying(10) DEFAULT 'Maked'::character varying NOT NULL,
    shadow_id character varying(60) DEFAULT ''::character varying NOT NULL
);


--
--

CREATE TABLE tbls_ctc_tmp (
    fin_id character varying(286) NOT NULL,
    product_id character varying(60),
    repository_id character varying(60),
    reference_date timestamp(0) without time zone,
    native_ctc numeric(21,2),
    native_ccy_id character varying(60),
    base_ctc numeric(21,2),
    base_ccy character varying(60),
    is_deleted character varying(1) DEFAULT 'N'::character varying NOT NULL,
    created timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    created_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_updated timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_checked_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_maked timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_db timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    mod_id double precision DEFAULT 0 NOT NULL,
    maker_checker_status character varying(10) DEFAULT 'Maked'::character varying NOT NULL,
    shadow_id character varying(120) DEFAULT ''::character varying NOT NULL,
    nostro character varying(81),
    next_business_date timestamp(0) without time zone,
    funding_amount_sign character varying(30),
    entry_date timestamp(0) without time zone,
    rate numeric(21,11)
);


--
--

CREATE TABLE tbls_currencies (
    fin_id character varying(60) NOT NULL,
    name character varying(30) NOT NULL,
    code character varying(3) NOT NULL,
    iso_code character varying(3) NOT NULL,
    spot_shifter character varying(2) NOT NULL,
    day_basis double precision NOT NULL,
    holiday_cal_code character varying(60) NOT NULL,
    decimal_precision double precision NOT NULL,
    rounding_for_bn character(1) NOT NULL,
    rounding_for_fx character(1) NOT NULL,
    group_name character varying(20),
    is_deleted character varying(1) DEFAULT 'N'::character varying NOT NULL,
    created timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    created_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_updated timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_checked_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_maked timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_db timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    mod_id double precision DEFAULT 0 NOT NULL,
    maker_checker_status character varying(10) DEFAULT 'Maked'::character varying NOT NULL,
    shadow_id character varying(60) DEFAULT ''::character varying NOT NULL,
    mrg_tol_cust_scheme double precision DEFAULT 0,
    mrg_tol_cust_no_scheme double precision DEFAULT 0,
    sort_order numeric(15,5) DEFAULT 1
);


--
--

CREATE TABLE tbls_currency_cutoffs (
    fin_id character varying(60) NOT NULL,
    currencies_id character varying(60),
    cutoff numeric(2,0),
    remarks character varying(20),
    regions_id character varying(60),
    is_deleted character varying(1) DEFAULT 'N'::character varying NOT NULL,
    created timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    created_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_updated timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_checked_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_maked timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_db timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    mod_id double precision DEFAULT 0 NOT NULL,
    maker_checker_status character varying(10) DEFAULT 'Maked'::character varying NOT NULL,
    shadow_id character varying(60) DEFAULT ''::character varying NOT NULL
);


--
--

CREATE TABLE tbls_currencypairs (
    fin_id character varying(60) NOT NULL,
    pairs_shortname character varying(60) NOT NULL,
    currency1_id character varying(60) NOT NULL,
    spot_factor double precision NOT NULL,
    currency2_id character varying(60) NOT NULL,
    swap_factor double precision NOT NULL,
    num_decimal double precision NOT NULL,
    ric character varying(15),
    is_retreivable character(1),
    spot_lag character varying(2),
    is_deleted character varying(1) DEFAULT 'N'::character varying NOT NULL,
    created timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    created_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_updated timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_checked_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_maked timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_db timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    mod_id double precision DEFAULT 0 NOT NULL,
    maker_checker_status character varying(10) DEFAULT 'Maked'::character varying NOT NULL,
    shadow_id character varying(60) DEFAULT ''::character varying NOT NULL
);


--
--

CREATE TABLE tbls_currencypairs_audit (
    id double precision DEFAULT nextval('"iseq$$_94065"'::regclass) NOT NULL,
    currencypair_id character varying(100) NOT NULL,
    operation_type character varying(100) NOT NULL,
    create_date timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL
);


--
--

CREATE TABLE tbls_cust_margin_int (
    fin_id character varying(60) NOT NULL,
    customer_id character varying(60),
    branch_id character varying(91),
    margin_template_id character varying(120),
    template_type character varying(20),
    region_id character varying(60),
    is_deleted character varying(1) DEFAULT 'N'::character varying NOT NULL,
    created timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    created_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_updated timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_checked_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_maked timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_db timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    mod_id double precision DEFAULT 0 NOT NULL,
    maker_checker_status character varying(10) DEFAULT 'Maked'::character varying NOT NULL,
    shadow_id character varying(60) DEFAULT ''::character varying NOT NULL
);


--
--

CREATE TABLE tbls_cust_rate_mappings_int (
    fin_id character varying(60) NOT NULL,
    customers_id character varying(30),
    currencies_id character varying(60),
    rate_sources_id character varying(121),
    is_deleted character varying(1) DEFAULT 'N'::character varying NOT NULL,
    created timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    created_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_updated timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_checked_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_maked timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_db timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    mod_id double precision DEFAULT 0 NOT NULL,
    maker_checker_status character varying(10) DEFAULT 'Maked'::character varying NOT NULL,
    shadow_id character varying(60) DEFAULT ''::character varying NOT NULL
);


--
--

CREATE TABLE tbls_customer_cons_balance (
    fin_id character varying(450) NOT NULL,
    consignee_code character varying(60),
    branch_code character varying(30),
    balance_date timestamp(6) without time zone DEFAULT clock_timestamp(),
    currency character varying(60),
    denom character varying(213),
    type character varying(60),
    balance numeric(21,2),
    is_deleted character varying(1) DEFAULT 'N'::character varying NOT NULL,
    created timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    created_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_updated timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_checked_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_maked timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_db timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    mod_id double precision DEFAULT 0 NOT NULL,
    maker_checker_status character varying(10) DEFAULT 'Maked'::character varying NOT NULL,
    shadow_id character varying(60) DEFAULT ''::character varying NOT NULL
);


--
--

CREATE TABLE tbls_customer_types (
    fin_id character varying(60) NOT NULL,
    type_code character varying(20),
    description character varying(50),
    gl_cust_type character varying(50),
    aml_cust_type character varying(50),
    erm_cust_type character varying(50),
    is_deleted character varying(1) DEFAULT 'N'::character varying NOT NULL,
    created timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    created_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_updated timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_checked_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_maked timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_db timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    mod_id double precision DEFAULT 0 NOT NULL,
    maker_checker_status character varying(10) DEFAULT 'Maked'::character varying NOT NULL,
    shadow_id character varying(60) DEFAULT ''::character varying NOT NULL,
    is_internal character(1),
    limit_exclude character(1)
);


--
--

CREATE TABLE tbls_customers (
    fin_id character varying(60) NOT NULL,
    short_name character varying(30),
    name character varying(100),
    ctp_no double precision,
    bwcif_no character varying(20),
    limit_code character varying(20),
    type_id character varying(60),
    parent_id character varying(60),
    credit_owner_id character varying(60),
    status character varying(30),
    open_date timestamp(6) without time zone DEFAULT clock_timestamp(),
    close_date timestamp(6) without time zone DEFAULT clock_timestamp(),
    shipping_location character varying(60),
    shipping_contact character varying(30),
    shipping_fax character varying(30),
    shipping_swift character varying(30),
    shipping_tel character varying(30),
    dormant_review_date timestamp(6) without time zone DEFAULT clock_timestamp(),
    cif_pri_name1 character varying(40),
    cif_pri_name2 character varying(40),
    bwcif_id character varying(30),
    bwcif_id_type character varying(30),
    bwcif_country_id character varying(120),
    cif_classifcation_id character varying(60),
    country_incorporation_id character varying(120),
    incorporation_date timestamp(6) without time zone DEFAULT clock_timestamp(),
    business_operation_country_id character varying(60),
    mas_code character varying(4),
    mas_industry_code character varying(2),
    hkma_code character varying(6),
    cto_code character varying(30),
    is_deleted character varying(1) DEFAULT 'N'::character varying NOT NULL,
    created timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    created_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_updated timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_checked_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_maked timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_db timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    mod_id double precision DEFAULT 0 NOT NULL,
    maker_checker_status character varying(10) DEFAULT 'Maked'::character varying NOT NULL,
    shadow_id character varying(60) DEFAULT ''::character varying NOT NULL,
    margin_template_id character varying(120),
    is_resident character varying(1),
    rate_source_scheme_id character varying(100),
    is_bwcif_updated character(1),
    closure_reason character varying(100)
);


--
--

CREATE TABLE tbls_customers_acc_address (
    fin_id character varying(121) NOT NULL,
    cust_id character varying(60),
    product_code character varying(60),
    account_number character varying(39),
    account_type character varying(3) DEFAULT 'BLS'::character varying,
    date_acc_open timestamp(6) without time zone DEFAULT clock_timestamp(),
    address_cif_no character varying(20),
    address_seq_no character varying(20),
    is_deleted character varying(1) DEFAULT 'N'::character varying NOT NULL,
    created timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    created_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_updated timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_checked_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_maked timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_db timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    mod_id double precision DEFAULT 0 NOT NULL,
    maker_checker_status character varying(10) DEFAULT 'Maked'::character varying NOT NULL,
    shadow_id character varying(121) DEFAULT ''::character varying NOT NULL,
    is_bwcif_updated character(1)
);


--
--

CREATE TABLE tbls_customers_aml (
    fin_id character varying(60) NOT NULL,
    cust_id character varying(60),
    risk_ranking character varying(30),
    per_change_buy character varying(30),
    per_change_sell character varying(30),
    buy_monthly_volume character varying(30),
    sell_monthly_volume character varying(30),
    actimize_risk_classification character varying(60),
    kyc_last_review_date timestamp(6) without time zone DEFAULT clock_timestamp(),
    pep_indicator character varying(30),
    review_date timestamp(6) without time zone DEFAULT clock_timestamp(),
    funds_source character varying(50),
    business_nature character varying(50),
    kyc_remarks character varying(50),
    is_deleted character varying(1) DEFAULT 'N'::character varying NOT NULL,
    created timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    created_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_updated timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_checked_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_maked timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_db timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    mod_id double precision DEFAULT 0 NOT NULL,
    maker_checker_status character varying(10) DEFAULT 'Maked'::character varying NOT NULL,
    shadow_id character varying(60) DEFAULT ''::character varying NOT NULL,
    buy_vol_usd double precision,
    sell_vol_usd double precision
);


--
--

CREATE TABLE tbls_customers_msg_config (
    fin_id character varying(152) NOT NULL,
    customers_id character varying(60),
    branches_id character varying(91),
    products_id character varying(60),
    gen_swift_confo character(1) DEFAULT 'N'::bpchar NOT NULL,
    gen_hard_copy character(1) DEFAULT 'N'::bpchar NOT NULL,
    gen_soft_copy character(1) DEFAULT 'N'::bpchar NOT NULL,
    gen_fax_copy character(1) DEFAULT 'N'::bpchar NOT NULL,
    regions_id character varying(60),
    is_deleted character varying(1) DEFAULT 'N'::character varying NOT NULL,
    created timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    created_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_updated timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_checked_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_maked timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_db timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    mod_id double precision DEFAULT 0 NOT NULL,
    maker_checker_status character varying(10) DEFAULT 'Maked'::character varying NOT NULL,
    shadow_id character varying(152) DEFAULT ''::character varying NOT NULL,
    module_action character varying(60),
    msg_id character varying(60)
);


--
--

CREATE TABLE tbls_daily_funding_open_bal (
    fin_id character varying(275) NOT NULL,
    repository_id character varying(60),
    product_id character varying(60),
    currency_id character varying(60),
    past_date timestamp(6) without time zone,
    funding_amount numeric(21,2),
    is_deleted character varying(1) DEFAULT 'N'::character varying NOT NULL,
    created timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    created_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_updated timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_checked_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_maked timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_db timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    mod_id double precision DEFAULT 0 NOT NULL,
    maker_checker_status character varying(10) DEFAULT 'Maked'::character varying NOT NULL,
    shadow_id character varying(275) DEFAULT ''::character varying NOT NULL,
    nostro character varying(81)
);


--
--

CREATE TABLE tbls_daily_pl (
    fin_id character varying(204) NOT NULL,
    repository_id character varying(60),
    product_id character varying(60),
    currency_id character varying(60),
    pl_date timestamp(0) without time zone,
    realized_pl numeric(21,2),
    unrealized_pl_disc numeric(21,2),
    total_pl numeric(21,2),
    is_deleted character varying(1) DEFAULT 'N'::character varying NOT NULL,
    created timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    created_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_updated timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_checked_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_maked timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_db timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    mod_id double precision DEFAULT 0 NOT NULL,
    maker_checker_status character varying(10) DEFAULT 'Maked'::character varying NOT NULL,
    shadow_id character varying(204) DEFAULT ''::character varying NOT NULL,
    reference_date timestamp(0) without time zone,
    discount_factor numeric(21,11),
    cash_realized_pl numeric(21,2) DEFAULT 0,
    cash_unrealized_pl numeric(21,2) DEFAULT 0,
    cash_total_pl numeric(21,2) DEFAULT 0,
    closing_rate numeric(21,11)
);


--
--

CREATE TABLE tbls_dates_master (
    fin_id character varying(60) NOT NULL,
    system_date timestamp(0) without time zone,
    accounting_date timestamp(0) without time zone,
    region_id character varying(60),
    is_deleted character varying(1) DEFAULT 'N'::character varying NOT NULL,
    created timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    created_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_updated timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_checked_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_maked timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_db timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    mod_id numeric DEFAULT 0 NOT NULL,
    maker_checker_status character varying(10) DEFAULT 'Maked'::character varying NOT NULL,
    shadow_id character varying(60) DEFAULT ''::character varying NOT NULL,
    eod_started character varying(25),
    reporting_date timestamp(0) without time zone,
    holiday_date timestamp(0) without time zone,
    gmp_consol_date timestamp(0) without time zone,
    edw_last_updated_time timestamp(0) without time zone
);


--
--

CREATE TABLE tbls_deal_comm_ssi (
    fin_id character varying(162) NOT NULL,
    deal_versions_id character varying(99),
    pay_receive character(1),
    commission_currency_id character varying(60),
    nv_code character varying(20),
    account_no character varying(35),
    gl_code character varying(20),
    ssi_code character varying(120),
    created timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    created_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_updated timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_checked_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_maked timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_db timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    mod_id double precision DEFAULT 0 NOT NULL,
    maker_checker_status character varying(10) DEFAULT 'Maked'::character varying NOT NULL,
    shadow_id character varying(162) DEFAULT ''::character varying NOT NULL,
    is_deleted character varying(1)
);


--
--

CREATE TABLE tbls_deal_comm_ssi_his (
    fin_id character varying(162) NOT NULL,
    deal_versions_id character varying(99),
    pay_receive character(1),
    commission_currency_id character varying(60),
    nv_code character varying(20),
    account_no character varying(35),
    gl_code character varying(20),
    ssi_code character varying(120),
    created timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    created_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_updated timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_checked_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_maked timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_db timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    mod_id double precision DEFAULT 0 NOT NULL,
    maker_checker_status character varying(10) DEFAULT 'Maked'::character varying NOT NULL,
    shadow_id character varying(162) DEFAULT ''::character varying NOT NULL,
    is_deleted character varying(1)
);


--
--

CREATE TABLE tbls_deal_edit_reason_codes (
    fin_id character varying(60) NOT NULL,
    code character varying(60) NOT NULL,
    template character varying(500) NOT NULL,
    is_deleted character varying(1) DEFAULT 'N'::character varying NOT NULL,
    created timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    created_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_updated timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_checked_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_maked timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_db timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    mod_id double precision DEFAULT 0 NOT NULL,
    maker_checker_status character varying(10) DEFAULT 'Maked'::character varying NOT NULL,
    shadow_id character varying(60) DEFAULT ''::character varying NOT NULL
);


--
--

CREATE TABLE tbls_deal_ssi (
    fin_id character varying(162) NOT NULL,
    deal_versions_id character varying(99),
    ssi_rules_id character varying(286),
    ssi_type character varying(60),
    pay_receive character(1),
    currency_id character varying(60),
    ssitype character varying(10),
    setl_mode_id character varying(60),
    nv_code character varying(20),
    nv_narration character varying(60),
    bic_code character varying(20),
    account_no character varying(35),
    gl_code character varying(20),
    ssi_code character varying(120),
    cust_agent_swift_code character varying(20),
    cust_agent_account character varying(35),
    cust_agent_name1 character varying(35),
    cust_agent_name2 character varying(35),
    cust_agent_name3 character varying(35),
    cust_agent_name4 character varying(35),
    beneficiary_acc_no character varying(35),
    int_swift_code character varying(20),
    int_account character varying(35),
    bene_name1 character varying(35),
    bene_name2 character varying(35),
    bene_name3 character varying(35),
    bene_name4 character varying(35),
    additional_info1 character varying(35),
    additional_info2 character varying(35),
    additional_info3 character varying(35),
    bene_swift_code character varying(35),
    msg_template_id character varying(60),
    is_deleted character varying(1) DEFAULT 'N'::character varying NOT NULL,
    created timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    created_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_updated timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_checked_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_maked timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_db timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    mod_id double precision DEFAULT 0 NOT NULL,
    maker_checker_status character varying(10) DEFAULT 'Maked'::character varying NOT NULL,
    shadow_id character varying(162) DEFAULT ''::character varying NOT NULL,
    msg_canc_id character varying(60),
    remittance_info_1 character varying(35),
    remittance_info_2 character varying(35),
    remittance_info_3 character varying(35),
    remittance_info_4 character varying(35),
    details_of_chgs character varying(3),
    sender_corr_acct character varying(30),
    receiver_corr_acct character varying(30),
    sender_corr_swift_code character varying(11),
    receiver_corr_swift_code character varying(11),
    additional_info6 character varying(35),
    additional_info5 character varying(35),
    additional_info4 character varying(35)
);


--
--

CREATE TABLE tbls_deal_ssi_his (
    fin_id character varying(162) NOT NULL,
    deal_versions_id character varying(99),
    ssi_rules_id character varying(286),
    ssi_type character varying(60),
    pay_receive character(1),
    currency_id character varying(60),
    ssitype character varying(10),
    setl_mode_id character varying(60),
    nv_code character varying(20),
    nv_narration character varying(60),
    bic_code character varying(20),
    account_no character varying(35),
    gl_code character varying(20),
    ssi_code character varying(120),
    cust_agent_swift_code character varying(20),
    cust_agent_account character varying(35),
    cust_agent_name1 character varying(35),
    cust_agent_name2 character varying(35),
    cust_agent_name3 character varying(35),
    cust_agent_name4 character varying(35),
    beneficiary_acc_no character varying(35),
    int_swift_code character varying(20),
    int_account character varying(35),
    bene_name1 character varying(35),
    bene_name2 character varying(35),
    bene_name3 character varying(35),
    bene_name4 character varying(35),
    additional_info1 character varying(35),
    additional_info2 character varying(35),
    additional_info3 character varying(35),
    bene_swift_code character varying(35),
    msg_template_id character varying(60),
    is_deleted character varying(1) DEFAULT 'N'::character varying NOT NULL,
    created timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    created_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_updated timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_checked_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_maked timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_db timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    mod_id double precision DEFAULT 0 NOT NULL,
    maker_checker_status character varying(10) DEFAULT 'Maked'::character varying NOT NULL,
    shadow_id character varying(162) DEFAULT ''::character varying NOT NULL,
    msg_canc_id character varying(60)
);


--
--

CREATE TABLE tbls_deal_status_trail (
    fin_id character varying(60) NOT NULL,
    deal_no character varying(60),
    from_status_id character varying(60),
    to_status_id character varying(60),
    action character varying(2),
    remarks character varying(100),
    is_deleted character varying(1) DEFAULT 'N'::character varying NOT NULL,
    created timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    created_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_updated timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_checked_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_maked timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_db timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    mod_id double precision DEFAULT 0 NOT NULL,
    maker_checker_status character varying(10) DEFAULT 'Maked'::character varying NOT NULL,
    shadow_id character varying(60) DEFAULT ''::character varying NOT NULL,
    version_no double precision,
    action_date timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL
);


--
--

CREATE TABLE tbls_deal_status_trail_his (
    fin_id character varying(60) NOT NULL,
    deal_no character varying(60),
    from_status_id character varying(60),
    to_status_id character varying(60),
    action character varying(2),
    remarks character varying(100),
    is_deleted character varying(1) DEFAULT 'N'::character varying NOT NULL,
    created timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    created_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_updated timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_checked_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_maked timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_db timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    mod_id double precision DEFAULT 0 NOT NULL,
    maker_checker_status character varying(10) DEFAULT 'Maked'::character varying NOT NULL,
    shadow_id character varying(60) DEFAULT ''::character varying NOT NULL,
    version_no double precision,
    action_date timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL
);


--
--

CREATE TABLE tbls_deal_upload_info (
    fin_id character varying(30) NOT NULL,
    consignee_code character varying(60),
    branch_code character varying(30),
    "current_date" timestamp(6) without time zone DEFAULT clock_timestamp(),
    currency character varying(60),
    denom character varying(213),
    type character varying(60),
    pieces double precision,
    amount numeric(21,2),
    balance numeric(21,2),
    deals_id character varying(60),
    deal_version_no double precision,
    leg_no double precision,
    file_name character varying(100),
    is_deleted character varying(1) DEFAULT 'N'::character varying NOT NULL,
    created timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    created_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_updated timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_checked_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_maked timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_db timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    mod_id double precision DEFAULT 0 NOT NULL,
    maker_checker_status character varying(10) DEFAULT 'Maked'::character varying NOT NULL,
    shadow_id character varying(60) DEFAULT ''::character varying NOT NULL,
    system_date timestamp(6) without time zone DEFAULT clock_timestamp()
);


--
--

CREATE TABLE tbls_deal_versions (
    fin_id character varying(99) NOT NULL,
    deals_id character varying(60) NOT NULL,
    version_no double precision,
    buy_sell character varying(10),
    trade_date timestamp(6) without time zone DEFAULT clock_timestamp(),
    value_date timestamp(6) without time zone DEFAULT clock_timestamp(),
    maturity_date timestamp(6) without time zone DEFAULT clock_timestamp(),
    products_id character varying(60) NOT NULL,
    ud_deal_types_id character varying(60) NOT NULL,
    users_id character varying(60) NOT NULL,
    regions_id character varying(60) NOT NULL,
    repositories_id character varying(60),
    action character varying(60) NOT NULL,
    input_mode character varying(60) NOT NULL,
    source_action character varying(60) NOT NULL,
    link_deal_no character varying(60),
    customers_id character varying(60),
    branches_id character varying(91),
    include_for_aml character(1),
    internal_comments character varying(500),
    external_comments character varying(500),
    is_deleted character varying(1) DEFAULT 'N'::character varying NOT NULL,
    created timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    created_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_updated timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_checked_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_maked timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_db timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    mod_id double precision DEFAULT 0 NOT NULL,
    maker_checker_status character varying(10) DEFAULT 'Maked'::character varying NOT NULL,
    shadow_id character varying(99) DEFAULT ''::character varying NOT NULL,
    action_date timestamp(6) without time zone NOT NULL,
    reason_code_id character varying(60),
    reason_custom character varying(500),
    deal_change_reason_codes_id character varying(60)
);


--
--

CREATE TABLE tbls_deal_versions_his (
    fin_id character varying(99) NOT NULL,
    deals_id character varying(60) NOT NULL,
    version_no double precision,
    buy_sell character varying(10),
    trade_date timestamp(6) without time zone DEFAULT clock_timestamp(),
    value_date timestamp(6) without time zone DEFAULT clock_timestamp(),
    maturity_date timestamp(6) without time zone DEFAULT clock_timestamp(),
    products_id character varying(60) NOT NULL,
    ud_deal_types_id character varying(60) NOT NULL,
    users_id character varying(60) NOT NULL,
    regions_id character varying(60) NOT NULL,
    repositories_id character varying(60),
    action character varying(60) NOT NULL,
    input_mode character varying(60) NOT NULL,
    source_action character varying(60) NOT NULL,
    link_deal_no character varying(60),
    customers_id character varying(60),
    branches_id character varying(91),
    include_for_aml character(1),
    internal_comments character varying(500),
    external_comments character varying(500),
    is_deleted character varying(1) DEFAULT 'N'::character varying NOT NULL,
    created timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    created_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_updated timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_checked_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_maked timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_db timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    mod_id double precision DEFAULT 0 NOT NULL,
    maker_checker_status character varying(10) DEFAULT 'Maked'::character varying NOT NULL,
    shadow_id character varying(99) DEFAULT ''::character varying NOT NULL,
    action_date timestamp(6) without time zone NOT NULL,
    reason_code_id character varying(60),
    reason_custom character varying(500),
    deal_change_reason_codes_id character varying(60)
);


--
--

CREATE TABLE tbls_deals (
    fin_id character varying(60) NOT NULL,
    deal_no character varying(30) NOT NULL,
    entry_date timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    version_no double precision,
    buy_sell character varying(10),
    trade_date timestamp(6) without time zone DEFAULT clock_timestamp(),
    value_date timestamp(6) without time zone DEFAULT clock_timestamp(),
    maturity_date timestamp(6) without time zone DEFAULT clock_timestamp(),
    products_id character varying(60),
    operations_date timestamp(6) without time zone DEFAULT clock_timestamp(),
    operations character varying(60),
    ud_deal_types_id character varying(60),
    users_id character varying(60) NOT NULL,
    regions_id character varying(60) NOT NULL,
    repositories_id character varying(60) NOT NULL,
    action character varying(10),
    action_date timestamp(6) without time zone NOT NULL,
    input_mode character varying(10),
    source_action character varying(10),
    link_deal_no character varying(60),
    customers_id character varying(60),
    branches_id character varying(91),
    include_for_aml character(1),
    internal_comments character varying(500),
    external_comments character varying(500),
    status character varying(10),
    is_deleted character varying(1) DEFAULT 'N'::character varying NOT NULL,
    created timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    created_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_updated timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_checked_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_maked timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_db timestamp(6) without time zone,
    mod_id double precision DEFAULT 0 NOT NULL,
    maker_checker_status character varying(10) DEFAULT 'Maked'::character varying NOT NULL,
    shadow_id character varying(60) DEFAULT ''::character varying NOT NULL,
    external_deal_no character varying(60)
);


--
--

CREATE TABLE tbls_deals_his (
    fin_id character varying(60) NOT NULL,
    deal_no character varying(30) NOT NULL,
    entry_date timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    version_no double precision,
    buy_sell character varying(10),
    trade_date timestamp(6) without time zone DEFAULT clock_timestamp(),
    value_date timestamp(6) without time zone DEFAULT clock_timestamp(),
    maturity_date timestamp(6) without time zone DEFAULT clock_timestamp(),
    products_id character varying(60),
    operations_date timestamp(6) without time zone DEFAULT clock_timestamp(),
    operations character varying(60),
    ud_deal_types_id character varying(60),
    users_id character varying(60) NOT NULL,
    regions_id character varying(60) NOT NULL,
    repositories_id character varying(60) NOT NULL,
    action character varying(10),
    action_date timestamp(6) without time zone NOT NULL,
    input_mode character varying(10),
    source_action character varying(10),
    link_deal_no character varying(60),
    customers_id character varying(60),
    branches_id character varying(91),
    include_for_aml character(1),
    internal_comments character varying(500),
    external_comments character varying(500),
    status character varying(10),
    is_deleted character varying(1) DEFAULT 'N'::character varying NOT NULL,
    created timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    created_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_updated timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_checked_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_maked timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_db timestamp(6) without time zone,
    mod_id double precision DEFAULT 0 NOT NULL,
    maker_checker_status character varying(10) DEFAULT 'Maked'::character varying NOT NULL,
    shadow_id character varying(60) DEFAULT ''::character varying NOT NULL,
    external_deal_no character varying(60)
);


--
--

CREATE TABLE tbls_deals_status (
    fin_id character varying(60) NOT NULL,
    deal_status_id character varying(60),
    fo_remarks character varying(255),
    setl_status_id character varying(60),
    bo_remarks character varying(255),
    shipping_status_id character varying(60),
    sh_remarks character varying(255),
    vault_status_id character varying(60),
    va_remarks character varying(255),
    is_deleted character varying(1) DEFAULT 'N'::character varying NOT NULL,
    created timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    created_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_updated timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_checked_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_maked timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_db timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    mod_id double precision DEFAULT 0 NOT NULL,
    maker_checker_status character varying(10) DEFAULT 'Maked'::character varying NOT NULL,
    shadow_id character varying(60) DEFAULT ''::character varying NOT NULL,
    operations_userid character varying(60)
);


--
--

CREATE TABLE tbls_deals_status_his (
    fin_id character varying(60) NOT NULL,
    deal_status_id character varying(60),
    fo_remarks character varying(255),
    setl_status_id character varying(60),
    bo_remarks character varying(255),
    shipping_status_id character varying(60),
    sh_remarks character varying(255),
    vault_status_id character varying(60),
    va_remarks character varying(255),
    is_deleted character varying(1) DEFAULT 'N'::character varying NOT NULL,
    created timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    created_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_updated timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_checked_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_maked timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_db timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    mod_id double precision DEFAULT 0 NOT NULL,
    maker_checker_status character varying(10) DEFAULT 'Maked'::character varying NOT NULL,
    shadow_id character varying(60) DEFAULT ''::character varying NOT NULL,
    operations_userid character varying(60)
);


--
--

CREATE TABLE tbls_dealwise_eod_pl (
    fin_id character varying(210) NOT NULL,
    deal_no character varying(60) NOT NULL,
    currency_id character varying(60),
    pl_date timestamp(0) without time zone,
    unrealized_pl numeric(21,2),
    realised_pl_today numeric(21,2),
    deal_value_date timestamp(6) without time zone,
    is_deleted character varying(1) DEFAULT 'N'::character varying NOT NULL,
    created timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    created_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_updated timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_checked_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_maked timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_db timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    mod_id double precision DEFAULT 0 NOT NULL,
    maker_checker_status character varying(10) DEFAULT 'Maked'::character varying NOT NULL,
    shadow_id character varying(210) DEFAULT ''::character varying NOT NULL,
    repository_id character varying(60),
    product_code character varying(60),
    product_id character varying(60),
    ud_deal_type_id character varying(60),
    mtm_rate numeric(21,11),
    leg_no double precision,
    version_no double precision,
    leg_vs_base_rate numeric(23,11),
    setl_vs_base_rate numeric(23,11),
    discount_factor_base_ccy numeric(21,11) DEFAULT 1,
    setl_vs_base_eod_rate numeric(23,11) DEFAULT 1
);


--
--

CREATE TABLE tbls_dealwise_eod_pl_his (
    fin_id character varying(210) NOT NULL,
    deal_no character varying(60) NOT NULL,
    currency_id character varying(60),
    pl_date timestamp(0) without time zone,
    unrealized_pl numeric(21,2),
    realised_pl_today numeric(21,2),
    deal_value_date timestamp(6) without time zone,
    is_deleted character varying(1) DEFAULT 'N'::character varying NOT NULL,
    created timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    created_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_updated timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_checked_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_maked timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_db timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    mod_id double precision DEFAULT 0 NOT NULL,
    maker_checker_status character varying(10) DEFAULT 'Maked'::character varying NOT NULL,
    shadow_id character varying(210) DEFAULT ''::character varying NOT NULL,
    repository_id character varying(60),
    product_code character varying(60),
    product_id character varying(60),
    ud_deal_type_id character varying(60),
    mtm_rate numeric(21,11),
    leg_no double precision,
    version_no double precision,
    leg_vs_base_rate numeric(23,11),
    setl_vs_base_rate numeric(23,11),
    discount_factor_base_ccy numeric(21,11) DEFAULT 1,
    setl_vs_base_eod_rate numeric(23,11) DEFAULT 1
);


--
--

CREATE TABLE tbls_disc_record_deal_int (
    fin_id character varying(99) NOT NULL,
    discrepancy_records_id character varying(60),
    discrepancy_deals_id character varying(60),
    discrepancy_type_id character varying(60),
    region_id character varying(60),
    is_deleted character varying(1) DEFAULT 'N'::character varying NOT NULL,
    created timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    created_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_updated timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_checked_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_maked timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_db timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    mod_id double precision DEFAULT 0 NOT NULL,
    maker_checker_status character varying(10) DEFAULT 'Maked'::character varying NOT NULL,
    shadow_id character varying(99) DEFAULT ''::character varying NOT NULL,
    discrepancy_record_legs_id character varying(99),
    discrepancy_deals_legs_id character varying(99),
    discrepancy_settlement_id character varying(60)
);


--
--

CREATE TABLE tbls_disc_settlement_methods (
    fin_id character varying(60) NOT NULL,
    code character varying(20),
    name character varying(50),
    regions_id character varying(60),
    is_deleted character varying(1) DEFAULT 'N'::character varying NOT NULL,
    created timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    created_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_updated timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_checked_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_maked timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_db timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    mod_id double precision DEFAULT 0 NOT NULL,
    maker_checker_status character varying(10) DEFAULT 'Maked'::character varying NOT NULL,
    shadow_id character varying(60) DEFAULT ''::character varying NOT NULL
);


--
--

CREATE TABLE tbls_discrepancy_record_legs (
    fin_id character varying(99) NOT NULL,
    leg_number double precision,
    currency_id character varying(60),
    note_denom_id character varying(60),
    note_type_id character varying(60),
    region_id character varying(60),
    is_deleted character varying(1) DEFAULT 'N'::character varying NOT NULL,
    created timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    created_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_updated timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_checked_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_maked timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_db timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    mod_id double precision DEFAULT 0 NOT NULL,
    maker_checker_status character varying(10) DEFAULT 'Maked'::character varying NOT NULL,
    shadow_id character varying(99) DEFAULT ''::character varying NOT NULL,
    amount numeric(21,2),
    remarks character varying(255),
    discrepancy_record_id character varying(60),
    outstanding_amount numeric(21,2),
    serial_no character varying(200)
);


--
--

CREATE TABLE tbls_discrepancy_records (
    fin_id character varying(60) NOT NULL,
    incurrence_date timestamp without time zone,
    discrepancy_type_id character varying(60),
    discrepancy_claim character varying(20),
    status_id character varying(60),
    sdi_id character varying(173),
    region_id character varying(60),
    is_deleted character varying(1) NOT NULL,
    created timestamp without time zone NOT NULL,
    created_by character varying(30) NOT NULL,
    last_updated timestamp without time zone NOT NULL,
    last_updated_by character varying(30) NOT NULL,
    last_checked_by character varying(30) NOT NULL,
    last_maked timestamp without time zone NOT NULL,
    last_updated_db timestamp without time zone NOT NULL,
    mod_id numeric(38,10) NOT NULL,
    maker_checker_status character varying(10) NOT NULL,
    shadow_id character varying(60) NOT NULL,
    discrepancy_contents bytea,
    remarks character varying(60),
    customers_id character varying(60),
    branches_id character varying(91),
    discrepancy_number character varying(60),
    shipment_records_id character varying(60),
    serial_no character varying(200),
    products_id character varying(60),
    action character varying(10),
    action_date timestamp without time zone,
    verification_date timestamp without time zone,
    repository_id character varying(60),
    entry_date timestamp without time zone,
    external_no character varying(60),
    version_no numeric(38,10),
    shipment_date timestamp without time zone,
    airway_bill_no character varying(30)
);


--
--

CREATE TABLE tbls_discrepancy_types (
    fin_id character varying(60) NOT NULL,
    code character varying(20),
    name character varying(50),
    nature character varying(50),
    plus_minus character(1),
    regions_id character varying(60),
    is_deleted character varying(1) DEFAULT 'N'::character varying NOT NULL,
    created timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    created_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_updated timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_checked_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_maked timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_db timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    mod_id double precision DEFAULT 0 NOT NULL,
    maker_checker_status character varying(10) DEFAULT 'Maked'::character varying NOT NULL,
    shadow_id character varying(60) DEFAULT ''::character varying NOT NULL
);


--
--

CREATE TABLE tbls_dl_order_source (
    fin_id character varying(60) NOT NULL,
    name character varying(60) NOT NULL,
    display_name character varying(60) NOT NULL,
    is_deleted character varying(1) DEFAULT 'N'::character varying NOT NULL,
    created timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    created_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_updated timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_checked_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_maked timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_db timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    mod_id double precision DEFAULT 0 NOT NULL,
    maker_checker_status character varying(10) DEFAULT 'Maked'::character varying NOT NULL,
    shadow_id character varying(60) DEFAULT ''::character varying NOT NULL,
    is_default character varying(1)
);


--
--

CREATE TABLE tbls_dly_acc_bal_tmp (
    fin_id character varying(60) NOT NULL,
    repository_id character varying(30),
    account_id character varying(60),
    sub_ledger character varying(60),
    account_name character varying(60),
    currency_id character varying(60),
    credit_debit character varying(1),
    amount numeric(21,2),
    reference_date timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    is_deleted character varying(1) DEFAULT 'N'::character varying NOT NULL,
    created timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    created_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_updated timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_checked_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_maked timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_db timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    mod_id double precision DEFAULT 0 NOT NULL,
    maker_checker_status character varying(10) DEFAULT 'Maked'::character varying NOT NULL,
    shadow_id character varying(60) DEFAULT ''::character varying NOT NULL,
    nostro character varying(81),
    ios_code character varying(10),
    opening_balance numeric(21,2),
    corp_code character varying(25),
    branch_code character varying(60),
    cost_center character varying(25),
    customer_types_id character varying(60),
    trial_balance_date timestamp(6) without time zone,
    sub_ledger_id character varying(162)
);


--
--

CREATE TABLE tbls_dly_accounting_balance (
    fin_id character varying(60) NOT NULL,
    repository_id character varying(30),
    account_id character varying(60),
    sub_ledger character varying(60),
    account_name character varying(60),
    currency_id character varying(60),
    credit_debit character varying(1),
    amount numeric(21,2),
    reference_date timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    is_deleted character varying(1) DEFAULT 'N'::character varying NOT NULL,
    created timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    created_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_updated timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_checked_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_maked timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_db timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    mod_id double precision DEFAULT 0 NOT NULL,
    maker_checker_status character varying(10) DEFAULT 'Maked'::character varying NOT NULL,
    shadow_id character varying(60) DEFAULT ''::character varying NOT NULL,
    nostro character varying(81),
    ios_code character varying(10),
    opening_balance numeric(21,2),
    corp_code character varying(25),
    branch_code character varying(60),
    cost_center character varying(25),
    customer_types_id character varying(60),
    trial_balance_date timestamp(6) without time zone,
    sub_ledger_id character varying(162)
);


--
--

CREATE TABLE tbls_dly_funding_op_bl_tmp (
    fin_id character varying(275) NOT NULL,
    repository_id character varying(60),
    product_id character varying(60),
    currency_id character varying(60),
    past_date timestamp(6) without time zone,
    funding_amount numeric(21,2),
    is_deleted character varying(1) DEFAULT 'N'::character varying NOT NULL,
    created timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    created_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_updated timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_checked_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_maked timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_db timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    mod_id double precision DEFAULT 0 NOT NULL,
    maker_checker_status character varying(10) DEFAULT 'Maked'::character varying NOT NULL,
    shadow_id character varying(275) DEFAULT ''::character varying NOT NULL,
    nostro character varying(81)
);


--
--

CREATE TABLE tbls_dly_fx_open_bal_tmp (
    fin_id character varying(193) NOT NULL,
    repository_id character varying(60),
    product_id character varying(60),
    currency_id character varying(60),
    past_date timestamp(6) without time zone,
    fx_opening_balance numeric(21,2),
    sigma_wr numeric(25,6),
    sigma_w numeric(21,2),
    is_deleted character varying(1) DEFAULT 'N'::character varying NOT NULL,
    created timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    created_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_updated timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_checked_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_maked timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_db timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    mod_id double precision DEFAULT 0 NOT NULL,
    maker_checker_status character varying(10) DEFAULT 'Maked'::character varying NOT NULL,
    shadow_id character varying(193) DEFAULT ''::character varying NOT NULL,
    cash_opening_balance numeric(21,2) DEFAULT 0,
    setl_opening_balance numeric(21,2) DEFAULT 0,
    last_closing_date timestamp(0) without time zone
);


--
--

CREATE TABLE tbls_dly_fx_opening_balance (
    fin_id character varying(193) NOT NULL,
    repository_id character varying(60),
    product_id character varying(60),
    currency_id character varying(60),
    past_date timestamp(6) without time zone,
    fx_opening_balance numeric(21,2),
    sigma_wr numeric(25,6),
    sigma_w numeric(21,2),
    is_deleted character varying(1) DEFAULT 'N'::character varying NOT NULL,
    created timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    created_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_updated timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_checked_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_maked timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_db timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    mod_id double precision DEFAULT 0 NOT NULL,
    maker_checker_status character varying(10) DEFAULT 'Maked'::character varying NOT NULL,
    shadow_id character varying(193) DEFAULT ''::character varying NOT NULL,
    cash_opening_balance numeric(21,2) DEFAULT 0,
    setl_opening_balance numeric(21,2) DEFAULT 0,
    last_closing_date timestamp(0) without time zone
);


--
--

CREATE TABLE tbls_document_modes (
    fin_id character varying(86) NOT NULL,
    region_id character varying(60),
    is_deleted character varying(1) DEFAULT 'N'::character varying NOT NULL,
    created timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    created_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_updated timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_checked_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_maked timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_db timestamp(6) without time zone DEFAULT clock_timestamp(),
    mod_id double precision DEFAULT 0 NOT NULL,
    maker_checker_status character varying(10) DEFAULT 'Maked'::character varying NOT NULL,
    shadow_id character varying(86) DEFAULT ''::character varying NOT NULL,
    shipment_types_id character varying(60),
    document_mode character varying(25)
);


--
--

CREATE TABLE tbls_email_configuration (
    fin_id character varying(60) NOT NULL,
    workflow_state character varying(30),
    object_module character varying(30),
    event character varying(30),
    individual_aggregate character varying(30),
    static_dynamic character varying(30),
    sender_id character varying(30),
    to_list character varying(500),
    cc_list character varying(500),
    email_subject character varying(100),
    email_content character varying(500),
    email_template character varying(50),
    email_attachment character varying(50),
    is_deleted character varying(1) DEFAULT 'N'::character varying NOT NULL,
    created timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    created_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_updated timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_checked_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_maked timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_db timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    mod_id double precision DEFAULT 0 NOT NULL,
    maker_checker_status character varying(10) DEFAULT 'Maked'::character varying NOT NULL,
    shadow_id character varying(61) DEFAULT ''::character varying NOT NULL
);


--
--

CREATE TABLE tbls_eod_progress (
    fin_id character varying(60) NOT NULL,
    process_name character varying(60),
    description character varying(100),
    status character varying(10),
    start_time timestamp without time zone,
    end_time timestamp without time zone,
    eod_date timestamp without time zone,
    eod_process character varying(25),
    dependent_on character varying(400),
    exceptions text,
    saturday_run character varying(10),
    shadow_id character varying(60),
    is_deleted character varying(1) NOT NULL,
    created timestamp without time zone NOT NULL,
    created_by character varying(30) NOT NULL,
    last_updated timestamp without time zone NOT NULL,
    last_updated_by character varying(30) NOT NULL,
    last_checked_by character varying(30) NOT NULL,
    last_maked timestamp without time zone NOT NULL,
    last_updated_db timestamp without time zone NOT NULL,
    mod_id numeric(38,10) NOT NULL,
    maker_checker_status character varying(10) NOT NULL
);


--
--

CREATE TABLE tbls_eod_sanity_checks (
    fin_id character varying(60) NOT NULL,
    eod_sequence character varying(100),
    description character varying(300),
    method_name character varying(60),
    sql_query character varying(1800),
    report_header character varying(1000),
    status character varying(60),
    output_file_path character varying(300),
    execution_date timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    pre_post_eod character varying(10),
    is_deleted character varying(1) DEFAULT 'N'::character varying NOT NULL,
    created timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    created_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_updated timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_checked_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_maked timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_db timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    mod_id numeric DEFAULT 0 NOT NULL,
    maker_checker_status character varying(10) DEFAULT 'COMMITTED'::character varying NOT NULL,
    shadow_id character varying(60) DEFAULT ''::character varying NOT NULL,
    field_count numeric(15,5)
);


--
--

CREATE TABLE tbls_ermctc_report (
    fin_id character varying(60) NOT NULL,
    reporting_date timestamp(6) without time zone DEFAULT clock_timestamp(),
    regions_id character varying(60) NOT NULL,
    repositories_id character varying(60) NOT NULL,
    currency_id character varying(60),
    eod_fundingbal_fc numeric(23,2),
    ctc_rate numeric(21,11),
    daily_ctcbal_fc numeric(23,2),
    mtd_ctcbal_fc numeric(23,2),
    ytd_ctcbal_fc numeric(23,2),
    daily_ctcbal_lc numeric(23,2),
    mtd_ctcbal_lc numeric(23,2),
    ytd_ctcbal_lc numeric(23,2),
    daily_charge_fc numeric(23,2),
    mtd_charge_fc numeric(23,2),
    ytd_charge_fc numeric(23,2),
    daily_charge_lc numeric(23,2),
    mtd_charge_lc numeric(23,2),
    ytd_charge_lc numeric(23,2),
    daily_commission_fc numeric(23,2),
    mtd_commission_fc numeric(23,2),
    ytd_commission_fc numeric(23,2),
    daily_commission_lc numeric(23,2),
    mtd_commission_lc numeric(23,2),
    ytd_commission_lc numeric(23,2),
    daily_overage_fc numeric(23,2),
    mtd_overage_fc numeric(23,2),
    ytd_overage_fc numeric(23,2),
    daily_overage_lc numeric(23,2),
    mtd_overage_lc numeric(23,2),
    ytd_overage_lc numeric(23,2),
    daily_shortage_fc numeric(23,2),
    mtd_shortage_fc numeric(23,2),
    ytd_shortage_fc numeric(23,2),
    daily_shortage_lc numeric(23,2),
    mtd_shortage_lc numeric(23,2),
    ytd_shortage_lc numeric(23,2),
    daily_writeoff_bal_fc numeric(23,2),
    mtd_writeoff_bal_fc numeric(23,2),
    ytd_writeoff_bal_fc numeric(23,2),
    daily_writeoff_bal_lc numeric(23,2),
    mtd_writeoff_bal_lc numeric(23,2),
    ytd_writeoff_bal_lc numeric(23,2),
    fctolc_rate numeric(21,11),
    is_deleted character varying(1) DEFAULT 'N'::character varying NOT NULL,
    created timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    created_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_updated timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_checked_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_maked timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_db timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    mod_id double precision DEFAULT 0 NOT NULL,
    maker_checker_status character varying(10) DEFAULT 'Maked'::character varying NOT NULL,
    shadow_id character varying(60) DEFAULT ''::character varying NOT NULL
);


--
--

CREATE TABLE tbls_ext_cons_brnch_map (
    fin_id character varying(91) NOT NULL,
    ext_consignee_code character varying(60),
    ext_branch_code character varying(30),
    branches_id character varying(91) NOT NULL,
    is_deleted character varying(1) DEFAULT 'N'::character varying NOT NULL,
    created timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    created_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_updated timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_checked_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_maked timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_db timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    mod_id double precision DEFAULT 0 NOT NULL,
    maker_checker_status character varying(10) DEFAULT 'Maked'::character varying NOT NULL,
    shadow_id character varying(60) DEFAULT ''::character varying NOT NULL
);


--
--

CREATE TABLE tbls_functions (
    fin_id character varying(121) NOT NULL,
    name character varying(60),
    group_id character varying(60),
    maker_checker_required character(1),
    parent_id character varying(100) DEFAULT 0 NOT NULL,
    display_name character varying(50),
    is_deleted character varying(1) DEFAULT 'N'::character varying NOT NULL,
    created timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    created_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_updated timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_checked_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_maked timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_db timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    mod_id double precision DEFAULT 0 NOT NULL,
    maker_checker_status character varying(10) DEFAULT 'Maked'::character varying NOT NULL,
    shadow_id character varying(121) DEFAULT ''::character varying NOT NULL,
    process_method character varying(200),
    sort_order numeric(15,5),
    hot_key character varying(25),
    display_menu character varying(25)
);


--
--

CREATE TABLE tbls_funding_positions (
    fin_id character varying(275) NOT NULL,
    repository_id character varying(60),
    currency_id character varying(60),
    product_id character varying(60),
    value_date timestamp(6) without time zone,
    funding_amount numeric(21,2),
    is_deleted character varying(1) DEFAULT 'N'::character varying NOT NULL,
    created timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    created_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_updated timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_checked_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_maked timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_db timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    mod_id double precision DEFAULT 0 NOT NULL,
    maker_checker_status character varying(10) DEFAULT 'Maked'::character varying NOT NULL,
    shadow_id character varying(275) DEFAULT ''::character varying NOT NULL,
    nostro character varying(81)
);


--
--

CREATE TABLE tbls_fx_deals (
    fin_id character varying(99) NOT NULL,
    deal_versions_id character varying(99),
    value_date timestamp(6) without time zone DEFAULT clock_timestamp(),
    pair_id character varying(60),
    buy_sell character varying(10),
    buy_currency_id character varying(60),
    buy_amount numeric(21,2),
    sell_currency_id character varying(60),
    sell_amount numeric(21,2),
    usd_rate_vs_sell_cur numeric(21,11),
    usd_rate_vs_buy_cur numeric(21,11),
    usd_rate_vs_base_cur numeric(21,11),
    pl_amount numeric(21,2),
    spot_rate numeric(21,11),
    deal_rate numeric(21,11),
    nondeliverable character(1),
    fixingdate timestamp(6) without time zone,
    fixingrate numeric(21,11),
    external_no character varying(60),
    external_other_no character varying(60),
    is_deleted character varying(1) DEFAULT 'N'::character varying NOT NULL,
    created timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    created_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_updated timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_checked_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_maked timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_db timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    mod_id double precision DEFAULT 0 NOT NULL,
    maker_checker_status character varying(10) DEFAULT 'Maked'::character varying NOT NULL,
    shadow_id character varying(99) DEFAULT ''::character varying NOT NULL
);


--
--

CREATE TABLE tbls_fx_overnight_limits (
    fin_id character varying(60) NOT NULL,
    currencies_id character varying(60),
    on_limit double precision,
    is_deleted character varying(1) DEFAULT 'N'::character varying NOT NULL,
    created timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    created_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_updated timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_checked_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_maked timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_db timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    mod_id double precision DEFAULT 0 NOT NULL,
    maker_checker_status character varying(10) DEFAULT 'Maked'::character varying NOT NULL,
    shadow_id character varying(60) DEFAULT ''::character varying NOT NULL
);


--
--

CREATE TABLE tbls_fx_positions (
    fin_id character varying(193) NOT NULL,
    repository_id character varying(60),
    products_code character varying(60),
    currency_id character varying(60),
    value_date timestamp(0) without time zone,
    fx_pos_amount numeric(21,2),
    sigma_wr numeric(25,6),
    sigma_w numeric(21,2),
    is_deleted character varying(1) DEFAULT 'N'::character varying NOT NULL,
    created timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    created_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_updated timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_checked_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_maked timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_db timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    mod_id double precision DEFAULT 0 NOT NULL,
    maker_checker_status character varying(10) DEFAULT 'Maked'::character varying NOT NULL,
    shadow_id character varying(193) DEFAULT ''::character varying NOT NULL,
    cash_pos_amt numeric(21,2) DEFAULT 0,
    setl_pos_amt numeric(21,2) DEFAULT 0
);


--
--

CREATE TABLE tbls_fx_positions_history (
    fin_id character varying(204) NOT NULL,
    repository_id character varying(60),
    products_code character varying(60),
    currency_id character varying(60),
    value_date timestamp(0) without time zone,
    fx_pos_amount numeric(21,2),
    sigma_wr numeric(25,6),
    sigma_w numeric(21,2),
    reference_date timestamp(0) without time zone,
    is_deleted character varying(1) DEFAULT 'N'::character varying NOT NULL,
    created timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    created_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_updated timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_checked_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_maked timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_db timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    mod_id double precision DEFAULT 0 NOT NULL,
    maker_checker_status character varying(10) DEFAULT 'Maked'::character varying NOT NULL,
    shadow_id character varying(204) DEFAULT ''::character varying NOT NULL,
    cash_pos_amt numeric(21,2) DEFAULT 0,
    setl_pos_amt numeric(21,2) DEFAULT 0
);


--
--

CREATE TABLE tbls_fxforward_rates (
    fin_id character varying(230) NOT NULL,
    mkt_date timestamp(6) without time zone DEFAULT clock_timestamp(),
    system_codes_id character varying(60),
    rate_type character varying(20),
    currencypairs_id character varying(60),
    forward_date timestamp(6) without time zone DEFAULT clock_timestamp(),
    bid_rate numeric(21,11),
    ask_rate numeric(21,11),
    region_id character varying(60),
    data_set_name character varying(60),
    is_deleted character varying(1),
    created timestamp(6) without time zone DEFAULT clock_timestamp(),
    created_by character varying(30),
    last_updated timestamp(6) without time zone DEFAULT clock_timestamp(),
    last_updated_by character varying(30),
    last_checked_by character varying(30),
    last_maked timestamp(6) without time zone DEFAULT clock_timestamp(),
    last_updated_db timestamp(6) without time zone DEFAULT clock_timestamp(),
    mod_id double precision,
    maker_checker_status character varying(10),
    shadow_id character varying(230) DEFAULT 0,
    tenor character varying(25),
    source_system character varying(20)
);


--
--

CREATE TABLE tbls_fxforward_rates_his (
    fin_id character varying(230) NOT NULL,
    mkt_date timestamp(6) without time zone DEFAULT clock_timestamp(),
    system_codes_id character varying(60),
    rate_type character varying(20),
    currencypairs_id character varying(60),
    forward_date timestamp(6) without time zone DEFAULT clock_timestamp(),
    bid_rate numeric(21,11),
    ask_rate numeric(21,11),
    region_id character varying(60),
    data_set_name character varying(60),
    is_deleted character varying(1),
    created timestamp(6) without time zone DEFAULT clock_timestamp(),
    created_by character varying(30),
    last_updated timestamp(6) without time zone DEFAULT clock_timestamp(),
    last_updated_by character varying(30),
    last_checked_by character varying(30),
    last_maked timestamp(6) without time zone DEFAULT clock_timestamp(),
    last_updated_db timestamp(6) without time zone DEFAULT clock_timestamp(),
    mod_id double precision,
    maker_checker_status character varying(10),
    shadow_id character varying(230) DEFAULT 0,
    tenor character varying(25)
);


--
--

CREATE TABLE tbls_fxnopvol_hist (
    fin_id character varying(60) NOT NULL,
    bank_notes_deals_legs_id character varying(149),
    buy_amount numeric(21,2),
    sell_amount numeric(21,2),
    buy_currency character varying(60),
    sell_currency character varying(60),
    closing_rate numeric(21,11),
    action character varying(10),
    reversal_status character varying(10),
    fxnopvol_hist_id numeric(15,5),
    system_date timestamp(0) without time zone NOT NULL,
    deal_no character varying(60) NOT NULL,
    is_deleted character varying(1) DEFAULT 'N'::character varying NOT NULL,
    created timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    created_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_updated timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_checked_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_maked timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_db timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    mod_id double precision DEFAULT 0 NOT NULL,
    maker_checker_status character varying(10) DEFAULT 'COMMITTED'::character varying NOT NULL,
    shadow_id character varying(60) DEFAULT ''::character varying NOT NULL
);


--
--

CREATE TABLE tbls_fxspot_rates (
    fin_id character varying(182) NOT NULL,
    mkt_date timestamp(6) without time zone DEFAULT clock_timestamp(),
    system_codes_id character varying(60),
    currencypair_id character varying(60),
    data_set_id character varying(60),
    bid_rate numeric(21,11),
    ask_rate numeric(21,11),
    mid_rate numeric(21,11),
    region_id character varying(60),
    is_deleted character varying(1) DEFAULT 'N'::character varying NOT NULL,
    created timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    created_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_updated timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_checked_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_maked timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_db timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    mod_id double precision DEFAULT 0 NOT NULL,
    maker_checker_status character varying(10) DEFAULT 'Maked'::character varying NOT NULL,
    shadow_id character varying(182) DEFAULT ''::character varying NOT NULL
);


--
--

CREATE TABLE tbls_gl_recon_input (
    fin_id character varying(60) NOT NULL,
    eod_date timestamp(0) without time zone,
    corp_code character varying(10),
    branch_code character varying(10),
    cost_center character varying(10),
    gl_acc_number character varying(10),
    account_desc character varying(30),
    currency character varying(60),
    ytd_balance_fc numeric(23,2),
    local_ccy character varying(60),
    ytd_balance_lc numeric(23,2),
    shadow_id character varying(60) DEFAULT '-1'::character varying
);


--
--

CREATE TABLE tbls_global_bnc (
    fin_id character varying(60) NOT NULL,
    cust_fin_id character varying(60) NOT NULL,
    brch_short_name character varying(30),
    is_deleted character varying(1) DEFAULT 'N'::character varying NOT NULL,
    created timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    created_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_updated timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_checked_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_maked timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_db timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    mod_id double precision DEFAULT 0 NOT NULL,
    maker_checker_status character varying(10) DEFAULT 'Maked'::character varying NOT NULL,
    shadow_id character varying(60) DEFAULT ''::character varying NOT NULL
);


--
--

CREATE TABLE tbls_hist_vol_aml (
    fin_id character varying(60) NOT NULL,
    customers_id character varying(60) NOT NULL,
    branches_id character varying(91) NOT NULL,
    year_month character varying(10) NOT NULL,
    month_type character varying(10) NOT NULL,
    volume_cur_id character varying(60) NOT NULL,
    volume numeric(21,2) DEFAULT 0,
    is_deleted character varying(1) DEFAULT 'N'::character varying NOT NULL,
    created timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    created_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_updated timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_checked_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_maked timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_db timestamp(6) without time zone DEFAULT clock_timestamp(),
    mod_id double precision DEFAULT 0 NOT NULL,
    maker_checker_status character varying(10) DEFAULT 'Maked'::character varying NOT NULL,
    shadow_id character varying(60) DEFAULT ''::character varying NOT NULL,
    buy_sell character varying(10),
    volume_actual numeric(21,2) DEFAULT 0,
    products_code character varying(60) NOT NULL
);


--
--

CREATE TABLE tbls_hist_vol_aml_int (
    fin_id character varying(60) NOT NULL,
    deal_versions_id character varying(99) NOT NULL,
    leg_number numeric(10,0),
    customers_id character varying(60) NOT NULL,
    branches_id character varying(91) NOT NULL,
    buy_sell character varying(10),
    year_month character varying(10) NOT NULL,
    month_type character varying(10) NOT NULL,
    volume_cur_id character varying(60) NOT NULL,
    volume numeric(21,2) DEFAULT 0,
    action character varying(60) NOT NULL,
    plus_minus character varying(10) NOT NULL,
    process_date timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    is_deleted character varying(1) DEFAULT 'N'::character varying NOT NULL,
    created timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    created_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_updated timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_checked_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_maked timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_db timestamp(6) without time zone DEFAULT clock_timestamp(),
    mod_id double precision DEFAULT 0 NOT NULL,
    maker_checker_status character varying(10) DEFAULT 'Maked'::character varying NOT NULL,
    shadow_id character varying(60) DEFAULT ''::character varying NOT NULL,
    volume_actual numeric(21,2) DEFAULT 0,
    products_code character varying(60) NOT NULL
);


--
--

CREATE TABLE tbls_history_cust_cmprision (
    fin_id character varying(342) NOT NULL,
    country character varying(120) NOT NULL,
    client_id double precision NOT NULL,
    client_name character varying(91) NOT NULL,
    year character varying(4) NOT NULL,
    month character varying(2) NOT NULL,
    currency character varying(60) NOT NULL,
    total_buy_amt_native numeric(21,2),
    total_buy_amt_usd numeric(21,2),
    total_sell_amt_native numeric(21,2),
    total_sell_amt_usd numeric(21,2),
    quarter character varying(2) NOT NULL,
    is_deleted character varying(1),
    created timestamp(0) without time zone,
    created_by character varying(60),
    last_updated timestamp(0) without time zone,
    last_updated_by character varying(60),
    last_checked_by character varying(60),
    last_maked timestamp(0) without time zone,
    last_updated_db timestamp(0) without time zone,
    mod_id numeric(15,5),
    maker_checker_status character varying(10),
    shadow_id character varying(342),
    product_code character varying(60),
    branches_id character varying(91) NOT NULL
);


--
--

CREATE TABLE tbls_houskeep_cfg (
    fin_id character varying(50) NOT NULL,
    src_table character varying(50) NOT NULL,
    dest_table character varying(50) NOT NULL,
    field_id character varying(50) NOT NULL,
    housekeep_dtl character varying(50) NOT NULL,
    where_clause character varying(50) NOT NULL,
    type_of_data character varying(50) NOT NULL
);


--
--

CREATE TABLE tbls_import_bnk_deals_legs (
    fin_id character varying(200) NOT NULL,
    batch_no character varying(200),
    rec_no character varying(200),
    deal_no character varying(200),
    col1 character varying(200),
    col2 character varying(200),
    col3 character varying(200),
    col4 character varying(200),
    col5 character varying(200),
    col6 character varying(200),
    col7 character varying(200),
    col8 character varying(200),
    col9 character varying(200),
    col10 character varying(200),
    col11 character varying(200),
    col12 character varying(200),
    col13 character varying(200),
    bigcol1 character varying(500),
    bigcol2 character varying(500),
    col14 character varying(200),
    col15 character varying(200),
    col16 character varying(200),
    col17 character varying(200),
    col18 character varying(200),
    col19 character varying(200),
    col20 character varying(200),
    col21 character varying(200),
    col22 character varying(200),
    col23 character varying(200),
    col24 character varying(200),
    col25 character varying(200),
    col26 character varying(200),
    col27 character varying(200),
    col28 character varying(200),
    col29 character varying(200),
    col30 character varying(200),
    col31 character varying(200),
    col32 character varying(200),
    col33 character varying(200),
    col34 character varying(200),
    col35 character varying(200),
    col36 character varying(200),
    col37 character varying(200),
    col38 character varying(200),
    col39 character varying(200),
    col40 character varying(200),
    col41 character varying(200),
    col42 character varying(200),
    col43 character varying(200),
    col44 character varying(200),
    col45 character varying(200),
    col46 character varying(200),
    col47 character varying(200),
    col48 character varying(200),
    col49 character varying(200),
    col50 character varying(200),
    col51 character varying(200),
    col52 character varying(200),
    col53 character varying(200),
    col54 character varying(200),
    col55 character varying(200),
    col56 character varying(200),
    col57 character varying(200),
    col58 character varying(200),
    col59 character varying(200),
    col60 character varying(200),
    col61 character varying(200),
    col62 character varying(200),
    col63 character varying(200),
    is_deleted character varying(1) DEFAULT 'N'::character varying NOT NULL,
    created timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    created_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_updated timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_checked_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_maked timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_db timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    mod_id double precision DEFAULT 0 NOT NULL,
    maker_checker_status character varying(10) DEFAULT 'Maked'::character varying NOT NULL,
    shadow_id character varying(200) DEFAULT ''::character varying NOT NULL,
    col64 character varying(60),
    col65 character varying(60),
    errormsg character varying(1000),
    external_deal_no character varying(60),
    is_imported character varying(3),
    upload_type character varying(60)
);


--
--

CREATE TABLE tbls_import_column_config (
    fin_id character varying(100) NOT NULL,
    template_id character varying(60),
    header character varying(60),
    csv_header character varying(60),
    data_type character varying(100),
    is_deleted character varying(1) DEFAULT 'N'::character varying NOT NULL,
    created timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    created_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_updated timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_checked_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_maked timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_db timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    mod_id double precision DEFAULT 0 NOT NULL,
    maker_checker_status character varying(10) DEFAULT 'Maked'::character varying NOT NULL,
    shadow_id character varying(100) DEFAULT ''::character varying NOT NULL
);


--
--

CREATE TABLE tbls_import_properties (
    fin_id character varying(100) NOT NULL,
    parent_id character varying(60),
    type character varying(60),
    sub_type character varying(60),
    comments character varying(100),
    property_name character varying(60),
    property_value character varying(60),
    is_deleted character varying(1) DEFAULT 'N'::character varying NOT NULL,
    created timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    created_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_updated timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_checked_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_maked timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_db timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    mod_id double precision DEFAULT 0 NOT NULL,
    maker_checker_status character varying(10) DEFAULT 'Maked'::character varying NOT NULL,
    shadow_id character varying(100) DEFAULT ''::character varying NOT NULL,
    root_id character varying(60)
);


--
--

CREATE TABLE tbls_import_template_config (
    fin_id character varying(100) NOT NULL,
    name character varying(60),
    template_id character varying(60),
    is_deleted character varying(1) DEFAULT 'N'::character varying NOT NULL,
    created timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    created_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_updated timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_checked_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_maked timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_db timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    mod_id double precision DEFAULT 0 NOT NULL,
    maker_checker_status character varying(10) DEFAULT 'Maked'::character varying NOT NULL,
    shadow_id character varying(100) DEFAULT ''::character varying NOT NULL
);


--
--

CREATE TABLE tbls_insurance_config (
    fin_id character varying(487) NOT NULL,
    origin_airports_id character varying(182) NOT NULL,
    destination_airports_id character varying(182) NOT NULL,
    shipment_provider character varying(60) NOT NULL,
    shipment_basis_id character varying(60),
    insurance_provider character varying(60),
    is_deleted character varying(1) DEFAULT 'N'::character varying NOT NULL,
    created timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    created_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_updated timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_checked_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_maked timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_db timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    mod_id double precision DEFAULT 0 NOT NULL,
    maker_checker_status character varying(10) DEFAULT 'Maked'::character varying NOT NULL,
    shadow_id character varying(487) DEFAULT ''::character varying NOT NULL,
    shipment_arrangements_id character varying(60),
    shipment_methods_id character varying(60)
);


--
--

CREATE TABLE tbls_intf_acc_add_recon_log (
    fin_id character varying(25) NOT NULL,
    account_no character varying(60),
    old_address_cif_no character varying(60),
    new_address_cif_no character varying(60),
    old_address_seq_no character varying(60),
    new_address_seq_no character varying(60),
    error_code character varying(60),
    error_desc character varying(600),
    is_deleted character varying(1) DEFAULT 'N'::character varying NOT NULL,
    created timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    created_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_updated timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_checked_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_maked timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_db timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    mod_id double precision DEFAULT 0 NOT NULL,
    maker_checker_status character varying(10) DEFAULT 'Maked'::character varying NOT NULL,
    shadow_id character varying(25) DEFAULT ''::character varying NOT NULL,
    log_date timestamp(0) without time zone
);


--
--

CREATE TABLE tbls_intf_cus_demo_recon_log (
    fin_id character varying(60) NOT NULL,
    cif_number character varying(60),
    counterparty_name1 character varying(91),
    counterparty_name2 character varying(91),
    id_number character varying(60),
    is_deleted character varying(1) DEFAULT 'N'::character varying NOT NULL,
    created timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    created_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_updated timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_checked_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_maked timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_db timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    mod_id double precision DEFAULT 0 NOT NULL,
    maker_checker_status character varying(10) DEFAULT 'Maked'::character varying NOT NULL,
    shadow_id character varying(60) DEFAULT ''::character varying NOT NULL,
    mas_code character varying(60),
    country_of_incorporation character varying(120),
    country_of_ops character varying(120),
    mas_industry_code character varying(60),
    hkma_code character varying(60),
    cust_class character varying(60),
    error_code character varying(60),
    error_desc character varying(1000),
    log_date timestamp(0) without time zone,
    id_type character varying(25),
    id_issue_country_code character varying(25),
    incorporation_date character varying(60)
);


--
--

CREATE TABLE tbls_irr_config (
    fin_id character varying(60) NOT NULL,
    deal_grouping character varying(60),
    product_code character varying(60),
    deal_type character varying(60),
    ud_deal_type character varying(60),
    like_unlike character varying(60),
    buy_sell character varying(60),
    positive_negative character varying(10),
    report_amount character varying(60),
    is_deleted character varying(1) DEFAULT 'N'::character varying NOT NULL,
    created timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    created_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_updated timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_checked_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_maked timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_db timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    mod_id double precision DEFAULT 0 NOT NULL,
    maker_checker_status character varying(10) DEFAULT 'Maked'::character varying NOT NULL,
    shadow_id character varying(60) DEFAULT ''::character varying NOT NULL
);


--
--

CREATE TABLE tbls_irr_config_pay_rec (
    fin_id character varying(60) NOT NULL,
    deal_grouping character varying(60),
    product_code character varying(60),
    deal_type character varying(60),
    ud_deal_type character varying(60),
    like_unlike character varying(60),
    buy_sell character varying(60),
    positive_negative character varying(10),
    report_amount character varying(60),
    is_deleted character varying(1) DEFAULT 'N'::character varying NOT NULL,
    created timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    created_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_updated timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_checked_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_maked timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_db timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    mod_id double precision DEFAULT 0 NOT NULL,
    maker_checker_status character varying(10) DEFAULT 'Maked'::character varying NOT NULL,
    shadow_id character varying(60) DEFAULT ''::character varying NOT NULL,
    rule_type character varying(100),
    todate character varying(50),
    fromdate character varying(50)
);


--
--

CREATE TABLE tbls_it2_recon_input (
    fin_id character varying(30),
    user_ref character varying(60),
    deal_input_date timestamp(6) without time zone DEFAULT clock_timestamp(),
    recon_date timestamp(6) without time zone DEFAULT clock_timestamp(),
    branch_id character varying(20),
    company character varying(20),
    currency character varying(3),
    amount numeric(23,2)
);


--
--

CREATE TABLE tbls_like_like_base_pl_acc (
    fin_id character varying(210) NOT NULL,
    totalpl numeric(21,2),
    typeofpl character varying(60),
    pl_date timestamp(0) without time zone,
    product_code character varying(60),
    currencies_id character varying(60),
    repository character varying(60),
    is_deleted character varying(1) DEFAULT 'N'::character varying NOT NULL,
    created timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    created_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_updated timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_checked_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_maked timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_db timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    mod_id double precision DEFAULT 0 NOT NULL,
    maker_checker_status character varying(10) DEFAULT 'Maked'::character varying NOT NULL,
    shadow_id character varying(121) DEFAULT ''::character varying NOT NULL,
    reverse_pl double precision,
    pl double precision
);


--
--

CREATE TABLE tbls_limits_breach (
    fin_id character varying(60) NOT NULL,
    deal_no character varying(60),
    cels_code character varying(20),
    remarks character varying(100),
    breach_date timestamp(6) without time zone DEFAULT clock_timestamp(),
    breach_amount numeric(21,2),
    nearest_bucket_breached character varying(12),
    limit_type_id character varying(60),
    allocated_amount numeric(21,2),
    reallocated_amount numeric(21,2),
    utilised_amount numeric(21,2),
    is_override character(1),
    user_id character varying(60),
    region_id character varying(60),
    product_id character varying(60),
    currency_id character varying(60),
    breach_utilisation_date timestamp(6) without time zone DEFAULT clock_timestamp(),
    is_deleted character varying(1) DEFAULT 'N'::character varying NOT NULL,
    created timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    created_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_updated timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_checked_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_maked timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_db timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    mod_id double precision DEFAULT 0 NOT NULL,
    maker_checker_status character varying(10) DEFAULT 'Maked'::character varying NOT NULL,
    shadow_id character varying(60) DEFAULT ''::character varying NOT NULL,
    version_no character varying(30),
    deal_impacted character varying(60),
    products_code character varying(60),
    is_artificial_tenor character varying(10),
    prior_utilised_amount numeric(21,2),
    borrowed_amount numeric(21,2) DEFAULT 0 NOT NULL,
    split_info character varying(2000)
);


--
--

CREATE TABLE tbls_limits_breach_data (
    fin_id character varying(120) NOT NULL,
    limits_breach_id character varying(60),
    deal_no character varying(60),
    cels_code character varying(20),
    tenor character varying(100),
    split_info character varying(2000),
    remarks character varying(100),
    breach_date timestamp(6) without time zone DEFAULT clock_timestamp(),
    tenor_start_date timestamp(6) without time zone DEFAULT clock_timestamp(),
    tenor_end_date timestamp(6) without time zone DEFAULT clock_timestamp(),
    split_start_date timestamp(6) without time zone DEFAULT clock_timestamp(),
    split_end_date timestamp(6) without time zone DEFAULT clock_timestamp(),
    breach_amount numeric(21,2),
    nearest_bucket_breached character varying(12),
    limit_type_id character varying(60),
    allocated_amount numeric(21,2),
    reallocated_amount numeric(21,2),
    borrowed_amount numeric(21,2) DEFAULT 0 NOT NULL,
    utilised_amount numeric(21,2),
    is_override character(1),
    user_id character varying(60),
    region_id character varying(60),
    product_id character varying(60),
    currency_id character varying(60),
    breach_utilisation_date timestamp(6) without time zone DEFAULT clock_timestamp(),
    is_deleted character varying(1) DEFAULT 'N'::character varying NOT NULL,
    created timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    created_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_updated timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_checked_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_maked timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_db timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    mod_id double precision DEFAULT 0 NOT NULL,
    maker_checker_status character varying(10) DEFAULT 'Maked'::character varying NOT NULL,
    shadow_id character varying(60) DEFAULT ''::character varying NOT NULL,
    version_no character varying(30),
    deal_impacted character varying(60),
    products_code character varying(60),
    is_artificial_tenor character varying(10),
    prior_utilised_amount numeric(21,2)
);


--
--

CREATE TABLE tbls_limits_breach_ear (
    fin_id character varying(120) NOT NULL,
    limits_breach_data_id character varying(100),
    limits_override_id character varying(100),
    is_deleted character varying(1) DEFAULT 'N'::character varying NOT NULL,
    created timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    created_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_updated timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_checked_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_maked timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_db timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    mod_id double precision DEFAULT 0 NOT NULL,
    maker_checker_status character varying(10) DEFAULT 'Maked'::character varying NOT NULL,
    shadow_id character varying(60) DEFAULT ''::character varying NOT NULL
);


--
--

CREATE TABLE tbls_limits_exclusion (
    fin_id character varying(60) NOT NULL,
    buy_sell character(1) NOT NULL,
    customers_id character varying(60) NOT NULL,
    limit_type character varying(60) NOT NULL,
    products_id character varying(60) NOT NULL,
    sub_type character varying(60) NOT NULL,
    status character varying(60) NOT NULL,
    remarks character varying(500),
    is_deleted character varying(1) DEFAULT 'N'::character varying NOT NULL,
    created timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    created_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_updated timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_checked_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_maked timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_db timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    mod_id double precision DEFAULT 0 NOT NULL,
    maker_checker_status character varying(10) DEFAULT 'Maked'::character varying NOT NULL,
    shadow_id character varying(60) DEFAULT ''::character varying NOT NULL
);


--
--

CREATE TABLE tbls_limits_override (
    fin_id character varying(60) NOT NULL,
    ref_no character varying(20) NOT NULL,
    limit_type character varying(60) NOT NULL,
    cels_code character varying(60) NOT NULL,
    entry_date timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    start_date timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    end_date timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    status character varying(60) NOT NULL,
    cancelled_by character varying(60),
    cancellation_date timestamp(6) without time zone,
    amount numeric(21,2) DEFAULT 0 NOT NULL,
    remarks character varying(500),
    is_deleted character varying(1) DEFAULT 'N'::character varying NOT NULL,
    created timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    created_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_updated timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_checked_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_maked timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_db timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    mod_id double precision DEFAULT 0 NOT NULL,
    maker_checker_status character varying(10) DEFAULT 'Maked'::character varying NOT NULL,
    shadow_id character varying(60) DEFAULT ''::character varying NOT NULL,
    creation_verified_by character varying(60),
    creation_verified_date timestamp(6) without time zone,
    cancellation_verified_by character varying(60),
    cancellation_verified_date timestamp(6) without time zone,
    cancellation_remarks character varying(255)
);


--
--

CREATE TABLE tbls_limits_tenor_def (
    fin_id character varying(60) NOT NULL,
    regions_id character varying(60),
    code character varying(60),
    name character varying(60),
    offset_unit character varying(20),
    offset_from numeric(10,0),
    offset_to numeric(10,0),
    sign character varying(60),
    discontinued character varying(10),
    is_deleted character varying(1) DEFAULT 'N'::character varying NOT NULL,
    created timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    created_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_updated timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_checked_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_maked timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_db timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    mod_id double precision DEFAULT 0 NOT NULL,
    maker_checker_status character varying(10) DEFAULT 'Maked'::character varying NOT NULL,
    shadow_id character varying(60) DEFAULT ''::character varying NOT NULL
);


--
--

CREATE TABLE tbls_limits_utilisation (
    fin_id character varying(180) NOT NULL,
    region_id character varying(60),
    deal_no character varying(60),
    version_no numeric(21,2) NOT NULL,
    cels_code character varying(20) NOT NULL,
    products_code character varying(60) NOT NULL,
    type character varying(20) NOT NULL,
    opn character varying(10) NOT NULL,
    currency_id character varying(60),
    utilised_amount numeric(21,2),
    utilisation_date timestamp(6) without time zone DEFAULT clock_timestamp(),
    is_deleted character varying(1) DEFAULT 'N'::character varying NOT NULL,
    created timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    created_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_updated timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_checked_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_maked timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_db timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    mod_id double precision DEFAULT 0 NOT NULL,
    maker_checker_status character varying(10) DEFAULT 'Maked'::character varying NOT NULL,
    shadow_id character varying(180) DEFAULT ''::character varying NOT NULL,
    parent_reversal_entry character varying(5) DEFAULT 'N'::character varying NOT NULL,
    exclusion_rule character varying(2000)
);


--
--

CREATE TABLE tbls_limits_utlsation_dates (
    fin_id character varying(60) NOT NULL,
    current_date1 timestamp(6) without time zone DEFAULT clock_timestamp(),
    start_date timestamp(6) without time zone DEFAULT clock_timestamp(),
    end_date timestamp(6) without time zone DEFAULT clock_timestamp(),
    sort_order numeric(15,5) NOT NULL,
    is_deleted character varying(1) DEFAULT 'N'::character varying NOT NULL,
    created timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    created_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_updated timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_checked_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_maked timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_db timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    mod_id numeric DEFAULT 0 NOT NULL,
    maker_checker_status character varying(10) DEFAULT 'Maked'::character varying NOT NULL,
    shadow_id character varying(60) DEFAULT ''::character varying NOT NULL,
    name character varying(60),
    tenor_buckets_id character varying(60),
    helper_column numeric(15,5)
);


--
--

CREATE TABLE tbls_maker_checker (
    fin_id character varying(401) NOT NULL,
    function_id character varying(200),
    entity_id character varying(200),
    bean_name character varying(200),
    entity_status character varying(10),
    maker_checker_status character varying(10) DEFAULT 'Maked'::character varying NOT NULL,
    maker character varying(60),
    checker character varying(60),
    is_parent character varying(1) DEFAULT 'N'::character varying NOT NULL,
    source_event character varying(100),
    is_deleted character varying(1) DEFAULT 'N'::character varying NOT NULL,
    created timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    created_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_updated timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_checked_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_maked timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_db timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    mod_id double precision DEFAULT 0 NOT NULL,
    shadow_id character varying(401) DEFAULT ''::character varying NOT NULL,
    group_id character varying(60),
    parent_id character varying(401),
    maker_remarks character varying(100),
    checker_remarks character varying(100),
    old_value character varying(100),
    new_value character varying(100)
);


--
--

CREATE TABLE tbls_maker_checker_data (
    fin_id character varying(401) NOT NULL,
    old_object bytea,
    new_object bytea,
    is_deleted character varying(1) NOT NULL,
    created timestamp without time zone NOT NULL,
    created_by character varying(30) NOT NULL,
    last_updated timestamp without time zone NOT NULL,
    last_updated_by character varying(30) NOT NULL,
    last_checked_by character varying(30) NOT NULL,
    last_maked timestamp without time zone NOT NULL,
    last_updated_db timestamp without time zone NOT NULL,
    mod_id numeric(38,10) NOT NULL,
    shadow_id character varying(401) NOT NULL,
    maker_checker_id character varying(401),
    maker_checker_status character varying(10)
);


--
--

CREATE TABLE tbls_manual_postings (
    fin_id character varying(60) NOT NULL,
    repositories_id character varying(60),
    currencies_id character varying(60),
    posting_date timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    journal_desc character varying(100),
    debit_main_ledger character varying(100),
    debit_sub_ledger character varying(100),
    debit_account_desc character varying(200),
    debit_amount double precision DEFAULT 0 NOT NULL,
    debit_allocation_no character varying(60),
    debit_line_desc character varying(200),
    credit_main_ledger character varying(100),
    credit_sub_ledger character varying(100),
    credit_account_desc character varying(200),
    credit_amount double precision DEFAULT 0 NOT NULL,
    credit_allocation_no character varying(60),
    credit_line_desc character varying(200),
    is_deleted character varying(1) DEFAULT 'N'::character varying NOT NULL,
    created timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    created_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_updated timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_checked_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_maked timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_db timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    mod_id double precision DEFAULT 0 NOT NULL,
    maker_checker_status character varying(10) DEFAULT 'COMMITTED'::character varying NOT NULL,
    shadow_id character varying(60) DEFAULT ''::character varying NOT NULL,
    remarks character varying(100),
    credit_ios_code character varying(10),
    debit_ios_code character varying(10)
);


--
--

CREATE TABLE tbls_margin_templates (
    fin_id character varying(120) NOT NULL,
    template_name character varying(120) NOT NULL,
    priority_listing character varying(500),
    is_deleted character varying(1) DEFAULT 'N'::character varying NOT NULL,
    created timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    created_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_updated timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_checked_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_maked timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_db timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    mod_id double precision DEFAULT 0 NOT NULL,
    maker_checker_status character varying(10) DEFAULT 'Maked'::character varying NOT NULL,
    shadow_id character varying(120) DEFAULT ''::character varying NOT NULL
);


--
--

CREATE TABLE tbls_margins (
    fin_id character varying(60) NOT NULL,
    margin_template_id character varying(120),
    application_mode character varying(120),
    bank_notes_currency character varying(120),
    bank_notes_denoms_id character varying(213),
    bank_notes_types_id character varying(120),
    currency_factor character varying(120),
    maximum_amount character varying(120),
    minimum_amount character varying(120),
    reference_currency character varying(120),
    f9 character varying(120),
    f10 character varying(120),
    margin numeric(21,11) DEFAULT 0 NOT NULL,
    is_deleted character varying(1) DEFAULT 'N'::character varying NOT NULL,
    created timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    created_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_updated timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_checked_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_maked timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_db timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    mod_id double precision DEFAULT 0 NOT NULL,
    maker_checker_status character varying(10) DEFAULT 'Maked'::character varying NOT NULL,
    shadow_id character varying(60) DEFAULT ''::character varying NOT NULL,
    buy_sell character varying(3),
    priority numeric(21,2) DEFAULT 0 NOT NULL
);


--
--

CREATE TABLE tbls_margins_meta_data (
    fin_id character varying(171) NOT NULL,
    field_name character varying(50),
    field_desc character varying(100),
    io character(1),
    region_id character varying(60),
    is_deleted character varying(1) DEFAULT 'N'::character varying NOT NULL,
    created timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    created_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_updated timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_checked_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_maked timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_db timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    mod_id double precision DEFAULT 0 NOT NULL,
    maker_checker_status character varying(10) DEFAULT 'Maked'::character varying NOT NULL,
    shadow_id character varying(171) DEFAULT ''::character varying NOT NULL,
    reference_field character varying(25),
    margin_templates_id character varying(120),
    system_property_name character varying(50)
);


--
--

CREATE TABLE tbls_market_data_sets (
    fin_id character varying(60) NOT NULL,
    code character varying(60),
    name character varying(60),
    description character varying(100),
    is_deleted character varying(1) DEFAULT 'N'::character varying NOT NULL,
    created timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    created_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_updated timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_checked_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_maked timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_db timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    mod_id double precision DEFAULT 0 NOT NULL,
    maker_checker_status character varying(10) DEFAULT 'Maked'::character varying NOT NULL,
    shadow_id character varying(60) DEFAULT ''::character varying NOT NULL
);


--
--

CREATE TABLE tbls_market_data_sources (
    fin_id character varying(60) NOT NULL,
    code character varying(20),
    name character varying(20),
    description character varying(100),
    is_deleted character varying(1) DEFAULT 'N'::character varying NOT NULL,
    created timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    created_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_updated timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_checked_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_maked timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_db timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    mod_id double precision DEFAULT 0 NOT NULL,
    maker_checker_status character varying(10) DEFAULT 'Maked'::character varying NOT NULL,
    shadow_id character varying(60) DEFAULT ''::character varying NOT NULL
);


--
--

CREATE TABLE tbls_markets (
    fin_id character varying(60) NOT NULL,
    name character varying(60),
    code character varying(60),
    is_deleted character varying(1) DEFAULT 'N'::character varying NOT NULL,
    created timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    created_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_updated timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_checked_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_maked timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_db timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    mod_id double precision DEFAULT 0 NOT NULL,
    maker_checker_status character varying(10) DEFAULT 'COMMITTED'::character varying NOT NULL,
    shadow_id character varying(60) DEFAULT ''::character varying NOT NULL,
    remarks character varying(100)
);


--
--

CREATE TABLE tbls_markets_countries_int (
    fin_id character varying(181) NOT NULL,
    country_id character varying(120),
    market_id character varying(60),
    is_deleted character varying(1) DEFAULT 'N'::character varying NOT NULL,
    created timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    created_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_updated timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_checked_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_maked timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_db timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    mod_id double precision DEFAULT 0 NOT NULL,
    maker_checker_status character varying(10) DEFAULT 'Maked'::character varying NOT NULL,
    shadow_id character varying(181) DEFAULT ''::character varying NOT NULL
);


--
--

CREATE TABLE tbls_markets_pack_type_int (
    fin_id character varying(91) NOT NULL,
    markets_id character varying(60),
    pack_in_box character varying(30),
    pack_in_bag character varying(30),
    region_id character varying(60),
    is_deleted character varying(1) DEFAULT 'N'::character varying NOT NULL,
    created timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    created_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_updated timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_checked_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_maked timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_db timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    mod_id double precision DEFAULT 0 NOT NULL,
    maker_checker_status character varying(10) DEFAULT 'Maked'::character varying NOT NULL,
    shadow_id character varying(91) DEFAULT ''::character varying NOT NULL
);


--
--

CREATE TABLE tbls_messages_history (
    fin_id character varying(221) NOT NULL,
    module_entity_id character varying(60),
    module_name character varying(60),
    msg_templates_id character varying(60),
    generated_date timestamp(6) without time zone DEFAULT clock_timestamp(),
    msg_status_id character varying(30),
    generated_count numeric(15,5),
    is_deleted character varying(1) DEFAULT 'N'::character varying NOT NULL,
    created timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    created_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_updated timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_checked_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_maked timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_db timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    mod_id double precision DEFAULT 0 NOT NULL,
    maker_checker_status character varying(10) DEFAULT 'Maked'::character varying NOT NULL,
    shadow_id character varying(221) DEFAULT ''::character varying NOT NULL,
    msg_source character varying(60),
    isn_no character varying(30),
    ack_flag character varying(30),
    ack_text character varying(100),
    reason_flag character varying(1),
    reason_code character varying(10),
    reason_text character varying(100),
    received_date timestamp(6) without time zone DEFAULT clock_timestamp(),
    session_no character varying(30),
    version_no double precision DEFAULT 1,
    settl_version_no numeric(20,0) DEFAULT 0,
    page_no double precision
);


--
--

CREATE TABLE tbls_messages_history_his (
    fin_id character varying(221) NOT NULL,
    module_entity_id character varying(60),
    module_name character varying(60),
    msg_templates_id character varying(60),
    msg_contents bytea,
    generated_date timestamp without time zone,
    msg_status_id character varying(30),
    generated_count numeric(15,5),
    is_deleted character varying(1) NOT NULL,
    created timestamp without time zone NOT NULL,
    created_by character varying(30) NOT NULL,
    last_updated timestamp without time zone NOT NULL,
    last_updated_by character varying(30) NOT NULL,
    last_checked_by character varying(30) NOT NULL,
    last_maked timestamp without time zone NOT NULL,
    last_updated_db timestamp without time zone NOT NULL,
    mod_id numeric(38,10) NOT NULL,
    maker_checker_status character varying(10) NOT NULL,
    shadow_id character varying(221) NOT NULL,
    msg_source character varying(60),
    isn_no character varying(30),
    ack_flag character varying(30),
    ack_text character varying(100),
    reason_flag character varying(1),
    reason_code character varying(10),
    reason_text character varying(100),
    received_date timestamp without time zone,
    session_no character varying(30),
    version_no numeric(38,10),
    settl_version_no numeric(20,0)
);


--
--

CREATE TABLE tbls_migrproc_group (
    fin_id character varying(60) NOT NULL,
    name character varying(60),
    description character varying(60),
    is_deleted character varying(1) DEFAULT 'N'::character varying NOT NULL,
    created timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    created_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_updated timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_checked_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_maked timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_db timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    mod_id double precision DEFAULT 0 NOT NULL,
    maker_checker_status character varying(10) DEFAULT 'Maked'::character varying NOT NULL,
    shadow_id character varying(60) DEFAULT ''::character varying NOT NULL
);


--
--

CREATE TABLE tbls_migrproc_group_bean_int (
    fin_id character varying(60) NOT NULL,
    name character varying(150) NOT NULL,
    display_name character varying(60) NOT NULL,
    group_id character varying(60),
    function_id character varying(60) NOT NULL,
    is_deleted character varying(1) DEFAULT 'N'::character varying NOT NULL,
    created timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    created_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_updated timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_checked_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_maked timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_db timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    mod_id double precision DEFAULT 0 NOT NULL,
    maker_checker_status character varying(10) DEFAULT 'Maked'::character varying NOT NULL,
    shadow_id character varying(60) DEFAULT ''::character varying NOT NULL
);


--
--

CREATE TABLE tbls_mm_discount_factors (
    fin_id character varying(496) NOT NULL,
    source_id character varying(121),
    rate_type character varying(60),
    currencies_id character varying(60),
    tenor character varying(120),
    tenor_start_date timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    tenor_end_date timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    bid_rate numeric(21,11) DEFAULT 0,
    ask_rate numeric(21,11) DEFAULT 0,
    data_set_name character varying(120),
    is_deleted character varying(1) DEFAULT 'N'::character varying NOT NULL,
    created timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    created_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_updated timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_checked_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_maked timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_db timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    mod_id double precision DEFAULT 0 NOT NULL,
    maker_checker_status character varying(10) DEFAULT 'Maked'::character varying NOT NULL,
    shadow_id character varying(496) DEFAULT ''::character varying NOT NULL,
    mkt_date timestamp(0) without time zone,
    discount_factor numeric(21,11)
);


--
--

CREATE TABLE tbls_mm_disfactors_his (
    fin_id character varying(496) NOT NULL,
    source_id character varying(121),
    rate_type character varying(60),
    currencies_id character varying(60),
    tenor character varying(120),
    tenor_start_date timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    tenor_end_date timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    bid_rate numeric(21,11) DEFAULT 0,
    ask_rate numeric(21,11) DEFAULT 0,
    data_set_name character varying(120),
    is_deleted character varying(1) DEFAULT 'N'::character varying NOT NULL,
    created timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    created_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_updated timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_checked_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_maked timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_db timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    mod_id double precision DEFAULT 0 NOT NULL,
    maker_checker_status character varying(10) DEFAULT 'Maked'::character varying NOT NULL,
    shadow_id character varying(496) DEFAULT ''::character varying NOT NULL,
    mkt_date timestamp(0) without time zone,
    discount_factor numeric(21,11)
);


--
--

CREATE TABLE tbls_mm_rates (
    fin_id character varying(375) NOT NULL,
    mkt_date timestamp(6) without time zone DEFAULT clock_timestamp(),
    source_id character varying(121),
    rate_type character varying(60),
    currencies_id character varying(60),
    tenor character varying(120),
    tenor_start_date timestamp(6) without time zone DEFAULT clock_timestamp(),
    tenor_end_date timestamp(6) without time zone DEFAULT clock_timestamp(),
    bid_rate numeric(21,11),
    ask_rate numeric(21,11),
    region_id character varying(60),
    data_set_name character varying(120),
    is_deleted character varying(1),
    created timestamp(6) without time zone DEFAULT clock_timestamp(),
    created_by character varying(30),
    last_updated timestamp(6) without time zone DEFAULT clock_timestamp(),
    last_updated_by character varying(30),
    last_checked_by character varying(30),
    last_maked timestamp(6) without time zone DEFAULT clock_timestamp(),
    last_updated_db timestamp(6) without time zone DEFAULT clock_timestamp(),
    mod_id double precision,
    maker_checker_status character varying(10),
    shadow_id character varying(375) DEFAULT 0,
    source_system character varying(20)
);


--
--

CREATE TABLE tbls_mm_rates_his (
    fin_id character varying(375) NOT NULL,
    mkt_date timestamp(6) without time zone DEFAULT clock_timestamp(),
    source_id character varying(121),
    rate_type character varying(60),
    currencies_id character varying(60),
    tenor character varying(120),
    tenor_start_date timestamp(6) without time zone DEFAULT clock_timestamp(),
    tenor_end_date timestamp(6) without time zone DEFAULT clock_timestamp(),
    bid_rate numeric(21,11),
    ask_rate numeric(21,11),
    region_id character varying(60),
    data_set_name character varying(120),
    is_deleted character varying(1),
    created timestamp(6) without time zone DEFAULT clock_timestamp(),
    created_by character varying(30),
    last_updated timestamp(6) without time zone DEFAULT clock_timestamp(),
    last_updated_by character varying(30),
    last_checked_by character varying(30),
    last_maked timestamp(6) without time zone DEFAULT clock_timestamp(),
    last_updated_db timestamp(6) without time zone DEFAULT clock_timestamp(),
    mod_id double precision,
    maker_checker_status character varying(10),
    shadow_id character varying(375) DEFAULT 0
);


--
--

CREATE TABLE tbls_msg_configuration (
    fin_id character varying(182) NOT NULL,
    products_id character varying(60),
    buysell character(1),
    module_name character varying(60),
    module_action character varying(60),
    msg_id character varying(60),
    regions_id character varying(60),
    is_deleted character varying(1) DEFAULT 'N'::character varying NOT NULL,
    created timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    created_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_updated timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_checked_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_maked timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_db timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    mod_id double precision DEFAULT 0 NOT NULL,
    maker_checker_status character varying(10) DEFAULT 'Maked'::character varying NOT NULL,
    shadow_id character varying(182) DEFAULT ''::character varying NOT NULL
);


--
--

CREATE TABLE tbls_msg_configv2 (
    fin_id character varying(183) NOT NULL,
    products_id character varying(60),
    ud_deal_types_id character varying(60),
    module_name character varying(60),
    module_action character varying(60),
    source_state_id character varying(60),
    destination_state_id character varying(60),
    msg_id character varying(60),
    generation_type character varying(60),
    output_at_bo character(1) DEFAULT 'N'::bpchar NOT NULL,
    output_at_sh character(1) DEFAULT 'N'::bpchar NOT NULL,
    output_at_va character(1) DEFAULT 'N'::bpchar NOT NULL,
    regions_id character varying(60),
    is_deleted character varying(1) DEFAULT 'N'::character varying NOT NULL,
    created timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    created_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_updated timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_checked_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_maked timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_db timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    mod_id double precision DEFAULT 0 NOT NULL,
    maker_checker_status character varying(10) DEFAULT 'Maked'::character varying NOT NULL,
    shadow_id character varying(182) DEFAULT ''::character varying NOT NULL,
    output_type character varying(30) DEFAULT 'CONFO'::character varying
);


--
--

CREATE TABLE tbls_msg_history_content (
    fin_id character varying(221) NOT NULL,
    msg_history_id character varying(60),
    msg_contents bytea,
    is_deleted character varying(1) NOT NULL,
    created timestamp without time zone NOT NULL,
    created_by character varying(30) NOT NULL,
    last_updated timestamp without time zone NOT NULL,
    last_updated_by character varying(30) NOT NULL,
    last_checked_by character varying(30) NOT NULL,
    last_maked timestamp without time zone NOT NULL,
    last_updated_db timestamp without time zone NOT NULL,
    mod_id numeric(38,10) NOT NULL,
    maker_checker_status character varying(10) NOT NULL,
    shadow_id character varying(221) NOT NULL
);


--
--

CREATE TABLE tbls_msg_history_content_his (
    fin_id character varying(221) NOT NULL,
    msg_history_id character varying(60),
    msg_contents bytea,
    is_deleted character varying(1) NOT NULL,
    created timestamp without time zone NOT NULL,
    created_by character varying(30) NOT NULL,
    last_updated timestamp without time zone NOT NULL,
    last_updated_by character varying(30) NOT NULL,
    last_checked_by character varying(30) NOT NULL,
    last_maked timestamp without time zone NOT NULL,
    last_updated_db timestamp without time zone NOT NULL,
    mod_id numeric(38,10) NOT NULL,
    maker_checker_status character varying(10) NOT NULL,
    shadow_id character varying(221) NOT NULL
);


--
--

CREATE TABLE tbls_msg_pagination_cfg (
    fin_id character varying(50) NOT NULL,
    max_legs_perpg double precision NOT NULL,
    disclaimer_only_lstpg character varying(1) NOT NULL,
    is_deleted character varying(1) DEFAULT 'N'::character varying NOT NULL,
    created timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    created_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_updated timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_checked_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_maked timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_db timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    mod_id double precision DEFAULT 0 NOT NULL,
    maker_checker_status character varying(10) DEFAULT 'Maked'::character varying NOT NULL,
    shadow_id character varying(60) DEFAULT ''::character varying NOT NULL
);


--
--

CREATE TABLE tbls_msg_templates (
    fin_id character varying(60) NOT NULL,
    msg_code character varying(60),
    msg_name character varying(60),
    msg_template character varying(63),
    msg_template_location character varying(120),
    is_swift character varying(1) DEFAULT 'Y'::character varying NOT NULL,
    regions_id character varying(60),
    is_deleted character varying(1) DEFAULT 'N'::character varying NOT NULL,
    created timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    created_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_updated timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_checked_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_maked timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_db timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    mod_id double precision DEFAULT 0 NOT NULL,
    maker_checker_status character varying(10) DEFAULT 'Maked'::character varying NOT NULL,
    shadow_id character varying(60) DEFAULT ''::character varying NOT NULL,
    template_header character varying(30),
    swift_type character varying(3),
    amh_msg_header character varying(50)
);


--
--

CREATE TABLE tbls_msg_types (
    fin_id character varying(60) NOT NULL,
    msg_type_id character varying(60),
    msg_type_name character varying(60),
    msg_template character varying(63),
    is_swift character varying(1) DEFAULT 'Y'::character varying NOT NULL,
    module_name character varying(60),
    regions_id character varying(60),
    is_deleted character varying(1) DEFAULT 'N'::character varying NOT NULL,
    created timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    created_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_updated timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_checked_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_maked timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_db timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    mod_id double precision DEFAULT 0 NOT NULL,
    maker_checker_status character varying(10) DEFAULT 'Maked'::character varying NOT NULL,
    shadow_id character varying(60) DEFAULT ''::character varying NOT NULL
);


--
--

CREATE TABLE tbls_mtmsg_configuration (
    fin_id character varying(60) NOT NULL,
    deal_type_id character varying(60),
    currencies_id character varying(60),
    module_id character varying(60),
    setl_mode character varying(60),
    action character varying(60),
    conf_msg_type_id character varying(60),
    workflow_states_id character varying(61),
    setl_msg_type_id character varying(60),
    regions_id character varying(60),
    is_deleted character varying(1) DEFAULT 'N'::character varying NOT NULL,
    created timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    created_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_updated timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_checked_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_maked timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_db timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    mod_id double precision DEFAULT 0 NOT NULL,
    maker_checker_status character varying(10) DEFAULT 'Maked'::character varying NOT NULL,
    shadow_id character varying(60) DEFAULT ''::character varying NOT NULL
);


--
--

CREATE TABLE tbls_order_types (
    fin_id character varying(60) NOT NULL,
    code character varying(4),
    name character varying(60) NOT NULL,
    order_type_code character varying(60) NOT NULL,
    order_type_name character varying(60) NOT NULL,
    is_deleted character varying(1) DEFAULT 'N'::character varying NOT NULL,
    created timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    created_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_updated timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_checked_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_maked timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_db timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    mod_id double precision DEFAULT 0 NOT NULL,
    maker_checker_status character varying(10) DEFAULT 'Maked'::character varying NOT NULL,
    shadow_id character varying(60) DEFAULT ''::character varying NOT NULL
);


--
--

CREATE TABLE tbls_other_charges (
    fin_id character varying(477) NOT NULL,
    carrier_id character varying(60),
    origin_airports_id character varying(182),
    dest_airports_id character varying(182),
    local_currency_id character varying(60),
    other_charges_name character varying(50),
    rate numeric(21,11),
    min_charge numeric(21,2),
    max_charge numeric(21,2),
    is_deleted character varying(1) DEFAULT 'N'::character varying NOT NULL,
    created timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    created_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_updated timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_checked_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_maked timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_db timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    mod_id double precision DEFAULT 0 NOT NULL,
    maker_checker_status character varying(10) DEFAULT 'Maked'::character varying NOT NULL,
    shadow_id character varying(477) DEFAULT ''::character varying NOT NULL,
    restricted_weight numeric(21,2)
);


--
--

CREATE TABLE tbls_packing_list (
    fin_id character varying(60) NOT NULL,
    shipment_record_id character varying(60),
    packing_date timestamp(6) without time zone DEFAULT clock_timestamp(),
    currency_id character varying(60),
    note_type_id character varying(60),
    note_denom_id character varying(213),
    quantity numeric(21,2),
    amount numeric(21,2),
    container_sno character varying(20),
    fast_pak_no character varying(20),
    box_type_id character varying(60),
    box_from_sr_no character varying(20),
    box_to_sr_no character varying(20),
    bag_type_id character varying(60),
    bag_sr_no character varying(20),
    packing_purpose character varying(100),
    remarks character varying(255),
    status_id character varying(61),
    region_id character varying(60),
    is_deleted character varying(1) DEFAULT 'N'::character varying NOT NULL,
    created timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    created_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_updated timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_checked_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_maked timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_db timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    mod_id double precision DEFAULT 0 NOT NULL,
    maker_checker_status character varying(10) DEFAULT 'Maked'::character varying NOT NULL,
    shadow_id character varying(60) DEFAULT ''::character varying NOT NULL,
    deal_no character varying(30),
    order_no character varying(30),
    deal_leg_no double precision,
    order_leg_no double precision,
    packing_list_no character varying(30),
    client character varying(60),
    branch character varying(200),
    deal_version_no numeric(3,0),
    sdi character varying(200),
    reference_leg_id character varying(149)
);


--
--

CREATE TABLE tbls_packing_list_his (
    fin_id character varying(60) NOT NULL,
    shipment_record_id character varying(60),
    packing_date timestamp(6) without time zone DEFAULT clock_timestamp(),
    currency_id character varying(60),
    note_type_id character varying(60),
    note_denom_id character varying(213),
    quantity numeric(21,2),
    amount numeric(21,2),
    container_sno character varying(20),
    fast_pak_no character varying(20),
    box_type_id character varying(60),
    box_from_sr_no character varying(20),
    box_to_sr_no character varying(20),
    bag_type_id character varying(60),
    bag_sr_no character varying(20),
    packing_purpose character varying(100),
    remarks character varying(255),
    status_id character varying(61),
    region_id character varying(60),
    is_deleted character varying(1) DEFAULT 'N'::character varying NOT NULL,
    created timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    created_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_updated timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_checked_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_maked timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_db timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    mod_id double precision DEFAULT 0 NOT NULL,
    maker_checker_status character varying(10) DEFAULT 'Maked'::character varying NOT NULL,
    shadow_id character varying(60) DEFAULT ''::character varying NOT NULL,
    deal_no character varying(30),
    order_no character varying(30),
    deal_leg_no double precision,
    order_leg_no double precision,
    packing_list_no character varying(30),
    client character varying(60),
    branch character varying(200),
    deal_version_no numeric(3,0),
    sdi character varying(200),
    reference_leg_id character varying(149)
);


--
--

CREATE TABLE tbls_pl_main (
    fin_id character varying(60) NOT NULL,
    shipment_record_id character varying(60) NOT NULL,
    seal_no character varying(500),
    status character varying(60),
    no_of_pieces double precision DEFAULT 0,
    pl_remarks character varying(500),
    regions_id character varying(60),
    is_deleted character varying(1) DEFAULT 'N'::character varying NOT NULL,
    created timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    created_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_updated timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_checked_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_maked timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_db timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    mod_id double precision DEFAULT 0 NOT NULL,
    maker_checker_status character varying(10) DEFAULT 'COMMITTED'::character varying NOT NULL,
    shadow_id character varying(60) DEFAULT ''::character varying NOT NULL,
    version_no double precision,
    accounting_info character varying(400),
    awb_special_clause character varying(400),
    awb_remarks character varying(400)
);


--
--

CREATE TABLE tbls_pl_main_his (
    fin_id character varying(60) NOT NULL,
    shipment_record_id character varying(60) NOT NULL,
    seal_no character varying(500),
    status character varying(60),
    no_of_pieces double precision DEFAULT 0,
    pl_remarks character varying(500),
    regions_id character varying(60),
    is_deleted character varying(1) DEFAULT 'N'::character varying NOT NULL,
    created timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    created_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_updated timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_checked_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_maked timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_db timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    mod_id double precision DEFAULT 0 NOT NULL,
    maker_checker_status character varying(10) DEFAULT 'COMMITTED'::character varying NOT NULL,
    shadow_id character varying(60) DEFAULT ''::character varying NOT NULL,
    version_no double precision,
    accounting_info character varying(400),
    awb_special_clause character varying(400),
    awb_remarks character varying(400)
);


--
--

CREATE TABLE tbls_processing_inbox (
    fin_id character varying(401) NOT NULL,
    entity_name character varying(200),
    entity_id character varying(200),
    entity_shadow_id character varying(200),
    entity_status character varying(10),
    maker character varying(60),
    checker character varying(60),
    fromversion double precision,
    toversion double precision,
    priority_rating double precision,
    entity_item_name character varying(200),
    source_event character varying(100),
    is_deleted character varying(1) DEFAULT 'N'::character varying NOT NULL,
    created timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    created_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_updated timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_checked_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_maked timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_db timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    mod_id double precision DEFAULT 0 NOT NULL,
    maker_checker_status character varying(10) DEFAULT 'Maked'::character varying NOT NULL,
    shadow_id character varying(401) DEFAULT ''::character varying NOT NULL,
    groups_id character varying(60),
    function_id character varying(121)
);


--
--

CREATE TABLE tbls_products (
    fin_id character varying(60) NOT NULL,
    code character varying(3),
    name character varying(100),
    deal_type_code character varying(10),
    deal_type_name character varying(30),
    is_deleted character varying(1) DEFAULT 'N'::character varying NOT NULL,
    created timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    created_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_updated timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_checked_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_maked timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_db timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    mod_id double precision DEFAULT 0 NOT NULL,
    maker_checker_status character varying(10) DEFAULT 'Maked'::character varying NOT NULL,
    shadow_id character varying(60) DEFAULT ''::character varying NOT NULL
);


--
--

CREATE TABLE tbls_r_roles (
    fin_id character varying(91) NOT NULL,
    name character varying(30) NOT NULL,
    group_id character varying(60),
    category double precision,
    default_function_id numeric(15,5),
    is_deleted character varying(1) DEFAULT 'N'::character varying NOT NULL,
    created timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    created_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_updated timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_checked_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_maked timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_db timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    mod_id double precision DEFAULT 0 NOT NULL,
    maker_checker_status character varying(10) DEFAULT 'Maked'::character varying NOT NULL,
    shadow_id character varying(60) DEFAULT ''::character varying NOT NULL,
    region_id character varying(60) NOT NULL
);


--
--

CREATE TABLE tbls_r_users (
    fin_id character varying(60) NOT NULL,
    user_id character varying(60) NOT NULL,
    name character varying(30) NOT NULL,
    first_name character varying(30),
    last_name character varying(30),
    maker_checker character varying(3) NOT NULL,
    employee_id character varying(30) NOT NULL,
    department_id character varying(60),
    group_id character varying(60),
    user_status character varying(3),
    version double precision,
    logged_in character varying(3),
    unsuccessful_attempt_count double precision,
    force_password_change character varying(3),
    email_address character varying(30),
    password_expiry character(1),
    print_password character varying(1) DEFAULT 'N'::character varying,
    is_deleted character varying(1) DEFAULT 'N'::character varying NOT NULL,
    created timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    created_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_updated timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_checked_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_maked timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_db timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    mod_id double precision DEFAULT 0 NOT NULL,
    maker_checker_status character varying(10) DEFAULT 'Maked'::character varying NOT NULL,
    shadow_id character varying(60) DEFAULT ''::character varying NOT NULL,
    host_name character varying(100),
    session_id character varying(200)
);


--
--

CREATE TABLE tbls_r_users_regions_int (
    fin_id character varying(213) NOT NULL,
    user_id character varying(60) NOT NULL,
    region_id character varying(60),
    role_id character varying(91),
    is_home character(1),
    is_deleted character varying(1) NOT NULL,
    created timestamp(6) without time zone NOT NULL,
    created_by character varying(30) NOT NULL,
    last_updated timestamp(6) without time zone NOT NULL,
    last_updated_by character varying(30) NOT NULL,
    last_checked_by character varying(30) NOT NULL,
    last_maked timestamp(6) without time zone NOT NULL,
    last_updated_db timestamp(6) without time zone,
    mod_id double precision NOT NULL,
    maker_checker_status character varying(10) NOT NULL,
    shadow_id character varying(60) NOT NULL
);


--
--

CREATE TABLE tbls_rate_source_schemes (
    fin_id character varying(100) NOT NULL,
    rate_source_scheme_name character varying(100),
    is_deleted character varying(1) DEFAULT 'N'::character varying NOT NULL,
    created timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    created_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_updated timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_checked_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_maked timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_db timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    mod_id double precision DEFAULT 0 NOT NULL,
    maker_checker_status character varying(10) DEFAULT 'Maked'::character varying NOT NULL,
    shadow_id character varying(100) DEFAULT ''::character varying NOT NULL
);


--
--

CREATE TABLE tbls_rate_sources (
    fin_id character varying(121) NOT NULL,
    system_codes_id character varying(60),
    pairs_id character varying(60),
    major_currency_id character varying(60),
    minor_currency_id character varying(60),
    spot_factor double precision NOT NULL,
    num_decimal double precision NOT NULL,
    is_deleted character varying(1) DEFAULT 'N'::character varying NOT NULL,
    created timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    created_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_updated timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_checked_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_maked timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_db timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    mod_id double precision DEFAULT 0 NOT NULL,
    maker_checker_status character varying(10) DEFAULT 'Maked'::character varying NOT NULL,
    shadow_id character varying(121) DEFAULT ''::character varying NOT NULL
);


--
--

CREATE TABLE tbls_rate_src_schemes_data (
    fin_id character varying(226) NOT NULL,
    rate_source_scheme_id character varying(100),
    settlement_ccy character varying(60),
    bank_notes_ccy character varying(60),
    buy_sell character varying(3),
    bid_ask_mid character varying(1),
    is_deleted character varying(1) DEFAULT 'N'::character varying NOT NULL,
    created timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    created_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_updated timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_checked_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_maked timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_db timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    mod_id double precision DEFAULT 0 NOT NULL,
    maker_checker_status character varying(10) DEFAULT 'Maked'::character varying NOT NULL,
    shadow_id character varying(226) DEFAULT ''::character varying NOT NULL,
    rate_sources_id character varying(121) NOT NULL,
    priority double precision
);


--
--

CREATE TABLE tbls_rates_tolerance (
    fin_id character varying(121) NOT NULL,
    products_code character varying(60),
    currency_pair_id character varying(60),
    tolerance numeric(5,2),
    is_deleted character varying(1) DEFAULT 'N'::character varying NOT NULL,
    created timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    created_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_updated timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_checked_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_maked timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_db timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    mod_id double precision DEFAULT 0 NOT NULL,
    maker_checker_status character varying(10) DEFAULT 'Maked'::character varying NOT NULL,
    shadow_id character varying(121) DEFAULT ''::character varying NOT NULL
);


--
--

CREATE TABLE tbls_regions (
    fin_id character varying(60) NOT NULL,
    name character varying(30),
    database_id character varying(60),
    short_name character varying(5),
    currencies_id character varying(60),
    is_deleted character varying(1) DEFAULT 'N'::character varying NOT NULL,
    created timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    created_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_updated timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_checked_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_maked timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_db timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    mod_id double precision DEFAULT 0 NOT NULL,
    maker_checker_status character varying(10) DEFAULT 'Maked'::character varying NOT NULL,
    shadow_id character varying(60) DEFAULT ''::character varying NOT NULL,
    dom_cal_id character varying(60),
    gl_cc_code character varying(60),
    gl_branch_code character varying(60),
    corp_code character varying(60),
    gl_jrnlid character varying(60),
    blk_cal_id character varying(60),
    display_name character varying(30) DEFAULT 'Unknown'::character varying NOT NULL,
    is_merva_up character varying(3),
    df_interpolation character varying(10),
    fx_system character varying(20)
);


--
--

CREATE TABLE tbls_reports_config (
    fin_id character varying(60) NOT NULL,
    report_code character varying(20),
    report_name character varying(50),
    report_group character varying(50),
    filename character varying(100),
    location character varying(100),
    is_deleted character varying(1) DEFAULT 'N'::character varying NOT NULL,
    created timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    created_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_updated timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_checked_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_maked timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_db timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    mod_id double precision DEFAULT 0 NOT NULL,
    maker_checker_status character varying(10) DEFAULT 'Maked'::character varying NOT NULL,
    shadow_id character varying(60) DEFAULT ''::character varying NOT NULL,
    report_description character varying(100),
    report_type character varying(25),
    output_format character varying(30)
);


--
--

CREATE TABLE tbls_reports_param (
    fin_id character varying(60) NOT NULL,
    reports_config_id character varying(60),
    param_code character varying(20),
    param_name character varying(50),
    source_table_name character varying(100),
    source_field character varying(100),
    is_deleted character varying(1) DEFAULT 'N'::character varying NOT NULL,
    created timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    created_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_updated timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_checked_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_maked timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_db timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    mod_id double precision DEFAULT 0 NOT NULL,
    maker_checker_status character varying(10) DEFAULT 'Maked'::character varying NOT NULL,
    shadow_id character varying(60) DEFAULT ''::character varying NOT NULL
);


--
--

CREATE TABLE tbls_repositories (
    fin_id character varying(60) NOT NULL,
    parent_id character varying(60),
    name character varying(60),
    short_name character varying(15),
    repository_level double precision,
    leaf_node character(1),
    repository_type character varying(30),
    region_id character varying(60),
    cost_center character varying(30),
    is_deleted character varying(1) DEFAULT 'N'::character varying NOT NULL,
    created timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    created_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_updated timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_checked_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_maked timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_db timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    mod_id double precision DEFAULT 0 NOT NULL,
    maker_checker_status character varying(10) DEFAULT 'Maked'::character varying NOT NULL,
    shadow_id character varying(60) DEFAULT ''::character varying NOT NULL,
    corp_code character varying(30),
    is_ctc_applicable character varying(1) DEFAULT 'Y'::character varying NOT NULL,
    booking_repository character varying(1)
);


--
--

CREATE TABLE tbls_repositories_extn (
    fin_id character varying(155) NOT NULL,
    level1 double precision,
    level2 double precision,
    level3 double precision,
    level4 double precision,
    level5 double precision,
    level6 double precision,
    level7 double precision,
    is_deleted character varying(1) DEFAULT 'N'::character varying NOT NULL,
    created timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    created_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_updated timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_checked_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_maked timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_db timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    mod_id double precision DEFAULT 0 NOT NULL,
    maker_checker_status character varying(10) DEFAULT 'Maked'::character varying NOT NULL,
    shadow_id character varying(60) DEFAULT ''::character varying NOT NULL
);


--
--

CREATE TABLE tbls_repositories_prdcts_int (
    fin_id character varying(121) NOT NULL,
    repositories_id character varying(60) NOT NULL,
    products_id character varying(60) NOT NULL,
    is_deleted character varying(1) DEFAULT 'N'::character varying NOT NULL,
    created timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    created_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_updated timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_checked_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_maked timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_db timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    mod_id double precision DEFAULT 0 NOT NULL,
    maker_checker_status character varying(10) DEFAULT 'Maked'::character varying NOT NULL,
    shadow_id character varying(121) DEFAULT ''::character varying NOT NULL
);


--
--

CREATE TABLE tbls_repositories_users_int (
    fin_id character varying(121) NOT NULL,
    repository_id character varying(60) NOT NULL,
    user_id character varying(60) NOT NULL,
    region_id character varying(60) NOT NULL,
    allowed character varying(10),
    is_deleted character varying(1) DEFAULT 'N'::character varying NOT NULL,
    created timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    created_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_updated timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_checked_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_maked timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_db timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    mod_id double precision DEFAULT 0 NOT NULL,
    maker_checker_status character varying(10) DEFAULT 'Maked'::character varying NOT NULL,
    shadow_id character varying(121) DEFAULT ''::character varying NOT NULL
);


--
--

CREATE TABLE tbls_sdis (
    fin_id character varying(173) NOT NULL,
    customer_id character varying(60),
    branch_id character varying(91),
    sdi_code character varying(20),
    region_id character varying(60),
    addr1 character varying(50),
    addr2 character varying(50),
    addr3 character varying(50),
    addr4 character varying(50),
    contact_no character varying(20),
    fax_no character varying(20),
    telex_no character varying(20),
    contact_person character varying(50),
    contact_title character varying(50),
    email character varying(50),
    is_default character(1),
    is_deleted character varying(1) DEFAULT 'N'::character varying NOT NULL,
    created timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    created_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_updated timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_checked_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_maked timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_db timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    mod_id double precision DEFAULT 0 NOT NULL,
    maker_checker_status character varying(10) DEFAULT 'Maked'::character varying NOT NULL,
    shadow_id character varying(173) DEFAULT ''::character varying NOT NULL,
    products_code character varying(60),
    delivery_postal_code character varying(60),
    delivery_country_id character varying(60),
    is_active character varying(10)
);


--
--

CREATE TABLE tbls_service_account_types (
    fin_id character varying(60) NOT NULL,
    code character varying(10),
    name character varying(50),
    description character varying(50),
    is_deleted character varying(1) DEFAULT 'N'::character varying NOT NULL,
    created timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    created_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_updated timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_checked_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_maked timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_db timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    mod_id double precision DEFAULT 0 NOT NULL,
    maker_checker_status character varying(10) DEFAULT 'Maked'::character varying NOT NULL,
    shadow_id character varying(60) DEFAULT ''::character varying NOT NULL
);


--
--

CREATE TABLE tbls_service_categories (
    fin_id character varying(60) NOT NULL,
    code character varying(2),
    name character varying(50),
    description character varying(50),
    is_deleted character varying(1) DEFAULT 'N'::character varying NOT NULL,
    created timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    created_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_updated timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_checked_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_maked timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_db timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    mod_id double precision DEFAULT 0 NOT NULL,
    maker_checker_status character varying(10) DEFAULT 'Maked'::character varying NOT NULL,
    shadow_id character varying(60) DEFAULT ''::character varying NOT NULL,
    service_account_type_id character varying(60)
);


--
--

CREATE TABLE tbls_service_charges (
    fin_id character varying(60) NOT NULL,
    service_charge_code character varying(20) NOT NULL,
    service_charge_name character varying(60),
    is_deleted character varying(1) DEFAULT 'N'::character varying NOT NULL,
    created timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    created_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_updated timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_checked_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_maked timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_db timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    mod_id double precision DEFAULT 0 NOT NULL,
    maker_checker_status character varying(10) DEFAULT 'Maked'::character varying NOT NULL,
    shadow_id character varying(60) DEFAULT ''::character varying NOT NULL,
    service_category_id character varying(60)
);


--
--

CREATE TABLE tbls_service_providers (
    fin_id character varying(60) NOT NULL,
    short_name character varying(50),
    name character varying(50),
    address1 character varying(50),
    address2 character varying(50),
    address3 character varying(50),
    address4 character varying(50),
    regions_id character varying(60),
    is_deleted character varying(1),
    created timestamp(6) without time zone DEFAULT clock_timestamp(),
    created_by character varying(30),
    last_updated timestamp(6) without time zone DEFAULT clock_timestamp(),
    last_updated_by character varying(30),
    last_checked_by character varying(30),
    last_maked timestamp(6) without time zone DEFAULT clock_timestamp(),
    last_updated_db timestamp(6) without time zone DEFAULT clock_timestamp(),
    mod_id double precision,
    maker_checker_status character varying(10),
    shadow_id character varying(60) DEFAULT 0,
    city character varying(151)
);


--
--

CREATE TABLE tbls_settlement_modes (
    fin_id character varying(60) NOT NULL,
    setl_mode character varying(10),
    description character varying(50),
    is_deleted character varying(1) DEFAULT 'N'::character varying NOT NULL,
    created timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    created_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_updated timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_checked_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_maked timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_db timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    mod_id double precision DEFAULT 0 NOT NULL,
    maker_checker_status character varying(10) DEFAULT 'Maked'::character varying NOT NULL,
    shadow_id character varying(60) DEFAULT ''::character varying NOT NULL
);


--
--

CREATE TABLE tbls_settlements (
    fin_id character varying(169) NOT NULL,
    deal_versions_id character varying(99),
    setl_no character varying(30),
    setl_currency_id character varying(60),
    setl_amount numeric(21,2),
    ssi_rule_id character varying(120),
    pay_receive character(1),
    status_id character varying(61),
    setl_date timestamp(6) without time zone,
    setl_release_date timestamp(6) without time zone,
    is_netted character(1),
    setl_origin character varying(20),
    is_deleted character varying(1) DEFAULT 'N'::character varying NOT NULL,
    created timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    created_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_updated timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_checked_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_maked timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_db timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    mod_id double precision DEFAULT 0 NOT NULL,
    maker_checker_status character varying(10) DEFAULT 'Maked'::character varying NOT NULL,
    shadow_id character varying(169) DEFAULT ''::character varying NOT NULL,
    version_no double precision DEFAULT 1
);


--
--

CREATE TABLE tbls_settlements_his (
    fin_id character varying(169) NOT NULL,
    deal_versions_id character varying(99),
    setl_no character varying(30),
    setl_currency_id character varying(60),
    setl_amount numeric(21,2),
    ssi_rule_id character varying(120),
    pay_receive character(1),
    status_id character varying(61),
    setl_date timestamp(6) without time zone,
    setl_release_date timestamp(6) without time zone,
    is_netted character(1),
    setl_origin character varying(20),
    is_deleted character varying(1) DEFAULT 'N'::character varying NOT NULL,
    created timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    created_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_updated timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_checked_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_maked timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_db timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    mod_id double precision DEFAULT 0 NOT NULL,
    maker_checker_status character varying(10) DEFAULT 'Maked'::character varying NOT NULL,
    shadow_id character varying(169) DEFAULT ''::character varying NOT NULL,
    version_no double precision DEFAULT 1
);


--
--

CREATE TABLE tbls_settlements_netted (
    fin_id character varying(339) NOT NULL,
    setl_id character varying(169),
    parent_setl_id character varying(169),
    is_deleted character varying(1) DEFAULT 'N'::character varying NOT NULL,
    created timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    created_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_updated timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_checked_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_maked timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_db timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    mod_id double precision DEFAULT 0 NOT NULL,
    maker_checker_status character varying(10) DEFAULT 'Maked'::character varying NOT NULL,
    shadow_id character varying(339) DEFAULT ''::character varying NOT NULL
);


--
--

CREATE TABLE tbls_sh_record_routing_his (
    fin_id character varying(99) NOT NULL,
    shipment_record_id character varying(60),
    airway_bill_no character varying(30),
    leg_no double precision,
    shipment_schedule_id character varying(579),
    region_id character varying(60),
    is_deleted character varying(1) DEFAULT 'N'::character varying NOT NULL,
    created timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    created_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_updated timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_checked_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_maked timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_db timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    mod_id double precision DEFAULT 0 NOT NULL,
    maker_checker_status character varying(10) DEFAULT 'Maked'::character varying NOT NULL,
    shadow_id character varying(99) DEFAULT ''::character varying NOT NULL,
    shipment_date timestamp(6) without time zone,
    carrier_crew_extn_id character varying(111),
    arrival_date timestamp(6) without time zone,
    no_of_pcs double precision,
    chargeable_weight double precision
);


--
--

CREATE TABLE tbls_sh_rtn_charges_his (
    fin_id character varying(577) NOT NULL,
    shipment_routing_id character varying(99),
    other_charges_id character varying(477),
    staff_id character varying(101),
    seal_no character varying(60),
    total numeric(21,2),
    gross_weight numeric(25,9),
    chargeable_weight numeric(25,9),
    no_of_pcs numeric(21,9),
    regions_id character varying(60),
    is_deleted character varying(1) DEFAULT 'N'::character varying NOT NULL,
    created timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    created_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_updated timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_checked_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_maked timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_db timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    mod_id double precision DEFAULT 0 NOT NULL,
    maker_checker_status character varying(10) DEFAULT 'Maked'::character varying NOT NULL,
    shadow_id character varying(577) DEFAULT ''::character varying NOT NULL,
    restricted_weight numeric(25,9),
    rate numeric(21,11),
    charge_name character varying(60)
);


--
--

CREATE TABLE tbls_shipment_arrangements (
    fin_id character varying(60) NOT NULL,
    code character varying(30),
    name character varying(30),
    is_deleted character varying(1) DEFAULT 'N'::character varying NOT NULL,
    created timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    created_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_updated timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_checked_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_maked timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_db timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    mod_id double precision DEFAULT 0 NOT NULL,
    maker_checker_status character varying(10) DEFAULT 'Maked'::character varying NOT NULL,
    shadow_id character varying(60) DEFAULT ''::character varying NOT NULL
);


--
--

CREATE TABLE tbls_shipment_basis (
    fin_id character varying(60) NOT NULL,
    code character varying(30),
    name character varying(30),
    is_deleted character varying(1) DEFAULT 'N'::character varying NOT NULL,
    created timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    created_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_updated timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_checked_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_maked timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_db timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    mod_id double precision DEFAULT 0 NOT NULL,
    maker_checker_status character varying(10) DEFAULT 'Maked'::character varying NOT NULL,
    shadow_id character varying(60) DEFAULT ''::character varying NOT NULL
);


--
--

CREATE TABLE tbls_shipment_charges (
    fin_id character varying(467) NOT NULL,
    shipment_record_id character varying(60),
    remarks character varying(255),
    charge_ccy_id character varying(60),
    charge_amount numeric(21,2),
    invoice_no character varying(30),
    invoice_amount numeric(21,2),
    charge_date timestamp(6) without time zone,
    status character varying(61),
    region_id character varying(60),
    is_deleted character varying(1) DEFAULT 'N'::character varying NOT NULL,
    created timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    created_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_updated timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_checked_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_maked timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_db timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    mod_id double precision DEFAULT 0 NOT NULL,
    maker_checker_status character varying(10) DEFAULT 'Maked'::character varying NOT NULL,
    shadow_id character varying(467) DEFAULT ''::character varying NOT NULL,
    service_charge_provider_int character varying(334),
    invoice_date timestamp(6) without time zone,
    invoice_remarks character varying(150),
    invoice_status character varying(60),
    settlement_date timestamp(6) without time zone,
    is_charge_amt_propagated_deal character varying(2) DEFAULT 'N'::character varying,
    is_invoice_amt_propagated_deal character varying(2) DEFAULT 'N'::character varying,
    invoice_ccy character varying(60)
);


--
--

CREATE TABLE tbls_shipment_charges_his (
    fin_id character varying(467) NOT NULL,
    shipment_record_id character varying(60),
    remarks character varying(255),
    charge_ccy_id character varying(60),
    charge_amount numeric(21,2),
    invoice_no character varying(30),
    invoice_amount numeric(21,2),
    charge_date timestamp(6) without time zone,
    status character varying(61),
    region_id character varying(60),
    is_deleted character varying(1) DEFAULT 'N'::character varying NOT NULL,
    created timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    created_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_updated timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_checked_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_maked timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_db timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    mod_id double precision DEFAULT 0 NOT NULL,
    maker_checker_status character varying(10) DEFAULT 'Maked'::character varying NOT NULL,
    shadow_id character varying(467) DEFAULT ''::character varying NOT NULL,
    service_charge_provider_int character varying(334),
    invoice_date timestamp(6) without time zone,
    invoice_remarks character varying(150),
    invoice_status character varying(60),
    settlement_date timestamp(6) without time zone,
    is_charge_amt_propagated_deal character varying(2) DEFAULT 'N'::character varying,
    is_invoice_amt_propagated_deal character varying(2) DEFAULT 'N'::character varying,
    invoice_ccy character varying(60)
);


--
--

CREATE TABLE tbls_shipment_docs_generated (
    fin_id character varying(121) NOT NULL,
    shipment_record_id character varying(60),
    documents_id character varying(86),
    remarks character varying(255),
    status character varying(61),
    generated_date timestamp(6) without time zone,
    region_id character varying(60),
    is_deleted character varying(1) DEFAULT 'N'::character varying NOT NULL,
    created timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    created_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_updated timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_checked_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_maked timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_db timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    mod_id double precision DEFAULT 0 NOT NULL,
    maker_checker_status character varying(10) DEFAULT 'Maked'::character varying NOT NULL,
    shadow_id character varying(121) DEFAULT ''::character varying NOT NULL,
    modes_id character varying(86)
);


--
--

CREATE TABLE tbls_shipment_methods (
    fin_id character varying(60) NOT NULL,
    code character varying(30),
    name character varying(30),
    is_deleted character varying(1) DEFAULT 'N'::character varying NOT NULL,
    created timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    created_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_updated timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_checked_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_maked timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_db timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    mod_id double precision DEFAULT 0 NOT NULL,
    maker_checker_status character varying(10) DEFAULT 'Maked'::character varying NOT NULL,
    shadow_id character varying(60) DEFAULT ''::character varying NOT NULL,
    shipment_method_type character varying(60)
);


--
--

CREATE TABLE tbls_shipment_record_routing (
    fin_id character varying(99) NOT NULL,
    shipment_record_id character varying(60),
    airway_bill_no character varying(30),
    leg_no double precision,
    shipment_schedule_id character varying(579),
    region_id character varying(60),
    is_deleted character varying(1) DEFAULT 'N'::character varying NOT NULL,
    created timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    created_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_updated timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_checked_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_maked timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_db timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    mod_id double precision DEFAULT 0 NOT NULL,
    maker_checker_status character varying(10) DEFAULT 'Maked'::character varying NOT NULL,
    shadow_id character varying(99) DEFAULT ''::character varying NOT NULL,
    shipment_date timestamp(6) without time zone,
    carrier_crew_extn_id character varying(111),
    arrival_date timestamp(6) without time zone,
    no_of_pcs double precision,
    chargeable_weight double precision
);


--
--

CREATE TABLE tbls_shipment_records (
    fin_id character varying(60) NOT NULL,
    shipment_method_id character varying(60),
    shipper_id character varying(60),
    consignees_id character varying(60),
    consignee_contact_name character varying(111),
    shipment_type_id character varying(60),
    shipment_arrangement_id character varying(60),
    shipment_basis_id character varying(60),
    shipment_date timestamp(6) without time zone DEFAULT clock_timestamp(),
    shipment_currency_id character varying(60),
    remarks character varying(255),
    shipment_status_id character varying(61),
    shipment_charge_status character varying(61),
    shipment_document_status character varying(61),
    security_provider_id character varying(60),
    chargeable_wt numeric(21,2),
    no_of_pieces double precision,
    regions_id character varying(60),
    signal character(1),
    is_deleted character varying(1) DEFAULT 'N'::character varying NOT NULL,
    created timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    created_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_updated timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_checked_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_maked timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_db timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    mod_id double precision DEFAULT 0 NOT NULL,
    maker_checker_status character varying(10) DEFAULT 'Maked'::character varying NOT NULL,
    shadow_id character varying(60) DEFAULT ''::character varying NOT NULL,
    vault_status_id character varying(61),
    insurance_provider character varying(60),
    shipment_provider character varying(60),
    shipment_value_usd numeric(21,2) DEFAULT 0.0,
    shipment_value_base numeric(21,2) DEFAULT 0.0,
    insurance_value_base numeric(21,2) DEFAULT 0.0,
    insurance_value_usd numeric(21,2) DEFAULT 0.0,
    carrier_crew_extn_id character varying(111),
    end_time character varying(25),
    deletion_remarks character varying(100)
);


--
--

CREATE TABLE tbls_shipment_records_his (
    fin_id character varying(60) NOT NULL,
    shipment_method_id character varying(60),
    shipper_id character varying(60),
    consignees_id character varying(60),
    consignee_contact_name character varying(111),
    shipment_type_id character varying(60),
    shipment_arrangement_id character varying(60),
    shipment_basis_id character varying(60),
    shipment_date timestamp(6) without time zone DEFAULT clock_timestamp(),
    shipment_currency_id character varying(60),
    remarks character varying(255),
    shipment_status_id character varying(61),
    shipment_charge_status character varying(61),
    shipment_document_status character varying(61),
    security_provider_id character varying(60),
    chargeable_wt numeric(21,2),
    no_of_pieces double precision,
    regions_id character varying(60),
    signal character(1),
    is_deleted character varying(1) DEFAULT 'N'::character varying NOT NULL,
    created timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    created_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_updated timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_checked_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_maked timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_db timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    mod_id double precision DEFAULT 0 NOT NULL,
    maker_checker_status character varying(10) DEFAULT 'Maked'::character varying NOT NULL,
    shadow_id character varying(60) DEFAULT ''::character varying NOT NULL,
    vault_status_id character varying(61),
    insurance_provider character varying(60),
    shipment_provider character varying(60),
    shipment_value_usd numeric(21,2) DEFAULT 0.0,
    shipment_value_base numeric(21,2) DEFAULT 0.0,
    insurance_value_base numeric(21,2) DEFAULT 0.0,
    insurance_value_usd numeric(21,2) DEFAULT 0.0,
    carrier_crew_extn_id character varying(111),
    end_time character varying(25),
    deletion_remarks character varying(100)
);


--
--

CREATE TABLE tbls_shipment_rtn_charges (
    fin_id character varying(577) NOT NULL,
    shipment_routing_id character varying(99),
    other_charges_id character varying(477),
    staff_id character varying(101),
    seal_no character varying(60),
    total numeric(21,2),
    gross_weight numeric(25,9),
    chargeable_weight numeric(25,9),
    no_of_pcs numeric(21,9),
    regions_id character varying(60),
    is_deleted character varying(1) DEFAULT 'N'::character varying NOT NULL,
    created timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    created_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_updated timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_checked_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_maked timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_db timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    mod_id double precision DEFAULT 0 NOT NULL,
    maker_checker_status character varying(10) DEFAULT 'Maked'::character varying NOT NULL,
    shadow_id character varying(577) DEFAULT ''::character varying NOT NULL,
    restricted_weight numeric(25,9),
    rate numeric(21,11),
    charge_name character varying(60)
);


--
--

CREATE TABLE tbls_shipment_schedules (
    fin_id character varying(579) NOT NULL,
    carrier_id character varying(60),
    origin_airports_id character varying(182),
    dest_airports_id character varying(182),
    schedule character varying(50),
    est_time_departure character varying(50),
    est_time_arrival character varying(50),
    route_leg_seq_no double precision,
    arrival_date character varying(50),
    cutoff_hours_before_departure character varying(20),
    available_in_a_week character varying(7),
    remarks character varying(100),
    region_id character varying(60),
    is_deleted character varying(1) DEFAULT 'N'::character varying NOT NULL,
    created timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    created_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_updated timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_checked_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_maked timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_db timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    mod_id double precision DEFAULT 0 NOT NULL,
    maker_checker_status character varying(10) DEFAULT 'Maked'::character varying NOT NULL,
    shadow_id character varying(579) DEFAULT ''::character varying NOT NULL,
    status character varying(10)
);


--
--

CREATE TABLE tbls_shipment_types (
    fin_id character varying(60) NOT NULL,
    code character varying(30),
    name character varying(30),
    regions_id character varying(60),
    is_deleted character varying(1) DEFAULT 'N'::character varying NOT NULL,
    created timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    created_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_updated timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_checked_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_maked timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_db timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    mod_id double precision DEFAULT 0 NOT NULL,
    maker_checker_status character varying(10) DEFAULT 'Maked'::character varying NOT NULL,
    shadow_id character varying(60) DEFAULT ''::character varying NOT NULL
);


--
--

CREATE TABLE tbls_shipping_documents (
    fin_id character varying(60) NOT NULL,
    document_short_code character varying(60),
    document_name character varying(100),
    document_purpose character varying(100),
    document_template_name character varying(100),
    region_id character varying(60),
    is_deleted character varying(1) DEFAULT 'N'::character varying NOT NULL,
    created timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    created_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_updated timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_checked_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_maked timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_db timestamp(6) without time zone DEFAULT clock_timestamp(),
    mod_id double precision DEFAULT 0 NOT NULL,
    maker_checker_status character varying(10) DEFAULT 'Maked'::character varying NOT NULL,
    shadow_id character varying(60) DEFAULT ''::character varying NOT NULL
);


--
--

CREATE TABLE tbls_shipping_status_config (
    fin_id character varying(216) NOT NULL,
    shipping_type character varying(30),
    source_state_id character varying(61),
    destination_state_id character varying(61),
    vault_status character varying(61),
    deal_status character varying(30),
    is_editable character varying(1) DEFAULT 'N'::character varying NOT NULL,
    add_buy_deals character varying(1) DEFAULT 'N'::character varying NOT NULL,
    add_sell_deals character varying(1) DEFAULT 'N'::character varying NOT NULL,
    regions_id character varying(60),
    is_deleted character varying(1) DEFAULT 'N'::character varying NOT NULL,
    created timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    created_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_updated timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_checked_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_maked timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_db timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    mod_id double precision DEFAULT 0 NOT NULL,
    maker_checker_status character varying(10) DEFAULT 'Maked'::character varying NOT NULL,
    shadow_id character varying(216) DEFAULT ''::character varying NOT NULL
);


--
--

CREATE TABLE tbls_ssi_rules (
    fin_id character varying(286) NOT NULL,
    customers_id character varying(60),
    branches_id character varying(91),
    ssi_rule_id character varying(120) NOT NULL,
    ssi_counter numeric(10,0) NOT NULL,
    products_code character varying(60) NOT NULL,
    currencies_id character varying(60),
    setl_modes_id character varying(60),
    cust_agent_swift_code character varying(20),
    cust_agent_account character varying(35),
    cust_agent_name1 character varying(35),
    cust_agent_name2 character varying(35),
    cust_agent_name3 character varying(35),
    cust_agent_name4 character varying(35),
    beneficiary_acc_no character varying(35),
    int_swift_code character varying(20),
    int_account character varying(35),
    bene_name1 character varying(35),
    bene_name2 character varying(35),
    bene_name3 character varying(35),
    bene_name4 character varying(35),
    additional_info1 character varying(35),
    additional_info2 character varying(35),
    additional_info3 character varying(35),
    bene_swift_code character varying(35),
    nv_code_pay character varying(60),
    nv_code_receive character varying(60),
    rule_status character varying(10),
    effective_date timestamp(6) without time zone DEFAULT clock_timestamp(),
    expirydate timestamp(6) without time zone DEFAULT clock_timestamp(),
    is_default character(1),
    msg_template_pay_id character varying(60),
    is_deleted character varying(1) DEFAULT 'N'::character varying NOT NULL,
    created timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    created_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_updated timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_checked_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_maked timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_db timestamp(6) without time zone DEFAULT clock_timestamp(),
    mod_id double precision DEFAULT 0 NOT NULL,
    maker_checker_status character varying(10) DEFAULT 'Maked'::character varying NOT NULL,
    shadow_id character varying(286) DEFAULT ''::character varying NOT NULL,
    msg_canc_pay_id character varying(60),
    sender_corr_acct character varying(30),
    receiver_corr_acct character varying(30),
    sender_corr_swift_code character varying(11),
    receiver_corr_swift_code character varying(11),
    remittance_info_1 character varying(35),
    remittance_info_2 character varying(35),
    remittance_info_3 character varying(35),
    remittance_info_4 character varying(35),
    details_of_chgs character varying(3),
    additional_info_4 character varying(35),
    additional_info_5 character varying(35),
    additional_info_6 character varying(35)
);


--
--

CREATE TABLE tbls_ssis_nv (
    fin_id character varying(81) NOT NULL,
    currency_id character varying(60),
    setl_mode_id character varying(60),
    ssi_type character varying(10),
    nv_code character varying(20),
    narration character varying(60),
    bic_code character varying(20),
    account_no character varying(35),
    gl_code character varying(20),
    status character varying(10),
    is_default character(1),
    is_deleted character varying(1) DEFAULT 'N'::character varying NOT NULL,
    created timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    created_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_updated timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_checked_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_maked timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_db timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    mod_id double precision DEFAULT 0 NOT NULL,
    maker_checker_status character varying(10) DEFAULT 'Maked'::character varying NOT NULL,
    shadow_id character varying(81) DEFAULT ''::character varying NOT NULL,
    msg_template_receive_id character varying(60),
    msg_canc_receive_id character varying(60),
    cost_centre character varying(4)
);


--
--

CREATE TABLE tbls_staff (
    fin_id character varying(101) NOT NULL,
    id_number character varying(20),
    name character varying(50),
    name_in_fl character varying(50),
    passport_no character varying(50),
    contact_no character varying(50),
    mobile_no character varying(50),
    title character varying(50),
    department character varying(50),
    signatory character varying(50),
    courier_ops character varying(50),
    airport_ops character varying(50),
    ara_permit_no character varying(50),
    aat_permit_no character varying(50),
    hactl_permit_no character varying(50),
    regions_id character varying(60),
    is_deleted character varying(1) DEFAULT 'N'::character varying NOT NULL,
    created timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    created_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_updated timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_checked_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_maked timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_db timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    mod_id double precision DEFAULT 0 NOT NULL,
    maker_checker_status character varying(10) DEFAULT 'Maked'::character varying NOT NULL,
    shadow_id character varying(101) DEFAULT ''::character varying NOT NULL,
    birthday timestamp(0) without time zone,
    gender character(1),
    is_cbni_declarant character(1),
    passport_country_of_issue character varying(60),
    passport_nationality character varying(60),
    counted_in_reporting character(1),
    staff_no character varying(60)
);


--
--

CREATE TABLE tbls_standard_pack_cfg (
    fin_id character varying(100) NOT NULL,
    box_type character varying(60),
    currency character varying(10),
    denom character varying(50),
    is_deleted character varying(1) DEFAULT 'N'::character varying NOT NULL,
    created timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    created_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_updated timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_checked_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_maked timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_db timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    mod_id double precision DEFAULT 0 NOT NULL,
    maker_checker_status character varying(10) DEFAULT 'Maked'::character varying NOT NULL,
    shadow_id character varying(60) DEFAULT ''::character varying NOT NULL,
    pack_amt double precision
);


--
--

CREATE TABLE tbls_svc_charge_prvder_int (
    fin_id character varying(334) NOT NULL,
    service_charge_id character varying(60) NOT NULL,
    service_provider_id character varying(60),
    served_city character varying(151),
    is_deleted character varying(1) DEFAULT 'N'::character varying NOT NULL,
    created timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    created_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_updated timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_checked_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_maked timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_db timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    mod_id double precision DEFAULT 0 NOT NULL,
    maker_checker_status character varying(10) DEFAULT 'Maked'::character varying NOT NULL,
    shadow_id character varying(334) DEFAULT ''::character varying NOT NULL,
    regions_id character varying(60),
    service_currency character varying(60),
    counted_in_reporting character varying(60)
);


--
--

CREATE TABLE tbls_svc_provider_acc_int (
    fin_id character varying(60) NOT NULL,
    service_provider_id character varying(60),
    service_account_type_id character varying(60),
    region_id character varying(60),
    is_deleted character varying(1) DEFAULT 'N'::character varying NOT NULL,
    created timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    created_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_updated timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_checked_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_maked timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_db timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    mod_id double precision DEFAULT 0 NOT NULL,
    maker_checker_status character varying(10) DEFAULT 'Maked'::character varying NOT NULL,
    shadow_id character varying(60) DEFAULT ''::character varying NOT NULL
);


--
--

CREATE TABLE tbls_svc_prvder_categories (
    fin_id character varying(60) NOT NULL,
    code character varying(2),
    name character varying(50),
    description character varying(50),
    regions_id character varying(60),
    is_deleted character varying(1) DEFAULT 'N'::character varying NOT NULL,
    created timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    created_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_updated timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_checked_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_maked timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_db timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    mod_id double precision DEFAULT 0 NOT NULL,
    maker_checker_status character varying(10) DEFAULT 'Maked'::character varying NOT NULL,
    shadow_id character varying(60) DEFAULT ''::character varying NOT NULL
);


--
--

CREATE TABLE tbls_svc_prvder_cnts_extn (
    fin_id character varying(60) NOT NULL,
    service_provider_id character varying(60),
    name character varying(50),
    id_number character varying(60),
    contact_nos character varying(50),
    fax_nos character varying(50),
    email character varying(50),
    contact_default character(1),
    region_id character varying(60),
    is_deleted character varying(1) DEFAULT 'N'::character varying NOT NULL,
    created timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    created_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_updated timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_checked_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_maked timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_db timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    mod_id double precision DEFAULT 0 NOT NULL,
    maker_checker_status character varying(10) DEFAULT 'COMMITTED'::character varying NOT NULL,
    shadow_id character varying(60) DEFAULT ''::character varying NOT NULL,
    regions_id character varying(60)
);


--
--

CREATE TABLE tbls_svc_prvder_ctgry_int (
    fin_id character varying(60) NOT NULL,
    service_provider_id character varying(60),
    service_account_type_id character varying(60),
    city_id character varying(151),
    currency_id character varying(60),
    included_in_reporting character(1) DEFAULT 'Y'::bpchar,
    region_id character varying(60),
    is_deleted character varying(1) DEFAULT 'N'::character varying NOT NULL,
    created timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    created_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_updated timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_checked_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_maked timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_db timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    mod_id double precision DEFAULT 0 NOT NULL,
    maker_checker_status character varying(10) DEFAULT 'Maked'::character varying NOT NULL,
    shadow_id character varying(60) DEFAULT ''::character varying NOT NULL
);


--
--

CREATE TABLE tbls_sys_parameters (
    fin_id character varying(60) NOT NULL,
    function character varying(20),
    app_system_code character varying(60),
    app_system_value character varying(400),
    is_deleted character varying(1) DEFAULT 'N'::character varying NOT NULL,
    created timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    created_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_updated timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_checked_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_maked timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_db timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    mod_id double precision DEFAULT 0 NOT NULL,
    maker_checker_status character varying(10) DEFAULT 'Maked'::character varying NOT NULL,
    shadow_id character varying(60) DEFAULT ''::character varying NOT NULL,
    app_system_label character varying(60),
    cust_type character varying(10),
    buy_sell character varying(3)
);


--
--

CREATE TABLE tbls_system_codes (
    fin_id character varying(60) NOT NULL,
    code character varying(10),
    name character varying(20),
    description character varying(255),
    is_deleted character varying(1) DEFAULT 'N'::character varying NOT NULL,
    created timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    created_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_updated timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_checked_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_maked timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_db timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    mod_id double precision DEFAULT 0 NOT NULL,
    maker_checker_status character varying(10) DEFAULT 'Maked'::character varying NOT NULL,
    shadow_id character varying(60) DEFAULT ''::character varying NOT NULL
);


--
--

CREATE TABLE tbls_tact_rates (
    fin_id character varying(426) NOT NULL,
    carrier_id character varying(60),
    origin_airports_id character varying(182),
    dest_airports_id character varying(182),
    local_currency_id character varying(60),
    tact_rate numeric(21,11),
    restricted_weight numeric(21,2),
    min_charge numeric(21,2),
    max_charge numeric(21,2),
    is_deleted character varying(1) DEFAULT 'N'::character varying NOT NULL,
    created timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    created_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_updated timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_checked_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_maked timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_db timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    mod_id double precision DEFAULT 0 NOT NULL,
    maker_checker_status character varying(10) DEFAULT 'Maked'::character varying NOT NULL,
    shadow_id character varying(426) DEFAULT ''::character varying NOT NULL,
    security_charge_included double precision,
    rate_class character varying(100) DEFAULT 'N200%'::character varying
);


--
--

CREATE TABLE tbls_trans_hs_keep (
    fin_id character varying(50) NOT NULL,
    deal_id character varying(30) NOT NULL,
    deal_ver_id character varying(30) NOT NULL,
    bnk_dl_id character varying(30) NOT NULL,
    bnk_dl_leg_id character varying(30) NOT NULL,
    sh_rec_id character varying(30) NOT NULL,
    created timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    created_by character varying(30) DEFAULT 'System'::character varying NOT NULL
);


--
--

CREATE TABLE tbls_turnover_pl (
    fin_id character varying(60) NOT NULL,
    customers_id character varying(60) NOT NULL,
    branches_id character varying(91) NOT NULL,
    reference_date timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    volume_cur_id character varying(60) NOT NULL,
    volume_daily numeric(21,2) DEFAULT 0,
    volume_mtd numeric(21,2) DEFAULT 0,
    volume_ytd numeric(21,2) DEFAULT 0,
    margin_daily numeric(21,2) DEFAULT 0,
    margin_mtd numeric(21,2) DEFAULT 0,
    buy_sell character varying(10),
    deal_type_code character varying(60) NOT NULL,
    is_deleted character varying(1) DEFAULT 'N'::character varying NOT NULL,
    created timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    created_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_updated timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_checked_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_maked timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_db timestamp(6) without time zone DEFAULT clock_timestamp(),
    mod_id double precision DEFAULT 0 NOT NULL,
    maker_checker_status character varying(10) DEFAULT 'Maked'::character varying NOT NULL,
    shadow_id character varying(60) DEFAULT ''::character varying NOT NULL,
    margin_ytd numeric(21,2)
);


--
--

CREATE TABLE tbls_ud_deal_types (
    fin_id character varying(60) NOT NULL,
    code character varying(10),
    name character varying(60),
    is_deleted character varying(1) DEFAULT 'N'::character varying NOT NULL,
    created timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    created_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_updated timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_checked_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_maked timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_db timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    mod_id double precision DEFAULT 0 NOT NULL,
    maker_checker_status character varying(10) DEFAULT 'Maked'::character varying NOT NULL,
    shadow_id character varying(60) DEFAULT ''::character varying NOT NULL
);


--
--

CREATE TABLE tbls_ud_dt_mapping (
    fin_id character varying(121) NOT NULL,
    deal_types_id character varying(60),
    ud_deal_types_id character varying(60),
    is_aml_included character(1),
    is_mis_included character(1),
    is_deleted character varying(1) DEFAULT 'N'::character varying NOT NULL,
    created timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    created_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_updated timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_checked_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_maked timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_db timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    mod_id double precision DEFAULT 0 NOT NULL,
    maker_checker_status character varying(10) DEFAULT 'Maked'::character varying NOT NULL,
    shadow_id character varying(121) DEFAULT ''::character varying NOT NULL,
    cust_bkn character varying(2) DEFAULT 'N'::character varying,
    cust_bkn_offshore character varying(2) DEFAULT 'N'::character varying,
    cust_others character varying(2) DEFAULT 'N'::character varying,
    is_default character varying(2) DEFAULT 'N'::character varying,
    include_commission character varying(2)
);


--
--

CREATE TABLE tbls_ud_dt_rpt_mapping (
    fin_id character varying(121) NOT NULL,
    ud_deal_type character varying(60),
    deal_types_id character varying(60),
    ud_deal_types_id character varying(60),
    buy_sell character varying(2),
    cust_bkn character varying(2) DEFAULT 'N'::character varying,
    cust_bkn_offshore character varying(2) DEFAULT 'N'::character varying,
    cust_others character varying(2) DEFAULT 'N'::character varying,
    is_deleted character varying(1) DEFAULT 'N'::character varying,
    created timestamp(6) without time zone DEFAULT clock_timestamp(),
    created_by character varying(30) DEFAULT 'System'::character varying,
    last_updated timestamp(6) without time zone DEFAULT clock_timestamp(),
    last_updated_by character varying(30) DEFAULT 'System'::character varying,
    last_checked_by character varying(30) DEFAULT 'System'::character varying,
    last_maked timestamp(6) without time zone DEFAULT clock_timestamp(),
    last_updated_db timestamp(6) without time zone DEFAULT clock_timestamp(),
    mod_id double precision DEFAULT 0,
    maker_checker_status character varying(10) DEFAULT 'Maked'::character varying,
    shadow_id character varying(121) DEFAULT ''::character varying,
    report_code character varying(60)
);


--
--

CREATE TABLE tbls_users_markets_int (
    fin_id character varying(121) NOT NULL,
    user_id character varying(60) NOT NULL,
    market_id character varying(60),
    is_deleted character varying(1) DEFAULT 'N'::character varying NOT NULL,
    created timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    created_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_updated timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_checked_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_maked timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_db timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    mod_id double precision DEFAULT 0 NOT NULL,
    maker_checker_status character varying(10) DEFAULT 'Maked'::character varying NOT NULL,
    shadow_id character varying(121) DEFAULT ''::character varying NOT NULL,
    user_name character varying(30)
);


--
--

CREATE TABLE tbls_vault_state_trans (
    fin_id character varying(200) NOT NULL,
    shipment_type character varying(60),
    source_state_id character varying(61),
    destination_state_id character varying(61),
    is_manual character(1),
    regions_id character varying(60),
    is_deleted character varying(1) NOT NULL,
    created timestamp(6) without time zone NOT NULL,
    created_by character varying(30) NOT NULL,
    last_updated timestamp(6) without time zone NOT NULL,
    last_updated_by character varying(30) NOT NULL,
    last_checked_by character varying(30) NOT NULL,
    last_maked timestamp(6) without time zone NOT NULL,
    last_updated_db timestamp(6) without time zone NOT NULL,
    mod_id double precision NOT NULL,
    maker_checker_status character varying(10) NOT NULL,
    shadow_id character varying(200) NOT NULL,
    reverse_flag character(1)
);


--
--

CREATE TABLE tbls_vaults (
    fin_id character varying(60) NOT NULL,
    main_vault_code character varying(20),
    main_vault_name character varying(20),
    sub_vault_code character varying(20),
    sub_vault_name character varying(20),
    cust_id character varying(60),
    brch_id character varying(91),
    product_id character varying(60),
    region_id character varying(60),
    is_deleted character varying(1) DEFAULT 'N'::character varying NOT NULL,
    created timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    created_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_updated timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_checked_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_maked timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_db timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    mod_id double precision DEFAULT 0 NOT NULL,
    maker_checker_status character varying(10) DEFAULT 'Maked'::character varying NOT NULL,
    shadow_id character varying(60) DEFAULT ''::character varying NOT NULL
);


--
--

CREATE TABLE tbls_vaults_inv_cash (
    fin_id character varying(407) NOT NULL,
    vaults_id character varying(60),
    currencies_id character varying(60),
    bank_notes_types_id character varying(60),
    bank_notes_denoms_id character varying(213),
    quantity numeric(21,2),
    amount numeric(21,2),
    bal_date timestamp(6) without time zone DEFAULT clock_timestamp(),
    regions_id character varying(60),
    shipment_record_id character varying(60),
    is_deleted character varying(1) DEFAULT 'N'::character varying NOT NULL,
    created timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    created_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_updated timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_checked_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_maked timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_db timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    mod_id numeric DEFAULT 0 NOT NULL,
    maker_checker_status character varying(10) DEFAULT 'Maked'::character varying NOT NULL,
    shadow_id character varying(407) DEFAULT ''::character varying NOT NULL
);


--
--

CREATE TABLE tbls_workflow_states (
    fin_id character varying(61) NOT NULL,
    workflow_module character varying(30),
    name character varying(30),
    deal_display_module character varying(30),
    workflow_level double precision DEFAULT 0,
    gen_confo character(1) DEFAULT 'N'::bpchar NOT NULL,
    gen_settlements character(1) DEFAULT 'N'::bpchar NOT NULL,
    release_shipment character(1) DEFAULT 'N'::bpchar NOT NULL,
    update_main_inv character(1) DEFAULT 'N'::bpchar NOT NULL,
    update_other_inv character(1) DEFAULT 'N'::bpchar NOT NULL,
    is_deal_editable character(1) DEFAULT 'Y'::bpchar,
    is_deleted character varying(1) DEFAULT 'N'::character varying NOT NULL,
    created timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    created_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_updated timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_checked_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_maked timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_db timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    mod_id double precision DEFAULT 0 NOT NULL,
    maker_checker_status character varying(10) DEFAULT 'Maked'::character varying NOT NULL,
    shadow_id character varying(61) DEFAULT ''::character varying NOT NULL,
    gen_deal_ticket character(1) DEFAULT 'N'::bpchar NOT NULL,
    vault_start character(1) DEFAULT 'N'::bpchar NOT NULL,
    is_deal_splittable character varying(1) NOT NULL,
    send_email character varying(3) DEFAULT 'N'::character varying
);


--
--

CREATE TABLE tbls_wrkflow_state_trans (
    fin_id character varying(154) NOT NULL,
    worklfow_module character varying(30),
    source_state_id character varying(61),
    destination_state_id character varying(61),
    is_manual character(1),
    regions_id character varying(60),
    is_deleted character varying(1) DEFAULT 'N'::character varying NOT NULL,
    created timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    created_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_updated timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_checked_by character varying(30) DEFAULT 'System'::character varying NOT NULL,
    last_maked timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    last_updated_db timestamp(6) without time zone DEFAULT clock_timestamp() NOT NULL,
    mod_id double precision DEFAULT 0 NOT NULL,
    maker_checker_status character varying(10) DEFAULT 'Maked'::character varying NOT NULL,
    shadow_id character varying(154) DEFAULT ''::character varying NOT NULL,
    rollback_vault character(1) DEFAULT 'N'::bpchar,
    rollback_bo character(1) DEFAULT 'N'::bpchar,
    four_eye_required character varying(1)
);


--
--

CREATE TABLE tbls_wss_positions (
    fin_id character varying(233) NOT NULL,
    bank_code character varying(60),
    area character varying(60),
    repository character varying(100),
    currency character varying(60),
    fx_position numeric(21,2),
    base_equivalent_cost numeric(21,2),
    book_rate numeric(21,11),
    closing_rate numeric(21,11),
    pnl numeric(15,5),
    reporting_date timestamp(0) without time zone,
    shadow_id character varying(233) DEFAULT '-1'::character varying,
    is_deleted character varying(1),
    created timestamp(6) without time zone,
    created_by character varying(30),
    last_updated timestamp(6) without time zone,
    last_updated_by character varying(30),
    last_checked_by character varying(30),
    last_maked timestamp(6) without time zone,
    last_updated_db timestamp(6) without time zone,
    mod_id double precision,
    maker_checker_status character varying(10)
);


--
--

CREATE VIEW vbls_bkn_deal_entries AS
 SELECT (((((deals.deal_no)::text || '_'::text) || deals.version_no) || '_'::text) || bn_legs.leg_number) AS fin_id,
    'DEAL'::text AS rule_type,
    ''::text AS external_no,
    deals.deal_no,
    deals.version_no,
    bn_legs.leg_number AS leg_no,
    prd.code AS product_type,
    prd.deal_type_code AS deal_type,
        CASE
            WHEN ((bn_legs.currencies_id)::text = (bn.setl_cur_id)::text) THEN
            CASE
                WHEN ((bn_legs.currencies_id)::text = (( SELECT tbls_regions.currencies_id
                   FROM tbls_regions
                  WHERE ((tbls_regions.fin_id)::text = (( SELECT tbls_dates_master.region_id
                           FROM tbls_dates_master))::text)))::text) THEN 'LIKE_BASE'::text
                ELSE 'LIKE'::text
            END
            ELSE 'UNLIKE'::text
        END AS deal_sub_type,
    deals.buy_sell,
    deals.entry_date,
        CASE
            WHEN (deals.trade_date < deals.action_date) THEN deals.action_date
            ELSE deals.trade_date
        END AS trade_date,
        CASE
            WHEN (deals.value_date < deals.action_date) THEN deals.action_date
            ELSE deals.value_date
        END AS value_date,
        CASE
            WHEN (bn.release_date < deals.action_date) THEN deals.action_date
            ELSE bn.release_date
        END AS release_date,
        CASE
            WHEN (bn.vault_date < deals.action_date) THEN deals.action_date
            ELSE bn.vault_date
        END AS vault_date,
        CASE
            WHEN (((deals.products_id)::text = ANY (ARRAY[('BKN_CAEX'::character varying)::text, ('BKN_CONT'::character varying)::text, ('BKN_CONR'::character varying)::text, ('BKN_DISC'::character varying)::text, ('TCQ_DISC'::character varying)::text])) AND (bn.vault2_date < deals.action_date)) THEN deals.action_date
            WHEN (((deals.products_id)::text = ANY (ARRAY[('BKN_CAEX'::character varying)::text, ('BKN_CONT'::character varying)::text, ('BKN_CONR'::character varying)::text, ('BKN_DISC'::character varying)::text, ('TCQ_DISC'::character varying)::text])) AND (bn.vault2_date >= deals.action_date)) THEN bn.vault2_date
            ELSE NULL::timestamp without time zone
        END AS vault2_date,
        CASE
            WHEN (((deals.products_id)::text = ANY (ARRAY[('BKN_CAEX'::character varying)::text, ('BKN_OFFS'::character varying)::text, ('BKN_DISC'::character varying)::text, ('TCQ_DISC'::character varying)::text])) AND (bn.release2_date < deals.action_date)) THEN deals.action_date
            WHEN (((deals.products_id)::text = ANY (ARRAY[('BKN_CAEX'::character varying)::text, ('BKN_OFFS'::character varying)::text, ('BKN_DISC'::character varying)::text, ('TCQ_DISC'::character varying)::text])) AND (bn.release2_date >= deals.action_date)) THEN bn.release2_date
            ELSE NULL::timestamp without time zone
        END AS release2_date,
    ( SELECT tbls_dates_master.system_date
           FROM tbls_dates_master) AS accounting_date,
        CASE
            WHEN (bn.release_date < deals.value_date) THEN
            CASE
                WHEN (bn.release_date < deals.action_date) THEN deals.action_date
                ELSE bn.release_date
            END
            ELSE
            CASE
                WHEN (deals.value_date < deals.action_date) THEN deals.action_date
                ELSE deals.value_date
            END
        END AS memo_rev_date,
        CASE
            WHEN ((deals.buy_sell)::text = 'B'::text) THEN bn_legs.currencies_id
            ELSE bn.setl_cur_id
        END AS buy_currency,
        CASE
            WHEN ((deals.buy_sell)::text = 'S'::text) THEN bn_legs.currencies_id
            ELSE bn.setl_cur_id
        END AS sell_currency,
        CASE
            WHEN ((deals.buy_sell)::text = 'B'::text) THEN bn_legs.amount
            ELSE bn_legs.setl_amount
        END AS buy_amount,
        CASE
            WHEN ((deals.buy_sell)::text = 'S'::text) THEN bn_legs.amount
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
            WHEN ((deals.buy_sell)::text = 'B'::text) THEN bn_legs.leg_ccy_vs_lcu_spotrate
            ELSE bn_legs.leg_ccy_vs_lcu_dealrate
        END, (0)::numeric) AS leg_ccy_vs_lcu_spotrate,
    COALESCE(bn_legs.lcu_eqv_amount, (0)::numeric) AS lcu_eqv_amount,
    COALESCE(bn_legs.lcu_setl_eqv_amount, (0)::numeric) AS lcu_setl_eqv_amount
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
  WHERE (((deals.fin_id)::text = (versions.deals_id)::text) AND (deals.version_no = versions.version_no) AND ((versions.fin_id)::text = (bn.fin_id)::text) AND ((bn.fin_id)::text = (bn_legs.bank_notes_deals_id)::text) AND ((deals.buy_sell)::text = (bn_legs.buy_sell)::text) AND ((deals.repositories_id)::text = (rp.fin_id)::text) AND ((deals.customers_id)::text = (cust.fin_id)::text) AND ((cust.type_id)::text = (ct.fin_id)::text) AND ((deals.products_id)::text = (prd.fin_id)::text) AND ((deals.ud_deal_types_id)::text = (uddt.fin_id)::text) AND ((uddt.ud_deal_types_id)::text = (uddealtypes.fin_id)::text) AND ((deals.action)::text <> 'CANCEL'::text) AND (to_char(deals.action_date, 'YYYYMMDD'::text) <= ( SELECT to_char(tbls_dates_master.accounting_date, 'YYYYMMDD'::text) AS to_char
           FROM tbls_dates_master)) AND ((deals.maker_checker_status)::text = 'COMMITTED'::text) AND ((deals.is_deleted)::text = 'N'::text) AND ((versions.maker_checker_status)::text = 'COMMITTED'::text) AND ((versions.is_deleted)::text = 'N'::text) AND ((bn.maker_checker_status)::text = 'COMMITTED'::text) AND ((bn.is_deleted)::text = 'N'::text) AND ((bn_legs.maker_checker_status)::text = 'COMMITTED'::text) AND ((bn_legs.is_deleted)::text = 'N'::text) AND ((rp.maker_checker_status)::text = 'COMMITTED'::text) AND ((rp.is_deleted)::text = 'N'::text) AND ((ct.maker_checker_status)::text = 'COMMITTED'::text) AND ((ct.is_deleted)::text = 'N'::text) AND ((cust.maker_checker_status)::text = 'COMMITTED'::text) AND ((cust.is_deleted)::text = 'N'::text) AND ((deals.products_id)::text IN ( SELECT tbls_products.fin_id
           FROM tbls_products
          WHERE ((tbls_products.code)::text = ANY (ARRAY[('BKN'::character varying)::text, ('TCQ'::character varying)::text])))) AND ((deals.branches_id)::text = (branch.fin_id)::text));


--
--

CREATE VIEW vbls_bn_ccypairs AS
 SELECT (((dealccys.currencies_id)::text || '/'::text) || (dealccys.setl_cur_id)::text) AS fin_id,
    dealccys.currencies_id,
    dealccys.setl_cur_id,
    'N'::text AS existing_pair
   FROM ( SELECT DISTINCT legs.currencies_id,
            bndeals.setl_cur_id
           FROM tbls_bank_notes_deals_legs legs,
            tbls_bank_notes_deals bndeals
          WHERE (((legs.bank_notes_deals_id)::text = (bndeals.fin_id)::text) AND (legs.currencies_id IS NOT NULL) AND (bndeals.setl_cur_id IS NOT NULL) AND ((legs.currencies_id)::text <> (bndeals.setl_cur_id)::text))) dealccys
  WHERE ((NOT ((((dealccys.currencies_id)::text || '/'::text) || (dealccys.setl_cur_id)::text) IN ( SELECT tbls_currencypairs.pairs_shortname
           FROM tbls_currencypairs))) AND (NOT ((((dealccys.setl_cur_id)::text || '/'::text) || (dealccys.currencies_id)::text) IN ( SELECT tbls_currencypairs.pairs_shortname
           FROM tbls_currencypairs))))
UNION
 SELECT DISTINCT ccypairs.pairs_shortname AS fin_id,
    ccypairs.currency1_id AS currencies_id,
    ccypairs.currency2_id AS setl_cur_id,
    'Y'::text AS existing_pair
   FROM ( SELECT DISTINCT legs.currencies_id,
            bndeals.setl_cur_id
           FROM tbls_bank_notes_deals_legs legs,
            tbls_bank_notes_deals bndeals
          WHERE (((legs.bank_notes_deals_id)::text = (bndeals.fin_id)::text) AND (legs.currencies_id IS NOT NULL) AND (bndeals.setl_cur_id IS NOT NULL) AND ((legs.currencies_id)::text <> (bndeals.setl_cur_id)::text))) dealccys,
    tbls_currencypairs ccypairs
  WHERE (((ccypairs.pairs_shortname)::text = (((dealccys.currencies_id)::text || '/'::text) || (dealccys.setl_cur_id)::text)) OR ((ccypairs.pairs_shortname)::text = (((dealccys.setl_cur_id)::text || '/'::text) || (dealccys.currencies_id)::text)))
UNION
 SELECT (((
        CASE
            WHEN ((ccypairs.currency1_id)::text = (regions.currencies_id)::text) THEN ccypairs.currency2_id
            ELSE ccypairs.currency1_id
        END)::text || '/'::text) || (regions.currencies_id)::text) AS fin_id,
        CASE
            WHEN ((ccypairs.currency1_id)::text = (regions.currencies_id)::text) THEN ccypairs.currency2_id
            ELSE ccypairs.currency1_id
        END AS currencies_id,
    regions.currencies_id AS setl_cur_id,
    'Y'::text AS existing_pair
   FROM tbls_currencypairs ccypairs,
    tbls_regions regions,
    tbls_dates_master datesmaster
  WHERE (((regions.fin_id)::text = (datesmaster.region_id)::text) AND (((ccypairs.currency1_id)::text = (regions.currencies_id)::text) OR ((ccypairs.currency2_id)::text = (regions.currencies_id)::text)) AND ((ccypairs.is_deleted)::text = 'N'::text) AND ((ccypairs.maker_checker_status)::text = 'COMMITTED'::text));


--
--

CREATE VIEW vbls_commission_entries AS
 SELECT DISTINCT ((bn.fin_id)::text || '_CHARGE'::text) AS fin_id,
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
            WHEN (deals.trade_date < deals.action_date) THEN deals.action_date
            ELSE deals.trade_date
        END AS trade_date,
        CASE
            WHEN (deals.value_date < deals.action_date) THEN deals.action_date
            ELSE deals.value_date
        END AS value_date,
        CASE
            WHEN (bn.release_date < deals.action_date) THEN deals.action_date
            ELSE bn.release_date
        END AS release_date,
        CASE
            WHEN (bn.vault_date < deals.action_date) THEN deals.action_date
            ELSE bn.vault_date
        END AS vault_date,
    NULL::timestamp without time zone AS commission_date,
        CASE
            WHEN (bn.release_date < deals.value_date) THEN
            CASE
                WHEN (bn.release_date < deals.action_date) THEN deals.action_date
                ELSE bn.release_date
            END
            ELSE
            CASE
                WHEN (deals.value_date < deals.action_date) THEN deals.action_date
                ELSE deals.value_date
            END
        END AS memo_rev_date,
    abs(bn.charge_amount) AS charge_amount,
    bn.setl_cur_id AS charge_currency,
    NULL::numeric AS commission_amount,
    ''::text AS commission_currency,
    'CHARGES'::text AS charges_commissions,
        CASE
            WHEN (bn.charge_amount > (0)::numeric) THEN 'INCOME'::text
            WHEN (bn.charge_amount = (0)::numeric) THEN ''::text
            ELSE 'EXPENSE'::text
        END AS income_exp,
    ''::text AS comm_setl_type,
    deals.repositories_id,
    rp.corp_code,
    rp.cost_center,
    cust.short_name AS customers_id,
    cust.is_resident,
    ct.type_code AS customer_type
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
  WHERE (((deals.fin_id)::text = (versions.deals_id)::text) AND (deals.version_no = versions.version_no) AND ((versions.fin_id)::text = (bn.fin_id)::text) AND ((bn.fin_id)::text = (bn_legs.bank_notes_deals_id)::text) AND ((deals.repositories_id)::text = (rp.fin_id)::text) AND ((deals.customers_id)::text = (cust.fin_id)::text) AND ((deals.products_id)::text = (prd.fin_id)::text) AND ((versions.ud_deal_types_id)::text = (uddt.fin_id)::text) AND ((uddt.ud_deal_types_id)::text = (uddealtypes.fin_id)::text) AND ((deals.action)::text <> 'CANCEL'::text) AND ((cust.type_id)::text = (ct.fin_id)::text) AND ((deals.maker_checker_status)::text = 'COMMITTED'::text) AND ((deals.is_deleted)::text = 'N'::text) AND ((versions.maker_checker_status)::text = 'COMMITTED'::text) AND ((versions.is_deleted)::text = 'N'::text) AND ((bn.maker_checker_status)::text = 'COMMITTED'::text) AND ((bn.is_deleted)::text = 'N'::text) AND ((bn_legs.maker_checker_status)::text = 'COMMITTED'::text) AND ((bn_legs.is_deleted)::text = 'N'::text) AND ((rp.maker_checker_status)::text = 'COMMITTED'::text) AND ((rp.is_deleted)::text = 'N'::text) AND ((ct.maker_checker_status)::text = 'COMMITTED'::text) AND ((ct.is_deleted)::text = 'N'::text) AND ((cust.maker_checker_status)::text = 'COMMITTED'::text) AND ((cust.is_deleted)::text = 'N'::text) AND (bn.charge_amount <> (0)::numeric) AND ((deals.products_id)::text IN ( SELECT tbls_products.fin_id
           FROM tbls_products
          WHERE ((tbls_products.code)::text = ANY (ARRAY[('BKN'::character varying)::text, ('TCQ'::character varying)::text])))) AND (to_char(deals.action_date, 'YYYYMMDD'::text) <= ( SELECT to_char(tbls_dates_master.accounting_date, 'YYYYMMDD'::text) AS to_char
           FROM tbls_dates_master)))
UNION ALL
 SELECT DISTINCT ((bn.fin_id)::text || '_COMMISSION'::text) AS fin_id,
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
            WHEN (deals.trade_date < deals.action_date) THEN deals.action_date
            ELSE deals.trade_date
        END AS trade_date,
        CASE
            WHEN (deals.value_date < deals.action_date) THEN deals.action_date
            ELSE deals.value_date
        END AS value_date,
        CASE
            WHEN (bn.release_date < deals.action_date) THEN deals.action_date
            ELSE bn.release_date
        END AS release_date,
        CASE
            WHEN (bn.vault_date < deals.action_date) THEN deals.action_date
            ELSE bn.vault_date
        END AS vault_date,
        CASE
            WHEN (bn.commission_setl_date < deals.action_date) THEN deals.action_date
            ELSE bn.commission_setl_date
        END AS commission_date,
        CASE
            WHEN (bn.release_date < deals.value_date) THEN
            CASE
                WHEN (bn.release_date < deals.action_date) THEN deals.action_date
                ELSE bn.release_date
            END
            ELSE
            CASE
                WHEN (deals.value_date < deals.action_date) THEN deals.action_date
                ELSE deals.value_date
            END
        END AS memo_rev_date,
    NULL::numeric AS charge_amount,
    ''::text AS charge_currency,
    abs(bn.commission_amount) AS commission_amount,
    bn.commission_cur_id AS commission_currency,
    'COMMISSION'::text AS charges_commissions,
        CASE
            WHEN (bn.commission_amount > (0)::numeric) THEN 'INCOME'::text
            WHEN (bn.commission_amount = (0)::numeric) THEN ''::text
            ELSE 'EXPENSE'::text
        END AS income_exp,
        CASE
            WHEN ((bn.commission_setl_type)::text = 'cash'::text) THEN 'CASH'::text
            WHEN ((bn.commission_setl_type)::text = 'tt'::text) THEN 'SETTLE A/C'::text
            ELSE ''::text
        END AS comm_setl_type,
    deals.repositories_id,
    rp.corp_code,
    rp.cost_center,
    cust.short_name AS customers_id,
    cust.is_resident,
    ct.type_code AS customer_type
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
  WHERE (((deals.fin_id)::text = (versions.deals_id)::text) AND (deals.version_no = versions.version_no) AND ((versions.fin_id)::text = (bn.fin_id)::text) AND ((bn.fin_id)::text = (bn_legs.bank_notes_deals_id)::text) AND ((deals.repositories_id)::text = (rp.fin_id)::text) AND ((deals.customers_id)::text = (cust.fin_id)::text) AND ((deals.products_id)::text = (prd.fin_id)::text) AND ((versions.ud_deal_types_id)::text = (uddt.fin_id)::text) AND ((uddt.ud_deal_types_id)::text = (uddealtypes.fin_id)::text) AND ((deals.action)::text <> 'CANCEL'::text) AND ((cust.type_id)::text = (ct.fin_id)::text) AND ((deals.maker_checker_status)::text = 'COMMITTED'::text) AND ((deals.is_deleted)::text = 'N'::text) AND ((versions.maker_checker_status)::text = 'COMMITTED'::text) AND ((versions.is_deleted)::text = 'N'::text) AND ((bn.maker_checker_status)::text = 'COMMITTED'::text) AND ((bn.is_deleted)::text = 'N'::text) AND ((bn_legs.maker_checker_status)::text = 'COMMITTED'::text) AND ((bn_legs.is_deleted)::text = 'N'::text) AND ((rp.maker_checker_status)::text = 'COMMITTED'::text) AND ((rp.is_deleted)::text = 'N'::text) AND ((ct.maker_checker_status)::text = 'COMMITTED'::text) AND ((ct.is_deleted)::text = 'N'::text) AND ((cust.maker_checker_status)::text = 'COMMITTED'::text) AND ((cust.is_deleted)::text = 'N'::text) AND (bn.commission_amount <> (0)::numeric) AND ((deals.products_id)::text IN ( SELECT tbls_products.fin_id
           FROM tbls_products
          WHERE ((tbls_products.code)::text = ANY (ARRAY[('BKN'::character varying)::text, ('TCQ'::character varying)::text])))) AND (to_char(deals.action_date, 'YYYYMMDD'::text) <= ( SELECT to_char(tbls_dates_master.accounting_date, 'YYYYMMDD'::text) AS to_char
           FROM tbls_dates_master)));


--
--

CREATE VIEW vbls_commission_reversals AS
 SELECT acc_entries.fin_id,
    acc_entries.corp_code,
    acc_entries.branch_code,
    acc_entries.major_no,
    acc_entries.minor_no,
    acc_entries.check_digit,
    acc_entries.in_out_country_code,
    acc_entries.cost_center,
    acc_entries.currencies_id,
    acc_entries.amount,
    acc_entries.debit_credit,
    acc_entries.trans_ref,
    acc_entries.description,
    acc_entries.customer_types_id,
    acc_entries.acc_rules_id,
    acc_entries.main_ledger_id,
    acc_entries.r_account_allocation_no,
    acc_entries.deal_no,
    acc_entries.version_no,
    acc_entries.region_id,
    acc_entries.repositories_id,
    acc_entries.is_deleted,
    acc_entries.created,
    acc_entries.created_by,
    acc_entries.last_updated,
    acc_entries.last_updated_by,
    acc_entries.last_checked_by,
    acc_entries.last_maked,
    acc_entries.last_updated_db,
    acc_entries.mod_id,
    acc_entries.maker_checker_status,
    acc_entries.shadow_id,
    acc_entries.is_reversal,
    acc_entries.entry_date,
    acc_entries.event_date,
    acc_entries.posting_flag,
    acc_entries.allocation_no,
    acc_entries.customers_id,
    acc_entries.deal_type,
    acc_entries.deal_sub_type,
    acc_entries.ud_deal_types_id,
    acc_entries.buy_sell,
    acc_entries.journal_desc,
    acc_entries.ctc_mtm_sign,
    acc_entries.charge_commission,
    acc_entries.income_expense,
    acc_entries.comm_setl_type,
    acc_entries.disc_setl_type,
    acc_entries.nv_code,
    acc_entries.leg_no,
    acc_entries.sub_ledger_id,
    acc_entries.gl_account_no
   FROM tbls_acc_entries_table acc_entries,
    ( SELECT DISTINCT entries.deal_no,
            entries.version_no,
            rules.fin_id AS rules_id,
            max(entries.entry_date) AS max_entries_date
           FROM tbls_deals deals,
            tbls_deal_versions versions,
            tbls_bank_notes_deals bn,
            tbls_acc_entries_table entries,
            tbls_acc_rules rules,
            tbls_dates_master dm
          WHERE (((deals.fin_id)::text = (versions.deals_id)::text) AND ((versions.fin_id)::text = (bn.fin_id)::text) AND ((entries.deal_no)::text = (deals.deal_no)::text) AND ((entries.acc_rules_id)::text = (rules.fin_id)::text) AND ((entries.description)::text = 'CHARGE_COMMISSION'::text) AND ((rules.charges_commission)::text = 'COMMISSION'::text) AND ((rules.rule_type)::text = 'CHARGE_COMMISSION'::text) AND ((deals.maker_checker_status)::text = 'COMMITTED'::text) AND ((deals.is_deleted)::text = 'N'::text) AND ((versions.maker_checker_status)::text = 'COMMITTED'::text) AND ((versions.is_deleted)::text = 'N'::text) AND ((bn.maker_checker_status)::text = 'COMMITTED'::text) AND ((bn.is_deleted)::text = 'N'::text) AND ((deals.products_id)::text IN ( SELECT tbls_products.fin_id
                   FROM tbls_products
                  WHERE ((tbls_products.code)::text = ANY (ARRAY[('BKN'::character varying)::text, ('TCQ'::character varying)::text])))) AND ((((deals.action)::text <> 'CANCEL'::text) AND (versions.version_no = entries.version_no) AND (to_char(deals.action_date, 'YYYYMMDD'::text) <= ( SELECT to_char(tbls_dates_master.accounting_date, 'YYYYMMDD'::text) AS to_char
                   FROM tbls_dates_master)) AND (to_char(bn.commission_rev_date, 'YYYYMMDD'::text) = ( SELECT to_char(tbls_dates_master.accounting_date, 'YYYYMMDD'::text) AS to_char
                   FROM tbls_dates_master)) AND ((bn.commission_setl_type)::text = 'cash'::text)) OR (((deals.action)::text = 'CANCEL'::text) AND (to_char(deals.action_date, 'YYYYMMDD'::text) = ( SELECT to_char(tbls_dates_master.accounting_date, 'YYYYMMDD'::text) AS to_char
                   FROM tbls_dates_master)) AND ((bn.commission_setl_type)::text = 'cash'::text)) OR (((deals.action)::text <> 'CANCEL'::text) AND (versions.version_no = entries.version_no) AND (to_char(deals.action_date, 'YYYYMMDD'::text) = ( SELECT to_char(tbls_dates_master.accounting_date, 'YYYYMMDD'::text) AS to_char
                   FROM tbls_dates_master)) AND (bn.commission_rev_date IS NULL) AND ((bn.commission_setl_type)::text = 'cash'::text))) AND (to_char(entries.entry_date, 'YYYYMMDD'::text) < to_char(dm.accounting_date, 'YYYYMMDD'::text)))
          GROUP BY entries.deal_no, entries.version_no, rules.fin_id) innerq
  WHERE (((acc_entries.deal_no)::text = (innerq.deal_no)::text) AND (acc_entries.version_no = innerq.version_no) AND ((acc_entries.acc_rules_id)::text = (innerq.rules_id)::text) AND (acc_entries.entry_date = innerq.max_entries_date) AND ((acc_entries.description)::text = 'CHARGE_COMMISSION'::text) AND ((acc_entries.is_reversal)::text = 'N'::text));


--
--

CREATE VIEW vbls_cons_limit_aggregate AS
 SELECT concat_ws(''::text, cust.limit_code, cons.native_currencies_id) AS fin_id,
    cust.limit_code,
    cons.native_currencies_id,
    sum(cons.util_native_amount) AS util_native_amount,
    sum(cons.util_amount) AS util_amount,
    'N'::text AS is_deleted,
    max(cons.created) AS created,
    'System'::text AS created_by,
    max(cons.last_updated) AS last_updated,
    'System'::text AS last_updated_by,
    'System'::text AS last_checked_by,
    max(cons.last_maked) AS last_maked,
    max(cons.last_updated_db) AS last_updated_db,
    max(cons.mod_id) AS mod_id,
    'COMMITTED'::text AS maker_checker_status,
    '-1'::text AS shadow_id
   FROM tbls_cons_limit_util cons,
    tbls_customers cust
  WHERE (((cons.customers_id)::text = (cust.fin_id)::text) AND ((cons.is_deleted)::text = 'N'::text) AND ((cons.shadow_id)::text = '-1'::text) AND ((cons.maker_checker_status)::text = 'COMMITTED'::text) AND ((cust.is_deleted)::text = 'N'::text) AND ((cust.shadow_id)::text = '-1'::text) AND ((cust.maker_checker_status)::text = 'COMMITTED'::text))
  GROUP BY cust.limit_code, cons.native_currencies_id;


--
--

CREATE VIEW vbls_ctc_charge_comm AS
 SELECT (((((innerq.repository_id)::text || '_'::text) || (innerq.ccy)::text) || '_'::text) || to_char(innerq.reference_date, 'YYYYMMDD'::text)) AS fin_id,
    innerq.repository_id,
    innerq.reference_date,
    innerq.ccy,
        CASE
            WHEN (innerq.type_of_charge = 'CTC'::text) THEN innerq.amt
            ELSE (0)::numeric
        END AS ctc_amt,
        CASE
            WHEN (innerq.type_of_charge = 'COMM'::text) THEN innerq.amt
            ELSE (0)::numeric
        END AS comm_amt,
        CASE
            WHEN (innerq.type_of_charge = 'CHAR'::text) THEN innerq.amt
            ELSE (0)::numeric
        END AS char_amt
   FROM ( SELECT tbls_cost_to_carry.repository_id,
            tbls_cost_to_carry.entry_date AS reference_date,
            tbls_cost_to_carry.native_ccy_id AS ccy,
            sum(tbls_cost_to_carry.base_ctc) AS amt,
            'CTC'::text AS type_of_charge
           FROM tbls_cost_to_carry
          GROUP BY tbls_cost_to_carry.repository_id, tbls_cost_to_carry.native_ccy_id, tbls_cost_to_carry.entry_date
        UNION ALL
         SELECT deals.repositories_id AS repository_id,
            deals.entry_date AS reference_date,
            bndeals.commission_cur_id AS ccy,
            sum(bndeals.commission_amount) AS amt,
            'COMM'::text AS type_of_charge
           FROM tbls_bank_notes_deals bndeals,
            tbls_deal_versions versions,
            tbls_deals deals
          WHERE (((versions.deals_id)::text = (deals.fin_id)::text) AND (deals.version_no = versions.version_no) AND ((bndeals.fin_id)::text = (versions.fin_id)::text) AND (bndeals.commission_amount <> (0)::numeric) AND ((deals.action)::text <> 'CANCEL'::text))
          GROUP BY deals.repositories_id, deals.entry_date, bndeals.commission_cur_id
        UNION ALL
         SELECT deals.repositories_id AS repository_id,
            deals.entry_date AS reference_date,
            bndeals.setl_cur_id AS ccy,
            sum(bndeals.charge_amount) AS amt,
            'CHAR'::text AS type_of_charge
           FROM tbls_bank_notes_deals bndeals,
            tbls_deal_versions versions,
            tbls_deals deals
          WHERE (((versions.deals_id)::text = (deals.fin_id)::text) AND (deals.version_no = versions.version_no) AND ((bndeals.fin_id)::text = (versions.fin_id)::text) AND (bndeals.charge_amount <> (0)::numeric) AND ((deals.action)::text <> 'CANCEL'::text))
          GROUP BY deals.repositories_id, deals.entry_date, bndeals.setl_cur_id) innerq;


--
--

CREATE VIEW vbls_ctc_entries AS
 SELECT
        CASE
            WHEN ((deals.buy_sell)::text = 'B'::text) THEN ((((deals.deal_no)::text || '_'::text) || deals.version_no) || 'N'::text)
            ELSE ((((deals.deal_no)::text || '_'::text) || deals.version_no) || 'P'::text)
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
            WHEN (deals.trade_date < deals.action_date) THEN deals.action_date
            ELSE deals.trade_date
        END AS trade_date,
        CASE
            WHEN (deals.value_date < deals.action_date) THEN deals.action_date
            ELSE deals.value_date
        END AS value_date,
    bkn.release_date,
    bkn.vault_date,
    deals.maturity_date AS memo_rev_date,
    ( SELECT max(tbls_dates_master.accounting_date) AS max
           FROM tbls_dates_master) AS accounting_date,
        CASE
            WHEN ((deals.buy_sell)::text = 'B'::text) THEN 'DEAL_SETL_AMT_NEGATIVE'::text
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
    ''::text AS funding_position_sign
   FROM tbls_deals deals,
    tbls_deal_versions versions,
    tbls_bank_notes_deals bkn,
    tbls_repositories rp,
    tbls_customers cust,
    tbls_customer_types ct,
    tbls_products prd,
    tbls_ud_dt_mapping uddt,
    tbls_ud_deal_types uddealtypes
  WHERE (((deals.fin_id)::text = (versions.deals_id)::text) AND (deals.version_no = versions.version_no) AND ((versions.fin_id)::text = (bkn.fin_id)::text) AND ((deals.repositories_id)::text = (rp.fin_id)::text) AND (btrim((deals.customers_id)::text) = btrim((cust.fin_id)::text)) AND ((cust.type_id)::text = (ct.fin_id)::text) AND ((deals.products_id)::text = (prd.fin_id)::text) AND ((deals.ud_deal_types_id)::text = (uddt.fin_id)::text) AND ((uddt.ud_deal_types_id)::text = (uddealtypes.fin_id)::text) AND ((deals.maker_checker_status)::text = 'COMMITTED'::text) AND ((deals.is_deleted)::text = 'N'::text) AND ((versions.maker_checker_status)::text = 'COMMITTED'::text) AND ((versions.is_deleted)::text = 'N'::text) AND ((bkn.maker_checker_status)::text = 'COMMITTED'::text) AND ((bkn.is_deleted)::text = 'N'::text) AND ((rp.maker_checker_status)::text = 'COMMITTED'::text) AND ((rp.is_deleted)::text = 'N'::text) AND ((ct.maker_checker_status)::text = 'COMMITTED'::text) AND ((ct.is_deleted)::text = 'N'::text) AND ((cust.maker_checker_status)::text = 'COMMITTED'::text) AND ((cust.is_deleted)::text = 'N'::text) AND ((deals.products_id)::text IN ( SELECT tbls_products.fin_id
           FROM tbls_products
          WHERE ((tbls_products.code)::text = ANY (ARRAY[('BKN'::character varying)::text, ('TCQ'::character varying)::text])))) AND ((deals.action)::text <> 'CANCEL'::text) AND ((deals.products_id)::text <> ALL (ARRAY[('BKN_CAEX'::character varying)::text, ('BKN_DISC'::character varying)::text, ('BKN_DISW'::character varying)::text, ('TCQ_DISC'::character varying)::text, ('TCQ_DISW'::character varying)::text])) AND (to_char(deals.action_date, 'YYYYMMDD'::text) <= ( SELECT to_char(tbls_dates_master.accounting_date, 'YYYYMMDD'::text) AS to_char
           FROM tbls_dates_master)))
UNION ALL
 SELECT ((((deals.deal_no)::text || '_'::text) || deals.version_no) || 'P'::text) AS fin_id,
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
            WHEN (deals.trade_date < deals.action_date) THEN deals.action_date
            ELSE deals.trade_date
        END AS trade_date,
        CASE
            WHEN (deals.value_date < deals.action_date) THEN deals.action_date
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
    ''::text AS funding_position_sign
   FROM tbls_deals deals,
    tbls_deal_versions versions,
    tbls_fx_deals fx_deals,
    tbls_repositories rp,
    tbls_customers cust,
    tbls_customer_types ct,
    tbls_ud_dt_mapping uddt,
    tbls_ud_deal_types uddealtypes
  WHERE (((deals.fin_id)::text = (versions.deals_id)::text) AND (deals.version_no = versions.version_no) AND ((versions.fin_id)::text = (fx_deals.deal_versions_id)::text) AND ((deals.repositories_id)::text = (rp.fin_id)::text) AND (btrim((deals.customers_id)::text) = btrim((cust.fin_id)::text)) AND ((cust.type_id)::text = (ct.fin_id)::text) AND ((deals.maker_checker_status)::text = 'COMMITTED'::text) AND ((deals.is_deleted)::text = 'N'::text) AND ((deals.ud_deal_types_id)::text = (uddt.fin_id)::text) AND ((uddt.ud_deal_types_id)::text = (uddealtypes.fin_id)::text) AND ((versions.maker_checker_status)::text = 'COMMITTED'::text) AND ((versions.is_deleted)::text = 'N'::text) AND ((fx_deals.maker_checker_status)::text = 'COMMITTED'::text) AND ((fx_deals.is_deleted)::text = 'N'::text) AND ((rp.maker_checker_status)::text = 'COMMITTED'::text) AND ((rp.is_deleted)::text = 'N'::text) AND ((ct.maker_checker_status)::text = 'COMMITTED'::text) AND ((ct.is_deleted)::text = 'N'::text) AND ((cust.maker_checker_status)::text = 'COMMITTED'::text) AND ((cust.is_deleted)::text = 'N'::text) AND ((deals.products_id)::text IN ( SELECT tbls_products.fin_id
           FROM tbls_products
          WHERE ((tbls_products.code)::text = 'IFX'::text))) AND ((deals.action)::text <> 'CANCEL'::text) AND (to_char(deals.action_date, 'YYYYMMDD'::text) <= ( SELECT to_char(tbls_dates_master.accounting_date, 'YYYYMMDD'::text) AS to_char
           FROM tbls_dates_master)))
UNION ALL
 SELECT ((((deals.deal_no)::text || '_'::text) || deals.version_no) || 'N'::text) AS fin_id,
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
            WHEN (deals.trade_date < deals.action_date) THEN deals.action_date
            ELSE deals.trade_date
        END AS trade_date,
        CASE
            WHEN (deals.value_date < deals.action_date) THEN deals.action_date
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
    ''::text AS funding_position_sign
   FROM tbls_deals deals,
    tbls_deal_versions versions,
    tbls_fx_deals fx_deals,
    tbls_repositories rp,
    tbls_customers cust,
    tbls_customer_types ct,
    tbls_ud_dt_mapping uddt,
    tbls_ud_deal_types uddealtypes
  WHERE (((deals.fin_id)::text = (versions.deals_id)::text) AND (deals.version_no = versions.version_no) AND ((versions.fin_id)::text = (fx_deals.deal_versions_id)::text) AND ((deals.repositories_id)::text = (rp.fin_id)::text) AND (btrim((deals.customers_id)::text) = btrim((cust.fin_id)::text)) AND ((cust.type_id)::text = (ct.fin_id)::text) AND ((deals.ud_deal_types_id)::text = (uddt.fin_id)::text) AND ((uddt.ud_deal_types_id)::text = (uddealtypes.fin_id)::text) AND ((deals.maker_checker_status)::text = 'COMMITTED'::text) AND ((deals.is_deleted)::text = 'N'::text) AND ((versions.maker_checker_status)::text = 'COMMITTED'::text) AND ((versions.is_deleted)::text = 'N'::text) AND ((fx_deals.maker_checker_status)::text = 'COMMITTED'::text) AND ((fx_deals.is_deleted)::text = 'N'::text) AND ((rp.maker_checker_status)::text = 'COMMITTED'::text) AND ((rp.is_deleted)::text = 'N'::text) AND ((ct.maker_checker_status)::text = 'COMMITTED'::text) AND ((ct.is_deleted)::text = 'N'::text) AND ((cust.maker_checker_status)::text = 'COMMITTED'::text) AND ((cust.is_deleted)::text = 'N'::text) AND ((deals.products_id)::text IN ( SELECT tbls_products.fin_id
           FROM tbls_products
          WHERE ((tbls_products.code)::text = 'IFX'::text))) AND ((deals.action)::text <> 'CANCEL'::text) AND (to_char(deals.action_date, 'YYYYMMDD'::text) <= ( SELECT to_char(tbls_dates_master.accounting_date, 'YYYYMMDD'::text) AS to_char
           FROM tbls_dates_master)))
UNION ALL
 SELECT
        CASE
            WHEN (bkn.commission_amount < (0)::numeric) THEN ((((deals.deal_no)::text || '_'::text) || deals.version_no) || 'COMM_N'::text)
            ELSE ((((deals.deal_no)::text || '_'::text) || deals.version_no) || 'COMM_P'::text)
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
            WHEN (deals.trade_date < deals.action_date) THEN deals.action_date
            ELSE deals.trade_date
        END AS trade_date,
        CASE
            WHEN (deals.value_date < deals.action_date) THEN deals.action_date
            ELSE deals.value_date
        END AS value_date,
    bkn.release_date,
    bkn.vault_date,
    deals.maturity_date AS memo_rev_date,
    ( SELECT max(tbls_dates_master.accounting_date) AS max
           FROM tbls_dates_master) AS accounting_date,
        CASE
            WHEN (bkn.commission_amount < (0)::numeric) THEN 'COMMISSION_AMOUNT_NEGATIVE'::text
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
    ''::text AS funding_position_sign
   FROM tbls_deals deals,
    tbls_deal_versions versions,
    tbls_bank_notes_deals bkn,
    tbls_repositories rp,
    tbls_customers cust,
    tbls_customer_types ct,
    tbls_products prd,
    tbls_ud_dt_mapping uddt,
    tbls_ud_deal_types uddealtypes
  WHERE ((bkn.commission_amount <> (0)::numeric) AND ((bkn.commission_setl_type)::text = 'tt'::text) AND ((deals.fin_id)::text = (versions.deals_id)::text) AND (deals.version_no = versions.version_no) AND ((versions.fin_id)::text = (bkn.fin_id)::text) AND ((deals.repositories_id)::text = (rp.fin_id)::text) AND (btrim((deals.customers_id)::text) = btrim((cust.fin_id)::text)) AND ((cust.type_id)::text = (ct.fin_id)::text) AND ((deals.products_id)::text = (prd.fin_id)::text) AND ((deals.ud_deal_types_id)::text = (uddt.fin_id)::text) AND ((uddt.ud_deal_types_id)::text = (uddealtypes.fin_id)::text) AND ((deals.maker_checker_status)::text = 'COMMITTED'::text) AND ((deals.is_deleted)::text = 'N'::text) AND ((versions.maker_checker_status)::text = 'COMMITTED'::text) AND ((versions.is_deleted)::text = 'N'::text) AND ((bkn.maker_checker_status)::text = 'COMMITTED'::text) AND ((bkn.is_deleted)::text = 'N'::text) AND ((rp.maker_checker_status)::text = 'COMMITTED'::text) AND ((rp.is_deleted)::text = 'N'::text) AND ((ct.maker_checker_status)::text = 'COMMITTED'::text) AND ((ct.is_deleted)::text = 'N'::text) AND ((cust.maker_checker_status)::text = 'COMMITTED'::text) AND ((cust.is_deleted)::text = 'N'::text) AND ((deals.products_id)::text IN ( SELECT tbls_products.fin_id
           FROM tbls_products
          WHERE ((tbls_products.code)::text = ANY (ARRAY[('BKN'::character varying)::text, ('TCQ'::character varying)::text])))) AND ((deals.action)::text <> 'CANCEL'::text) AND ((deals.products_id)::text <> ALL (ARRAY[('BKN_CAEX'::character varying)::text, ('BKN_DISC'::character varying)::text, ('BKN_DISW'::character varying)::text, ('TCQ_DISC'::character varying)::text, ('TCQ_DISW'::character varying)::text])) AND (to_char(deals.action_date, 'YYYYMMDD'::text) <= ( SELECT to_char(tbls_dates_master.accounting_date, 'YYYYMMDD'::text) AS to_char
           FROM tbls_dates_master)))
UNION ALL
 SELECT (((((((((ctc.repository_id)::text || '_'::text) || (ctc.native_ccy_id)::text) || '_'::text) || 'ALL'::text) || '_'::text) || to_char(ctc.reference_date, 'YYYYMMDD'::text)) || '_'::text) || (ctc.interest_amount_sign)::text) AS fin_id,
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
    ctc.interest_amount_sign AS funding_position_sign
   FROM tbls_cost_to_carry ctc,
    tbls_repositories rp
  WHERE (((ctc.repository_id)::text = (rp.fin_id)::text) AND ((ctc.maker_checker_status)::text = 'COMMITTED'::text) AND ((ctc.is_deleted)::text = 'N'::text) AND ((rp.maker_checker_status)::text = 'COMMITTED'::text) AND ((rp.is_deleted)::text = 'N'::text) AND (ctc.entry_date = ( SELECT tbls_dates_master.accounting_date
           FROM tbls_dates_master)))
  GROUP BY ctc.reference_date, ctc.entry_date, ctc.interest_amount_sign, ctc.native_ccy_id, ctc.repository_id, rp.corp_code, rp.cost_center;


--
--

CREATE VIEW vbls_ctc_view AS
 SELECT (((((((ctc.repository_id)::text || '_'::text) || (openbal.currency_id)::text) || '_'::text) || to_char(ctc.reference_date, 'YYYYMMDD'::text)) || '_'::text) || to_char(openbal.past_date, 'YYYYMMDD'::text)) AS fin_id,
    ctc.repository_id,
    openbal.currency_id,
    sum(openbal.funding_amount) AS funding_amount,
    avg(ctc.rate) AS rate,
    sum(ctc.native_ctc) AS native_ctc,
    sum(ctc.base_ctc) AS base_ctc,
    ctc.reference_date,
    openbal.past_date
   FROM tbls_cost_to_carry ctc,
    ( SELECT tbls_daily_funding_open_bal.currency_id,
            tbls_daily_funding_open_bal.repository_id,
            sum(tbls_daily_funding_open_bal.funding_amount) AS funding_amount,
            tbls_daily_funding_open_bal.product_id,
            tbls_daily_funding_open_bal.past_date,
            tbls_daily_funding_open_bal.nostro
           FROM tbls_daily_funding_open_bal
          GROUP BY tbls_daily_funding_open_bal.currency_id, tbls_daily_funding_open_bal.repository_id, tbls_daily_funding_open_bal.product_id, tbls_daily_funding_open_bal.past_date, tbls_daily_funding_open_bal.nostro) openbal
  WHERE (((openbal.repository_id)::text = (ctc.repository_id)::text) AND ((openbal.product_id)::text = (ctc.product_id)::text) AND ((openbal.currency_id)::text = (ctc.native_ccy_id)::text) AND (openbal.past_date = ctc.next_business_date) AND ((openbal.nostro)::text = (ctc.nostro)::text))
  GROUP BY ctc.repository_id, openbal.currency_id, ctc.reference_date, openbal.past_date;


--
--

CREATE VIEW vbls_deal_alloc_no_dtl AS
 SELECT deals.fin_id,
    deals.repositories_id,
    deals.deal_no AS deal_number,
    dealversions.version_no AS deals_version_no,
    customers.short_name AS customers_short_name,
    customers.name AS customers_name,
    branches.short_name AS branches_short_name,
    branches.fin_id AS branches_id,
    branches.name AS branches_name,
    deals.entry_date,
    deals.trade_date,
    deals.value_date,
    COALESCE(dealssi.nv_code, ' '::character varying) AS nv_code,
    COALESCE(dealssi.setl_mode_id, ' '::character varying) AS nv_setl_code,
        CASE
            WHEN (allocno.allocation_no IS NULL) THEN (substr((deals.deal_no)::text, 5, 9))::character varying
            ELSE allocno.allocation_no
        END AS allocation_no,
    datesmaster.system_date,
    COALESCE(banknotesdeals.setl_cur_id, ''::character varying) AS setl_cur_id,
    COALESCE(banknotesdeals.net_setl_amt, 0.00) AS net_setl_amt
   FROM tbls_bank_notes_deals banknotesdeals,
    (tbls_deal_versions dealversions
     LEFT JOIN tbls_deal_ssi dealssi ON (((dealversions.fin_id)::text = (dealssi.deal_versions_id)::text))),
    (tbls_deals deals
     LEFT JOIN tbls_acc_allocno allocno ON (((deals.deal_no)::text = (allocno.deal_no)::text))),
    tbls_customers customers,
    tbls_branches branches,
    tbls_dates_master datesmaster
  WHERE ((deals.version_no = dealversions.version_no) AND ((banknotesdeals.fin_id)::text = (dealversions.fin_id)::text) AND ((dealversions.deals_id)::text = (deals.fin_id)::text) AND ((banknotesdeals.fin_id)::text = (dealversions.fin_id)::text) AND ((dealversions.customers_id)::text = (customers.fin_id)::text) AND ((dealversions.branches_id)::text = (branches.fin_id)::text));


--
--

CREATE VIEW vbls_deal_search_view AS
 SELECT ((banknotesdeals.fin_id)::text || COALESCE(settlements.version_no, ((0)::bigint)::double precision)) AS fin_id,
    COALESCE(banknotesdeals.fully_funded, ' '::bpchar) AS fully_funded,
    banknotesdeals.vault_date,
        CASE
            WHEN ((products.deal_type_name)::text = 'ECI Repatriation'::text) THEN banknotesdeals.depo_withdraw_date
            WHEN ((products.deal_type_name)::text = 'ECI Top-up'::text) THEN banknotesdeals.depo_withdraw_date
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
    COALESCE(settlements.version_no, ((0)::bigint)::double precision) AS setl_version_no,
    COALESCE(settlements.setl_amount, (0)::numeric) AS setl_amt,
    COALESCE(settlements.setl_origin, ' '::character varying) AS setl_origin,
    COALESCE(settlements.pay_receive, ' '::bpchar) AS setl_pay_receive,
    COALESCE(to_char(settlements.setl_date, 'DD/MM/YYYY'::text), ' '::text) AS setl_date,
    COALESCE(to_char(settlements.setl_release_date, 'DD/MM/YYYY'::text), '01/01/1970'::text) AS setl_release_date,
        CASE
            WHEN (((COALESCE(settlements.is_deleted, 'N'::character varying))::text = 'Y'::text) AND ((COALESCE(workflowstatessetl.name, ' '::character varying))::text = 'NETTEDC'::text)) THEN 'N'::character varying
            ELSE COALESCE(settlements.is_deleted, 'N'::character varying)
        END AS setl_deleted,
    workflowstatesdeals.name AS deal_status,
    COALESCE(dealstatus.operations_userid, ' '::character varying) AS deal_status_validator,
    workflowstatesdeals.workflow_level AS deal_status_level,
    workflowstatesshipment.name AS shipment_status,
    workflowstatesvault.name AS vault_status,
    COALESCE(workflowstatessetl.name, ' '::character varying) AS setl_status,
    COALESCE(workflowstatessetl.workflow_level, (('-1'::integer)::bigint)::double precision) AS setl_status_level,
    COALESCE(ssinv.ssi_type, ' '::character varying) AS ssi_nv_type,
    COALESCE(dealstatus.fo_remarks, ' '::character varying) AS fo_remarks,
    COALESCE(dealstatus.bo_remarks, ' '::character varying) AS setl_remarks
   FROM (tbls_bank_notes_deals banknotesdeals
     LEFT JOIN tbls_sdis sdis ON (((banknotesdeals.sdi_id)::text = (sdis.fin_id)::text))),
    ((((tbls_deal_versions dealversions
     LEFT JOIN tbls_deal_ssi dealssi ON (((dealversions.fin_id)::text = (dealssi.deal_versions_id)::text)))
     LEFT JOIN tbls_ssis_nv ssinv ON (((dealssi.nv_code)::text = (ssinv.fin_id)::text)))
     LEFT JOIN tbls_settlements settlements ON ((((dealversions.fin_id)::text = (settlements.deal_versions_id)::text) AND (((settlements.is_deleted)::text = 'N'::text) OR ((settlements.status_id)::text = 'PAYMENTS_CANCELLED'::text) OR ((settlements.status_id)::text = 'PAYMENTS_NETTEDP'::text) OR ((settlements.status_id)::text = 'PAYMENTS_NETTEDC'::text)))))
     LEFT JOIN tbls_workflow_states workflowstatessetl ON (((workflowstatessetl.fin_id)::text = (settlements.status_id)::text))),
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
  WHERE (((deals.version_no = dealversions.version_no) OR ((settlements.status_id)::text = 'PAYMENTS_CANCELLED'::text)) AND ((banknotesdeals.fin_id)::text = (dealversions.fin_id)::text) AND ((dealversions.deals_id)::text = (deals.fin_id)::text) AND ((banknotesdeals.fin_id)::text = (dealversions.fin_id)::text) AND (((dealversions.customers_id)::text = (customers.fin_id)::text) AND ((banknotesdeals.fin_id)::text = (dealversions.fin_id)::text)) AND (((dealversions.branches_id)::text = (branches.fin_id)::text) AND ((banknotesdeals.fin_id)::text = (dealversions.fin_id)::text)) AND (((dealversions.products_id)::text = (products.fin_id)::text) AND ((banknotesdeals.fin_id)::text = (dealversions.fin_id)::text)) AND (((dealstatus.fin_id)::text = (deals.deal_no)::text) AND ((dealstatus.deal_status_id)::text = (workflowstatesdeals.fin_id)::text)) AND (((uddealtypes.fin_id)::text = (uddtmapping.ud_deal_types_id)::text) AND ((uddtmapping.fin_id)::text = (deals.ud_deal_types_id)::text)) AND ((workflowstatesshipment.fin_id)::text = (dealstatus.shipping_status_id)::text) AND ((workflowstatesvault.fin_id)::text = (dealstatus.vault_status_id)::text));


--
--

CREATE VIEW vbls_deal_search_w_legs_view AS
 SELECT ((banknotesdeals.fin_id)::text || COALESCE(settlements.version_no, ((0)::bigint)::double precision)) AS fin_id,
    COALESCE(banknotesdeals.fully_funded, ' '::bpchar) AS fully_funded,
    banknotesdeals.vault_date,
        CASE
            WHEN ((products.deal_type_name)::text = 'ECI Repatriation'::text) THEN banknotesdeals.depo_withdraw_date
            WHEN ((products.deal_type_name)::text = 'ECI Top-up'::text) THEN banknotesdeals.depo_withdraw_date
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
    COALESCE(settlements.version_no, ((0)::bigint)::double precision) AS setl_version_no,
    COALESCE(settlements.setl_amount, (0)::numeric) AS setl_amt,
    COALESCE(settlements.setl_origin, ' '::character varying) AS setl_origin,
    COALESCE(settlements.pay_receive, ' '::bpchar) AS setl_pay_receive,
    COALESCE(to_char(settlements.setl_date, 'DD/MM/YYYY'::text), ' '::text) AS setl_date,
    COALESCE(to_char(settlements.setl_release_date, 'DD/MM/YYYY'::text), '01/01/1970'::text) AS setl_release_date,
        CASE
            WHEN (((COALESCE(settlements.is_deleted, 'N'::character varying))::text = 'Y'::text) AND ((COALESCE(workflowstatessetl.name, ' '::character varying))::text = 'NETTEDC'::text)) THEN 'N'::character varying
            ELSE COALESCE(settlements.is_deleted, 'N'::character varying)
        END AS setl_deleted,
    workflowstatesdeals.name AS deal_status,
    COALESCE(dealstatus.operations_userid, ' '::character varying) AS deal_status_validator,
    workflowstatesdeals.workflow_level AS deal_status_level,
    workflowstatesshipment.name AS shipment_status,
    workflowstatesvault.name AS vault_status,
    COALESCE(workflowstatessetl.name, ' '::character varying) AS setl_status,
    COALESCE(workflowstatessetl.workflow_level, (('-1'::integer)::bigint)::double precision) AS setl_status_level,
    COALESCE(dealstatus.fo_remarks, ' '::character varying) AS fo_remarks,
    ( SELECT string_agg((tbls_bank_notes_deals_legs.currencies_id)::text, '|'::text ORDER BY tbls_bank_notes_deals_legs.bank_notes_deals_id) AS leg_curr
           FROM tbls_bank_notes_deals_legs
          WHERE ((tbls_bank_notes_deals_legs.bank_notes_deals_id)::text = (banknotesdeals.fin_id)::text)) AS leg_currencies,
    COALESCE(ssinv.ssi_type, ' '::character varying) AS ssi_nv_type,
    COALESCE(dealstatus.bo_remarks, ' '::character varying) AS setl_remarks
   FROM (tbls_bank_notes_deals banknotesdeals
     LEFT JOIN tbls_sdis sdis ON (((banknotesdeals.sdi_id)::text = (sdis.fin_id)::text))),
    ((((tbls_deal_versions dealversions
     LEFT JOIN tbls_deal_ssi dealssi ON (((dealversions.fin_id)::text = (dealssi.deal_versions_id)::text)))
     LEFT JOIN tbls_ssis_nv ssinv ON (((dealssi.nv_code)::text = (ssinv.fin_id)::text)))
     LEFT JOIN tbls_settlements settlements ON ((((dealversions.fin_id)::text = (settlements.deal_versions_id)::text) AND (((settlements.is_deleted)::text = 'N'::text) OR ((settlements.status_id)::text = 'PAYMENTS_CANCELLED'::text) OR ((settlements.status_id)::text = 'PAYMENTS_NETTEDP'::text) OR ((settlements.status_id)::text = 'PAYMENTS_NETTEDC'::text)))))
     LEFT JOIN tbls_workflow_states workflowstatessetl ON (((workflowstatessetl.fin_id)::text = (settlements.status_id)::text))),
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
  WHERE (((deals.version_no = dealversions.version_no) OR ((settlements.status_id)::text = 'PAYMENTS_CANCELLED'::text)) AND ((banknotesdeals.fin_id)::text = (dealversions.fin_id)::text) AND ((dealversions.deals_id)::text = (deals.fin_id)::text) AND ((banknotesdeals.fin_id)::text = (dealversions.fin_id)::text) AND (((dealversions.customers_id)::text = (customers.fin_id)::text) AND ((banknotesdeals.fin_id)::text = (dealversions.fin_id)::text)) AND (((dealversions.branches_id)::text = (branches.fin_id)::text) AND ((banknotesdeals.fin_id)::text = (dealversions.fin_id)::text)) AND (((dealversions.products_id)::text = (products.fin_id)::text) AND ((banknotesdeals.fin_id)::text = (dealversions.fin_id)::text)) AND (((dealstatus.fin_id)::text = (deals.deal_no)::text) AND ((dealstatus.deal_status_id)::text = (workflowstatesdeals.fin_id)::text)) AND (((uddealtypes.fin_id)::text = (uddtmapping.ud_deal_types_id)::text) AND ((uddtmapping.fin_id)::text = (deals.ud_deal_types_id)::text)) AND ((workflowstatesshipment.fin_id)::text = (dealstatus.shipping_status_id)::text) AND ((workflowstatesvault.fin_id)::text = (dealstatus.vault_status_id)::text));


--
--

CREATE VIEW vbls_deals AS
 SELECT (((((deals.deal_no)::text || '_'::text) || deals.version_no) || '_'::text) || bn_legs.leg_number) AS fin_id,
    deals.deal_no,
    deals.version_no,
    bn_legs.leg_number AS leg_no,
    prd.code AS product_type,
    deals.buy_sell,
        CASE
            WHEN (deals.trade_date < deals.entry_date) THEN deals.entry_date
            ELSE deals.trade_date
        END AS trade_date,
    deals.value_date,
    COALESCE(( SELECT tbls_currencypairs.fin_id
           FROM tbls_currencypairs
          WHERE (((tbls_currencypairs.currency1_id)::text = (bn_legs.currencies_id)::text) AND ((tbls_currencypairs.currency2_id)::text = (bn.setl_cur_id)::text))), ( SELECT tbls_currencypairs.fin_id
           FROM tbls_currencypairs
          WHERE (((tbls_currencypairs.currency2_id)::text = (bn_legs.currencies_id)::text) AND ((tbls_currencypairs.currency1_id)::text = (bn.setl_cur_id)::text))), ((((bn_legs.currencies_id)::text || '/'::text) || (bn.setl_cur_id)::text))::character varying) AS currencypair,
    bn_legs.pl_amount AS leg_margin_amount,
    bn_legs.amount AS leg_amount,
    deals.users_id AS trader,
    deals.entry_date,
        CASE
            WHEN ((deals.buy_sell)::text = 'B'::text) THEN bn_legs.currencies_id
            ELSE bn.setl_cur_id
        END AS buy_currency,
        CASE
            WHEN ((deals.buy_sell)::text = 'S'::text) THEN bn_legs.currencies_id
            ELSE bn.setl_cur_id
        END AS sell_currency,
        CASE
            WHEN ((deals.buy_sell)::text = 'B'::text) THEN bn_legs.amount
            ELSE bn_legs.setl_amount
        END AS buy_amount,
        CASE
            WHEN ((deals.buy_sell)::text = 'S'::text) THEN bn_legs.amount
            ELSE bn_legs.setl_amount
        END AS sell_amount,
    bn_legs.setl_amount AS settlement_amount,
    deals.repositories_id,
    deals.customers_id,
    cust.country_incorporation_id AS customer_country,
    cust.is_resident,
    ct.type_code AS customer_type,
    bn_legs.deal_rate,
    bn_legs.market_rate,
    bn_legs.pl_amount AS margin,
    bn.setl_cur_id AS margin_cur,
    deals.ud_deal_types_id,
    uddt.is_mis_included
   FROM tbls_deals deals,
    tbls_deal_versions versions,
    tbls_bank_notes_deals bn,
    tbls_bank_notes_deals_legs bn_legs,
    tbls_repositories rp,
    tbls_customers cust,
    tbls_customer_types ct,
    tbls_products prd,
    tbls_ud_dt_mapping uddt
  WHERE (((deals.fin_id)::text = (versions.deals_id)::text) AND (deals.version_no = versions.version_no) AND ((versions.fin_id)::text = (bn.fin_id)::text) AND ((bn.fin_id)::text = (bn_legs.bank_notes_deals_id)::text) AND ((deals.buy_sell)::text = (bn_legs.buy_sell)::text) AND ((deals.repositories_id)::text = (rp.fin_id)::text) AND ((deals.customers_id)::text = (cust.fin_id)::text) AND ((cust.type_id)::text = (ct.fin_id)::text) AND ((deals.products_id)::text = (prd.fin_id)::text) AND ((deals.action)::text <> 'CANCEL'::text) AND ((deals.ud_deal_types_id)::text = (uddt.fin_id)::text) AND (to_char(deals.entry_date, 'YYYYMMDD'::text) <= ( SELECT to_char(tbls_dates_master.reporting_date, 'YYYYMMDD'::text) AS to_char
           FROM tbls_dates_master)) AND ((deals.maker_checker_status)::text = 'COMMITTED'::text) AND ((deals.is_deleted)::text = 'N'::text) AND ((versions.maker_checker_status)::text = 'COMMITTED'::text) AND ((versions.is_deleted)::text = 'N'::text) AND ((bn.maker_checker_status)::text = 'COMMITTED'::text) AND ((bn.is_deleted)::text = 'N'::text) AND ((bn_legs.maker_checker_status)::text = 'COMMITTED'::text) AND ((bn_legs.is_deleted)::text = 'N'::text) AND ((rp.maker_checker_status)::text = 'COMMITTED'::text) AND ((rp.is_deleted)::text = 'N'::text) AND ((ct.maker_checker_status)::text = 'COMMITTED'::text) AND ((ct.is_deleted)::text = 'N'::text) AND ((cust.maker_checker_status)::text = 'COMMITTED'::text) AND ((cust.is_deleted)::text = 'N'::text) AND ((deals.products_id)::text IN ( SELECT tbls_products.fin_id
           FROM tbls_products
          WHERE ((tbls_products.code)::text = ANY (ARRAY[('BKN'::character varying)::text, ('TCQ'::character varying)::text])))))
UNION ALL
 SELECT (((deals.deal_no)::text || '_'::text) || deals.version_no) AS fin_id,
    deals.deal_no,
    deals.version_no,
    0 AS leg_no,
    'IFX'::character varying AS product_type,
    fx_deals.buy_sell,
        CASE
            WHEN (deals.trade_date < deals.action_date) THEN deals.action_date
            ELSE deals.trade_date
        END AS trade_date,
    deals.value_date,
    fx_deals.pair_id AS currencypair,
    COALESCE(fx_deals.pl_amount, (0)::numeric) AS leg_margin_amount,
        CASE
            WHEN ((fx_deals.buy_sell)::text = 'B'::text) THEN fx_deals.buy_amount
            ELSE fx_deals.sell_amount
        END AS leg_amount,
    deals.users_id AS trader,
    deals.entry_date,
    fx_deals.buy_currency_id AS buy_currency,
    fx_deals.sell_currency_id AS sell_currency,
    COALESCE(fx_deals.buy_amount, (0)::numeric) AS buy_amount,
    COALESCE(fx_deals.sell_amount, (0)::numeric) AS sell_amount,
    0 AS settlement_amount,
    deals.repositories_id,
    deals.customers_id,
    cust.country_incorporation_id AS customer_country,
    cust.is_resident,
    ct.type_code AS customer_type,
    fx_deals.deal_rate,
    fx_deals.spot_rate AS market_rate,
        CASE
            WHEN ((fx_deals.buy_sell)::text = 'B'::text) THEN ((fx_deals.spot_rate - fx_deals.deal_rate) * fx_deals.buy_amount)
            ELSE ((fx_deals.deal_rate - fx_deals.spot_rate) * fx_deals.sell_amount)
        END AS margin,
        CASE
            WHEN ((fx_deals.buy_sell)::text = 'B'::text) THEN fx_deals.sell_currency_id
            ELSE fx_deals.buy_currency_id
        END AS margin_cur,
    deals.ud_deal_types_id,
    uddt.is_mis_included
   FROM tbls_deals deals,
    tbls_deal_versions versions,
    tbls_fx_deals fx_deals,
    tbls_repositories rp,
    tbls_customers cust,
    tbls_customer_types ct,
    tbls_ud_dt_mapping uddt
  WHERE (((deals.fin_id)::text = (versions.deals_id)::text) AND (deals.version_no = versions.version_no) AND ((versions.fin_id)::text = (fx_deals.deal_versions_id)::text) AND ((deals.repositories_id)::text = (rp.fin_id)::text) AND ((deals.customers_id)::text = (cust.fin_id)::text) AND ((deals.ud_deal_types_id)::text = (uddt.fin_id)::text) AND ((cust.type_id)::text = (ct.fin_id)::text) AND ((deals.action)::text <> 'CANCEL'::text) AND (to_char(deals.entry_date, 'YYYYMMDD'::text) <= ( SELECT to_char(tbls_dates_master.reporting_date, 'YYYYMMDD'::text) AS to_char
           FROM tbls_dates_master)) AND ((deals.maker_checker_status)::text = 'COMMITTED'::text) AND ((deals.is_deleted)::text = 'N'::text) AND ((versions.maker_checker_status)::text = 'COMMITTED'::text) AND ((versions.is_deleted)::text = 'N'::text) AND ((fx_deals.maker_checker_status)::text = 'COMMITTED'::text) AND ((fx_deals.is_deleted)::text = 'N'::text) AND ((rp.maker_checker_status)::text = 'COMMITTED'::text) AND ((rp.is_deleted)::text = 'N'::text) AND ((ct.maker_checker_status)::text = 'COMMITTED'::text) AND ((ct.is_deleted)::text = 'N'::text) AND ((cust.maker_checker_status)::text = 'COMMITTED'::text) AND ((cust.is_deleted)::text = 'N'::text) AND ((deals.products_id)::text IN ( SELECT tbls_products.fin_id
           FROM tbls_products
          WHERE ((tbls_products.code)::text = 'IFX'::text))));


--
--

CREATE VIEW vbls_deleterowids AS
 SELECT row_number() OVER (ORDER BY tbls_shipping_status_config.fin_id) AS champak
   FROM tbls_shipping_status_config
  WHERE ((tbls_shipping_status_config.is_deleted)::text = 'Y'::text);


--
--

CREATE VIEW vbls_discrepancy_entries AS
 SELECT (((record.discrepancy_number)::text || '_'::text) || leg.leg_number) AS fin_id,
    'DISCREPANCY RECORD'::text AS rule_type,
    record.discrepancy_number,
    leg.leg_number AS leg_no,
    record.products_id AS product_type,
    'ALL'::text AS deal_type,
        CASE
            WHEN (rectype.plus_minus = 'M'::bpchar) THEN 'EXCESS'::text
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
    record.sdi_id AS discrepancy_sdi
   FROM tbls_discrepancy_records record,
    tbls_discrepancy_record_legs leg,
    tbls_discrepancy_types rectype,
    tbls_customers cust,
    tbls_customer_types ct,
    tbls_repositories repositories,
    tbls_dates_master datesmaster,
    tbls_regions regions
  WHERE (((record.fin_id)::text = (leg.discrepancy_record_id)::text) AND ((record.discrepancy_type_id)::text = (rectype.fin_id)::text) AND ((record.customers_id)::text = (cust.fin_id)::text) AND ((cust.type_id)::text = (ct.fin_id)::text) AND ((regions.fin_id)::text = (datesmaster.region_id)::text) AND ((repositories.fin_id)::text = (record.repository_id)::text) AND ((record.action)::text <> 'CANCEL'::text));


--
--

CREATE VIEW vbls_discrepancy_search AS
 SELECT discinfo.fin_id,
    discinfo.user_id,
    discinfo.shipment_records_id,
    discinfo.products_id,
    discinfo.action,
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
    discrecord2.shipment_date AS shipmentdate,
    discinfo.version_no
   FROM tbls_discrepancy_records discrecord2,
    ( SELECT discrecord.fin_id,
            discrecord.last_updated_by AS user_id,
            discrecord.shipment_records_id,
            discrecord.products_id,
            discrecord.action,
            disctype.name AS discrepancy_type,
            discrecord.incurrence_date,
            discrecord.discrepancy_claim,
            states.name AS discrepancy_status,
            sdis.sdi_code AS sdi,
            discrecord.customers_id,
            customers.name AS customers_name,
            customers.short_name AS customers_short_name,
            customers.ctp_no AS customers_ctp_no,
            discrecord.branches_id,
            branches.name AS branches_name,
            branches.short_name AS branches_short_name,
                CASE
                    WHEN (sum(discreclegs.outstanding_amount) = (0)::numeric) THEN 'SETTLED'::text
                    ELSE 'UNSETTLED'::text
                END AS settled_flag,
            discrecord.version_no
           FROM tbls_discrepancy_records discrecord,
            tbls_workflow_states states,
            tbls_customers customers,
            tbls_branches branches,
            tbls_discrepancy_types disctype,
            tbls_discrepancy_record_legs discreclegs,
            tbls_dates_master datesmaster,
            tbls_sdis sdis
          WHERE (((discrecord.discrepancy_type_id)::text = (disctype.fin_id)::text) AND ((discrecord.status_id)::text = (states.fin_id)::text) AND ((discrecord.customers_id)::text = (customers.fin_id)::text) AND ((discrecord.branches_id)::text = (branches.fin_id)::text) AND ((discreclegs.discrepancy_record_id)::text = (discrecord.fin_id)::text) AND (((discrecord.action)::text = ANY (ARRAY[('INSERT'::character varying)::text, ('UPDATE'::character varying)::text, ('AMEND'::character varying)::text])) OR (((discrecord.action)::text = 'CANCEL'::text) AND (discrecord.action_date = datesmaster.system_date))) AND ((discrecord.sdi_id)::text = (sdis.fin_id)::text))
          GROUP BY discrecord.fin_id, disctype.name, discrecord.incurrence_date, discrecord.discrepancy_claim, states.name, sdis.sdi_code, customers.name, customers.short_name, customers.ctp_no, branches.name, branches.short_name, discrecord.shipment_records_id, discrecord.last_updated_by, discrecord.customers_id, discrecord.branches_id, discrecord.products_id, discrecord.action, discrecord.version_no) discinfo
  WHERE ((discrecord2.fin_id)::text = (discinfo.fin_id)::text)
  ORDER BY discrecord2.fin_id DESC;


--
--

CREATE VIEW vbls_dly_accounting_balance AS
 SELECT row_number() OVER () AS fin_id,
    iq.repository_id,
    iq.account_id,
    iq.account_name,
    iq.currency_id,
    iq.reference_date,
    iq.sap_gl_no,
    iq.trial_balance_date,
    COALESCE((iq.total_debit_open - iq.total_credit_open), (0)::numeric) AS total_open,
    COALESCE((iq.total_credit_close - iq.total_credit_open), (0)::numeric) AS total_credit,
    COALESCE((iq.total_debit_close - iq.total_debit_open), (0)::numeric) AS total_debit,
    COALESCE((iq.total_debit_close - iq.total_credit_close), (0)::numeric) AS total_close,
    iq.nostro,
    iq.ios_code,
    iq.corp_code,
    iq.branch_code,
    iq.cost_center,
    iq.customer_types_id
   FROM ( SELECT tbls_dly_accounting_balance.repository_id,
            tbls_dly_accounting_balance.account_id,
            tbls_dly_accounting_balance.account_name,
            tbls_dly_accounting_balance.currency_id,
            sum(
                CASE
                    WHEN ((tbls_dly_accounting_balance.credit_debit)::text = 'C'::text) THEN tbls_dly_accounting_balance.amount
                    ELSE (0)::numeric
                END) AS total_credit_close,
            sum(
                CASE
                    WHEN ((tbls_dly_accounting_balance.credit_debit)::text = 'C'::text) THEN tbls_dly_accounting_balance.opening_balance
                    ELSE (0)::numeric
                END) AS total_credit_open,
            sum(
                CASE
                    WHEN ((tbls_dly_accounting_balance.credit_debit)::text = 'D'::text) THEN tbls_dly_accounting_balance.amount
                    ELSE (0)::numeric
                END) AS total_debit_close,
            sum(
                CASE
                    WHEN ((tbls_dly_accounting_balance.credit_debit)::text = 'D'::text) THEN tbls_dly_accounting_balance.opening_balance
                    ELSE (0)::numeric
                END) AS total_debit_open,
            tbls_dly_accounting_balance.nostro,
            tbls_dly_accounting_balance.ios_code,
            tbls_dly_accounting_balance.corp_code,
            tbls_dly_accounting_balance.branch_code,
            tbls_dly_accounting_balance.cost_center,
            tbls_dly_accounting_balance.customer_types_id,
            tbls_dly_accounting_balance.reference_date,
            tbls_dly_accounting_balance.sub_ledger AS sap_gl_no,
            tbls_dly_accounting_balance.trial_balance_date
           FROM tbls_dly_accounting_balance
          GROUP BY tbls_dly_accounting_balance.repository_id, tbls_dly_accounting_balance.account_id, tbls_dly_accounting_balance.account_name, tbls_dly_accounting_balance.currency_id, tbls_dly_accounting_balance.nostro, tbls_dly_accounting_balance.ios_code, tbls_dly_accounting_balance.corp_code, tbls_dly_accounting_balance.branch_code, tbls_dly_accounting_balance.cost_center, tbls_dly_accounting_balance.customer_types_id, tbls_dly_accounting_balance.reference_date, tbls_dly_accounting_balance.sub_ledger, tbls_dly_accounting_balance.trial_balance_date) iq;


--
--

CREATE VIEW vbls_entry_balancing_deals AS
 SELECT (((((((((((((accentries.acc_rules_id)::text || '_'::text) || (accentries.deal_no)::text) || '_'::text) || accentries.version_no) || '_'::text) || (accentries.leg_no)::text) || '_'::text) || (accentries.repositories_id)::text) || '_'::text) || (accmainledger.memo_nonmemo)::text) || '_'::text) || (accentries.corp_code)::text) AS fin_id,
    accentries.acc_rules_id AS accrulesid,
    accentries.deal_no,
    accentries.currencies_id AS currency_id,
    accentries.version_no,
    accentries.leg_no,
    accentries.repositories_id,
    accmainledger.memo_nonmemo,
    sum(
        CASE
            WHEN ((accentries.debit_credit)::text = 'D'::text) THEN accentries.amount
            ELSE (accentries.amount * ('-1'::integer)::numeric)
        END) AS amount,
    accentries.corp_code AS corpcode
   FROM tbls_acc_entries_table accentries,
    tbls_acc_sub_ledger accsubledger,
    tbls_acc_main_ledger accmainledger
  WHERE (((accsubledger.main_ledger_id)::text = (accmainledger.fin_id)::text) AND (((accentries.sub_ledger_id)::text = (accsubledger.fin_id)::text) AND (accentries.entry_date = ( SELECT datesmaste2_.accounting_date
           FROM tbls_dates_master datesmaste2_)) AND (accentries.deal_no IS NOT NULL)))
  GROUP BY accentries.acc_rules_id, accentries.deal_no, accentries.version_no, accentries.leg_no, accentries.currencies_id, accentries.repositories_id, accmainledger.memo_nonmemo, accentries.corp_code
 HAVING (sum(
        CASE
            WHEN ((accentries.debit_credit)::text = 'D'::text) THEN accentries.amount
            ELSE (accentries.amount * ('-1'::integer)::numeric)
        END) <> (0)::numeric);


--
--

CREATE VIEW vbls_fx_deal_entries AS
 SELECT (((deals.deal_no)::text || '_'::text) || deals.version_no) AS fin_id,
    'DEAL'::text AS rule_type,
        CASE
            WHEN (fx_deals.external_no IS NULL) THEN fx_deals.external_other_no
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
            WHEN (deals.trade_date < deals.action_date) THEN deals.action_date
            ELSE deals.trade_date
        END AS trade_date,
        CASE
            WHEN (deals.value_date < deals.action_date) THEN deals.action_date
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
    COALESCE(fx_deals.spot_rate, (0)::numeric) AS market_rate,
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
    0 AS lcu_setl_eqv_amount
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
  WHERE (((deals.fin_id)::text = (versions.deals_id)::text) AND (deals.version_no = versions.version_no) AND ((versions.fin_id)::text = (fx_deals.deal_versions_id)::text) AND ((deals.repositories_id)::text = (rp.fin_id)::text) AND ((deals.customers_id)::text = (cust.fin_id)::text) AND ((cust.type_id)::text = (ct.fin_id)::text) AND ((deals.products_id)::text = (prd.fin_id)::text) AND ((deals.ud_deal_types_id)::text = (uddt.fin_id)::text) AND ((uddt.ud_deal_types_id)::text = (uddealtypes.fin_id)::text) AND ((deals.action)::text <> 'CANCEL'::text) AND (to_char(deals.trade_date, 'YYYYMMDD'::text) <= ( SELECT to_char(tbls_dates_master.accounting_date, 'YYYYMMDD'::text) AS to_char
           FROM tbls_dates_master)) AND ((deals.maker_checker_status)::text = 'COMMITTED'::text) AND ((deals.is_deleted)::text = 'N'::text) AND ((versions.maker_checker_status)::text = 'COMMITTED'::text) AND ((versions.is_deleted)::text = 'N'::text) AND ((fx_deals.maker_checker_status)::text = 'COMMITTED'::text) AND ((fx_deals.is_deleted)::text = 'N'::text) AND ((rp.maker_checker_status)::text = 'COMMITTED'::text) AND ((rp.is_deleted)::text = 'N'::text) AND ((ct.maker_checker_status)::text = 'COMMITTED'::text) AND ((ct.is_deleted)::text = 'N'::text) AND ((cust.maker_checker_status)::text = 'COMMITTED'::text) AND ((cust.is_deleted)::text = 'N'::text) AND ((deals.products_id)::text IN ( SELECT tbls_products.fin_id
           FROM tbls_products
          WHERE ((tbls_products.code)::text = 'IFX'::text))) AND ((deals.branches_id)::text = (branch.fin_id)::text));


--
--

CREATE VIEW vbls_fx_position_dealentries AS
 SELECT versions.fin_id,
    versions.deals_id AS deal_no,
    versions.version_no,
    prd.code AS product_type,
    versions.buy_sell,
        CASE
            WHEN (versions.trade_date < versions.action_date) THEN versions.action_date
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
    uddt.is_mis_included
   FROM tbls_deal_versions versions,
    tbls_bank_notes_deals bn,
    tbls_repositories rp,
    tbls_customers cust,
    tbls_customer_types ct,
    tbls_products prd,
    tbls_ud_dt_mapping uddt
  WHERE (((versions.fin_id)::text = (bn.fin_id)::text) AND ((versions.repositories_id)::text = (rp.fin_id)::text) AND ((versions.customers_id)::text = (cust.fin_id)::text) AND ((cust.type_id)::text = (ct.fin_id)::text) AND ((versions.products_id)::text = (prd.fin_id)::text) AND ((versions.ud_deal_types_id)::text = (uddt.fin_id)::text) AND ((versions.maker_checker_status)::text = 'COMMITTED'::text) AND ((versions.is_deleted)::text = 'N'::text) AND ((bn.maker_checker_status)::text = 'COMMITTED'::text) AND ((bn.is_deleted)::text = 'N'::text) AND ((rp.maker_checker_status)::text = 'COMMITTED'::text) AND ((rp.is_deleted)::text = 'N'::text) AND ((ct.maker_checker_status)::text = 'COMMITTED'::text) AND ((ct.is_deleted)::text = 'N'::text) AND ((cust.maker_checker_status)::text = 'COMMITTED'::text) AND ((cust.is_deleted)::text = 'N'::text) AND ((versions.products_id)::text IN ( SELECT tbls_products.fin_id
           FROM tbls_products
          WHERE ((tbls_products.code)::text = ANY (ARRAY[('BKN'::character varying)::text, ('TCQ'::character varying)::text])))))
UNION ALL
 SELECT versions.fin_id,
    versions.deals_id AS deal_no,
    versions.version_no,
    'IFX'::character varying AS product_type,
    fx_deals.buy_sell,
        CASE
            WHEN (versions.trade_date < versions.action_date) THEN versions.action_date
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
    uddt.is_mis_included
   FROM tbls_deal_versions versions,
    tbls_fx_deals fx_deals,
    tbls_repositories rp,
    tbls_customers cust,
    tbls_customer_types ct,
    tbls_ud_dt_mapping uddt
  WHERE (((versions.fin_id)::text = (fx_deals.deal_versions_id)::text) AND ((versions.repositories_id)::text = (rp.fin_id)::text) AND ((versions.customers_id)::text = (cust.fin_id)::text) AND ((versions.ud_deal_types_id)::text = (uddt.fin_id)::text) AND ((cust.type_id)::text = (ct.fin_id)::text) AND ((versions.maker_checker_status)::text = 'COMMITTED'::text) AND ((versions.is_deleted)::text = 'N'::text) AND ((fx_deals.maker_checker_status)::text = 'COMMITTED'::text) AND ((fx_deals.is_deleted)::text = 'N'::text) AND ((rp.maker_checker_status)::text = 'COMMITTED'::text) AND ((rp.is_deleted)::text = 'N'::text) AND ((ct.maker_checker_status)::text = 'COMMITTED'::text) AND ((ct.is_deleted)::text = 'N'::text) AND ((cust.maker_checker_status)::text = 'COMMITTED'::text) AND ((cust.is_deleted)::text = 'N'::text) AND ((versions.products_id)::text IN ( SELECT tbls_products.fin_id
           FROM tbls_products
          WHERE ((tbls_products.code)::text = 'IFX'::text))));


--
--

CREATE VIEW vbls_hist_cus_comparison_cty AS
 SELECT (iq.curryear)::integer AS curryear,
    iq.month,
    max(
        CASE
            WHEN (iq.year = ((iq.curryear)::integer - 2)) THEN iq.total
            ELSE (0)::numeric
        END) AS tyear3,
    max(
        CASE
            WHEN (iq.year = ((iq.curryear)::integer - 1)) THEN iq.total
            ELSE (0)::numeric
        END) AS tyear2,
    max(
        CASE
            WHEN (iq.year = (iq.curryear)::integer) THEN iq.total
            ELSE (0)::numeric
        END) AS tyear1,
        CASE
            WHEN ((max(
            CASE
                WHEN (iq.year = ((iq.curryear)::integer - 2)) THEN iq.total
                ELSE (0)::numeric
            END) <> (0)::numeric) AND (max(
            CASE
                WHEN (iq.year = ((iq.curryear)::integer - 1)) THEN iq.total
                ELSE (0)::numeric
            END) <> (0)::numeric)) THEN (round(((max(
            CASE
                WHEN (iq.year = ((iq.curryear)::integer - 1)) THEN iq.total
                ELSE (0)::numeric
            END) - max(
            CASE
                WHEN (iq.year = ((iq.curryear)::integer - 2)) THEN iq.total
                ELSE (0)::numeric
            END)) / max(
            CASE
                WHEN (iq.year = ((iq.curryear)::integer - 2)) THEN iq.total
                ELSE (0)::numeric
            END)), 2) * (100)::numeric)
            WHEN ((max(
            CASE
                WHEN (iq.year = ((iq.curryear)::integer - 2)) THEN iq.total
                ELSE (0)::numeric
            END) = (0)::numeric) AND (max(
            CASE
                WHEN (iq.year = ((iq.curryear)::integer - 1)) THEN iq.total
                ELSE (0)::numeric
            END) <> (0)::numeric)) THEN 9999.99
            ELSE (0)::numeric
        END AS t2v1,
        CASE
            WHEN ((max(
            CASE
                WHEN (iq.year = ((iq.curryear)::integer - 1)) THEN iq.total
                ELSE (0)::numeric
            END) <> (0)::numeric) AND (max(
            CASE
                WHEN (iq.year = (iq.curryear)::integer) THEN iq.total
                ELSE (0)::numeric
            END) <> (0)::numeric)) THEN (round(((max(
            CASE
                WHEN (iq.year = (iq.curryear)::integer) THEN iq.total
                ELSE (0)::numeric
            END) - max(
            CASE
                WHEN (iq.year = ((iq.curryear)::integer - 1)) THEN iq.total
                ELSE (0)::numeric
            END)) / max(
            CASE
                WHEN (iq.year = ((iq.curryear)::integer - 1)) THEN iq.total
                ELSE (0)::numeric
            END)), 2) * (100)::numeric)
            WHEN ((max(
            CASE
                WHEN (iq.year = ((iq.curryear)::integer - 1)) THEN iq.total
                ELSE (0)::numeric
            END) = (0)::numeric) AND (max(
            CASE
                WHEN (iq.year = (iq.curryear)::integer) THEN iq.total
                ELSE (0)::numeric
            END) <> (0)::numeric)) THEN 9999.99
            ELSE (0)::numeric
        END AS tcv1,
    max(
        CASE
            WHEN (iq.year = ((iq.curryear)::integer - 2)) THEN iq.buy
            ELSE (0)::numeric
        END) AS bpyear3,
    max(
        CASE
            WHEN (iq.year = ((iq.curryear)::integer - 1)) THEN iq.buy
            ELSE (0)::numeric
        END) AS bpyear2,
    max(
        CASE
            WHEN (iq.year = (iq.curryear)::integer) THEN iq.buy
            ELSE (0)::numeric
        END) AS bpyear1,
        CASE
            WHEN ((max(
            CASE
                WHEN (iq.year = ((iq.curryear)::integer - 2)) THEN iq.buy
                ELSE (0)::numeric
            END) <> (0)::numeric) AND (max(
            CASE
                WHEN (iq.year = ((iq.curryear)::integer - 1)) THEN iq.buy
                ELSE (0)::numeric
            END) <> (0)::numeric)) THEN (round(((max(
            CASE
                WHEN (iq.year = ((iq.curryear)::integer - 1)) THEN iq.buy
                ELSE (0)::numeric
            END) - max(
            CASE
                WHEN (iq.year = ((iq.curryear)::integer - 2)) THEN iq.buy
                ELSE (0)::numeric
            END)) / max(
            CASE
                WHEN (iq.year = ((iq.curryear)::integer - 2)) THEN iq.buy
                ELSE (0)::numeric
            END)), 2) * (100)::numeric)
            WHEN ((max(
            CASE
                WHEN (iq.year = ((iq.curryear)::integer - 2)) THEN iq.buy
                ELSE (0)::numeric
            END) = (0)::numeric) AND (max(
            CASE
                WHEN (iq.year = ((iq.curryear)::integer - 1)) THEN iq.buy
                ELSE (0)::numeric
            END) <> (0)::numeric)) THEN 9999.99
            ELSE (0)::numeric
        END AS bp2v1,
        CASE
            WHEN ((max(
            CASE
                WHEN (iq.year = ((iq.curryear)::integer - 1)) THEN iq.buy
                ELSE (0)::numeric
            END) <> (0)::numeric) AND (max(
            CASE
                WHEN (iq.year = (iq.curryear)::integer) THEN iq.buy
                ELSE (0)::numeric
            END) <> (0)::numeric)) THEN (round(((max(
            CASE
                WHEN (iq.year = (iq.curryear)::integer) THEN iq.buy
                ELSE (0)::numeric
            END) - max(
            CASE
                WHEN (iq.year = ((iq.curryear)::integer - 1)) THEN iq.buy
                ELSE (0)::numeric
            END)) / max(
            CASE
                WHEN (iq.year = ((iq.curryear)::integer - 1)) THEN iq.buy
                ELSE (0)::numeric
            END)), 2) * (100)::numeric)
            WHEN ((max(
            CASE
                WHEN (iq.year = ((iq.curryear)::integer - 1)) THEN iq.buy
                ELSE (0)::numeric
            END) = (0)::numeric) AND (max(
            CASE
                WHEN (iq.year = (iq.curryear)::integer) THEN iq.buy
                ELSE (0)::numeric
            END) <> (0)::numeric)) THEN 9999.99
            ELSE (0)::numeric
        END AS bpcv1,
    max(
        CASE
            WHEN (iq.year = ((iq.curryear)::integer - 2)) THEN iq.sell
            ELSE (0)::numeric
        END) AS bsyear3,
    max(
        CASE
            WHEN (iq.year = ((iq.curryear)::integer - 1)) THEN iq.sell
            ELSE (0)::numeric
        END) AS bsyear2,
    max(
        CASE
            WHEN (iq.year = (iq.curryear)::integer) THEN iq.sell
            ELSE (0)::numeric
        END) AS bsyear1,
        CASE
            WHEN ((max(
            CASE
                WHEN (iq.year = ((iq.curryear)::integer - 2)) THEN iq.sell
                ELSE (0)::numeric
            END) <> (0)::numeric) AND (max(
            CASE
                WHEN (iq.year = ((iq.curryear)::integer - 1)) THEN iq.sell
                ELSE (0)::numeric
            END) <> (0)::numeric)) THEN (round(((max(
            CASE
                WHEN (iq.year = ((iq.curryear)::integer - 1)) THEN iq.sell
                ELSE (0)::numeric
            END) - max(
            CASE
                WHEN (iq.year = ((iq.curryear)::integer - 2)) THEN iq.sell
                ELSE (0)::numeric
            END)) / max(
            CASE
                WHEN (iq.year = ((iq.curryear)::integer - 2)) THEN iq.sell
                ELSE (0)::numeric
            END)), 2) * (100)::numeric)
            WHEN ((max(
            CASE
                WHEN (iq.year = ((iq.curryear)::integer - 2)) THEN iq.sell
                ELSE (0)::numeric
            END) = (0)::numeric) AND (max(
            CASE
                WHEN (iq.year = ((iq.curryear)::integer - 1)) THEN iq.sell
                ELSE (0)::numeric
            END) <> (0)::numeric)) THEN 9999.99
            ELSE (0)::numeric
        END AS bs2v1,
        CASE
            WHEN ((max(
            CASE
                WHEN (iq.year = ((iq.curryear)::integer - 1)) THEN iq.sell
                ELSE (0)::numeric
            END) <> (0)::numeric) AND (max(
            CASE
                WHEN (iq.year = (iq.curryear)::integer) THEN iq.sell
                ELSE (0)::numeric
            END) <> (0)::numeric)) THEN (round(((max(
            CASE
                WHEN (iq.year = (iq.curryear)::integer) THEN iq.sell
                ELSE (0)::numeric
            END) - max(
            CASE
                WHEN (iq.year = ((iq.curryear)::integer - 1)) THEN iq.sell
                ELSE (0)::numeric
            END)) / max(
            CASE
                WHEN (iq.year = ((iq.curryear)::integer - 1)) THEN iq.sell
                ELSE (0)::numeric
            END)), 2) * (100)::numeric)
            WHEN ((max(
            CASE
                WHEN (iq.year = ((iq.curryear)::integer - 1)) THEN iq.sell
                ELSE (0)::numeric
            END) = (0)::numeric) AND (max(
            CASE
                WHEN (iq.year = (iq.curryear)::integer) THEN iq.sell
                ELSE (0)::numeric
            END) <> (0)::numeric)) THEN 9999.99
            ELSE (0)::numeric
        END AS bscv1,
    max((iq.country)::text) AS country,
    max((iq.quarter)::text) AS quarter,
    iq.product_code
   FROM ( SELECT countries.name AS country,
            (cc.year)::integer AS year,
            (cc.month)::integer AS month,
            cc.quarter,
            (sum(cc.total_buy_amt_usd) / (1000)::numeric) AS buy,
            (sum(cc.total_sell_amt_usd) / (1000)::numeric) AS sell,
            ((sum(cc.total_buy_amt_usd) / (1000)::numeric) + (sum(cc.total_sell_amt_usd) / (1000)::numeric)) AS total,
            max(to_char(dm.system_date, 'YYYY'::text)) AS curryear,
            cc.product_code
           FROM tbls_history_cust_cmprision cc,
            tbls_dates_master dm,
            tbls_countries countries
          WHERE ((cc.country)::text = (countries.fin_id)::text)
          GROUP BY countries.name, cc.year, cc.quarter, cc.month, cc.product_code) iq
  GROUP BY iq.country, iq.quarter, iq.month, iq.curryear, iq.product_code
  ORDER BY iq.country, iq.quarter, ((iq.month)::numeric);


--
--

CREATE VIEW vbls_hist_cust_comp_10 AS
 SELECT (iq.curryear)::integer AS curryear,
    lpad((iq.month)::text, 2, '0'::text) AS month,
    max(
        CASE
            WHEN (iq.year = ((iq.curryear)::integer - 2)) THEN iq.total
            ELSE (0)::numeric
        END) AS tyear3,
    max(
        CASE
            WHEN (iq.year = ((iq.curryear)::integer - 1)) THEN iq.total
            ELSE (0)::numeric
        END) AS tyear2,
    max(
        CASE
            WHEN (iq.year = (iq.curryear)::integer) THEN iq.total
            ELSE (0)::numeric
        END) AS tyear1,
        CASE
            WHEN ((max(
            CASE
                WHEN (iq.year = ((iq.curryear)::integer - 2)) THEN iq.total
                ELSE (0)::numeric
            END) <> (0)::numeric) AND (max(
            CASE
                WHEN (iq.year = ((iq.curryear)::integer - 1)) THEN iq.total
                ELSE (0)::numeric
            END) <> (0)::numeric)) THEN (round(((max(
            CASE
                WHEN (iq.year = ((iq.curryear)::integer - 1)) THEN iq.total
                ELSE (0)::numeric
            END) - max(
            CASE
                WHEN (iq.year = ((iq.curryear)::integer - 2)) THEN iq.total
                ELSE (0)::numeric
            END)) / max(
            CASE
                WHEN (iq.year = ((iq.curryear)::integer - 2)) THEN iq.total
                ELSE (0)::numeric
            END)), 2) * (100)::numeric)
            WHEN ((max(
            CASE
                WHEN (iq.year = ((iq.curryear)::integer - 2)) THEN iq.total
                ELSE (0)::numeric
            END) = (0)::numeric) AND (max(
            CASE
                WHEN (iq.year = ((iq.curryear)::integer - 1)) THEN iq.total
                ELSE (0)::numeric
            END) <> (0)::numeric)) THEN 9999.99
            ELSE (0)::numeric
        END AS t2v1,
        CASE
            WHEN ((max(
            CASE
                WHEN (iq.year = ((iq.curryear)::integer - 1)) THEN iq.total
                ELSE (0)::numeric
            END) <> (0)::numeric) AND (max(
            CASE
                WHEN (iq.year = (iq.curryear)::integer) THEN iq.total
                ELSE (0)::numeric
            END) <> (0)::numeric)) THEN (round(((max(
            CASE
                WHEN (iq.year = (iq.curryear)::integer) THEN iq.total
                ELSE (0)::numeric
            END) - max(
            CASE
                WHEN (iq.year = ((iq.curryear)::integer - 1)) THEN iq.total
                ELSE (0)::numeric
            END)) / max(
            CASE
                WHEN (iq.year = ((iq.curryear)::integer - 1)) THEN iq.total
                ELSE (0)::numeric
            END)), 2) * (100)::numeric)
            WHEN ((max(
            CASE
                WHEN (iq.year = ((iq.curryear)::integer - 1)) THEN iq.total
                ELSE (0)::numeric
            END) = (0)::numeric) AND (max(
            CASE
                WHEN (iq.year = (iq.curryear)::integer) THEN iq.total
                ELSE (0)::numeric
            END) <> (0)::numeric)) THEN 9999.99
            ELSE (0)::numeric
        END AS tcv1,
    max(
        CASE
            WHEN (iq.year = ((iq.curryear)::integer - 2)) THEN iq.buy
            ELSE (0)::numeric
        END) AS bpyear3,
    max(
        CASE
            WHEN (iq.year = ((iq.curryear)::integer - 1)) THEN iq.buy
            ELSE (0)::numeric
        END) AS bpyear2,
    max(
        CASE
            WHEN (iq.year = (iq.curryear)::integer) THEN iq.buy
            ELSE (0)::numeric
        END) AS bpyear1,
        CASE
            WHEN ((max(
            CASE
                WHEN (iq.year = ((iq.curryear)::integer - 2)) THEN iq.buy
                ELSE (0)::numeric
            END) <> (0)::numeric) AND (max(
            CASE
                WHEN (iq.year = ((iq.curryear)::integer - 1)) THEN iq.buy
                ELSE (0)::numeric
            END) <> (0)::numeric)) THEN (round(((max(
            CASE
                WHEN (iq.year = ((iq.curryear)::integer - 1)) THEN iq.buy
                ELSE (0)::numeric
            END) - max(
            CASE
                WHEN (iq.year = ((iq.curryear)::integer - 2)) THEN iq.buy
                ELSE (0)::numeric
            END)) / max(
            CASE
                WHEN (iq.year = ((iq.curryear)::integer - 2)) THEN iq.buy
                ELSE (0)::numeric
            END)), 2) * (100)::numeric)
            WHEN ((max(
            CASE
                WHEN (iq.year = ((iq.curryear)::integer - 2)) THEN iq.buy
                ELSE (0)::numeric
            END) = (0)::numeric) AND (max(
            CASE
                WHEN (iq.year = ((iq.curryear)::integer - 1)) THEN iq.buy
                ELSE (0)::numeric
            END) <> (0)::numeric)) THEN 9999.99
            ELSE (0)::numeric
        END AS bp2v1,
        CASE
            WHEN ((max(
            CASE
                WHEN (iq.year = ((iq.curryear)::integer - 1)) THEN iq.buy
                ELSE (0)::numeric
            END) <> (0)::numeric) AND (max(
            CASE
                WHEN (iq.year = (iq.curryear)::integer) THEN iq.buy
                ELSE (0)::numeric
            END) <> (0)::numeric)) THEN (round(((max(
            CASE
                WHEN (iq.year = (iq.curryear)::integer) THEN iq.buy
                ELSE (0)::numeric
            END) - max(
            CASE
                WHEN (iq.year = ((iq.curryear)::integer - 1)) THEN iq.buy
                ELSE (0)::numeric
            END)) / max(
            CASE
                WHEN (iq.year = ((iq.curryear)::integer - 1)) THEN iq.buy
                ELSE (0)::numeric
            END)), 2) * (100)::numeric)
            WHEN ((max(
            CASE
                WHEN (iq.year = ((iq.curryear)::integer - 1)) THEN iq.buy
                ELSE (0)::numeric
            END) = (0)::numeric) AND (max(
            CASE
                WHEN (iq.year = (iq.curryear)::integer) THEN iq.buy
                ELSE (0)::numeric
            END) <> (0)::numeric)) THEN 9999.99
            ELSE (0)::numeric
        END AS bpcv1,
    max(
        CASE
            WHEN (iq.year = ((iq.curryear)::integer - 2)) THEN iq.sell
            ELSE (0)::numeric
        END) AS bsyear3,
    max(
        CASE
            WHEN (iq.year = ((iq.curryear)::integer - 1)) THEN iq.sell
            ELSE (0)::numeric
        END) AS bsyear2,
    max(
        CASE
            WHEN (iq.year = (iq.curryear)::integer) THEN iq.sell
            ELSE (0)::numeric
        END) AS bsyear1,
        CASE
            WHEN ((max(
            CASE
                WHEN (iq.year = ((iq.curryear)::integer - 2)) THEN iq.sell
                ELSE (0)::numeric
            END) <> (0)::numeric) AND (max(
            CASE
                WHEN (iq.year = ((iq.curryear)::integer - 1)) THEN iq.sell
                ELSE (0)::numeric
            END) <> (0)::numeric)) THEN (round(((max(
            CASE
                WHEN (iq.year = ((iq.curryear)::integer - 1)) THEN iq.sell
                ELSE (0)::numeric
            END) - max(
            CASE
                WHEN (iq.year = ((iq.curryear)::integer - 2)) THEN iq.sell
                ELSE (0)::numeric
            END)) / max(
            CASE
                WHEN (iq.year = ((iq.curryear)::integer - 2)) THEN iq.sell
                ELSE (0)::numeric
            END)), 2) * (100)::numeric)
            WHEN ((max(
            CASE
                WHEN (iq.year = ((iq.curryear)::integer - 2)) THEN iq.sell
                ELSE (0)::numeric
            END) = (0)::numeric) AND (max(
            CASE
                WHEN (iq.year = ((iq.curryear)::integer - 1)) THEN iq.sell
                ELSE (0)::numeric
            END) <> (0)::numeric)) THEN 9999.99
            ELSE (0)::numeric
        END AS bs2v1,
        CASE
            WHEN ((max(
            CASE
                WHEN (iq.year = ((iq.curryear)::integer - 1)) THEN iq.sell
                ELSE (0)::numeric
            END) <> (0)::numeric) AND (max(
            CASE
                WHEN (iq.year = (iq.curryear)::integer) THEN iq.sell
                ELSE (0)::numeric
            END) <> (0)::numeric)) THEN (round(((max(
            CASE
                WHEN (iq.year = (iq.curryear)::integer) THEN iq.sell
                ELSE (0)::numeric
            END) - max(
            CASE
                WHEN (iq.year = ((iq.curryear)::integer - 1)) THEN iq.sell
                ELSE (0)::numeric
            END)) / max(
            CASE
                WHEN (iq.year = ((iq.curryear)::integer - 1)) THEN iq.sell
                ELSE (0)::numeric
            END)), 2) * (100)::numeric)
            WHEN ((max(
            CASE
                WHEN (iq.year = ((iq.curryear)::integer - 1)) THEN iq.sell
                ELSE (0)::numeric
            END) = (0)::numeric) AND (max(
            CASE
                WHEN (iq.year = (iq.curryear)::integer) THEN iq.sell
                ELSE (0)::numeric
            END) <> (0)::numeric)) THEN 9999.99
            ELSE (0)::numeric
        END AS bscv1,
    max((iq.country)::text) AS country,
    max((iq.quarter)::text) AS quarter,
    iq.product_code
   FROM ( SELECT countries.name AS country,
            (cc.year)::integer AS year,
            cc.month,
            cc.quarter,
            (sum(cc.total_buy_amt_usd) / (1000)::numeric) AS buy,
            (sum(cc.total_sell_amt_usd) / (1000)::numeric) AS sell,
            ((sum(cc.total_buy_amt_usd) / (1000)::numeric) + (sum(cc.total_sell_amt_usd) / (1000)::numeric)) AS total,
            max(to_char(dm.system_date, 'YYYY'::text)) AS curryear,
            cc.product_code
           FROM tbls_history_cust_cmprision cc,
            tbls_dates_master dm,
            tbls_countries countries
          WHERE ((cc.country)::text = (countries.fin_id)::text)
          GROUP BY countries.name, cc.year, cc.quarter, cc.month, cc.product_code) iq
  GROUP BY iq.country, iq.quarter, iq.month, (iq.curryear)::integer, iq.product_code
  ORDER BY iq.country, iq.quarter, (iq.month)::numeric;


--
--

CREATE VIEW vbls_hist_cust_comp_11 AS
 SELECT iq.curryear,
    lpad((iq.month)::text, 2, '0'::text) AS month,
    max(
        CASE
            WHEN (iq.year = (iq.curryear - 2)) THEN iq.total
            ELSE (0)::numeric
        END) AS tyear3,
    max(
        CASE
            WHEN (iq.year = (iq.curryear - 1)) THEN iq.total
            ELSE (0)::numeric
        END) AS tyear2,
    max(
        CASE
            WHEN (iq.year = iq.curryear) THEN iq.total
            ELSE (0)::numeric
        END) AS tyear1,
        CASE
            WHEN ((max(
            CASE
                WHEN (iq.year = (iq.curryear - 2)) THEN iq.total
                ELSE (0)::numeric
            END) <> (0)::numeric) AND (max(
            CASE
                WHEN (iq.year = (iq.curryear - 1)) THEN iq.total
                ELSE (0)::numeric
            END) <> (0)::numeric)) THEN (round(((max(
            CASE
                WHEN (iq.year = (iq.curryear - 1)) THEN iq.total
                ELSE (0)::numeric
            END) - max(
            CASE
                WHEN (iq.year = (iq.curryear - 2)) THEN iq.total
                ELSE (0)::numeric
            END)) / max(
            CASE
                WHEN (iq.year = (iq.curryear - 2)) THEN iq.total
                ELSE (0)::numeric
            END)), 2) * (100)::numeric)
            WHEN ((max(
            CASE
                WHEN (iq.year = (iq.curryear - 2)) THEN iq.total
                ELSE (0)::numeric
            END) = (0)::numeric) AND (max(
            CASE
                WHEN (iq.year = (iq.curryear - 1)) THEN iq.total
                ELSE (0)::numeric
            END) <> (0)::numeric)) THEN 9999.99
            ELSE (0)::numeric
        END AS t2v1,
        CASE
            WHEN ((max(
            CASE
                WHEN (iq.year = (iq.curryear - 1)) THEN iq.total
                ELSE (0)::numeric
            END) <> (0)::numeric) AND (max(
            CASE
                WHEN (iq.year = iq.curryear) THEN iq.total
                ELSE (0)::numeric
            END) <> (0)::numeric)) THEN (round(((max(
            CASE
                WHEN (iq.year = iq.curryear) THEN iq.total
                ELSE (0)::numeric
            END) - max(
            CASE
                WHEN (iq.year = (iq.curryear - 1)) THEN iq.total
                ELSE (0)::numeric
            END)) / max(
            CASE
                WHEN (iq.year = (iq.curryear - 1)) THEN iq.total
                ELSE (0)::numeric
            END)), 2) * (100)::numeric)
            WHEN ((max(
            CASE
                WHEN (iq.year = (iq.curryear - 1)) THEN iq.total
                ELSE (0)::numeric
            END) = (0)::numeric) AND (max(
            CASE
                WHEN (iq.year = iq.curryear) THEN iq.total
                ELSE (0)::numeric
            END) <> (0)::numeric)) THEN 9999.99
            ELSE (0)::numeric
        END AS tcv1,
    max(
        CASE
            WHEN (iq.year = (iq.curryear - 2)) THEN iq.buy
            ELSE (0)::numeric
        END) AS bpyear3,
    max(
        CASE
            WHEN (iq.year = (iq.curryear - 1)) THEN iq.buy
            ELSE (0)::numeric
        END) AS bpyear2,
    max(
        CASE
            WHEN (iq.year = iq.curryear) THEN iq.buy
            ELSE (0)::numeric
        END) AS bpyear1,
        CASE
            WHEN ((max(
            CASE
                WHEN (iq.year = (iq.curryear - 2)) THEN iq.buy
                ELSE (0)::numeric
            END) <> (0)::numeric) AND (max(
            CASE
                WHEN (iq.year = (iq.curryear - 1)) THEN iq.buy
                ELSE (0)::numeric
            END) <> (0)::numeric)) THEN (round(((max(
            CASE
                WHEN (iq.year = (iq.curryear - 1)) THEN iq.buy
                ELSE (0)::numeric
            END) - max(
            CASE
                WHEN (iq.year = (iq.curryear - 2)) THEN iq.buy
                ELSE (0)::numeric
            END)) / max(
            CASE
                WHEN (iq.year = (iq.curryear - 2)) THEN iq.buy
                ELSE (0)::numeric
            END)), 2) * (100)::numeric)
            WHEN ((max(
            CASE
                WHEN (iq.year = (iq.curryear - 2)) THEN iq.buy
                ELSE (0)::numeric
            END) = (0)::numeric) AND (max(
            CASE
                WHEN (iq.year = (iq.curryear - 1)) THEN iq.buy
                ELSE (0)::numeric
            END) <> (0)::numeric)) THEN 9999.99
            ELSE (0)::numeric
        END AS bp2v1,
        CASE
            WHEN ((max(
            CASE
                WHEN (iq.year = (iq.curryear - 1)) THEN iq.buy
                ELSE (0)::numeric
            END) <> (0)::numeric) AND (max(
            CASE
                WHEN (iq.year = iq.curryear) THEN iq.buy
                ELSE (0)::numeric
            END) <> (0)::numeric)) THEN (round(((max(
            CASE
                WHEN (iq.year = iq.curryear) THEN iq.buy
                ELSE (0)::numeric
            END) - max(
            CASE
                WHEN (iq.year = (iq.curryear - 1)) THEN iq.buy
                ELSE (0)::numeric
            END)) / max(
            CASE
                WHEN (iq.year = (iq.curryear - 1)) THEN iq.buy
                ELSE (0)::numeric
            END)), 2) * (100)::numeric)
            WHEN ((max(
            CASE
                WHEN (iq.year = (iq.curryear - 1)) THEN iq.buy
                ELSE (0)::numeric
            END) = (0)::numeric) AND (max(
            CASE
                WHEN (iq.year = iq.curryear) THEN iq.buy
                ELSE (0)::numeric
            END) <> (0)::numeric)) THEN 9999.99
            ELSE (0)::numeric
        END AS bpcv1,
    max(
        CASE
            WHEN (iq.year = (iq.curryear - 2)) THEN iq.sell
            ELSE (0)::numeric
        END) AS bsyear3,
    max(
        CASE
            WHEN (iq.year = (iq.curryear - 1)) THEN iq.sell
            ELSE (0)::numeric
        END) AS bsyear2,
    max(
        CASE
            WHEN (iq.year = iq.curryear) THEN iq.sell
            ELSE (0)::numeric
        END) AS bsyear1,
        CASE
            WHEN ((max(
            CASE
                WHEN (iq.year = (iq.curryear - 2)) THEN iq.sell
                ELSE (0)::numeric
            END) <> (0)::numeric) AND (max(
            CASE
                WHEN (iq.year = (iq.curryear - 1)) THEN iq.sell
                ELSE (0)::numeric
            END) <> (0)::numeric)) THEN (round(((max(
            CASE
                WHEN (iq.year = (iq.curryear - 1)) THEN iq.sell
                ELSE (0)::numeric
            END) - max(
            CASE
                WHEN (iq.year = (iq.curryear - 2)) THEN iq.sell
                ELSE (0)::numeric
            END)) / max(
            CASE
                WHEN (iq.year = (iq.curryear - 2)) THEN iq.sell
                ELSE (0)::numeric
            END)), 2) * (100)::numeric)
            WHEN ((max(
            CASE
                WHEN (iq.year = (iq.curryear - 2)) THEN iq.sell
                ELSE (0)::numeric
            END) = (0)::numeric) AND (max(
            CASE
                WHEN (iq.year = (iq.curryear - 1)) THEN iq.sell
                ELSE (0)::numeric
            END) <> (0)::numeric)) THEN 9999.99
            ELSE (0)::numeric
        END AS bs2v1,
        CASE
            WHEN ((max(
            CASE
                WHEN (iq.year = (iq.curryear - 1)) THEN iq.sell
                ELSE (0)::numeric
            END) <> (0)::numeric) AND (max(
            CASE
                WHEN (iq.year = iq.curryear) THEN iq.sell
                ELSE (0)::numeric
            END) <> (0)::numeric)) THEN (round(((max(
            CASE
                WHEN (iq.year = iq.curryear) THEN iq.sell
                ELSE (0)::numeric
            END) - max(
            CASE
                WHEN (iq.year = (iq.curryear - 1)) THEN iq.sell
                ELSE (0)::numeric
            END)) / max(
            CASE
                WHEN (iq.year = (iq.curryear - 1)) THEN iq.sell
                ELSE (0)::numeric
            END)), 2) * (100)::numeric)
            WHEN ((max(
            CASE
                WHEN (iq.year = (iq.curryear - 1)) THEN iq.sell
                ELSE (0)::numeric
            END) = (0)::numeric) AND (max(
            CASE
                WHEN (iq.year = iq.curryear) THEN iq.sell
                ELSE (0)::numeric
            END) <> (0)::numeric)) THEN 9999.99
            ELSE (0)::numeric
        END AS bscv1,
    max((iq.country)::text) AS country,
    iq.product_code
   FROM ( SELECT countries.name AS country,
            (cc.year)::integer AS year,
            cc.month,
            (sum(cc.total_buy_amt_usd) / (1000)::numeric) AS buy,
            (sum(cc.total_sell_amt_usd) / (1000)::numeric) AS sell,
            ((sum(cc.total_buy_amt_usd) / (1000)::numeric) + (sum(cc.total_sell_amt_usd) / (1000)::numeric)) AS total,
            (max(to_char(dm.system_date, 'YYYY'::text)))::integer AS curryear,
            cc.product_code
           FROM tbls_history_cust_cmprision cc,
            tbls_dates_master dm,
            tbls_countries countries
          WHERE ((cc.country)::text = (countries.fin_id)::text)
          GROUP BY countries.name, cc.year, cc.month, cc.product_code) iq
  GROUP BY iq.country, iq.month, iq.curryear, iq.product_code
  ORDER BY iq.country, (iq.month)::numeric;


--
--

CREATE VIEW vbls_hist_cust_comp_12 AS
 SELECT (iq.curryear)::integer AS curryear,
    lpad((iq.month)::text, 2, '0'::text) AS month,
    max(
        CASE
            WHEN (iq.year = ((iq.curryear)::integer - 2)) THEN iq.total
            ELSE (0)::numeric
        END) AS tyear3,
    max(
        CASE
            WHEN (iq.year = ((iq.curryear)::integer - 1)) THEN iq.total
            ELSE (0)::numeric
        END) AS tyear2,
    max(
        CASE
            WHEN (iq.year = (iq.curryear)::integer) THEN iq.total
            ELSE (0)::numeric
        END) AS tyear1,
        CASE
            WHEN ((max(
            CASE
                WHEN (iq.year = ((iq.curryear)::integer - 2)) THEN iq.total
                ELSE (0)::numeric
            END) <> (0)::numeric) AND (max(
            CASE
                WHEN (iq.year = ((iq.curryear)::integer - 1)) THEN iq.total
                ELSE (0)::numeric
            END) <> (0)::numeric)) THEN (round(((max(
            CASE
                WHEN (iq.year = ((iq.curryear)::integer - 1)) THEN iq.total
                ELSE (0)::numeric
            END) - max(
            CASE
                WHEN (iq.year = ((iq.curryear)::integer - 2)) THEN iq.total
                ELSE (0)::numeric
            END)) / max(
            CASE
                WHEN (iq.year = ((iq.curryear)::integer - 2)) THEN iq.total
                ELSE (0)::numeric
            END)), 2) * (100)::numeric)
            WHEN ((max(
            CASE
                WHEN (iq.year = ((iq.curryear)::integer - 2)) THEN iq.total
                ELSE (0)::numeric
            END) = (0)::numeric) AND (max(
            CASE
                WHEN (iq.year = ((iq.curryear)::integer - 1)) THEN iq.total
                ELSE (0)::numeric
            END) <> (0)::numeric)) THEN 9999.99
            ELSE (0)::numeric
        END AS t2v1,
        CASE
            WHEN ((max(
            CASE
                WHEN (iq.year = ((iq.curryear)::integer - 1)) THEN iq.total
                ELSE (0)::numeric
            END) <> (0)::numeric) AND (max(
            CASE
                WHEN (iq.year = (iq.curryear)::integer) THEN iq.total
                ELSE (0)::numeric
            END) <> (0)::numeric)) THEN (round(((max(
            CASE
                WHEN (iq.year = (iq.curryear)::integer) THEN iq.total
                ELSE (0)::numeric
            END) - max(
            CASE
                WHEN (iq.year = ((iq.curryear)::integer - 1)) THEN iq.total
                ELSE (0)::numeric
            END)) / max(
            CASE
                WHEN (iq.year = ((iq.curryear)::integer - 1)) THEN iq.total
                ELSE (0)::numeric
            END)), 2) * (100)::numeric)
            WHEN ((max(
            CASE
                WHEN (iq.year = ((iq.curryear)::integer - 1)) THEN iq.total
                ELSE (0)::numeric
            END) = (0)::numeric) AND (max(
            CASE
                WHEN (iq.year = (iq.curryear)::integer) THEN iq.total
                ELSE (0)::numeric
            END) <> (0)::numeric)) THEN 9999.99
            ELSE (0)::numeric
        END AS tcv1,
    max(
        CASE
            WHEN (iq.year = ((iq.curryear)::integer - 2)) THEN iq.buy
            ELSE (0)::numeric
        END) AS bpyear3,
    max(
        CASE
            WHEN (iq.year = ((iq.curryear)::integer - 1)) THEN iq.buy
            ELSE (0)::numeric
        END) AS bpyear2,
    max(
        CASE
            WHEN (iq.year = (iq.curryear)::integer) THEN iq.buy
            ELSE (0)::numeric
        END) AS bpyear1,
        CASE
            WHEN ((max(
            CASE
                WHEN (iq.year = ((iq.curryear)::integer - 2)) THEN iq.buy
                ELSE (0)::numeric
            END) <> (0)::numeric) AND (max(
            CASE
                WHEN (iq.year = ((iq.curryear)::integer - 1)) THEN iq.buy
                ELSE (0)::numeric
            END) <> (0)::numeric)) THEN (round(((max(
            CASE
                WHEN (iq.year = ((iq.curryear)::integer - 1)) THEN iq.buy
                ELSE (0)::numeric
            END) - max(
            CASE
                WHEN (iq.year = ((iq.curryear)::integer - 2)) THEN iq.buy
                ELSE (0)::numeric
            END)) / max(
            CASE
                WHEN (iq.year = ((iq.curryear)::integer - 2)) THEN iq.buy
                ELSE (0)::numeric
            END)), 2) * (100)::numeric)
            WHEN ((max(
            CASE
                WHEN (iq.year = ((iq.curryear)::integer - 2)) THEN iq.buy
                ELSE (0)::numeric
            END) = (0)::numeric) AND (max(
            CASE
                WHEN (iq.year = ((iq.curryear)::integer - 1)) THEN iq.buy
                ELSE (0)::numeric
            END) <> (0)::numeric)) THEN 9999.99
            ELSE (0)::numeric
        END AS bp2v1,
        CASE
            WHEN ((max(
            CASE
                WHEN (iq.year = ((iq.curryear)::integer - 1)) THEN iq.buy
                ELSE (0)::numeric
            END) <> (0)::numeric) AND (max(
            CASE
                WHEN (iq.year = (iq.curryear)::integer) THEN iq.buy
                ELSE (0)::numeric
            END) <> (0)::numeric)) THEN (round(((max(
            CASE
                WHEN (iq.year = (iq.curryear)::integer) THEN iq.buy
                ELSE (0)::numeric
            END) - max(
            CASE
                WHEN (iq.year = ((iq.curryear)::integer - 1)) THEN iq.buy
                ELSE (0)::numeric
            END)) / max(
            CASE
                WHEN (iq.year = ((iq.curryear)::integer - 1)) THEN iq.buy
                ELSE (0)::numeric
            END)), 2) * (100)::numeric)
            WHEN ((max(
            CASE
                WHEN (iq.year = ((iq.curryear)::integer - 1)) THEN iq.buy
                ELSE (0)::numeric
            END) = (0)::numeric) AND (max(
            CASE
                WHEN (iq.year = (iq.curryear)::integer) THEN iq.buy
                ELSE (0)::numeric
            END) <> (0)::numeric)) THEN 9999.99
            ELSE (0)::numeric
        END AS bpcv1,
    max(
        CASE
            WHEN (iq.year = ((iq.curryear)::integer - 2)) THEN iq.sell
            ELSE (0)::numeric
        END) AS bsyear3,
    max(
        CASE
            WHEN (iq.year = ((iq.curryear)::integer - 1)) THEN iq.sell
            ELSE (0)::numeric
        END) AS bsyear2,
    max(
        CASE
            WHEN (iq.year = (iq.curryear)::integer) THEN iq.sell
            ELSE (0)::numeric
        END) AS bsyear1,
        CASE
            WHEN ((max(
            CASE
                WHEN (iq.year = ((iq.curryear)::integer - 2)) THEN iq.sell
                ELSE (0)::numeric
            END) <> (0)::numeric) AND (max(
            CASE
                WHEN (iq.year = ((iq.curryear)::integer - 1)) THEN iq.sell
                ELSE (0)::numeric
            END) <> (0)::numeric)) THEN (round(((max(
            CASE
                WHEN (iq.year = ((iq.curryear)::integer - 1)) THEN iq.sell
                ELSE (0)::numeric
            END) - max(
            CASE
                WHEN (iq.year = ((iq.curryear)::integer - 2)) THEN iq.sell
                ELSE (0)::numeric
            END)) / max(
            CASE
                WHEN (iq.year = ((iq.curryear)::integer - 2)) THEN iq.sell
                ELSE (0)::numeric
            END)), 2) * (100)::numeric)
            WHEN ((max(
            CASE
                WHEN (iq.year = ((iq.curryear)::integer - 2)) THEN iq.sell
                ELSE (0)::numeric
            END) = (0)::numeric) AND (max(
            CASE
                WHEN (iq.year = ((iq.curryear)::integer - 1)) THEN iq.sell
                ELSE (0)::numeric
            END) <> (0)::numeric)) THEN 9999.99
            ELSE (0)::numeric
        END AS bs2v1,
        CASE
            WHEN ((max(
            CASE
                WHEN (iq.year = ((iq.curryear)::integer - 1)) THEN iq.sell
                ELSE (0)::numeric
            END) <> (0)::numeric) AND (max(
            CASE
                WHEN (iq.year = (iq.curryear)::integer) THEN iq.sell
                ELSE (0)::numeric
            END) <> (0)::numeric)) THEN (round(((max(
            CASE
                WHEN (iq.year = (iq.curryear)::integer) THEN iq.sell
                ELSE (0)::numeric
            END) - max(
            CASE
                WHEN (iq.year = ((iq.curryear)::integer - 1)) THEN iq.sell
                ELSE (0)::numeric
            END)) / max(
            CASE
                WHEN (iq.year = ((iq.curryear)::integer - 1)) THEN iq.sell
                ELSE (0)::numeric
            END)), 2) * (100)::numeric)
            WHEN ((max(
            CASE
                WHEN (iq.year = ((iq.curryear)::integer - 1)) THEN iq.sell
                ELSE (0)::numeric
            END) = (0)::numeric) AND (max(
            CASE
                WHEN (iq.year = (iq.curryear)::integer) THEN iq.sell
                ELSE (0)::numeric
            END) <> (0)::numeric)) THEN 9999.99
            ELSE (0)::numeric
        END AS bscv1,
    max((iq.country)::text) AS country,
    max((iq.cpty)::text) AS counterparty,
    iq.product_code,
    iq.currency
   FROM ( SELECT countries.name AS country,
            cc.branches_id AS cpty,
            (cc.year)::integer AS year,
            cc.month,
            cc.currency,
            (sum(cc.total_buy_amt_usd) / (1000)::numeric) AS buy,
            (sum(cc.total_sell_amt_usd) / (1000)::numeric) AS sell,
            ((sum(cc.total_buy_amt_usd) / (1000)::numeric) + (sum(cc.total_sell_amt_usd) / (1000)::numeric)) AS total,
            max(to_char(dm.system_date, 'YYYY'::text)) AS curryear,
            cc.product_code
           FROM tbls_history_cust_cmprision cc,
            tbls_dates_master dm,
            tbls_countries countries
          WHERE ((cc.country)::text = (countries.fin_id)::text)
          GROUP BY countries.name, cc.branches_id, cc.year, cc.month, cc.currency, cc.product_code) iq
  GROUP BY iq.country, iq.cpty, iq.month, (iq.curryear)::integer, iq.product_code, iq.currency
  ORDER BY iq.country, iq.cpty, (iq.month)::numeric;


--
--

CREATE VIEW vbls_hist_cust_comp_13 AS
 SELECT (iq.curryear)::integer AS curryear,
    lpad((iq.month)::text, 2, '0'::text) AS month,
    max(
        CASE
            WHEN (iq.year = ((iq.curryear)::integer - 2)) THEN iq.total
            ELSE (0)::numeric
        END) AS tyear3,
    max(
        CASE
            WHEN (iq.year = ((iq.curryear)::integer - 1)) THEN iq.total
            ELSE (0)::numeric
        END) AS tyear2,
    max(
        CASE
            WHEN (iq.year = (iq.curryear)::integer) THEN iq.total
            ELSE (0)::numeric
        END) AS tyear1,
        CASE
            WHEN ((max(
            CASE
                WHEN (iq.year = ((iq.curryear)::integer - 2)) THEN iq.total
                ELSE (0)::numeric
            END) <> (0)::numeric) AND (max(
            CASE
                WHEN (iq.year = ((iq.curryear)::integer - 1)) THEN iq.total
                ELSE (0)::numeric
            END) <> (0)::numeric)) THEN (round(((max(
            CASE
                WHEN (iq.year = ((iq.curryear)::integer - 1)) THEN iq.total
                ELSE (0)::numeric
            END) - max(
            CASE
                WHEN (iq.year = ((iq.curryear)::integer - 2)) THEN iq.total
                ELSE (0)::numeric
            END)) / max(
            CASE
                WHEN (iq.year = ((iq.curryear)::integer - 2)) THEN iq.total
                ELSE (0)::numeric
            END)), 2) * (100)::numeric)
            WHEN ((max(
            CASE
                WHEN (iq.year = ((iq.curryear)::integer - 2)) THEN iq.total
                ELSE (0)::numeric
            END) = (0)::numeric) AND (max(
            CASE
                WHEN (iq.year = ((iq.curryear)::integer - 1)) THEN iq.total
                ELSE (0)::numeric
            END) <> (0)::numeric)) THEN 9999.99
            ELSE (0)::numeric
        END AS t2v1,
        CASE
            WHEN ((max(
            CASE
                WHEN (iq.year = ((iq.curryear)::integer - 1)) THEN iq.total
                ELSE (0)::numeric
            END) <> (0)::numeric) AND (max(
            CASE
                WHEN (iq.year = (iq.curryear)::integer) THEN iq.total
                ELSE (0)::numeric
            END) <> (0)::numeric)) THEN (round(((max(
            CASE
                WHEN (iq.year = (iq.curryear)::integer) THEN iq.total
                ELSE (0)::numeric
            END) - max(
            CASE
                WHEN (iq.year = ((iq.curryear)::integer - 1)) THEN iq.total
                ELSE (0)::numeric
            END)) / max(
            CASE
                WHEN (iq.year = ((iq.curryear)::integer - 1)) THEN iq.total
                ELSE (0)::numeric
            END)), 2) * (100)::numeric)
            WHEN ((max(
            CASE
                WHEN (iq.year = ((iq.curryear)::integer - 1)) THEN iq.total
                ELSE (0)::numeric
            END) = (0)::numeric) AND (max(
            CASE
                WHEN (iq.year = (iq.curryear)::integer) THEN iq.total
                ELSE (0)::numeric
            END) <> (0)::numeric)) THEN 9999.99
            ELSE (0)::numeric
        END AS tcv1,
    max(
        CASE
            WHEN (iq.year = ((iq.curryear)::integer - 2)) THEN iq.buy
            ELSE (0)::numeric
        END) AS bpyear3,
    max(
        CASE
            WHEN (iq.year = ((iq.curryear)::integer - 1)) THEN iq.buy
            ELSE (0)::numeric
        END) AS bpyear2,
    max(
        CASE
            WHEN (iq.year = (iq.curryear)::integer) THEN iq.buy
            ELSE (0)::numeric
        END) AS bpyear1,
        CASE
            WHEN ((max(
            CASE
                WHEN (iq.year = ((iq.curryear)::integer - 2)) THEN iq.buy
                ELSE (0)::numeric
            END) <> (0)::numeric) AND (max(
            CASE
                WHEN (iq.year = ((iq.curryear)::integer - 1)) THEN iq.buy
                ELSE (0)::numeric
            END) <> (0)::numeric)) THEN (round(((max(
            CASE
                WHEN (iq.year = ((iq.curryear)::integer - 1)) THEN iq.buy
                ELSE (0)::numeric
            END) - max(
            CASE
                WHEN (iq.year = ((iq.curryear)::integer - 2)) THEN iq.buy
                ELSE (0)::numeric
            END)) / max(
            CASE
                WHEN (iq.year = ((iq.curryear)::integer - 2)) THEN iq.buy
                ELSE (0)::numeric
            END)), 2) * (100)::numeric)
            WHEN ((max(
            CASE
                WHEN (iq.year = ((iq.curryear)::integer - 2)) THEN iq.buy
                ELSE (0)::numeric
            END) = (0)::numeric) AND (max(
            CASE
                WHEN (iq.year = ((iq.curryear)::integer - 1)) THEN iq.buy
                ELSE (0)::numeric
            END) <> (0)::numeric)) THEN 9999.99
            ELSE (0)::numeric
        END AS bp2v1,
        CASE
            WHEN ((max(
            CASE
                WHEN (iq.year = ((iq.curryear)::integer - 1)) THEN iq.buy
                ELSE (0)::numeric
            END) <> (0)::numeric) AND (max(
            CASE
                WHEN (iq.year = (iq.curryear)::integer) THEN iq.buy
                ELSE (0)::numeric
            END) <> (0)::numeric)) THEN (round(((max(
            CASE
                WHEN (iq.year = (iq.curryear)::integer) THEN iq.buy
                ELSE (0)::numeric
            END) - max(
            CASE
                WHEN (iq.year = ((iq.curryear)::integer - 1)) THEN iq.buy
                ELSE (0)::numeric
            END)) / max(
            CASE
                WHEN (iq.year = ((iq.curryear)::integer - 1)) THEN iq.buy
                ELSE (0)::numeric
            END)), 2) * (100)::numeric)
            WHEN ((max(
            CASE
                WHEN (iq.year = ((iq.curryear)::integer - 1)) THEN iq.buy
                ELSE (0)::numeric
            END) = (0)::numeric) AND (max(
            CASE
                WHEN (iq.year = (iq.curryear)::integer) THEN iq.buy
                ELSE (0)::numeric
            END) <> (0)::numeric)) THEN 9999.99
            ELSE (0)::numeric
        END AS bpcv1,
    max(
        CASE
            WHEN (iq.year = ((iq.curryear)::integer - 2)) THEN iq.sell
            ELSE (0)::numeric
        END) AS bsyear3,
    max(
        CASE
            WHEN (iq.year = ((iq.curryear)::integer - 1)) THEN iq.sell
            ELSE (0)::numeric
        END) AS bsyear2,
    max(
        CASE
            WHEN (iq.year = (iq.curryear)::integer) THEN iq.sell
            ELSE (0)::numeric
        END) AS bsyear1,
        CASE
            WHEN ((max(
            CASE
                WHEN (iq.year = ((iq.curryear)::integer - 2)) THEN iq.sell
                ELSE (0)::numeric
            END) <> (0)::numeric) AND (max(
            CASE
                WHEN (iq.year = ((iq.curryear)::integer - 1)) THEN iq.sell
                ELSE (0)::numeric
            END) <> (0)::numeric)) THEN (round(((max(
            CASE
                WHEN (iq.year = ((iq.curryear)::integer - 1)) THEN iq.sell
                ELSE (0)::numeric
            END) - max(
            CASE
                WHEN (iq.year = ((iq.curryear)::integer - 2)) THEN iq.sell
                ELSE (0)::numeric
            END)) / max(
            CASE
                WHEN (iq.year = ((iq.curryear)::integer - 2)) THEN iq.sell
                ELSE (0)::numeric
            END)), 2) * (100)::numeric)
            WHEN ((max(
            CASE
                WHEN (iq.year = ((iq.curryear)::integer - 2)) THEN iq.sell
                ELSE (0)::numeric
            END) = (0)::numeric) AND (max(
            CASE
                WHEN (iq.year = ((iq.curryear)::integer - 1)) THEN iq.sell
                ELSE (0)::numeric
            END) <> (0)::numeric)) THEN 9999.99
            ELSE (0)::numeric
        END AS bs2v1,
        CASE
            WHEN ((max(
            CASE
                WHEN (iq.year = ((iq.curryear)::integer - 1)) THEN iq.sell
                ELSE (0)::numeric
            END) <> (0)::numeric) AND (max(
            CASE
                WHEN (iq.year = (iq.curryear)::integer) THEN iq.sell
                ELSE (0)::numeric
            END) <> (0)::numeric)) THEN (round(((max(
            CASE
                WHEN (iq.year = (iq.curryear)::integer) THEN iq.sell
                ELSE (0)::numeric
            END) - max(
            CASE
                WHEN (iq.year = ((iq.curryear)::integer - 1)) THEN iq.sell
                ELSE (0)::numeric
            END)) / max(
            CASE
                WHEN (iq.year = ((iq.curryear)::integer - 1)) THEN iq.sell
                ELSE (0)::numeric
            END)), 2) * (100)::numeric)
            WHEN ((max(
            CASE
                WHEN (iq.year = ((iq.curryear)::integer - 1)) THEN iq.sell
                ELSE (0)::numeric
            END) = (0)::numeric) AND (max(
            CASE
                WHEN (iq.year = (iq.curryear)::integer) THEN iq.sell
                ELSE (0)::numeric
            END) <> (0)::numeric)) THEN 9999.99
            ELSE (0)::numeric
        END AS bscv1,
    max((iq.country)::text) AS country,
    iq.product_code,
    iq.currency
   FROM ( SELECT countries.name AS country,
            (cc.year)::integer AS year,
            cc.month,
            cc.currency,
            (sum(cc.total_buy_amt_usd) / (1000)::numeric) AS buy,
            (sum(cc.total_sell_amt_usd) / (1000)::numeric) AS sell,
            ((sum(cc.total_buy_amt_usd) / (1000)::numeric) + (sum(cc.total_sell_amt_usd) / (1000)::numeric)) AS total,
            max(to_char(dm.system_date, 'YYYY'::text)) AS curryear,
            cc.product_code
           FROM tbls_history_cust_cmprision cc,
            tbls_dates_master dm,
            tbls_countries countries
          WHERE ((cc.country)::text = (countries.fin_id)::text)
          GROUP BY countries.name, cc.year, cc.month, cc.currency, cc.product_code) iq
  GROUP BY iq.country, iq.month, (iq.curryear)::integer, iq.product_code, iq.currency
  ORDER BY iq.country, (iq.month)::numeric;


--
--

CREATE VIEW vbls_hist_cust_comp_8 AS
 SELECT (iq.curryear)::integer AS curryear,
    lpad((iq.month)::text, 2, '0'::text) AS month,
    max(
        CASE
            WHEN (iq.year = ((iq.curryear)::integer - 2)) THEN iq.total
            ELSE (0)::numeric
        END) AS tyear3,
    max(
        CASE
            WHEN (iq.year = ((iq.curryear)::integer - 1)) THEN iq.total
            ELSE (0)::numeric
        END) AS tyear2,
    max(
        CASE
            WHEN (iq.year = (iq.curryear)::integer) THEN iq.total
            ELSE (0)::numeric
        END) AS tyear1,
        CASE
            WHEN ((max(
            CASE
                WHEN (iq.year = ((iq.curryear)::integer - 2)) THEN iq.total
                ELSE (0)::numeric
            END) <> (0)::numeric) AND (max(
            CASE
                WHEN (iq.year = ((iq.curryear)::integer - 1)) THEN iq.total
                ELSE (0)::numeric
            END) <> (0)::numeric)) THEN (round(((max(
            CASE
                WHEN (iq.year = ((iq.curryear)::integer - 1)) THEN iq.total
                ELSE (0)::numeric
            END) - max(
            CASE
                WHEN (iq.year = ((iq.curryear)::integer - 2)) THEN iq.total
                ELSE (0)::numeric
            END)) / max(
            CASE
                WHEN (iq.year = ((iq.curryear)::integer - 2)) THEN iq.total
                ELSE (0)::numeric
            END)), 2) * (100)::numeric)
            WHEN ((max(
            CASE
                WHEN (iq.year = ((iq.curryear)::integer - 2)) THEN iq.total
                ELSE (0)::numeric
            END) = (0)::numeric) AND (max(
            CASE
                WHEN (iq.year = ((iq.curryear)::integer - 1)) THEN iq.total
                ELSE (0)::numeric
            END) <> (0)::numeric)) THEN 9999.99
            ELSE (0)::numeric
        END AS t2v1,
        CASE
            WHEN ((max(
            CASE
                WHEN (iq.year = ((iq.curryear)::integer - 1)) THEN iq.total
                ELSE (0)::numeric
            END) <> (0)::numeric) AND (max(
            CASE
                WHEN (iq.year = (iq.curryear)::integer) THEN iq.total
                ELSE (0)::numeric
            END) <> (0)::numeric)) THEN (round(((max(
            CASE
                WHEN (iq.year = (iq.curryear)::integer) THEN iq.total
                ELSE (0)::numeric
            END) - max(
            CASE
                WHEN (iq.year = ((iq.curryear)::integer - 1)) THEN iq.total
                ELSE (0)::numeric
            END)) / max(
            CASE
                WHEN (iq.year = ((iq.curryear)::integer - 1)) THEN iq.total
                ELSE (0)::numeric
            END)), 2) * (100)::numeric)
            WHEN ((max(
            CASE
                WHEN (iq.year = ((iq.curryear)::integer - 1)) THEN iq.total
                ELSE (0)::numeric
            END) = (0)::numeric) AND (max(
            CASE
                WHEN (iq.year = (iq.curryear)::integer) THEN iq.total
                ELSE (0)::numeric
            END) <> (0)::numeric)) THEN 9999.99
            ELSE (0)::numeric
        END AS tcv1,
    max(
        CASE
            WHEN (iq.year = ((iq.curryear)::integer - 2)) THEN iq.buy
            ELSE (0)::numeric
        END) AS bpyear3,
    max(
        CASE
            WHEN (iq.year = ((iq.curryear)::integer - 1)) THEN iq.buy
            ELSE (0)::numeric
        END) AS bpyear2,
    max(
        CASE
            WHEN (iq.year = (iq.curryear)::integer) THEN iq.buy
            ELSE (0)::numeric
        END) AS bpyear1,
        CASE
            WHEN ((max(
            CASE
                WHEN (iq.year = ((iq.curryear)::integer - 2)) THEN iq.buy
                ELSE (0)::numeric
            END) <> (0)::numeric) AND (max(
            CASE
                WHEN (iq.year = ((iq.curryear)::integer - 1)) THEN iq.buy
                ELSE (0)::numeric
            END) <> (0)::numeric)) THEN (round(((max(
            CASE
                WHEN (iq.year = ((iq.curryear)::integer - 1)) THEN iq.buy
                ELSE (0)::numeric
            END) - max(
            CASE
                WHEN (iq.year = ((iq.curryear)::integer - 2)) THEN iq.buy
                ELSE (0)::numeric
            END)) / max(
            CASE
                WHEN (iq.year = ((iq.curryear)::integer - 2)) THEN iq.buy
                ELSE (0)::numeric
            END)), 2) * (100)::numeric)
            WHEN ((max(
            CASE
                WHEN (iq.year = ((iq.curryear)::integer - 2)) THEN iq.buy
                ELSE (0)::numeric
            END) = (0)::numeric) AND (max(
            CASE
                WHEN (iq.year = ((iq.curryear)::integer - 1)) THEN iq.buy
                ELSE (0)::numeric
            END) <> (0)::numeric)) THEN 9999.99
            ELSE (0)::numeric
        END AS bp2v1,
        CASE
            WHEN ((max(
            CASE
                WHEN (iq.year = ((iq.curryear)::integer - 1)) THEN iq.buy
                ELSE (0)::numeric
            END) <> (0)::numeric) AND (max(
            CASE
                WHEN (iq.year = (iq.curryear)::integer) THEN iq.buy
                ELSE (0)::numeric
            END) <> (0)::numeric)) THEN (round(((max(
            CASE
                WHEN (iq.year = (iq.curryear)::integer) THEN iq.buy
                ELSE (0)::numeric
            END) - max(
            CASE
                WHEN (iq.year = ((iq.curryear)::integer - 1)) THEN iq.buy
                ELSE (0)::numeric
            END)) / max(
            CASE
                WHEN (iq.year = ((iq.curryear)::integer - 1)) THEN iq.buy
                ELSE (0)::numeric
            END)), 2) * (100)::numeric)
            WHEN ((max(
            CASE
                WHEN (iq.year = ((iq.curryear)::integer - 1)) THEN iq.buy
                ELSE (0)::numeric
            END) = (0)::numeric) AND (max(
            CASE
                WHEN (iq.year = (iq.curryear)::integer) THEN iq.buy
                ELSE (0)::numeric
            END) <> (0)::numeric)) THEN 9999.99
            ELSE (0)::numeric
        END AS bpcv1,
    max(
        CASE
            WHEN (iq.year = ((iq.curryear)::integer - 2)) THEN iq.sell
            ELSE (0)::numeric
        END) AS bsyear3,
    max(
        CASE
            WHEN (iq.year = ((iq.curryear)::integer - 1)) THEN iq.sell
            ELSE (0)::numeric
        END) AS bsyear2,
    max(
        CASE
            WHEN (iq.year = (iq.curryear)::integer) THEN iq.sell
            ELSE (0)::numeric
        END) AS bsyear1,
        CASE
            WHEN ((max(
            CASE
                WHEN (iq.year = ((iq.curryear)::integer - 2)) THEN iq.sell
                ELSE (0)::numeric
            END) <> (0)::numeric) AND (max(
            CASE
                WHEN (iq.year = ((iq.curryear)::integer - 1)) THEN iq.sell
                ELSE (0)::numeric
            END) <> (0)::numeric)) THEN (round(((max(
            CASE
                WHEN (iq.year = ((iq.curryear)::integer - 1)) THEN iq.sell
                ELSE (0)::numeric
            END) - max(
            CASE
                WHEN (iq.year = ((iq.curryear)::integer - 2)) THEN iq.sell
                ELSE (0)::numeric
            END)) / max(
            CASE
                WHEN (iq.year = ((iq.curryear)::integer - 2)) THEN iq.sell
                ELSE (0)::numeric
            END)), 2) * (100)::numeric)
            WHEN ((max(
            CASE
                WHEN (iq.year = ((iq.curryear)::integer - 2)) THEN iq.sell
                ELSE (0)::numeric
            END) = (0)::numeric) AND (max(
            CASE
                WHEN (iq.year = ((iq.curryear)::integer - 1)) THEN iq.sell
                ELSE (0)::numeric
            END) <> (0)::numeric)) THEN 9999.99
            ELSE (0)::numeric
        END AS bs2v1,
        CASE
            WHEN ((max(
            CASE
                WHEN (iq.year = ((iq.curryear)::integer - 1)) THEN iq.sell
                ELSE (0)::numeric
            END) <> (0)::numeric) AND (max(
            CASE
                WHEN (iq.year = (iq.curryear)::integer) THEN iq.sell
                ELSE (0)::numeric
            END) <> (0)::numeric)) THEN (round(((max(
            CASE
                WHEN (iq.year = (iq.curryear)::integer) THEN iq.sell
                ELSE (0)::numeric
            END) - max(
            CASE
                WHEN (iq.year = ((iq.curryear)::integer - 1)) THEN iq.sell
                ELSE (0)::numeric
            END)) / max(
            CASE
                WHEN (iq.year = ((iq.curryear)::integer - 1)) THEN iq.sell
                ELSE (0)::numeric
            END)), 2) * (100)::numeric)
            WHEN ((max(
            CASE
                WHEN (iq.year = ((iq.curryear)::integer - 1)) THEN iq.sell
                ELSE (0)::numeric
            END) = (0)::numeric) AND (max(
            CASE
                WHEN (iq.year = (iq.curryear)::integer) THEN iq.sell
                ELSE (0)::numeric
            END) <> (0)::numeric)) THEN 9999.99
            ELSE (0)::numeric
        END AS bscv1,
    max((iq.country)::text) AS country,
    max((iq.cpty)::text) AS counterparty,
    max((iq.quarter)::text) AS quarter,
    iq.product_code
   FROM ( SELECT countries.name AS country,
            cc.branches_id AS cpty,
            (cc.year)::integer AS year,
            cc.month,
            cc.quarter,
            (sum(cc.total_buy_amt_usd) / (1000)::numeric) AS buy,
            (sum(cc.total_sell_amt_usd) / (1000)::numeric) AS sell,
            ((sum(cc.total_buy_amt_usd) / (1000)::numeric) + (sum(cc.total_sell_amt_usd) / (1000)::numeric)) AS total,
            max(to_char(dm.system_date, 'YYYY'::text)) AS curryear,
            cc.product_code
           FROM tbls_history_cust_cmprision cc,
            tbls_dates_master dm,
            tbls_countries countries
          WHERE ((cc.country)::text = (countries.fin_id)::text)
          GROUP BY countries.name, cc.branches_id, cc.year, cc.quarter, cc.month, cc.product_code) iq
  GROUP BY iq.country, iq.cpty, iq.quarter, iq.month, (iq.curryear)::integer, iq.product_code
  ORDER BY iq.country, iq.cpty, iq.quarter, (iq.month)::numeric;


--
--

CREATE VIEW vbls_hist_cust_comparison_ccy AS
 SELECT (iq.curryear)::integer AS curryear,
    iq.month,
    max(
        CASE
            WHEN (iq.year = ((iq.curryear)::integer - 2)) THEN iq.total
            ELSE (0)::numeric
        END) AS tyear3,
    max(
        CASE
            WHEN (iq.year = ((iq.curryear)::integer - 1)) THEN iq.total
            ELSE (0)::numeric
        END) AS tyear2,
    max(
        CASE
            WHEN (iq.year = (iq.curryear)::integer) THEN iq.total
            ELSE (0)::numeric
        END) AS tyear1,
        CASE
            WHEN ((max(
            CASE
                WHEN (iq.year = ((iq.curryear)::integer - 2)) THEN iq.total
                ELSE (0)::numeric
            END) <> (0)::numeric) AND (max(
            CASE
                WHEN (iq.year = ((iq.curryear)::integer - 1)) THEN iq.total
                ELSE (0)::numeric
            END) <> (0)::numeric)) THEN (round(((max(
            CASE
                WHEN (iq.year = ((iq.curryear)::integer - 1)) THEN iq.total
                ELSE (0)::numeric
            END) - max(
            CASE
                WHEN (iq.year = ((iq.curryear)::integer - 2)) THEN iq.total
                ELSE (0)::numeric
            END)) / max(
            CASE
                WHEN (iq.year = ((iq.curryear)::integer - 2)) THEN iq.total
                ELSE (0)::numeric
            END)), 2) * (100)::numeric)
            WHEN ((max(
            CASE
                WHEN (iq.year = ((iq.curryear)::integer - 2)) THEN iq.total
                ELSE (0)::numeric
            END) = (0)::numeric) AND (max(
            CASE
                WHEN (iq.year = ((iq.curryear)::integer - 1)) THEN iq.total
                ELSE (0)::numeric
            END) <> (0)::numeric)) THEN 9999.99
            ELSE (0)::numeric
        END AS t2v1,
        CASE
            WHEN ((max(
            CASE
                WHEN (iq.year = ((iq.curryear)::integer - 1)) THEN iq.total
                ELSE (0)::numeric
            END) <> (0)::numeric) AND (max(
            CASE
                WHEN (iq.year = (iq.curryear)::integer) THEN iq.total
                ELSE (0)::numeric
            END) <> (0)::numeric)) THEN (round(((max(
            CASE
                WHEN (iq.year = (iq.curryear)::integer) THEN iq.total
                ELSE (0)::numeric
            END) - max(
            CASE
                WHEN (iq.year = ((iq.curryear)::integer - 1)) THEN iq.total
                ELSE (0)::numeric
            END)) / max(
            CASE
                WHEN (iq.year = ((iq.curryear)::integer - 1)) THEN iq.total
                ELSE (0)::numeric
            END)), 2) * (100)::numeric)
            WHEN ((max(
            CASE
                WHEN (iq.year = ((iq.curryear)::integer - 1)) THEN iq.total
                ELSE (0)::numeric
            END) = (0)::numeric) AND (max(
            CASE
                WHEN (iq.year = (iq.curryear)::integer) THEN iq.total
                ELSE (0)::numeric
            END) <> (0)::numeric)) THEN 9999.99
            ELSE (0)::numeric
        END AS tcv1,
    max(
        CASE
            WHEN (iq.year = ((iq.curryear)::integer - 2)) THEN iq.buy
            ELSE (0)::numeric
        END) AS bpyear3,
    max(
        CASE
            WHEN (iq.year = ((iq.curryear)::integer - 1)) THEN iq.buy
            ELSE (0)::numeric
        END) AS bpyear2,
    max(
        CASE
            WHEN (iq.year = (iq.curryear)::integer) THEN iq.buy
            ELSE (0)::numeric
        END) AS bpyear1,
        CASE
            WHEN ((max(
            CASE
                WHEN (iq.year = ((iq.curryear)::integer - 2)) THEN iq.buy
                ELSE (0)::numeric
            END) <> (0)::numeric) AND (max(
            CASE
                WHEN (iq.year = ((iq.curryear)::integer - 1)) THEN iq.buy
                ELSE (0)::numeric
            END) <> (0)::numeric)) THEN (round(((max(
            CASE
                WHEN (iq.year = ((iq.curryear)::integer - 1)) THEN iq.buy
                ELSE (0)::numeric
            END) - max(
            CASE
                WHEN (iq.year = ((iq.curryear)::integer - 2)) THEN iq.buy
                ELSE (0)::numeric
            END)) / max(
            CASE
                WHEN (iq.year = ((iq.curryear)::integer - 2)) THEN iq.buy
                ELSE (0)::numeric
            END)), 2) * (100)::numeric)
            WHEN ((max(
            CASE
                WHEN (iq.year = ((iq.curryear)::integer - 2)) THEN iq.buy
                ELSE (0)::numeric
            END) = (0)::numeric) AND (max(
            CASE
                WHEN (iq.year = ((iq.curryear)::integer - 1)) THEN iq.buy
                ELSE (0)::numeric
            END) <> (0)::numeric)) THEN 9999.99
            ELSE (0)::numeric
        END AS bp2v1,
        CASE
            WHEN ((max(
            CASE
                WHEN (iq.year = ((iq.curryear)::integer - 1)) THEN iq.buy
                ELSE (0)::numeric
            END) <> (0)::numeric) AND (max(
            CASE
                WHEN (iq.year = (iq.curryear)::integer) THEN iq.buy
                ELSE (0)::numeric
            END) <> (0)::numeric)) THEN (round(((max(
            CASE
                WHEN (iq.year = (iq.curryear)::integer) THEN iq.buy
                ELSE (0)::numeric
            END) - max(
            CASE
                WHEN (iq.year = ((iq.curryear)::integer - 1)) THEN iq.buy
                ELSE (0)::numeric
            END)) / max(
            CASE
                WHEN (iq.year = ((iq.curryear)::integer - 1)) THEN iq.buy
                ELSE (0)::numeric
            END)), 2) * (100)::numeric)
            WHEN ((max(
            CASE
                WHEN (iq.year = ((iq.curryear)::integer - 1)) THEN iq.buy
                ELSE (0)::numeric
            END) = (0)::numeric) AND (max(
            CASE
                WHEN (iq.year = (iq.curryear)::integer) THEN iq.buy
                ELSE (0)::numeric
            END) <> (0)::numeric)) THEN 9999.99
            ELSE (0)::numeric
        END AS bpcv1,
    max(
        CASE
            WHEN (iq.year = ((iq.curryear)::integer - 2)) THEN iq.sell
            ELSE (0)::numeric
        END) AS bsyear3,
    max(
        CASE
            WHEN (iq.year = ((iq.curryear)::integer - 1)) THEN iq.sell
            ELSE (0)::numeric
        END) AS bsyear2,
    max(
        CASE
            WHEN (iq.year = (iq.curryear)::integer) THEN iq.sell
            ELSE (0)::numeric
        END) AS bsyear1,
        CASE
            WHEN ((max(
            CASE
                WHEN (iq.year = ((iq.curryear)::integer - 2)) THEN iq.sell
                ELSE (0)::numeric
            END) <> (0)::numeric) AND (max(
            CASE
                WHEN (iq.year = ((iq.curryear)::integer - 1)) THEN iq.sell
                ELSE (0)::numeric
            END) <> (0)::numeric)) THEN (round(((max(
            CASE
                WHEN (iq.year = ((iq.curryear)::integer - 1)) THEN iq.sell
                ELSE (0)::numeric
            END) - max(
            CASE
                WHEN (iq.year = ((iq.curryear)::integer - 2)) THEN iq.sell
                ELSE (0)::numeric
            END)) / max(
            CASE
                WHEN (iq.year = ((iq.curryear)::integer - 2)) THEN iq.sell
                ELSE (0)::numeric
            END)), 2) * (100)::numeric)
            WHEN ((max(
            CASE
                WHEN (iq.year = ((iq.curryear)::integer - 2)) THEN iq.sell
                ELSE (0)::numeric
            END) = (0)::numeric) AND (max(
            CASE
                WHEN (iq.year = ((iq.curryear)::integer - 1)) THEN iq.sell
                ELSE (0)::numeric
            END) <> (0)::numeric)) THEN 9999.99
            ELSE (0)::numeric
        END AS bs2v1,
        CASE
            WHEN ((max(
            CASE
                WHEN (iq.year = ((iq.curryear)::integer - 1)) THEN iq.sell
                ELSE (0)::numeric
            END) <> (0)::numeric) AND (max(
            CASE
                WHEN (iq.year = (iq.curryear)::integer) THEN iq.sell
                ELSE (0)::numeric
            END) <> (0)::numeric)) THEN (round(((max(
            CASE
                WHEN (iq.year = (iq.curryear)::integer) THEN iq.sell
                ELSE (0)::numeric
            END) - max(
            CASE
                WHEN (iq.year = ((iq.curryear)::integer - 1)) THEN iq.sell
                ELSE (0)::numeric
            END)) / max(
            CASE
                WHEN (iq.year = ((iq.curryear)::integer - 1)) THEN iq.sell
                ELSE (0)::numeric
            END)), 2) * (100)::numeric)
            WHEN ((max(
            CASE
                WHEN (iq.year = ((iq.curryear)::integer - 1)) THEN iq.sell
                ELSE (0)::numeric
            END) = (0)::numeric) AND (max(
            CASE
                WHEN (iq.year = (iq.curryear)::integer) THEN iq.sell
                ELSE (0)::numeric
            END) <> (0)::numeric)) THEN 9999.99
            ELSE (0)::numeric
        END AS bscv1,
    max((iq.country)::text) AS country,
    max((iq.cpty)::text) AS counterparty,
    max((iq.quarter)::text) AS quarter,
    iq.product_code,
    iq.currency
   FROM ( SELECT countries.name AS country,
            cc.client_name AS cpty,
            (cc.year)::integer AS year,
            cc.month,
            cc.quarter,
            cc.currency,
            (sum(cc.total_buy_amt_usd) / (1000)::numeric) AS buy,
            (sum(cc.total_sell_amt_usd) / (1000)::numeric) AS sell,
            ((sum(cc.total_buy_amt_usd) / (1000)::numeric) + (sum(cc.total_sell_amt_usd) / (1000)::numeric)) AS total,
            max(to_char(dm.system_date, 'YYYY'::text)) AS curryear,
            cc.product_code
           FROM tbls_history_cust_cmprision cc,
            tbls_dates_master dm,
            tbls_countries countries,
            tbls_currencypairs cp,
            tbls_fxforward_rates fxs
          WHERE (((cc.country)::text = (countries.fin_id)::text) AND ((((cp.currency1_id)::text = (cc.currency)::text) AND ((cp.currency2_id)::text = 'USD'::text)) OR (((cp.currency1_id)::text = 'USD'::text) AND ((cp.currency2_id)::text = (cc.currency)::text)) OR (((cc.currency)::text = 'USD'::text) AND ((cp.currency1_id)::text = 'USD'::text) AND ((cp.currency2_id)::text = 'SGD'::text))) AND ((fxs.currencypairs_id)::text = (cp.pairs_shortname)::text) AND (to_char(dm.reporting_date, 'YYYYMMDD'::text) = to_char(fxs.mkt_date, 'YYYYMMDD'::text)) AND ((fxs.tenor)::text = 'S'::text))
          GROUP BY countries.name, cc.client_name, cc.year, cc.quarter, cc.month, cc.currency, cc.product_code) iq
  GROUP BY iq.country, iq.cpty, iq.quarter, iq.month, (iq.curryear)::integer, iq.product_code, iq.currency
  ORDER BY iq.country, iq.cpty, iq.quarter, (iq.month)::numeric;


--
--

CREATE VIEW vbls_hist_customer_comp_12 AS
 SELECT iq.ccy AS currency,
    max(
        CASE
            WHEN (iq.year = ((iq.curryear)::integer - 2)) THEN iq.total
            ELSE (0)::numeric
        END) AS tyear3,
    max(
        CASE
            WHEN (iq.year = ((iq.curryear)::integer - 1)) THEN iq.total
            ELSE (0)::numeric
        END) AS tyear2,
    max(
        CASE
            WHEN (iq.year = (iq.curryear)::integer) THEN iq.total
            ELSE (0)::numeric
        END) AS tyear1,
    round(((max(
        CASE
            WHEN (iq.year = ((iq.curryear)::integer - 1)) THEN iq.total
            ELSE (0)::numeric
        END) - max(
        CASE
            WHEN (iq.year = ((iq.curryear)::integer - 2)) THEN iq.total
            ELSE (0)::numeric
        END)) / max(
        CASE
            WHEN (iq.year = ((iq.curryear)::integer - 2)) THEN iq.total
            ELSE (0)::numeric
        END)), 2) AS t2v1,
    round(((max(
        CASE
            WHEN (iq.year = (iq.curryear)::integer) THEN iq.total
            ELSE (0)::numeric
        END) - max(
        CASE
            WHEN (iq.year = ((iq.curryear)::integer - 1)) THEN iq.total
            ELSE (0)::numeric
        END)) / max(
        CASE
            WHEN (iq.year = ((iq.curryear)::integer - 1)) THEN iq.total
            ELSE (0)::numeric
        END)), 2) AS tcv1,
    max(
        CASE
            WHEN (iq.year = ((iq.curryear)::integer - 2)) THEN iq.buy
            ELSE (0)::numeric
        END) AS bpyear3,
    max(
        CASE
            WHEN (iq.year = ((iq.curryear)::integer - 1)) THEN iq.buy
            ELSE (0)::numeric
        END) AS bpyear2,
    max(
        CASE
            WHEN (iq.year = (iq.curryear)::integer) THEN iq.buy
            ELSE (0)::numeric
        END) AS bpyear1,
    round(((max(
        CASE
            WHEN (iq.year = ((iq.curryear)::integer - 1)) THEN iq.buy
            ELSE (0)::numeric
        END) - max(
        CASE
            WHEN (iq.year = ((iq.curryear)::integer - 2)) THEN iq.buy
            ELSE (0)::numeric
        END)) / max(
        CASE
            WHEN (iq.year = ((iq.curryear)::integer - 2)) THEN iq.buy
            ELSE (0)::numeric
        END)), 2) AS bp2v1,
    round(((max(
        CASE
            WHEN (iq.year = (iq.curryear)::integer) THEN iq.buy
            ELSE (0)::numeric
        END) - max(
        CASE
            WHEN (iq.year = ((iq.curryear)::integer - 1)) THEN iq.buy
            ELSE (0)::numeric
        END)) / max(
        CASE
            WHEN (iq.year = ((iq.curryear)::integer - 1)) THEN iq.buy
            ELSE (0)::numeric
        END)), 2) AS bpcv1,
    max(
        CASE
            WHEN (iq.year = ((iq.curryear)::integer - 2)) THEN iq.sell
            ELSE (0)::numeric
        END) AS bsyear3,
    max(
        CASE
            WHEN (iq.year = ((iq.curryear)::integer - 1)) THEN iq.sell
            ELSE (0)::numeric
        END) AS bsyear2,
    max(
        CASE
            WHEN (iq.year = (iq.curryear)::integer) THEN iq.sell
            ELSE (0)::numeric
        END) AS bsyear1,
    round(((max(
        CASE
            WHEN (iq.year = ((iq.curryear)::integer - 1)) THEN iq.sell
            ELSE (0)::numeric
        END) - max(
        CASE
            WHEN (iq.year = ((iq.curryear)::integer - 2)) THEN iq.sell
            ELSE (0)::numeric
        END)) / max(
        CASE
            WHEN (iq.year = ((iq.curryear)::integer - 2)) THEN iq.sell
            ELSE (0)::numeric
        END)), 2) AS bs2v1,
    round(((max(
        CASE
            WHEN (iq.year = (iq.curryear)::integer) THEN iq.sell
            ELSE (0)::numeric
        END) - max(
        CASE
            WHEN (iq.year = ((iq.curryear)::integer - 1)) THEN iq.sell
            ELSE (0)::numeric
        END)) / max(
        CASE
            WHEN (iq.year = ((iq.curryear)::integer - 1)) THEN iq.sell
            ELSE (0)::numeric
        END)), 2) AS bscv1,
    max((iq.country)::text) AS country,
    max((iq.counterparty)::text) AS counterparty
   FROM ( SELECT cc.country,
            (cc.year)::integer AS year,
            cc.currency AS ccy,
            cc.client_name AS counterparty,
            sum(cc.total_buy_amt_usd) AS buy,
            sum(cc.total_sell_amt_usd) AS sell,
            (sum(cc.total_buy_amt_usd) + sum(cc.total_sell_amt_usd)) AS total,
            max(to_char(dm.system_date, 'YYYY'::text)) AS curryear
           FROM tbls_history_cust_cmprision cc,
            tbls_dates_master dm
          GROUP BY cc.country, cc.client_name, cc.year, cc.currency) iq
  GROUP BY iq.country, iq.counterparty, iq.ccy
  ORDER BY iq.country, iq.counterparty, iq.ccy;


--
--

CREATE VIEW vbls_hist_customer_comparison AS
 SELECT iq.curryear,
    iq.month,
    max(
        CASE
            WHEN (iq.year = (iq.curryear - 2)) THEN iq.total
            ELSE (0)::numeric
        END) AS tyear3,
    max(
        CASE
            WHEN (iq.year = (iq.curryear - 1)) THEN iq.total
            ELSE (0)::numeric
        END) AS tyear2,
    max(
        CASE
            WHEN (iq.year = iq.curryear) THEN iq.total
            ELSE (0)::numeric
        END) AS tyear1,
        CASE
            WHEN ((max(
            CASE
                WHEN (iq.year = (iq.curryear - 2)) THEN iq.total
                ELSE (0)::numeric
            END) <> (0)::numeric) AND (max(
            CASE
                WHEN (iq.year = (iq.curryear - 1)) THEN iq.total
                ELSE (0)::numeric
            END) <> (0)::numeric)) THEN (round(((max(
            CASE
                WHEN (iq.year = (iq.curryear - 1)) THEN iq.total
                ELSE (0)::numeric
            END) - max(
            CASE
                WHEN (iq.year = (iq.curryear - 2)) THEN iq.total
                ELSE (0)::numeric
            END)) / max(
            CASE
                WHEN (iq.year = (iq.curryear - 2)) THEN iq.total
                ELSE (0)::numeric
            END)), 2) * (100)::numeric)
            WHEN ((max(
            CASE
                WHEN (iq.year = (iq.curryear - 2)) THEN iq.total
                ELSE (0)::numeric
            END) = (0)::numeric) AND (max(
            CASE
                WHEN (iq.year = (iq.curryear - 1)) THEN iq.total
                ELSE (0)::numeric
            END) <> (0)::numeric)) THEN 9999.99
            ELSE (0)::numeric
        END AS t2v1,
        CASE
            WHEN ((max(
            CASE
                WHEN (iq.year = (iq.curryear - 1)) THEN iq.total
                ELSE (0)::numeric
            END) <> (0)::numeric) AND (max(
            CASE
                WHEN (iq.year = iq.curryear) THEN iq.total
                ELSE (0)::numeric
            END) <> (0)::numeric)) THEN (round(((max(
            CASE
                WHEN (iq.year = iq.curryear) THEN iq.total
                ELSE (0)::numeric
            END) - max(
            CASE
                WHEN (iq.year = (iq.curryear - 1)) THEN iq.total
                ELSE (0)::numeric
            END)) / max(
            CASE
                WHEN (iq.year = (iq.curryear - 1)) THEN iq.total
                ELSE (0)::numeric
            END)), 2) * (100)::numeric)
            WHEN ((max(
            CASE
                WHEN (iq.year = (iq.curryear - 1)) THEN iq.total
                ELSE (0)::numeric
            END) = (0)::numeric) AND (max(
            CASE
                WHEN (iq.year = iq.curryear) THEN iq.total
                ELSE (0)::numeric
            END) <> (0)::numeric)) THEN 9999.99
            ELSE (0)::numeric
        END AS tcv1,
    max(
        CASE
            WHEN (iq.year = (iq.curryear - 2)) THEN iq.buy
            ELSE (0)::numeric
        END) AS bpyear3,
    max(
        CASE
            WHEN (iq.year = (iq.curryear - 1)) THEN iq.buy
            ELSE (0)::numeric
        END) AS bpyear2,
    max(
        CASE
            WHEN (iq.year = iq.curryear) THEN iq.buy
            ELSE (0)::numeric
        END) AS bpyear1,
        CASE
            WHEN ((max(
            CASE
                WHEN (iq.year = (iq.curryear - 2)) THEN iq.buy
                ELSE (0)::numeric
            END) <> (0)::numeric) AND (max(
            CASE
                WHEN (iq.year = (iq.curryear - 1)) THEN iq.buy
                ELSE (0)::numeric
            END) <> (0)::numeric)) THEN (round(((max(
            CASE
                WHEN (iq.year = (iq.curryear - 1)) THEN iq.buy
                ELSE (0)::numeric
            END) - max(
            CASE
                WHEN (iq.year = (iq.curryear - 2)) THEN iq.buy
                ELSE (0)::numeric
            END)) / max(
            CASE
                WHEN (iq.year = (iq.curryear - 2)) THEN iq.buy
                ELSE (0)::numeric
            END)), 2) * (100)::numeric)
            WHEN ((max(
            CASE
                WHEN (iq.year = (iq.curryear - 2)) THEN iq.buy
                ELSE (0)::numeric
            END) = (0)::numeric) AND (max(
            CASE
                WHEN (iq.year = (iq.curryear - 1)) THEN iq.buy
                ELSE (0)::numeric
            END) <> (0)::numeric)) THEN 9999.99
            ELSE (0)::numeric
        END AS bp2v1,
        CASE
            WHEN ((max(
            CASE
                WHEN (iq.year = (iq.curryear - 1)) THEN iq.buy
                ELSE (0)::numeric
            END) <> (0)::numeric) AND (max(
            CASE
                WHEN (iq.year = iq.curryear) THEN iq.buy
                ELSE (0)::numeric
            END) <> (0)::numeric)) THEN (round(((max(
            CASE
                WHEN (iq.year = iq.curryear) THEN iq.buy
                ELSE (0)::numeric
            END) - max(
            CASE
                WHEN (iq.year = (iq.curryear - 1)) THEN iq.buy
                ELSE (0)::numeric
            END)) / max(
            CASE
                WHEN (iq.year = (iq.curryear - 1)) THEN iq.buy
                ELSE (0)::numeric
            END)), 2) * (100)::numeric)
            WHEN ((max(
            CASE
                WHEN (iq.year = (iq.curryear - 1)) THEN iq.buy
                ELSE (0)::numeric
            END) = (0)::numeric) AND (max(
            CASE
                WHEN (iq.year = iq.curryear) THEN iq.buy
                ELSE (0)::numeric
            END) <> (0)::numeric)) THEN 9999.99
            ELSE (0)::numeric
        END AS bpcv1,
    max(
        CASE
            WHEN (iq.year = (iq.curryear - 2)) THEN iq.sell
            ELSE (0)::numeric
        END) AS bsyear3,
    max(
        CASE
            WHEN (iq.year = (iq.curryear - 1)) THEN iq.sell
            ELSE (0)::numeric
        END) AS bsyear2,
    max(
        CASE
            WHEN (iq.year = iq.curryear) THEN iq.sell
            ELSE (0)::numeric
        END) AS bsyear1,
        CASE
            WHEN ((max(
            CASE
                WHEN (iq.year = (iq.curryear - 2)) THEN iq.sell
                ELSE (0)::numeric
            END) <> (0)::numeric) AND (max(
            CASE
                WHEN (iq.year = (iq.curryear - 1)) THEN iq.sell
                ELSE (0)::numeric
            END) <> (0)::numeric)) THEN (round(((max(
            CASE
                WHEN (iq.year = (iq.curryear - 1)) THEN iq.sell
                ELSE (0)::numeric
            END) - max(
            CASE
                WHEN (iq.year = (iq.curryear - 2)) THEN iq.sell
                ELSE (0)::numeric
            END)) / max(
            CASE
                WHEN (iq.year = (iq.curryear - 2)) THEN iq.sell
                ELSE (0)::numeric
            END)), 2) * (100)::numeric)
            WHEN ((max(
            CASE
                WHEN (iq.year = (iq.curryear - 2)) THEN iq.sell
                ELSE (0)::numeric
            END) = (0)::numeric) AND (max(
            CASE
                WHEN (iq.year = (iq.curryear - 1)) THEN iq.sell
                ELSE (0)::numeric
            END) <> (0)::numeric)) THEN 9999.99
            ELSE (0)::numeric
        END AS bs2v1,
        CASE
            WHEN ((max(
            CASE
                WHEN (iq.year = (iq.curryear - 1)) THEN iq.sell
                ELSE (0)::numeric
            END) <> (0)::numeric) AND (max(
            CASE
                WHEN (iq.year = iq.curryear) THEN iq.sell
                ELSE (0)::numeric
            END) <> (0)::numeric)) THEN (round(((max(
            CASE
                WHEN (iq.year = iq.curryear) THEN iq.sell
                ELSE (0)::numeric
            END) - max(
            CASE
                WHEN (iq.year = (iq.curryear - 1)) THEN iq.sell
                ELSE (0)::numeric
            END)) / max(
            CASE
                WHEN (iq.year = (iq.curryear - 1)) THEN iq.sell
                ELSE (0)::numeric
            END)), 2) * (100)::numeric)
            WHEN ((max(
            CASE
                WHEN (iq.year = (iq.curryear - 1)) THEN iq.sell
                ELSE (0)::numeric
            END) = (0)::numeric) AND (max(
            CASE
                WHEN (iq.year = iq.curryear) THEN iq.sell
                ELSE (0)::numeric
            END) <> (0)::numeric)) THEN 9999.99
            ELSE (0)::numeric
        END AS bscv1,
    max((iq.country)::text) AS country,
    max((iq.cpty)::text) AS counterparty,
    max((iq.quarter)::text) AS quarter,
    iq.product_code,
    iq.currency
   FROM ( SELECT countries.name AS country,
            cc.client_name AS cpty,
            (cc.year)::integer AS year,
            (cc.month)::integer AS month,
            cc.quarter,
            cc.currency,
            (sum(cc.total_buy_amt_usd) / (1000)::numeric) AS buy,
            (sum(cc.total_sell_amt_usd) / (1000)::numeric) AS sell,
            ((sum(cc.total_buy_amt_usd) / (1000)::numeric) + (sum(cc.total_sell_amt_usd) / (1000)::numeric)) AS total,
            (max(to_char(dm.system_date, 'YYYY'::text)))::integer AS curryear,
            cc.product_code
           FROM tbls_history_cust_cmprision cc,
            tbls_dates_master dm,
            tbls_countries countries,
            tbls_currencypairs cp,
            tbls_fxforward_rates fxs
          WHERE (((cc.country)::text = (countries.fin_id)::text) AND ((((cp.currency1_id)::text = (cc.currency)::text) AND ((cp.currency2_id)::text = 'USD'::text)) OR (((cp.currency1_id)::text = 'USD'::text) AND ((cp.currency2_id)::text = (cc.currency)::text)) OR (((cc.currency)::text = 'USD'::text) AND ((cp.currency1_id)::text = 'USD'::text) AND ((cp.currency2_id)::text = 'SGD'::text))) AND ((fxs.currencypairs_id)::text = (cp.pairs_shortname)::text) AND (to_char(dm.reporting_date, 'YYYYMMDD'::text) = to_char(fxs.mkt_date, 'YYYYMMDD'::text)) AND ((fxs.tenor)::text = 'S'::text) AND ((fxs.data_set_name)::text = 'CLOSING'::text))
          GROUP BY countries.name, cc.client_name, cc.year, cc.quarter, cc.month, cc.currency, cc.product_code) iq
  GROUP BY iq.country, iq.cpty, iq.quarter, iq.month, iq.curryear, iq.product_code, iq.currency
  ORDER BY iq.country, iq.cpty, iq.quarter, ((iq.month)::numeric);


--
--

CREATE VIEW vbls_historical_cust_comp_10 AS
 SELECT iq.month,
    max(
        CASE
            WHEN (iq.year = (iq.curryear - 2)) THEN iq.total
            ELSE (0)::numeric
        END) AS tyear3,
    max(
        CASE
            WHEN (iq.year = (iq.curryear - 1)) THEN iq.total
            ELSE (0)::numeric
        END) AS tyear2,
    max(
        CASE
            WHEN (iq.year = iq.curryear) THEN iq.total
            ELSE (0)::numeric
        END) AS tyear1,
    round(((max(
        CASE
            WHEN (iq.year = (iq.curryear - 1)) THEN iq.total
            ELSE (0)::numeric
        END) - max(
        CASE
            WHEN (iq.year = (iq.curryear - 2)) THEN iq.total
            ELSE (0)::numeric
        END)) / max(
        CASE
            WHEN (iq.year = (iq.curryear - 2)) THEN iq.total
            ELSE (0)::numeric
        END)), 2) AS t2v1,
    round(((max(
        CASE
            WHEN (iq.year = iq.curryear) THEN iq.total
            ELSE (0)::numeric
        END) - max(
        CASE
            WHEN (iq.year = (iq.curryear - 1)) THEN iq.total
            ELSE (0)::numeric
        END)) / max(
        CASE
            WHEN (iq.year = (iq.curryear - 1)) THEN iq.total
            ELSE (0)::numeric
        END)), 2) AS tcv1,
    max(
        CASE
            WHEN (iq.year = (iq.curryear - 2)) THEN iq.buy
            ELSE (0)::numeric
        END) AS bpyear3,
    max(
        CASE
            WHEN (iq.year = (iq.curryear - 1)) THEN iq.buy
            ELSE (0)::numeric
        END) AS bpyear2,
    max(
        CASE
            WHEN (iq.year = iq.curryear) THEN iq.buy
            ELSE (0)::numeric
        END) AS bpyear1,
    round(((max(
        CASE
            WHEN (iq.year = (iq.curryear - 1)) THEN iq.buy
            ELSE (0)::numeric
        END) - max(
        CASE
            WHEN (iq.year = (iq.curryear - 2)) THEN iq.buy
            ELSE (0)::numeric
        END)) / max(
        CASE
            WHEN (iq.year = (iq.curryear - 2)) THEN iq.buy
            ELSE (0)::numeric
        END)), 2) AS bp2v1,
    round(((max(
        CASE
            WHEN (iq.year = iq.curryear) THEN iq.buy
            ELSE (0)::numeric
        END) - max(
        CASE
            WHEN (iq.year = (iq.curryear - 1)) THEN iq.buy
            ELSE (0)::numeric
        END)) / max(
        CASE
            WHEN (iq.year = (iq.curryear - 1)) THEN iq.buy
            ELSE (0)::numeric
        END)), 2) AS bpcv1,
    max(
        CASE
            WHEN (iq.year = (iq.curryear - 2)) THEN iq.sell
            ELSE (0)::numeric
        END) AS bsyear3,
    max(
        CASE
            WHEN (iq.year = (iq.curryear - 1)) THEN iq.sell
            ELSE (0)::numeric
        END) AS bsyear2,
    max(
        CASE
            WHEN (iq.year = iq.curryear) THEN iq.sell
            ELSE (0)::numeric
        END) AS bsyear1,
    round(((max(
        CASE
            WHEN (iq.year = (iq.curryear - 1)) THEN iq.sell
            ELSE (0)::numeric
        END) - max(
        CASE
            WHEN (iq.year = (iq.curryear - 2)) THEN iq.sell
            ELSE (0)::numeric
        END)) / max(
        CASE
            WHEN (iq.year = (iq.curryear - 2)) THEN iq.sell
            ELSE (0)::numeric
        END)), 2) AS bs2v1,
    round(((max(
        CASE
            WHEN (iq.year = iq.curryear) THEN iq.sell
            ELSE (0)::numeric
        END) - max(
        CASE
            WHEN (iq.year = (iq.curryear - 1)) THEN iq.sell
            ELSE (0)::numeric
        END)) / max(
        CASE
            WHEN (iq.year = (iq.curryear - 1)) THEN iq.sell
            ELSE (0)::numeric
        END)), 2) AS bscv1,
    max((iq.country)::text) AS country,
    max((iq.cpty)::text) AS counterparty,
    max((iq.quarter)::text) AS quarter
   FROM ( SELECT cc.country,
            cc.client_name AS cpty,
            (cc.year)::integer AS year,
            cc.month,
            cc.quarter,
            sum(cc.total_buy_amt_usd) AS buy,
            sum(cc.total_sell_amt_usd) AS sell,
            (sum(cc.total_buy_amt_usd) + sum(cc.total_sell_amt_usd)) AS total,
            (max(to_char(dm.system_date, 'YYYY'::text)))::integer AS curryear
           FROM tbls_history_cust_cmprision cc,
            tbls_dates_master dm
          GROUP BY cc.country, cc.client_name, cc.year, cc.quarter, cc.month) iq
  GROUP BY iq.country, iq.quarter, iq.month
  ORDER BY iq.country, iq.quarter, (iq.month)::numeric;


--
--

CREATE VIEW vbls_inventory_pos_buysell AS
 SELECT (((((((((((((((((((invprojection.currency)::text || '_'::text) || invprojection.buy_sell) || '_'::text) || (invprojection.productscode)::text) || '_'::text) || (invprojection.denomid)::text) || '_'::text) || (invprojection.banknotestypeid)::text) || '_'::text) || (invprojection.vaultid)::text) || '_'::text) || (vaults.main_vault_name)::text) || '_'::text) || (vaults.sub_vault_name)::text) || '_'::text) || to_char(invprojection.vaultdate, 'YYYYMMDD'::text)) || '_'::text) || to_char(invprojection.systemdate, 'YYYYMMDD'::text)) AS fin_id,
    invprojection.currency,
    invprojection.productscode,
    invprojection.denomid,
    invprojection.denomination,
    invprojection.denomcode,
    invprojection.banknotestypeid,
    invprojection.banknotestype,
    invprojection.vaultid,
    vaults.main_vault_name,
    vaults.sub_vault_name,
    invprojection.buy_sell,
    invprojection.seq,
    invprojection.part,
    to_char(invprojection.vaultdate, 'YYYYMMDD'::text) AS vaultdate,
    to_char(invprojection.systemdate, 'YYYYMMDD'::text) AS systemdate,
    (to_date(to_char(invprojection.vaultdate, 'YYYYMMDD'::text), 'YYYYMMDD'::text) - to_date(to_char(invprojection.systemdate, 'YYYYMMDD'::text), 'YYYYMMDD'::text)) AS datediff,
    invprojection.dateflag,
    sum(invprojection.amount) AS amount
   FROM ( SELECT deals.deal_no AS dealno,
            legs.leg_number AS legnumber,
            legs.currencies_id AS currency,
            denoms.fin_id AS denomid,
            denoms.products_code AS productscode,
            denoms.multiplier AS denomination,
            denoms.code AS denomcode,
            bntypes.fin_id AS banknotestypeid,
            bntypes.code AS banknotestype,
            'Part1'::text AS part,
                CASE
                    WHEN ((legs.buy_sell)::text = 'B'::text) THEN abs(legs.amount)
                    ELSE (abs(legs.amount) * ('-1'::integer)::numeric)
                END AS amount,
            legs.vault_status_id AS vaultstatus,
                CASE
                    WHEN (((deals.products_id)::text = ANY (ARRAY[('BKN_DISC'::character varying)::text, ('BKN_DISN'::character varying)::text, ('BKN_CAEX'::character varying)::text, ('BKN_DISW'::character varying)::text, ('TCQ_DISC'::character varying)::text, ('TCQ_DISW'::character varying)::text, ('TCQ_DISN'::character varying)::text])) AND ((legs.buy_sell)::text <> (deals.buy_sell)::text)) THEN bndeals.vault2_date
                    ELSE bndeals.vault_date
                END AS vaultdate,
                CASE
                    WHEN (((deals.products_id)::text = ANY (ARRAY[('BKN_DISC'::character varying)::text, ('BKN_DISN'::character varying)::text, ('BKN_CAEX'::character varying)::text, ('BKN_DISW'::character varying)::text, ('TCQ_DISC'::character varying)::text, ('TCQ_DISW'::character varying)::text, ('TCQ_DISN'::character varying)::text])) AND ((legs.buy_sell)::text <> (deals.buy_sell)::text)) THEN bndeals.vault2_id
                    ELSE bndeals.vault1_id
                END AS vaultid,
            'OPEN'::text AS dateflag,
            dates.system_date AS systemdate,
            'Total'::text AS buy_sell,
            1 AS seq
           FROM tbls_bank_notes_deals_legs legs,
            tbls_bank_notes_deals bndeals,
            tbls_deal_versions versions,
            tbls_deals deals,
            tbls_workflow_states wfstates,
            tbls_bank_notes_denoms denoms,
            tbls_bank_notes_types bntypes,
            tbls_dates_master dates
          WHERE (((legs.is_deleted)::text = 'N'::text) AND ((legs.maker_checker_status)::text = 'COMMITTED'::text) AND ((bndeals.is_deleted)::text = 'N'::text) AND ((bndeals.maker_checker_status)::text = 'COMMITTED'::text) AND ((versions.is_deleted)::text = 'N'::text) AND ((versions.maker_checker_status)::text = 'COMMITTED'::text) AND ((deals.is_deleted)::text = 'N'::text) AND ((deals.maker_checker_status)::text = 'COMMITTED'::text) AND ((wfstates.is_deleted)::text = 'N'::text) AND ((wfstates.maker_checker_status)::text = 'COMMITTED'::text) AND ((denoms.is_deleted)::text = 'N'::text) AND ((denoms.maker_checker_status)::text = 'COMMITTED'::text) AND ((bntypes.is_deleted)::text = 'N'::text) AND ((bntypes.maker_checker_status)::text = 'COMMITTED'::text) AND ((deals.products_id)::text <> ALL (ARRAY[('BKN_UNRR'::character varying)::text, ('BKN_COLS'::character varying)::text])) AND ((legs.bank_notes_deals_id)::text = (bndeals.fin_id)::text) AND ((bndeals.fin_id)::text = (versions.fin_id)::text) AND ((versions.deals_id)::text = (deals.fin_id)::text) AND (deals.version_no = versions.version_no) AND ((legs.vault_status_id)::text = (wfstates.fin_id)::text) AND ((denoms.fin_id)::text = (legs.bank_notes_denoms_id)::text) AND ((bntypes.fin_id)::text = (legs.bank_notes_types_id)::text) AND (to_char(
                CASE
                    WHEN (((deals.products_id)::text = ANY (ARRAY[('BKN_DISC'::character varying)::text, ('BKN_DISN'::character varying)::text, ('BKN_CAEX'::character varying)::text, ('BKN_DISW'::character varying)::text, ('TCQ_DISC'::character varying)::text, ('TCQ_DISW'::character varying)::text, ('TCQ_DISN'::character varying)::text])) AND ((legs.buy_sell)::text <> (deals.buy_sell)::text)) THEN bndeals.vault2_date
                    ELSE bndeals.vault_date
                END, 'YYYYMMDD'::text) >= to_char(dates.system_date, 'YYYYMMDD'::text)) AND ((deals.status)::text = ANY (ARRAY[('LIVE'::character varying)::text, ('INCOMPLETE'::character varying)::text])) AND ((wfstates.workflow_module)::text = 'VAULT'::text) AND ((wfstates.update_main_inv <> 'Y'::bpchar) OR (wfstates.update_other_inv <> 'Y'::bpchar)) AND ((COALESCE(legs.vault_inventory_updated, 'N'::character varying))::text <> 'Y'::text))
        UNION ALL
         SELECT deals.deal_no AS dealno,
            legs.leg_number AS legnumber,
            legs.currencies_id AS currency,
            denoms.fin_id AS denomid,
            denoms.products_code AS productscode,
            denoms.multiplier AS denomination,
            denoms.code AS denomcode,
            bntypes.fin_id AS banknotestypeid,
            bntypes.code AS banknotestype,
            'Part2'::text AS part,
                CASE
                    WHEN ((legs.buy_sell)::text = 'B'::text) THEN (('-1'::integer)::numeric * abs(legs.amount))
                    ELSE abs(legs.amount)
                END AS amount,
            legs.vault_status_id AS vaultstatus,
            bndeals.vault2_date AS vaultdate,
            bndeals.vault2_id AS vaultid,
            'OPEN'::text AS dateflag,
            dates.system_date AS systemdate,
            'Total'::text AS buy_sell,
            1 AS seq
           FROM tbls_bank_notes_deals_legs legs,
            tbls_bank_notes_deals bndeals,
            tbls_deal_versions versions,
            tbls_deals deals,
            tbls_workflow_states wfstates,
            tbls_bank_notes_denoms denoms,
            tbls_bank_notes_types bntypes,
            tbls_dates_master dates
          WHERE (((legs.is_deleted)::text = 'N'::text) AND ((legs.maker_checker_status)::text = 'COMMITTED'::text) AND ((bndeals.is_deleted)::text = 'N'::text) AND ((bndeals.maker_checker_status)::text = 'COMMITTED'::text) AND ((versions.is_deleted)::text = 'N'::text) AND ((versions.maker_checker_status)::text = 'COMMITTED'::text) AND ((deals.is_deleted)::text = 'N'::text) AND ((deals.maker_checker_status)::text = 'COMMITTED'::text) AND ((wfstates.is_deleted)::text = 'N'::text) AND ((wfstates.maker_checker_status)::text = 'COMMITTED'::text) AND ((denoms.is_deleted)::text = 'N'::text) AND ((denoms.maker_checker_status)::text = 'COMMITTED'::text) AND ((bntypes.is_deleted)::text = 'N'::text) AND ((bntypes.maker_checker_status)::text = 'COMMITTED'::text) AND ((deals.products_id)::text = ANY (ARRAY[('BKN_ECIB'::character varying)::text, ('BKN_ECIS'::character varying)::text, ('BKN_CONT'::character varying)::text, ('BKN_CONR'::character varying)::text, ('BKN_CONS'::character varying)::text])) AND ((legs.bank_notes_deals_id)::text = (bndeals.fin_id)::text) AND ((bndeals.fin_id)::text = (versions.fin_id)::text) AND ((versions.deals_id)::text = (deals.fin_id)::text) AND (deals.version_no = versions.version_no) AND ((legs.vault_status_id)::text = (wfstates.fin_id)::text) AND ((denoms.fin_id)::text = (legs.bank_notes_denoms_id)::text) AND ((bntypes.fin_id)::text = (legs.bank_notes_types_id)::text) AND (to_char(COALESCE(bndeals.vault_date, COALESCE(bndeals.vault2_date, dates.system_date)), 'YYYYMMDD'::text) >= to_char(dates.system_date, 'YYYYMMDD'::text)) AND ((deals.status)::text = ANY (ARRAY[('LIVE'::character varying)::text, ('INCOMPLETE'::character varying)::text])) AND ((wfstates.workflow_module)::text = 'VAULT'::text) AND ((wfstates.update_main_inv <> 'Y'::bpchar) OR (wfstates.update_other_inv <> 'Y'::bpchar)) AND ((COALESCE(legs.vault_inventory_updated, 'N'::character varying))::text <> 'Y'::text))
        UNION ALL
         SELECT 'Holding'::character varying AS dealno,
            0 AS legnumber,
            inventory.currencies_id AS currency,
            denoms.fin_id AS denomid,
            denoms.products_code AS productscode,
            denoms.multiplier AS denomination,
            denoms.code AS denomcode,
            bntypes.fin_id AS banknotestypeid,
            bntypes.code AS banknotestype,
            'Part3'::text AS part,
            inventory.amount,
            'HOLDING'::character varying AS vaultstatus,
            dates.system_date AS vaultdate,
            inventory.vaults_id AS vaultid,
            'HOLDING'::text AS dateflag,
            dates.system_date AS systemdate,
            'Total'::text AS buy_sell,
            1 AS seq
           FROM tbls_vaults_inv_cash inventory,
            tbls_bank_notes_denoms denoms,
            tbls_bank_notes_types bntypes,
            tbls_dates_master dates
          WHERE (((inventory.is_deleted)::text = 'N'::text) AND ((inventory.maker_checker_status)::text = 'COMMITTED'::text) AND ((denoms.is_deleted)::text = 'N'::text) AND ((denoms.maker_checker_status)::text = 'COMMITTED'::text) AND ((bntypes.is_deleted)::text = 'N'::text) AND ((bntypes.maker_checker_status)::text = 'COMMITTED'::text) AND ((bntypes.fin_id)::text = (inventory.bank_notes_types_id)::text) AND ((denoms.fin_id)::text = (inventory.bank_notes_denoms_id)::text) AND (inventory.amount <> (0)::numeric))
        UNION ALL
         SELECT deals.deal_no AS dealno,
            legs.leg_number AS legnumber,
            legs.currencies_id AS currency,
            denoms.fin_id AS denomid,
            denoms.products_code AS productscode,
            denoms.multiplier AS denomination,
            denoms.code AS denomcode,
            bntypes.fin_id AS banknotestypeid,
            bntypes.code AS banknotestype,
            'Part4'::text AS part,
                CASE
                    WHEN ((legs.buy_sell)::text = 'B'::text) THEN abs(legs.amount)
                    ELSE (abs(legs.amount) * ('-1'::integer)::numeric)
                END AS amount,
            legs.vault_status_id AS vaultstatus,
                CASE
                    WHEN (((deals.products_id)::text = ANY (ARRAY[('BKN_DISC'::character varying)::text, ('BKN_DISN'::character varying)::text, ('BKN_CAEX'::character varying)::text, ('BKN_DISW'::character varying)::text, ('TCQ_DISC'::character varying)::text, ('TCQ_DISW'::character varying)::text, ('TCQ_DISN'::character varying)::text])) AND ((legs.buy_sell)::text <> (deals.buy_sell)::text)) THEN bndeals.vault2_date
                    ELSE bndeals.vault_date
                END AS vaultdate,
                CASE
                    WHEN (((deals.products_id)::text = ANY (ARRAY[('BKN_DISC'::character varying)::text, ('BKN_DISN'::character varying)::text, ('BKN_CAEX'::character varying)::text, ('BKN_DISW'::character varying)::text, ('TCQ_DISC'::character varying)::text, ('TCQ_DISW'::character varying)::text, ('TCQ_DISN'::character varying)::text])) AND ((legs.buy_sell)::text <> (deals.buy_sell)::text)) THEN bndeals.vault2_id
                    ELSE bndeals.vault1_id
                END AS vaultid,
            'OPEN'::text AS dateflag,
            dates.system_date AS systemdate,
            legs.buy_sell,
                CASE
                    WHEN ((legs.buy_sell)::text = 'B'::text) THEN 2
                    ELSE 3
                END AS seq
           FROM tbls_bank_notes_deals_legs legs,
            tbls_bank_notes_deals bndeals,
            tbls_deal_versions versions,
            tbls_deals deals,
            tbls_workflow_states wfstates,
            tbls_bank_notes_denoms denoms,
            tbls_bank_notes_types bntypes,
            tbls_dates_master dates
          WHERE (((legs.is_deleted)::text = 'N'::text) AND ((legs.maker_checker_status)::text = 'COMMITTED'::text) AND ((bndeals.is_deleted)::text = 'N'::text) AND ((bndeals.maker_checker_status)::text = 'COMMITTED'::text) AND ((versions.is_deleted)::text = 'N'::text) AND ((versions.maker_checker_status)::text = 'COMMITTED'::text) AND ((deals.is_deleted)::text = 'N'::text) AND ((deals.maker_checker_status)::text = 'COMMITTED'::text) AND ((wfstates.is_deleted)::text = 'N'::text) AND ((wfstates.maker_checker_status)::text = 'COMMITTED'::text) AND ((denoms.is_deleted)::text = 'N'::text) AND ((denoms.maker_checker_status)::text = 'COMMITTED'::text) AND ((bntypes.is_deleted)::text = 'N'::text) AND ((bntypes.maker_checker_status)::text = 'COMMITTED'::text) AND ((deals.products_id)::text <> ALL (ARRAY[('BKN_UNRR'::character varying)::text, ('BKN_COLS'::character varying)::text])) AND ((legs.bank_notes_deals_id)::text = (bndeals.fin_id)::text) AND ((bndeals.fin_id)::text = (versions.fin_id)::text) AND ((versions.deals_id)::text = (deals.fin_id)::text) AND (deals.version_no = versions.version_no) AND ((legs.vault_status_id)::text = (wfstates.fin_id)::text) AND ((denoms.fin_id)::text = (legs.bank_notes_denoms_id)::text) AND ((bntypes.fin_id)::text = (legs.bank_notes_types_id)::text) AND (to_char(
                CASE
                    WHEN (((deals.products_id)::text = ANY (ARRAY[('BKN_DISC'::character varying)::text, ('BKN_DISN'::character varying)::text, ('BKN_CAEX'::character varying)::text, ('BKN_DISW'::character varying)::text, ('TCQ_DISC'::character varying)::text, ('TCQ_DISW'::character varying)::text, ('TCQ_DISN'::character varying)::text])) AND ((legs.buy_sell)::text <> (deals.buy_sell)::text)) THEN bndeals.vault2_date
                    ELSE bndeals.vault_date
                END, 'YYYYMMDD'::text) >= to_char(dates.system_date, 'YYYYMMDD'::text)) AND ((deals.status)::text = ANY (ARRAY[('LIVE'::character varying)::text, ('INCOMPLETE'::character varying)::text])) AND ((wfstates.workflow_module)::text = 'VAULT'::text) AND ((wfstates.update_main_inv <> 'Y'::bpchar) OR (wfstates.update_other_inv <> 'Y'::bpchar)) AND ((COALESCE(legs.vault_inventory_updated, 'N'::character varying))::text <> 'Y'::text))
        UNION ALL
         SELECT deals.deal_no AS dealno,
            legs.leg_number AS legnumber,
            legs.currencies_id AS currency,
            denoms.fin_id AS denomid,
            denoms.products_code AS productscode,
            denoms.multiplier AS denomination,
            denoms.code AS denomcode,
            bntypes.fin_id AS banknotestypeid,
            bntypes.code AS banknotestype,
            'Part5'::text AS part,
                CASE
                    WHEN ((legs.buy_sell)::text = 'B'::text) THEN (('-1'::integer)::numeric * abs(legs.amount))
                    ELSE abs(legs.amount)
                END AS amount,
            legs.vault_status_id AS vaultstatus,
            bndeals.vault2_date AS vaultdate,
            bndeals.vault2_id AS vaultid,
            'OPEN'::text AS dateflag,
            dates.system_date AS systemdate,
            legs.buy_sell,
                CASE
                    WHEN ((legs.buy_sell)::text = 'B'::text) THEN 2
                    ELSE 3
                END AS seq
           FROM tbls_bank_notes_deals_legs legs,
            tbls_bank_notes_deals bndeals,
            tbls_deal_versions versions,
            tbls_deals deals,
            tbls_workflow_states wfstates,
            tbls_bank_notes_denoms denoms,
            tbls_bank_notes_types bntypes,
            tbls_dates_master dates
          WHERE (((legs.is_deleted)::text = 'N'::text) AND ((legs.maker_checker_status)::text = 'COMMITTED'::text) AND ((bndeals.is_deleted)::text = 'N'::text) AND ((bndeals.maker_checker_status)::text = 'COMMITTED'::text) AND ((versions.is_deleted)::text = 'N'::text) AND ((versions.maker_checker_status)::text = 'COMMITTED'::text) AND ((deals.is_deleted)::text = 'N'::text) AND ((deals.maker_checker_status)::text = 'COMMITTED'::text) AND ((wfstates.is_deleted)::text = 'N'::text) AND ((wfstates.maker_checker_status)::text = 'COMMITTED'::text) AND ((denoms.is_deleted)::text = 'N'::text) AND ((denoms.maker_checker_status)::text = 'COMMITTED'::text) AND ((bntypes.is_deleted)::text = 'N'::text) AND ((bntypes.maker_checker_status)::text = 'COMMITTED'::text) AND ((deals.products_id)::text = ANY (ARRAY[('BKN_ECIB'::character varying)::text, ('BKN_ECIS'::character varying)::text, ('BKN_CONT'::character varying)::text, ('BKN_CONR'::character varying)::text, ('BKN_CONS'::character varying)::text])) AND ((legs.bank_notes_deals_id)::text = (bndeals.fin_id)::text) AND ((bndeals.fin_id)::text = (versions.fin_id)::text) AND ((versions.deals_id)::text = (deals.fin_id)::text) AND (deals.version_no = versions.version_no) AND ((legs.vault_status_id)::text = (wfstates.fin_id)::text) AND ((denoms.fin_id)::text = (legs.bank_notes_denoms_id)::text) AND ((bntypes.fin_id)::text = (legs.bank_notes_types_id)::text) AND (to_char(COALESCE(bndeals.vault_date, COALESCE(bndeals.vault2_date, dates.system_date)), 'YYYYMMDD'::text) >= to_char(dates.system_date, 'YYYYMMDD'::text)) AND ((deals.status)::text = ANY (ARRAY[('LIVE'::character varying)::text, ('INCOMPLETE'::character varying)::text])) AND ((wfstates.workflow_module)::text = 'VAULT'::text) AND ((wfstates.update_main_inv <> 'Y'::bpchar) OR (wfstates.update_other_inv <> 'Y'::bpchar)) AND ((COALESCE(legs.vault_inventory_updated, 'N'::character varying))::text <> 'Y'::text))) invprojection,
    tbls_vaults vaults
  WHERE ((vaults.fin_id)::text = (invprojection.vaultid)::text)
  GROUP BY invprojection.currency, invprojection.productscode, invprojection.denomid, invprojection.denomination, invprojection.denomcode, invprojection.banknotestypeid, invprojection.banknotestype, invprojection.vaultid, vaults.main_vault_name, vaults.sub_vault_name, invprojection.vaultdate, invprojection.dateflag, invprojection.systemdate, invprojection.buy_sell, invprojection.seq, invprojection.part
  ORDER BY invprojection.vaultdate, invprojection.vaultid, invprojection.productscode, invprojection.currency, invprojection.denomid, invprojection.denomination, invprojection.denomcode, invprojection.banknotestypeid, invprojection.banknotestype, invprojection.seq;


--
--

CREATE VIEW vbls_inv_pos_buysell_cumul AS
 SELECT (((((((((a.dateflag || (a.currency)::text) || (a.productscode)::text) || substr('000000000'::text, 0, (length('000000000'::text) - length((a.denomination)::text)))) || (a.denomination)::text) || (a.denomcode)::text) || (a.banknotestype)::text) || (a.vaultid)::text) || a.vaultdate) || a.buy_sell) AS fin_id,
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
  WHERE ((((a.dateflag = 'HOLDING'::text) AND (a.dateflag = b.dateflag)) OR ((a.dateflag = 'OPEN'::text) AND (a.vaultdate >= b.vaultdate))) AND ((a.currency)::text = (b.currency)::text) AND ((a.productscode)::text = (b.productscode)::text) AND ((a.denomination)::text = (b.denomination)::text) AND ((COALESCE(a.denomcode, ' '::character varying))::text = (COALESCE(b.denomcode, ' '::character varying))::text) AND ((a.banknotestype)::text = (b.banknotestype)::text) AND ((a.vaultid)::text = (b.vaultid)::text) AND (a.seq = b.seq) AND (a.buy_sell = b.buy_sell))
  GROUP BY a.currency, a.productscode, a.denomination, a.denomcode, a.denomid, a.banknotestype, a.vaultid, a.main_vault_name, a.sub_vault_name, a.buy_sell, a.seq, a.vaultdate, a.datediff, a.dateflag
  ORDER BY a.currency, a.productscode, a.denomination, a.banknotestype, a.vaultid, a.vaultdate, a.seq;


--
--

CREATE VIEW vbls_inventory_position AS
 SELECT (((((((((((((((((invprojection.currency)::text || '_'::text) || (invprojection.productscode)::text) || '_'::text) || (invprojection.denomid)::text) || '_'::text) || (invprojection.banknotestypeid)::text) || '_'::text) || (invprojection.vaultid)::text) || '_'::text) || (vaults.main_vault_name)::text) || '_'::text) || (vaults.sub_vault_name)::text) || '_'::text) || to_char(invprojection.vaultdate, 'YYYYMMDD'::text)) || '_'::text) || to_char(invprojection.systemdate, 'YYYYMMDD'::text)) AS fin_id,
    invprojection.currency,
    invprojection.productscode,
    invprojection.denomid,
    invprojection.denomination,
    invprojection.denomcode,
    invprojection.banknotestypeid,
    invprojection.banknotestype,
    invprojection.vaultid,
    vaults.main_vault_name,
    vaults.sub_vault_name,
    to_char(invprojection.vaultdate, 'YYYYMMDD'::text) AS vaultdate,
    to_char(invprojection.systemdate, 'YYYYMMDD'::text) AS systemdate,
    (to_date(to_char(invprojection.vaultdate, 'YYYYMMDD'::text), 'YYYYMMDD'::text) - to_date(to_char(invprojection.systemdate, 'YYYYMMDD'::text), 'YYYYMMDD'::text)) AS datediff,
    invprojection.dateflag,
    sum(invprojection.amount) AS amount
   FROM ( SELECT deals.deal_no AS dealno,
            legs.leg_number AS legnumber,
            legs.currencies_id AS currency,
            denoms.fin_id AS denomid,
            denoms.products_code AS productscode,
            denoms.multiplier AS denomination,
            denoms.code AS denomcode,
            bntypes.fin_id AS banknotestypeid,
            bntypes.code AS banknotestype,
                CASE
                    WHEN ((legs.buy_sell)::text = 'B'::text) THEN abs(legs.amount)
                    ELSE (abs(legs.amount) * ('-1'::integer)::numeric)
                END AS amount,
            legs.vault_status_id AS vaultstatus,
                CASE
                    WHEN (((deals.products_id)::text = ANY (ARRAY[('BKN_DISC'::character varying)::text, ('BKN_DISN'::character varying)::text, ('BKN_CAEX'::character varying)::text, ('BKN_DISW'::character varying)::text, ('TCQ_DISC'::character varying)::text, ('TCQ_DISW'::character varying)::text, ('TCQ_DISN'::character varying)::text])) AND ((legs.buy_sell)::text <> (deals.buy_sell)::text)) THEN bndeals.vault2_date
                    ELSE bndeals.vault_date
                END AS vaultdate,
                CASE
                    WHEN (((deals.products_id)::text = ANY (ARRAY[('BKN_DISC'::character varying)::text, ('BKN_DISN'::character varying)::text, ('BKN_CAEX'::character varying)::text, ('BKN_DISW'::character varying)::text, ('TCQ_DISC'::character varying)::text, ('TCQ_DISW'::character varying)::text, ('TCQ_DISN'::character varying)::text])) AND ((legs.buy_sell)::text <> (deals.buy_sell)::text)) THEN bndeals.vault2_id
                    ELSE bndeals.vault1_id
                END AS vaultid,
            'OPEN'::text AS dateflag,
            dates.system_date AS systemdate
           FROM tbls_bank_notes_deals_legs legs,
            tbls_bank_notes_deals bndeals,
            tbls_deal_versions versions,
            tbls_deals deals,
            tbls_workflow_states wfstates,
            tbls_bank_notes_denoms denoms,
            tbls_bank_notes_types bntypes,
            tbls_dates_master dates
          WHERE (((legs.is_deleted)::text = 'N'::text) AND ((legs.maker_checker_status)::text = 'COMMITTED'::text) AND ((bndeals.is_deleted)::text = 'N'::text) AND ((bndeals.maker_checker_status)::text = 'COMMITTED'::text) AND ((versions.is_deleted)::text = 'N'::text) AND ((versions.maker_checker_status)::text = 'COMMITTED'::text) AND ((deals.is_deleted)::text = 'N'::text) AND ((deals.maker_checker_status)::text = 'COMMITTED'::text) AND ((wfstates.is_deleted)::text = 'N'::text) AND ((wfstates.maker_checker_status)::text = 'COMMITTED'::text) AND ((denoms.is_deleted)::text = 'N'::text) AND ((denoms.maker_checker_status)::text = 'COMMITTED'::text) AND ((bntypes.is_deleted)::text = 'N'::text) AND ((bntypes.maker_checker_status)::text = 'COMMITTED'::text) AND ((deals.products_id)::text <> ALL (ARRAY[('BKN_UNRR'::character varying)::text, ('BKN_COLS'::character varying)::text])) AND ((legs.bank_notes_deals_id)::text = (bndeals.fin_id)::text) AND ((bndeals.fin_id)::text = (versions.fin_id)::text) AND ((versions.deals_id)::text = (deals.fin_id)::text) AND (deals.version_no = versions.version_no) AND ((legs.vault_status_id)::text = (wfstates.fin_id)::text) AND ((denoms.fin_id)::text = (legs.bank_notes_denoms_id)::text) AND ((bntypes.fin_id)::text = (legs.bank_notes_types_id)::text) AND (to_char(
                CASE
                    WHEN (((deals.products_id)::text = ANY (ARRAY[('BKN_DISC'::character varying)::text, ('BKN_DISN'::character varying)::text, ('BKN_CAEX'::character varying)::text, ('BKN_DISW'::character varying)::text, ('TCQ_DISC'::character varying)::text, ('TCQ_DISW'::character varying)::text, ('TCQ_DISN'::character varying)::text])) AND ((legs.buy_sell)::text <> (deals.buy_sell)::text)) THEN bndeals.vault2_date
                    ELSE bndeals.vault_date
                END, 'YYYYMMDD'::text) >= to_char(dates.system_date, 'YYYYMMDD'::text)) AND ((deals.status)::text = ANY (ARRAY[('LIVE'::character varying)::text, ('INCOMPLETE'::character varying)::text])) AND ((wfstates.workflow_module)::text = 'VAULT'::text) AND ((wfstates.update_main_inv <> 'Y'::bpchar) OR (wfstates.update_other_inv <> 'Y'::bpchar)) AND ((COALESCE(legs.vault_inventory_updated, 'N'::character varying))::text <> 'Y'::text))
        UNION ALL
         SELECT deals.deal_no AS dealno,
            legs.leg_number AS legnumber,
            legs.currencies_id AS currency,
            denoms.fin_id AS denomid,
            denoms.products_code AS productscode,
            denoms.multiplier AS denomination,
            denoms.code AS denomcode,
            bntypes.fin_id AS banknotestypeid,
            bntypes.code AS banknotestype,
                CASE
                    WHEN ((legs.buy_sell)::text = 'B'::text) THEN (('-1'::integer)::numeric * abs(legs.amount))
                    ELSE abs(legs.amount)
                END AS amount,
            legs.vault_status_id AS vaultstatus,
            bndeals.vault2_date AS vaultdate,
            bndeals.vault2_id AS vaultid,
            'OPEN'::text AS dateflag,
            dates.system_date AS systemdate
           FROM tbls_bank_notes_deals_legs legs,
            tbls_bank_notes_deals bndeals,
            tbls_deal_versions versions,
            tbls_deals deals,
            tbls_workflow_states wfstates,
            tbls_bank_notes_denoms denoms,
            tbls_bank_notes_types bntypes,
            tbls_dates_master dates
          WHERE (((legs.is_deleted)::text = 'N'::text) AND ((legs.maker_checker_status)::text = 'COMMITTED'::text) AND ((bndeals.is_deleted)::text = 'N'::text) AND ((bndeals.maker_checker_status)::text = 'COMMITTED'::text) AND ((versions.is_deleted)::text = 'N'::text) AND ((versions.maker_checker_status)::text = 'COMMITTED'::text) AND ((deals.is_deleted)::text = 'N'::text) AND ((deals.maker_checker_status)::text = 'COMMITTED'::text) AND ((wfstates.is_deleted)::text = 'N'::text) AND ((wfstates.maker_checker_status)::text = 'COMMITTED'::text) AND ((denoms.is_deleted)::text = 'N'::text) AND ((denoms.maker_checker_status)::text = 'COMMITTED'::text) AND ((bntypes.is_deleted)::text = 'N'::text) AND ((bntypes.maker_checker_status)::text = 'COMMITTED'::text) AND ((deals.products_id)::text = ANY (ARRAY[('BKN_ECIB'::character varying)::text, ('BKN_ECIS'::character varying)::text, ('BKN_CONT'::character varying)::text, ('BKN_CONR'::character varying)::text, ('BKN_CONS'::character varying)::text])) AND ((legs.bank_notes_deals_id)::text = (bndeals.fin_id)::text) AND ((bndeals.fin_id)::text = (versions.fin_id)::text) AND ((versions.deals_id)::text = (deals.fin_id)::text) AND (deals.version_no = versions.version_no) AND ((legs.vault_status_id)::text = (wfstates.fin_id)::text) AND ((denoms.fin_id)::text = (legs.bank_notes_denoms_id)::text) AND ((bntypes.fin_id)::text = (legs.bank_notes_types_id)::text) AND (to_char(COALESCE(bndeals.vault_date, COALESCE(bndeals.vault2_date, dates.system_date)), 'YYYYMMDD'::text) >= to_char(dates.system_date, 'YYYYMMDD'::text)) AND ((deals.status)::text = ANY (ARRAY[('LIVE'::character varying)::text, ('INCOMPLETE'::character varying)::text])) AND ((wfstates.workflow_module)::text = 'VAULT'::text) AND ((wfstates.update_main_inv <> 'Y'::bpchar) OR (wfstates.update_other_inv <> 'Y'::bpchar)) AND ((COALESCE(legs.vault_inventory_updated, 'N'::character varying))::text <> 'Y'::text))
        UNION ALL
         SELECT 'Holding'::character varying AS dealno,
            0 AS legnumber,
            inventory.currencies_id AS currency,
            denoms.fin_id AS denomid,
            denoms.products_code AS productscode,
            denoms.multiplier AS denomination,
            denoms.code AS denomcode,
            bntypes.fin_id AS banknotestypeid,
            bntypes.code AS banknotestype,
            inventory.amount,
            'HOLDING'::character varying AS vaultstatus,
            dates.system_date AS vaultdate,
            inventory.vaults_id AS vaultid,
            'HOLDING'::text AS dateflag,
            dates.system_date AS systemdate
           FROM tbls_vaults_inv_cash inventory,
            tbls_bank_notes_denoms denoms,
            tbls_bank_notes_types bntypes,
            tbls_dates_master dates
          WHERE (((inventory.is_deleted)::text = 'N'::text) AND ((inventory.maker_checker_status)::text = 'COMMITTED'::text) AND ((denoms.is_deleted)::text = 'N'::text) AND ((denoms.maker_checker_status)::text = 'COMMITTED'::text) AND ((bntypes.is_deleted)::text = 'N'::text) AND ((bntypes.maker_checker_status)::text = 'COMMITTED'::text) AND ((bntypes.fin_id)::text = (inventory.bank_notes_types_id)::text) AND ((denoms.fin_id)::text = (inventory.bank_notes_denoms_id)::text))) invprojection,
    tbls_vaults vaults
  WHERE ((vaults.fin_id)::text = (invprojection.vaultid)::text)
  GROUP BY invprojection.currency, invprojection.productscode, invprojection.denomid, invprojection.denomination, invprojection.denomcode, invprojection.banknotestypeid, invprojection.banknotestype, invprojection.vaultid, vaults.main_vault_name, vaults.sub_vault_name, invprojection.vaultdate, invprojection.dateflag, invprojection.systemdate
  ORDER BY invprojection.vaultdate, invprojection.vaultid, invprojection.productscode, invprojection.currency, invprojection.denomid, invprojection.denomination, invprojection.denomcode, invprojection.banknotestypeid, invprojection.banknotestype;


--
--

CREATE VIEW vbls_inventory_position_cumul AS
 SELECT ((((((((a.dateflag || (a.currency)::text) || (a.productscode)::text) || substr('000000000'::text, 0, (length('000000000'::text) - length((a.denomination)::text)))) || (a.denomination)::text) || COALESCE((a.denomcode)::text, ''::text)) || (a.banknotestype)::text) || (a.vaultid)::text) || a.vaultdate) AS fin_id,
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
   FROM vbls_inventory_position a,
    vbls_inventory_position b
  WHERE ((((a.dateflag = 'HOLDING'::text) AND (a.dateflag = b.dateflag)) OR ((a.dateflag = 'OPEN'::text) AND (a.vaultdate >= b.vaultdate))) AND ((a.currency)::text = (b.currency)::text) AND ((a.productscode)::text = (b.productscode)::text) AND ((a.denomination)::text = (b.denomination)::text) AND ((COALESCE(a.denomcode, ' '::character varying))::text = (COALESCE(b.denomcode, ' '::character varying))::text) AND ((a.banknotestype)::text = (b.banknotestype)::text) AND ((a.vaultid)::text = (b.vaultid)::text))
  GROUP BY a.currency, a.productscode, a.denomination, a.denomcode, a.denomid, a.banknotestype, a.vaultid, a.main_vault_name, a.sub_vault_name, a.vaultdate, a.datediff, a.dateflag
  ORDER BY a.currency, a.productscode, a.denomination, a.denomcode, a.denomid, a.banknotestype, a.vaultid, a.main_vault_name, a.sub_vault_name, a.vaultdate, a.dateflag;


--
--

CREATE VIEW vbls_irr_deal_entries AS
 SELECT (((((((deals.deal_no)::text || '_'::text) || deals.version_no) || '_'::text) || bn_legs.leg_number) || '_'::text) || (prd.deal_type_code)::text) AS fin_id,
    deals.deal_no,
    deals.version_no,
    bn_legs.leg_number AS leg_no,
    prd.code AS product_type,
    prd.deal_type_code AS deal_type,
        CASE
            WHEN ((bn_legs.currencies_id)::text = (bn.setl_cur_id)::text) THEN
            CASE
                WHEN ((bn_legs.currencies_id)::text = (( SELECT tbls_regions.currencies_id
                   FROM tbls_regions
                  WHERE ((tbls_regions.fin_id)::text = (( SELECT tbls_dates_master.region_id
                           FROM tbls_dates_master))::text)))::text) THEN 'LIKE_BASE'::text
                ELSE 'LIKE'::text
            END
            ELSE 'UNLIKE'::text
        END AS deal_sub_type,
    deals.buy_sell,
        CASE
            WHEN (deals.trade_date < deals.action_date) THEN deals.action_date
            ELSE deals.trade_date
        END AS trade_date,
        CASE
            WHEN (deals.value_date < deals.action_date) THEN deals.action_date
            ELSE deals.value_date
        END AS value_date,
        CASE
            WHEN (bn.release_date < deals.action_date) THEN deals.action_date
            ELSE bn.release_date
        END AS release_date,
        CASE
            WHEN (bn.vault_date < deals.action_date) THEN deals.action_date
            ELSE bn.vault_date
        END AS vault_date,
        CASE
            WHEN ((deals.products_id)::text = ANY (ARRAY[('BKN_CAEX'::character varying)::text, ('BKN_CONT'::character varying)::text])) THEN bn.vault2_date
            ELSE NULL::timestamp without time zone
        END AS vault2_date,
        CASE
            WHEN ((deals.products_id)::text = ANY (ARRAY[('BKN_CAEX'::character varying)::text, ('BKN_OFFS'::character varying)::text])) THEN bn.release2_date
            ELSE NULL::timestamp without time zone
        END AS release2_date,
    ( SELECT tbls_dates_master.system_date
           FROM tbls_dates_master) AS accounting_date,
        CASE
            WHEN (bn.release_date < deals.value_date) THEN
            CASE
                WHEN (bn.release_date < deals.action_date) THEN deals.action_date
                ELSE bn.release_date
            END
            ELSE
            CASE
                WHEN (deals.value_date < deals.action_date) THEN deals.action_date
                ELSE deals.value_date
            END
        END AS memo_rev_date,
        CASE
            WHEN ((deals.buy_sell)::text = 'B'::text) THEN bn_legs.currencies_id
            ELSE bn.setl_cur_id
        END AS buy_currency,
        CASE
            WHEN ((deals.buy_sell)::text = 'S'::text) THEN bn_legs.currencies_id
            ELSE bn.setl_cur_id
        END AS sell_currency,
        CASE
            WHEN ((deals.buy_sell)::text = 'B'::text) THEN bn_legs.amount
            ELSE bn_legs.setl_amount
        END AS buy_amount,
        CASE
            WHEN ((deals.buy_sell)::text = 'S'::text) THEN bn_legs.amount
            ELSE bn_legs.setl_amount
        END AS sell_amount,
    bn.setl_cur_id AS settlement_currency,
    bn_legs.setl_amount AS settlement_amount,
    COALESCE(fxsetlrates.closing_rate, (1)::numeric) AS settlementfxrate,
    COALESCE(fxlegrates.closing_rate, (1)::numeric) AS legfxrate,
    deals.repositories_id,
    rp.corp_code,
    rp.cost_center,
    cust.short_name AS customers_id,
    cust.country_incorporation_id AS customer_country,
    cust.is_resident,
    ct.type_code AS customer_type,
        CASE
            WHEN ((cust.is_resident)::text = 'Y'::text) THEN '0'::text
            ELSE '1'::text
        END AS ios_code,
    bn_legs.deal_rate,
    bn_legs.market_rate,
    bn.usd_rate_vs_setl_cur,
    bn.usd_rate_vs_base_cur,
    bn_legs.md,
    bn_legs.spotfactor,
    uddt.ud_deal_types_id,
    prd.deal_type_code AS linked_deal_type,
    uddt.ud_deal_types_id AS linked_ud_deal_types_id
   FROM tbls_deals deals,
    tbls_deal_versions versions,
    (((tbls_bank_notes_deals bn
     LEFT JOIN tbls_deal_versions ver ON (((ver.fin_id)::text = (bn.fin_id)::text)))
     LEFT JOIN tbls_deals d ON (((d.version_no = ver.version_no) AND ((d.fin_id)::text = (ver.deals_id)::text))))
     LEFT JOIN ( SELECT
                CASE
                    WHEN ((rates.currency1)::text = (regions.currencies_id)::text) THEN rates.currency2
                    ELSE rates.currency1
                END AS ccy1,
                CASE
                    WHEN ((rates.currency2)::text = (regions.currencies_id)::text) THEN rates.currency2
                    ELSE rates.currency1
                END AS ccy2,
                CASE
                    WHEN ((rates.currency1)::text = (regions.currencies_id)::text) THEN ((1)::numeric / rates.closing_rate)
                    ELSE rates.closing_rate
                END AS closing_rate,
            rates.mkt_date
           FROM tbls_bls_closing_spot_rates rates,
            tbls_dates_master dm_1,
            tbls_regions regions
          WHERE (((regions.fin_id)::text = (dm_1.region_id)::text) AND (((rates.currency1)::text = (regions.currencies_id)::text) OR ((rates.currency2)::text = (regions.currencies_id)::text)) AND (rates.mkt_date = rates.forward_date))) fxsetlrates ON ((((bn.setl_cur_id)::text = (fxsetlrates.ccy1)::text) AND (fxsetlrates.mkt_date = d.entry_date)))),
    (tbls_bank_notes_deals_legs bn_legs
     LEFT JOIN ( SELECT
                CASE
                    WHEN ((rates.currency1)::text = (regions.currencies_id)::text) THEN rates.currency2
                    ELSE rates.currency1
                END AS ccy1,
                CASE
                    WHEN ((rates.currency2)::text = (regions.currencies_id)::text) THEN rates.currency2
                    ELSE rates.currency1
                END AS ccy2,
                CASE
                    WHEN ((rates.currency1)::text = (regions.currencies_id)::text) THEN ((1)::numeric / rates.closing_rate)
                    ELSE rates.closing_rate
                END AS closing_rate
           FROM tbls_bls_closing_spot_rates rates,
            tbls_dates_master dm_1,
            tbls_regions regions
          WHERE (((regions.fin_id)::text = (dm_1.region_id)::text) AND (((rates.currency1)::text = (regions.currencies_id)::text) OR ((rates.currency2)::text = (regions.currencies_id)::text)) AND (rates.forward_date = dm_1.reporting_date) AND (rates.mkt_date = dm_1.reporting_date))) fxlegrates ON (((bn_legs.currencies_id)::text = (fxlegrates.ccy1)::text))),
    tbls_repositories rp,
    tbls_customers cust,
    tbls_customer_types ct,
    tbls_products prd,
    tbls_ud_dt_mapping uddt,
    tbls_dates_master dm
  WHERE (((deals.fin_id)::text = (versions.deals_id)::text) AND (deals.version_no = versions.version_no) AND ((versions.fin_id)::text = (bn.fin_id)::text) AND ((bn.fin_id)::text = (bn_legs.bank_notes_deals_id)::text) AND ((deals.buy_sell)::text = (bn_legs.buy_sell)::text) AND ((deals.repositories_id)::text = (rp.fin_id)::text) AND ((deals.customers_id)::text = (cust.fin_id)::text) AND ((cust.type_id)::text = (ct.fin_id)::text) AND ((deals.products_id)::text = (prd.fin_id)::text) AND ((uddt.fin_id)::text = (deals.ud_deal_types_id)::text) AND ((deals.action)::text <> 'CANCEL'::text) AND (((prd.deal_type_code)::text <> 'CAEX'::text) OR ((bn_legs.buy_sell)::text = (deals.buy_sell)::text)) AND (to_char(deals.action_date, 'YYYYMMDD'::text) <= ( SELECT to_char(tbls_dates_master.accounting_date, 'YYYYMMDD'::text) AS to_char
           FROM tbls_dates_master)) AND ((deals.maker_checker_status)::text = 'COMMITTED'::text) AND ((deals.is_deleted)::text = 'N'::text) AND ((versions.maker_checker_status)::text = 'COMMITTED'::text) AND ((versions.is_deleted)::text = 'N'::text) AND ((bn.maker_checker_status)::text = 'COMMITTED'::text) AND ((bn.is_deleted)::text = 'N'::text) AND ((bn_legs.maker_checker_status)::text = 'COMMITTED'::text) AND ((bn_legs.is_deleted)::text = 'N'::text) AND ((rp.maker_checker_status)::text = 'COMMITTED'::text) AND ((rp.is_deleted)::text = 'N'::text) AND ((ct.maker_checker_status)::text = 'COMMITTED'::text) AND ((ct.is_deleted)::text = 'N'::text) AND ((cust.maker_checker_status)::text = 'COMMITTED'::text) AND ((cust.is_deleted)::text = 'N'::text) AND (to_char(
        CASE
            WHEN (versions.maturity_date IS NOT NULL) THEN versions.maturity_date
            ELSE bn.vault_date
        END, 'YYYYMMDD'::text) >= to_char(dm.reporting_date, 'YYYYMMDD'::text)) AND (to_char(versions.trade_date, 'YYYYMMDD'::text) <= to_char(dm.reporting_date, 'YYYYMMDD'::text)) AND ((deals.products_id)::text IN ( SELECT tbls_products.fin_id
           FROM tbls_products
          WHERE ((tbls_products.code)::text = ANY (ARRAY[('BKN'::character varying)::text, ('TCQ'::character varying)::text])))) AND (bn.setl_cur_id IS NOT NULL))
UNION
 SELECT ((((((deals.deal_no)::text || '_'::text) || deals.version_no) || '_'::text) || bn_legs.leg_number) || '_COLC'::text) AS fin_id,
        CASE
            WHEN ((prd.deal_type_code)::text = 'COLC'::text) THEN deals.deal_no
            ELSE versions.link_deal_no
        END AS deal_no,
    deals.version_no,
    bn_legs.leg_number AS leg_no,
    prd.code AS product_type,
    prd.deal_type_code AS deal_type,
        CASE
            WHEN ((bn_legs.currencies_id)::text = (bn.setl_cur_id)::text) THEN
            CASE
                WHEN ((bn_legs.currencies_id)::text = (( SELECT tbls_regions.currencies_id
                   FROM tbls_regions
                  WHERE ((tbls_regions.fin_id)::text = (( SELECT tbls_dates_master.region_id
                           FROM tbls_dates_master))::text)))::text) THEN 'LIKE_BASE'::text
                ELSE 'LIKE'::text
            END
            ELSE 'UNLIKE'::text
        END AS deal_sub_type,
    deals.buy_sell,
        CASE
            WHEN (deals.trade_date < deals.action_date) THEN deals.action_date
            ELSE deals.trade_date
        END AS trade_date,
        CASE
            WHEN (deals.value_date < deals.action_date) THEN deals.action_date
            ELSE deals.value_date
        END AS value_date,
        CASE
            WHEN (bn.release_date < deals.action_date) THEN deals.action_date
            ELSE bn.release_date
        END AS release_date,
        CASE
            WHEN (bn.vault_date < deals.action_date) THEN deals.action_date
            ELSE bn.vault_date
        END AS vault_date,
        CASE
            WHEN ((deals.products_id)::text = ANY (ARRAY[('BKN_CAEX'::character varying)::text, ('BKN_CONT'::character varying)::text])) THEN bn.vault2_date
            ELSE NULL::timestamp without time zone
        END AS vault2_date,
        CASE
            WHEN ((deals.products_id)::text = ANY (ARRAY[('BKN_CAEX'::character varying)::text, ('BKN_OFFS'::character varying)::text])) THEN bn.release2_date
            ELSE NULL::timestamp without time zone
        END AS release2_date,
    ( SELECT tbls_dates_master.system_date
           FROM tbls_dates_master) AS accounting_date,
    dm.system_date AS memo_rev_date,
        CASE
            WHEN ((deals.buy_sell)::text = 'B'::text) THEN bn_legs.currencies_id
            ELSE ''::character varying
        END AS buy_currency,
        CASE
            WHEN ((deals.buy_sell)::text = 'S'::text) THEN bn_legs.currencies_id
            ELSE ''::character varying
        END AS sell_currency,
        CASE
            WHEN ((deals.buy_sell)::text = 'B'::text) THEN
            CASE
                WHEN ((prd.deal_type_code)::text = 'COLC'::text) THEN bn_legs.amount
                ELSE (('-1'::integer)::numeric * bn_legs.amount)
            END
            ELSE (0)::numeric
        END AS buy_amount,
        CASE
            WHEN ((deals.buy_sell)::text = 'S'::text) THEN
            CASE
                WHEN ((prd.deal_type_code)::text = 'COLC'::text) THEN bn_legs.amount
                ELSE (('-1'::integer)::numeric * bn_legs.amount)
            END
            ELSE (0)::numeric
        END AS sell_amount,
    bn.setl_cur_id AS settlement_currency,
    bn_legs.setl_amount AS settlement_amount,
    COALESCE(fxsetlrates.closing_rate, (1)::numeric) AS settlementfxrate,
    COALESCE(fxlegrates.closing_rate, (1)::numeric) AS legfxrate,
    deals.repositories_id,
    rp.corp_code,
    rp.cost_center,
    cust.short_name AS customers_id,
    cust.country_incorporation_id AS customer_country,
    cust.is_resident,
    ct.type_code AS customer_type,
        CASE
            WHEN ((cust.is_resident)::text = 'Y'::text) THEN '0'::text
            ELSE '1'::text
        END AS ios_code,
    bn_legs.deal_rate,
    bn_legs.market_rate,
    bn.usd_rate_vs_setl_cur,
    bn.usd_rate_vs_base_cur,
    bn_legs.md,
    bn_legs.spotfactor,
    uddt.ud_deal_types_id,
    'COLC'::character varying AS linked_deal_type,
    'COLC'::character varying AS linked_ud_deal_types_id
   FROM tbls_deals deals,
    tbls_deal_versions versions,
    (((tbls_bank_notes_deals bn
     LEFT JOIN tbls_deal_versions ver ON (((ver.fin_id)::text = (bn.fin_id)::text)))
     LEFT JOIN tbls_deals d ON (((d.version_no = ver.version_no) AND ((d.fin_id)::text = (ver.deals_id)::text))))
     LEFT JOIN ( SELECT
                CASE
                    WHEN ((rates.currency1)::text = (regions.currencies_id)::text) THEN rates.currency2
                    ELSE rates.currency1
                END AS ccy1,
                CASE
                    WHEN ((rates.currency2)::text = (regions.currencies_id)::text) THEN rates.currency2
                    ELSE rates.currency1
                END AS ccy2,
                CASE
                    WHEN ((rates.currency1)::text = (regions.currencies_id)::text) THEN ((1)::numeric / rates.closing_rate)
                    ELSE rates.closing_rate
                END AS closing_rate,
            rates.mkt_date
           FROM tbls_bls_closing_spot_rates rates,
            tbls_dates_master dm_1,
            tbls_regions regions
          WHERE (((regions.fin_id)::text = (dm_1.region_id)::text) AND (((rates.currency1)::text = (regions.currencies_id)::text) OR ((rates.currency2)::text = (regions.currencies_id)::text)) AND (rates.mkt_date = rates.forward_date))) fxsetlrates ON ((((bn.setl_cur_id)::text = (fxsetlrates.ccy1)::text) AND (fxsetlrates.mkt_date = d.entry_date)))),
    (tbls_bank_notes_deals_legs bn_legs
     LEFT JOIN ( SELECT
                CASE
                    WHEN ((rates.currency1)::text = (regions.currencies_id)::text) THEN rates.currency2
                    ELSE rates.currency1
                END AS ccy1,
                CASE
                    WHEN ((rates.currency2)::text = (regions.currencies_id)::text) THEN rates.currency2
                    ELSE rates.currency1
                END AS ccy2,
                CASE
                    WHEN ((rates.currency1)::text = (regions.currencies_id)::text) THEN ((1)::numeric / rates.closing_rate)
                    ELSE rates.closing_rate
                END AS closing_rate
           FROM tbls_bls_closing_spot_rates rates,
            tbls_dates_master dm_1,
            tbls_regions regions
          WHERE (((regions.fin_id)::text = (dm_1.region_id)::text) AND (((rates.currency1)::text = (regions.currencies_id)::text) OR ((rates.currency2)::text = (regions.currencies_id)::text)) AND (rates.forward_date = dm_1.reporting_date) AND (rates.mkt_date = dm_1.reporting_date))) fxlegrates ON (((bn_legs.currencies_id)::text = (fxlegrates.ccy1)::text))),
    tbls_repositories rp,
    tbls_customers cust,
    tbls_customer_types ct,
    tbls_products prd,
    tbls_ud_dt_mapping uddt,
    tbls_dates_master dm,
    ( SELECT
                CASE
                    WHEN ((p.deal_type_code)::text = 'COLC'::text) THEN d_1.deal_no
                    ELSE dv.link_deal_no
                END AS link_deal_no,
            bndl.currencies_id,
            sum(
                CASE
                    WHEN ((p.deal_type_code)::text = 'COLC'::text) THEN bndl.amount
                    ELSE (('-1'::integer)::numeric * bndl.amount)
                END) AS total
           FROM tbls_deals d_1,
            tbls_deal_versions dv,
            tbls_bank_notes_deals bnd,
            tbls_bank_notes_deals_legs bndl,
            tbls_products p
          WHERE (((d_1.deal_no)::text = (dv.deals_id)::text) AND (d_1.version_no = dv.version_no) AND ((dv.fin_id)::text = (bnd.fin_id)::text) AND ((bnd.fin_id)::text = (bndl.bank_notes_deals_id)::text) AND ((dv.products_id)::text = (p.fin_id)::text) AND ((p.deal_type_code)::text = ANY (ARRAY[('COLC'::character varying)::text, ('COLS'::character varying)::text, ('CRET'::character varying)::text])) AND ((d_1.action)::text <> 'CANCEL'::text))
          GROUP BY
                CASE
                    WHEN ((p.deal_type_code)::text = 'COLC'::text) THEN d_1.deal_no
                    ELSE dv.link_deal_no
                END, bndl.currencies_id
         HAVING (sum(
                CASE
                    WHEN ((p.deal_type_code)::text = 'COLC'::text) THEN bndl.amount
                    ELSE (('-1'::integer)::numeric * bndl.amount)
                END) <> (0)::numeric)) colc_check
  WHERE (((deals.fin_id)::text = (versions.deals_id)::text) AND (deals.version_no = versions.version_no) AND ((versions.fin_id)::text = (bn.fin_id)::text) AND ((bn.fin_id)::text = (bn_legs.bank_notes_deals_id)::text) AND ((deals.buy_sell)::text = (bn_legs.buy_sell)::text) AND ((deals.repositories_id)::text = (rp.fin_id)::text) AND ((deals.customers_id)::text = (cust.fin_id)::text) AND ((cust.type_id)::text = (ct.fin_id)::text) AND ((deals.products_id)::text = (prd.fin_id)::text) AND ((uddt.fin_id)::text = (deals.ud_deal_types_id)::text) AND ((deals.action)::text <> 'CANCEL'::text) AND (((colc_check.link_deal_no)::text = (deals.deal_no)::text) OR ((colc_check.link_deal_no)::text = (versions.link_deal_no)::text)) AND ((bn_legs.currencies_id)::text = (colc_check.currencies_id)::text) AND (((prd.deal_type_code)::text <> 'CAEX'::text) OR ((bn_legs.buy_sell)::text = (deals.buy_sell)::text)) AND ((deals.maker_checker_status)::text = 'COMMITTED'::text) AND ((deals.is_deleted)::text = 'N'::text) AND ((versions.maker_checker_status)::text = 'COMMITTED'::text) AND ((versions.is_deleted)::text = 'N'::text) AND ((bn.maker_checker_status)::text = 'COMMITTED'::text) AND ((bn.is_deleted)::text = 'N'::text) AND ((bn_legs.maker_checker_status)::text = 'COMMITTED'::text) AND ((bn_legs.is_deleted)::text = 'N'::text) AND ((rp.maker_checker_status)::text = 'COMMITTED'::text) AND ((rp.is_deleted)::text = 'N'::text) AND ((ct.maker_checker_status)::text = 'COMMITTED'::text) AND ((ct.is_deleted)::text = 'N'::text) AND ((cust.maker_checker_status)::text = 'COMMITTED'::text) AND ((cust.is_deleted)::text = 'N'::text) AND (to_char(versions.trade_date, 'YYYYMMDD'::text) <= to_char(dm.reporting_date, 'YYYYMMDD'::text)) AND ((deals.products_id)::text = ANY (ARRAY[('BKN_COLC'::character varying)::text, ('BKN_COLS'::character varying)::text, ('BKN_CRET'::character varying)::text])))
UNION
 SELECT ((((((deals.deal_no)::text || '_'::text) || deals.version_no) || '_'::text) || bn_legs.leg_number) || '_UNRU'::text) AS fin_id,
        CASE
            WHEN ((prd.deal_type_code)::text = 'UNRU'::text) THEN deals.deal_no
            ELSE versions.link_deal_no
        END AS deal_no,
    deals.version_no,
    bn_legs.leg_number AS leg_no,
    prd.code AS product_type,
    prd.deal_type_code AS deal_type,
        CASE
            WHEN ((bn_legs.currencies_id)::text = (bn.setl_cur_id)::text) THEN
            CASE
                WHEN ((bn_legs.currencies_id)::text = (( SELECT tbls_regions.currencies_id
                   FROM tbls_regions
                  WHERE ((tbls_regions.fin_id)::text = (( SELECT tbls_dates_master.region_id
                           FROM tbls_dates_master))::text)))::text) THEN 'LIKE_BASE'::text
                ELSE 'LIKE'::text
            END
            ELSE 'UNLIKE'::text
        END AS deal_sub_type,
    deals.buy_sell,
        CASE
            WHEN (deals.trade_date < deals.action_date) THEN deals.action_date
            ELSE deals.trade_date
        END AS trade_date,
        CASE
            WHEN (deals.value_date < deals.action_date) THEN deals.action_date
            ELSE deals.value_date
        END AS value_date,
        CASE
            WHEN (bn.release_date < deals.action_date) THEN deals.action_date
            ELSE bn.release_date
        END AS release_date,
        CASE
            WHEN (bn.vault_date < deals.action_date) THEN deals.action_date
            ELSE bn.vault_date
        END AS vault_date,
        CASE
            WHEN ((deals.products_id)::text = ANY (ARRAY[('BKN_CAEX'::character varying)::text, ('BKN_CONT'::character varying)::text])) THEN bn.vault2_date
            ELSE NULL::timestamp without time zone
        END AS vault2_date,
        CASE
            WHEN ((deals.products_id)::text = ANY (ARRAY[('BKN_CAEX'::character varying)::text, ('BKN_OFFS'::character varying)::text])) THEN bn.release2_date
            ELSE NULL::timestamp without time zone
        END AS release2_date,
    ( SELECT tbls_dates_master.system_date
           FROM tbls_dates_master) AS accounting_date,
    dm.system_date AS memo_rev_date,
        CASE
            WHEN ((deals.buy_sell)::text = 'B'::text) THEN bn_legs.currencies_id
            ELSE ''::character varying
        END AS buy_currency,
        CASE
            WHEN ((deals.buy_sell)::text = 'S'::text) THEN bn_legs.currencies_id
            ELSE ''::character varying
        END AS sell_currency,
        CASE
            WHEN ((deals.buy_sell)::text = 'B'::text) THEN
            CASE
                WHEN ((prd.deal_type_code)::text = 'UNRU'::text) THEN bn_legs.amount
                ELSE (('-1'::integer)::numeric * bn_legs.amount)
            END
            ELSE (0)::numeric
        END AS buy_amount,
        CASE
            WHEN ((deals.buy_sell)::text = 'S'::text) THEN
            CASE
                WHEN ((prd.deal_type_code)::text = 'UNRU'::text) THEN bn_legs.amount
                ELSE (('-1'::integer)::numeric * bn_legs.amount)
            END
            ELSE (0)::numeric
        END AS sell_amount,
    bn.setl_cur_id AS settlement_currency,
    bn_legs.setl_amount AS settlement_amount,
    COALESCE(fxsetlrates.closing_rate, (1)::numeric) AS settlementfxrate,
    COALESCE(fxlegrates.closing_rate, (1)::numeric) AS legfxrate,
    deals.repositories_id,
    rp.corp_code,
    rp.cost_center,
    cust.short_name AS customers_id,
    cust.country_incorporation_id AS customer_country,
    cust.is_resident,
    ct.type_code AS customer_type,
        CASE
            WHEN ((cust.is_resident)::text = 'Y'::text) THEN '0'::text
            ELSE '1'::text
        END AS ios_code,
    bn_legs.deal_rate,
    bn_legs.market_rate,
    bn.usd_rate_vs_setl_cur,
    bn.usd_rate_vs_base_cur,
    bn_legs.md,
    bn_legs.spotfactor,
    uddt.ud_deal_types_id,
    'UNRU'::character varying AS linked_deal_type,
    'UNRU'::character varying AS linked_ud_deal_types_id
   FROM tbls_deals deals,
    tbls_deal_versions versions,
    (((tbls_bank_notes_deals bn
     LEFT JOIN tbls_deal_versions ver ON (((ver.fin_id)::text = (bn.fin_id)::text)))
     LEFT JOIN tbls_deals d ON (((d.version_no = ver.version_no) AND ((d.fin_id)::text = (ver.deals_id)::text))))
     LEFT JOIN ( SELECT
                CASE
                    WHEN ((rates.currency1)::text = (regions.currencies_id)::text) THEN rates.currency2
                    ELSE rates.currency1
                END AS ccy1,
                CASE
                    WHEN ((rates.currency2)::text = (regions.currencies_id)::text) THEN rates.currency2
                    ELSE rates.currency1
                END AS ccy2,
                CASE
                    WHEN ((rates.currency1)::text = (regions.currencies_id)::text) THEN ((1)::numeric / rates.closing_rate)
                    ELSE rates.closing_rate
                END AS closing_rate,
            rates.mkt_date
           FROM tbls_bls_closing_spot_rates rates,
            tbls_dates_master dm_1,
            tbls_regions regions
          WHERE (((regions.fin_id)::text = (dm_1.region_id)::text) AND (((rates.currency1)::text = (regions.currencies_id)::text) OR ((rates.currency2)::text = (regions.currencies_id)::text)) AND (rates.mkt_date = rates.forward_date))) fxsetlrates ON ((((bn.setl_cur_id)::text = (fxsetlrates.ccy1)::text) AND (fxsetlrates.mkt_date = d.entry_date)))),
    (tbls_bank_notes_deals_legs bn_legs
     LEFT JOIN ( SELECT
                CASE
                    WHEN ((rates.currency1)::text = (regions.currencies_id)::text) THEN rates.currency2
                    ELSE rates.currency1
                END AS ccy1,
                CASE
                    WHEN ((rates.currency2)::text = (regions.currencies_id)::text) THEN rates.currency2
                    ELSE rates.currency1
                END AS ccy2,
                CASE
                    WHEN ((rates.currency1)::text = (regions.currencies_id)::text) THEN ((1)::numeric / rates.closing_rate)
                    ELSE rates.closing_rate
                END AS closing_rate
           FROM tbls_bls_closing_spot_rates rates,
            tbls_dates_master dm_1,
            tbls_regions regions
          WHERE (((regions.fin_id)::text = (dm_1.region_id)::text) AND (((rates.currency1)::text = (regions.currencies_id)::text) OR ((rates.currency2)::text = (regions.currencies_id)::text)) AND (rates.forward_date = dm_1.reporting_date) AND (rates.mkt_date = dm_1.reporting_date))) fxlegrates ON (((bn_legs.currencies_id)::text = (fxlegrates.ccy1)::text))),
    tbls_repositories rp,
    tbls_customers cust,
    tbls_customer_types ct,
    tbls_products prd,
    tbls_ud_dt_mapping uddt,
    tbls_dates_master dm,
    ( SELECT
                CASE
                    WHEN ((p.deal_type_code)::text = 'UNRU'::text) THEN d_1.deal_no
                    ELSE dv.link_deal_no
                END AS link_deal_no,
            bndl.currencies_id,
            sum(
                CASE
                    WHEN ((p.deal_type_code)::text = 'UNRU'::text) THEN bndl.amount
                    ELSE (('-1'::integer)::numeric * bndl.amount)
                END) AS total
           FROM tbls_deals d_1,
            tbls_deal_versions dv,
            tbls_bank_notes_deals bnd,
            tbls_bank_notes_deals_legs bndl,
            tbls_products p
          WHERE (((d_1.deal_no)::text = (dv.deals_id)::text) AND (d_1.version_no = dv.version_no) AND ((dv.fin_id)::text = (bnd.fin_id)::text) AND ((bnd.fin_id)::text = (bndl.bank_notes_deals_id)::text) AND ((dv.products_id)::text = (p.fin_id)::text) AND ((p.deal_type_code)::text = ANY (ARRAY[('UNRU'::character varying)::text, ('UNRR'::character varying)::text, ('URET'::character varying)::text])) AND ((d_1.action)::text <> 'CANCEL'::text))
          GROUP BY
                CASE
                    WHEN ((p.deal_type_code)::text = 'UNRU'::text) THEN d_1.deal_no
                    ELSE dv.link_deal_no
                END, bndl.currencies_id
         HAVING (sum(
                CASE
                    WHEN ((p.deal_type_code)::text = 'UNRU'::text) THEN bndl.amount
                    ELSE (('-1'::integer)::numeric * bndl.amount)
                END) <> (0)::numeric)) unru_check
  WHERE (((deals.fin_id)::text = (versions.deals_id)::text) AND (deals.version_no = versions.version_no) AND ((versions.fin_id)::text = (bn.fin_id)::text) AND ((bn.fin_id)::text = (bn_legs.bank_notes_deals_id)::text) AND ((deals.buy_sell)::text = (bn_legs.buy_sell)::text) AND ((deals.repositories_id)::text = (rp.fin_id)::text) AND ((deals.customers_id)::text = (cust.fin_id)::text) AND ((cust.type_id)::text = (ct.fin_id)::text) AND ((deals.products_id)::text = (prd.fin_id)::text) AND ((uddt.fin_id)::text = (deals.ud_deal_types_id)::text) AND ((deals.action)::text <> 'CANCEL'::text) AND (((unru_check.link_deal_no)::text = (deals.deal_no)::text) OR ((unru_check.link_deal_no)::text = (versions.link_deal_no)::text)) AND ((bn_legs.currencies_id)::text = (unru_check.currencies_id)::text) AND (((prd.deal_type_code)::text <> 'CAEX'::text) OR ((bn_legs.buy_sell)::text = (deals.buy_sell)::text)) AND ((deals.maker_checker_status)::text = 'COMMITTED'::text) AND ((deals.is_deleted)::text = 'N'::text) AND ((versions.maker_checker_status)::text = 'COMMITTED'::text) AND ((versions.is_deleted)::text = 'N'::text) AND ((bn.maker_checker_status)::text = 'COMMITTED'::text) AND ((bn.is_deleted)::text = 'N'::text) AND ((bn_legs.maker_checker_status)::text = 'COMMITTED'::text) AND ((bn_legs.is_deleted)::text = 'N'::text) AND ((rp.maker_checker_status)::text = 'COMMITTED'::text) AND ((rp.is_deleted)::text = 'N'::text) AND ((ct.maker_checker_status)::text = 'COMMITTED'::text) AND ((ct.is_deleted)::text = 'N'::text) AND ((cust.maker_checker_status)::text = 'COMMITTED'::text) AND ((cust.is_deleted)::text = 'N'::text) AND (to_char(versions.trade_date, 'YYYYMMDD'::text) <= to_char(dm.reporting_date, 'YYYYMMDD'::text)) AND ((deals.products_id)::text = ANY (ARRAY[('BKN_UNRU'::character varying)::text, ('BKN_UNRR'::character varying)::text, ('BKN_URET'::character varying)::text])))
UNION
 SELECT (((((((deals.deal_no)::text || '_'::text) || deals.version_no) || '_'::text) || 1) || '_'::text) || (prd.deal_type_code)::text) AS fin_id,
    deals.deal_no,
    deals.version_no,
    1 AS leg_no,
    prd.code AS product_type,
    prd.deal_type_code AS deal_type,
    'UNLIKE'::text AS deal_sub_type,
    fxdeal.buy_sell,
        CASE
            WHEN (deals.trade_date < deals.action_date) THEN deals.action_date
            ELSE deals.trade_date
        END AS trade_date,
        CASE
            WHEN (deals.value_date < deals.action_date) THEN deals.action_date
            ELSE deals.value_date
        END AS value_date,
    to_date(''::text, 'YYYYMMDD'::text) AS release_date,
    to_date(''::text, 'YYYYMMDD'::text) AS vault_date,
    to_date(''::text, 'YYYYMMDD'::text) AS vault2_date,
    to_date(''::text, 'YYYYMMDD'::text) AS release2_date,
    ( SELECT tbls_dates_master.system_date
           FROM tbls_dates_master) AS accounting_date,
        CASE
            WHEN (deals.value_date < deals.action_date) THEN deals.action_date
            ELSE deals.value_date
        END AS memo_rev_date,
    fxdeal.buy_currency_id AS buy_currency,
    fxdeal.sell_currency_id AS sell_currency,
    fxdeal.buy_amount,
    fxdeal.sell_amount,
    fxdeal.sell_currency_id AS settlement_currency,
    fxdeal.sell_amount AS settlement_amount,
    COALESCE(fxsetlrates.closing_rate, (1)::numeric) AS settlementfxrate,
    COALESCE(fxlegrates.closing_rate, (1)::numeric) AS legfxrate,
    deals.repositories_id,
    rp.corp_code,
    rp.cost_center,
    cust.short_name AS customers_id,
    cust.country_incorporation_id AS customer_country,
    cust.is_resident,
    ct.type_code AS customer_type,
        CASE
            WHEN ((cust.is_resident)::text = 'Y'::text) THEN '0'::text
            ELSE '1'::text
        END AS ios_code,
    fxdeal.deal_rate,
    fxdeal.spot_rate AS market_rate,
    fxdeal.usd_rate_vs_sell_cur AS usd_rate_vs_setl_cur,
    fxdeal.usd_rate_vs_base_cur,
    ''::bpchar AS md,
    1 AS spotfactor,
    uddt.ud_deal_types_id,
    prd.deal_type_code AS linked_deal_type,
    uddt.ud_deal_types_id AS linked_ud_deal_types_id
   FROM tbls_deals deals,
    tbls_deal_versions versions,
    (tbls_fx_deals fxdeal
     LEFT JOIN ( SELECT
                CASE
                    WHEN ((rates.currency1)::text = (regions.currencies_id)::text) THEN rates.currency2
                    ELSE rates.currency1
                END AS ccy1,
                CASE
                    WHEN ((rates.currency2)::text = (regions.currencies_id)::text) THEN rates.currency2
                    ELSE rates.currency1
                END AS ccy2,
                CASE
                    WHEN ((rates.currency1)::text = (regions.currencies_id)::text) THEN ((1)::numeric / rates.closing_rate)
                    ELSE rates.closing_rate
                END AS closing_rate
           FROM tbls_bls_closing_spot_rates rates,
            tbls_dates_master dm_1,
            tbls_regions regions
          WHERE (((regions.fin_id)::text = (dm_1.region_id)::text) AND (((rates.currency1)::text = (regions.currencies_id)::text) OR ((rates.currency2)::text = (regions.currencies_id)::text)) AND (rates.forward_date = dm_1.reporting_date) AND (rates.mkt_date = dm_1.reporting_date))) fxsetlrates ON (((fxdeal.sell_currency_id)::text = (fxsetlrates.ccy1)::text))),
    (tbls_fx_deals fxdeal1
     LEFT JOIN ( SELECT
                CASE
                    WHEN ((rates.currency1)::text = (regions.currencies_id)::text) THEN rates.currency2
                    ELSE rates.currency1
                END AS ccy1,
                CASE
                    WHEN ((rates.currency2)::text = (regions.currencies_id)::text) THEN rates.currency2
                    ELSE rates.currency1
                END AS ccy2,
                CASE
                    WHEN ((rates.currency1)::text = (regions.currencies_id)::text) THEN ((1)::numeric / rates.closing_rate)
                    ELSE rates.closing_rate
                END AS closing_rate
           FROM tbls_bls_closing_spot_rates rates,
            tbls_dates_master dm_1,
            tbls_regions regions
          WHERE (((regions.fin_id)::text = (dm_1.region_id)::text) AND (((rates.currency1)::text = (regions.currencies_id)::text) OR ((rates.currency2)::text = (regions.currencies_id)::text)) AND (rates.forward_date = dm_1.reporting_date) AND (rates.mkt_date = dm_1.reporting_date))) fxlegrates ON (((fxdeal1.buy_currency_id)::text = (fxlegrates.ccy1)::text))),
    tbls_repositories rp,
    tbls_customers cust,
    tbls_customer_types ct,
    tbls_products prd,
    tbls_ud_dt_mapping uddt,
    tbls_dates_master dm
  WHERE (((deals.fin_id)::text = (versions.deals_id)::text) AND (deals.version_no = versions.version_no) AND ((versions.fin_id)::text = (fxdeal1.deal_versions_id)::text) AND ((versions.fin_id)::text = (fxdeal.deal_versions_id)::text) AND ((deals.repositories_id)::text = (rp.fin_id)::text) AND ((deals.customers_id)::text = (cust.fin_id)::text) AND ((cust.type_id)::text = (ct.fin_id)::text) AND ((deals.products_id)::text = (prd.fin_id)::text) AND ((uddt.fin_id)::text = (deals.ud_deal_types_id)::text) AND ((deals.action)::text <> 'CANCEL'::text) AND (to_char(deals.action_date, 'YYYYMMDD'::text) <= ( SELECT to_char(tbls_dates_master.accounting_date, 'YYYYMMDD'::text) AS to_char
           FROM tbls_dates_master)) AND ((deals.maker_checker_status)::text = 'COMMITTED'::text) AND ((deals.is_deleted)::text = 'N'::text) AND ((versions.maker_checker_status)::text = 'COMMITTED'::text) AND ((versions.is_deleted)::text = 'N'::text) AND ((fxdeal1.maker_checker_status)::text = 'COMMITTED'::text) AND ((fxdeal1.is_deleted)::text = 'N'::text) AND ((fxdeal.maker_checker_status)::text = 'COMMITTED'::text) AND ((fxdeal.is_deleted)::text = 'N'::text) AND ((rp.maker_checker_status)::text = 'COMMITTED'::text) AND ((rp.is_deleted)::text = 'N'::text) AND ((ct.maker_checker_status)::text = 'COMMITTED'::text) AND ((ct.is_deleted)::text = 'N'::text) AND ((cust.maker_checker_status)::text = 'COMMITTED'::text) AND ((cust.is_deleted)::text = 'N'::text) AND (to_char(versions.maturity_date, 'YYYYMMDD'::text) >= to_char(dm.reporting_date, 'YYYYMMDD'::text)) AND (to_char(versions.trade_date, 'YYYYMMDD'::text) <= to_char(dm.reporting_date, 'YYYYMMDD'::text)) AND ((deals.products_id)::text IN ( SELECT tbls_products.fin_id
           FROM tbls_products
          WHERE ((tbls_products.code)::text = 'IFX'::text))));


--
--

CREATE VIEW vbls_irr_payrec_dl_entries AS
 SELECT (((((((deals.deal_no)::text || '_'::text) || deals.version_no) || '_'::text) || bn_legs.leg_number) || '_'::text) || (prd.deal_type_code)::text) AS fin_id,
    deals.deal_no,
    deals.version_no,
    bn_legs.leg_number AS leg_no,
    prd.code AS product_type,
    prd.deal_type_code AS deal_type,
        CASE
            WHEN ((bn_legs.currencies_id)::text = (bn.setl_cur_id)::text) THEN
            CASE
                WHEN ((bn_legs.currencies_id)::text = (( SELECT tbls_regions.currencies_id
                   FROM tbls_regions
                  WHERE ((tbls_regions.fin_id)::text = (( SELECT tbls_dates_master.region_id
                           FROM tbls_dates_master))::text)))::text) THEN 'LIKE_BASE'::text
                ELSE 'LIKE'::text
            END
            ELSE 'UNLIKE'::text
        END AS deal_sub_type,
    deals.buy_sell,
        CASE
            WHEN (deals.trade_date < deals.action_date) THEN deals.action_date
            ELSE deals.trade_date
        END AS trade_date,
        CASE
            WHEN (deals.value_date < deals.action_date) THEN deals.action_date
            ELSE deals.value_date
        END AS value_date,
        CASE
            WHEN (bn.release_date < deals.action_date) THEN deals.action_date
            ELSE bn.release_date
        END AS release_date,
        CASE
            WHEN (bn.vault_date < deals.action_date) THEN deals.action_date
            ELSE bn.vault_date
        END AS vault_date,
        CASE
            WHEN ((deals.products_id)::text = ANY (ARRAY[('BKN_CAEX'::character varying)::text, ('BKN_CONT'::character varying)::text, ('BKN_DISC'::character varying)::text])) THEN bn.vault2_date
            ELSE NULL::timestamp without time zone
        END AS vault2_date,
        CASE
            WHEN ((deals.products_id)::text = ANY (ARRAY[('BKN_CAEX'::character varying)::text, ('BKN_OFFS'::character varying)::text, ('BKN_DISC'::character varying)::text])) THEN bn.release2_date
            ELSE NULL::timestamp without time zone
        END AS release2_date,
    ( SELECT tbls_dates_master.system_date
           FROM tbls_dates_master) AS accounting_date,
        CASE
            WHEN (bn.release_date < deals.value_date) THEN
            CASE
                WHEN (bn.release_date < deals.action_date) THEN deals.action_date
                ELSE bn.release_date
            END
            ELSE
            CASE
                WHEN (deals.value_date < deals.action_date) THEN deals.action_date
                ELSE deals.value_date
            END
        END AS memo_rev_date,
        CASE
            WHEN ((deals.buy_sell)::text = 'B'::text) THEN bn_legs.currencies_id
            ELSE bn.setl_cur_id
        END AS buy_currency,
        CASE
            WHEN ((deals.buy_sell)::text = 'S'::text) THEN bn_legs.currencies_id
            ELSE bn.setl_cur_id
        END AS sell_currency,
        CASE
            WHEN ((deals.buy_sell)::text = 'B'::text) THEN bn_legs.amount
            ELSE bn_legs.setl_amount
        END AS buy_amount,
        CASE
            WHEN ((deals.buy_sell)::text = 'S'::text) THEN bn_legs.amount
            ELSE bn_legs.setl_amount
        END AS sell_amount,
    bn.setl_cur_id AS settlement_currency,
    bn_legs.setl_amount AS settlement_amount,
    COALESCE(fxsetlrates.closing_rate, (1)::numeric) AS settlementfxrate,
    COALESCE(fxlegrates.closing_rate, (1)::numeric) AS legfxrate,
    deals.repositories_id,
    rp.corp_code,
    rp.cost_center,
    cust.short_name AS customers_id,
    cust.country_incorporation_id AS customer_country,
    cust.is_resident,
    ct.type_code AS customer_type,
        CASE
            WHEN ((cust.is_resident)::text = 'Y'::text) THEN '0'::text
            ELSE '1'::text
        END AS ios_code,
    bn_legs.deal_rate,
    bn_legs.market_rate,
    bn.usd_rate_vs_setl_cur,
    bn.usd_rate_vs_base_cur,
    bn_legs.md,
    bn_legs.spotfactor,
    uddt.ud_deal_types_id,
    prd.deal_type_code AS linked_deal_type,
    uddt.ud_deal_types_id AS linked_ud_deal_types_id,
    bn.charge_amount,
    bn.commission_amount,
    bn.commission_cur_id AS commission_currency,
    bn.commission_setl_date,
    bn.commission_setl_type,
    deals.products_id
   FROM tbls_deals deals,
    tbls_deal_versions versions,
    (((tbls_bank_notes_deals bn
     LEFT JOIN tbls_deal_versions ver ON (((ver.fin_id)::text = (bn.fin_id)::text)))
     LEFT JOIN tbls_deals d ON (((d.version_no = ver.version_no) AND ((d.fin_id)::text = (ver.deals_id)::text))))
     LEFT JOIN ( SELECT
                CASE
                    WHEN ((rates.currency1)::text = (regions.currencies_id)::text) THEN rates.currency2
                    ELSE rates.currency1
                END AS ccy1,
                CASE
                    WHEN ((rates.currency2)::text = (regions.currencies_id)::text) THEN rates.currency2
                    ELSE rates.currency1
                END AS ccy2,
                CASE
                    WHEN ((rates.currency1)::text = (regions.currencies_id)::text) THEN ((1)::numeric / rates.closing_rate)
                    ELSE rates.closing_rate
                END AS closing_rate,
            rates.mkt_date
           FROM tbls_bls_closing_spot_rates rates,
            tbls_dates_master dm_1,
            tbls_regions regions
          WHERE (((regions.fin_id)::text = (dm_1.region_id)::text) AND (((rates.currency1)::text = (regions.currencies_id)::text) OR ((rates.currency2)::text = (regions.currencies_id)::text)) AND (rates.mkt_date = rates.forward_date))) fxsetlrates ON ((((bn.setl_cur_id)::text = (fxsetlrates.ccy1)::text) AND (fxsetlrates.mkt_date = d.entry_date)))),
    (tbls_bank_notes_deals_legs bn_legs
     LEFT JOIN ( SELECT
                CASE
                    WHEN ((rates.currency1)::text = (regions.currencies_id)::text) THEN rates.currency2
                    ELSE rates.currency1
                END AS ccy1,
                CASE
                    WHEN ((rates.currency2)::text = (regions.currencies_id)::text) THEN rates.currency2
                    ELSE rates.currency1
                END AS ccy2,
                CASE
                    WHEN ((rates.currency1)::text = (regions.currencies_id)::text) THEN ((1)::numeric / rates.closing_rate)
                    ELSE rates.closing_rate
                END AS closing_rate
           FROM tbls_bls_closing_spot_rates rates,
            tbls_dates_master dm_1,
            tbls_regions regions
          WHERE (((regions.fin_id)::text = (dm_1.region_id)::text) AND (((rates.currency1)::text = (regions.currencies_id)::text) OR ((rates.currency2)::text = (regions.currencies_id)::text)) AND (rates.forward_date = dm_1.reporting_date) AND (rates.mkt_date = dm_1.reporting_date))) fxlegrates ON (((bn_legs.currencies_id)::text = (fxlegrates.ccy1)::text))),
    tbls_repositories rp,
    tbls_customers cust,
    tbls_customer_types ct,
    tbls_products prd,
    tbls_ud_dt_mapping uddt,
    tbls_dates_master dm
  WHERE (((deals.fin_id)::text = (versions.deals_id)::text) AND (deals.version_no = versions.version_no) AND ((versions.fin_id)::text = (bn.fin_id)::text) AND ((bn.fin_id)::text = (bn_legs.bank_notes_deals_id)::text) AND ((deals.buy_sell)::text = (bn_legs.buy_sell)::text) AND ((deals.repositories_id)::text = (rp.fin_id)::text) AND ((deals.customers_id)::text = (cust.fin_id)::text) AND ((cust.type_id)::text = (ct.fin_id)::text) AND ((deals.products_id)::text = (prd.fin_id)::text) AND ((uddt.fin_id)::text = (deals.ud_deal_types_id)::text) AND ((deals.action)::text <> 'CANCEL'::text) AND (((prd.deal_type_code)::text <> 'CAEX'::text) OR ((bn_legs.buy_sell)::text = (deals.buy_sell)::text)) AND (to_char(deals.action_date, 'YYYYMMDD'::text) <= ( SELECT to_char(tbls_dates_master.accounting_date, 'YYYYMMDD'::text) AS to_char
           FROM tbls_dates_master)) AND ((deals.maker_checker_status)::text = 'COMMITTED'::text) AND ((deals.is_deleted)::text = 'N'::text) AND ((versions.maker_checker_status)::text = 'COMMITTED'::text) AND ((versions.is_deleted)::text = 'N'::text) AND ((bn.maker_checker_status)::text = 'COMMITTED'::text) AND ((bn.is_deleted)::text = 'N'::text) AND ((bn_legs.maker_checker_status)::text = 'COMMITTED'::text) AND ((bn_legs.is_deleted)::text = 'N'::text) AND ((rp.maker_checker_status)::text = 'COMMITTED'::text) AND ((rp.is_deleted)::text = 'N'::text) AND ((ct.maker_checker_status)::text = 'COMMITTED'::text) AND ((ct.is_deleted)::text = 'N'::text) AND ((cust.maker_checker_status)::text = 'COMMITTED'::text) AND ((cust.is_deleted)::text = 'N'::text) AND (to_char(versions.trade_date, 'YYYYMMDD'::text) <= to_char(dm.reporting_date, 'YYYYMMDD'::text)) AND ((deals.products_id)::text IN ( SELECT tbls_products.fin_id
           FROM tbls_products
          WHERE ((tbls_products.code)::text = ANY (ARRAY[('BKN'::character varying)::text, ('TCQ'::character varying)::text])))) AND (bn.setl_cur_id IS NOT NULL) AND (((d.status)::text <> 'DEAD'::text) OR (bn.commission_setl_date < dm.reporting_date)))
UNION
 SELECT ((((((deals.deal_no)::text || '_'::text) || deals.version_no) || '_'::text) || bn_legs.leg_number) || '_COLC'::text) AS fin_id,
        CASE
            WHEN ((prd.deal_type_code)::text = 'COLC'::text) THEN deals.deal_no
            ELSE versions.link_deal_no
        END AS deal_no,
    deals.version_no,
    bn_legs.leg_number AS leg_no,
    prd.code AS product_type,
    prd.deal_type_code AS deal_type,
        CASE
            WHEN ((bn_legs.currencies_id)::text = (bn.setl_cur_id)::text) THEN
            CASE
                WHEN ((bn_legs.currencies_id)::text = (( SELECT tbls_regions.currencies_id
                   FROM tbls_regions
                  WHERE ((tbls_regions.fin_id)::text = (( SELECT tbls_dates_master.region_id
                           FROM tbls_dates_master))::text)))::text) THEN 'LIKE_BASE'::text
                ELSE 'LIKE'::text
            END
            ELSE 'UNLIKE'::text
        END AS deal_sub_type,
    deals.buy_sell,
        CASE
            WHEN (deals.trade_date < deals.action_date) THEN deals.action_date
            ELSE deals.trade_date
        END AS trade_date,
        CASE
            WHEN (deals.value_date < deals.action_date) THEN deals.action_date
            ELSE deals.value_date
        END AS value_date,
        CASE
            WHEN (bn.release_date < deals.action_date) THEN deals.action_date
            ELSE bn.release_date
        END AS release_date,
        CASE
            WHEN (bn.vault_date < deals.action_date) THEN deals.action_date
            ELSE bn.vault_date
        END AS vault_date,
        CASE
            WHEN ((deals.products_id)::text = ANY (ARRAY[('BKN_CAEX'::character varying)::text, ('BKN_CONT'::character varying)::text, ('BKN_DISC'::character varying)::text])) THEN bn.vault2_date
            ELSE NULL::timestamp without time zone
        END AS vault2_date,
        CASE
            WHEN ((deals.products_id)::text = ANY (ARRAY[('BKN_CAEX'::character varying)::text, ('BKN_OFFS'::character varying)::text, ('BKN_DISC'::character varying)::text])) THEN bn.release2_date
            ELSE NULL::timestamp without time zone
        END AS release2_date,
    ( SELECT tbls_dates_master.system_date
           FROM tbls_dates_master) AS accounting_date,
    dm.system_date AS memo_rev_date,
        CASE
            WHEN ((deals.buy_sell)::text = 'B'::text) THEN bn_legs.currencies_id
            ELSE ''::character varying
        END AS buy_currency,
        CASE
            WHEN ((deals.buy_sell)::text = 'S'::text) THEN bn_legs.currencies_id
            ELSE ''::character varying
        END AS sell_currency,
        CASE
            WHEN ((deals.buy_sell)::text = 'B'::text) THEN
            CASE
                WHEN ((prd.deal_type_code)::text = 'COLC'::text) THEN bn_legs.amount
                ELSE (('-1'::integer)::numeric * bn_legs.amount)
            END
            ELSE (0)::numeric
        END AS buy_amount,
        CASE
            WHEN ((deals.buy_sell)::text = 'S'::text) THEN
            CASE
                WHEN ((prd.deal_type_code)::text = 'COLC'::text) THEN bn_legs.amount
                ELSE (('-1'::integer)::numeric * bn_legs.amount)
            END
            ELSE (0)::numeric
        END AS sell_amount,
    bn.setl_cur_id AS settlement_currency,
    bn_legs.setl_amount AS settlement_amount,
    COALESCE(fxsetlrates.closing_rate, (1)::numeric) AS settlementfxrate,
    COALESCE(fxlegrates.closing_rate, (1)::numeric) AS legfxrate,
    deals.repositories_id,
    rp.corp_code,
    rp.cost_center,
    cust.short_name AS customers_id,
    cust.country_incorporation_id AS customer_country,
    cust.is_resident,
    ct.type_code AS customer_type,
        CASE
            WHEN ((cust.is_resident)::text = 'Y'::text) THEN '0'::text
            ELSE '1'::text
        END AS ios_code,
    bn_legs.deal_rate,
    bn_legs.market_rate,
    bn.usd_rate_vs_setl_cur,
    bn.usd_rate_vs_base_cur,
    bn_legs.md,
    bn_legs.spotfactor,
    uddt.ud_deal_types_id,
    'COLC'::character varying AS linked_deal_type,
    'COLC'::character varying AS linked_ud_deal_types_id,
    bn.charge_amount,
    bn.commission_amount,
    bn.commission_cur_id AS commission_currency,
    bn.commission_setl_date,
    bn.commission_setl_type,
    deals.products_id
   FROM tbls_deals deals,
    tbls_deal_versions versions,
    (((tbls_bank_notes_deals bn
     LEFT JOIN tbls_deal_versions ver ON (((ver.fin_id)::text = (bn.fin_id)::text)))
     LEFT JOIN tbls_deals d ON (((d.version_no = ver.version_no) AND ((d.fin_id)::text = (ver.deals_id)::text))))
     LEFT JOIN ( SELECT
                CASE
                    WHEN ((rates.currency1)::text = (regions.currencies_id)::text) THEN rates.currency2
                    ELSE rates.currency1
                END AS ccy1,
                CASE
                    WHEN ((rates.currency2)::text = (regions.currencies_id)::text) THEN rates.currency2
                    ELSE rates.currency1
                END AS ccy2,
                CASE
                    WHEN ((rates.currency1)::text = (regions.currencies_id)::text) THEN ((1)::numeric / rates.closing_rate)
                    ELSE rates.closing_rate
                END AS closing_rate,
            rates.mkt_date
           FROM tbls_bls_closing_spot_rates rates,
            tbls_dates_master dm_1,
            tbls_regions regions
          WHERE (((regions.fin_id)::text = (dm_1.region_id)::text) AND (((rates.currency1)::text = (regions.currencies_id)::text) OR ((rates.currency2)::text = (regions.currencies_id)::text)) AND (rates.mkt_date = rates.forward_date))) fxsetlrates ON ((((bn.setl_cur_id)::text = (fxsetlrates.ccy1)::text) AND (fxsetlrates.mkt_date = d.entry_date)))),
    (tbls_bank_notes_deals_legs bn_legs
     LEFT JOIN ( SELECT
                CASE
                    WHEN ((rates.currency1)::text = (regions.currencies_id)::text) THEN rates.currency2
                    ELSE rates.currency1
                END AS ccy1,
                CASE
                    WHEN ((rates.currency2)::text = (regions.currencies_id)::text) THEN rates.currency2
                    ELSE rates.currency1
                END AS ccy2,
                CASE
                    WHEN ((rates.currency1)::text = (regions.currencies_id)::text) THEN ((1)::numeric / rates.closing_rate)
                    ELSE rates.closing_rate
                END AS closing_rate
           FROM tbls_bls_closing_spot_rates rates,
            tbls_dates_master dm_1,
            tbls_regions regions
          WHERE (((regions.fin_id)::text = (dm_1.region_id)::text) AND (((rates.currency1)::text = (regions.currencies_id)::text) OR ((rates.currency2)::text = (regions.currencies_id)::text)) AND (rates.forward_date = dm_1.reporting_date) AND (rates.mkt_date = dm_1.reporting_date))) fxlegrates ON (((bn_legs.currencies_id)::text = (fxlegrates.ccy1)::text))),
    tbls_repositories rp,
    tbls_customers cust,
    tbls_customer_types ct,
    tbls_products prd,
    tbls_ud_dt_mapping uddt,
    tbls_dates_master dm,
    ( SELECT
                CASE
                    WHEN ((p.deal_type_code)::text = 'COLC'::text) THEN d_1.deal_no
                    ELSE dv.link_deal_no
                END AS link_deal_no,
            bndl.currencies_id,
            sum(
                CASE
                    WHEN ((p.deal_type_code)::text = 'COLC'::text) THEN bndl.amount
                    ELSE (('-1'::integer)::numeric * bndl.amount)
                END) AS total
           FROM tbls_deals d_1,
            tbls_deal_versions dv,
            tbls_bank_notes_deals bnd,
            tbls_bank_notes_deals_legs bndl,
            tbls_products p
          WHERE (((d_1.deal_no)::text = (dv.deals_id)::text) AND (d_1.version_no = dv.version_no) AND ((dv.fin_id)::text = (bnd.fin_id)::text) AND ((bnd.fin_id)::text = (bndl.bank_notes_deals_id)::text) AND ((dv.products_id)::text = (p.fin_id)::text) AND ((p.deal_type_code)::text = ANY (ARRAY[('COLC'::character varying)::text, ('COLS'::character varying)::text, ('CRET'::character varying)::text])) AND ((d_1.action)::text <> 'CANCEL'::text))
          GROUP BY
                CASE
                    WHEN ((p.deal_type_code)::text = 'COLC'::text) THEN d_1.deal_no
                    ELSE dv.link_deal_no
                END, bndl.currencies_id
         HAVING (sum(
                CASE
                    WHEN ((p.deal_type_code)::text = 'COLC'::text) THEN bndl.amount
                    ELSE (('-1'::integer)::numeric * bndl.amount)
                END) <> (0)::numeric)) colc_check
  WHERE (((deals.fin_id)::text = (versions.deals_id)::text) AND (deals.version_no = versions.version_no) AND ((versions.fin_id)::text = (bn.fin_id)::text) AND ((bn.fin_id)::text = (bn_legs.bank_notes_deals_id)::text) AND ((deals.buy_sell)::text = (bn_legs.buy_sell)::text) AND ((deals.repositories_id)::text = (rp.fin_id)::text) AND ((deals.customers_id)::text = (cust.fin_id)::text) AND ((cust.type_id)::text = (ct.fin_id)::text) AND ((deals.products_id)::text = (prd.fin_id)::text) AND ((uddt.fin_id)::text = (deals.ud_deal_types_id)::text) AND ((deals.action)::text <> 'CANCEL'::text) AND (((colc_check.link_deal_no)::text = (deals.deal_no)::text) OR ((colc_check.link_deal_no)::text = (versions.link_deal_no)::text)) AND ((bn_legs.currencies_id)::text = (colc_check.currencies_id)::text) AND (((prd.deal_type_code)::text <> 'CAEX'::text) OR ((bn_legs.buy_sell)::text = (deals.buy_sell)::text)) AND ((deals.maker_checker_status)::text = 'COMMITTED'::text) AND ((deals.is_deleted)::text = 'N'::text) AND ((versions.maker_checker_status)::text = 'COMMITTED'::text) AND ((versions.is_deleted)::text = 'N'::text) AND ((bn.maker_checker_status)::text = 'COMMITTED'::text) AND ((bn.is_deleted)::text = 'N'::text) AND ((bn_legs.maker_checker_status)::text = 'COMMITTED'::text) AND ((bn_legs.is_deleted)::text = 'N'::text) AND ((rp.maker_checker_status)::text = 'COMMITTED'::text) AND ((rp.is_deleted)::text = 'N'::text) AND ((ct.maker_checker_status)::text = 'COMMITTED'::text) AND ((ct.is_deleted)::text = 'N'::text) AND ((cust.maker_checker_status)::text = 'COMMITTED'::text) AND ((cust.is_deleted)::text = 'N'::text) AND (to_char(versions.trade_date, 'YYYYMMDD'::text) <= to_char(dm.reporting_date, 'YYYYMMDD'::text)) AND ((deals.products_id)::text = ANY (ARRAY[('BKN_COLC'::character varying)::text, ('BKN_COLS'::character varying)::text, ('BKN_CRET'::character varying)::text])) AND (((d.status)::text <> 'DEAD'::text) OR (bn.commission_setl_date < dm.reporting_date)))
UNION
 SELECT ((((((deals.deal_no)::text || '_'::text) || deals.version_no) || '_'::text) || bn_legs.leg_number) || '_UNRU'::text) AS fin_id,
        CASE
            WHEN ((prd.deal_type_code)::text = 'UNRU'::text) THEN deals.deal_no
            ELSE versions.link_deal_no
        END AS deal_no,
    deals.version_no,
    bn_legs.leg_number AS leg_no,
    prd.code AS product_type,
    prd.deal_type_code AS deal_type,
        CASE
            WHEN ((bn_legs.currencies_id)::text = (bn.setl_cur_id)::text) THEN
            CASE
                WHEN ((bn_legs.currencies_id)::text = (( SELECT tbls_regions.currencies_id
                   FROM tbls_regions
                  WHERE ((tbls_regions.fin_id)::text = (( SELECT tbls_dates_master.region_id
                           FROM tbls_dates_master))::text)))::text) THEN 'LIKE_BASE'::text
                ELSE 'LIKE'::text
            END
            ELSE 'UNLIKE'::text
        END AS deal_sub_type,
    deals.buy_sell,
        CASE
            WHEN (deals.trade_date < deals.action_date) THEN deals.action_date
            ELSE deals.trade_date
        END AS trade_date,
        CASE
            WHEN (deals.value_date < deals.action_date) THEN deals.action_date
            ELSE deals.value_date
        END AS value_date,
        CASE
            WHEN (bn.release_date < deals.action_date) THEN deals.action_date
            ELSE bn.release_date
        END AS release_date,
        CASE
            WHEN (bn.vault_date < deals.action_date) THEN deals.action_date
            ELSE bn.vault_date
        END AS vault_date,
        CASE
            WHEN ((deals.products_id)::text = ANY (ARRAY[('BKN_CAEX'::character varying)::text, ('BKN_CONT'::character varying)::text, ('BKN_DISC'::character varying)::text])) THEN bn.vault2_date
            ELSE NULL::timestamp without time zone
        END AS vault2_date,
        CASE
            WHEN ((deals.products_id)::text = ANY (ARRAY[('BKN_CAEX'::character varying)::text, ('BKN_OFFS'::character varying)::text, ('BKN_DISC'::character varying)::text])) THEN bn.release2_date
            ELSE NULL::timestamp without time zone
        END AS release2_date,
    ( SELECT tbls_dates_master.system_date
           FROM tbls_dates_master) AS accounting_date,
    dm.system_date AS memo_rev_date,
        CASE
            WHEN ((deals.buy_sell)::text = 'B'::text) THEN bn_legs.currencies_id
            ELSE ''::character varying
        END AS buy_currency,
        CASE
            WHEN ((deals.buy_sell)::text = 'S'::text) THEN bn_legs.currencies_id
            ELSE ''::character varying
        END AS sell_currency,
        CASE
            WHEN ((deals.buy_sell)::text = 'B'::text) THEN
            CASE
                WHEN ((prd.deal_type_code)::text = 'UNRU'::text) THEN bn_legs.amount
                ELSE (('-1'::integer)::numeric * bn_legs.amount)
            END
            ELSE (0)::numeric
        END AS buy_amount,
        CASE
            WHEN ((deals.buy_sell)::text = 'S'::text) THEN
            CASE
                WHEN ((prd.deal_type_code)::text = 'UNRU'::text) THEN bn_legs.amount
                ELSE (('-1'::integer)::numeric * bn_legs.amount)
            END
            ELSE (0)::numeric
        END AS sell_amount,
    bn.setl_cur_id AS settlement_currency,
    bn_legs.setl_amount AS settlement_amount,
    COALESCE(fxsetlrates.closing_rate, (1)::numeric) AS settlementfxrate,
    COALESCE(fxlegrates.closing_rate, (1)::numeric) AS legfxrate,
    deals.repositories_id,
    rp.corp_code,
    rp.cost_center,
    cust.short_name AS customers_id,
    cust.country_incorporation_id AS customer_country,
    cust.is_resident,
    ct.type_code AS customer_type,
        CASE
            WHEN ((cust.is_resident)::text = 'Y'::text) THEN '0'::text
            ELSE '1'::text
        END AS ios_code,
    bn_legs.deal_rate,
    bn_legs.market_rate,
    bn.usd_rate_vs_setl_cur,
    bn.usd_rate_vs_base_cur,
    bn_legs.md,
    bn_legs.spotfactor,
    uddt.ud_deal_types_id,
    'UNRU'::character varying AS linked_deal_type,
    'UNRU'::character varying AS linked_ud_deal_types_id,
    bn.charge_amount,
    bn.commission_amount,
    bn.commission_cur_id AS commission_currency,
    bn.commission_setl_date,
    bn.commission_setl_type,
    deals.products_id
   FROM tbls_deals deals,
    tbls_deal_versions versions,
    (((tbls_bank_notes_deals bn
     LEFT JOIN tbls_deal_versions ver ON (((ver.fin_id)::text = (bn.fin_id)::text)))
     LEFT JOIN tbls_deals d ON (((d.version_no = ver.version_no) AND ((d.fin_id)::text = (ver.deals_id)::text))))
     LEFT JOIN ( SELECT
                CASE
                    WHEN ((rates.currency1)::text = (regions.currencies_id)::text) THEN rates.currency2
                    ELSE rates.currency1
                END AS ccy1,
                CASE
                    WHEN ((rates.currency2)::text = (regions.currencies_id)::text) THEN rates.currency2
                    ELSE rates.currency1
                END AS ccy2,
                CASE
                    WHEN ((rates.currency1)::text = (regions.currencies_id)::text) THEN ((1)::numeric / rates.closing_rate)
                    ELSE rates.closing_rate
                END AS closing_rate,
            rates.mkt_date
           FROM tbls_bls_closing_spot_rates rates,
            tbls_dates_master dm_1,
            tbls_regions regions
          WHERE (((regions.fin_id)::text = (dm_1.region_id)::text) AND (((rates.currency1)::text = (regions.currencies_id)::text) OR ((rates.currency2)::text = (regions.currencies_id)::text)) AND (rates.mkt_date = rates.forward_date))) fxsetlrates ON ((((bn.setl_cur_id)::text = (fxsetlrates.ccy1)::text) AND (fxsetlrates.mkt_date = d.entry_date)))),
    (tbls_bank_notes_deals_legs bn_legs
     LEFT JOIN ( SELECT
                CASE
                    WHEN ((rates.currency1)::text = (regions.currencies_id)::text) THEN rates.currency2
                    ELSE rates.currency1
                END AS ccy1,
                CASE
                    WHEN ((rates.currency2)::text = (regions.currencies_id)::text) THEN rates.currency2
                    ELSE rates.currency1
                END AS ccy2,
                CASE
                    WHEN ((rates.currency1)::text = (regions.currencies_id)::text) THEN ((1)::numeric / rates.closing_rate)
                    ELSE rates.closing_rate
                END AS closing_rate
           FROM tbls_bls_closing_spot_rates rates,
            tbls_dates_master dm_1,
            tbls_regions regions
          WHERE (((regions.fin_id)::text = (dm_1.region_id)::text) AND (((rates.currency1)::text = (regions.currencies_id)::text) OR ((rates.currency2)::text = (regions.currencies_id)::text)) AND (rates.forward_date = dm_1.reporting_date) AND (rates.mkt_date = dm_1.reporting_date))) fxlegrates ON (((bn_legs.currencies_id)::text = (fxlegrates.ccy1)::text))),
    tbls_repositories rp,
    tbls_customers cust,
    tbls_customer_types ct,
    tbls_products prd,
    tbls_ud_dt_mapping uddt,
    tbls_dates_master dm,
    ( SELECT
                CASE
                    WHEN ((p.deal_type_code)::text = 'UNRU'::text) THEN d_1.deal_no
                    ELSE dv.link_deal_no
                END AS link_deal_no,
            bndl.currencies_id,
            sum(
                CASE
                    WHEN ((p.deal_type_code)::text = 'UNRU'::text) THEN bndl.amount
                    ELSE (('-1'::integer)::numeric * bndl.amount)
                END) AS total
           FROM tbls_deals d_1,
            tbls_deal_versions dv,
            tbls_bank_notes_deals bnd,
            tbls_bank_notes_deals_legs bndl,
            tbls_products p
          WHERE (((d_1.deal_no)::text = (dv.deals_id)::text) AND (d_1.version_no = dv.version_no) AND ((dv.fin_id)::text = (bnd.fin_id)::text) AND ((bnd.fin_id)::text = (bndl.bank_notes_deals_id)::text) AND ((dv.products_id)::text = (p.fin_id)::text) AND ((p.deal_type_code)::text = ANY (ARRAY[('UNRU'::character varying)::text, ('UNRR'::character varying)::text, ('URET'::character varying)::text])) AND ((d_1.action)::text <> 'CANCEL'::text))
          GROUP BY
                CASE
                    WHEN ((p.deal_type_code)::text = 'UNRU'::text) THEN d_1.deal_no
                    ELSE dv.link_deal_no
                END, bndl.currencies_id
         HAVING (sum(
                CASE
                    WHEN ((p.deal_type_code)::text = 'UNRU'::text) THEN bndl.amount
                    ELSE (('-1'::integer)::numeric * bndl.amount)
                END) <> (0)::numeric)) unru_check
  WHERE (((deals.fin_id)::text = (versions.deals_id)::text) AND (deals.version_no = versions.version_no) AND ((versions.fin_id)::text = (bn.fin_id)::text) AND ((bn.fin_id)::text = (bn_legs.bank_notes_deals_id)::text) AND ((deals.buy_sell)::text = (bn_legs.buy_sell)::text) AND ((deals.repositories_id)::text = (rp.fin_id)::text) AND ((deals.customers_id)::text = (cust.fin_id)::text) AND ((cust.type_id)::text = (ct.fin_id)::text) AND ((deals.products_id)::text = (prd.fin_id)::text) AND ((uddt.fin_id)::text = (deals.ud_deal_types_id)::text) AND ((deals.action)::text <> 'CANCEL'::text) AND (((unru_check.link_deal_no)::text = (deals.deal_no)::text) OR ((unru_check.link_deal_no)::text = (versions.link_deal_no)::text)) AND ((bn_legs.currencies_id)::text = (unru_check.currencies_id)::text) AND (((prd.deal_type_code)::text <> 'CAEX'::text) OR ((bn_legs.buy_sell)::text = (deals.buy_sell)::text)) AND ((deals.maker_checker_status)::text = 'COMMITTED'::text) AND ((deals.is_deleted)::text = 'N'::text) AND ((versions.maker_checker_status)::text = 'COMMITTED'::text) AND ((versions.is_deleted)::text = 'N'::text) AND ((bn.maker_checker_status)::text = 'COMMITTED'::text) AND ((bn.is_deleted)::text = 'N'::text) AND ((bn_legs.maker_checker_status)::text = 'COMMITTED'::text) AND ((bn_legs.is_deleted)::text = 'N'::text) AND ((rp.maker_checker_status)::text = 'COMMITTED'::text) AND ((rp.is_deleted)::text = 'N'::text) AND ((ct.maker_checker_status)::text = 'COMMITTED'::text) AND ((ct.is_deleted)::text = 'N'::text) AND ((cust.maker_checker_status)::text = 'COMMITTED'::text) AND ((cust.is_deleted)::text = 'N'::text) AND (to_char(versions.trade_date, 'YYYYMMDD'::text) <= to_char(dm.reporting_date, 'YYYYMMDD'::text)) AND ((deals.products_id)::text = ANY (ARRAY[('BKN_UNRU'::character varying)::text, ('BKN_UNRR'::character varying)::text, ('BKN_URET'::character varying)::text])) AND (((d.status)::text <> 'DEAD'::text) OR (bn.commission_setl_date < dm.reporting_date)));


--
--

CREATE VIEW vbls_msg_search_view AS
 SELECT (((((banknotesdeals.fin_id)::text || COALESCE(settlements.version_no, ((0)::bigint)::double precision)) || (COALESCE(messageshistory.module_name, ' '::character varying))::text) || (COALESCE(messageshistory.msg_source, ' '::character varying))::text) || COALESCE(messageshistory.page_no, ((1)::bigint)::double precision)) AS fin_id,
    COALESCE(banknotesdeals.fully_funded, ' '::bpchar) AS fully_funded,
    banknotesdeals.vault_date,
    banknotesdeals.release_date,
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
    COALESCE(settlements.version_no, ((0)::bigint)::double precision) AS setl_version_no,
    COALESCE(settlements.setl_amount, (0)::numeric) AS setl_amt,
    COALESCE(settlements.setl_origin, ' '::character varying) AS setl_origin,
    COALESCE(to_char(settlements.setl_date, 'DD/MM/YYYY'::text), ' '::text) AS setl_date,
    COALESCE(to_char(settlements.setl_release_date, 'DD/MM/YYYY'::text), ' '::text) AS setl_release_date,
        CASE
            WHEN (((COALESCE(settlements.is_deleted, 'N'::character varying))::text = 'Y'::text) AND ((COALESCE(workflowstatessetl.name, ' '::character varying))::text = 'NETTEDC'::text)) THEN 'N'::character varying
            ELSE COALESCE(settlements.is_deleted, 'N'::character varying)
        END AS setl_deleted,
    workflowstatesdeals.name AS deal_status,
    COALESCE(dealstatus.operations_userid, ' '::character varying) AS deal_status_validator,
    workflowstatesdeals.workflow_level AS deal_status_level,
    workflowstatesshipment.name AS shipment_status,
    workflowstatesvault.name AS vault_status,
    COALESCE(workflowstatessetl.name, ' '::character varying) AS setl_status,
    COALESCE(workflowstatessetl.workflow_level, (('-1'::integer)::bigint)::double precision) AS setl_status_level,
    COALESCE(dealstatus.fo_remarks, ' '::character varying) AS fo_remarks,
    COALESCE(dealstatus.bo_remarks, ' '::character varying) AS setl_remarks,
    COALESCE(messageshistory.module_entity_id, ' '::character varying) AS module_entity_id,
    COALESCE(messageshistory.module_name, ' '::character varying) AS module_name,
    COALESCE(messageshistory.msg_source, ' '::character varying) AS msg_source,
    COALESCE(messageshistory.isn_no, ' '::character varying) AS isn_no,
    COALESCE(messageshistory.session_no, ' '::character varying) AS session_no,
    COALESCE(workflowmsgstatus.name, ' '::character varying) AS msg_status,
    COALESCE(msgtemplates.msg_name, ' '::character varying) AS msg_name,
    COALESCE(msgtemplates.msg_code, ' '::character varying) AS msg_code,
    COALESCE(msgtemplates.swift_type, ' '::character varying) AS swift_type,
    COALESCE(to_char(messageshistory.generated_date, 'DD/MM/YYYY'::text), ' '::text) AS generated_date,
    COALESCE(messageshistory.reason_flag, ' '::character varying) AS reason_flag,
    COALESCE(messageshistory.reason_code, ' '::character varying) AS reason_code,
    COALESCE(messageshistory.reason_text, ' '::character varying) AS reason_text,
    COALESCE(messageshistory.ack_flag, ' '::character varying) AS ack_flag,
    COALESCE(messageshistory.ack_text, ' '::character varying) AS ack_text,
    COALESCE(messageshistory.page_no, ((1)::bigint)::double precision) AS page_no
   FROM (tbls_bank_notes_deals banknotesdeals
     LEFT JOIN tbls_sdis sdis ON (((banknotesdeals.sdi_id)::text = (sdis.fin_id)::text))),
    (((tbls_deal_versions dealversions
     LEFT JOIN tbls_deal_ssi dealssi ON (((dealversions.fin_id)::text = (dealssi.deal_versions_id)::text)))
     LEFT JOIN tbls_settlements settlements ON ((((dealversions.fin_id)::text = (settlements.deal_versions_id)::text) AND ((settlements.is_deleted)::text = 'N'::text))))
     LEFT JOIN tbls_workflow_states workflowstatessetl ON (((workflowstatessetl.fin_id)::text = (settlements.status_id)::text))),
    tbls_deals deals,
    tbls_products products,
    tbls_ud_deal_types uddealtypes,
    tbls_ud_dt_mapping uddtmapping,
    tbls_customers customers,
    tbls_branches branches,
    tbls_messages_history messageshistory,
    tbls_msg_templates msgtemplates,
    tbls_deals_status dealstatus,
    tbls_workflow_states workflowstatesdeals,
    tbls_workflow_states workflowstatesshipment,
    tbls_workflow_states workflowstatesvault,
    tbls_workflow_states workflowmsgstatus,
    tbls_dates_master datesmaster
  WHERE (((banknotesdeals.fin_id)::text = (dealversions.fin_id)::text) AND ((dealversions.deals_id)::text = (deals.fin_id)::text) AND ((dealversions.customers_id)::text = (customers.fin_id)::text) AND ((dealversions.branches_id)::text = (branches.fin_id)::text) AND ((dealversions.products_id)::text = (products.fin_id)::text) AND ((dealstatus.fin_id)::text = (deals.deal_no)::text) AND ((dealstatus.deal_status_id)::text = (workflowstatesdeals.fin_id)::text) AND ((uddealtypes.code)::text = (uddtmapping.ud_deal_types_id)::text) AND ((uddtmapping.fin_id)::text = (deals.ud_deal_types_id)::text) AND ((workflowstatesshipment.fin_id)::text = (dealstatus.shipping_status_id)::text) AND ((workflowstatesvault.fin_id)::text = (dealstatus.vault_status_id)::text) AND ((((messageshistory.module_entity_id)::text = (dealversions.deals_id)::text) AND ((messageshistory.module_name)::text = 'DEALS'::text) AND (messageshistory.version_no = dealversions.version_no) AND ((messageshistory.msg_status_id)::text = (workflowmsgstatus.fin_id)::text) AND ((msgtemplates.fin_id)::text = (messageshistory.msg_templates_id)::text)) OR (((messageshistory.module_entity_id)::text = (settlements.fin_id)::text) AND ((messageshistory.module_name)::text = 'SETTLEMENTS'::text) AND ((settlements.deal_versions_id)::text = (dealversions.fin_id)::text) AND ((messageshistory.msg_status_id)::text = (workflowmsgstatus.fin_id)::text) AND ((msgtemplates.fin_id)::text = (messageshistory.msg_templates_id)::text) AND (settlements.setl_date >= (datesmaster.system_date - '15 days'::interval)))) AND (to_char(deals.trade_date, 'YYYYMMDD'::text) >= to_char((datesmaster.system_date - '15 days'::interval), 'YYYYMMDD'::text)) AND (dealversions.trade_date >= (datesmaster.system_date - '15 days'::interval)));


--
--

CREATE VIEW vbls_mtm_entries AS
 SELECT eodpl.fin_id,
    (((eodpl.deal_no)::text || '_'::text) || eodpl.leg_no) AS trans_ref,
    ''::text AS external_no,
    eodpl.deal_no,
    (eodpl.leg_no)::character varying AS leg_no,
    deals.version_no,
    'MTM'::text AS rule_type,
    'MTM_TODAY'::text AS deal_flag,
        CASE
            WHEN ((deals.maturity_date >= deals.action_date) AND (deals.maturity_date <= datesmaster.accounting_date)) THEN 'REALISED'::text
            WHEN ((deals.maturity_date <= deals.action_date) AND (deals.action_date <= datesmaster.accounting_date)) THEN 'REALISED'::text
            WHEN ((deals.maturity_date >= deals.action_date) AND (deals.maturity_date > datesmaster.accounting_date)) THEN 'UNREALISED'::text
            WHEN ((deals.maturity_date <= deals.action_date) AND (deals.action_date > datesmaster.accounting_date)) THEN 'UNREALISED'::text
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
            WHEN ((legs.currencies_id)::text = (bndeals.setl_cur_id)::text) THEN
            CASE
                WHEN ((legs.currencies_id)::text = (regions.currencies_id)::text) THEN 'LIKE_BASE'::text
                ELSE 'LIKE'::text
            END
            ELSE 'UNLIKE'::text
        END AS deal_sub_type,
        CASE
            WHEN (((eodpl.unrealized_pl * eodpl.discount_factor_base_ccy) + eodpl.realised_pl_today) > (0)::numeric) THEN 'MTM_POSITIVE'::text
            ELSE 'MTM_NEGATIVE'::text
        END AS ctc_mtm_sign_today,
        CASE
            WHEN (((eodpl.unrealized_pl * eodpl.discount_factor_base_ccy) + eodpl.realised_pl_today) > (0)::numeric) THEN abs(((eodpl.unrealized_pl * eodpl.discount_factor_base_ccy) + eodpl.realised_pl_today))
            ELSE (0)::numeric
        END AS mtm_gain,
        CASE
            WHEN (((eodpl.unrealized_pl * eodpl.discount_factor_base_ccy) + eodpl.realised_pl_today) <= (0)::numeric) THEN abs(((eodpl.unrealized_pl * eodpl.discount_factor_base_ccy) + eodpl.realised_pl_today))
            ELSE (0)::numeric
        END AS mtm_loss,
    eodpl.repository_id AS repository,
    repositories.corp_code,
    repositories.cost_center,
        CASE
            WHEN (deals.trade_date < deals.action_date) THEN deals.action_date
            ELSE deals.trade_date
        END AS trade_date,
        CASE
            WHEN (deals.value_date < deals.action_date) THEN deals.action_date
            ELSE deals.value_date
        END AS value_date,
        CASE
            WHEN (deals.maturity_date < deals.action_date) THEN deals.action_date
            ELSE deals.maturity_date
        END AS memo_rev_date,
    datesmaster.accounting_date,
    cust.is_resident
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
  WHERE (((uddeals.fin_id)::text = (eodpl.ud_deal_type_id)::text) AND ((uddeals.ud_deal_types_id)::text = (uddealtypes.fin_id)::text) AND ((eodpl.product_id)::text = (products.fin_id)::text) AND ((deals.deal_no)::text = (eodpl.deal_no)::text) AND ((deals.repositories_id)::text = (repositories.fin_id)::text) AND ((versions.fin_id)::text = (bndeals.fin_id)::text) AND ((legs.bank_notes_deals_id)::text = (bndeals.fin_id)::text) AND (legs.leg_number = eodpl.leg_no) AND (deals.version_no = eodpl.version_no) AND ((deals.fin_id)::text = (versions.deals_id)::text) AND (deals.version_no = versions.version_no) AND ((deals.customers_id)::text = (cust.fin_id)::text) AND ((cust.type_id)::text = (ct.fin_id)::text) AND ((deals.action)::text <> 'CANCEL'::text) AND (to_char(deals.action_date, 'YYYYMMDD'::text) <= ( SELECT to_char(tbls_dates_master.accounting_date, 'YYYYMMDD'::text) AS to_char
           FROM tbls_dates_master)) AND (to_char(eodpl.pl_date, 'YYYYMMDD'::text) = to_char(datesmaster.accounting_date, 'YYYYMMDD'::text)) AND (to_char(eodpl.deal_value_date, 'YYYYMMDD'::text) >= to_char(datesmaster.accounting_date, 'YYYYMMDD'::text)) AND ((regions.fin_id)::text = (datesmaster.region_id)::text))
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
            WHEN ((deals.value_date >= deals.trade_date) AND (deals.value_date <= datesmaster.accounting_date)) THEN 'REALISED'::text
            WHEN ((deals.value_date <= deals.trade_date) AND (deals.trade_date <= datesmaster.accounting_date)) THEN 'REALISED'::text
            WHEN ((deals.value_date >= deals.trade_date) AND (deals.value_date > datesmaster.accounting_date)) THEN 'UNREALISED'::text
            WHEN ((deals.value_date <= deals.trade_date) AND (deals.trade_date > datesmaster.accounting_date)) THEN 'UNREALISED'::text
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
            WHEN ((fxdeals.buy_currency_id)::text = (fxdeals.sell_currency_id)::text) THEN
            CASE
                WHEN ((fxdeals.buy_currency_id)::text = (regions.currencies_id)::text) THEN 'LIKE_BASE'::text
                ELSE 'LIKE'::text
            END
            ELSE 'UNLIKE'::text
        END AS deal_sub_type,
        CASE
            WHEN (((eodpl.unrealized_pl * eodpl.discount_factor_base_ccy) + eodpl.realised_pl_today) > (0)::numeric) THEN 'MTM_POSITIVE'::text
            ELSE 'MTM_NEGATIVE'::text
        END AS ctc_mtm_sign_today,
        CASE
            WHEN (((eodpl.unrealized_pl * eodpl.discount_factor_base_ccy) + eodpl.realised_pl_today) > (0)::numeric) THEN abs(((eodpl.unrealized_pl * eodpl.discount_factor_base_ccy) + eodpl.realised_pl_today))
            ELSE (0)::numeric
        END AS mtm_gain,
        CASE
            WHEN (((eodpl.unrealized_pl * eodpl.discount_factor_base_ccy) + eodpl.realised_pl_today) <= (0)::numeric) THEN abs(((eodpl.unrealized_pl * eodpl.discount_factor_base_ccy) + eodpl.realised_pl_today))
            ELSE (0)::numeric
        END AS mtm_loss,
    eodpl.repository_id AS repository,
    repositories.corp_code,
    repositories.cost_center,
    deals.trade_date,
        CASE
            WHEN (deals.value_date < deals.trade_date) THEN deals.trade_date
            ELSE deals.value_date
        END AS value_date,
        CASE
            WHEN (deals.value_date < deals.trade_date) THEN deals.trade_date
            ELSE deals.value_date
        END AS memo_rev_date,
    datesmaster.accounting_date,
    cust.is_resident
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
  WHERE (((uddeals.fin_id)::text = (eodpl.ud_deal_type_id)::text) AND ((uddeals.ud_deal_types_id)::text = (uddealtypes.fin_id)::text) AND ((eodpl.product_id)::text = (products.fin_id)::text) AND ((deals.deal_no)::text = (eodpl.deal_no)::text) AND ((deals.repositories_id)::text = (repositories.fin_id)::text) AND (deals.version_no = eodpl.version_no) AND ((deals.fin_id)::text = (versions.deals_id)::text) AND (deals.version_no = versions.version_no) AND ((deals.customers_id)::text = (cust.fin_id)::text) AND ((cust.type_id)::text = (ct.fin_id)::text) AND ((fxdeals.deal_versions_id)::text = (versions.fin_id)::text) AND ((deals.action)::text <> 'CANCEL'::text) AND (to_char(deals.trade_date, 'YYYYMMDD'::text) <= ( SELECT to_char(tbls_dates_master.accounting_date, 'YYYYMMDD'::text) AS to_char
           FROM tbls_dates_master)) AND (to_char(eodpl.pl_date, 'YYYYMMDD'::text) = to_char(datesmaster.accounting_date, 'YYYYMMDD'::text)) AND (to_char(eodpl.deal_value_date, 'YYYYMMDD'::text) >= to_char(datesmaster.accounting_date, 'YYYYMMDD'::text)) AND ((regions.fin_id)::text = (datesmaster.region_id)::text))
UNION ALL
 SELECT ((((((innerq.product_id || '_'::text) || (innerq.repository_id)::text) || '_'::text) || (innerq.currency_id)::text) || '_'::text) || 'FXPOSITION_TODAY'::text) AS fin_id,
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
            WHEN (sum(innerq.total_pl) > (0)::numeric) THEN 'MTM_POSITIVE'::text
            ELSE 'MTM_NEGATIVE'::text
        END AS ctc_mtm_sign_today,
        CASE
            WHEN (sum(innerq.total_pl) > (0)::numeric) THEN abs(sum(innerq.total_pl))
            ELSE (0)::numeric
        END AS mtm_gain,
        CASE
            WHEN (sum(innerq.total_pl) <= (0)::numeric) THEN abs(sum(innerq.total_pl))
            ELSE (0)::numeric
        END AS mtm_loss,
    innerq.repository_id AS repository,
    innerq.corp_code,
    innerq.cost_center,
    innerq.pl_date AS trade_date,
    innerq.pl_date AS value_date,
    innerq.pl_date AS memo_rev_date,
    innerq.reference_date AS accounting_date,
    'Y'::character varying AS is_resident
   FROM ( SELECT 'ALL'::text AS product_id,
            dailypl.repository_id,
            repositories.corp_code,
            repositories.cost_center,
            regions.currencies_id AS currency_id,
            dailypl.pl_date,
            datesmaster.accounting_date AS reference_date,
            dailypl.total_pl
           FROM tbls_daily_pl dailypl,
            tbls_repositories repositories,
            tbls_dates_master datesmaster,
            tbls_regions regions
          WHERE (((dailypl.repository_id)::text = (repositories.fin_id)::text) AND (to_char(dailypl.pl_date, 'YYYYMMDD'::text) = to_char(datesmaster.accounting_date, 'YYYYMMDD'::text)) AND (to_char(dailypl.reference_date, 'YYYYMMDD'::text) = to_char(datesmaster.accounting_date, 'YYYYMMDD'::text)) AND ((regions.fin_id)::text = (datesmaster.region_id)::text))) innerq
  GROUP BY innerq.product_id, innerq.repository_id, innerq.cost_center, innerq.corp_code, innerq.currency_id, innerq.pl_date, innerq.reference_date;


--
--

CREATE VIEW vbls_nop_opening_balance AS
 SELECT
        CASE
            WHEN (table1.ccy IS NULL) THEN table2.ccy
            ELSE table1.ccy
        END AS ccy,
    COALESCE(table1.purchases, (0)::numeric) AS cumul_purchases,
    COALESCE(table1.sales, (0)::numeric) AS cumul_sales,
    COALESCE(table2.cancel, (0)::numeric) AS cumul_cancel,
    ((COALESCE(table1.purchases, (0)::numeric) - COALESCE(table1.sales, (0)::numeric)) - COALESCE(table2.cancel, (0)::numeric)) AS opening_position
   FROM (( SELECT
                CASE
                    WHEN (t1.buy_currency IS NULL) THEN t2.sell_currency
                    ELSE t1.buy_currency
                END AS ccy,
            COALESCE(t1.purchases, (0)::numeric) AS purchases,
            COALESCE(t2.sales, (0)::numeric) AS sales
           FROM (( SELECT fxnop.buy_currency,
                    sum(COALESCE(fxnop.buy_amount, (0)::numeric)) AS purchases
                   FROM tbls_fxnopvol_hist fxnop,
                    tbls_dates_master dm,
                    tbls_regions regions
                  WHERE (((fxnop.reversal_status)::text = 'NORMAL'::text) AND (to_char(fxnop.system_date, 'YYYYMMDD'::text) < to_char(dm.reporting_date, 'YYYYMMDD'::text)) AND ((dm.region_id)::text = (regions.fin_id)::text) AND (((fxnop.buy_currency)::text = (regions.currencies_id)::text) OR ((fxnop.sell_currency)::text = (regions.currencies_id)::text)))
                  GROUP BY fxnop.buy_currency) t1
             FULL JOIN ( SELECT fxnop.sell_currency,
                    sum(COALESCE(fxnop.sell_amount, (0)::numeric)) AS sales
                   FROM tbls_fxnopvol_hist fxnop,
                    tbls_dates_master dm,
                    tbls_regions regions
                  WHERE (((fxnop.reversal_status)::text = 'NORMAL'::text) AND (to_char(fxnop.system_date, 'YYYYMMDD'::text) < to_char(dm.reporting_date, 'YYYYMMDD'::text)) AND ((dm.region_id)::text = (regions.fin_id)::text) AND (((fxnop.buy_currency)::text = (regions.currencies_id)::text) OR ((fxnop.sell_currency)::text = (regions.currencies_id)::text)))
                  GROUP BY fxnop.sell_currency) t2 ON (((t1.buy_currency)::text = (t2.sell_currency)::text)))) table1
     FULL JOIN ( SELECT
                CASE
                    WHEN (t1.buy_currency IS NULL) THEN t2.sell_currency
                    ELSE t1.buy_currency
                END AS ccy,
            (COALESCE(t2.sales_to_reverse, (0)::numeric) - COALESCE(t1.purchases_to_reverse, (0)::numeric)) AS cancel
           FROM (( SELECT fxnop.buy_currency,
                    COALESCE(sum(fxnop.buy_amount), '0'::numeric) AS purchases_to_reverse
                   FROM tbls_fxnopvol_hist fxnop,
                    tbls_dates_master dm,
                    tbls_regions regions
                  WHERE (((fxnop.reversal_status)::text = 'REVERSE'::text) AND (to_char(fxnop.system_date, 'YYYYMMDD'::text) < to_char(dm.reporting_date, 'YYYYMMDD'::text)) AND ((dm.region_id)::text = (regions.fin_id)::text) AND (((fxnop.buy_currency)::text = (regions.currencies_id)::text) OR ((fxnop.sell_currency)::text = (regions.currencies_id)::text)))
                  GROUP BY fxnop.buy_currency) t1
             FULL JOIN ( SELECT fxnop.sell_currency,
                    COALESCE(sum(fxnop.sell_amount), '0'::numeric) AS sales_to_reverse
                   FROM tbls_fxnopvol_hist fxnop,
                    tbls_dates_master dm,
                    tbls_regions regions
                  WHERE (((fxnop.reversal_status)::text = 'REVERSE'::text) AND (to_char(fxnop.system_date, 'YYYYMMDD'::text) < to_char(dm.reporting_date, 'YYYYMMDD'::text)) AND ((dm.region_id)::text = (regions.fin_id)::text) AND (((fxnop.buy_currency)::text = (regions.currencies_id)::text) OR ((fxnop.sell_currency)::text = (regions.currencies_id)::text)))
                  GROUP BY fxnop.sell_currency) t2 ON (((t1.buy_currency)::text = (t2.sell_currency)::text)))) table2 ON (((table1.ccy)::text = (table2.ccy)::text)));


--
--

CREATE VIEW vbls_order_search_view AS
 SELECT banknotesorders.fin_id,
    banknotesorders.vault_date,
    banknotesorders.vault2_date,
    banknotesorders.release_date,
    banknotesorders.entry_date,
    banknotesorders.trade_date,
    banknotesorders.value_date,
    banknotesorders.action,
    banknotesorders.action_date,
    COALESCE(banknotesorders.deal_no, ' '::character varying) AS deal_number,
    banknotesorders.buy_sell,
    banknotesorders.customers_id AS customer_id,
    banknotesorders.branches_id,
    banknotesorders.users_id AS user_id,
    banknotesorders.products_id,
    banknotesorders.internal_comments,
    banknotesorders.external_comments,
    banknotesorders.deal_change_reason_codes_id,
    banknotesorders.reason_custom,
    banknotesorders.version_no,
    banknotesorders.setl_cur_id,
    products.name AS products_name,
    products.deal_type_name AS dealtype_name,
    customers.name AS customers_name,
    customers.short_name AS customers_short_name,
    customers.ctp_no AS customers_ctp_no,
    branches.name AS branches_name,
    branches.short_name AS branches_short_name,
    COALESCE(sdis.sdi_code, ' '::character varying) AS sdi_code,
    workflowstatesorders.name AS order_status,
    workflowstatesorders.workflow_level AS order_status_level
   FROM (tbls_bank_notes_orders banknotesorders
     LEFT JOIN tbls_sdis sdis ON (((banknotesorders.sdi_id)::text = (sdis.fin_id)::text))),
    tbls_products products,
    tbls_customers customers,
    tbls_branches branches,
    tbls_workflow_states workflowstatesorders
  WHERE (((banknotesorders.customers_id)::text = (customers.fin_id)::text) AND ((banknotesorders.branches_id)::text = (branches.fin_id)::text) AND ((banknotesorders.products_id)::text = (products.fin_id)::text) AND ((banknotesorders.order_status)::text = (workflowstatesorders.fin_id)::text));


--
--

CREATE VIEW vbls_packing_list_search_view AS
 SELECT DISTINCT alias2.fin_id,
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
   FROM ( SELECT shipmentrecords.fin_id,
            shipmentrecords.shipment_method_id AS shipment_method,
            shipmentrecords.shipper_id AS shipper,
            shipmentrecords.consignees_id AS consignee,
            COALESCE(packinglist.packing_list_no, ' '::character varying) AS packing_list_no,
            shipmentrecords.shipment_type_id,
            shipmentrecords.shipment_date,
            shipmentrouting.arrival_date,
            workflowstatesshipment.name AS shipment_status,
            workflowstatesvault.name AS vault_status,
            shipmentrecords.last_updated AS last_updated_date
           FROM (tbls_shipment_records shipmentrecords
             LEFT JOIN tbls_packing_list packinglist ON ((((packinglist.shipment_record_id)::text = (shipmentrecords.fin_id)::text) AND ((packinglist.is_deleted)::text = 'N'::text)))),
            tbls_workflow_states workflowstatesshipment,
            tbls_workflow_states workflowstatesvault,
            tbls_shipment_record_routing shipmentrouting
          WHERE (((workflowstatesshipment.fin_id)::text = (shipmentrecords.shipment_status_id)::text) AND ((workflowstatesvault.fin_id)::text = (shipmentrecords.vault_status_id)::text) AND ((shipmentrouting.shipment_record_id)::text = (shipmentrecords.fin_id)::text) AND (shipmentrouting.leg_no = (1)::double precision) AND ((shipmentrecords.is_deleted)::text = 'N'::text))) alias2
  ORDER BY alias2.shipment_date DESC, alias2.fin_id DESC;


--
--

CREATE VIEW vbls_reval_pl AS
 SELECT ((((((dailypl.repository_id)::text || '_'::text) || to_char(dailypl.reference_date, 'YYYYMMDD'::text)) || '_'::text) || (dailypl.currency_id)::text) || '_'::text) AS fin_id,
    dailypl.repository_id,
    dailypl.reference_date,
    dailypl.currency_id,
    COALESCE(sum(
        CASE
            WHEN ((dailypl.product_id)::text = 'BKN'::text) THEN dailypl.total_pl
            ELSE (0)::numeric
        END), (0)::numeric) AS bkn_pl,
    COALESCE(sum(
        CASE
            WHEN ((dailypl.product_id)::text = 'TCQ'::text) THEN dailypl.total_pl
            ELSE (0)::numeric
        END), (0)::numeric) AS tcq_pl,
    COALESCE(sum(
        CASE
            WHEN ((dailypl.product_id)::text = 'IFX'::text) THEN dailypl.total_pl
            ELSE (0)::numeric
        END), (0)::numeric) AS ifx_pl,
    outerq.position_amt,
    'NON LIKE LIKE BASE'::text AS pl_type
   FROM tbls_daily_pl dailypl,
    ( SELECT innerq.currency_id,
            sum(innerq.fx_opening_balance) AS position_amt,
            innerq.repository_id,
            innerq.reference_date
           FROM ( SELECT tbls_dly_fx_opening_balance.currency_id,
                    tbls_dly_fx_opening_balance.repository_id,
                    tbls_dly_fx_opening_balance.fx_opening_balance,
                    tbls_dly_fx_opening_balance.past_date AS reference_date
                   FROM tbls_dly_fx_opening_balance
                  WHERE ((tbls_dly_fx_opening_balance.is_deleted)::text = 'N'::text)
                UNION ALL
                 SELECT tbls_fx_positions_history.currency_id,
                    tbls_fx_positions_history.repository_id,
                    tbls_fx_positions_history.fx_pos_amount,
                    tbls_fx_positions_history.reference_date
                   FROM tbls_fx_positions_history
                  WHERE ((tbls_fx_positions_history.is_deleted)::text = 'N'::text)) innerq
          GROUP BY innerq.currency_id, innerq.repository_id, innerq.reference_date) outerq
  WHERE (((outerq.currency_id)::text = (dailypl.currency_id)::text) AND ((outerq.repository_id)::text = (dailypl.repository_id)::text) AND (outerq.reference_date = dailypl.reference_date))
  GROUP BY dailypl.repository_id, dailypl.reference_date, dailypl.currency_id, outerq.position_amt
UNION ALL
 SELECT (((((((innerq.repository)::text || '_'::text) || to_char(innerq.pl_date, 'YYYYMMDD'::text)) || '_'::text) || (innerq.currencies_id)::text) || '_'::text) || (innerq.product_code)::text) AS fin_id,
    innerq.repository AS repository_id,
    innerq.pl_date AS reference_date,
    innerq.currencies_id AS currency_id,
    COALESCE(sum(
        CASE
            WHEN ((innerq.product_code)::text = 'BKN'::text) THEN innerq.totalpl
            ELSE (0)::numeric
        END), (0)::numeric) AS bkn_pl,
    COALESCE(sum(
        CASE
            WHEN ((innerq.product_code)::text = 'TCQ'::text) THEN innerq.totalpl
            ELSE (0)::numeric
        END), (0)::numeric) AS tcq_pl,
    COALESCE(sum(
        CASE
            WHEN ((innerq.product_code)::text = 'IFX'::text) THEN innerq.totalpl
            ELSE (0)::numeric
        END), (0)::numeric) AS ifx_pl,
    COALESCE(sum(innerq.totalpl), (0)::numeric) AS position_amt,
    'LIKE LIKE BASE'::text AS pl_type
   FROM ( SELECT tbls_like_like_base_pl_acc.totalpl,
            tbls_like_like_base_pl_acc.typeofpl,
            tbls_like_like_base_pl_acc.pl_date,
            tbls_like_like_base_pl_acc.product_code,
            tbls_like_like_base_pl_acc.currencies_id,
            tbls_like_like_base_pl_acc.repository
           FROM tbls_like_like_base_pl_acc) innerq
  GROUP BY innerq.repository, innerq.pl_date, innerq.currencies_id, innerq.product_code;


--
--

CREATE VIEW vbls_shipment_invoice AS
 SELECT DISTINCT shipmentcharges.fin_id,
    shipmentcharges.service_charge_provider_int AS service_charge_provider,
    shipmentcharges.charge_ccy_id,
    COALESCE(shipmentcharges.invoice_ccy, shipmentcharges.charge_ccy_id) AS invoice_ccy,
    shipmentcharges.shipment_record_id,
    shipmentcharges.remarks,
    shipmentcharges.invoice_remarks,
    COALESCE(shipmentcharges.charge_amount, (0)::numeric) AS charge_amount,
    shipmentcharges.invoice_no,
    COALESCE(shipmentcharges.invoice_amount, COALESCE(shipmentcharges.charge_amount, (0)::numeric)) AS invoice_amount,
    shipmentcharges.charge_date,
    COALESCE(shipmentcharges.invoice_date, datesmaster.system_date) AS invoice_date,
    shipmentcharges.settlement_date,
    shipmentcharges.status,
    shipmentcharges.invoice_status,
    shipmentcharges.is_charge_amt_propagated_deal,
    shipmentcharges.is_invoice_amt_propagated_deal,
    shipmentrecordrouting.airway_bill_no,
    shipmentschedule.origin_airports_id,
    shipmentschedule.dest_airports_id,
    shipmentschedule.schedule,
    shipmentrecords.shipment_date,
    shipmentrecords.shipment_value_usd,
    shipmentrecords.shipment_value_base,
    shipmentrecords.shipment_method_id,
    servicecharges.service_charge_name,
    serviceprovider.name AS service_provider_name,
    serviceprovider.fin_id AS service_provider_id,
    serviceaccounttypes.name AS service_account_type_name,
    shipmentcharges.last_updated
   FROM tbls_shipment_charges shipmentcharges,
    tbls_shipment_records shipmentrecords,
    tbls_svc_charge_prvder_int servicechargeprvd,
    tbls_service_charges servicecharges,
    tbls_shipment_record_routing shipmentrecordrouting,
    tbls_shipment_schedules shipmentschedule,
    tbls_service_providers serviceprovider,
    tbls_service_categories servicecategories,
    tbls_service_account_types serviceaccounttypes,
    tbls_dates_master datesmaster,
    ( SELECT tbls_shipment_record_routing.shipment_record_id,
            min(tbls_shipment_record_routing.leg_no) AS minlegno
           FROM tbls_shipment_record_routing
          WHERE ((tbls_shipment_record_routing.is_deleted)::text = 'N'::text)
          GROUP BY tbls_shipment_record_routing.shipment_record_id) shrouteminleg
  WHERE (((shipmentcharges.shipment_record_id)::text = (shipmentrecords.fin_id)::text) AND ((shipmentcharges.service_charge_provider_int)::text = (servicechargeprvd.fin_id)::text) AND ((shipmentrecords.fin_id)::text = (shipmentrecordrouting.shipment_record_id)::text) AND ((shipmentrecords.fin_id)::text = (shipmentrecordrouting.shipment_record_id)::text) AND ((shrouteminleg.shipment_record_id)::text = (shipmentrecordrouting.shipment_record_id)::text) AND (shipmentrecordrouting.leg_no = shrouteminleg.minlegno) AND ((shipmentrecordrouting.shipment_schedule_id)::text = (shipmentschedule.fin_id)::text) AND ((servicechargeprvd.service_charge_id)::text = (servicecharges.fin_id)::text) AND ((serviceprovider.fin_id)::text = (servicechargeprvd.service_provider_id)::text) AND ((servicecategories.fin_id)::text = (servicecharges.service_category_id)::text) AND ((servicecategories.service_account_type_id)::text = (serviceaccounttypes.fin_id)::text) AND ((shipmentcharges.is_deleted)::text = 'N'::text) AND ((shipmentrecordrouting.is_deleted)::text = 'N'::text))
  ORDER BY shipmentcharges.charge_date DESC, shipmentrecords.shipment_date DESC, shipmentrecordrouting.airway_bill_no DESC, shipmentcharges.shipment_record_id DESC, serviceprovider.name DESC, servicecharges.service_charge_name DESC;


--
--

CREATE VIEW vbls_shipper_consginee_detail AS
 SELECT shipmentrecords.fin_id AS shipment_id,
    shipmentrecordrouting.fin_id,
    COALESCE(shipmentrecordrouting.no_of_pcs, ((0)::bigint)::double precision) AS no_of_pcs,
    shipper.fin_id AS shipper_id,
    consignees.fin_id AS consignee_id,
    COALESCE(consigneecontacts.name, ' '::character varying) AS consignee_contact_name,
    COALESCE(consignees.address1, ' '::character varying) AS consignee_address,
    COALESCE(consigneecontacts.id_number, ' '::character varying) AS consignee_contact_id,
    COALESCE(consigneecontacts.contact_nos, ' '::character varying) AS consignee_contact_nos,
    COALESCE(consigneecontacts.fax_nos, ' '::character varying) AS consginee_fax_no,
    COALESCE(consigneecontacts.email, ' '::character varying) AS consignee_email,
    consigneeairport.code AS consignee_airport_code,
    COALESCE(shippercontacts.name, ' '::character varying) AS shipper_contact_name,
    COALESCE(shipper.address1, ' '::character varying) AS shipper_address,
    COALESCE(shippercontacts.id_number, ' '::character varying) AS shipper_contact_id,
    COALESCE(shippercontacts.contact_nos, ' '::character varying) AS shipper_contact_nos,
    COALESCE(shippercontacts.fax_nos, ' '::character varying) AS shipper_fax_no,
    COALESCE(shippercontacts.email, ' '::character varying) AS shipper_email,
    shipperairport.code AS shipper_airport_code,
    shipmentschedule.origin_airports_id AS originating_airport_code,
    shipmentschedule.dest_airports_id AS destination_airport_code,
    shipmentschedule.carrier_id,
    shipmentrecordrouting.airway_bill_no,
    carrier.accountinginfo AS accounting_info,
    shipmentrecordrouting.leg_no AS routinglegno,
    consignees.awb_special_clause
   FROM ((tbls_shipment_records shipmentrecords
     LEFT JOIN tbls_consignee_contacts_extn consigneecontacts ON ((((shipmentrecords.consignees_id)::text = (consigneecontacts.consignees_id)::text) AND ((shipmentrecords.consignee_contact_name)::text = (consigneecontacts.fin_id)::text))))
     LEFT JOIN tbls_consignee_contacts_extn shippercontacts ON (((shipmentrecords.shipper_id)::text = (shippercontacts.consignees_id)::text))),
    tbls_shipment_record_routing shipmentrecordrouting,
    tbls_consignees shipper,
    tbls_consignees consignees,
    tbls_airports shipperairport,
    tbls_airports consigneeairport,
    tbls_shipment_schedules shipmentschedule,
    tbls_carriers carrier
  WHERE (((shipmentrecordrouting.is_deleted)::text = 'N'::text) AND ((shipmentrecords.is_deleted)::text = 'N'::text) AND ((shipmentrecords.fin_id)::text = (shipmentrecordrouting.shipment_record_id)::text) AND ((shipmentrecords.shipper_id)::text = (shipper.fin_id)::text) AND ((shipmentrecords.consignees_id)::text = (consignees.fin_id)::text) AND ((shipper.airports_id)::text = (shipperairport.fin_id)::text) AND ((consignees.airports_id)::text = (consigneeairport.fin_id)::text) AND ((shipmentrecordrouting.shipment_schedule_id)::text = (shipmentschedule.fin_id)::text) AND ((shipmentschedule.carrier_id)::text = (carrier.fin_id)::text))
  ORDER BY shipmentrecords.fin_id, shipmentrecordrouting.leg_no;


--
--

CREATE VIEW vbls_shiprec_with_org_dest AS
 SELECT originariportsrecs.shipment_record_id AS fin_id,
    originariportsrecs.origin_airports_id,
    destairportrecords.dest_airports_id
   FROM ( SELECT reoutingleg.shipment_record_id,
            nearestschedule.origin_airports_id
           FROM tbls_shipment_record_routing reoutingleg,
            tbls_shipment_schedules nearestschedule,
            ( SELECT nearestrouting.shipment_record_id AS shrecord,
                    min(nearestrouting.leg_no) AS minlegno
                   FROM tbls_shipment_record_routing nearestrouting
                  WHERE ((nearestrouting.is_deleted)::text = 'N'::text)
                  GROUP BY nearestrouting.shipment_record_id
                  ORDER BY nearestrouting.shipment_record_id) nearestlegrecords
          WHERE ((reoutingleg.leg_no = nearestlegrecords.minlegno) AND ((reoutingleg.shipment_record_id)::text = (nearestlegrecords.shrecord)::text) AND ((reoutingleg.shipment_schedule_id)::text = (nearestschedule.fin_id)::text))) originariportsrecs,
    ( SELECT farroutingleg.shipment_record_id,
            farthestschedule.dest_airports_id
           FROM tbls_shipment_record_routing farroutingleg,
            tbls_shipment_schedules farthestschedule,
            ( SELECT fartherrouting.shipment_record_id AS shrecord,
                    max(fartherrouting.leg_no) AS maxlegno
                   FROM tbls_shipment_record_routing fartherrouting
                  WHERE ((fartherrouting.is_deleted)::text = 'N'::text)
                  GROUP BY fartherrouting.shipment_record_id
                  ORDER BY fartherrouting.shipment_record_id) farthestlegrecords
          WHERE ((farroutingleg.leg_no = farthestlegrecords.maxlegno) AND ((farroutingleg.shipment_record_id)::text = (farthestlegrecords.shrecord)::text) AND ((farroutingleg.shipment_schedule_id)::text = (farthestschedule.fin_id)::text))) destairportrecords
  WHERE ((originariportsrecs.shipment_record_id)::text = (destairportrecords.shipment_record_id)::text)
  ORDER BY originariportsrecs.shipment_record_id DESC;


--
--

CREATE VIEW vbls_trading_activity AS
 SELECT (((((deals.deal_no)::text || '_'::text) || dealversions.version_no) || '_'::text) || banknotesdealslegs.leg_number) AS fin_id,
    deals.repositories_id,
    products.code AS products_code,
    deals.deal_no AS deal_number,
    dealversions.version_no AS deals_version_no,
    countries.name AS country,
    customers.short_name AS customers_short_name,
    customers.is_resident AS customers_is_resident,
    branches.short_name AS branches_short_name,
    sdis.sdi_code,
    banknotesdealslegs.shipment_records_id,
    deals.entry_date,
    deals.trade_date,
    deals.value_date,
    deals.users_id AS input_by_id,
    banknotesdeals.vault_date,
        CASE
            WHEN ((products.deal_type_name)::text = 'ECI Repatriation'::text) THEN banknotesdeals.depo_withdraw_date
            WHEN ((products.deal_type_name)::text = 'ECI Top-up'::text) THEN banknotesdeals.depo_withdraw_date
            ELSE banknotesdeals.release_date
        END AS release_date,
    banknotesdealslegs.buy_sell,
    products.deal_type_name AS dealtype_name,
    uddealtypes.name AS ud_type_name,
    banknotesdeals.vault1_id,
    banknotesdeals.vault2_id,
    banknotesdeals.release2_date,
    banknotesdeals.vault2_date,
    dealversions.link_deal_no,
    workflowstatesdeals.name AS deal_status,
    workflowstatesshipment.name AS shipment_status,
    workflowstatesvault.name AS vault_status,
    COALESCE(workflowstatessetl.name, ' '::character varying) AS setl_status,
    COALESCE(banknotesdeals.fully_funded, ' '::bpchar) AS fully_funded,
    banknotesdealslegs.leg_number,
    banknotesdealslegs.currencies_id AS leg_currency,
    ((COALESCE(denoms.code, ''::character varying))::text || (denoms.multiplier)::text) AS leg_denom,
    banknotesdealslegs.bank_notes_types_id AS leg_notes_types,
    banknotesdealslegs.amount AS leg_amount,
    round((banknotesdealslegs.amount *
        CASE
            WHEN ((banknotesdealslegs.currencies_id)::text = 'USD'::text) THEN (1)::numeric
            WHEN (((banknotesdealslegs.currencies_id)::text = (cpforleg.currency1_id)::text) AND ((cpforleg.currency2_id)::text = 'USD'::text)) THEN (((fxsforleg.bid_rate + fxsforleg.ask_rate) / (2)::numeric) / (cpforleg.spot_factor)::numeric)
            ELSE ((cpforleg.spot_factor)::numeric / ((fxsforleg.bid_rate + fxsforleg.ask_rate) / (2)::numeric))
        END), 2) AS leg_amount_usd,
    round(
        CASE
            WHEN ((banknotesdealslegs.currencies_id)::text = 'USD'::text) THEN (1)::numeric
            WHEN (((banknotesdealslegs.currencies_id)::text = (cpforleg.currency1_id)::text) AND ((cpforleg.currency2_id)::text = 'USD'::text)) THEN (((fxsforleg.bid_rate + fxsforleg.ask_rate) / (2)::numeric) / (cpforleg.spot_factor)::numeric)
            ELSE ((cpforleg.spot_factor)::numeric / ((fxsforleg.bid_rate + fxsforleg.ask_rate) / (2)::numeric))
        END, 11) AS leg_usd_rate,
    banknotesdealslegs.market_rate AS leg_market_rate,
    banknotesdealslegs.md AS leg_md,
    banknotesdealslegs.deal_rate AS leg_deal_rate,
    banknotesdealslegs.margin AS leg_margin,
        CASE
            WHEN (banknotesdealslegs.market_rate <> (0)::numeric) THEN ((banknotesdealslegs.deal_rate / banknotesdealslegs.market_rate) * (100)::numeric)
            ELSE (100)::numeric
        END AS leg_margin_factor,
    banknotesdealslegs.setl_amount AS leg_setl_amt,
    banknotesdealslegs.pl_amount AS leg_pl_amt,
    round((banknotesdealslegs.pl_amount *
        CASE
            WHEN ((banknotesdeals.setl_cur_id)::text = 'USD'::text) THEN (1)::numeric
            WHEN (((banknotesdeals.setl_cur_id)::text = (cp.currency1_id)::text) AND ((cp.currency2_id)::text = 'USD'::text)) THEN (((fxs.bid_rate + fxs.ask_rate) / (2)::numeric) / (cp.spot_factor)::numeric)
            ELSE ((cp.spot_factor)::numeric / ((fxs.bid_rate + fxs.ask_rate) / (2)::numeric))
        END), 2) AS leg_pl_amt_usd,
    banknotesdeals.charge_amount AS charge,
    banknotesdeals.setl_cur_id AS setl_currency,
    banknotesdeals.net_setl_amt AS total_setl_amt,
    round((banknotesdeals.net_setl_amt *
        CASE
            WHEN ((banknotesdeals.setl_cur_id)::text = 'USD'::text) THEN (1)::numeric
            WHEN (((banknotesdeals.setl_cur_id)::text = (cp.currency1_id)::text) AND ((cp.currency2_id)::text = 'USD'::text)) THEN (((fxs.bid_rate + fxs.ask_rate) / (2)::numeric) / (cp.spot_factor)::numeric)
            ELSE ((cp.spot_factor)::numeric / ((fxs.bid_rate + fxs.ask_rate) / (2)::numeric))
        END), 2) AS total_setl_amt_usd,
    round(
        CASE
            WHEN ((banknotesdeals.setl_cur_id)::text = 'USD'::text) THEN (1)::numeric
            WHEN ((banknotesdeals.setl_cur_id)::text = (cp.currency1_id)::text) THEN (((fxs.bid_rate + fxs.ask_rate) / (2)::numeric) / (cp.spot_factor)::numeric)
            ELSE ((cp.spot_factor)::numeric / ((fxs.bid_rate + fxs.ask_rate) / (2)::numeric))
        END, 11) AS usd_rate,
    banknotesdeals.usd_rate_vs_setl_cur,
    deals.external_comments AS external_remarks,
    deals.internal_comments AS internal_remarks,
    banknotesdeals.commission_amount,
    banknotesdeals.commission_cur_id,
    banknotesdeals.commission_setl_type,
    banknotesdeals.commission_setl_date,
    banknotesdeals.pl_amount AS totalpl,
    (banknotesdeals.pl_amount *
        CASE
            WHEN ((banknotesdeals.setl_cur_id)::text = 'USD'::text) THEN (1)::numeric
            WHEN (((banknotesdeals.setl_cur_id)::text = (cp.currency1_id)::text) AND ((cp.currency2_id)::text = 'USD'::text)) THEN (((fxs.bid_rate + fxs.ask_rate) / (2)::numeric) / (cp.spot_factor)::numeric)
            ELSE ((cp.spot_factor)::numeric / ((fxs.bid_rate + fxs.ask_rate) / (2)::numeric))
        END) AS total_pl_usd,
    banknotesdeals.usd_rate_vs_base_cur,
    banknotesdealslegs.leg_ccy_vs_usd_dealrate,
    banknotesdealslegs.leg_ccy_vs_base_dealrate,
    customertypes.description AS customertype,
    COALESCE(dealssi.nv_code, ' '::character varying) AS nv_code,
    COALESCE(dealssi.setl_mode_id, ' '::character varying) AS nv_setl_code,
    deals.action,
    datesmaster.system_date,
    datesmaster.reporting_date,
    shiprec.shipment_method_id
   FROM (tbls_bank_notes_deals banknotesdeals
     LEFT JOIN tbls_sdis sdis ON (((banknotesdeals.sdi_id)::text = (sdis.fin_id)::text))),
    (((tbls_deal_versions dealversions
     LEFT JOIN tbls_deal_ssi dealssi ON (((dealversions.fin_id)::text = (dealssi.deal_versions_id)::text)))
     LEFT JOIN ( SELECT tso.deal_versions_id,
            tso.status_id
           FROM ( SELECT max(ts.version_no) AS setlno,
                    ts.deal_versions_id AS dealversionid
                   FROM tbls_settlements ts
                  WHERE (((ts.is_deleted)::text = 'N'::text) OR ((ts.status_id)::text = 'PAYMENTS_CANCELLED'::text) OR ((ts.status_id)::text = 'PAYMENTS_NETTEDP'::text) OR ((ts.status_id)::text = 'PAYMENTS_NETTEDC'::text))
                  GROUP BY ts.deal_versions_id) ts_in,
            tbls_settlements tso
          WHERE (((tso.deal_versions_id)::text = (ts_in.dealversionid)::text) AND (ts_in.setlno = tso.version_no))) settlements ON (((dealversions.fin_id)::text = (settlements.deal_versions_id)::text)))
     LEFT JOIN tbls_workflow_states workflowstatessetl ON (((workflowstatessetl.fin_id)::text = (settlements.status_id)::text))),
    (((tbls_bank_notes_deals_legs banknotesdealslegs
     LEFT JOIN tbls_workflow_states workflowstatesvault ON (((banknotesdealslegs.vault_status_id)::text = (workflowstatesvault.fin_id)::text)))
     LEFT JOIN tbls_workflow_states workflowstatesshipment ON (((banknotesdealslegs.shipping_status_id)::text = (workflowstatesshipment.fin_id)::text)))
     LEFT JOIN tbls_shipment_records shiprec ON (((banknotesdealslegs.shipment_records_id)::text = (shiprec.fin_id)::text))),
    tbls_deals deals,
    tbls_products products,
    tbls_ud_deal_types uddealtypes,
    tbls_ud_dt_mapping uddtmapping,
    tbls_customers customers,
    tbls_branches branches,
    tbls_countries countries,
    tbls_deals_status dealstatus,
    tbls_workflow_states workflowstatesdeals,
    tbls_customer_types customertypes,
    tbls_bank_notes_denoms denoms,
    tbls_dates_master datesmaster,
    tbls_fxforward_rates fxs,
    tbls_currencypairs cp,
    tbls_fxforward_rates fxsforleg,
    tbls_currencypairs cpforleg
  WHERE ((deals.version_no = dealversions.version_no) AND ((banknotesdeals.fin_id)::text = (dealversions.fin_id)::text) AND ((dealversions.deals_id)::text = (deals.fin_id)::text) AND ((banknotesdeals.fin_id)::text = (dealversions.fin_id)::text) AND ((banknotesdeals.fin_id)::text = (banknotesdealslegs.bank_notes_deals_id)::text) AND (((dealversions.customers_id)::text = (customers.fin_id)::text) AND ((customertypes.fin_id)::text = (customers.type_id)::text) AND ((banknotesdeals.fin_id)::text = (dealversions.fin_id)::text)) AND (((dealversions.branches_id)::text = (branches.fin_id)::text) AND ((banknotesdeals.fin_id)::text = (dealversions.fin_id)::text)) AND (((dealversions.products_id)::text = (products.fin_id)::text) AND ((banknotesdeals.fin_id)::text = (dealversions.fin_id)::text)) AND (((dealstatus.fin_id)::text = (deals.deal_no)::text) AND ((dealstatus.deal_status_id)::text = (workflowstatesdeals.fin_id)::text)) AND (((uddealtypes.fin_id)::text = (uddtmapping.ud_deal_types_id)::text) AND ((uddtmapping.fin_id)::text = (deals.ud_deal_types_id)::text)) AND ((banknotesdealslegs.bank_notes_denoms_id)::text = (denoms.fin_id)::text) AND ((customers.business_operation_country_id)::text = (countries.fin_id)::text) AND ((((cp.currency1_id)::text = (banknotesdeals.setl_cur_id)::text) AND ((cp.currency2_id)::text = 'USD'::text)) OR (((cp.currency1_id)::text = 'USD'::text) AND ((cp.currency2_id)::text = (banknotesdeals.setl_cur_id)::text)) OR (((cp.currency1_id)::text = 'USD'::text) AND ((cp.currency2_id)::text = 'SGD'::text) AND ((cp.currency1_id)::text = (banknotesdeals.setl_cur_id)::text)) OR (((cp.currency1_id)::text = 'USD'::text) AND ((cp.currency2_id)::text = 'SGD'::text) AND (banknotesdeals.setl_cur_id IS NULL))) AND ((fxs.currencypairs_id)::text = (cp.pairs_shortname)::text) AND (to_char(deals.trade_date, 'YYYYMMDD'::text) = to_char(fxs.mkt_date, 'YYYYMMDD'::text)) AND ((fxs.tenor)::text = 'S'::text) AND ((fxs.data_set_name)::text = 'OPENING'::text) AND ((((cpforleg.currency1_id)::text = (banknotesdealslegs.currencies_id)::text) AND ((cpforleg.currency2_id)::text = 'USD'::text)) OR (((cpforleg.currency1_id)::text = 'USD'::text) AND ((cpforleg.currency2_id)::text = (banknotesdealslegs.currencies_id)::text)) OR (((cpforleg.currency1_id)::text = 'USD'::text) AND ((cpforleg.currency2_id)::text = 'SGD'::text) AND ((cpforleg.currency1_id)::text = (banknotesdealslegs.currencies_id)::text)) OR (((cpforleg.currency1_id)::text = 'USD'::text) AND ((cpforleg.currency2_id)::text = 'SGD'::text) AND (banknotesdealslegs.currencies_id IS NULL))) AND ((fxsforleg.currencypairs_id)::text = (cpforleg.pairs_shortname)::text) AND (to_char(deals.trade_date, 'YYYYMMDD'::text) = to_char(fxsforleg.mkt_date, 'YYYYMMDD'::text)) AND ((fxsforleg.tenor)::text = 'S'::text) AND ((fxsforleg.data_set_name)::text = 'OPENING'::text))
  ORDER BY deals.deal_no DESC, dealversions.version_no DESC, banknotesdealslegs.leg_number;


--
--

CREATE VIEW vbls_trading_positions AS
 SELECT (((alias8.currency_id)::text || '_'::text) || (alias8.repository_id)::text) AS fin_id,
    sum(alias8.amount) AS amount,
    sum(alias8.sigma_wr) AS sigma_wr,
    alias8.currency_id,
    alias8.repository_id,
    'N'::text AS excess,
    avg(alias8.onlimit) AS on_limit
   FROM ( SELECT fxpos.fx_pos_amount AS amount,
            fxpos.sigma_w,
            fxpos.sigma_wr,
            fxpos.currency_id,
            fxpos.repository_id,
            rp.name AS repository_name,
            COALESCE(onlimit.on_limit, ((0)::bigint)::double precision) AS onlimit
           FROM tbls_repositories rp,
            (tbls_fx_positions fxpos
             LEFT JOIN tbls_fx_overnight_limits onlimit ON ((((fxpos.currency_id)::text = (onlimit.currencies_id)::text) AND ((onlimit.is_deleted)::text = 'N'::text) AND ((onlimit.maker_checker_status)::text = 'COMMITTED'::text))))
          WHERE (((fxpos.is_deleted)::text = 'N'::text) AND ((fxpos.maker_checker_status)::text = 'COMMITTED'::text) AND ((rp.fin_id)::text = (fxpos.repository_id)::text))
        UNION ALL
         SELECT dfx.fx_opening_balance AS amount,
            dfx.sigma_w,
            dfx.sigma_wr,
            dfx.currency_id,
            dfx.repository_id,
            rp.name AS repository_name,
            COALESCE(onlimit.on_limit, ((0)::bigint)::double precision) AS onlimit
           FROM tbls_repositories rp,
            (tbls_dly_fx_opening_balance dfx
             LEFT JOIN tbls_fx_overnight_limits onlimit ON ((((dfx.currency_id)::text = (onlimit.currencies_id)::text) AND ((onlimit.is_deleted)::text = 'N'::text) AND ((onlimit.maker_checker_status)::text = 'COMMITTED'::text))))
          WHERE ((to_char(dfx.past_date, 'YYYYMMDD'::text) = ( SELECT to_char(tbls_dates_master.system_date, 'YYYYMMDD'::text) AS to_char
                   FROM tbls_dates_master)) AND ((dfx.is_deleted)::text = 'N'::text) AND ((dfx.maker_checker_status)::text = 'COMMITTED'::text) AND ((dfx.repository_id)::text = (rp.fin_id)::text))) alias8
  GROUP BY alias8.currency_id, alias8.repository_id;


--
--

CREATE VIEW vbls_trading_positions_hist AS
 SELECT ((((((alias3.currency_id)::text || '_'::text) || (alias3.products_code)::text) || '_'::text) || (alias3.repository_id)::text) || to_char(alias3.reference_date, 'YYYYMMDD'::text)) AS fin_id,
    sum(alias3.amount) AS amount,
    sum(alias3.sigma_wr) AS sigma_wr,
    alias3.currency_id,
    alias3.products_code,
    alias3.repository_id,
    alias3.reference_date
   FROM ( SELECT tbls_fx_positions_history.fx_pos_amount AS amount,
            tbls_fx_positions_history.sigma_w,
            tbls_fx_positions_history.sigma_wr,
            tbls_fx_positions_history.currency_id,
            tbls_fx_positions_history.products_code,
            tbls_fx_positions_history.repository_id,
            tbls_fx_positions_history.reference_date
           FROM tbls_fx_positions_history
          WHERE (((tbls_fx_positions_history.is_deleted)::text = 'N'::text) AND ((tbls_fx_positions_history.maker_checker_status)::text = 'COMMITTED'::text))
        UNION ALL
         SELECT tbls_dly_fx_opening_balance.fx_opening_balance AS amount,
            tbls_dly_fx_opening_balance.sigma_w,
            tbls_dly_fx_opening_balance.sigma_wr,
            tbls_dly_fx_opening_balance.currency_id,
            tbls_dly_fx_opening_balance.product_id AS products_code,
            tbls_dly_fx_opening_balance.repository_id,
            tbls_dly_fx_opening_balance.last_closing_date AS reference_date
           FROM tbls_dly_fx_opening_balance
          WHERE (((tbls_dly_fx_opening_balance.is_deleted)::text = 'N'::text) AND ((tbls_dly_fx_opening_balance.maker_checker_status)::text = 'COMMITTED'::text))) alias3
  GROUP BY alias3.currency_id, alias3.products_code, alias3.repository_id, alias3.reference_date;


--
--

CREATE VIEW vbls_trading_positions_prdwise AS
 SELECT (((((alias5.currency_id)::text || '_'::text) || (alias5.products_code)::text) || '_'::text) || (alias5.repository_id)::text) AS fin_id,
    sum(alias5.amount) AS amount,
    sum(alias5.sigma_wr) AS sigma_wr,
    alias5.currency_id,
    alias5.products_code,
    alias5.repository_id,
    'N'::text AS excess,
    0 AS on_limit
   FROM ( SELECT tbls_fx_positions.fx_pos_amount AS amount,
            tbls_fx_positions.sigma_w,
            tbls_fx_positions.sigma_wr,
            tbls_fx_positions.currency_id,
            tbls_fx_positions.products_code,
            tbls_fx_positions.repository_id
           FROM tbls_fx_positions
          WHERE (((tbls_fx_positions.is_deleted)::text = 'N'::text) AND ((tbls_fx_positions.maker_checker_status)::text = 'COMMITTED'::text))
        UNION ALL
         SELECT tbls_dly_fx_opening_balance.fx_opening_balance AS amount,
            tbls_dly_fx_opening_balance.sigma_w,
            tbls_dly_fx_opening_balance.sigma_wr,
            tbls_dly_fx_opening_balance.currency_id,
            tbls_dly_fx_opening_balance.product_id AS products_code,
            tbls_dly_fx_opening_balance.repository_id
           FROM tbls_dly_fx_opening_balance
          WHERE ((to_char(tbls_dly_fx_opening_balance.past_date, 'YYYYMMDD'::text) = ( SELECT to_char(tbls_dates_master.system_date, 'YYYYMMDD'::text) AS to_char
                   FROM tbls_dates_master)) AND ((tbls_dly_fx_opening_balance.is_deleted)::text = 'N'::text) AND ((tbls_dly_fx_opening_balance.maker_checker_status)::text = 'COMMITTED'::text))) alias5
  GROUP BY alias5.currency_id, alias5.products_code, alias5.repository_id;


--
--

CREATE VIEW vbls_uob_deal_entries AS
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
    vbls_bkn_deal_entries.lcu_setl_eqv_amount
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
    vbls_fx_deal_entries.lcu_setl_eqv_amount
   FROM vbls_fx_deal_entries;


--
--

CREATE VIEW vbls_view_credit_limits AS
 SELECT alias27.fin_id,
    alias27.tenor_name,
    alias27.limit_utilisation,
    alias27.tenor_buckets_id,
    alias27.products_code,
    alias27.type,
    alias27.opn,
    alias27.currencies_id,
    alias27.cels_code,
    alias27.tenor,
    alias27.sort_order,
    alias27.current_date1,
    alias27.allocated_start_date,
    alias27.allocated_expiry_date
   FROM ( SELECT ((((((((((a.fin_id)::text || '_'::text) || (b.cels_code)::text) || '_'::text) || (b.products_code)::text) || '_'::text) || (b.type)::text) || '_'::text) || substr(((a.current_date1)::character varying)::text, 2, 8)) || (b.opn)::text) AS fin_id,
            a.name AS tenor_name,
            sum(b.utilised_amount) AS limit_utilisation,
            a.tenor_buckets_id,
            b.products_code,
            b.type,
            b.opn,
            b.currency_id AS currencies_id,
            b.cels_code,
                CASE
                    WHEN (substr((a.tenor_buckets_id)::text, '-4'::integer) = 'WEEK'::text) THEN (substr(((a.start_date)::character varying)::text, 0, 9))::character varying
                    ELSE a.tenor_buckets_id
                END AS tenor,
            a.sort_order,
            to_date(to_char(a.current_date1, 'YYYYMMDD'::text), 'YYYYMMDD'::text) AS current_date1,
            a.start_date AS allocated_start_date,
            a.end_date AS allocated_expiry_date
           FROM tbls_limits_utlsation_dates a,
            tbls_limits_utilisation b
          WHERE (((a.name)::text = 'OVERNIGHT'::text) AND ((((b.type)::text = 'SETL'::text) AND ((b.opn)::text = 'START'::text)) OR ((NOT (((b.type)::text = 'SETL'::text) AND ((b.opn)::text = 'START'::text))) AND (to_char(b.utilisation_date, 'YYYYMMDD'::text) >= to_char(a.start_date, 'YYYYMMDD'::text)))) AND ((b.is_deleted)::text <> 'Y'::text) AND (to_char(b.utilisation_date, 'YYYYMMDD'::text) < to_char(a.end_date, 'YYYYMMDD'::text)))
          GROUP BY b.products_code, b.cels_code, a.fin_id, b.opn, a.start_date, a.sort_order, a.current_date1, b.type, b.currency_id, a.tenor_buckets_id, a.name, a.end_date
        UNION ALL
         SELECT ((((((((((a.fin_id)::text || '_'::text) || (b.cels_code)::text) || '_'::text) || (b.products_code)::text) || '_'::text) || (b.type)::text) || '_'::text) || substr(((a.current_date1)::character varying)::text, 2, 8)) || (b.opn)::text) AS fin_id,
            a.name AS tenor_name,
            sum(b.utilised_amount) AS limit_utilisation,
            a.tenor_buckets_id,
            b.products_code,
            b.type,
            b.opn,
            b.currency_id AS currencies_id,
            b.cels_code,
                CASE
                    WHEN (substr((a.tenor_buckets_id)::text, '-4'::integer) = 'WEEK'::text) THEN (substr(((a.start_date)::character varying)::text, 0, 9))::character varying
                    ELSE a.tenor_buckets_id
                END AS tenor,
            a.sort_order,
            to_date(to_char(a.current_date1, 'YYYYMMDD'::text), 'YYYYMMDD'::text) AS current_date1,
            a.start_date AS allocated_start_date,
            a.end_date AS allocated_expiry_date
           FROM tbls_limits_utlsation_dates a,
            tbls_limits_utilisation b
          WHERE ((to_char(b.utilisation_date, 'YYYYMMDD'::text) >= to_char(a.start_date, 'YYYYMMDD'::text)) AND ((a.name)::text <> 'OVERNIGHT'::text) AND ((b.is_deleted)::text <> 'Y'::text) AND (to_char(b.utilisation_date, 'YYYYMMDD'::text) < to_char(a.end_date, 'YYYYMMDD'::text)))
          GROUP BY b.products_code, b.cels_code, a.fin_id, b.opn, a.start_date, a.sort_order, a.current_date1, b.type, b.currency_id, a.tenor_buckets_id, a.name, a.end_date) alias27
  ORDER BY alias27.sort_order;


--
--

CREATE VIEW vbls_view_credit_limits_alloc AS
 SELECT (((((((a.products_code)::text || '_'::text) || (a.cels_code)::text) || '_'::text) || (a.tenor_buckets_id)::text) || '_'::text) || to_date(to_char((a.current_date1)::timestamp with time zone, 'YYYYMMDD'::text), 'YYYYMMDD'::text)) AS fin_id,
    a.tenor_name,
    a.tenor_buckets_id,
    a.type,
    sum(a.limit_utilisation) AS limit_utilisation,
    a.cels_code,
    a.products_code,
    to_date(to_char((a.current_date1)::timestamp with time zone, 'YYYYMMDD'::text), 'YYYYMMDD'::text) AS current_date1,
    COALESCE(b.allocated_amount, (0)::numeric) AS amount,
    b.allocated_start_date,
    b.allocated_expiry_date
   FROM vbls_view_credit_limits a,
    tbls_allocated_limits b
  WHERE (((a.tenor_buckets_id)::text = (b.tenor_buckets_id)::text) AND ((a.cels_code)::text = (b.cels_code)::text) AND ((a.products_code)::text = (b.products_code)::text))
  GROUP BY a.tenor_buckets_id, a.type, a.cels_code, a.products_code, b.allocated_amount, b.allocated_start_date, b.allocated_expiry_date, (to_date(to_char((a.current_date1)::timestamp with time zone, 'YYYYMMDD'::text), 'YYYYMMDD'::text)), a.tenor_name;


--
--

ALTER TABLE ONLY tbls_maker_checker_data
    ADD CONSTRAINT "TBLS_MAKER_CHECKER_DATA_pkey" PRIMARY KEY (fin_id);


--
--

ALTER TABLE ONLY tbls_msg_history_content
    ADD CONSTRAINT "TBLS_MSG_HISTORY_CONTENT_pkey" PRIMARY KEY (fin_id);


--
--

ALTER TABLE ONLY tbls_acc_allocno
    ADD CONSTRAINT pk_bls_acc_allocno PRIMARY KEY (fin_id);


--
--

ALTER TABLE ONLY tbls_acc_ent_his
    ADD CONSTRAINT pk_bls_acc_ent_his PRIMARY KEY (fin_id);


--
--

ALTER TABLE ONLY tbls_acc_entries_table
    ADD CONSTRAINT pk_bls_acc_entries_table PRIMARY KEY (fin_id);


--
--

ALTER TABLE ONLY tbls_acc_main_ledger
    ADD CONSTRAINT pk_bls_acc_main_ledger PRIMARY KEY (fin_id);


--
--

ALTER TABLE ONLY tbls_acc_rules
    ADD CONSTRAINT pk_bls_acc_rules PRIMARY KEY (fin_id);


--
--

ALTER TABLE ONLY tbls_acc_sub_ledger
    ADD CONSTRAINT pk_bls_acc_sub_ledger PRIMARY KEY (fin_id);


--
--

ALTER TABLE ONLY tbls_airports
    ADD CONSTRAINT pk_bls_airports PRIMARY KEY (fin_id);


--
--

ALTER TABLE ONLY tbls_allocated_limits
    ADD CONSTRAINT pk_bls_allocated_limits PRIMARY KEY (fin_id);


--
--

ALTER TABLE ONLY tbls_assets
    ADD CONSTRAINT pk_bls_assets PRIMARY KEY (fin_id);


--
--

ALTER TABLE ONLY tbls_audit_deal_numbers
    ADD CONSTRAINT pk_bls_audit_deal_numbers PRIMARY KEY (fin_id);


--
--

ALTER TABLE ONLY tbls_audit_dl_no_his
    ADD CONSTRAINT pk_bls_audit_dl_no_his PRIMARY KEY (fin_id);


--
--

ALTER TABLE ONLY tbls_audit_trail
    ADD CONSTRAINT pk_bls_audit_trail PRIMARY KEY (fin_id);


--
--

ALTER TABLE ONLY tbls_bank_notes_deals
    ADD CONSTRAINT pk_bls_bank_notes_deals PRIMARY KEY (fin_id);


--
--

ALTER TABLE ONLY tbls_bank_notes_deals_legs
    ADD CONSTRAINT pk_bls_bank_notes_deals_legs PRIMARY KEY (fin_id);


--
--

ALTER TABLE ONLY tbls_bank_notes_denoms
    ADD CONSTRAINT pk_bls_bank_notes_denoms PRIMARY KEY (fin_id);


--
--

ALTER TABLE ONLY tbls_bank_notes_orders
    ADD CONSTRAINT pk_bls_bank_notes_orders PRIMARY KEY (fin_id);


--
--

ALTER TABLE ONLY tbls_bank_notes_orders_legs
    ADD CONSTRAINT pk_bls_bank_notes_orders_legs PRIMARY KEY (fin_id);


--
--

ALTER TABLE ONLY tbls_bank_notes_types
    ADD CONSTRAINT pk_bls_bank_notes_types PRIMARY KEY (fin_id);


--
--

ALTER TABLE ONLY tbls_bls_closing_spot_rates
    ADD CONSTRAINT pk_bls_bls_closing_spot_rates PRIMARY KEY (fin_id);


--
--

ALTER TABLE ONLY tbls_bnk_deals_his
    ADD CONSTRAINT pk_bls_bnk_deals_his PRIMARY KEY (fin_id);


--
--

ALTER TABLE ONLY tbls_bnk_deals_legs_his
    ADD CONSTRAINT pk_bls_bnk_deals_legs_his PRIMARY KEY (fin_id);


--
--

ALTER TABLE ONLY tbls_box_extn
    ADD CONSTRAINT pk_bls_box_extn PRIMARY KEY (fin_id);


--
--

ALTER TABLE ONLY tbls_box_market_int
    ADD CONSTRAINT pk_bls_box_market_int PRIMARY KEY (fin_id);


--
--

ALTER TABLE ONLY tbls_box_types
    ADD CONSTRAINT pk_bls_box_types PRIMARY KEY (fin_id);


--
--

ALTER TABLE ONLY tbls_branches
    ADD CONSTRAINT pk_bls_branches PRIMARY KEY (fin_id);


--
--

ALTER TABLE ONLY tbls_calendar_hols
    ADD CONSTRAINT pk_bls_calendar_hols PRIMARY KEY (fin_id);


--
--

ALTER TABLE ONLY tbls_calendars
    ADD CONSTRAINT pk_bls_calendars PRIMARY KEY (fin_id);


--
--

ALTER TABLE ONLY tbls_carrier_contacts_extn
    ADD CONSTRAINT pk_bls_carrier_contacts_extn PRIMARY KEY (fin_id);


--
--

ALTER TABLE ONLY tbls_carrier_crew_extn
    ADD CONSTRAINT pk_bls_carrier_crew_extn PRIMARY KEY (fin_id);


--
--

ALTER TABLE ONLY tbls_carriers
    ADD CONSTRAINT pk_bls_carriers PRIMARY KEY (fin_id);


--
--

ALTER TABLE ONLY tbls_cif_cust_classification
    ADD CONSTRAINT pk_bls_cif_cust_classification PRIMARY KEY (fin_id);


--
--

ALTER TABLE ONLY tbls_cif_id_types
    ADD CONSTRAINT pk_bls_cif_id_types PRIMARY KEY (fin_id);


--
--

ALTER TABLE ONLY tbls_cities
    ADD CONSTRAINT pk_bls_cities PRIMARY KEY (fin_id);


--
--

ALTER TABLE ONLY tbls_commissions
    ADD CONSTRAINT pk_bls_commissions PRIMARY KEY (fin_id);


--
--

ALTER TABLE ONLY tbls_commissions_config
    ADD CONSTRAINT pk_bls_commissions_config PRIMARY KEY (fin_id);


--
--

ALTER TABLE ONLY tbls_comms_cfg_template
    ADD CONSTRAINT pk_bls_comms_cfg_template PRIMARY KEY (fin_id);


--
--

ALTER TABLE ONLY tbls_cons_limit
    ADD CONSTRAINT pk_bls_cons_limit PRIMARY KEY (fin_id);


--
--

ALTER TABLE ONLY tbls_cons_limit_util
    ADD CONSTRAINT pk_bls_cons_limit_util PRIMARY KEY (fin_id);


--
--

ALTER TABLE ONLY tbls_consignee_branches_int
    ADD CONSTRAINT pk_bls_consignee_branches_int PRIMARY KEY (fin_id);


--
--

ALTER TABLE ONLY tbls_consignee_contacts_extn
    ADD CONSTRAINT pk_bls_consignee_contacts_extn PRIMARY KEY (fin_id);


--
--

ALTER TABLE ONLY tbls_consignees
    ADD CONSTRAINT pk_bls_consignees PRIMARY KEY (fin_id);


--
--

ALTER TABLE ONLY tbls_cost_center
    ADD CONSTRAINT pk_bls_cost_center PRIMARY KEY (fin_id);


--
--

ALTER TABLE ONLY tbls_cost_to_carry
    ADD CONSTRAINT pk_bls_cost_to_carry PRIMARY KEY (fin_id);


--
--

ALTER TABLE ONLY tbls_countries
    ADD CONSTRAINT pk_bls_countries PRIMARY KEY (fin_id);


--
--

ALTER TABLE ONLY tbls_credit_limits_reporting
    ADD CONSTRAINT pk_bls_credit_limits_reporting PRIMARY KEY (fin_id);


--
--

ALTER TABLE ONLY tbls_credit_owner_types
    ADD CONSTRAINT pk_bls_credit_owner_types PRIMARY KEY (fin_id);


--
--

ALTER TABLE ONLY tbls_currencies
    ADD CONSTRAINT pk_bls_currencies PRIMARY KEY (fin_id);


--
--

ALTER TABLE ONLY tbls_currency_cutoffs
    ADD CONSTRAINT pk_bls_currency_cutoffs PRIMARY KEY (fin_id);


--
--

ALTER TABLE ONLY tbls_currencypairs
    ADD CONSTRAINT pk_bls_currencypairs PRIMARY KEY (fin_id);


--
--

ALTER TABLE ONLY tbls_cust_margin_int
    ADD CONSTRAINT pk_bls_cust_margin_int PRIMARY KEY (fin_id);


--
--

ALTER TABLE ONLY tbls_cust_rate_mappings_int
    ADD CONSTRAINT pk_bls_cust_rate_mappings_int PRIMARY KEY (fin_id);


--
--

ALTER TABLE ONLY tbls_customer_cons_balance
    ADD CONSTRAINT pk_bls_customer_cons_balance PRIMARY KEY (fin_id);


--
--

ALTER TABLE ONLY tbls_customer_types
    ADD CONSTRAINT pk_bls_customer_types PRIMARY KEY (fin_id);


--
--

ALTER TABLE ONLY tbls_customers
    ADD CONSTRAINT pk_bls_customers PRIMARY KEY (fin_id);


--
--

ALTER TABLE ONLY tbls_customers_acc_address
    ADD CONSTRAINT pk_bls_customers_acc_address PRIMARY KEY (fin_id);


--
--

ALTER TABLE ONLY tbls_customers_aml
    ADD CONSTRAINT pk_bls_customers_aml PRIMARY KEY (fin_id);


--
--

ALTER TABLE ONLY tbls_customers_msg_config
    ADD CONSTRAINT pk_bls_customers_msg_config PRIMARY KEY (fin_id);


--
--

ALTER TABLE ONLY tbls_daily_funding_open_bal
    ADD CONSTRAINT pk_bls_daily_funding_open_bal PRIMARY KEY (fin_id);


--
--

ALTER TABLE ONLY tbls_daily_pl
    ADD CONSTRAINT pk_bls_daily_pl PRIMARY KEY (fin_id);


--
--

ALTER TABLE ONLY tbls_dates_master
    ADD CONSTRAINT pk_bls_dates_master PRIMARY KEY (fin_id);


--
--

ALTER TABLE ONLY tbls_deal_comm_ssi
    ADD CONSTRAINT pk_bls_deal_comm_ssi PRIMARY KEY (fin_id);


--
--

ALTER TABLE ONLY tbls_deal_comm_ssi_his
    ADD CONSTRAINT pk_bls_deal_comm_ssi_his PRIMARY KEY (fin_id);


--
--

ALTER TABLE ONLY tbls_deal_edit_reason_codes
    ADD CONSTRAINT pk_bls_deal_edit_reason_codes PRIMARY KEY (fin_id);


--
--

ALTER TABLE ONLY tbls_deal_ssi
    ADD CONSTRAINT pk_bls_deal_ssi PRIMARY KEY (fin_id);


--
--

ALTER TABLE ONLY tbls_deal_ssi_his
    ADD CONSTRAINT pk_bls_deal_ssi_his PRIMARY KEY (fin_id);


--
--

ALTER TABLE ONLY tbls_deal_status_trail
    ADD CONSTRAINT pk_bls_deal_status_trail PRIMARY KEY (fin_id);


--
--

ALTER TABLE ONLY tbls_deal_status_trail_his
    ADD CONSTRAINT pk_bls_deal_status_trail_his PRIMARY KEY (fin_id);


--
--

ALTER TABLE ONLY tbls_deal_upload_info
    ADD CONSTRAINT pk_bls_deal_upload_info PRIMARY KEY (fin_id);


--
--

ALTER TABLE ONLY tbls_deal_versions
    ADD CONSTRAINT pk_bls_deal_versions PRIMARY KEY (fin_id);


--
--

ALTER TABLE ONLY tbls_deal_versions_his
    ADD CONSTRAINT pk_bls_deal_versions_his PRIMARY KEY (fin_id);


--
--

ALTER TABLE ONLY tbls_deals
    ADD CONSTRAINT pk_bls_deals PRIMARY KEY (fin_id);


--
--

ALTER TABLE ONLY tbls_deals_his
    ADD CONSTRAINT pk_bls_deals_his PRIMARY KEY (fin_id);


--
--

ALTER TABLE ONLY tbls_deals_status
    ADD CONSTRAINT pk_bls_deals_status PRIMARY KEY (fin_id);


--
--

ALTER TABLE ONLY tbls_deals_status_his
    ADD CONSTRAINT pk_bls_deals_status_his PRIMARY KEY (fin_id);


--
--

ALTER TABLE ONLY tbls_dealwise_eod_pl
    ADD CONSTRAINT pk_bls_dealwise_eod_pl PRIMARY KEY (fin_id);


--
--

ALTER TABLE ONLY tbls_disc_record_deal_int
    ADD CONSTRAINT pk_bls_disc_record_deal_int PRIMARY KEY (fin_id);


--
--

ALTER TABLE ONLY tbls_disc_settlement_methods
    ADD CONSTRAINT pk_bls_disc_settlement_methods PRIMARY KEY (fin_id);


--
--

ALTER TABLE ONLY tbls_discrepancy_record_legs
    ADD CONSTRAINT pk_bls_discrepancy_record_legs PRIMARY KEY (fin_id);


--
--

ALTER TABLE ONLY tbls_discrepancy_types
    ADD CONSTRAINT pk_bls_discrepancy_types PRIMARY KEY (fin_id);


--
--

ALTER TABLE ONLY tbls_dl_order_source
    ADD CONSTRAINT pk_bls_dl_order_source PRIMARY KEY (fin_id);


--
--

ALTER TABLE ONLY tbls_dealwise_eod_pl_his
    ADD CONSTRAINT pk_bls_dlwise_eod_pl_his PRIMARY KEY (fin_id);


--
--

ALTER TABLE ONLY tbls_dly_accounting_balance
    ADD CONSTRAINT pk_bls_dly_accounting_balance PRIMARY KEY (fin_id);


--
--

ALTER TABLE ONLY tbls_dly_fx_opening_balance
    ADD CONSTRAINT pk_bls_dly_fx_opening_balance PRIMARY KEY (fin_id);


--
--

ALTER TABLE ONLY tbls_document_modes
    ADD CONSTRAINT pk_bls_document_modes PRIMARY KEY (fin_id);


--
--

ALTER TABLE ONLY tbls_email_configuration
    ADD CONSTRAINT pk_bls_email_configuration PRIMARY KEY (fin_id);


--
--

ALTER TABLE ONLY tbls_eod_sanity_checks
    ADD CONSTRAINT pk_bls_eod_sanity_checks PRIMARY KEY (fin_id);


--
--

ALTER TABLE ONLY tbls_ermctc_report
    ADD CONSTRAINT pk_bls_ermctc_report PRIMARY KEY (fin_id);


--
--

ALTER TABLE ONLY tbls_ext_cons_brnch_map
    ADD CONSTRAINT pk_bls_ext_cons_brnch_map PRIMARY KEY (fin_id);


--
--

ALTER TABLE ONLY tbls_functions
    ADD CONSTRAINT pk_bls_functions PRIMARY KEY (fin_id);


--
--

ALTER TABLE ONLY tbls_funding_positions
    ADD CONSTRAINT pk_bls_funding_positions PRIMARY KEY (fin_id);


--
--

ALTER TABLE ONLY tbls_fx_deals
    ADD CONSTRAINT pk_bls_fx_deals PRIMARY KEY (fin_id);


--
--

ALTER TABLE ONLY tbls_fx_overnight_limits
    ADD CONSTRAINT pk_bls_fx_overnight_limits PRIMARY KEY (fin_id);


--
--

ALTER TABLE ONLY tbls_fx_positions
    ADD CONSTRAINT pk_bls_fx_positions PRIMARY KEY (fin_id);


--
--

ALTER TABLE ONLY tbls_fx_positions_history
    ADD CONSTRAINT pk_bls_fx_positions_history PRIMARY KEY (fin_id);


--
--

ALTER TABLE ONLY tbls_fxforward_rates_his
    ADD CONSTRAINT pk_bls_fxforward_his PRIMARY KEY (fin_id);


--
--

ALTER TABLE ONLY tbls_fxforward_rates
    ADD CONSTRAINT pk_bls_fxforward_rates PRIMARY KEY (fin_id);


--
--

ALTER TABLE ONLY tbls_fxnopvol_hist
    ADD CONSTRAINT pk_bls_fxnopvol_hist PRIMARY KEY (fin_id);


--
--

ALTER TABLE ONLY tbls_fxspot_rates
    ADD CONSTRAINT pk_bls_fxspot_rates PRIMARY KEY (fin_id);


--
--

ALTER TABLE ONLY tbls_gl_recon_input
    ADD CONSTRAINT pk_bls_gl_recon_input PRIMARY KEY (fin_id);


--
--

ALTER TABLE ONLY tbls_global_bnc
    ADD CONSTRAINT pk_bls_global_bnc PRIMARY KEY (fin_id);


--
--

ALTER TABLE ONLY tbls_hist_vol_aml
    ADD CONSTRAINT pk_bls_hist_vol_aml PRIMARY KEY (fin_id);


--
--

ALTER TABLE ONLY tbls_hist_vol_aml_int
    ADD CONSTRAINT pk_bls_hist_vol_aml_int PRIMARY KEY (fin_id);


--
--

ALTER TABLE ONLY tbls_history_cust_cmprision
    ADD CONSTRAINT pk_bls_history_cust_cmprision PRIMARY KEY (fin_id);


--
--

ALTER TABLE ONLY tbls_import_bnk_deals_legs
    ADD CONSTRAINT pk_bls_import_bnk_deals_legs PRIMARY KEY (fin_id);


--
--

ALTER TABLE ONLY tbls_import_column_config
    ADD CONSTRAINT pk_bls_import_column_config PRIMARY KEY (fin_id);


--
--

ALTER TABLE ONLY tbls_import_properties
    ADD CONSTRAINT pk_bls_import_properties PRIMARY KEY (fin_id);


--
--

ALTER TABLE ONLY tbls_import_template_config
    ADD CONSTRAINT pk_bls_import_template_config PRIMARY KEY (fin_id);


--
--

ALTER TABLE ONLY tbls_insurance_config
    ADD CONSTRAINT pk_bls_insurance_config PRIMARY KEY (fin_id);


--
--

ALTER TABLE ONLY tbls_intf_acc_add_recon_log
    ADD CONSTRAINT pk_bls_intf_acc_add_recon_log PRIMARY KEY (fin_id);


--
--

ALTER TABLE ONLY tbls_intf_cus_demo_recon_log
    ADD CONSTRAINT pk_bls_intf_cus_demo_recon_log PRIMARY KEY (fin_id);


--
--

ALTER TABLE ONLY tbls_irr_config
    ADD CONSTRAINT pk_bls_irr_config PRIMARY KEY (fin_id);


--
--

ALTER TABLE ONLY tbls_irr_config_pay_rec
    ADD CONSTRAINT pk_bls_irr_config_pay_rec PRIMARY KEY (fin_id);


--
--

ALTER TABLE ONLY tbls_like_like_base_pl_acc
    ADD CONSTRAINT pk_bls_like_like_base_pl_acc PRIMARY KEY (fin_id);


--
--

ALTER TABLE ONLY tbls_limits_breach
    ADD CONSTRAINT pk_bls_limits_breach PRIMARY KEY (fin_id);


--
--

ALTER TABLE ONLY tbls_limits_breach_data
    ADD CONSTRAINT pk_bls_limits_breach_data PRIMARY KEY (fin_id);


--
--

ALTER TABLE ONLY tbls_limits_exclusion
    ADD CONSTRAINT pk_bls_limits_exclusion PRIMARY KEY (fin_id);


--
--

ALTER TABLE ONLY tbls_limits_override
    ADD CONSTRAINT pk_bls_limits_override PRIMARY KEY (fin_id);


--
--

ALTER TABLE ONLY tbls_limits_tenor_def
    ADD CONSTRAINT pk_bls_limits_tenor_def PRIMARY KEY (fin_id);


--
--

ALTER TABLE ONLY tbls_limits_utilisation
    ADD CONSTRAINT pk_bls_limits_utilisation PRIMARY KEY (fin_id);


--
--

ALTER TABLE ONLY tbls_limits_utlsation_dates
    ADD CONSTRAINT pk_bls_limits_utlsation_dates PRIMARY KEY (fin_id);


--
--

ALTER TABLE ONLY tbls_maker_checker
    ADD CONSTRAINT pk_bls_maker_checker PRIMARY KEY (fin_id);


--
--

ALTER TABLE ONLY tbls_manual_postings
    ADD CONSTRAINT pk_bls_manual_postings PRIMARY KEY (fin_id);


--
--

ALTER TABLE ONLY tbls_margin_templates
    ADD CONSTRAINT pk_bls_margin_templates PRIMARY KEY (fin_id);


--
--

ALTER TABLE ONLY tbls_margins
    ADD CONSTRAINT pk_bls_margins PRIMARY KEY (fin_id);


--
--

ALTER TABLE ONLY tbls_margins_meta_data
    ADD CONSTRAINT pk_bls_margins_meta_data PRIMARY KEY (fin_id);


--
--

ALTER TABLE ONLY tbls_market_data_sets
    ADD CONSTRAINT pk_bls_market_data_sets PRIMARY KEY (fin_id);


--
--

ALTER TABLE ONLY tbls_market_data_sources
    ADD CONSTRAINT pk_bls_market_data_sources PRIMARY KEY (fin_id);


--
--

ALTER TABLE ONLY tbls_markets
    ADD CONSTRAINT pk_bls_markets PRIMARY KEY (fin_id);


--
--

ALTER TABLE ONLY tbls_markets_countries_int
    ADD CONSTRAINT pk_bls_markets_countries_int PRIMARY KEY (fin_id);


--
--

ALTER TABLE ONLY tbls_markets_pack_type_int
    ADD CONSTRAINT pk_bls_markets_pack_type_int PRIMARY KEY (fin_id);


--
--

ALTER TABLE ONLY tbls_messages_history
    ADD CONSTRAINT pk_bls_messages_history PRIMARY KEY (fin_id);


--
--

ALTER TABLE ONLY tbls_migrproc_group
    ADD CONSTRAINT pk_bls_migrproc_group PRIMARY KEY (fin_id);


--
--

ALTER TABLE ONLY tbls_migrproc_group_bean_int
    ADD CONSTRAINT pk_bls_migrproc_group_bean_int PRIMARY KEY (fin_id);


--
--

ALTER TABLE ONLY tbls_mm_discount_factors
    ADD CONSTRAINT pk_bls_mm_discount_factors PRIMARY KEY (fin_id);


--
--

ALTER TABLE ONLY tbls_mm_disfactors_his
    ADD CONSTRAINT pk_bls_mm_disfactors_his PRIMARY KEY (fin_id);


--
--

ALTER TABLE ONLY tbls_mm_rates
    ADD CONSTRAINT pk_bls_mm_rates PRIMARY KEY (fin_id);


--
--

ALTER TABLE ONLY tbls_mm_rates_his
    ADD CONSTRAINT pk_bls_mm_rates_his PRIMARY KEY (fin_id);


--
--

ALTER TABLE ONLY tbls_msg_configuration
    ADD CONSTRAINT pk_bls_msg_configuration PRIMARY KEY (fin_id);


--
--

ALTER TABLE ONLY tbls_msg_configv2
    ADD CONSTRAINT pk_bls_msg_configv2 PRIMARY KEY (fin_id);


--
--

ALTER TABLE ONLY tbls_msg_templates
    ADD CONSTRAINT pk_bls_msg_templates PRIMARY KEY (fin_id);


--
--

ALTER TABLE ONLY tbls_msg_types
    ADD CONSTRAINT pk_bls_msg_types PRIMARY KEY (fin_id);


--
--

ALTER TABLE ONLY tbls_mtmsg_configuration
    ADD CONSTRAINT pk_bls_mtmsg_configuration PRIMARY KEY (fin_id);


--
--

ALTER TABLE ONLY tbls_order_types
    ADD CONSTRAINT pk_bls_order_types PRIMARY KEY (fin_id);


--
--

ALTER TABLE ONLY tbls_other_charges
    ADD CONSTRAINT pk_bls_other_charges PRIMARY KEY (fin_id);


--
--

ALTER TABLE ONLY tbls_packing_list
    ADD CONSTRAINT pk_bls_packing_list PRIMARY KEY (fin_id);


--
--

ALTER TABLE ONLY tbls_packing_list_his
    ADD CONSTRAINT pk_bls_packing_list_his PRIMARY KEY (fin_id);


--
--

ALTER TABLE ONLY tbls_pl_main
    ADD CONSTRAINT pk_bls_pl_main PRIMARY KEY (fin_id);


--
--

ALTER TABLE ONLY tbls_pl_main_his
    ADD CONSTRAINT pk_bls_pl_main_his PRIMARY KEY (fin_id);


--
--

ALTER TABLE ONLY tbls_processing_inbox
    ADD CONSTRAINT pk_bls_processing_inbox PRIMARY KEY (fin_id);


--
--

ALTER TABLE ONLY tbls_products
    ADD CONSTRAINT pk_bls_products PRIMARY KEY (fin_id);


--
--

ALTER TABLE ONLY tbls_r_roles
    ADD CONSTRAINT pk_bls_r_roles PRIMARY KEY (fin_id);


--
--

ALTER TABLE ONLY tbls_r_users
    ADD CONSTRAINT pk_bls_r_users PRIMARY KEY (fin_id);


--
--

ALTER TABLE ONLY tbls_r_users_regions_int
    ADD CONSTRAINT pk_bls_r_users_regions_int PRIMARY KEY (fin_id);


--
--

ALTER TABLE ONLY tbls_rate_source_schemes
    ADD CONSTRAINT pk_bls_rate_source_schemes PRIMARY KEY (fin_id);


--
--

ALTER TABLE ONLY tbls_rate_sources
    ADD CONSTRAINT pk_bls_rate_sources PRIMARY KEY (fin_id);


--
--

ALTER TABLE ONLY tbls_rate_src_schemes_data
    ADD CONSTRAINT pk_bls_rate_src_schemes_data PRIMARY KEY (fin_id);


--
--

ALTER TABLE ONLY tbls_rates_tolerance
    ADD CONSTRAINT pk_bls_rates_tolerance PRIMARY KEY (fin_id);


--
--

ALTER TABLE ONLY tbls_regions
    ADD CONSTRAINT pk_bls_regions PRIMARY KEY (fin_id);


--
--

ALTER TABLE ONLY tbls_reports_config
    ADD CONSTRAINT pk_bls_reports_config PRIMARY KEY (fin_id);


--
--

ALTER TABLE ONLY tbls_reports_param
    ADD CONSTRAINT pk_bls_reports_param PRIMARY KEY (fin_id);


--
--

ALTER TABLE ONLY tbls_repositories
    ADD CONSTRAINT pk_bls_repositories PRIMARY KEY (fin_id);


--
--

ALTER TABLE ONLY tbls_repositories_extn
    ADD CONSTRAINT pk_bls_repositories_extn PRIMARY KEY (fin_id);


--
--

ALTER TABLE ONLY tbls_repositories_prdcts_int
    ADD CONSTRAINT pk_bls_repositories_prdcts_int PRIMARY KEY (fin_id);


--
--

ALTER TABLE ONLY tbls_repositories_users_int
    ADD CONSTRAINT pk_bls_repositories_users_int PRIMARY KEY (fin_id);


--
--

ALTER TABLE ONLY tbls_sdis
    ADD CONSTRAINT pk_bls_sdis PRIMARY KEY (fin_id);


--
--

ALTER TABLE ONLY tbls_service_account_types
    ADD CONSTRAINT pk_bls_service_account_types PRIMARY KEY (fin_id);


--
--

ALTER TABLE ONLY tbls_service_categories
    ADD CONSTRAINT pk_bls_service_categories PRIMARY KEY (fin_id);


--
--

ALTER TABLE ONLY tbls_service_charges
    ADD CONSTRAINT pk_bls_service_charges PRIMARY KEY (fin_id);


--
--

ALTER TABLE ONLY tbls_service_providers
    ADD CONSTRAINT pk_bls_service_providers PRIMARY KEY (fin_id);


--
--

ALTER TABLE ONLY tbls_settlement_modes
    ADD CONSTRAINT pk_bls_settlement_modes PRIMARY KEY (fin_id);


--
--

ALTER TABLE ONLY tbls_settlements
    ADD CONSTRAINT pk_bls_settlements PRIMARY KEY (fin_id);


--
--

ALTER TABLE ONLY tbls_settlements_his
    ADD CONSTRAINT pk_bls_settlements_his PRIMARY KEY (fin_id);


--
--

ALTER TABLE ONLY tbls_settlements_netted
    ADD CONSTRAINT pk_bls_settlements_netted PRIMARY KEY (fin_id);


--
--

ALTER TABLE ONLY tbls_sh_record_routing_his
    ADD CONSTRAINT pk_bls_sh_record_routing_his PRIMARY KEY (fin_id);


--
--

ALTER TABLE ONLY tbls_sh_rtn_charges_his
    ADD CONSTRAINT pk_bls_sh_rtn_charges_his PRIMARY KEY (fin_id);


--
--

ALTER TABLE ONLY tbls_shipment_arrangements
    ADD CONSTRAINT pk_bls_shipment_arrangements PRIMARY KEY (fin_id);


--
--

ALTER TABLE ONLY tbls_shipment_basis
    ADD CONSTRAINT pk_bls_shipment_basis PRIMARY KEY (fin_id);


--
--

ALTER TABLE ONLY tbls_shipment_charges
    ADD CONSTRAINT pk_bls_shipment_charges PRIMARY KEY (fin_id);


--
--

ALTER TABLE ONLY tbls_shipment_charges_his
    ADD CONSTRAINT pk_bls_shipment_charges_his PRIMARY KEY (fin_id);


--
--

ALTER TABLE ONLY tbls_shipment_docs_generated
    ADD CONSTRAINT pk_bls_shipment_docs_generated PRIMARY KEY (fin_id);


--
--

ALTER TABLE ONLY tbls_shipment_methods
    ADD CONSTRAINT pk_bls_shipment_methods PRIMARY KEY (fin_id);


--
--

ALTER TABLE ONLY tbls_shipment_record_routing
    ADD CONSTRAINT pk_bls_shipment_record_routing PRIMARY KEY (fin_id);


--
--

ALTER TABLE ONLY tbls_shipment_records
    ADD CONSTRAINT pk_bls_shipment_records PRIMARY KEY (fin_id);


--
--

ALTER TABLE ONLY tbls_shipment_records_his
    ADD CONSTRAINT pk_bls_shipment_records_his PRIMARY KEY (fin_id);


--
--

ALTER TABLE ONLY tbls_shipment_rtn_charges
    ADD CONSTRAINT pk_bls_shipment_rtn_charges PRIMARY KEY (fin_id);


--
--

ALTER TABLE ONLY tbls_shipment_schedules
    ADD CONSTRAINT pk_bls_shipment_schedules PRIMARY KEY (fin_id);


--
--

ALTER TABLE ONLY tbls_shipment_types
    ADD CONSTRAINT pk_bls_shipment_types PRIMARY KEY (fin_id);


--
--

ALTER TABLE ONLY tbls_shipping_documents
    ADD CONSTRAINT pk_bls_shipping_documents PRIMARY KEY (fin_id);


--
--

ALTER TABLE ONLY tbls_shipping_status_config
    ADD CONSTRAINT pk_bls_shipping_status_config PRIMARY KEY (fin_id);


--
--

ALTER TABLE ONLY tbls_ssi_rules
    ADD CONSTRAINT pk_bls_ssi_rules PRIMARY KEY (fin_id);


--
--

ALTER TABLE ONLY tbls_ssis_nv
    ADD CONSTRAINT pk_bls_ssis_nv PRIMARY KEY (fin_id);


--
--

ALTER TABLE ONLY tbls_staff
    ADD CONSTRAINT pk_bls_staff PRIMARY KEY (fin_id);


--
--

ALTER TABLE ONLY tbls_svc_charge_prvder_int
    ADD CONSTRAINT pk_bls_svc_charge_prvder_int PRIMARY KEY (fin_id);


--
--

ALTER TABLE ONLY tbls_svc_provider_acc_int
    ADD CONSTRAINT pk_bls_svc_provider_acc_int PRIMARY KEY (fin_id);


--
--

ALTER TABLE ONLY tbls_svc_prvder_categories
    ADD CONSTRAINT pk_bls_svc_prvder_categories PRIMARY KEY (fin_id);


--
--

ALTER TABLE ONLY tbls_svc_prvder_ctgry_int
    ADD CONSTRAINT pk_bls_svc_prvder_ctgry_int PRIMARY KEY (fin_id);


--
--

ALTER TABLE ONLY tbls_sys_parameters
    ADD CONSTRAINT pk_bls_sys_parameters PRIMARY KEY (fin_id);


--
--

ALTER TABLE ONLY tbls_system_codes
    ADD CONSTRAINT pk_bls_system_codes PRIMARY KEY (fin_id);


--
--

ALTER TABLE ONLY tbls_tact_rates
    ADD CONSTRAINT pk_bls_tact_rates PRIMARY KEY (fin_id);


--
--

ALTER TABLE ONLY tbls_turnover_pl
    ADD CONSTRAINT pk_bls_turnover_pl PRIMARY KEY (fin_id);


--
--

ALTER TABLE ONLY tbls_ud_deal_types
    ADD CONSTRAINT pk_bls_ud_deal_types PRIMARY KEY (fin_id);


--
--

ALTER TABLE ONLY tbls_ud_dt_mapping
    ADD CONSTRAINT pk_bls_ud_dt_mapping PRIMARY KEY (fin_id);


--
--

ALTER TABLE ONLY tbls_ud_dt_rpt_mapping
    ADD CONSTRAINT pk_bls_ud_dt_rpt_mapping PRIMARY KEY (fin_id);


--
--

ALTER TABLE ONLY tbls_users_markets_int
    ADD CONSTRAINT pk_bls_users_markets_int PRIMARY KEY (fin_id);


--
--

ALTER TABLE ONLY tbls_vaults
    ADD CONSTRAINT pk_bls_vaults PRIMARY KEY (fin_id);


--
--

ALTER TABLE ONLY tbls_vaults_inv_cash
    ADD CONSTRAINT pk_bls_vaults_inv_cash PRIMARY KEY (fin_id);


--
--

ALTER TABLE ONLY tbls_workflow_states
    ADD CONSTRAINT pk_bls_workflow_states PRIMARY KEY (fin_id);


--
--

ALTER TABLE ONLY tbls_wrkflow_state_trans
    ADD CONSTRAINT pk_bls_wrkflow_state_trans PRIMARY KEY (fin_id);


--
--

ALTER TABLE ONLY tbls_wss_positions
    ADD CONSTRAINT pk_bls_wss_positions PRIMARY KEY (fin_id);


--
--

ALTER TABLE ONLY tbls_dly_fx_open_bal_tmp
    ADD CONSTRAINT sys_c0013468 PRIMARY KEY (fin_id);


--
--

ALTER TABLE ONLY tbls_vault_state_trans
    ADD CONSTRAINT sys_c0013824 PRIMARY KEY (fin_id);


--
--

ALTER TABLE ONLY tbls_houskeep_cfg
    ADD CONSTRAINT sys_c0014083 PRIMARY KEY (fin_id);


--
--

ALTER TABLE ONLY tbls_standard_pack_cfg
    ADD CONSTRAINT sys_c0014784 PRIMARY KEY (fin_id);


--
--

ALTER TABLE ONLY tbls_msg_pagination_cfg
    ADD CONSTRAINT sys_c0014854 PRIMARY KEY (fin_id);


--
--

ALTER TABLE ONLY tbls_trans_hs_keep
    ADD CONSTRAINT sys_c0015761 PRIMARY KEY (fin_id);


--
--

ALTER TABLE ONLY tbls_svc_prvder_cnts_extn
    ADD CONSTRAINT sys_c0015911 PRIMARY KEY (fin_id);


--
--

ALTER TABLE ONLY tbls_limits_breach_ear
    ADD CONSTRAINT sys_c0016336 PRIMARY KEY (fin_id);


--
--

ALTER TABLE ONLY tbls_aml_alerts_comment_his
    ADD CONSTRAINT tbls_aml_alerts_comment_his_pkey PRIMARY KEY (fin_id);


--
--

ALTER TABLE ONLY tbls_aml_breach_alerts
    ADD CONSTRAINT tbls_aml_breach_alerts_pk PRIMARY KEY (fin_id);


--
--

ALTER TABLE ONLY tbls_discrepancy_records
    ADD CONSTRAINT tbls_discrepancy_records_pkey PRIMARY KEY (fin_id);


--
--

ALTER TABLE ONLY tbls_eod_progress
    ADD CONSTRAINT tbls_eod_progress_pkey PRIMARY KEY (fin_id);


--
--

ALTER TABLE ONLY tbls_messages_history_his
    ADD CONSTRAINT tbls_messages_history_his_pkey PRIMARY KEY (fin_id);


--
--

ALTER TABLE ONLY tbls_msg_history_content_his
    ADD CONSTRAINT tbls_msg_history_content_his_pkey PRIMARY KEY (fin_id);


--
--

ALTER TABLE ONLY tbls_discrepancy_records
    ADD CONSTRAINT uk1_bls_discrepancy_records UNIQUE (external_no);


--
--

ALTER TABLE ONLY tbls_reports_config
    ADD CONSTRAINT uk1_bls_reports_config UNIQUE (report_code);


--
--

ALTER TABLE ONLY tbls_deals
    ADD CONSTRAINT uk2_bls_deals UNIQUE (external_deal_no);


--
--

ALTER TABLE ONLY tbls_bank_notes_orders
    ADD CONSTRAINT uk_bls_bank_notes_orders UNIQUE (order_no);


--
--

ALTER TABLE ONLY tbls_deals
    ADD CONSTRAINT uk_bls_deals UNIQUE (deal_no);


--
--

CREATE INDEX tbls_aml_alerts_comment_his_idx ON tbls_aml_alerts_comment_his USING btree (content);


--
--

CREATE INDEX tbls_discrepancy_records_idx ON tbls_discrepancy_records USING btree (discrepancy_contents);


--
--

CREATE INDEX tbls_eod_progress_idx ON tbls_eod_progress USING btree (exceptions);


--
--

CREATE INDEX tbls_maker_checker_data_idx ON tbls_maker_checker_data USING btree (old_object);


--
--

CREATE INDEX tbls_maker_checker_data_idx001 ON tbls_maker_checker_data USING btree (new_object);


--
--

CREATE INDEX tbls_messages_history_his_idx ON tbls_messages_history_his USING btree (msg_contents);


--
--

CREATE INDEX tbls_msg_history_content_his_idx ON tbls_msg_history_content_his USING btree (msg_contents);


--
--

CREATE INDEX tbls_msg_history_content_idx ON tbls_msg_history_content USING btree (msg_contents);


--
--

CREATE INDEX xbls_acc_entries_table002 ON tbls_acc_entries_table USING btree (((((deal_no)::text || '_'::text) || (number_to_char(version_no))::text)), description);


--
--

CREATE INDEX xbls_acc_entries_table003 ON tbls_acc_entries_table USING btree (timestamp_to_char(entry_date));


--
--

CREATE INDEX xbls_acc_main_ledger001 ON tbls_acc_main_ledger USING btree (acc_type);


--
--

CREATE INDEX xbls_acc_sub_ledger001 ON tbls_acc_sub_ledger USING btree (main_ledger_id);


--
--

CREATE INDEX xbls_airport001 ON tbls_airports USING btree (cities_id);


--
--

CREATE INDEX xbls_allocated_limits001 ON tbls_allocated_limits USING btree (cels_code);


--
--

CREATE INDEX xbls_bank_notes_deals001 ON tbls_bank_notes_deals USING btree (timestamp_to_char(vault_date));


--
--

CREATE INDEX xbls_bank_notes_deals002 ON tbls_bank_notes_deals USING btree (timestamp_to_char(release_date));


--
--

CREATE INDEX xbls_bank_notes_deals_legs001 ON tbls_bank_notes_deals_legs USING btree (bank_notes_deals_id);


--
--

CREATE INDEX xbls_bank_notes_denom001 ON tbls_bank_notes_denoms USING btree (currencies_id);


--
--

CREATE INDEX xbls_bls_closing_spot_rates001 ON tbls_bls_closing_spot_rates USING btree (mkt_date);


--
--

CREATE INDEX xbls_branchs001 ON tbls_branches USING btree (short_name);


--
--

CREATE INDEX xbls_branchs002 ON tbls_branches USING btree (cust_id);


--
--

CREATE INDEX xbls_cites001 ON tbls_cities USING btree (code);


--
--

CREATE INDEX xbls_cites002 ON tbls_cities USING btree (countries_id);


--
--

CREATE INDEX xbls_currencypairs001 ON tbls_currencypairs USING btree (currency1_id);


--
--

CREATE INDEX xbls_currencypairs002 ON tbls_currencypairs USING btree (currency2_id);


--
--

CREATE INDEX xbls_customers001 ON tbls_customers USING btree (short_name);


--
--

CREATE INDEX xbls_customers_acc_address001 ON tbls_customers_acc_address USING btree (cust_id);


--
--

CREATE INDEX xbls_daily_funding_open_bal003 ON tbls_daily_funding_open_bal USING btree (currency_id);


--
--

CREATE INDEX xbls_daily_funding_open_bal004 ON tbls_daily_funding_open_bal USING btree (timestamp_to_char(past_date));


--
--

CREATE INDEX xbls_daily_pl003 ON tbls_daily_pl USING btree (currency_id);


--
--

CREATE INDEX xbls_daily_pl004 ON tbls_daily_pl USING btree (timestamp_to_char(pl_date));


--
--

CREATE INDEX xbls_deal_ssi001 ON tbls_deal_ssi USING btree (deal_versions_id);


--
--

CREATE INDEX xbls_deal_ssi002 ON tbls_deal_ssi USING btree (ssi_rules_id);


--
--

CREATE INDEX xbls_deal_ssi003 ON tbls_deal_ssi USING btree (setl_mode_id);


--
--

CREATE INDEX xbls_deal_status_trail001 ON tbls_deal_status_trail USING btree (deal_no);


--
--

CREATE INDEX xbls_deal_versions001 ON tbls_deal_versions USING btree (deals_id);


--
--

CREATE INDEX xbls_deal_versions0010 ON tbls_deal_versions USING btree (branches_id);


--
--

CREATE INDEX xbls_deal_versions004 ON tbls_deal_versions USING btree (timestamp_to_char(trade_date));


--
--

CREATE INDEX xbls_deal_versions005 ON tbls_deal_versions USING btree (timestamp_to_char(value_date));


--
--

CREATE INDEX xbls_deal_versions006 ON tbls_deal_versions USING btree (timestamp_to_char(action_date));


--
--

CREATE INDEX xbls_deal_versions009 ON tbls_deal_versions USING btree (customers_id);


--
--

CREATE INDEX xbls_deals001 ON tbls_deals USING btree (timestamp_to_char(entry_date));


--
--

CREATE INDEX xbls_deals002 ON tbls_deals USING btree (timestamp_to_char(trade_date));


--
--

CREATE INDEX xbls_deals003 ON tbls_deals USING btree (timestamp_to_char(value_date));


--
--

CREATE INDEX xbls_deals004 ON tbls_deals USING btree (timestamp_to_char(action_date));


--
--

CREATE INDEX xbls_deals007 ON tbls_deals USING btree (branches_id);


--
--

CREATE INDEX xbls_deals008 ON tbls_deals USING btree (customers_id);


--
--

CREATE INDEX xbls_deals009 ON tbls_deals USING btree (action);


--
--

CREATE INDEX xbls_deals_status001 ON tbls_deals_status USING btree (deal_status_id);


--
--

CREATE INDEX xbls_deals_status002 ON tbls_deals_status USING btree (setl_status_id);


--
--

CREATE INDEX xbls_deals_status003 ON tbls_deals_status USING btree (shipping_status_id);


--
--

CREATE INDEX xbls_deals_status004 ON tbls_deals_status USING btree (vault_status_id);


--
--

CREATE INDEX xbls_dealwise_eod_pl001 ON tbls_dealwise_eod_pl USING btree (repository_id);


--
--

CREATE INDEX xbls_dealwise_eod_pl002 ON tbls_dealwise_eod_pl USING btree (timestamp_to_char(pl_date));


--
--

CREATE INDEX xbls_dealwise_eod_pl003 ON tbls_dealwise_eod_pl USING btree (currency_id);


--
--

CREATE INDEX xbls_dly_accounting_balance001 ON tbls_dly_accounting_balance USING btree (currency_id);


--
--

CREATE INDEX xbls_dly_accounting_balance002 ON tbls_dly_accounting_balance USING btree (timestamp_to_char(reference_date));


--
--

CREATE INDEX xbls_dly_accounting_balance003 ON tbls_dly_accounting_balance USING btree (timestamp_to_char(trial_balance_date));


--
--

CREATE INDEX xbls_dly_fx_opening_balance003 ON tbls_dly_fx_opening_balance USING btree (currency_id);


--
--

CREATE INDEX xbls_dly_fx_opening_balance004 ON tbls_dly_fx_opening_balance USING btree (timestamp_to_char(past_date));


--
--

CREATE INDEX xbls_funding_positions003 ON tbls_funding_positions USING btree (currency_id);


--
--

CREATE INDEX xbls_funding_positions004 ON tbls_funding_positions USING btree (timestamp_to_char(value_date));


--
--

CREATE INDEX xbls_fx_deals001 ON tbls_fx_deals USING btree (deal_versions_id);


--
--

CREATE INDEX xbls_fx_positions_historys003 ON tbls_fx_positions_history USING btree (currency_id);


--
--

CREATE INDEX xbls_fx_positions_historys004 ON tbls_fx_positions_history USING btree (timestamp_to_char(value_date));


--
--

CREATE INDEX xbls_fx_positionss003 ON tbls_fx_positions USING btree (currency_id);


--
--

CREATE INDEX xbls_fx_positionss004 ON tbls_fx_positions USING btree (timestamp_to_char(value_date));


--
--

CREATE INDEX xbls_fxforward_rates001 ON tbls_fxforward_rates USING btree (timestamp_to_char(mkt_date));


--
--

CREATE INDEX xbls_limits_breach001 ON tbls_limits_breach USING btree (cels_code);


--
--

CREATE INDEX xbls_limits_breach002 ON tbls_limits_breach USING btree (deal_no);


--
--

CREATE INDEX xbls_messages_history001 ON tbls_messages_history USING btree (module_entity_id);


--
--

CREATE INDEX xbls_messages_history002 ON tbls_messages_history USING btree (module_entity_id, module_name);


--
--

CREATE INDEX xbls_mm_discount_factorss001 ON tbls_mm_discount_factors USING btree (timestamp_to_char(mkt_date));


--
--

CREATE INDEX xbls_mm_discount_factorss005 ON tbls_mm_discount_factors USING btree (currencies_id);


--
--

CREATE INDEX xbls_mm_ratess001 ON tbls_mm_rates USING btree (timestamp_to_char(mkt_date));


--
--

CREATE INDEX xbls_rates_tolerance002 ON tbls_rates_tolerance USING btree (currency_pair_id);


--
--

CREATE INDEX xbls_shipment_charges001 ON tbls_shipment_charges USING btree (shipment_record_id);


--
--

CREATE INDEX xbls_shipment_charges002 ON tbls_shipment_charges USING btree (service_charge_provider_int);


--
--

CREATE INDEX xbls_shipment_record_rout001 ON tbls_shipment_record_routing USING btree (shipment_record_id);


--
--

CREATE INDEX xbls_shipment_record_rout002 ON tbls_shipment_record_routing USING btree (shipment_schedule_id);


--
--

CREATE INDEX xbls_shipment_records001 ON tbls_shipment_records USING btree (shipment_method_id);


--
--

CREATE INDEX xbls_shipment_records002 ON tbls_shipment_records USING btree (shipper_id);


--
--

CREATE INDEX xbls_shipment_records003 ON tbls_shipment_records USING btree (consignees_id);


--
--

CREATE INDEX xbls_shipment_records004 ON tbls_shipment_records USING btree (shipment_type_id);


--
--

CREATE INDEX xbls_shipment_schedules001 ON tbls_shipment_schedules USING btree (carrier_id);


--
--

CREATE INDEX xbls_ssi_rules001 ON tbls_ssi_rules USING btree (customers_id);


--
--

CREATE INDEX xbls_ssi_rules002 ON tbls_ssi_rules USING btree (branches_id);


--
--

CREATE INDEX xbls_ssi_rules003 ON tbls_ssi_rules USING btree (currencies_id);


--
--

CREATE INDEX xbls_ssi_rules004 ON tbls_ssi_rules USING btree (products_code);


--
--

CREATE INDEX xbls_ssis_nv001 ON tbls_ssis_nv USING btree (currency_id);


--
--

CREATE INDEX xbls_tbls_consignees001 ON tbls_consignees USING btree (short_name);


--
--

CREATE INDEX xbls_tbls_margins001 ON tbls_margins USING btree (margin_template_id);


--
--

CREATE INDEX xbls_tbls_margins002 ON tbls_margins USING btree (bank_notes_currency);


--
--

CREATE INDEX xbls_tbls_settlements001 ON tbls_settlements USING btree (deal_versions_id);


--
--

CREATE INDEX xbls_vaults_inv_cash001 ON tbls_vaults_inv_cash USING btree (vaults_id);


--
--

CREATE INDEX xbls_vaults_inv_cash002 ON tbls_vaults_inv_cash USING btree (currencies_id);


--
--

CREATE INDEX xbls_vaults_inv_cash003 ON tbls_vaults_inv_cash USING btree (timestamp_to_char(bal_date));



