Prompt ================================================================================================================
Prompt =                          Moving orapw to adm directory                                                       =
Prompt ================================================================================================================

host mv OHOME/dbs/orapwOSID ADMIN_PATH/DB_UNIQUE_NAME/
host ln -sf ADMIN_PATH/DB_UNIQUE_NAME/orapwOSID OHOME/dbs/orapwOSID
