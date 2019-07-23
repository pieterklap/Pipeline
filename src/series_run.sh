#!/bin/bash

#   this is not made to be run on its own but it can

PrecursorMassToleranceRange="$1 $2"
PrecursorMassToleranceIncrement="$3"

shift
shift
shift

LOC=$(echo $@ |awk '{print $NF}')
DSS=$(echo $@ | awk '{print $(NF-1)}')

Run_Script=$(echo $@ |awk '{$NF="";$(NF-1)="";print $0}')


shift

while [ "$3" != "" ]; do
    Help="0"
    case $1 in
        -o | --output )         shift               # Enter -o to specify the output location
                                DSSoutput=$1        # Enter -o to specify the output location
                                ;;
        -i | --input )          shift               # Enter -i to specify the input location
                                DSSinput=$1         # Enter -i to specify the input location
                                ;;
        -p | --parameter )      shift               # Enter -p to specify the paramater locatio
                                DSSparam=$1
                                ;;
        -v | --valparameter )   shift
                                VALparam=$1
                                ;;
        -g | --gprofiler )      shift
                                GPparams=$1
                                ;;
        -l | --logfile )        shift
                                logfile=$1
                                ;;
        -L | --location )       shift
                                location="$1"
                                ;;
        * )                     echo " "            # Requires you to anounce input with a - option
                                echo "Error invalid paramater $1"
                                echo "$@"
                                exit
                                ;;
    esac
    shift
done

source $LOC/src/parameter_repeat.sh
Parameter_repeat_default

if [[ $DSS == "comet" ]]; then
    Rerun_Comet_Tollerance_Parameters
fi

if [[ $DSS == "Xtandem" ]]; then
    Rerun_Tandem_Tollerance_Parameters
fi

if [[ $DSS == "MSGFPlus" ]]; then
    Rerun_MSGFPlus_Tollerance_Parameters
fi

if [[ $DSS == "MSFragger" ]]; then
    Rerun_MSFragger_Tollerance_Parameters
fi
