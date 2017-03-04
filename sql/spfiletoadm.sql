Prompt ================================================================================================================
Prompt =                          Moving spfile to adm/spfile directory                                               =
Prompt ================================================================================================================

host mkdir ADMIN_PATH/DB_UNIQUE_NAME/spfile
host echo SPFILE=ADMIN_PATH/DB_UNIQUE_NAME/spfile/spfileOSID.ora>OHOME/dbs/initOSID.ora
host mv OHOME/dbs/spfileOSID.ora ADMIN_PATH/DB_UNIQUE_NAME/spfile
