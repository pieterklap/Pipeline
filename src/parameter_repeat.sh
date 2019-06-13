#!/bin/bash

#   sets the start and end number for the Mass Tolerence
    PrecursorMassTolerance=$(echo $PrecursorMassToleranceRange | awk '{print $1}')
    PrecursorMassToleranceMax=$(echo $PrecursorMassToleranceRange | awk '{print $2}')

#   Checks if a decimal number has been added TODO: check the other PrecursorMassTolerenceiables as well
    Deci=$(echo $PrecursorMassToleranceIncrement | awk -F. '{print $2}')
    if [[ $Deci != "" ]]; then
        Deci="yes"
    fi

#   sets the whole number of the Inceremting to a PrecursorMassTolerenceiable
    PrecursorMassToleranceIncrement1=$(echo $PrecursorMassToleranceIncrement | awk -F. '{print $1}')
#   if a value has been given that didn't specify the whole number it is assumed as 0 ( e.g. [.5])
    if [[ $PrecursorMassToleranceIncrement1 == "" ]]; then
        PrecursorMassToleranceIncrement1="0"
    fi
#   and the same for the decimal value.
    if [[ $Deci == "yes" ]]; then
        PrecursorMassToleranceIncrement2=$(echo $PrecursorMassToleranceIncrement | awk -F. '{print $2}')
    else
        PrecursorMassToleranceIncrement2="0"
    fi


SET_Tollerance_values ()
{
#   set the start for PrecursorMassTolerence
    PrecursorMassTolerence1=$(echo $PrecursorMassTolerance | awk -F. '{print $1}')
    PrecursorMassTolerence2=$(echo $PrecursorMassTolerance | awk -F. '{print $2}')
    if [[ $PrecursorMassTolerence2 == "" ]]; then
        PrecursorMassTolerence2="0"
    fi
#   Set the end for the PrecursorMassTolerence
    PrecursorMassToleranceMax1=$(echo $PrecursorMassToleranceMax | awk -F. '{print $1}')
    PrecursorMassToleranceMax2=$(echo $PrecursorMassToleranceMax | awk -F. '{print $2}')
    if [[ $PrecursorMassToleranceMax2 == "" ]]; then
        PrecursorMassToleranceMax2="0"
    fi

    if (($PrecursorMassTolerence1 > $PrecursorMassToleranceMax1)); then
        echo "Error the start value of the range is larger than the end value"
        exit
    fi
    if (($PrecursorMassTolerence1 == $PrecursorMassToleranceMax1)) && (($PrecursorMassTolerence2 > $PrecursorMassToleranceMax2)); then
        echo "Error the start value of the range is larger than the end value"
        exit
    fi
#   Tests if the value that has been entered is >= 0.1 (Checks if more than 2 characters have been enter after the period,
#                                                        and if the second value is not equal to 0 it exits)

    PMTI2test=$(echo $PrecursorMassToleranceIncrement2 | sed 's/./& /' | awk '{if($2!="" && $2!=0)print "exit"}')
    PMT2test=$(echo $PrecursorMassTolerance2 | sed 's/./& /' | awk '{if($2!="" && $2!=0)print "exit"}')
    PMTMax2test=$(echo $PrecursorMassToleranceMax2 | sed 's/./& /' | awk '{if($2!="" && $2!=0)print "exit"}')

    if [[ $PMTI2test == "exit" ]] || [[ $PMT2test == "exit" ]] || [[ $PMTMax2test == "exit" ]]; then
        echo "Error please enter a value with only one significant figure after the decimal point"
        exit
    fi
}

