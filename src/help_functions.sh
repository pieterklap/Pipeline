#!/bin/bash


comet_Help ()
{
#    echo "comet help file goes here"
    Comet_location=$(grep "comet" $LOC/install_locations | awk '{print $2}' | awk -F\/ '{$NF="";print $0}' | tr " " "/")
    if [ -f "$Comet_location"README.txt ] && [[ "$Comet_location"README.txt != "" ]]; then
        echo "$Comet_location"README.txt
        cat  "$Comet_location"README.txt
    else
        echo -e "More information about comet can be found here: http://comet-ms.sourceforge.net/"
    fi
}

Xtandem_Help ()
{
    echo "Tandem help file goes here"
}

MSGFPlus_Help ()
{
    echo "MSGFPlus help file goes here"
}

MSFragger_Help ()
{
    echo "MSFragger help file goes here"
}

PeptideProphet_Help ()
{
    echo "PeptideProphet help file goes here"
}

percolator_Help ()
{
    echo "percolator help file goes here"
}

all_Help ()
{
    PeptideProphet_Help
    percolator_Help
}

