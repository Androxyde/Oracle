echo "restore controlfile preview; restore database preview;" | NLS_DATE_FORMAT='yyyymmddhh24miss' rman target / | awk '
/Finished restore at /{timestamp=$4}
/Recovery must be done beyond SCN /{if ($7>scn) scn=$7 }
/.arc/ { files[$NF]=1 }
/.bkp/ { files[$NF]=1 }
END{ for (i in files) print i > "files-"timestamp"-SCN-"scn".txt" }
'
