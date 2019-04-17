#!/bin/bash

#   location of the modification file extrected fro=m the shared parameter file
Shared_mod_file=$(grep "^Modification_file" $LOC_Shared_param_file | awk '{print $3}')

# maximum amount of mods per peptide
Max_mods=$(grep "Maximum_mods_per_peptide" $Shared_mod_file | awk '{print $3}')

# all the modifications
MODS=$(grep "^mod" $Shared_mod_file | awk -F= '{print $2}')

#   the letters representing amino acids needed fo fixed mods of comet
aminoacids="G A S P V T C L I N D Q K E M O H F U R Y W"


if [[ $output_dir == "" ]]; then
    output_dir=$PWD/
    echo "ERROR: This sould never happen"
fi


# Seperates the parameters in the modificatoin file into 7 variables
Seperate ()
{
    mod01=$(echo ${mod} | awk -F\: '{print $1}')
    mod02=$(echo ${mod} | awk -F\: '{print $2}')
    mod03=$(echo ${mod} | awk -F\: '{print $3}')
    mod04=$(echo ${mod} | awk -F\: '{print $4}')
    mod05=$(echo ${mod} | awk -F\: '{print $5}')
    mod06=$(echo ${mod} | awk -F\: '{print $6}')
    mod07=$(echo ${mod} | awk -F\: '{print $7}')
}


Comet_mods ()
{
#    cp $cometparam $output_dir/cometparam
#    local cometparam=$output_dir/
    local temp_comet=$output_dir/.temp.comet

#   reset fixed comet params
    for AA in $aminoacids
    do
        fixmod_old=$(grep "add_""${AA}""_" $cometparam | awk '{print $1,$2,$3}') 
        fixmod=$(grep "add_""${AA}""_" $cometparam | awk '{print $1,$2}')
        sed "s/$fixmod_old/$fixmod 0.0000/" $cometparam > $temp_comet
        cat $temp_comet > $cometparam
        rm $temp_comet
    done

#   TODO: reset the fixed and variable modifications
    local NUM=1
    for mod in $MODS
    do
        Seperate

    #   Seperates the fixed and variable modifications
    #   Swaps the old fixed modificion with the new one
        if [[ $mod04 == fix ]]; then
            fixmod_old=$(grep "add_""$mod03""_" $cometparam | awk '{print $1,$2,$3}')
            fixmod=$(grep "add_""$mod03""_" $cometparam | awk '{print $1,$2}')
            sed "s/$fixmod_old/$fixmod $mod02/" $cometparam > $temp_comet
            cat $temp_comet > $cometparam
            rm $temp_comet
        fi
    #   Swaps the old variable mod with a new one
        if [[ $mod04 == opt ]] && (( $NUM <= 9 )); then
            optmod_old=$(grep "variable_mod0""$NUM" $cometparam | awk '{print $0}')
            optmod=$(grep "variable_mod0""$NUM" $cometparam | awk '{print $1,$2}')
            comet_order=$(echo "$optmod $mod02 $mod03 0 $Max_mods $mod06 $mod05 $mod07")
            sed "s/$optmod_old/$comet_order/" $cometparam > $temp_comet
            cat $temp_comet > $cometparam
            rm $temp_comet
            NUM=$(($NUM+1))
        fi
        if (( $NUM >= 10 )) && [[ $mod04 == opt ]]; then
            echo "${mod} isn't added to the comet parameter file because more than 9 variable modifications have been used"
        fi
    done
}


