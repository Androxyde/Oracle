Prompt ================================================================================================================
Prompt =                          Setting database parameters                                                         =
Prompt ================================================================================================================

alter system set memory_max_target=memory_max_target_VALM scope=spfile;
alter system set memory_target=memory_target_VALM scope=spfile;
alter system set sga_target=sga_target_VALM scope=spfile;
alter system set sga_max_size=sga_max_size_VALM scope=spfile;
alter system set pga_aggregate_target=pga_aggregate_target_VALM scope=spfile;
