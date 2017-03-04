#!/bin/ksh

function get_db_unique_name {
	echo "$1" | awk '{print substr($0,1,9)}'
}

function get_db_name {
	if test ${#1} -eq 10
	then
		echo "$1" | awk '{print substr($0,1,7)}'
	else
		echo "$1" | awk '{print substr($0,1,6)}'
	fi
}

function get_oracle_version {
	echo $($1/bin/sqlplus -v 2>/dev/null|awk '{print $3}'|awk 'BEGIN { FS = "." } ; { print $1 $2 }'|xargs)
}

function get_oracle_fullversion {
	echo $($1/bin/sqlplus -v 2>/dev/null|awk '{print $3}')
}

function to_lower {
	echo $1 | awk '{print tolower($0)}'
}

function check_mount {
FS=$(df -Pm $1 2>/dev/null|grep /dev|awk '{print $6}')
DEV=$(df -Pm $1 2>/dev/null|grep /dev|awk '{print $1}')

if test "${FS}" = "${1}"
then
	if test "${OSRELEASE}" = "AIX"
	then
		VG=$(lvdisplay $DEV|grep VG|awk '{print $3}')
	fi
        echo OK
else
        echo KO
fi
}

function get_owner {
	ls -ld $1 | awk 'NR==1 {print $3}'
}

function get_mount_point {
for i in $(cat ${WORKDIR}/.templates.${ARBORESCENCE})
do
        echo $i|IFS=':' read -r PARAM1 PARAM2 PARAM3 PARAM4 PARAM5
        case $PARAM1 in
                FS) if test "${PARAM2}" = "${1}"
                    then
                        echo ${PARAM3}
                    fi
                    ;;
        esac
done
}

function add_to_custom {
S_PATH=$1
S_SCRIPT=$2
if test -f ${S_PATH}/${S_SCRIPT}
then
	cp ${S_PATH}/${S_SCRIPT} ${WORKDIR}
	echo "@${WORKDIR}/${S_SCRIPT}" >> ${WORKDIR}/custom.sql
else
	echo "@${S_PATH}" >> ${WORKDIR}/custom.sql
fi
}

function f_syntaxe {
  cat <<!

syntaxe : $PROGRAM -oh <oracle home> -sid <instance name> [-bs <BLOCKSIZE> -cs <CHARACTERSET> -tpl <template> -arb <arborescence>]

parametres obligatoires :
  -oh <oracle home>           : oracle home a utiliser pour la creation de l'instance
  -sid <instance name>        : nom de l'instance

parametres optionnels :
  -bs <BLOCKSIZE>              : blocksize (8, 16, 32). Par defaut : 8
  -cs <CHARACTERSET>           : character set. Par defaut : AL32UTF8
  -tpl <template>              : template (SMALL, MEDIUM, BIG, JUMBO). Par defaut : SMALL
  -arb <arborescence>          : topologie des filesystems. Par defaut : v4

exemple : $PROGRAM -oh /apps/oracle/product/11.2.0/dbhome_1 -sid P12345AP10 -bs 8 -cs AL32UTF8

!
}

export PROGRAM=$0
export TOOLDIR="$( cd "$( dirname "$PROGRAM" )" && cd .. && pwd )"
export ORACLE_BASE=/apps/oracle

userid=$(id -u)

if ! test $userid -eq 0
then
        echo "Vous devez etre root pour executer ce script"
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
    -oh)  export ORACLE_HOME="$2"
          shift
          ;;
    -sid) export ORACLE_SID="$2"
          shift
          ;;
    -bs) export BLOCKSIZE="$2"
          shift
          ;;
    -cs) export CHARACTERSET="$2"
          shift
          ;;
    -tpl) export TMPL="$2"
          shift
          ;;
    -arb) export ARBORESCENCE="$2"
          shift
          ;;
    -l) export NLS_LANGUAGE="$2"
          shift
          ;;
    -t) export NLS_TERRITORY="$2"
          shift
          ;;
    -dbc) export USE_DBC="$2"
          shift
          ;;
    *)    print "\nERREUR : le parametre '$1' n'existe pas\n"
          f_syntaxe
          exit 1
          ;;
  esac
  shift
done


export OVERSION=$(get_oracle_version $ORACLE_HOME)
export OFULLVERSION=$(get_oracle_fullversion $ORACLE_HOME)
export PLATFORM=$(uname)

if test "${PLATFORM}" = "Linux"
then
	export OSRELEASE="RHAS"
else
	export OSRELEASE="AIX"
fi

if test -z "$OVERSION"
then
	echo $1 : Oracle Home invalide
	exit 1
fi

if test -z "$BLOCKSIZE"
then
        export BLOCKSIZE=8
fi

if test -z "$USE_DBC"
then
        export USE_DBC="true"
fi

if test -z "$CHARACTERSET"
then
        export CHARACTERSET="AL32UTF8"
fi

if test -z "$TMPL"
then
        export TMPL="SMALL"
fi

if test -z "$ARBORESCENCE"
then
        export ARBORESCENCE="v4"
fi

