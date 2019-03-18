#!/bin/bash

if [[ $1 == "" ]]; then
    cat info.pipeline
    exit
fi

# $LOC is the directory of the pipeline
LOC=$(echo "$0" |awk -F/ '{$NF="";print $0}' | tr " " "/")

if [[ $LOC == "./" ]]; then
    LOC="$PWD/"
fi

echo $LOC
# allows the options to work
while [ "$1" != "" ]; do

    case $1 in
        -P | --PeptideID )  while [[ ${2:0:1} != "-" ]] && [[ "$1" != "" ]]; do
                                shift                   # Allows for multiple PeptideIDentifiers (PIDs) to be entered
                                PIDprog+=${1,,}" "      # Allows for multiple PeptideIDentifiers (PIDs) to be entered
                                NUMprog=$[$NUMprog+1]   # Counts the amount of programs entered
                            done
                            ;;
        -V | --Validator )  while [[ ${2:0:1} != "-" ]] && [[ "$1" != "" ]]; do
                                shift                   # Allows for multiple validators to be entered
                                VALprog+=${1,,}" "      # Allows for multiple validators to be entered
                            done
                            ;;
        -L | --location )   location="$1 $2"                        # If the script isn't ran where it was created (for use on the shark cluster)
                            shift
                            ;;
        -i | --input )      input="$1 $2"
                            shift
                            ;;
        -o | --output )     output="$1 $2"
                            shift
                            ;;
        -p | -parameters )  while [[ ${2:0:1} != "-" ]] && [[ "$1" != "" ]]; do
                                shift
                                PIDparam+=$1" "
                                NUMparam=$[$NUMparam+1] # Counts the amount of parameter files entered
                            done
                            ;;
        -L | --location )   shift
                            LOC="$1"
                            ;;
        -l | --logfile )    logfile="$1 $2"
                            shift
                            ;;
        -r | --norun )      RUNscripts="n"
                            ;;
        -s | --shark )      SHARK="1"
                            while [[ "$1" != "" ]]; do
                                shift                           # Allows Shark options to be entered
                                SHARKoptions+=$1" "          # Allows Shark options to be entered
                            done
                            ;;
        * )                 echo "Unknown parameter ""$1"
                            exit
                            ;;
    esac
    shift
done

# sets the parameter files to be used for each peptide identifier
for prog in $PIDprog
do
    if [[ ${prog} == comet ]]; then
        paramcomet=$(echo $PIDparam | awk '{print "-p "$1}')
        PIDparam=$(echo $PIDparam | awk '{$1="";print}')
    fi
    if [[ ${prog} == tandem ]]; then
        paramtandem=$(echo $PIDparam | awk '{print "-p "$1}')
        PIDparam=$(echo $PIDparam | awk '{$1="";print}')
    fi
    if [[ ${prog} == msgfplus ]]; then
        paramMSGFPlus=$(echo $PIDparam | awk '{print "-p "$1}')
        PIDparam=$(echo $PIDparam | awk '{$1="";print}')
    fi
done

# adds all file locations to a variable to test if they are direct references i.e. start with /
if [[ $RUNscripts == "" ]]; then
    DirectTest=$(cat $LOC/install_locations | awk '{print $2" "}')
    DirectTest+=$(echo $input | awk '{print $2" "}')
    DirectTest+=$(echo $output | awk '{print $2" "}')
    DirectTest+=$(echo $logfile | awk '{print $2" "}')
    DirectTest+=$PIDparam
fi
# Tests if each file is a direct reference
for file in $DirectTest
do
    Direct=$(echo ${file} | cut -c 1-1)
    if [[ $Direct != "/" ]] && [[ $Direct != "" ]]; then
        echo "ERROR: ${file} is no a direct reference"
        Exitcode=2
    fi
done

# Exits if a indirect reference has been used
if [[ $Exitcode = 2 ]]; then
    echo "Please use direct references"
    exit
fi


