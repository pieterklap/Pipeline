#!/bin/bash

#   The name of the head node of the server cluster the default is shark.
#   If you are not using the shark cluster you can leave it blank or change the name.
#   the script will not directly execute programs on a node with the same name as the variable Head_node_name.
Head_node_name="shark"

PPG="$0"
Entered_Command=" $@"

# $LOC is the directory of the pipeline
LOC=$(echo "$0" |awk -F/ '{$NF="";print $0}' | tr " " "/")
#   if the Pipeline was called using ./PPG.sh set it to $PWD/
if [[ ${LOC:0:1} != "/" ]]; then
    if [[ "$LOC" == "./" ]]; then
        LOC="$PWD/"
    else
        LOC="$PWD/$LOC"
    fi
fi


#   if nothing has been entered output the README.md to the terminal.
if [[ $1 == "" ]]; then
    if [ -f "$LOC"README.md ]; then
        cat "$LOC"README.md
        exit
    else
        echo -e "\e[91mERROR:\e[0m ""$LOC""README.md: No such file or directory"
        exit
    fi
fi


# All the programs that are compatible with the PPG
valid=" comet tandem msgfplus peptideprophet percolator gprofiler reactome "

NUMprog="0"
NUMparam="0"

# allows the options to work
while [ "$1" != "" ]; do
    case "$1" in
        -P | --Programs )   while [[ ${2:0:1} != "-" ]] && [[ "$2" != "" ]]; do
                                shift
                                Programs+="$1 "     # Puts the program names in a variable
                                NUMprog=$[$NUMprog+1]   # Counts the amount of programs entered
                            done
                            ;;
        -L | --location )   location="$1 $2"            # Allows the script to be placed where to user wants
                            END_LOCscripts="$2"
                            shift
                            ;;
        -i | --input )      input="$1 "
                            if [[ ${3:0:1} == "-" ]] && [[ "$3" != "" ]] && [ -f "$2" ]; then
                                shift
                                meta_file_test=$(grep "^/" "$1" | head -n1)
                                #   checks if the file contains file locations
                                for file in $meta_file_test
                                do
                                    meta_file_test=$(echo ${file})
                                done
                                #   tests if it is a file if so puts it into $input
                                if [ -f $meta_file_test ] && [[ $meta_file_test != "" ]]; then
                                    echo "PPG meta file"
                                    input+=$(echo $(sed 's/#.*//g' "$1"))
                                elif [[ $meta_file_test == "" ]]; then
                                    echo "separate file"
                                    input+="$1"
                                else
                                    echo "$meta_file_test is not a file"
                                    exit
                                fi
                            else
                                echo "separate files"
                                while [[ ${2:0:1} != "-" ]] && [[ "$2" != "" ]]; do
                                    shift
                                    if [ -f "$1" ]; then
                                        input+="$1 "
                                    else
                                        echo -e "\e[91mERROR:\e[0m ""$1"" is not a file"
                                        exit
                                    fi
                                done
                            fi
                            ;;
        -o | --output )     output="$1 $2"
                            shift
                            ;;
        -p | --parameters ) while [[ ${2:0:1} != "-" ]] && [[ "$2" != "" ]]; do
                                shift
                                paramsProg+="$1 "
                                NUMparam=$[$NUMparam+1] # Counts the amount of parameter files entered
                            done
                            ;;
        -l | --logfile )    if [[ $2 != "" ]] && [[ ${2:0:1} != "-" ]]; then    #   creates a log file at the given location
                                logfile="$1 $2"                                 #   if no location was given it creates one in
                                shift                                           #   the current working directory
                            else
                                logfile="$1 $PWD"
                            fi
                            ;;
        -r | --repeatrun )  shift
                            if [[ ${1,,} == "pmt" ]]; then
                                RepeatRun_PMT="yes"
                                shift
                                PrecursorMassToleranceIncrement="$1"
                                PrecursorMassToleranceRange="$2 $3"
                                shift
                                shift
                            fi
                            if [[ ${1,,} == "parameter" ]]; then
                                RepeatRun_parameter_files="yes"
                            fi
                            ;;
        -n | --norun )      RUNscripts="n"
                            ;;
        -g | --genparam )   onlyparam="1"
                            ;;
        -S | --noScripts )  Run_scripts="no"
                            while [[ ${2:0:1} != "-" ]] && [[ "$2" != "" ]]; do
                                shift
                                Scripts_to_Run+="$1 "
                            done
                            ;;
        -s | --shark )      SHARK="1"
                            shift                        # Allows Shark options to be entered
                            while [[ $1 != "" ]]; do
                                SHARKoptions+="$1 "             # Allows Shark options to be entered
                                shift
                            done
                            ;;
        --auto-run )        RUN="y"
                            ;;
        -h | --help )       if [ -f "$LOC"README.md ]; then
                                cat "$LOC"README.md
                                exit
                            else
                                echo -e "\e[91mERROR:\e[0m ""$LOC""README.md: No such file or directory"
                                exit
                            fi
                            ;;
        -f | --fused )      one_script_per_DDS="yes"
                            ;;
        --separate )        Separate_TD_search="yes"
                            Extra_parameters+="--separate "
                            ;;
        * )                 echo -e "\e[91mERROR:\e[0m Unknown parameter ""$1"
                            exit
                            ;;
    esac
    shift
