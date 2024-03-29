#!/bin/bash

# the command used to submit the job on the shark cluster (change to sbatch for shark cluster with SLURM Workload Manager)
submit_command="qsub"

# Checks if the required parameters have been passed to the script
if [[ $RUNscripts == "" ]]; then
    if [[ $input == "" ]]; then
        echo -e "\e[91mERROR:\e[0m no input file given"
        exit
    elif (($NUMprog>$NUMparam)); then
        echo -e "\e[91mERROR:\e[0m too few parameter files given"
        exit
    elif (($NUMprog<$NUMparam)); then
        echo -e "\e[91mERROR:\e[0m too many parameter files given"
        exit
    elif (($NUMparam == 0)); then
        echo -e "\e[91mERROR:\e[0m No parameter files given"
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
    DSS=$(echo ${file} | awk -F. '{print $1}' | awk -F_ '{print $1}' | awk -F/ '{print $NF}')
    VAL=$(echo ${file} | awk -F. '{print $1}' | awk -F_ '{print $2}')

#    DSSparam="-p "
#    VALparam="-v "
    ANAparam="-a "

    if [[ $DSS == "comet" ]]; then
        DSSparam="-p $comet"
    fi
    if [[ $DSS == "Tandem" ]]; then
        DSSparam="-p $tandem"
    fi
    if [[ $DSS == "MSGFPlus" ]]; then
        DSSparam="-p $msgfplus"
    fi
    if [[ $DSS == "MSFragger" ]]; then
        DSSparam="-p $msfragger"
    fi
    if [[ $VAL == "PeptideProphet" ]]; then
        VALparam="-v $peptideprophet"
    fi
    if [[ $VAL == "percolator" ]]; then
        VALparam="-v $percolator"
    fi
    if [[ $VAL == "all" ]]; then
        VALparam="-v $peptideprophet $percolator"
    fi
    if [[ $gprofiler != "" ]] && [[ $NOVAL != "1" ]]; then
        ANAparam+="$gprofiler "
    fi
    if [[ $reactome != "" ]] && [[ $NOVAL != "1" ]]; then
        ANAparam+="$reactome "
    fi
}

Local_Run ()
{
    if [[ $HOSTNAME == $Head_node_name ]]; then
        echo "currently running on the head node do not execute the pipeline on the head node"
        echo "if this is a exucutable node change the variable Head_node_name in the PPG.sh file to the head node name or leave it empty"
        exit
    fi
    while [[ $RUN != [yY] ]]; do
        read -p "Are you sure you want to run the pipeline locally?(y/n): " RUN
        if [[ $RUN == [nN] ]]; then
            exit
        fi
    done
    echo $Scripts_to_Run
    for file in $Scripts_to_Run
    do
        Set_corect_parameter
    #   Run the pipeline for each combination of programs
        ${file} $DSSparam $VALparam $input $output $logfile $location $ANAparam $Extra_parameters
    done
}

Shark_Run ()
{
    for file in $Scripts_to_Run
    do
        Set_corect_parameter
        $submit_command $SHARKoptions ${file} $DSSparam $VALparam $input $output $logfile $location $GPparams
    done
}

Repeat_Run_Shark ()
{
    source $LOC/src/parameter_repeat.sh

    for file in $Scripts_to_Run
    do
        Set_corect_parameter

        if [[ $Parallel_Run == "" ]]; then
                Run_Script="$submit_command $SHARKoptions ${file} $DSSparam $VALparam $input $output $logfile $location $GPparams"
                DSSparam=$(echo $DSSparam | awk '{print $2}')
            if [[ $DSS == "comet" ]]; then
                Rerun_Comet_Tollerance_Parameters
            fi
            if [[ $DSS == "Xtandem" ]]; then
                Rerun_Tandem_Tollerance_Parameters
            fi
            if [[ $DSS == "MSGFPlus" ]]; then
                Rerun_MSGFPlus_Tollerance_Parameters
            fi

        fi
        if [[ $Series_Run == "1" ]]; then
            Run_Script="${file} $DSSparam $VALparam $input $output $logfile $location $GPparams"
            $submit_command $SHARKoptions $LOC/src/series_run.sh $PrecursorMassToleranceRange $PrecursorMassToleranceIncrement $Run_Script $DSS $LOC
        fi
    done


}

Repeat_Run_Local ()
{
    if [[ $HOSTNAME == $Head_node_name ]]; then
        echo "currently running on the head node do not execute the pipeline on the head node"
        exit
    fi
    while [[ $RUN != [yY] ]]; do
        read -p "Are you sure you want to run the pipeline locally?(y/n): " RUN
        if [[ $RUN == [nN] ]]; then
            exit
        fi
    done
    for file in $Scripts_to_Run
    do
        Set_corect_parameter
        Run_Script="${file} $DSSparam $VALparam $input $output $logfile $location $GPparams"
        $LOC/src/series_run.sh $PrecursorMassToleranceRange $PrecursorMassToleranceIncrement $Run_Script $DSS $LOC
    done

}


