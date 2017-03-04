Prompt ================================================================================================================
Prompt =                          Applying BP2I specific settings                                                     =
Prompt ================================================================================================================

alter database default tablespace DATA0001;

CREATE USER TADDM IDENTIFIED BY TADDM DEFAULT TABLESPACE DATA0001 TEMPORARY TABLESPACE TEMP PROFILE DEFAULT ACCOUNT UNLOCK;
GRANT SELECT_CATALOG_ROLE TO TADDM;
ALTER USER TADDM DEFAULT ROLE ALL;
GRANT CREATE SESSION TO TADDM;
GRANT SELECT ANY DICTIONARY TO TADDM;

CREATE USER PERFSTAT IDENTIFIED BY PERFSTAT DEFAULT TABLESPACE STATSPACK TEMPORARY TABLESPACE TEMP PROFILE DEFAULT ACCOUNT UNLOCK;
GRANT SELECT_CATALOG_ROLE TO PERFSTAT;
GRANT CREATE SESSION TO PERFSTAT;
GRANT SELECT ANY DICTIONARY TO PERFSTAT;
ALTER USER PERFSTAT DEFAULT ROLE ALL;

CREATE USER EZMON IDENTIFIED BY VALUES '80554154353F6F2D' DEFAULT TABLESPACE DATA0001 TEMPORARY TABLESPACE TEMP PROFILE DEFAULT ACCOUNT UNLOCK;
GRANT SELECT_CATALOG_ROLE TO EZMON;
ALTER USER EZMON DEFAULT ROLE ALL;
GRANT CREATE SESSION TO EZMON;
GRANT SELECT ANY DICTIONARY TO EZMON;
GRANT SELECT ANY TABLE TO EZMON;
GRANT ALTER SESSION TO EZMON;
GRANT RESTRICTED SESSION TO EZMON;

alter user dbsnmp identified by HOSTNAME account unlock;
alter profile default limit password_life_time unlimited;

--revoke execute on UTL_FILE from public;
revoke execute on UTL_TCP from public;
revoke execute on UTL_HTTP from public;
revoke execute on UTL_SMTP from public;
--revoke execute on DBMS_LOB from public;
--revoke execute on DBMS_SQL from public;
--revoke execute on DBMS_JOB from public;
--revoke execute on DBMS_XMLGEN from public;
--revoke execute on DBMS_SCHEDULER from public;

alter profile default limit FAILED_LOGIN_ATTEMPTS 5;
