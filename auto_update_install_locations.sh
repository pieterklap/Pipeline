#!/bin/bash

# runs updatedb if the user is root in order to make sure the information is up to date
if [[ $EUID == 0 ]]; then
    updatedb
else
    echo -e "Run the script as root if some programs are missing or removed programs are shown\n"
fi


PROGs=${@,,}

#   Programs that work with the pipeline
valid="comet tandem msgfplus peptideprophet percolator tandem2pin tandem2xml idconvert msgf2pin"

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
        LOCprog=$(locate comet.exe)
        EXProg=$(grep "Comet " install_locations | awk '{print $2}')
    fi
    if [[ ${prog} == "tandem" ]]; then
        LOCprog=$(locate tandem.exe)
        EXProg=$(grep "Tandem " install_locations | awk '{print $2}')
    fi
    if [[ ${prog} == "msgfplus" ]]; then
        LOCprog=$(locate MSGFPlus.jar)
        EXProg=$(grep "MSGFPlus " install_locations | awk '{print $2}')
    fi
    if [[ ${prog} == "peptideprophet" ]]; then
        LOCprog=$(locate bin/PeptideProphetParser)
        EXProg=$(grep "PeptideProphet " install_locations | awk '{print $2}')
    fi
    if [[ ${prog} == "percolator" ]]; then
        LOCprog=$(locate bin/percolator)
        EXProg=$(grep "percolator " install_locations | awk '{print $2}')
    fi
    if [[ ${prog} == "tandem2xml" ]]; then
        LOCprog=$(locate bin/Tandem2XML)
        EXProg=$(grep "tandem2XML " install_locations | awk '{print $2}')
    fi
    if [[ ${prog} == "tandem2pin" ]]; then
        LOCprog=$(locate bin/tandem2pin)
        EXProg=$(grep "tandem2pin " install_locations | awk '{print $2}')
    fi
    if [[ ${prog} == "idconvert" ]]; then
        LOCprog=$(locate bin/idconvert)
        EXProg=$(grep "idconvert " install_locations | awk '{print $2}')
    fi
    if [[ ${prog} == "msgf2pin" ]]; then
        LOCprog=$(locate bin/msgf2pin)
        EXProg=$(grep "msgf2pin " install_locations | awk '{print $2}')
    fi
#   Done checking the location of the programs
#   Tells the user that a program isn't part of the pipeline
    if [[ $notavalible != 1 ]]; then
        echo "${prog} is not an avalible program"
    else
        #count the amount of programs found
        NUMprog=$(echo $LOCprog | wc -w)
        if [[ $NUMprog == "1" ]]; then
            #if only one file has been found enter the file into the install_locations file
            echo -e "\n$NUMprog version of ${prog} found and updated\n$LOCprog"

            sedProg=${LOCprog//\//\\/}               # sets backslashes in front of forward slashes for use with sed
            sedEXProg=${EXProg//\//\\/}

            sed "s/$sedEXProg/$sedProg/" install_locations > .install_locations
            cat .install_locations > install_locations
            rm .install_locations
        fi
        # errors if more than one program has been foun report to the user the amount and which programs
        if [[ $NUMprog > 1 ]]; then
            echo -e "\n$NUMprog versions of ${prog} found"
            if [[ $NUMprog < 10 ]]; then
                echo -e "\nonly the first 10 results are shown"
                echo "$LOCprog" | head -n10
            else
                echo -e "\n$LOCprog"
            fi
        fi
#       Tells the user which prorgam hasn't been found
        if [[ $NUMprog == 0 ]]; then
            echo -e "\n${prog} not found"
        fi
        EXProg=$(grep Comet install_locations | awk '{print $2}')
        Prog=$LOCprog
        #reset variables
        NUMprog=0
        LOCprog=""
    fi
done


exit 0
