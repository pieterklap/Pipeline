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

# allows the options to work
while [ "$1" != "" ]; do

	case $1 in
		-P | --PeptideID )	while [[ ${2:0:1} != "-" ]] && [[ "$1" != "" ]]; do
                            	shift                   # Allows for multiple PeptideIDentifiers (PIDs) to be entered
								PIDprog+=${1,,}" "      # Allows for multiple PeptideIDentifiers (PIDs) to be entered
                            done
							PIDprog1=$(echo "$PIDprog" | awk '{print $1}')	# Allows the parameter files to be used
							PIDprog2=$(echo "$PIDprog" | awk '{print $2}')
							PIDprog3=$(echo "$PIDprog" | awk '{print $3}')
							;;
		-V | --Validator )	while [[ ${2:0:1} != "-" ]] && [[ "$1" != "" ]]; do
                                shift                   # Allows for multiple validators to be entered
                                VALprog+=${1,,}" "      # Allows for multiple validators to be entered
                            done
                            VALprog1=$(echo "$VALprog" | awk '{print $1}')	# Not used will allow parameter files to be used for validators
                            VALprog2=$(echo "$VALprog" | awk '{print $2}')
                            ;;
		-i | --input )		input="$1 $2"
							shift	;;
		-o | --output )		output="$1 $2"
							shift	;;
		-p | -parameters )	while [[ ${2:0:1} != "-" ]] && [[ "$1" != "" ]]; do
								shift
								PIDparam+=$1" "
							done
							;;
		-l | --logfile )	logfile="$1 $2"
							shift
							;;
		-r | --norun )		RUNscripts="n"
							;;
		-s | --shark )		SHARK="1"
							while [[ ${2:0:1} != "-" ]] && [[ "$1" != "" ]]; do
                                shift                  		 # Allows Shark options to be entered
                                SHARKoptions+=$1" " 	     # Allows Shark options to be entered
                            done
							;;
		* )					echo "Unknown parameter ""$1"
							exit
							;;
	esac
	shift
done

# sets the parameter files to be used for each peptide identifier
if [[ "$PIDprog1" == "comet" ]]; then
	paramcomet=$(echo "$PIDparam" | awk '{print $1}')
	paramcomet="-p $paramcomet"
fi
if [[ "$PIDprog2" == "comet" ]]; then
	paramcomet=$(echo "$PIDparam" | awk '{print $2}')
	paramcomet="-p $paramcomet"
fi
if [[ "$PIDprog3" == "comet" ]]; then
    paramcomet=$(echo "$PIDparam" | awk '{print $3}')
    paramcomet="-p $paramcomet"
fi

if [[ "$PIDprog1" == "tandem" ]]; then
	paramtandem=$(echo "$PIDparam" | awk '{print $1}')
	paramtandem="-p $paramtandem"
fi
if [[ "$PIDprog2" == "tandem" ]]; then
	paramtandem=$(echo "$PIDparam" | awk '{print $2}')
	paramtandem="-p $paramtandem"
fi
if [[ "$PIDprog3" == "tandem" ]]; then
    paramtandem=$(echo "$PIDparam" | awk '{print $3}')
    paramtandem="-p $paramtandem"
fi

if [[ "$PIDprog1" == "msgfplus" ]]; then
    paramMSGFPlus=$(echo "$PIDparam" | awk '{print $1}')
    paramMSGFPlus="-p $paramMSGFPlus"
fi
if [[ "$PIDprog2" == "msgfplus" ]]; then
    paramMSGFPlus=$(echo "$PIDparam" | awk '{print $2}')
    paramMSGFPlus="-p $paramMSGFPlus"
fi
if [[ "$PIDprog3" == "msgfplus" ]]; then
    paramMSGFPlus=$(echo "$PIDparam" | awk '{print $3}')
    paramMSGFPlus="-p $paramMSGFPlus"
fi

# adds all file locations to a variable to test if they are direct references i.e. start with /
if [[ $RUNscripts == "" ]]; then
	Test=$(cat $LOC/install_locations | awk '{print $2" "}')
	Test+=$(echo $input | awk '{print $2" "}')
	Test+=$(echo $output | awk '{print $2" "}')
	Test+=$(echo $logfile | awk '{print $2" "}')
	Test+=$PIDparam
fi
# Tests if each file is a direct referance
for file in $Test
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

fi
# done adding validators to the name of the scripts


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

# done adding validators to the scripts


# The pipeline generates a file named *[program]* if the program was not selected
# the following code removes the files that were created when a program was not selected
# All new programs in the pipeline should be added above this line of code
for file in "$LOC"scripts/\**
do
	rm ${file}
done

# tells the user the scripts are generated
echo "All the scripts are generated"
if [[ $RUNscripts == "" ]]; then
	if [[ $input == "" ]] || [[ $PIDparam == "" ]]; then
		echo "Error no input and/or parameter file given"
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

	"$LOC"scripts/comet* $paramcomet $input $output $logfile
	"$LOC"scripts/Xtandem* $paramtandem $input $output $logfile
	"$LOC"scripts/MSGFPlus* $paramMSGFPlus $input $output $logfile

fi

if [[ "$RUNscripts" == "" ]] && [[ "$SHARK" == "1" ]]; then
	qsub $SHARKoptions "$LOC"scripts/comet* $paramcomet $input $output $logfile
	qsub $SHARKoptions "$LOC"scripts/Xtandem* $paramtandem $input $output $logfile
	qsub $SHARKoptions "$LOC"scripts/MSGFPlus* $paramtandem $input $output $logfile

fi
