Prompt ================================================================================================================
Prompt =                          Setting redo to 4k blocksize                                                        =
Prompt ================================================================================================================

alter database add logfile group 1 ('REDO11_PATH/REDO11_FILE','REDO12_PATH/REDO12_FILE') size REDO_VALM blocksize 4096;
alter database add logfile group 2 ('REDO21_PATH/REDO21_FILE','REDO22_PATH/REDO22_FILE') size REDO_VALM blocksize 4096;
alter database add logfile group 3 ('REDO31_PATH/REDO31_FILE','REDO32_PATH/REDO32_FILE') size REDO_VALM blocksize 4096;

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

host rm -Rf REDO11_PATH/redotmp11
host rm -Rf REDO12_PATH/redotmp12
host rm -Rf REDO21_PATH/redotmp21
host rm -Rf REDO22_PATH/redotmp22
