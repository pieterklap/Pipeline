#!/bin/bash

# the command used to submit the job on the shark cluster (change to sbatch for shark cluster with SLURM Workload Manager)
submit_command="qsub"

# Checks if the required parameters have been passed to the script
if [[ $RUNscripts == "" ]]; then
    if [[ $input == "" ]]; then
        echo "Error no input file given"
        exit
    elif (($NUMprog>$NUMparam)); then
        echo "too few parameter files given"
        exit
    elif (($NUMprog<$NUMparam)); then
        echo "too many parameter files given"
        exit
    elif (($NUMparam == 0)); then
        echo "No parameter files given"
        exit
    fi
    if [[ $(grep -v "^#" "$LOC"install_locations |awk '{print $2}') == "" ]]; then
        while [[ $Empty != [yY] ]]; do
            read -p "The install_locations file is empty, are you sure you want to run it (y/n): " Empty
            if [[ $Empty == [nN] ]]; then
                exit
            fi
        done

    fi
fi

if [[ $location == "" ]]; then
    location="-L ""$LOCscripts"
fi

Set_corect_parameter ()
{
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
    if [[ $PID == "MSFragger" ]]; then
        PIDparam="-p $msfragger"
    fi
    if [[ $VAL == "PeptideProphet" ]]; then
        VALparam="-v $peptideprophet"
    fi
    if [[ $VAL == "percolator" ]]; then
        VALparam="-v $percolator"
    fi
    if [[ $gprofiler != "" ]] && [[ $NOVAL != "1" ]]; then
        GPparams="-g $gprofiler"
    fi
}

Local_Run ()
{
    while [[ $RUN != [yY] ]]; do
        read -p "Are you sure you want to run the pipeline locally?(y/n): " RUN
        if [[ $RUN == [nN] ]]; then
            exit
        fi
    done
    for file in "$LOCscripts"*.sh
    do
        Set_corect_parameter
    #   Run the pipeline for each combination of programs
        ${file} $PIDparam $VALparam $input $output $logfile $location $GPparams
    done
}

Shark_Run ()
{
    for file in "$LOCscripts"*.sh
    do
        Set_corect_parameter
        $submit_command $SHARKoptions ${file} $PIDparam $input $output $logfile $location $GPparams
    done
}

Repeat_Run_Shark ()
{
    source $LOC/src/parameter_repeat.sh

    for file in "$LOCscripts"*.sh
    do
        Set_corect_parameter

        if [[ $Parallel_Run == "" ]]; then
                Run_Script="$submit_command $SHARKoptions ${file} $PIDparam $input $output $logfile $location $GPparams"
                PIDparam=$(echo $PIDparam | awk '{print $2}')
            if [[ $PID == "comet" ]]; then
                Rerun_Comet_Parameters
            fi
            if [[ $PID == "Xtandem" ]]; then
                Rerun_Tandem_Parameters
            fi
            if [[ $PID == "MSGFPlus" ]]; then
                Rerun_MSGFPlus_Parameters
            fi

        fi
        if [[ $Series_Run == "1" ]]; then
            Run_Script="${file} $PIDparam $VALparam $input $output $logfile $location $GPparams"
            $submit_command $SHARKoptions $LOC/src/series_run.sh $PrecursorMassToleranceRange $PrecursorMassToleranceIncrement $Run_Script $PID $LOC
        fi
    done


}

Repeat_Run_Local ()
{
    while [[ $RUN != [yY] ]]; do
        read -p "Are you sure you want to run the pipeline locally?(y/n): " RUN
        if [[ $RUN == [nN] ]]; then
            exit
        fi
    done
    for file in "$LOCscripts"*.sh
    do
        Set_corect_parameter
        Run_Script="${file} $PIDparam $VALparam $input $output $logfile $location $GPparams"
        $LOC/src/series_run.sh $PrecursorMassToleranceRange $PrecursorMassToleranceIncrement $Run_Script $PID $LOC
    done

}