done


if [[ $onlyparam == "1" ]] && [[ $paramsProg == "" ]]; then
    echo -e "\e[91mERROR:\e[0m no parameter files entered"
    exit
fi

#   If no Script location has been given set it to a directory named Scripts in the directory of the pipeline
if [[ $END_LOCscripts == "" ]]; then
    END_LOCscripts="$LOC"Scripts/
fi

#   makes the user enter one program
if [[ $Programs == "" ]]; then
    echo -e "\e[91mERROR:\e[0m please enter at least one program"
    exit
fi
#   checks if the validators have been called on the commandline when the fussed option has been used.
#   if they have not add them to programs
if [[ $one_script_per_DDS == "yes" ]]; then
    if [[ ${Programs,,} != *"peptideprophet"* ]]; then
        Programs+="peptideprophet "
        NUMprog=$[$NUMprog+1]
    fi
    if [[ ${Programs,,} != *"percolator"* ]]; then
        Programs+="percolator "
        NUMprog=$[$NUMprog+1]
    fi
fi

#   If all has been entered set Programs to include all the valid programs and skip the validation
if [[ $Programs == *"all"* ]]; then
    Programs=$valid
    NUMprog=$(echo $valid | wc -w)
else
#   Check if the entered programs are a part of the PPG
    for prog in $Programs
    do
        if [[ $valid != *" ${prog,,} "* ]]; then
            echo -e "\n\e[91mERROR:\e[0m ${prog} is not a valid name"
            exit
        fi
    done
fi

# changes the given name to lowercase to make the entering of the program names case insensitive
Programs=${Programs,,}

for parameter_file in $paramsProg
do
    if [ ! -f ${parameter_file} ]; then
        echo -e "\e[91mERROR:\e[0m ${parameter_file} is not a file"
        exit
    fi
done

for input_file in $input
do

    if [ ! -f ${input_file} ] && [[ ${input_file} != "-i" ]] && [[ $onlyparam != "1" ]] && [[ $RUNscripts != "n" ]]; then
        echo -e "\e[91mERROR:\e[0m ${input_file} is not a file"
        exit
    fi
done

# Add the names of the required converters to a variable to check if they are direct references
if [[ $Programs == *"tandem"* ]]; then
    if [[ $Programs == *"peptideprophet"* ]]; then
        converters+="tandem2xml "
    fi
    if [[ $Programs == *"percolator"* ]]; then
        converters+="tandem2pin "
    fi
