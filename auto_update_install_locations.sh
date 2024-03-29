#!/bin/bash
case $1 in
    -l | --location )   shift
                        LOC="$1""*"
                        shift
                        ;;
esac

# runs updatedb if the user is root in order to make sure the information is up to date
if [[ $EUID == 0 ]]; then
    updatedb
else
    echo -e "Run the script as root if some programs are missing or removed programs are shown\n"
fi

if [[ $LOC == "" ]]; then
    LOC="*/bin/"
fi

PROGs=${@,,}

#   Programs that work with the pipeline
valid="comet tandem msgfplus msfragger peptideprophet percolator tandem2pin tandem2xml idconvert msgf2pin crux"

# if all has been added check all the programs e.g. $valid
if [[ $PROGs == "all" ]]; then
    PROGs=$valid
fi

for prog in $PROGs
do
    notavalible=0
    # check if the enter name is a program in the pipeline
    for name in $valid
    do
        if [[ ${name} == ${prog} ]]; then
            notavalible=1
        fi
    done

#   Checks all the posible locations of the programs 
    if [[ ${prog} == "comet" ]]; then
        LOCprog=$(locate "$LOC"comet)
        EXProg=$(grep "Comet " install_locations | awk '{print $2}')
    fi
    if [[ ${prog} == "tandem" ]]; then
        LOCprog=$(locate "$LOC"tandem)
        EXProg=$(grep "Tandem " install_locations | awk '{print $2}')
    fi
    if [[ ${prog} == "msgfplus" ]]; then
        LOCprog=$(locate "$LOC"MSGFPlus*.jar)
        EXProg=$(grep "MSGFPlus " install_locations | awk '{print $2}')
    fi
    if [[ ${prog} == "msfragger" ]]; then
        LOCprog=$(locate "$LOC"MSFragger*.jar)
        EXProg=$(grep "MSFragger " install_locations | awk '{print $2}')
    fi
    if [[ ${prog} == "peptideprophet" ]]; then
        LOCprog=$(locate "$LOC"PeptideProphetParser)
        EXProg=$(grep "PeptideProphet " install_locations | awk '{print $2}')
    fi
    if [[ ${prog} == "percolator" ]]; then
        LOCprog=$(locate "$LOC"percolator)
        EXProg=$(grep "percolator " install_locations | awk '{print $2}')
    fi
    if [[ ${prog} == "tandem2xml" ]]; then
        LOCprog=$(locate "$LOC"Tandem2XML)
        EXProg=$(grep "tandem2XML " install_locations | awk '{print $2}')
    fi
    if [[ ${prog} == "tandem2pin" ]]; then
        LOCprog=$(locate "$LOC"tandem2pin)
        EXProg=$(grep "tandem2pin " install_locations | awk '{print $2}')
    fi
    if [[ ${prog} == "idconvert" ]]; then
        LOCprog=$(locate "$LOC"idconvert)
        EXProg=$(grep "idconvert " install_locations | awk '{print $2}')
    fi
    if [[ ${prog} == "msgf2pin" ]]; then
        LOCprog=$(locate "$LOC"msgf2pin)
        EXProg=$(grep "msgf2pin " install_locations | awk '{print $2}')
    fi
    if [[ ${prog} == "crux" ]]; then
        LOCprog=$(locate "$LOC"crux)
        EXProg=$(grep "crux " install_locations | awk '{print $2}')
    fi

#   sets EXProg to something if it is empty if it does not do that it will delete the install_locations file
    if [[ $EXProg == "" ]]; then
        EXProg="something"
        echo "${prog} is not in the install_locations file"
    fi

#   Done checking the location of the programs
#   Tells the user that a program isn't part of the pipeline
    if [[ $notavalible != 1 ]]; then
        echo "${prog} is not an avalible program"
    else
#       Count the amount of programs found
        NUMprog=$(echo $LOCprog | wc -w)
        if [[ "$NUMprog" == "1" ]]; then
#           If only one file has been found enter the file into the install_locations file
            echo -e "\n$NUMprog version of ${prog} found and updated\n$LOCprog"

            sedProg=${LOCprog//\//\\/}               # sets backslashes in front of forward slashes for use with sed
            sedEXProg=${EXProg//\//\\/}

            sed -i "s/$sedEXProg/$sedProg/" install_locations
        fi
#       If more than one program has been found report to the user the amount and which programs
        if [[ "$NUMprog" > "1" ]]; then
            echo -e "\n$NUMprog versions of ${prog} found"
            if (( "$NUMprog" > "10" )); then
                echo -e "\nonly the first 10 results are shown use the option -l [location] to reduce the search space"
                echo "$LOCprog" | head -n10
            else
                echo -e "\n$LOCprog"
            fi
        fi
#       Tells the user which prorgam hasn't been found
        if [[ $NUMprog == 0 ]]; then
            echo -e "\n${prog} not found"
            echo "use the option -l [location] to increase the search space"
        fi
        EXProg=$(grep Comet install_locations | awk '{print $2}')
        Prog=$LOCprog
        #reset variables
        NUMprog=0
        LOCprog=""
    fi
done


exit 0