Increment_Tolerance_values ()
{
    #   Allows it to exit correctly if the PrecursorMassTolerenceIncrement < 1
        if (($PrecursorMassTolerence1 == $PrecursorMassToleranceMax1)) && (($PrecursorMassTolerence2 >= $PrecursorMassToleranceMax2)); then
            PrecursorMassTolerence1=$(($PrecursorMassToleranceMax1+1))
        fi
    #   increments the masstolerance2
        PrecursorMassTolerence2=$(($PrecursorMassTolerence2+$PrecursorMassToleranceIncrement2))
    #   Increments PrecursorMassTolerence1 if PrecursorMassTolerence2 is greater than 10
        if (($PrecursorMassTolerence2 >= 10)) && [[ $Deci == "yes" ]]; then
            PrecursorMassTolerence1=$(($PrecursorMassTolerence1+1))
            PrecursorMassTolerence2=$(($PrecursorMassTolerence2-10))
        fi
    #   increments PrecursorMassTolerence1 if PrecursorMassTolerence1 >= 1
        if (($PrecursorMassToleranceIncrement1 >= 1)); then
            PrecursorMassTolerence1=$(($PrecursorMassTolerence1+$PrecursorMassToleranceIncrement1))
        fi
}

Run_Repeated_pipeline ()
{
    #   Set backslashes infront of the forward slashes for use in sed
        PIDparam_sed=${PIDparam//\//\\/}
        PIDparam_Repeat_sed=${PIDparam_Repeat//\//\\/}
    #   replace the original parameter location with the new one
        Run_Script_Repeat=$(echo "$Run_Script" | sed "s/$PIDparam_sed/$PIDparam_Repeat_sed/")

        echo "$PrecursorMassTolerence1.$PrecursorMassTolerence2 $MassUnit"
    #   Run the database search software
        $Run_Script_Repeat "-s" "_$PrecursorMassTolerence1""_$PrecursorMassTolerence2$MassUnit"
}

Rerun_Comet_Tollerance_Parameters ()
{

    SET_Tollerance_values

#   Notes the mass unit (ppm or Daltons)
    MassUnit=$(grep "peptide_mass_units = " $PIDparam | awk '{print $3}')
#   Translates the number in the parameter file to the corresponding unit
    if [[ $MassUnit == "2" ]]; then
        MassUnit="ppm"
    else
        MassUnit="Daltons"
    fi

#   Do this while PrecursorMassTolerence is lower than the maximum value
    while (($PrecursorMassTolerence1 <= $PrecursorMassToleranceMax1)); do

#   Start editing the parameter files

    #   creates a file which includes the mass tolerance in the name
        PIDparam_Repeat="$PIDparam""_$PrecursorMassTolerence1""_$PrecursorMassTolerence2""$MassUnit"
    #   changes the peptide mass tolerance
        sed  "s/peptide_mass_tolerance = .*/peptide_mass_tolerance = $PrecursorMassTolerence1.$PrecursorMassTolerence2/" $PIDparam > $PIDparam_Repeat
    #   changes the name of the output to inculde the ppm/daltons
        sed -i "s/output_suffix =.*/output_suffix = _$PrecursorMassTolerence1\_$PrecursorMassTolerence2$MassUnit/" $PIDparam_Repeat

#   Done editing the parameter files

        Run_Repeated_pipeline

        Increment_Tolerance_values

    done
}

Rerun_Tandem_Tollerance_Parameters ()
{
    SET_Tollerance_values

#   Notes the mass unit (ppm or Daltons)
    PIDparam_Default=$(grep "list path, default parameters" $PIDparam | awk -F\> '{print $2}' | awk -F\< '{print $1}')
    MassUnit=$(grep "spectrum, parent monoisotopic mass error units" $PIDparam_Default | awk -F\> '{print $2}' | awk -F\< '{print $1}')
#   Notes the extention of the tandem parameter file if it has one (should be .xml)
    Extention_PIDparam=$(echo $PIDparam | awk -F\/ '{print $NF}' | awk -F\. '{if ($NF > 1) print "."$NF}')
    EXtention_PIDparam_Default=$(echo $PIDparam_Default | awk -F\/ '{print $NF}' | awk -F\. '{if ($NF > 1) print "."$NF}')

#   Do this while PrecursorMassTolerence is lower than the maximum value
    while (($PrecursorMassTolerence1 <= $PrecursorMassToleranceMax1)); do

#   Start edditing parameter file

    #   creates a file which includes the mass tolerance in the name
        PIDparam_Repeat=${PIDparam//$Extention_PIDparam/_$PrecursorMassTolerence1\_$PrecursorMassTolerence2$MassUnit$Extention_PIDparam}
        PIDparam_Default_Repeat=${PIDparam_Default//$EXtention_PIDparam_Default/_$PrecursorMassTolerence1\_$PrecursorMassTolerence2$MassUnit$EXtention_PIDparam_Default}
        cp $PIDparam $PIDparam_Repeat

    #   changes the peptide mass tolerance
        sed  "s/label=\"spectrum, parent monoisotopic mass error plus\">.*</label=\"spectrum, parent monoisotopic mass error plus\">$PrecursorMassTolerence1.$PrecursorMassTolerence2</" $PIDparam_Default > $PIDparam_Default_Repeat
    #   changes the name of the output to inculde the ppm/daltons
        sed -i "s/label=\"spectrum, parent monoisotopic mass error minus\">.*</label=\"spectrum, parent monoisotopic mass error minus\">$PrecursorMassTolerence1.$PrecursorMassTolerence2</" $PIDparam_Default_Repeat

    #   Escape the forward slash, that way sed can use it.
        PIDparam_Default_sed=${PIDparam_Default//\//\\/}
        PIDparam_Default_Repeat_sed=${PIDparam_Default_Repeat//\//\\/}
    #   replace the location of the standard default parameter file with the repeat default parameter file
        sed -i "s/$PIDparam_Default_sed/$PIDparam_Default_Repeat_sed/"  $PIDparam_Repeat

#   Done editing prameter files

        Run_Repeated_pipeline

        Increment_Tolerance_values
    done

}

Rerun_MSGFPlus_Tollerance_Parameters ()
{
    SET_Tollerance_values

#   Notes the mass unit (ppm or Daltons)
    MassUnit=$(grep "^PrecursorMassTolerance -t " $PIDparam | awk '{print $3}' | awk -F[0-9] '{print $NF}')
    if [[ $MassUnit == "" ]]; then
        MassUnit="ppm"
    fi

#   Do this while PrecursorMassTolerence is lower than the maximum value
    while (($PrecursorMassTolerence1 <= $PrecursorMassToleranceMax1)); do

#   Start editing the parameter files

    #   creates a file which includes the mass tolerance in the name
        PIDparam_Repeat="$PIDparam""_$PrecursorMassTolerence1""_$PrecursorMassTolerence2""$MassUnit"
    #   changes the peptide mass tolerance and the unit
        sed "s/PrecursorMassTolerance -t .*/PrecursorMassTolerance -t $PrecursorMassTolerence1.$PrecursorMassTolerence2$MassUnit/" $PIDparam > $PIDparam_Repeat
        sed -i "s/#Output_suffix .*/#Output_suffix _$PrecursorMassTolerence1\_$PrecursorMassTolerence2$MassUnit/" $PIDparam_Repeat

#   Done editing the parameter files

        Run_Repeated_pipeline

        Increment_Tolerance_values
    done

}

Rerun_MSFragger_Tollerance_Parameters ()
{
    SET_Tollerance_values

#   Notes the mass unit (ppm or Daltons)
    MassUnit=$(grep "precursor_mass_units = " $PIDparam | awk '{print $3}')
#   Translates the number in the parameter file to the corresponding unit
    if [[ $MassUnit == "2" ]]; then
        MassUnit="ppm"
    else
        MassUnit="Daltons"
    fi

#   Do this while PrecursorMassTolerence is lower than the maximum value
    while (($PrecursorMassTolerence1 <= $PrecursorMassToleranceMax1)); do

#   Start editing the parameter files

    #   creates a file which includes the mass tolerance in the name
        PIDparam_Repeat="$PIDparam""_$PrecursorMassTolerence1""_$PrecursorMassTolerence2""$MassUnit"
    #   changes the peptide mass tolerance and the unit
        sed "s/precursor_mass_tolerance = .*/precursor_mass_tolerance = $PrecursorMassTolerence1.$PrecursorMassTolerence2/" $PIDparam > $PIDparam_repeat
        sed -i "s/#Output_suffix .*/#Output_suffix _$PrecursorMassTolerence1\_$PrecursorMassTolerence2$MassUnit/" $PIDparam_Repeat

#   Done editing the parameter files

        Run_Repeated_pipeline

        Increment_Tolerance_values
    done



}