fi
if [[ $Programs == *"msgfplus"* ]]; then
    if [[ $Programs == *"peptideprophet"* ]]; then
        converters+="idconvert "
    fi
    if [[ $Programs == *"percolator"* ]]; then
        converters+="msgf2pin "
    fi
fi
if [[ $Programs == *"msfragger"* ]]; then
    if [[ $Programs == *"msfragger"* ]]; then
        converters+="crux "
    fi
fi

# Check if install_locations is a file
if [ ! -f $LOC/install_locations ] && [[ $onlyparam != "1" ]]; then
    echo -e "\n\e[93mWARNING:\e[0m "$LOC"install_locations not found"
    echo -e "Programs may not be able to be run without knowing where they are located"
    echo -e "create a file named install_locations in same directory as PPG.sh with the locations of the installed programs\n"
fi

# adds all file locations to a variable to test if they are direct references i.e. start with /
if [[ $RUNscripts == "" ]]; then
#   Only check for programs that are being used
    for prog in $Programs
    do
        DirectTest+=$(grep -i "${prog} " $LOC/install_locations | awk '{print $2" "}')
    done
#   also check the converters
    for prog in $converters
    do
        DirectTest+=$(grep -i "${prog} " $LOC/install_locations | awk '{print $2" "}')
    done
    DirectTest+=$(echo $input | awk '{print $2" "}')
    DirectTest+=$(echo $output | awk '{print $2" "}')
    DirectTest+=$(echo $logfile | awk '{print $2" "}')
    DirectTest+=$paramsProg
    DirectTest+=$(echo $GPparams | awk '{print $2" "}')
    DirectTest+=$(echo $location | awk '{print $2" "}')
fi

# Tests if each file is a direct reference or is not referenced
for file in $DirectTest
do
    Direct=$(echo ${file} | cut -c 1-1)
    if [[ $Direct != "/" ]] && [[ $Direct != "" ]]; then
        echo -e "\e[91mERROR:\e[0m ${file} is not a direct reference"
        Exitcode=2
    fi
done
# Exits if a indirect reference has been used
if [[ $Exitcode = 2 ]]; then
    echo "Please use direct references"
    exit
fi


#   will skip generateing scripts if asked
if [[ $Run_scripts != "no" ]] && [[ $onlyparam != "1" ]]; then

