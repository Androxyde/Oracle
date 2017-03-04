Prompt ================================================================================================================
Prompt =                          Moving spfile to adm/spfile directory                                               =
Prompt ================================================================================================================

host mkdir /apps/oracle/adm/Q12345AP1/spfile
host echo SPFILE=/apps/oracle/adm/Q12345AP1/spfile/spfileQ12345AP10.ora>/apps/oracle/product/12.1.0/dbhome_2/dbs/initQ12345AP10.ora
host mv /apps/oracle/product/12.1.0/dbhome_2/dbs/spfileQ12345AP10.ora /apps/oracle/adm/Q12345AP1/spfile
