#!/bin/ksh

function get_db_unique_name {
	echo "$1" | awk '{print substr($0,1,9)}'
}

function remove_fs_linux {
	for i in $(lvdisplay -C|grep $1|awk '{print "/dev/"$2"/"$1}')
	do
		umount $i
		lvremove -y $i
		if ! test $? -eq 0
		then
			lvremove -f $i
		fi
		sed -i "\@$i@d" /etc/fstab
	done
}

function remove_fs_aix {
        for i in $(lsvg)
        do
                ISCLUSTER=$(cllsvg 2>/dev/nulld|awk '{print $2}'|grep -w ${i}|wc -l)
                if test ${ISCLUSTER} -eq 0
                then
                        for j in $(lsvg -l $i|grep $1|awk '{print $1}')
                        do
                                umount /dev/$j
                                rmfs /dev/$j
                        done
                fi
        done
}

function f_syntaxe {
  cat <<!

syntaxe : $PROGRAM -sid <instance name>

parametres obligatoires :
  -sid <instance name>        : nom de l'instance

exemple : $PROGRAM -sid Q12345AP10

!
}

export PROGRAM=$0

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
    -sid) export ORACLE_SID="$2"
          shift
          ;;
    *)    print "\nERREUR : le parametre '$1' n'existe pas\n"
          f_syntaxe
          exit 1
          ;;
  esac
  shift
done

export TOOLDIR=$PWD

export DB_UNIQUE_NAME=$(get_db_unique_name $ORACLE_SID)

case $(uname) in
	Linux)
		remove_fs_linux  ${DB_UNIQUE_NAME}
		;;
	AIX)
		remove_fs_aix  ${DB_UNIQUE_NAME}
		;;
esac
