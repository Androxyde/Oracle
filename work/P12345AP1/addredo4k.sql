Prompt ================================================================================================================
Prompt =                          Setting redo to 4k blocksize                                                        =
Prompt ================================================================================================================

alter database add logfile group 1 ('/apps/oradata01/P12345AP1/datafile/redo11.rdo','/apps/orafra/P12345AP1/redo12.rdo') size 512M blocksize 4096;
alter database add logfile group 2 ('/apps/oradata01/P12345AP1/datafile/redo21.rdo','/apps/orafra/P12345AP1/redo22.rdo') size 512M blocksize 4096;
alter database add logfile group 3 ('/apps/oradata01/P12345AP1/datafile/redo31.rdo','/apps/orafra/P12345AP1/redo32.rdo') size 512M blocksize 4096;

Prompt ================================================================================================================
Prompt =                          Removing temporary redo from database                                               =
Prompt ================================================================================================================

declare
   nblog number;
begin
   select count(1) nblog into nblog from v$log where group# in (4,5);
   while nblog>0
   loop
     execute immediate 'alter system switch logfile';
     execute immediate 'alter system checkpoint';
     begin
       execute immediate 'alter database drop logfile group 4';
     exception
       when others then null;
     end;
     begin
       execute immediate 'alter database drop logfile group 5';
     exception
       when others then null;
     end;
     select count(1) into nblog from v$log where group# in (4,5);
   end loop;
end;
/

Prompt ================================================================================================================
Prompt =                          Removing temporary redo from filesystem                                             =
Prompt ================================================================================================================

host rm -Rf /apps/oradata01/P12345AP1/datafile/redotmp11
host rm -Rf /apps/orafra/P12345AP1/redotmp12
host rm -Rf /apps/oradata01/P12345AP1/datafile/redotmp21
host rm -Rf /apps/orafra/P12345AP1/redotmp22