if test -z "$NLS_LANGUAGE"
then
        export NLS_LANGUAGE="AMERICAN"
fi

if test -z "$NLS_TERRITORY"
then
        export NLS_TERRITORY="AMERICA"
fi

if ! test -f ${TOOLDIR}/config/templates.${ARBORESCENCE}
then
	echo "Cette arborescence : ${ARBORESCENCE} ne fait pas partie de la configuration"
	exit 1
fi

HASTMPL=$(cat ${TOOLDIR}/config/templates.${ARBORESCENCE}|grep ${TMPL}:|wc -l)
if test $HASTMPL -eq 0
then
	echo "Ce template : ${TMPL} ne fait pas partie de la configuration"
	exit 1
fi

export BLOCKSBYTES=$(($BLOCKSIZE*1024))

export DB_UNIQUE_NAME=$(get_db_unique_name $ORACLE_SID)
export DB_UNIQUE_NAME_low=$(to_lower $DB_UNIQUE_NAME)
export DB_NAME=$(get_db_name $ORACLE_SID)

if test "${USE_DBC}" = "true"
then
echo "Recuperation des templates"
if ! test -f ${TOOLDIR}/dbtemplates/${OSRELEASE=}_${OFULLVERSION}_${BLOCKSIZE}.dfb
then
	$TOOLDIR/perl/Get_File.pl nimprod /ORADELIVERY/MASTERS/${OSRELEASE=}/DBCA/${OSRELEASE=}_${OFULLVERSION}_${BLOCKSIZE}.dfb $TOOLDIR/dbtemplates > /dev/null 2>&1
fi
if ! test -f ${TOOLDIR}/dbtemplates/${OSRELEASE=}_${OFULLVERSION}_${BLOCKSIZE}.ctl
then
	$TOOLDIR/perl/Get_File.pl nimprod /ORADELIVERY/MASTERS/${OSRELEASE=}/DBCA/${OSRELEASE=}_${OFULLVERSION}_${BLOCKSIZE}.ctl $TOOLDIR/dbtemplates > /dev/null 2>&1
fi
fi

if test -f ${TOOLDIR}/dbtemplates/${OSRELEASE=}_${OFULLVERSION}_${BLOCKSIZE}.dfb -a "${USE_DBC}" = "true"
then
	chown oracle:dba ${TOOLDIR}/dbtemplates/${OSRELEASE=}_${OFULLVERSION}_${BLOCKSIZE}.dfb
	export dbtemplate=DBTEMPLATE.dbc
	export TEMPLATE_WITH_FILES="oui"
else
	export dbtemplate=DBTEMPLATE.dbt
	export TEMPLATE_WITH_FILES="non"
fi

if test -f ${TOOLDIR}/dbtemplates/${OSRELEASE=}_${OFULLVERSION}_${BLOCKSIZE}.ctl
then
	chown oracle:dba ${TOOLDIR}/dbtemplates/${OSRELEASE=}_${OFULLVERSION}_${BLOCKSIZE}.ctl
fi

export WORKDIR=${TOOLDIR}/work/${DB_UNIQUE_NAME}
rm -Rf $WORKDIR
mkdir -p $WORKDIR
echo "Generation des fichiers de travail dans ${WORKDIR}"

cp ${TOOLDIR}/config/${OVERSION}/${dbtemplate} ${WORKDIR}

if test "${TEMPLATE_WITH_FILES}" = "non"
then
	add_to_custom "?/rdbms/admin/owmuinst.plb"
fi
add_to_custom ${TOOLDIR}/sql addredo4k.sql
if test "${TEMPLATE_WITH_FILES}" = "non"
then
	add_to_custom ${TOOLDIR}/sql/${OVERSION} bp2i.sql
fi
add_to_custom ${TOOLDIR}/sql datapump.sql
add_to_custom ${TOOLDIR}/sql/${OVERSION} parameters.sql
add_to_custom ${TOOLDIR}/sql shutdown.sql
add_to_custom ${TOOLDIR}/sql spfiletoadm.sql
add_to_custom ${TOOLDIR}/sql orapwtoadm.sql
if test "${TEMPLATE_WITH_FILES}" = "oui"
then
        add_to_custom ${TOOLDIR}/sql startupupgrade.sql
	add_to_custom ${TOOLDIR}/sql/${OVERSION} datapatch.sql
        add_to_custom ${TOOLDIR}/sql shutdown.sql
fi
add_to_custom ${TOOLDIR}/sql startup.sql
add_to_custom ${TOOLDIR}/sql utlrp.sql

cp ${TOOLDIR}/config/templates.${ARBORESCENCE} ${WORKDIR}

