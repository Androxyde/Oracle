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

function create_fs_linux {
	export LV_PART=$1
	export LV_SIZE=$2
	export LV_VG=$3
	export LV_MOUNTPOINT=$(get_mount_point ${LV_PART})
	if test -b /dev/${LV_VG}/lv_${DB_UNIQUE_NAME}${LV_PART}
	then
		echo Le LV lv_${DB_UNIQUE_NAME}${LV_PART} existe deja dans le VG ${LV_VG}
		return
	fi
	lvcreate -y -Wy -n lv_${DB_UNIQUE_NAME}${LV_PART} -L${LV_SIZE} ${LV_VG}
	if ! test $? -eq 0
	then
		lvcreate -n lv_${DB_UNIQUE_NAME}${LV_PART} -L${LV_SIZE} ${LV_VG}
	fi
	if test $? -eq 0
	then
		if test -f /sbin/mkfs.xfs
		then
			mkfs.xfs /dev/mapper/${LV_VG}-lv_${DB_UNIQUE_NAME}${LV_PART}
			export FSTYPE=xfs
		else
			if test -f /sbin/mkfs.ext4
			then
				mkfs.ext4 /dev/mapper/${LV_VG}-lv_${DB_UNIQUE_NAME}${LV_PART}
				export FSTYPE=ext4
			else
				if test -f /sbin/mkfs.ext3
				then
					mkfs.ext3 /dev/mapper/${LV_VG}-lv_${DB_UNIQUE_NAME}${LV_PART}
					export FSTYPE=ext3
				fi
			fi
		fi
		mkdir -p ${LV_MOUNTPOINT}
		mount /dev/mapper/${LV_VG}-lv_${DB_UNIQUE_NAME}${LV_PART} ${LV_MOUNTPOINT}
		fstabexists=$(is_in_fstab ${LV_MOUNTPOINT})
		if test $fstabexists -eq 0
		then
			echo /dev/${LV_VG}/lv_${DB_UNIQUE_NAME}${LV_PART} ${LV_MOUNTPOINT} ${FSTYPE} defaults 0 0 >> /etc/fstab
		fi
		chown oracle:dba ${LV_MOUNTPOINT}
	else
		echo Impossible de creer le logical volume lv_${DB_UNIQUE_NAME}${LV_PART}
	fi
}

function create_fs_aix {
	export LV_PART=$1
	export LV_NAME=lv_${DB_UNIQUE_NAME}${LV_PART}
	export LV_SIZE=$2
	export LV_VG=$3
	export LV_MOUNTPOINT=$(get_mount_point ${LV_PART})
	export ISCLUSTER=$4
        if test ${ISCLUSTER} -eq 0
        then
		if test $(is_in_filesystems ${LV_MOUNTPOINT}) -eq 1
		then
			echo Ce point de montage existe deja : ${LV_MOUNTPOINT}
			return
		fi
		mklv -y ${LV_NAME} -t jfs2 ${LV_VG} ${LV_SIZE}
		crfs -v jfs2 -d ${LV_NAME} -m ${LV_MOUNTPOINT} -A yes
		mkdir -p ${LV_MOUNTPOINT}
		mount ${LV_MOUNTPOINT}
		chown oracle:dba ${LV_MOUNTPOINT}
        else
                echo "Ce VG est en cluster. Merci de vous adresser a UNIX : ${LV_NAME} monte sur ${LV_MOUNTPOINT} taille ${LV_SIZE} dans le VG ${LV_VG}"
                return 1
        fi
}

function f_syntaxe {
  cat <<!

syntaxe : $PROGRAM -oh <oracle home> -sid <instance name> -vg <volume_group> [-tpl <template> -arb <arborescence>]

parametres obligatoires :
  -oh <oracle home>           : oracle home a utiliser pour la creation de l'instance
  -sid <instance name>        : nom de l'instance
  -vg <volume_group>          : nom du volume group

parametres optionnels :
  -tpl <template>              : template (SMALL, MEDIUM, BIG, JUMBO). Par defaut : SMALL
  -arb <arborescence>          : topologie des filesystems. Par defaut : v4

exemple : $PROGRAM -oh /opt/oracle/product/11.2.0/dbhome_1 -sid P12345AP10 -vg vg_data

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
    -vg) export VG="$2"
          shift
          ;;
    -tpl) export TMPL="$2"
          shift
          ;;
    -arb) export ARBORESCENCE="$2"
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

if test -z "$OVERSION"
then
        echo $1 : Oracle Home invalide
        exit 1
fi

if test -z "$ORACLE_SID"
then
        echo sid obligatoire
        exit 1
fi

if test -z "$VG"
then
        echo vg obligatoire
        exit 1
fi

if test -z "$TMPL"
then
	export TMPL=SMALL
fi

if test -z "$ARBORESCENCE"
then
	export ARBORESCENCE=v4
fi

export DB_UNIQUE_NAME=$(get_db_unique_name $ORACLE_SID)
export DB_UNIQUE_NAME_low=$(to_lower $DB_UNIQUE_NAME)
export PLATFORM=$(uname)

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

echo "Oracle Verson          : " $OVERSION 
echo "DB_UNIQUE_NAME         : " $DB_UNIQUE_NAME

ISCLUSTER=$(cllsvg 2>/dev/nulld|awk '{print $2}'|grep -w ${VG}|wc -l)

for i in $(cat ${TOOLDIR}/config/templates.${ARBORESCENCE})
do
        LINE=$(echo $i |sed "s/DB_UNIQUE_NAME_low/${DB_UNIQUE_NAME_low}/g"|sed "s/DB_UNIQUE_NAME/${DB_UNIQUE_NAME}/g"|sed "s/ORACLE_SID/${ORACLE_SID}/g")
        echo $LINE|IFS=':' read -r PARAM1 PARAM2 PARAM3 PARAM4 PARAM5
        eval 'case $PARAM1 in
                FOLDER)
			mkdir -p ${PARAM3}
			chown oracle:dba ${PARAM3}
			;;
                ${TMPL})
			case ${PARAM2} in
				FS)
					case ${PLATFORM} in
						Linux)
							create_fs_linux  ${PARAM3} ${PARAM4} ${VG}
							;;
						AIX)
							create_fs_aix  ${PARAM3} ${PARAM4} ${VG} ${ISCLUSTER}
							;;
					esac
					;;
			esac
			;;
        esac'
done