#   Creates the files for the PIDs
    mkdir -vp "$LOC".PIDs
    rm -f "$LOC".PIDs/*
#   Creates the files that will use comet
    if [[ $Programs == *"comet"* ]]; then
        touch "$LOC".PIDs/comet
    fi
#   Creates the files that will use Xtandem
    if [[ $Programs == *"tandem"* ]]; then
        touch "$LOC".PIDs/Xtandem
    fi
#   Creates the files that will use MSGFPlus
    if [[ $Programs == *"msgfplus"* ]]; then
        touch "$LOC".PIDs/MSGFPlus
    fi
    if [[ $Programs == *"msfragger"* ]]; then
        touch "$LOC".PIDs/MSFragger
    fi

#   done creating files for the PIDs


#   Adds the validator to the name of the scripts
    mkdir -vp "$LOC".VALs
    rm -f "$LOC".VALs/*
#   Creates the files that will use PeptideProphet or percolator
   if [[ $one_script_per_DDS == "yes" ]]; then
    #   only create a script named [DDS]_all.sh
        PeptideProphet_base_script="all"
        percolator_base_script="all"

        for file in "$LOC".PIDs/*
        do
            cp ${file} ${file}_all
            cp "$LOC".PIDs/*_all "$LOC".VALs/
            rm -f "$LOC".PIDs/*_all
        done
    else
        PeptideProphet_base_script="PeptideProphet"
        percolator_base_script="percolator"

        if [[ $Programs == *"peptideprophet"* ]];then
            for file in "$LOC".PIDs/*
            do
                cp ${file} ${file}_$PeptideProphet_base_script
                cp "$LOC".PIDs/*_$PeptideProphet_base_script "$LOC".VALs/
                rm -f "$LOC".PIDs/*_$PeptideProphet_base_script
            done
        fi
        if [[ $Programs == *"percolator"* ]];then
            for file in "$LOC".PIDs/*
            do
                cp ${file} ${file}_$percolator_base_script
                cp "$LOC".PIDs/*_$percolator_base_script "$LOC".VALs/
                rm -f "$LOC".PIDs/*_$percolator_base_script
            done
        fi
    fi
#   checks if a validator has been used if not it copies everyting in the .PIDs directory to the .VALs directory
#   It also sets NOVAL to 1 to stop analysis programs from being added
    VALcheck=$(ls "$LOC".VALs)
    if [[ $VALcheck == "" ]]; then
        cp "$LOC".PIDs/* "$LOC".VALs/
        NOVAL="1"
    fi
#   done adding validators to the name of the scripts

#   Counts the amount of scripts that have been generated
    NUM=$(ls "$LOC".VALs/ | wc -l)

#   adds .sh to the files
    LOC=$(echo "$0" |awk -F/ '{$NF="";print $0}' | tr " " "/")

    mkdir -vp "$LOC".END
    rm -f "$LOC".END/*
    for file in "$LOC".VALs/*
    do
        cp ${file} ${file}.sh
        cp "$LOC".VALs/*.sh "$LOC".END/
        rm -f "$LOC".VALs/*.sh
    done

    LOCscripts="$LOC"".END/"

#   Adds the options fille to all the scripts
#   this should always be first
    for file in "$LOCscripts"*.sh
    do
        cat "$LOC"src/base_scripts/options > ${file}
    #   changes PIDhelp_to_be_replaced and VALhelp_to_be_replaced to the name of the PID/VAL
        PIDHELP=$(echo ${file} | awk -F\/ '{print $NF}' | awk -F_ '{print $1}')
        VALHELP=$(echo ${file} | awk -F_ '{print $2}' | awk -F\. '{print $1}')
        LOC_sed=${LOC//\//\\/}
        sed -i "s/LOChelp_to_be_replaced/$LOC_sed/" ${file}
        sed -i "s/PIDhelp_to_be_replaced/$PIDHELP/" ${file}
        sed -i "s/VALhelp_to_be_replaced/$VALHELP/" ${file}
    done

#   Makes changes to the parameter files
#   Changes the comet output file from pep.xml to PIN
    for file in "$LOCscripts"*comet_$percolator_base_script*
    do
        cat "$LOC"src/base_scripts/comet2pin >> ${file}
    done
    for file in "$LOCscripts"*comet_$PeptideProphet_base_script*
    do
        cat "$LOC"src/base_scripts/comet2xml >> ${file}
    done

    for file in "$LOCscripts"*MSGFPlus_$percolator_base_script*
    do
        cat "$LOC"src/base_scripts/MSGF2percolator >> ${file}
    done



#   starts adding PIDs to the scripts
#   Adds the comet file to all the scripts containing comet
    for file in "$LOCscripts"*comet*
    do
        cat "$LOC"src/base_scripts/comet >> ${file}
    done
#   Adds the Xtandem file to all the scripts containing Xtandem
    for file in "$LOCscripts"*Xtandem*
    do
        cat "$LOC"src/base_scripts/Xtandem >> ${file}
    done
#   adds the MSGFPlus file to all the scripts containing MSGFPlus
    for file in "$LOCscripts"*MSGFPlus*
    do
        cat "$LOC"src/base_scripts/MSGFPlus >> ${file}
    done
    for file in "$LOCscripts"*MSFragger*
    do
        cat "$LOC"src/base_scripts/MSFragger >> ${file}
    done

#   done with adding PIDs to the scripts

#   Add an intermediate time to the script
    for file in "$LOCscripts"*.sh
    do
        cat "$LOC"src/base_scripts/"time" >> ${file}
    done


#   starts adding converters to the scripts
#   Adds the Tandem2XML file to all the scripts that contain Xtandem and Peptideprophet
    for file in "$LOCscripts"*Xtandem_$PeptideProphet_base_script*
    do
        cat "$LOC"src/base_scripts/Tandem2XML >> ${file}
    done
    for file in "$LOCscripts"*MSGFPlus_$PeptideProphet_base_script*
    do
        cat "$LOC"src/base_scripts/idconvert >> ${file}
    done
    for file in "$LOCscripts"*Xtandem_$percolator_base_script*
    do
        cat "$LOC"src/base_scripts/tandem2pin >> ${file}
    done
    for file in "$LOCscripts"*MSGFPlus_$percolator_base_script*
    do
        cat "$LOC"src/base_scripts/msgf2pin >> ${file}
    done
    for file in "$LOCscripts"*MSFragger_$percolator_base_script*
    do
        cat "$LOC""src/base_scripts/make-pin" >> ${file}
    done

#   done adding converters to the scripts

#   starts adding validators to the scripts
#   Adds the PeptideProphet file to all the scripts containing peptideprophet
    for file in "$LOCscripts"*$PeptideProphet_base_script*
    do
        cat "$LOC"src/base_scripts/PeptideProphet >> ${file}
    done
#   Adds the percolator file to all the scripts containing percolator
    for file in "$LOCscripts"*$percolator_base_script*
    do
        cat "$LOC"src/base_scripts/percolator >> ${file}
    done
#   done adding validators to the scripts

#   Add an intermediate time to the script
    for file in "$LOCscripts"*_*.sh
    do
        cat "$LOC"src/base_scripts/"time" >> ${file}
    done

#   Adds analysis tools to the pipeline
    if [[ $Programs == *"gprofiler"* ]] && [[ $NOVAL != "1" ]]; then
        for file in "$LOCscripts"*.sh
        do
            cat "$LOC"src/base_scripts/gprofiler >> ${file}
        done
    fi
    if [[ $Programs == *"reactome"* ]] && [[ $NOVAL != "1" ]]; then
        for file in "$LOCscripts"/*.sh
        do
            cat "$LOC"src/base_scripts/Reactome >> ${file}
        done
    fi

#   add the ending part to the script needed to know how long it took to run the scripts
    for file in "$LOCscripts"*.sh
    do
        cat "$LOC"src/base_scripts/End >> ${file}
        echo "Generated ""$END_LOCscripts""$(echo "${file}" | awk -F\/ '{print $NF}')"
    done

#   puts the name of the script in the script (changes the name of the job on the shark cluster)
    for file in "$LOCscripts"*.sh
    do
        Script_Name=$(echo ${file} | awk -F\/ '{print $NF}' | awk -F. '{print $1}')
        sed -i "s/Script_Name_shark_cluster/$Script_Name/" ${file}
    done

#   The pipeline generates a file named *[program]* if the program was not selected
#   the following code removes the files that were created when a program was not selected
#   All new programs in the pipeline should be added above this line of code
    for file in "$LOCscripts"\**
    do
        rm -f "${file}"
    done

    LOCscripts="$END_LOCscripts"
#   Creates the directory scripts and copies the scripts to it and makes them executable and removes the files in the temp folders
    if [ ! -d "$LOCscripts" ]; then
        mkdir -vp "$LOCscripts"
    fi
    for file in "$LOC".END/*
    do
        cp "${file}" "$LOCscripts"
        Scripts_to_Run+="$LOCscripts""$(echo "${file}" | awk -F\/ '{print $NF}') "
    done
    chmod 750 "$LOCscripts"*
    rm -f "$LOC".PIDs/* "$LOC".VALs/*
    rm -f "$LOC".END/*


#   copies the install_locations to the locations of the scripts
    cp -v "$LOC"install_locations "$LOCscripts"

#   tells the user the scripts are generated
    if (($NUM == 1)); then
        echo "$NUM script has been generated"
    else
        echo "$NUM scripts have been generated"
    fi

#   Tells the user if a program has not been added because a previous program was required
    if  [[ $NOVAL == "1" ]]; then
        if [[ $Programs == *"gprofiler"* ]]; then
            echo -e "\e[93mWARNING:\e[0m g:profiler isn't added to the script because it requires at least one validator"
        fi
        if [[ $Programs == *"reactome"* ]]; then
            echo -e "\e[93mWARNING:\e[0m Reactome isn't added to the script because it requires at least one validator"
        fi
    fi
fi

# if header check is placed here the -r parameter option will no longer be needed
source "$LOC"src/Shared_parameter_maker.sh

#   Checks if the first parameter file is a PPG parameter file if it is it assumes the others are aswell
LOC_Shared_param_file="$(echo $paramsProg | awk '{print $1}')"
if [[ $LOC_Shared_param_file != "" ]]; then
    Header_Check
fi
if [[ "$Header" == "$Header_file" ]] && [[ $LOC_Shared_param_file != "" ]]; then
    if (($NUMparam>=2)); then
        RepeatRun_parameter_files="yes"
    else
        Run_PPG_with_sharedparam="yes"
    fi
fi
#   reapeat run parameters
if [[ $RepeatRun_parameter_files == "yes" ]] && (($NUMparam>=2)); then
    if [[ $Times_Run == "" ]]; then
        Times_Run=0
    fi
    for param_file in $paramsProg
    do
        #   Checks the header
        LOC_Shared_param_file=${param_file}
        Header_Check
        Header_Exit
        #   TODO check if output_suffix has been set
        if [[ $(grep "^Output_suffix" ${param_file} | awk '{print $4}') == "" ]]; then
            echo -e "\e[91mERROR\e[0m ${param_file}: No output suffix given. \n      Without it the names of the output files would be the same"
        else
            sed_param_file=${param_file//\//\\/}
            sed_paramsProg=${paramsProg//\//\\/}

            $PPG $(echo "$Entered_Command -S $Scripts_to_Run" | sed "s/$sed_paramsProg/$sed_param_file /")
            Times_Run=$[$Times_Run+1]
        fi
    done
    exit
fi

# if only one parameter file was entered but multiple programs the pipeline assumes the parameter file is the Shared parameter file.
if [[ $Run_PPG_with_sharedparam == "yes" ]]; then
#   Use the Shared parameter file
    echo "not fully implemented yet"

    LOC_Shared_param_file="$paramsProg"
    echo "PPG parameter file"

#   removes the spaces between the parameter name and value and makes sure there is one space between each parameter
    Shared_param_file=$(grep -v "^#" $LOC_Shared_param_file | sed "s/ //g" | tr "\n" " " | tr "\t" " " | sed "s/ \+/ /g" |tr " " "\n" )

#   notes the output directory of the shared parameter file
    LOC_param=$(echo $LOC_Shared_param_file | awk -F/ '{$NF="";print $0}' | tr " " "/")
#   resets the parameter counter
    NUMparam="0"
#   uses the functions in the following bash scripts
    Header_Check
    Header_Exit
    Default_check

    source "$LOC"src/modifications.sh
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
    if [[ $Programs == *"msfragger"* ]]; then
        MSFragger
        MSFragger_mods
        msfragger="$MSFraggerparam"
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
    if [[ $Programs == *"gprofiler"* ]]; then
        Gprofiler                       #   For use later if gprofiler gets added to the shared parameter file
        gprofiler="$gprofilerParam"     #
        NUMparam=$[$NUMparam+1]
    fi
    if [[ $Programs == *"reactome"* ]]; then
        Reactome                        #   For use later if Reactome gets added to the shared parameter file
        reactome="$ReactomeParam"       #
        NUMparam=$[$NUMparam+1]
    fi

#   if the number of parameter files is equal to the amount of programs run this
    elif (($NUMparam==$NUMprog)); then
#   use the parameter files the user entered
    echo "idividual parameter files"
# sets the parameter files to be used for each peptide identifier
    for prog in $Programs
    do
#   Puts the parameter location into a variable with the programs name and removes the location from the string of locations
        paramloc=$(echo $paramsProg | awk '{print $1}')
        declare "${prog}"="$paramloc"
        paramsProg=$(echo $paramsProg | awk '{$1="";print}')
    done
#   if the cluster option is used change the memory requirement for java because the shark cluster doesn't allocate memory correctly
#   the amount that the memory is changed is in the CPU_Use function in src/Shared_parameter_maker.sh
    if [[ $SHARK == "1" ]]; then
        if [[ $Programs == *"msgfplus"* ]]; then
            SHARKoptions_CPUUse=$SHARKoptions
            CPU_Use $SHARKoptions_CPUUse
            MSGFPlus_Mem_Use=$(grep "^#Mem_Use" $msgfplus | awk '{print $2}')
            if [[ $MSGFPlus_Mem_Use != "" ]]; then
                if [[ $MSGFPlus_Mem_Use != $Mem_Use ]]; then
                    sed -i "s/#Mem_Use .*/#Mem_Use $Mem_Use/" $msgfplus
                    echo "MS-GF+: The amount of memory availible to java has been adjusted to $Mem_Use from $MSGFPlus_Mem_Use"
                fi
            else
                echo "#Mem_Use $Mem_Use" >> $msgfplus
                echo "MS-GF+: The amount of memory availible to java has been set to $Mem_Use"
            fi
        fi
        if [[ $Programs == *"msfragger"* ]]; then
            SHARKoptions_CPUUse=$SHARKoptions
            CPU_Use $SHARKoptions_CPUUse
            MSFragger_Mem_Use=$(grep "^#Mem_Use" $msfragger | awk '{print $2}')
            if [[ $MSFragger_Mem_Use != "" ]]; then
                if [[ $MSFragger_Mem_Use != $Mem_Use ]]; then
                    sed -i "s/#Mem_Use .*/#Mem_Use $Mem_Use/" $msfragger
                    echo "MSFragger: The amount of memory availible to java has been adjusted to $Mem_Use from $MSFragger_Mem_Use"
                fi
            else
                echo "#Mem_Use $Mem_Use" >> $msfragger
                echo "MSFragger: The amount of memory availible to java has been set to $Mem_Use"
            fi
        fi
    fi

