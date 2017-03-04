#!/bin/ksh

function f_syntaxe {
  cat <<!

syntaxe : $PROGRAM -sid <instance name>

parametres obligatoires :
  -sid <instance name>        : nom de l'instance

exemple : $PROGRAM -sid Q12345AP10

!
}

export PROGRAM=$0
export TOOLDIR="$( cd "$( dirname "$PROGRAM" )" && cd .. && pwd )"

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

su oracle -c '${ORACLE_HOME}/bin/dbca -silent -deleteDatabase -sourceDB $ORACLE_SID -sysDBAUserName sys -sysDBAPassword $(hostname)'
