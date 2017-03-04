#!/bin/ksh

function get_db_unique_name {
	echo "$1" | awk '{print substr($0,1,9)}'
}

function get_db_name {
	echo "$1" | awk '{print substr($0,1,7)}'
}

function get_oracle_version {
	echo $($1/bin/sqlplus -v 2>/dev/null|awk '{print $3}'|awk 'BEGIN { FS = "." } ; { print $1 $2 }'|xargs)
}

function to_lower {
	echo $1 | awk '{print tolower($0)}'
}

function is_in_fstab {
	for i in $(cat /etc/fstab|awk '{print $2}')
	do
		if test "$1" = "$i"
		then
			echo 1
			return
		fi
	done
	echo 0
}

function is_in_filesystems {
	grep ${1}: /etc/filesystems|wc -l
}

function get_mount_point {
for i in $(cat ${TOOLDIR}/config/templates.${ARBORESCENCE})
do
        LINE=$(echo $i |sed "s/DB_UNIQUE_NAME_low/${DB_UNIQUE_NAME_low}/g"|sed "s/DB_UNIQUE_NAME/${DB_UNIQUE_NAME}/g"|sed "s/ORACLE_SID/${ORACLE_SID}/g")
        echo $LINE|IFS=':' read -r PARAM1 PARAM2 PARAM3 PARAM4 PARAM5
	case $PARAM1 in
		FS) if test "${PARAM2}" = "${1}"
		    then
		    	echo ${PARAM3}
		    fi
		    ;;
	esac
done
}

function f_syntaxe {
  cat <<!

syntaxe : $PROGRAM -oh <oracle home> -sid <instance name> -vg <volume_group> [-tpl <template> -arb <arborescence>]

parametres obligatoires :
  -sid <instance name>        : nom de l'instance
  -path <save_path>           : chemin de savegarde

parametres optionnels :
  -level <level>              : Mode de sauvegardePar defaut : FULL+CONTROLFILE+SPFILE

exemple : $PROGRAM -oh /opt/oracle/product/11.2.0/dbhome_1 -sid P12345AP10 -path fra

!
}

export PROGRAM=$0
export TOOLDIR="$( cd "$( dirname "$PROGRAM" )" && cd .. && pwd )"
export ORACLE_BASE=/apps/oracle

userid=$(id -u)

if ! test $userid -eq 300
then
	echo "Vous devez etre oracle pour executer ce script"
	exit 1
fi

if [ -z "$1" ] ; then
  f_syntaxe
  exit 1
fi

while [ ! -z "$1" ]
do
  case $1 in
    -h)   f_syntaxe
          exit 0
          ;;
    -sid) export ORACLE_SID="$2"
          shift
          ;;
    -path) export SAVE_PATH="$2"
          shift
          ;;
    -level) export LEVEL="$2"
          shift
          ;;
    *)    print "\nERREUR : le parametre '$1' n'existe pas\n"
          f_syntaxe
          exit 1
          ;;
  esac
  shift
done

if test -z "$ORACLE_SID"
then
        echo sid obligatoire
        exit 1
fi

for i in $(cat /etc/oratab)
do
        echo $i|IFS=':' read -r SID OHOME AUTORUN
        eval 'case ${SID} in
                ${ORACLE_SID})
                        export ORACLE_HOME=${OHOME}
                        ;;
        esac'
done

if test -z "$ORACLE_HOME"
then
        echo $ORACLE_SID absent de /etc/oratab
        exit 1
fi

export OVERSION=$(get_oracle_version $ORACLE_HOME)

if test -z "$OVERSION"
then
        echo $1 : Oracle Home invalide
        exit 1
fi

if test -z "$SAVE_PATH"
then
        echo path obligatoire
        exit 1
fi

if test -z "$LEVEL"
then
	export LEVEL=FULL
fi

export DB_UNIQUE_NAME=$(get_db_unique_name $ORACLE_SID)
export DB_UNIQUE_NAME_low=$(to_lower $DB_UNIQUE_NAME)
export PLATFORM=$(uname)

echo "Oracle Verson          : " $OVERSION 
echo "DB_UNIQUE_NAME         : " $DB_UNIQUE_NAME

$ORACLE_HOME/bin/rman<<EOF

connect target / 
sql 'alter system archive log current'; 
sql "alter session set nls_date_format=''dd.mm.yyyy hh24:mi:ss''"; 
RUN 
{ 
  set command id to '${ORACLE_SID}OnlineBackupFull'; 
  ALLOCATE CHANNEL c1 DEVICE TYPE disk maxpiecesize 8G; 
  ALLOCATE CHANNEL c2 DEVICE TYPE disk maxpiecesize 8G; 
  ALLOCATE CHANNEL c3 DEVICE TYPE disk maxpiecesize 8G; 
  ALLOCATE CHANNEL c4 DEVICE TYPE disk maxpiecesize 8G; 
  BACKUP
  FORMAT '${SAVE_PATH}/%d_DATABASE_%T_%u_s%s_p%p.bkp'
  AS COMPRESSED BACKUPSET
  DATABASE
  CURRENT CONTROLFILE
  FORMAT '${SAVE_PATH}/%d_CONTROL_%T_%u.bkp'
  SPFILE
  FORMAT '${SAVE_PATH}/%d_SPFILE_%T_%u.bkp'
  PLUS ARCHIVELOG
  FORMAT '${SAVE_PATH}/%d_ARCHIVE_%T_%u_s%s_p%p.bkp';
  release channel c1; 
  release channel c2; 
  release channel c3; 
  release channel c4; 
}
EOF
