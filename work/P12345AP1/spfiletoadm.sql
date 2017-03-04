Prompt ================================================================================================================
Prompt =                          Moving spfile to adm/spfile directory                                               =
Prompt ================================================================================================================

host mkdir /apps/oracle/adm/P12345AP1/spfile
host echo SPFILE=/apps/oracle/adm/P12345AP1/spfile/spfileP12345AP10.ora>/apps/oracle/product/12.1.0/dbhome_2/dbs/initP12345AP10.ora
host mv /apps/oracle/product/12.1.0/dbhome_2/dbs/spfileP12345AP10.ora /apps/oracle/adm/P12345AP1/spfile