else
    #   If all else fails exit
    if [[ $RUNscripts != "n" ]]; then
        if [[ $NUMparam == "0" ]]; then
            RUNscripts="n"
            echo -e "\e[93mWARNING:\e[0m No parameter file was given, only creating the scripts."
        else
            echo -e "\e[91mERROR:\e[0m number of programs($NUMprog) is not equal to the number of parameter files($NUMparam) given"
            exit
        fi
    fi
fi

# Exits if only the parameterfiles were required
if [[ $onlyparam == "1" ]] && [[ $LOC_Shared_param_file != "" ]]; then
    echo "the parameter files have been genegrated"
    exit
fi

#   End of asigning/generating parameter files

#   Load the file that runs the scripts
source $LOC/src/run_pipeline.sh

#   Run the scripts localy
if [[ "$RUNscripts" == "" ]] && [[ "$SHARK" != "1" ]]; then

    if [[ "$RepeatRun_PMT" == "yes" ]]; then
        Repeat_Run_Local
    else
        Local_Run
    fi
fi

#   Run the scripts on the sharkcluster
if [[ "$RUNscripts" == "" ]] && [[ "$SHARK" == "1" ]]; then

    if  [[ "$RepeatRun_PMT" == "yes" ]]; then
        Repeat_Run_Shark
    else
        Shark_Run
    fi
fi

#END of pipeline generator
exit

