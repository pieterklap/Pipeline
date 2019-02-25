#!/bin/bash


while [ "$1" != "" ]; do

    case ${1,,} in
		-a | --add )		shift	# Adds another program to the install_locations.sh file only use if you want to add a programm to the pipeline
									# It still needs to be added to the case
							sed "s/@/$1/g" install_locations.template >> install_locations.sh
							;;
        comet )				shift
							Comet="$1"
							;;
		xtandem | tandem )	shift
							Tandem="$1"
							;;
		peptideprophet )	shift
							PeptideProphet="$1"
							;;
		triqler )			shift
							Triqler="$1"
							;;
		tandem2xml )		shift
							Tandem2XML="$1"
							;;
		* )					echo -e " $1 " "is not a program in the pipeline \n"
							shift
							;;
	esac
	shift
done

echo "$Comet"
echo "$Tandem"
echo "$PeptideProphet"
echo "$Tandem2XML"
echo "$Triqler"

if [ -f $Comet ] && [[ $Comet != "" ]]; then
	EXComet=$(grep Comet install_locations)

	sedComet=${Comet//\//\\/}               # sets backslashes in front of forward slashes for use with sed
	sedEXComet=${EXComet//\//\\/}

    sed "s/$sedEXComet/Comet $sedComet/" install_locations > .install_locations
	cat .install_locations > install_locations
	rm .install_locations
fi

if [ -f $Tandem ] && [[ $Tandem != "" ]]; then
    EXTandem=$(grep "Tandem " install_locations)

    sedTandem=${Tandem//\//\\/}               # sets backslashes in front of forward slashes for use with sed
    sedEXTandem=${EXTandem//\//\\/}

	sed "s/$sedEXTandem/Tandem $sedTandem/" install_locations  > .install_locations
    cat .install_locations > install_locations
    rm .install_locations
fi

if [ -f $PeptideProphet ] && [[ $PeptideProphet != "" ]]; then
    EXPeptideProphet=$(grep PeptideProphet install_locations)

    sedPeptideProphet=${PeptideProphet//\//\\/}               # sets backslashes in front of forward slashes for use with sed
    sedEXPeptideProphet=${EXPeptideProphet//\//\\/}

    sed "s/$sedEXPeptideProphet/PeptideProphet $sedPeptideProphet/" install_locations > .install_locations
    cat .install_locations > install_locations
    rm .install_locations
fi

if [ -f $Triqler ] && [[ $Triqler != "" ]]; then
    EXTriqler=$(grep Triqler install_locations)

    sedTriqler=${Triqler//\//\\/}               # sets backslashes in front of forward slashes for use with sed
    sedEXTriqler=${EXTriqler//\//\\/}

    sed "s/$sedEXTriqler/Triqler $sedTriqler/" install_locations > .install_locations
    cat .install_locations > install_locations
    rm .install_locations
fi

if [ -f $Tandem2XML ] && [[ $Tandem2XML != "" ]]; then
    EXTandem2XML=$(grep tandem2XML install_locations)

    sedTandem2XML=${Tandem2XML//\//\\/}               # sets backslashes in front of forward slashes for use with sed
    sedEXTandem2XML=${EXTandem2XML//\//\\/}

    sed "s/$sedEXTandem2XML/tandem2XML $sedTandem2XML/" install_locations > .install_locations
    cat .install_locations > install_locations
    rm .install_locations
fi

