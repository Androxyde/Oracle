Prompt ================================================================================================================
Prompt =                          Setting database parameters                                                         =
Prompt ================================================================================================================

alter system set memory_max_target=1280M scope=spfile;
alter system set memory_target=1280M scope=spfile;
alter system set sga_target=896M scope=spfile;
alter system set sga_max_size=1024M scope=spfile;
alter system set pga_aggregate_target=128M scope=spfile;