MSGFPlus_mods ()
{
    #   1.mass 2.residues 3.fixed/variable 4.N/C-term 5.Unimod_PSI-MS_name
    #   [Name]:[mass]:[residue(s)]:[fix/opt]:[n/c-term]:[distance]:[forced]
    msgfparam_mods="$output_dir"msgfparam_mods
    echo -e "NumMods=$Max_mods \n" > $msgfparam_mods

    for mod in $MODS
    do
        Seperate
    #   Checks if the terminus if modified and if it is which terminal is modified
        if [[ $mod06 == "-1" ]]; then
            local terminus="any"
        fi
        if [[ $mod05 == "0" ]] && [[ $mod06 != "-1" ]]; then
            local terminus="ProtNterm"
        fi
        if [[ $mod05 == "1" ]] && [[ $mod06 != "-1" ]]; then
            local terminus="ProtCterm"
        fi
        if [[ $mod05 == "2" ]] && [[ $mod06 != "-1" ]]; then
            local terminus="Nterm"
        fi
        if [[ $mod05 == "3" ]] && [[ $mod06 != "-1" ]]; then
            local terminus="Cterm"
        fi
    #   If there is no specific modification set the residue to * indicating that any amino acid can be modified
        if [[ $mod03 == "c" ]] || [[ $mod03 == "n" ]]; then
            mod03=\*
        fi
    #   Set the order
        local msgf_order=$(echo "$mod02,$mod03,$mod04,$terminus,$mod01")
    #   Add it to the modification_parameter file
        echo $msgf_order >> $msgfparam_mods
    done

    echo "ModificationFileName -mod $msgfparam_mods" >> $MSGFPlusparam
}

Tandem_mods ()
{
    local temp_tandem=$output_dir/.temp.tandem
    local tandemparam=$Tandemparam


    for mod in $MODS
    do
        Seperate

    #   Checks if the modification is on the N/C terminal
        if [[ $mod06 == "-1" ]]; then
        #   Puts the fixed modifications in the variable fix and the variable modifications in the variable opt

            residue_amount=$(echo $mod03 | wc -c)
        #   if the amount of residues is greater than 1 split them ( wc -c returns 1 + the amount of characters)
            if (( $residue_amount > 2 )); then
            #   Adds speces inbetween the residues
                Residues=$(echo $mod03 | sed "s/./& /g")

                for res in $Residues
                do
                #   Puts the fixed modifications in the variable fix and the variable modifications in the variable opt
                    declare local $mod04+=$(echo $mod02"@"${res}",")
                done
            else
            #   Puts the fixed modifications in the variable fix and the variable modifications in the variable opt
                declare local $mod04+=$(echo $mod02"@"$mod03",")
            fi
        fi
        if [[ $mod06 != "-1" ]] && [[ $mod05 == 0 ]]; then
            ProtNterm=$mod02
        fi
        if [[ $mod06 != "-1" ]] && [[ $mod05 == 1 ]]; then
            ProtCterm=$mod02
        fi
        if [[ $mod06 != "-1" ]] && [[ $mod05 == 2 ]]; then
            PepNterm=$mod02
        fi
        if [[ $mod06 != "-1" ]] && [[ $mod05 == 3 ]]; then
            PepCterm=$mod02
        fi

    done
    #   Removes the last comma from the list of modifications
        local fix=$(echo $fix | head -c-2)
        local opt=$(echo $opt | head -c-2)

    #   if the terminal isn't modified the value is set to 0.0
        if [[ $ProtNterm == "" ]]; then
            ProtNterm=0.0
        fi
        if [[ $ProtCterm == "" ]]; then
            ProtCterm=0.0
        fi
        if [[ $PepNterm == "" ]]; then
            PepNterm=0.0
        fi
        if [[ $PepCterm == "" ]]; then
            PepCterm=0.0
        fi

        sed "s/modification mass\">.*<\/note>/modification mass\"><\/note>/" $tandemparam > $temp_tandem
        cat $temp_tandem > $tandemparam
        rm $temp_tandem

        sed "s/residue, modification mass\">/&$fix/" $tandemparam > $temp_tandem
        cat $temp_tandem > $tandemparam
        rm $temp_tandem

        sed "s/residue, potential modification mass\">/&$opt/" $tandemparam > $temp_tandem
        cat $temp_tandem > $tandemparam
        rm $temp_tandem

        sed "s/N-terminal residue modification mass\">/&$ProtNterm/" $tandemparam > $temp_tandem
        cat $temp_tandem > $tandemparam
        rm $temp_tandem

        sed "s/C-terminal residue modification mass\">/&$ProtCterm/" $tandemparam > $temp_tandem
        cat $temp_tandem > $tandemparam
        rm $temp_tandem

    #   TODO:  find out where the peptide N/C term modifications should go
}

