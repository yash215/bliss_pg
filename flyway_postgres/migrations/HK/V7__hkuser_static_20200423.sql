DELETE FROM hkuser.TBLS_DL_ORDER_SOURCE t WHERE t.fin_id = 'Upload';
DELETE FROM hkuser.TBLS_REPOSITORIES t WHERE t.fin_id IN ('T_HK_HKG_A_TCQ', 'T_HK_HKG_A_BKN');
INSERT INTO hkuser.TBLS_DL_ORDER_SOURCE VALUES('Upload', 'Upload', 'Upload', 'N', TO_TIMESTAMP('2019-11-25 04:05:56.0', 'YYYY-MM-DD HH24:MI:SS.FF'), 'trdbth', TO_TIMESTAMP('2019-11-25 04:05:56.0', 'YYYY-MM-DD HH24:MI:SS.FF'), 'trdbth', 'System', TO_TIMESTAMP('2019-11-25 04:05:56.0', 'YYYY-MM-DD HH24:MI:SS.FF'), TO_TIMESTAMP('2019-11-25 04:05:56.0', 'YYYY-MM-DD HH24:MI:SS.FF'), 1.0, 'COMMITTED', '-1', 'N');
INSERT INTO hkuser.TBLS_REPOSITORIES VALUES('T_HK_HKG_A_BKN', 'T_HK_HKG_A', 'T_HK_HKG_A_BKN', 'BKN', 4.0, 'Y', 'ACTIVE', 'HK', '5925', 'N', TO_TIMESTAMP('2020-02-21 00:00:00.0', 'YYYY-MM-DD HH24:MI:SS.FF'), 'HKS-AllPunit', TO_TIMESTAMP('2020-02-21 16:46:18.253', 'YYYY-MM-DD HH24:MI:SS.FF'), 'HKS-AllSuraj', 'System', TO_TIMESTAMP('2018-07-16 15:41:28.56959', 'YYYY-MM-DD HH24:MI:SS.FF'), TO_TIMESTAMP('2018-07-16 15:41:28.56959', 'YYYY-MM-DD HH24:MI:SS.FF'), 14.0, 'COMMITTED', '-1', '06005', 'N', 'Y', 'K997');
