Prompt ================================================================================================================
Prompt =                          Moving orapw to adm directory                                                       =
Prompt ================================================================================================================

host mv /apps/oracle/product/12.1.0/dbhome_2/dbs/orapwP12345AP10 /apps/oracle/adm/P12345AP1/
host ln -sf /apps/oracle/adm/P12345AP1/orapwP12345AP10 /apps/oracle/product/12.1.0/dbhome_2/dbs/orapwP12345AP10
