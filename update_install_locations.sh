#!/bin/bash

while [ "$1" != "" ]; do

    case ${1,,} in
#Databse searchers
        comet )				shift
                            LOCprograms+="$1 "
							programs+="Comet "
							;;
		xtandem | tandem )	shift
                            LOCprograms+="$1 "
							programs+="Tandem "
                            ;;
        msgfplus | msgf+ )  shift
                            LOCprograms+="$1 "
                            programs+="MSGFPlus "
							;;
# Validators
		peptideprophet )	shift
                            LOCprograms+="$1 "
							programs+="PeptideProphet "
							;;
        percolator )        shift
                            LOCprograms+="$1 "
                            programs+="percolator "
                            ;;
		triqler )			shift
                            LOCprograms+="$1 "
							programs+="Triqler "
							;;
# Converters
		tandem2xml )		shift
                            LOCprograms+="$1 "
							programs+="tandem2XML "
							;;
        tandem2pin )        shift
                            LOCprograms+="$1 "
                            programs+="tandem2pin "
                            ;;
        idconvert )         shift
                            LOCprograms+="$1 "
                            programs+="idconvert "
                            ;;
        msgf2pin )          shift
                            LOCprograms+="$1 "
                            programs+="msgf2pin "
                            ;;
		* )					echo -e " $1 " "is not a program in the pipeline \n"
							shift
							;;
	esac
	shift
done

for prog in $programs
do
    # sets the first location in $LOCprograms to $Prog and then removes it form $LOCprograms
    Prog=$(echo $LOCprograms | awk '{print $1}')
    LOCprograms=$(echo $LOCprograms | awk '{$1="";print}')

    if [ -f $Prog ] && [[ $Prog != "" ]]; then
    	EXProg=$(grep "${prog} " install_locations)

	    sedProg=${Prog//\//\\/}               # sets backslashes in front of forward slashes for use with sed
        sedEXProg=${EXProg//\//\\/}

        sed -i "s/$sedEXProg/${prog} $sedProg/" install_locations
    fi
done