MSFragger_mods ()
{


    local temp_MSFragger=$output_dir/.temp.MSFragger

#   reset fixed comet params
    for AA in $aminoacids
    do
        fixmod_old=$(grep "add_""${AA}""_" $MSFraggerparam | awk '{print $1,$2,$3}') 
        fixmod=$(grep "add_""${AA}""_" $MSFraggerparam | awk '{print $1,$2}')
        sed "s/$fixmod_old/$fixmod 0.0000/" $MSFraggerparam > $temp_MSFragger
        cat $temp_MSFragger > $MSFraggerparam
        rm $temp_MSFragger
    done


    local NUM=1
    for mod in $MODS
    do
        Seperate

    #   Seperates the fixed and variable modifications
    #   Swaps the old fixed modificion with the new one
        if [[ $mod04 == fix ]]; then
            fixmod_old=$(grep "add_""$mod03""_" $MSFraggerparam | awk '{print $1,$2,$3}')
            fixmod=$(grep "add_""$mod03""_" $MSFraggerparam | awk '{print $1,$2}')
            sed "s/$fixmod_old/$fixmod $mod02/" $MSFraggerparam > $temp_MSFragger
            cat $temp_MSFragger > $MSFraggerparam
            rm $temp_MSFragger
        fi

    #   maximum of 7 mods - amino acid codes, * for any amino acid, ^ for termini, [ and ] specifies protein termini, n and c specifies peptide termini
        if [[ $mod04 == opt ]] && (( $NUM <= 7 )); then

            if [[ $mod03 == "n" ]] || [[ $mod03 == "c" ]]; then
                mod03="^"
            fi
#           Checks if the modification is on the N/C terminal
            if [[ $mod06 != "-1" ]]; then

                if [[ $mod05 == "0" ]]; then
                    local terminal="["
                fi
                if [[ $mod05 == "1" ]]; then
                    local terminal="]"
                fi
                if [[ $mod05 == "2" ]]; then
                    local terminal="n"
                fi
                if [[ $mod05 == "3" ]]; then
                    local terminal="c"
                fi
            fi
    #       When mod06 is -1 set terminal to nothing
            if [[ $mod06 == "-1" ]]; then
                terminal=""
            fi

    #       Puts the fixed modifications in the variable fix and the variable modifications in the variable opt
            residue_amount=$(echo $mod03 | wc -c)
    #       Resets the residue location
            residue_location=""
    #       if the amount of residues is greater than 1 split them ( wc -c returns 1 + the amount of characters)
            if (( $residue_amount > 2 )); then
            #   Adds speces inbetween the residues
                local Residues=$(echo $mod03 | sed "s/./& /g")
                for res in $Residues
                do
                #   Puts the fixed modifications in the variable fix and the variable modifications in the variable opt
                    local residue_location+=$(echo "$terminal""${res}")
                done
            else
            #   Puts the fixed modifications in the variable fix and the variable modifications in the variable opt
                local residue_location+=$(echo "$terminal""$mod03")
            fi

            echo "variable_mod_0""$NUM = $mod02 $residue_location" >> $MSFraggerparam

            local NUM=$(($NUM+1))
        fi

        if (( $NUM >= 8 )) && [[ $mod04 == opt ]]; then
            echo "${mod} isn't added to the MSFragger parameter file because more than $(($NUM-1)) variable modifications have been used"
            local NUM=$(($NUM+1))
        fi

    done
}
