#!/bin/bash

if [[ $1 == "" ]]; then
    cat README.md
    exit
fi

# $LOC is the directory of the pipeline
LOC=$(echo "$0" |awk -F/ '{$NF="";print $0}' | tr " " "/")

if [[ $LOC == "./" ]]; then
    LOC="$PWD/"
fi

valid="comet tandem msgfplus peptideprophet percolator gprofiler"

NUMprog="0"
NUMparam="0"

#echo $LOC
# allows the options to work
while [ "$1" != "" ]; do

    case $1 in
        -P | --Programs )   while [[ ${2:0:1} != "-" ]] && [[ "$2" != "" ]]; do
                                shift
                                Programs+=${1,,}" "     # Puts the program names in a variable
                                NUMprog=$[$NUMprog+1]   # Counts the amount of programs entered
                            done
                            ;;
        -L | --location )   location="$1 $2"            # If the script isn't ran where it was created (for use on the shark cluster) Probably redundent
                            LOCscripts="$2"
                            shift
                            ;;
        -i | --input )      input="$1 $2"
                            shift
                            ;;
        -o | --output )     output="$1 $2"
                            shift
                            ;;
        -p | --parameters ) while [[ ${2:0:1} != "-" ]] && [[ "$2" != "" ]]; do
                                shift
                                paramsProg+=$1" "
                                NUMparam=$[$NUMparam+1] # Counts the amount of parameter files entered
                            done
                            ;;
        -l | --logfile )    logfile="$1 $2"
                            shift
                            ;;
        -r | --norun )      RUNscripts="n"
                            ;;
        -g | --genparam )   onlyparam="1"
                            ;;
        -s | --shark )      SHARK="1"
                            shift                        # Allows Shark options to be entered
                            SHARKoptions=$1             # Allows Shark options to be entered
                            ;;
        * )                 echo "Unknown parameter ""$1"
                            exit
                            ;;
    esac
    shift
done

if [[ $LOCscripts == "" ]]; then
    LOCscripts="$LOC"scripts
fi


# adds all file locations to a variable to test if they are direct references i.e. start with /
if [[ $RUNscripts == "" ]]; then
    DirectTest=$(cat $LOC/install_locations | awk '{print $2" "}')
    DirectTest+=$(echo $input | awk '{print $2" "}')
    DirectTest+=$(echo $output | awk '{print $2" "}')
    DirectTest+=$(echo $logfile | awk '{print $2" "}')
    DirectTest+=$PIDparam
    DirectTest+=$(echo $GPparams | awk '{print $2" "}')
fi
# Tests if each file is a direct reference
for file in $DirectTest
do
    Direct=$(echo ${file} | cut -c 1-1)
    if [[ $Direct != "/" ]] && [[ $Direct != "" ]]; then
        echo "ERROR: ${file} is not a direct reference"
        Exitcode=2
    fi
done

# Exits if a indirect reference has been used
if [[ $Exitcode = 2 ]]; then
    echo "Please use direct references"
    exit
fi


# if only one parameter file was entered but multiple programs the pipeline assumes the parameter file is the Shared parameter file.
if (($NUMprog > 1)) && [[ $NUMparam == "1" ]]; then
#   Use the Shared parameter file
    echo "not fully implemented yet"

    LOC_Shared_param_file="$paramsProg"
    echo "Shared param file"

#   removes the spaces between the parameter name and value and makes sure there is one space between each parameter
    Shared_param_file=$(grep -v "^#" $LOC_Shared_param_file | sed "s/ //g" | tr "\n" " " | tr "\t" " " | sed "s/ \+/ /g" |tr " " "\n" )

#   if no output directory is given set the outputdirectory to the working directory
    LOC_param=$(echo $LOC_Shared_param_file | awk -F/ '{$NF="";print $0}' | tr " " "/")
    output_dir=$LOC_param
#   resets the parameter counter
    NUMparam="0"
#   uses the functions in the following bash scripts
    source "$LOC"Shared_parameter_maker.sh
    source "$LOC"modifications.sh
    if [[ $Programs == *"comet"* ]]; then
        Comet                   #   generates the main bulk of the parameter file
        Comet_mods              #   generates the modification data for the parameter file
        comet="$cometparam"     #   sets the variable comet to the generated comet parameterfile
        NUMparam=$[$NUMparam+1] #   recounts the parameter files
    fi
    if [[ $Programs == *"tandem"* ]]; then
        Tandem
        Tandem_mods
        tandem="$Tandemparam_input"
        NUMparam=$[$NUMparam+1]
    fi
    if [[ $Programs == *"msgfplus"* ]]; then
        MSGFPlus
        MSGFPlus_mods
        msgfplus="$MSGFPlusparam"
        NUMparam=$[$NUMparam+1]
    fi
    if [[ $Programs == *"peptideprophet"* ]]; then
        PeptideProphet                  #   For use later if peptideprophet gets added to the shared parameter file
        peptideprophet="$PepProphParam" #
        NUMparam=$[$NUMparam+1]
    fi
    if [[ $Programs == *"percolator"* ]]; then
        Percolator                      #   For use later if percolator gets added to the shared parameter file
        percolator="$PercolatorParam"   #
        NUMparam=$[$NUMparam+1]
    fi
