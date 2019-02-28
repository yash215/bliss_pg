--
-- Name: sq_bls_audit_trail; Type: SEQUENCE; Schema: dfuser; Owner: -
--

CREATE SEQUENCE dfuser.sq_bls_audit_trail
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: sq_bls_audit_trail_hist; Type: SEQUENCE; Schema: dfuser; Owner: -
--

CREATE SEQUENCE dfuser.sq_bls_audit_trail_hist
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: sq_bls_calendar_hols; Type: SEQUENCE; Schema: dfuser; Owner: -
--

CREATE SEQUENCE dfuser.sq_bls_calendar_hols
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: sq_bls_processing_inbox; Type: SEQUENCE; Schema: dfuser; Owner: -
--

CREATE SEQUENCE dfuser.sq_bls_processing_inbox
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: tbls_audit_trail; Type: TABLE; Schema: dfuser; Owner: -
--

CREATE TABLE dfuser.tbls_audit_trail (
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
    shadow_id character varying(60) DEFAULT ''::character varying NOT NULL,
    parameters character varying(1800),
    audit_date timestamp(0) without time zone,
    region_id character varying(60)
);


--
-- Name: tbls_audit_trail_hist; Type: TABLE; Schema: dfuser; Owner: -
--

CREATE TABLE dfuser.tbls_audit_trail_hist (
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
-- Name: tbls_calendar_hols; Type: TABLE; Schema: dfuser; Owner: -
--

CREATE TABLE dfuser.tbls_calendar_hols (
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
    shadow_id character varying(60) DEFAULT ''::character varying NOT NULL
);


--
-- Name: tbls_calendars; Type: TABLE; Schema: dfuser; Owner: -
--

CREATE TABLE dfuser.tbls_calendars (
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
-- Name: tbls_countries; Type: TABLE; Schema: dfuser; Owner: -
--

CREATE TABLE dfuser.tbls_countries (
    fin_id character varying(120) NOT NULL,
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
    maker_checker_status character varying(10) DEFAULT 'Maked'::character varying NOT NULL,
    shadow_id character varying(60) DEFAULT ''::character varying NOT NULL
);


--
-- Name: tbls_dates_master; Type: TABLE; Schema: dfuser; Owner: -
--

CREATE TABLE dfuser.tbls_dates_master (
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
    edw_last_updated_time timestamp(0) without time zone,
    gmp_consol_date timestamp(0) without time zone
);


--
-- Name: tbls_departments; Type: TABLE; Schema: dfuser; Owner: -
--

CREATE TABLE dfuser.tbls_departments (
    fin_id character varying(91) NOT NULL,
    name character varying(50),
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
    code character varying(30)
);


--
-- Name: tbls_eod_progress; Type: TABLE; Schema: dfuser; Owner: -
--

CREATE TABLE dfuser.tbls_eod_progress (
    fin_id character varying(60) NOT NULL,
    process_name character varying(60),
    description character varying(100),
    status character varying(10),
    start_time timestamp(0) without time zone,
    end_time timestamp(0) without time zone,
    eod_date timestamp(0) without time zone,
    eod_process character varying(25),
    dependent_on character varying(400),
    exceptions text,
    saturday_run character varying(10),
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
    shadow_id character varying(60) DEFAULT '-1'::character varying
);


--
-- Name: tbls_eod_sanity_checks; Type: TABLE; Schema: dfuser; Owner: -
--

CREATE TABLE dfuser.tbls_eod_sanity_checks (
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
    mod_id double precision DEFAULT 0 NOT NULL,
    maker_checker_status character varying(10) DEFAULT 'COMMITTED'::character varying NOT NULL,
    shadow_id character varying(60) DEFAULT ''::character varying NOT NULL,
    field_count numeric(15,5)
);


--
-- Name: tbls_functions; Type: TABLE; Schema: dfuser; Owner: -
--

CREATE TABLE dfuser.tbls_functions (
    fin_id character varying(121) NOT NULL,
    name character varying(60),
    group_id character varying(60),
    maker_checker_required character(1),
    parent_id character varying(121) DEFAULT 0 NOT NULL,
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
    shadow_id character varying(60) DEFAULT ''::character varying NOT NULL,
    process_method character varying(200),
    sort_order numeric(15,5),
    hot_key character varying(25),
    display_menu character varying(25)
);


--
-- Name: tbls_groups; Type: TABLE; Schema: dfuser; Owner: -
--

CREATE TABLE dfuser.tbls_groups (
    fin_id character varying(60) NOT NULL,
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
-- Name: tbls_keypair; Type: TABLE; Schema: dfuser; Owner: -
--

CREATE TABLE dfuser.tbls_keypair (
    fin_id character varying(100) NOT NULL,
    alias_name character varying(60) NOT NULL,
    key_algorithm character varying(60),
    private_key_password character varying(200) NOT NULL,
    key_size numeric(15,5),
    validity numeric(15,5),
    fm_keystore_id character varying(100),
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
    salt1 character varying(200),
    salt2 character varying(200)
);


--
-- Name: tbls_keystore; Type: TABLE; Schema: dfuser; Owner: -
--

CREATE TABLE dfuser.tbls_keystore (
    fin_id character varying(25) NOT NULL,
    name character varying(60) NOT NULL,
    file_path character varying(100) NOT NULL,
    password character varying(200) NOT NULL,
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
    salt1 character varying(200),
    salt2 character varying(200),
    is_active character varying(25)
);


--
-- Name: tbls_maker_checker; Type: TABLE; Schema: dfuser; Owner: -
--

CREATE TABLE dfuser.tbls_maker_checker (
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
    parent_id character varying(401)
);


--
-- Name: tbls_maker_checker_data; Type: TABLE; Schema: dfuser; Owner: -
--

CREATE TABLE dfuser.tbls_maker_checker_data (
    fin_id character varying(401) NOT NULL,
    old_object bytea,
    new_object bytea,
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
    maker_checker_id character varying(401),
    maker_checker_status character varying(10)
);


--
-- Name: tbls_markets_countries_int; Type: TABLE; Schema: dfuser; Owner: -
--

CREATE TABLE dfuser.tbls_markets_countries_int (
    fin_id character varying(60) NOT NULL,
    country_id character varying(60),
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
    shadow_id character varying(60) DEFAULT ''::character varying NOT NULL
);


--
-- Name: tbls_migrproc_group; Type: TABLE; Schema: dfuser; Owner: -
--

CREATE TABLE dfuser.tbls_migrproc_group (
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
-- Name: tbls_migrproc_group_bean_int; Type: TABLE; Schema: dfuser; Owner: -
--

CREATE TABLE dfuser.tbls_migrproc_group_bean_int (
    fin_id character varying(60) NOT NULL,
    name character varying(150) NOT NULL,
    display_name character varying(60) NOT NULL,
    group_id character varying(60),
    function_id character varying(121) NOT NULL,
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
-- Name: tbls_msg_templates; Type: TABLE; Schema: dfuser; Owner: -
--

CREATE TABLE dfuser.tbls_msg_templates (
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
-- Name: tbls_passwordhistory; Type: TABLE; Schema: dfuser; Owner: -
--

CREATE TABLE dfuser.tbls_passwordhistory (
    fin_id character varying(361) NOT NULL,
    passwordvalue character varying(300),
    fromdate timestamp(6) without time zone DEFAULT clock_timestamp(),
    todate timestamp(6) without time zone DEFAULT clock_timestamp(),
    password_status character varying(3),
    user_id character varying(60),
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
    salt1 character varying(300),
    salt2 character varying(300),
    salt3 character varying(300)
);


--
-- Name: tbls_policies; Type: TABLE; Schema: dfuser; Owner: -
--

CREATE TABLE dfuser.tbls_policies (
    fin_id character varying(91) NOT NULL,
    name character varying(30),
    display_name character varying(100),
    is_active character varying(1),
    regions_id character varying(60) DEFAULT '0'::character varying,
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
-- Name: tbls_policies_details; Type: TABLE; Schema: dfuser; Owner: -
--

CREATE TABLE dfuser.tbls_policies_details (
    fin_id character varying(192) NOT NULL,
    policies_id character varying(91),
    display_name character varying(100),
    property_name character varying(100),
    property_value character varying(30),
    is_configurable character(1),
    is_applicable_superadmin character(1),
    is_deleted character varying(1) DEFAULT 'N'::character varying,
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
-- Name: tbls_processing_inbox; Type: TABLE; Schema: dfuser; Owner: -
--

CREATE TABLE dfuser.tbls_processing_inbox (
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
    shadow_id character varying(60) DEFAULT ''::character varying NOT NULL,
    groups_id character varying(60),
    function_id character varying(121)
);


--
-- Name: tbls_regions; Type: TABLE; Schema: dfuser; Owner: -
--

CREATE TABLE dfuser.tbls_regions (
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
    df_interpolation character varying(20),
    fx_system character varying(20)
);


--
-- Name: tbls_reports_config; Type: TABLE; Schema: dfuser; Owner: -
--

CREATE TABLE dfuser.tbls_reports_config (
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
-- Name: tbls_roles; Type: TABLE; Schema: dfuser; Owner: -
--

CREATE TABLE dfuser.tbls_roles (
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
-- Name: tbls_roles_functions_int; Type: TABLE; Schema: dfuser; Owner: -
--

CREATE TABLE dfuser.tbls_roles_functions_int (
    fin_id character varying(213) NOT NULL,
    role_id character varying(91),
    function_id character varying(121),
    access_level character varying(10),
    default_link character(1) DEFAULT 'N'::bpchar,
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
    shadow_id character varying(200) DEFAULT ''::character varying NOT NULL
);


--
-- Name: tbls_static_cfg_requests; Type: TABLE; Schema: dfuser; Owner: -
--

CREATE TABLE dfuser.tbls_static_cfg_requests (
    fin_id character varying(401) NOT NULL,
    function_id character varying(121),
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
    groups_id character varying(60)
);


--
-- Name: tbls_users; Type: TABLE; Schema: dfuser; Owner: -
--

CREATE TABLE dfuser.tbls_users (
    fin_id character varying(60) NOT NULL,
    user_id character varying(60) NOT NULL,
    password character varying(300) NOT NULL,
    salt1 character varying(300),
    salt2 character varying(300),
    salt3 character varying(300),
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
    last_successful_login timestamp(6) without time zone,
    unsuccessful_attempt_count double precision,
    force_password_change character varying(3),
    email_address character varying(30),
    last_password_change timestamp(6) without time zone,
    password_expiry character(1),
    from_date timestamp(6) without time zone,
    print_password character varying(1) DEFAULT 'N'::character varying,
    to_date timestamp(6) without time zone,
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
-- Name: tbls_users_regions_int; Type: TABLE; Schema: dfuser; Owner: -
--

CREATE TABLE dfuser.tbls_users_regions_int (
    fin_id character varying(213) NOT NULL,
    user_id character varying(60) NOT NULL,
    region_id character varying(60),
    role_id character varying(91),
    is_home character(1) DEFAULT 'Y'::bpchar,
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
-- Name: tbls_audit_trail pk_bls_audit_trail; Type: CONSTRAINT; Schema: dfuser; Owner: -
--

ALTER TABLE ONLY dfuser.tbls_audit_trail
    ADD CONSTRAINT pk_bls_audit_trail PRIMARY KEY (fin_id);


--
-- Name: tbls_calendar_hols pk_bls_calendar_hols; Type: CONSTRAINT; Schema: dfuser; Owner: -
--

ALTER TABLE ONLY dfuser.tbls_calendar_hols
    ADD CONSTRAINT pk_bls_calendar_hols PRIMARY KEY (fin_id);


--
-- Name: tbls_calendars pk_bls_calendars; Type: CONSTRAINT; Schema: dfuser; Owner: -
--

ALTER TABLE ONLY dfuser.tbls_calendars
    ADD CONSTRAINT pk_bls_calendars PRIMARY KEY (fin_id);


--
-- Name: tbls_countries pk_bls_countries; Type: CONSTRAINT; Schema: dfuser; Owner: -
--

ALTER TABLE ONLY dfuser.tbls_countries
    ADD CONSTRAINT pk_bls_countries PRIMARY KEY (fin_id);


--
-- Name: tbls_dates_master pk_bls_dates_master; Type: CONSTRAINT; Schema: dfuser; Owner: -
--

ALTER TABLE ONLY dfuser.tbls_dates_master
    ADD CONSTRAINT pk_bls_dates_master PRIMARY KEY (fin_id);


--
-- Name: tbls_departments pk_bls_departments; Type: CONSTRAINT; Schema: dfuser; Owner: -
--

ALTER TABLE ONLY dfuser.tbls_departments
    ADD CONSTRAINT pk_bls_departments PRIMARY KEY (fin_id);


--
-- Name: tbls_eod_progress pk_bls_eod_progress; Type: CONSTRAINT; Schema: dfuser; Owner: -
--

ALTER TABLE ONLY dfuser.tbls_eod_progress
    ADD CONSTRAINT pk_bls_eod_progress PRIMARY KEY (fin_id);


--
-- Name: tbls_eod_sanity_checks pk_bls_eod_sanity_checks; Type: CONSTRAINT; Schema: dfuser; Owner: -
--

ALTER TABLE ONLY dfuser.tbls_eod_sanity_checks
    ADD CONSTRAINT pk_bls_eod_sanity_checks PRIMARY KEY (fin_id);


--
-- Name: tbls_functions pk_bls_functions; Type: CONSTRAINT; Schema: dfuser; Owner: -
--

ALTER TABLE ONLY dfuser.tbls_functions
    ADD CONSTRAINT pk_bls_functions PRIMARY KEY (fin_id);


--
-- Name: tbls_groups pk_bls_groups; Type: CONSTRAINT; Schema: dfuser; Owner: -
--

ALTER TABLE ONLY dfuser.tbls_groups
    ADD CONSTRAINT pk_bls_groups PRIMARY KEY (fin_id);


--
-- Name: tbls_markets_countries_int pk_bls_markets_countries_int; Type: CONSTRAINT; Schema: dfuser; Owner: -
--

ALTER TABLE ONLY dfuser.tbls_markets_countries_int
    ADD CONSTRAINT pk_bls_markets_countries_int PRIMARY KEY (fin_id);


--
-- Name: tbls_migrproc_group pk_bls_migrproc_group; Type: CONSTRAINT; Schema: dfuser; Owner: -
--

ALTER TABLE ONLY dfuser.tbls_migrproc_group
    ADD CONSTRAINT pk_bls_migrproc_group PRIMARY KEY (fin_id);


--
-- Name: tbls_migrproc_group_bean_int pk_bls_migrproc_group_bean_int; Type: CONSTRAINT; Schema: dfuser; Owner: -
--

ALTER TABLE ONLY dfuser.tbls_migrproc_group_bean_int
    ADD CONSTRAINT pk_bls_migrproc_group_bean_int PRIMARY KEY (fin_id);


--
-- Name: tbls_msg_templates pk_bls_msg_templates; Type: CONSTRAINT; Schema: dfuser; Owner: -
--

ALTER TABLE ONLY dfuser.tbls_msg_templates
    ADD CONSTRAINT pk_bls_msg_templates PRIMARY KEY (fin_id);


--
-- Name: tbls_passwordhistory pk_bls_passwordhistory; Type: CONSTRAINT; Schema: dfuser; Owner: -
--

ALTER TABLE ONLY dfuser.tbls_passwordhistory
    ADD CONSTRAINT pk_bls_passwordhistory PRIMARY KEY (fin_id);


--
-- Name: tbls_policies pk_bls_policies; Type: CONSTRAINT; Schema: dfuser; Owner: -
--

ALTER TABLE ONLY dfuser.tbls_policies
    ADD CONSTRAINT pk_bls_policies PRIMARY KEY (fin_id);


--
-- Name: tbls_policies_details pk_bls_policies_details; Type: CONSTRAINT; Schema: dfuser; Owner: -
--

ALTER TABLE ONLY dfuser.tbls_policies_details
    ADD CONSTRAINT pk_bls_policies_details PRIMARY KEY (fin_id);


--
-- Name: tbls_processing_inbox pk_bls_processing_inbox; Type: CONSTRAINT; Schema: dfuser; Owner: -
--

ALTER TABLE ONLY dfuser.tbls_processing_inbox
    ADD CONSTRAINT pk_bls_processing_inbox PRIMARY KEY (fin_id);


--
-- Name: tbls_regions pk_bls_regions; Type: CONSTRAINT; Schema: dfuser; Owner: -
--

ALTER TABLE ONLY dfuser.tbls_regions
    ADD CONSTRAINT pk_bls_regions PRIMARY KEY (fin_id);


--
-- Name: tbls_reports_config pk_bls_reports_config; Type: CONSTRAINT; Schema: dfuser; Owner: -
--

ALTER TABLE ONLY dfuser.tbls_reports_config
    ADD CONSTRAINT pk_bls_reports_config PRIMARY KEY (fin_id);


--
-- Name: tbls_roles_functions_int pk_bls_roles_functions_int; Type: CONSTRAINT; Schema: dfuser; Owner: -
--

ALTER TABLE ONLY dfuser.tbls_roles_functions_int
    ADD CONSTRAINT pk_bls_roles_functions_int PRIMARY KEY (fin_id);


--
-- Name: tbls_users pk_bls_users; Type: CONSTRAINT; Schema: dfuser; Owner: -
--

ALTER TABLE ONLY dfuser.tbls_users
    ADD CONSTRAINT pk_bls_users PRIMARY KEY (fin_id);


--
-- Name: tbls_users_regions_int pk_bls_users_regions_int; Type: CONSTRAINT; Schema: dfuser; Owner: -
--

ALTER TABLE ONLY dfuser.tbls_users_regions_int
    ADD CONSTRAINT pk_bls_users_regions_int PRIMARY KEY (fin_id);


--
-- Name: tbls_audit_trail_hist sys_c0026042; Type: CONSTRAINT; Schema: dfuser; Owner: -
--

ALTER TABLE ONLY dfuser.tbls_audit_trail_hist
    ADD CONSTRAINT sys_c0026042 PRIMARY KEY (fin_id);


--
-- Name: tbls_roles sys_c0026043; Type: CONSTRAINT; Schema: dfuser; Owner: -
--

ALTER TABLE ONLY dfuser.tbls_roles
    ADD CONSTRAINT sys_c0026043 PRIMARY KEY (fin_id);


--
-- Name: tbls_maker_checker sys_c0026044; Type: CONSTRAINT; Schema: dfuser; Owner: -
--

ALTER TABLE ONLY dfuser.tbls_maker_checker
    ADD CONSTRAINT sys_c0026044 PRIMARY KEY (fin_id);


--
-- Name: tbls_maker_checker_data sys_c0026045; Type: CONSTRAINT; Schema: dfuser; Owner: -
--

ALTER TABLE ONLY dfuser.tbls_maker_checker_data
    ADD CONSTRAINT sys_c0026045 PRIMARY KEY (fin_id);


--
-- Name: tbls_static_cfg_requests sys_c0026046; Type: CONSTRAINT; Schema: dfuser; Owner: -
--

ALTER TABLE ONLY dfuser.tbls_static_cfg_requests
    ADD CONSTRAINT sys_c0026046 PRIMARY KEY (fin_id);


--
-- Name: tbls_keystore sys_c0075330; Type: CONSTRAINT; Schema: dfuser; Owner: -
--

ALTER TABLE ONLY dfuser.tbls_keystore
    ADD CONSTRAINT sys_c0075330 PRIMARY KEY (fin_id);


--
-- Name: tbls_keypair sys_c0075345; Type: CONSTRAINT; Schema: dfuser; Owner: -
--

ALTER TABLE ONLY dfuser.tbls_keypair
    ADD CONSTRAINT sys_c0075345 PRIMARY KEY (fin_id);


--
-- Name: tbls_reports_config uk1_bls_reports_config; Type: CONSTRAINT; Schema: dfuser; Owner: -
--

ALTER TABLE ONLY dfuser.tbls_reports_config
    ADD CONSTRAINT uk1_bls_reports_config UNIQUE (report_code);


--
-- Name: tbls_eod_progress_idx; Type: INDEX; Schema: dfuser; Owner: -
--

CREATE INDEX tbls_eod_progress_idx ON dfuser.tbls_eod_progress USING btree (exceptions);


--
-- Name: tbls_maker_checker_data_idx; Type: INDEX; Schema: dfuser; Owner: -
--

CREATE INDEX tbls_maker_checker_data_idx ON dfuser.tbls_maker_checker_data USING btree (old_object);


--
-- Name: tbls_maker_checker_data_idx001; Type: INDEX; Schema: dfuser; Owner: -
--

CREATE INDEX tbls_maker_checker_data_idx001 ON dfuser.tbls_maker_checker_data USING btree (new_object);