for file in ${WORKDIR}/*
do
	sed "s/DB_UNIQUE_NAME_low/${DB_UNIQUE_NAME_low}/g;s/DB_UNIQUE_NAME/${DB_UNIQUE_NAME}/g;s/BLOCKSIZE/${BLOCKSIZE}/g;s/BLOCKSBYTES/${BLOCKSBYTES}/g;s/PLATFORM/${OSRELEASE=}/g;s/FULLVERSION/${OFULLVERSION}/g;s|TOOLDIR|${TOOLDIR}|g;s|HOSTNAME|$(hostname)|g;s|OHOME|${ORACLE_HOME}|g;s|OSID|${ORACLE_SID}|g;s|WORKDIR|${WORKDIR}|g;s|NLS_LANGUAGE|${NLS_LANGUAGE}|g;s|NLS_TERRITORY|${NLS_TERRITORY}|g" ${file}>${file}.tmp && rm ${file} && mv ${file}.tmp ${file}
done

mv ${WORKDIR}/templates.${ARBORESCENCE} ${WORKDIR}/.templates.${ARBORESCENCE}


for i in $(cat ${WORKDIR}/.templates.${ARBORESCENCE})
do
	echo $i|IFS=':' read -r PARAM1 PARAM2 PARAM3 PARAM4 PARAM5
	eval 'case $PARAM1 in
		${TMPL})
			for file in ${WORKDIR}/*
			do
				sed "s|${PARAM3}_VAL|${PARAM4}|g" ${file}>${file}.tmp && rm ${file} && mv ${file}.tmp ${file}
			done
			case ${PARAM2} in
                                FS) MOUNTPOINT=$(get_mount_point $PARAM3)
				    ISLV=$(check_mount ${MOUNTPOINT})
				    if test "${ISLV}" = "KO"
				    then
				    	echo $(get_mount_point $PARAM3) doit etre un monte sur un LV
					exit 1
				    else
					if ! test "$(get_owner ${MOUNTPOINT})" = "oracle"
					then
						echo "Le proprietaire de $MOUNTPOINT doit etre oracle"
						exit 1
					fi
				    fi
			esac
			;;
		DBF)
			for file in ${WORKDIR}/*
			do
				sed "s|${PARAM2}_FILE|${PARAM3}|g;s|${PARAM2}_PATH|$(get_mount_point ${PARAM4})|g" ${file}>${file}.tmp && rm ${file} && mv ${file}.tmp ${file}
			done
			;;
		FOLDER)
			for file in ${WORKDIR}/*
			do
				sed "s|${PARAM2}_PATH|${PARAM3}|g" ${file}>${file}.tmp && rm ${file} && mv ${file}.tmp ${file}
			done
			;;
	esac'
done

chown oracle:dba ${TOOLDIR}/work/*

echo "Demarrage de la creation de la base de donnees en tant qu'oracle"
echo "Recapitulatif : "
echo "Oracle Home            : " $ORACLE_HOME
echo "Oracle Verson          : " $OVERSION " (" $OFULLVERSION ")"
echo "Template avec fichiers : " $TEMPLATE_WITH_FILES
echo "DB_NAME                : " $DB_NAME
echo "ORACLE_SID             : " $ORACLE_SID
echo "DB_UNIQUE_NAME         : " $DB_UNIQUE_NAME
echo "DB_UNIQUE_NAME (lower) : " $DB_UNIQUE_NAME_low
echo "DB BLOCK SIZE          : " $BLOCKSIZE
if test "${TEMPLATE_WITH_FILES}" = "oui"
then
	echo "DB NLS                 : " AMERICAN_AMERICA.${CHARACTERSET}
else
	echo "DB NLS                 : " ${NLS_LANGUAGE}_${NLS_TERRITORY}.${CHARACTERSET}
fi
echo "INSTANCE NLS           : " ${NLS_LANGUAGE}_${NLS_TERRITORY}.${CHARACTERSET}

chown -R oracle:dba ${WORKDIR}

su oracle -c '$ORACLE_HOME/bin/dbca -silent -createDatabase -templateName ${WORKDIR}/${dbtemplate} -gdbName ${DB_NAME} -sid ${ORACLE_SID} -systemPassword $(hostname) -sysPassword $(hostname) -initParams db_unique_name=${DB_UNIQUE_NAME} -characterSet ${CHARACTERSET} -continueOnNonFatalErrors true'

if test "${CHARACTERSET}" = "US7ASCII"
then
	if ! test -f ${TOOLDIR}/dbtemplates/${OSRELEASE=}_${OFULLVERSION}_${BLOCKSIZE}.dfb
	then
		su oracle -c '$ORACLE_HOME/bin/dbca -silent -createCloneTemplate -sourceSID ${ORACLE_SID} -templateName ${OSRELEASE}_${OFULLVERSION}_${BLOCKSIZE} -sysDBAUserName sys -sysDBAPassword $(hostname) -maintainFileLocations false -datafileJarLocation ${TOOLDIR}/dbtemplates'
		mv ${ORACLE_HOME}/assistants/dbca/templates/${OSRELEASE}_* ${TOOLDIR}/dbtemplates
		rm -f ${TOOLDIR}/dbtemplates/*dbc
		chown oracle:dba ${TOOLDIR}/dbtemplates/*
	fi
fi

rm -Rf $ORACLE_BASE/audit/${DB_UNIQUE_NAME}
rm -Rf $ORACLE_HOME/rdbms/audit/${ORACLE_SID}*