else
#   use the parameter files the user entered
    echo "idividual parameter files"

# sets the parameter files to be used for each peptide identifier
    for prog in $Programs
    do
#   Check if the entered programs are a part of the pipeline
        avalible=0
        for name in $valid
        do
            if [[ ${name} == ${prog} ]]; then
                avalible=1
            fi
        done
        if [[ $avalible != 1 ]]; then
            echo "ERROR: ${prog} is not a valid name"
            exit
        fi
#   Puts the parameter location into a variable with the programs name and removes the location from the string of locations
        paramloc=$(echo $paramsProg | awk '{print $1}')
        declare "${prog}"="$paramloc"
        paramsProg=$(echo $paramsProg | awk '{$1="";print}')
    done

fi

# Exits if only the parameterfiles were required
if [[ $onlyparam == "1" ]] && [[ $LOC_Shared_param_file != "" ]]; then
    echo "the parameter files have been genegrated"
    exit
fi

# Creates the files for the PIDs
mkdir -vp "$LOC".PIDs
rm -vf "$LOC".PIDs/*
# Creates the files that will use comet
if [[ $Programs == *"comet"* ]]; then
    touch "$LOC".PIDs/comet
fi
# Creates the files that will use Xtandem
if [[ $Programs == *"tandem"* ]]; then
    touch "$LOC".PIDs/Xtandem
fi
# Creates the files that will use MSGFPlus
if [[ $Programs == *"msgfplus"* ]]; then
    touch "$LOC".PIDs/MSGFPlus
fi
# done creating files for the PIDs


# Adds the validator to the name of the scripts
mkdir -vp "$LOC".VALs
rm -vf "$LOC".VALs/*
# Creates the files that will use PeptideProphet
if [[ $Programs == *"peptideprophet"* ]];then
    for file in "$LOC".PIDs/*
    do
        cp -v ${file} ${file}_peptideprophet
        cp "$LOC".PIDs/*_peptideprophet "$LOC".VALs/
        rm -f "$LOC".PIDs/*_peptideprophet
    done
fi
if [[ $Programs == *"triqler"* ]];then
    for file in "$LOC".PIDs/*
    do
        cp -v ${file} ${file}_Triqler
        cp "$LOC".PIDs/*_Triqler "$LOC".VALs/
        rm -f "$LOC".PIDs/*_Triqler
    done
fi
if [[ $Programs == *"percolator"* ]];then
    for file in "$LOC".PIDs/*
    do
        cp -v ${file} ${file}_percolator
        cp "$LOC".PIDs/*_percolator "$LOC".VALs/
        rm -f "$LOC".PIDs/*_percolator
    done
fi

# checks if a validator has been used if not it copies everyting in the .PIDs directory to the .VALs directory
# It also sets NOVAL to 1 to stop analysis programs from being added
VALcheck=$(ls "$LOC".VALs)
if [[ $VALcheck == "" ]]; then
    cp "$LOC".PIDs/* "$LOC".VALs/
    NOVAL="1"
fi
# done adding validators to the name of the scripts

NUM=$(ls "$LOC".VALs/ | wc -l)
# adds .sh to the files

mkdir -vp "$LOC".END
rm -vf "$LOC".END/*
for file in "$LOC".VALs/*
do
    cp -v ${file} ${file}.sh
    cp "$LOC".VALs/*.sh "$LOC".END/
    rm -f "$LOC".VALs/*.sh
done

# Creates the directory scripts and copies the scripts to it and makes them executable and removes the files in the temp folders
rm -v "$LOCscripts"/*
mkdir -vp "$LOCscripts"
cp -v "$LOC".END/* "$LOCscripts"/
chmod 750 "$LOCscripts"/*
rm -vf "$LOC".PIDs/* "$LOC".VALs/*
rm -f "$LOC".END/*
# Adds the options fille to all the scripts
# this should always be first
for file in "$LOCscripts"/*.sh
do
    cat "$LOC"src/options > ${file}
done

# Makes changes to the parameter files
# Changes the comet output file from pep.xml to PIN
for file in "$LOCscripts"/*comet_percolator*
do
    cat "$LOC"src/comet2pin >> ${file}
done
for file in "$LOCscripts"/*MSGFPlus_percolator*
do
    cat "$LOC"src/MSGF2percolator >> ${file}
done



# starts adding PIDs to the scripts
# Adds the comet file to all the scripts containing comet
for file in "$LOCscripts"/*comet*
do
    cat "$LOC"src/comet >> ${file}
done
# Adds the Xtandem file to all the scripts containing Xtandem
for file in "$LOCscripts"/*Xtandem*
do
    cat "$LOC"src/Xtandem >> ${file}
done
# adds the MSGFPlus file to all the scripts containing MSGFPlus
for file in "$LOCscripts"/*MSGFPlus*
do
    cat "$LOC"src/MSGFPlus >> ${file}
done

# done with adding PIDs to the scripts

# starts adding converters to the scripts
# Adds the Tandem2XML file to all the scripts that contain Xtandem and Peptideprophet
for file in "$LOCscripts"/*Xtandem_peptideprophet*
do
    cat "$LOC"src/Tandem2XML >> ${file}
done
for file in "$LOCscripts"/*MSGFPlus_peptideprophet*
do
    cat "$LOC"src/idconvert >> ${file}
done
for file in "$LOCscripts"/*Xtandem_percolator*
do
    cat "$LOC"src/tandem2pin >> ${file}
done
for file in "$LOCscripts"/*MSGFPlus_percolator*
do
    cat "$LOC"src/msgf2pin >> ${file}
done

#done adding converters to the scripts

# starts adding validators to the scripts
# Adds the PeptideProphet file to all the scripts containing peptideprophet
for file in "$LOCscripts"/*peptideprophet*
do
    cat "$LOC"src/PeptideProphet >> ${file}
done
# Adds the Triqler file to all the scripts containing Triqler
for file in "$LOCscripts"/*Triqler*
do
    cat "$LOC"src/Triqler >> ${file}
done
# Adds the percolator file to all the scripts containing percolator
for file in "$LOCscripts"/*percolator*
do
    cat "$LOC"src/percolator >> ${file}
done
# done adding validators to the scripts
# Adds analysis tools to the pipeline
if [[ $Programs == *"gprofiler"* ]] && [[ $NOVAL != "1" ]]; then
    for file in "$LOCscripts"/*.sh
    do
        cat "$LOC"src/gprofiler >> ${file}
    done
fi

for file in "$LOCscripts"/*.sh
do
    cat "$LOC"src/End >> ${file}
done

# The pipeline generates a file named *[program]* if the program was not selected
# the following code removes the files that were created when a program was not selected
# All new programs in the pipeline should be added above this line of code
for file in "$LOCscripts"/\**
do
    rm ${file}
done

cp "$LOC"install_locations "$LOCscripts"/

# tells the user the scripts are generated
echo "$NUM scripts have been generated"
if [[ $NOVAL == "1" ]] && [[ $gprofiler != "" ]]; then
    echo "g:profiler isn't added to the script because it requires at least one validator"
fi

# Checks if the required parameters have been passed to the script
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
    for file in "$LOCscripts"/*.sh
    do
        # Sets the correct parameter files to be used with the corect program
        PID=$(echo ${file} | awk -F. '{print $1}' | awk -F_ '{print $1}' | awk -F/ '{print $NF}')
        VAL=$(echo ${file} | awk -F. '{print $1}' | awk -F_ '{print $2}')

        if [[ $PID == "comet" ]]; then
            PIDparam="-p $comet"
        fi
        if [[ $PID == "Xtandem" ]]; then
            PIDparam="-p $tandem"
        fi
        if [[ $PID == "MSGFPlus" ]]; then
            PIDparam="-p $msgfplus"
        fi
        if [[ $VAL == "peptideprophet" ]]; then
            VALparam="-v $peptideprophet"
        fi
        if [[ $VAL == "percolator" ]]; then
            VALparam="-v $percolator"
        fi
        if [[ $gprofiler != "" ]] && [[ $NOVAL != "1" ]]; then
            GPparams="-g $gprofiler"
        fi
#           Run the pipeline for each combination of programs
            ${file} $PIDparam $VALparam $input $output $logfile $location $GPparams
    done
fi

if [[ "$RUNscripts" == "" ]] && [[ "$SHARK" == "1" ]]; then
    if [[ $location == "" ]]; then
        location="-L $LOC/scripts"
    fi

    for file in "$LOCscripts"/*.sh
    do
        # Sets the correct parameter files to be used with the corect program
        PID=$(echo ${file} | awk -F. '{print $1}' | awk -F_ '{print $1}' | awk -F/ '{print $NF}')
        VAL=$(echo ${file} | awk -F. '{print $1}' | awk -F_ '{print $2}')

        if [[ $PID == "comet" ]]; then
            PIDparam="-p $comet"
        fi
        if [[ $PID == "Xtandem" ]]; then
            PIDparam="-p $tandem"
        fi
        if [[ $PID == "MSGFPlus" ]]; then
            PIDparam="-p $msgfplus"
        fi
        if [[ $VAL == "peptideprophet" ]]; then
            VALparam="-v $peptideprophet"
        fi
        if [[ $VAL == "percolator" ]]; then
            VALparam="-v $percolator"
        fi
        if [[ $gprofiler != "" ]] && [[ $NOVAL != "1" ]]; then
            GPparams="-g $gprofiler"
        fi
        qsub $SHARKoptions ${file} $PIDparam $input $output $logfile $location $GPparams
    done
fi

#END of pipeline generator
exit