# Creates the files for the PIDs
if [[ $PIDprog != "" ]]; then
    mkdir -vp "$LOC".PIDs
    rm -vf "$LOC".PIDs/*
    # Creates the files that will use comet
    if [[ $PIDprog == *"comet"* ]]; then
        touch "$LOC".PIDs/comet
    fi
    # Creates the files that will use Xtandem
    if [[ $PIDprog == *"tandem"* ]]; then
        touch "$LOC".PIDs/Xtandem
    fi
    # Creates the files that will use MSGFPlus
    if [[ $PIDprog == *"msgfplus"* ]]; then
        touch "$LOC".PIDs/MSGFPlus
    fi
fi
# done creating files for the PIDs


# Adds the validator to the name of the scripts
if [[ $VALprog != "" ]]; then
    mkdir -vp "$LOC".VALs
    rm -vf "$LOC".VALs/*
    # Creates the files that will use PeptideProphet
    if [[ $VALprog == *"peptideprophet"* ]];then
        for file in "$LOC".PIDs/*
        do
            cp -v ${file} ${file}_peptideprophet.sh
            cp "$LOC".PIDs/*_peptideprophet.sh "$LOC".VALs/
            rm -f "$LOC".PIDs/*_peptideprophet.sh
        done
    fi

    if [[ $VALprog == *"triqler"* ]];then
        for file in "$LOC".PIDs/*
        do
            cp -v ${file} ${file}_Triqler.sh
            cp "$LOC".PIDs/*_Triqler.sh "$LOC".VALs/
            rm -f "$LOC".PIDs/*_Triqler.sh
        done
    fi

    if [[ $VALprog == *"percolator"* ]];then
        for file in "$LOC".PIDs/*
        do
            cp -v ${file} ${file}_percolator.sh
            cp "$LOC".PIDs/*_percolator.sh "$LOC".VALs/
            rm -f "$LOC".PIDs/*_percolator.sh
        done
    fi
fi
# done adding validators to the name of the scripts
NUM=$(ls "$LOC".VALs/ | grep ".sh" | wc -l)


# Creates the directory scripts and copies the scripts to it and makes them executable and removes the files in the temp folders
mkdir -vp "$LOC"scripts
cp -v "$LOC".VALs/* "$LOC"scripts/
chmod 744 "$LOC"scripts/*
rm -vf "$LOC".PIDs/* "$LOC".VALs/*


# Adds the options fille to all the scripts
# this should always be first
for file in "$LOC"scripts/*.sh
do
    cat "$LOC"src/options > ${file}
done

# Makes changes to the parameter files
# Changes the comet output file from pep.xml to PIN
for file in "$LOC"scripts/*comet_percolator*
do
    cat "$LOC"src/comet2pin >> ${file}
done
for file in "$LOC"scripts/*MSGFPlus_percolator*
do
    cat "$LOC"src/MSGF2percolator >> ${file}
done



# starts adding PIDs to the scripts
# Adds the comet file to all the scripts containing comet
for file in "$LOC"scripts/*comet*
do
    cat "$LOC"src/comet >> ${file}
done
# Adds the Xtandem file to all the scripts containing Xtandem
for file in "$LOC"scripts/*Xtandem*
do
    cat "$LOC"src/Xtandem >> ${file}
done
# adds the MSGFPlus file to all the scripts containing MSGFPlus
for file in "$LOC"scripts/*MSGFPlus*
do
    cat "$LOC"src/MSGFPlus >> ${file}
done

# done with adding PIDs to the scripts

# starts adding converters to the scripts
# Adds the Tandem2XML file to all the scripts that contain Xtandem and Peptideprophet
for file in "$LOC"scripts/*Xtandem_peptideprophet*
do
    cat "$LOC"src/Tandem2XML >> ${file}
done
for file in "$LOC"scripts/*MSGFPlus_peptideprophet*
do
    cat "$LOC"src/idconvert >> ${file}
done
for file in "$LOC"scripts/*Xtandem_percolator*
do
    cat "$LOC"src/tandem2pin >> ${file}
done
for file in "$LOC"scripts/*MSGFPlus_percolator*
do
    cat "$LOC"src/msgf2pin >> ${file}
done

#done adding converters to the scripts

# starts adding validators to the scripts
# Adds the PeptideProphet file to all the scripts containing peptideprophet
for file in "$LOC"scripts/*peptideprophet*
do
    cat "$LOC"src/PeptideProphet >> ${file}
done
# Adds the Triqler file to all the scripts containing Triqler
for file in "$LOC"scripts/*Triqler*
do
    cat "$LOC"src/Triqler >> ${file}
done
# Adds the percolator file to all the scripts containing percolator
for file in "$LOC"scripts/*percolator*
do
    cat "$LOC"src/percolator >> ${file}
done
# done adding validators to the scripts

for file in "$LOC"scripts/*
do
    cat "$LOC"src/gprofiler >> ${file}
done

for file in "$LOC"scripts/*
do
    cat "$LOC"src/End >> ${file}
done

# The pipeline generates a file named *[program]* if the program was not selected
# the following code removes the files that were created when a program was not selected
# All new programs in the pipeline should be added above this line of code
for file in "$LOC"scripts/\**
do
    rm ${file}
done

# tells the user the scripts are generated
echo "$NUM scripts have been generated"
if [[ $RUNscripts == "" ]]; then
    if [[ $input == "" ]]; then
        echo "Error no input file given"
        exit
    fi
    if [[ $NUMprog > $NUMparam ]]; then
        echo "too few parameter files given"
        exit
    fi
    if [[ $NUMprog < $NUMparam ]]; then
        echo "too many parameter files given"
        exit
    fi
    if [[ $NUMparam == 0 ]]; then
        echo "No parameter files given"
        exit
    fi
fi

# runs the scripts with the correct parameter files for the PIDs
if [[ "$RUNscripts" == "" ]] && [[ "$SHARK" != "1" ]]; then
    while [[ $RUN != [yY] ]]; do
        read -p "Are you sure you want to run the pipeline locally?(y/n): " RUN
        if [[ $RUN == [nN] ]]; then
            exit
        fi
    done
    for file in "$LOC"scripts/*.sh
    do
        PID=$(echo ${file} | awk -F_ '{print $1}' | awk -F/ '{print $NF}')

        if [[ $PID == "comet" ]]; then
            PIDparam=$paramcomet
        fi
        if [[ $PID == "Xtandem" ]]; then
            PIDparam=$paramtandem
        fi
        if [[ $PID == "MSGFPlus" ]]; then
            PIDparam=$paramMSGFPlus
        fi
        ${file} $PIDparam $input $output $logfile $location
    done
fi

if [[ "$RUNscripts" == "" ]] && [[ "$SHARK" == "1" ]]; then
    for file in "$LOC"scripts/*.sh
    do
        PID=$(echo ${file} | awk -F_ '{print $1}' | awk -F/ '{print $NF}')

        if [[ $PID == "comet" ]]; then
            PIDparam=$paramcomet
        fi
        if [[ $PID == "Xtandem" ]]; then
            PIDparam=$paramtandem
        fi
        if [[ $PID == "MSGFPlus" ]]; then
            PIDparam=$paramMSGFPlus
        fi
        qsub $SHARKoptions ${file} $PIDparam $input $output $logfile $location
    done
fi


