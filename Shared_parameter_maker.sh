#!/bin/bash

Header="# Parameter file to be used with the Proteomic Pipeline Generator. "
Header_ver="(v0.x)"
Header_file_ver=$(head -n1 $LOC_Shared_param_file | awk '{print $NF}')
Header_file=$(head -n1 $LOC_Shared_param_file | awk '{$NF="";print $0}')


if [[ "$Header" != "$Header_file" ]]; then
    echo "Shared parameter file is in the incorrect format"
    exit
fi

if [[ "$Header_ver" != "$Header_file_ver" ]]; then
    echo "Wrong version used. Version used: $Header_file_ver; version needed: $Header_ver"
    exit
fi


Comet ()
{
    #input needed is $LOC_Shared_param_file and $output_dir

    cometparam="$output_dir"cometparam_PPG
    local Shared_param_file=$(echo $Shared_param_file | tr "[" "=")
    for param in $Shared_param_file
    do
    #   Check if the parameter is usable with comet
        local param_program=$(echo ${param} | awk -F\= '{print $3}')
        if [[ $param_program == *"comet"* ]]; then
        #   If the parameter is usable with comet extract the parameter name and value from the file
            local param_name=$(echo ${param} | awk -F\= '{print $1}')
            local param_value=$(echo ${param} | awk -F\= '{print $2}')
        #   Set the parameter value in a variable with the parameter name
            declare local "$param_name"="$param_value"
        fi
    done
#   set the parammeter to use the correct notation
    if [[ $MassUnit == "Daltons" ]]; then
        MassUnit="0"
    fi
    if [[ $MassUnit == "ppm" ]]; then
        MassUnit="2"
    fi

#   echos all the comet parameters into a parameter file named cometparam_PPG
#   There probaly is a better way of doing this but it works.  TODO: fix it
    echo "# comet_version 2017.01 rev. 1 " > $cometparam                # Start of the comet parameterfile
    echo "# Comet MS/MS search engine parameters file." >> $cometparam  # Start of the comet parameterfile

    echo "database_name = $fasta_file" >> $cometparam
    echo "decoy_search = $Decoy_Database" >> $cometparam
    echo "peff_format = 0" >> $cometparam
    echo "peff_obo =" >> $cometparam
    echo "num_threads = $NumThreads" >> $cometparam
    echo "peptide_mass_tolerance = $PrecursorMassTolerance" >> $cometparam
    echo "peptide_mass_units = $MassUnit" >> $cometparam
    echo "mass_type_parent = $mass_type_precursor" >> $cometparam
    echo "mass_type_fragment = $mass_type_fragment" >> $cometparam

    echo "precursor_tolerance_type = 0" >> $cometparam

    local IsotopeErrorRange=$(echo $IsotopeErrorRange | awk -F\, '{print $NF}')
    echo "isotope_error = $IsotopeErrorRange" >> $cometparam
    echo "search_enzyme_number = $search_enzyme_number" >> $cometparam
    echo "num_enzyme_termini = $Tolerable_Termini" >> $cometparam
    echo "allowed_missed_cleavage = $allowed_missed_cleavage" >> $cometparam

    echo "fragment_bin_tol = $fragment_ion_tolerance" >> $cometparam
    echo "fragment_bin_offset = $fragment_bin_offset" >> $cometparam
    echo "theoretical_fragment_ions = $theoretical_fragment_ions" >> $cometparam
    echo "use_A_ions = $use_A_ions" >> $cometparam
    echo "use_B_ions = $use_B_ions" >> $cometparam
    echo "use_C_ions = $use_C_ions" >> $cometparam
    echo "use_X_ions = $use_X_ions" >> $cometparam
    echo "use_Y_ions = $use_Y_ions" >> $cometparam
    echo "use_Z_ions = $use_Z_ions" >> $cometparam
    echo "use_NL_ions = $use_NL_ions" >> $cometparam

    echo "print_expect_score = 1" >> $cometparam
    echo "num_output_lines = $NumMatchesPerSpec" >> $cometparam
    echo "show_fragment_ions = 0" >> $cometparam
    echo "sample_enzyme_number = $search_enzyme_number" >> $cometparam

    echo "scan_range = 0" >> $cometparam
    echo "precursor_charge = 0" >> $cometparam
    echo "override_charge = 0" >> $cometparam
    echo "ms_level = 2" >> $cometparam
    if [[ $FragmentMethodID == 0 ]]; then
        FragmentMethodID=""
    fi
    if [[ $FragmentMethodID == 1 ]]; then
        FragmentMethodID="CID"
    fi
    if [[ $FragmentMethodID == 2 ]]; then
        FragmentMethodID="ETD"
    fi
    if [[ $FragmentMethodID == 1 ]]; then
        FragmentMethodID="HCD"
    fi
    echo "activation_method = $FragmentMethodID" >> $cometparam

    echo "digest_mass_range = $MinPepMass $MaxPepMass" >> $cometparam

    echo "num_results = 100" >> $cometparam
    echo "skip_researching = 1" >> $cometparam
    echo "max_fragment_charge = 3" >> $cometparam
    echo "max_precursor_charge = $MaxCharge" >> $cometparam
    echo "nucleotide_reading_frame = 0" >> $cometparam
    echo "clip_nterm_methionine = 0" >> $cometparam
    echo "spectrum_batch_size = $spectrum_batch_size" >> $cometparam
    echo "decoy_prefix = DECOY_" >> $cometparam
    echo "output_suffix =" >> $cometparam
    echo "mass_offsets = " >> $cometparam

    echo "minimum_peaks = 10" >> $cometparam
    echo "minimum_intensity = 0" >> $cometparam
    echo "remove_precursor_peak = 0" >> $cometparam
    echo "remove_precursor_tolerance = 1.5" >> $cometparam
    echo "clear_mz_range = 0.0" >> $cometparam

#   These parameters will be edited by the pipelines so they shouldn't be changed.
    echo "output_sqtstream = 0" >> $cometparam
    echo "output_sqtfile = 0" >> $cometparam
    echo "output_txtfile = 0" >> $cometparam
    echo "output_pepxmlfile = 1" >> $cometparam
    echo "output_percolatorfile = 0" >> $cometparam


#   will be changed by the modification file
    echo "variable_mod01 = 0.0 X 0 0 -1 0 0" >> $cometparam
    echo "variable_mod02 = 0.0 X 0 3 -1 0 0" >> $cometparam
    echo "variable_mod03 = 0.0 X 0 3 -1 0 0" >> $cometparam
    echo "variable_mod04 = 0.0 X 0 3 -1 0 0" >> $cometparam
    echo "variable_mod05 = 0.0 X 0 3 -1 0 0" >> $cometparam
    echo "variable_mod06 = 0.0 X 0 3 -1 0 0" >> $cometparam
    echo "variable_mod07 = 0.0 X 0 3 -1 0 0" >> $cometparam
    echo "variable_mod08 = 0.0 X 0 3 -1 0 0" >> $cometparam
    echo "variable_mod09 = 0.0 X 0 3 -1 0 0" >> $cometparam
    echo "max_variable_mods_in_peptide = 5" >> $cometparam
    echo -e "require_variable_mod = 0\n" >> $cometparam

    echo "add_Cterm_peptide = 0.0" >> $cometparam
    echo "add_Nterm_peptide = 0.0" >> $cometparam
    echo "add_Cterm_protein = 0.0" >> $cometparam
    echo "add_Nterm_protein = 0.0" >> $cometparam
    echo "add_G_glycine = 0.0000" >> $cometparam
    echo "add_A_alanine = 0.0000" >> $cometparam
    echo "add_S_serine = 0.0000" >> $cometparam
    echo "add_P_proline = 0.0000" >> $cometparam
    echo "add_V_valine = 0.0000" >> $cometparam
    echo "add_T_threonine = 0.0000" >> $cometparam
    echo "add_C_cysteine = 0.0000" >> $cometparam
    echo "add_L_leucine = 0.0000" >> $cometparam
    echo "add_I_isoleucine = 0.0000" >> $cometparam
    echo "add_N_asparagine = 0.0000" >> $cometparam
    echo "add_D_aspartic_acid = 0.0000" >> $cometparam
    echo "add_Q_glutamine = 0.0000" >> $cometparam
    echo "add_K_lysine = 0.0000" >> $cometparam
    echo "add_E_glutamic_acid = 0.0000" >> $cometparam
    echo "add_M_methionine = 0.0000" >> $cometparam
    echo "add_O_ornithine = 0.0000" >> $cometparam
    echo "add_H_histidine = 0.0000" >> $cometparam
    echo "add_F_phenylalanine = 0.0000" >> $cometparam
    echo "add_U_selenocysteine = 0.0000" >> $cometparam
    echo "add_R_arginine = 0.0000" >> $cometparam
    echo "add_Y_tyrosine = 0.0000" >> $cometparam
    echo "add_W_tryptophan = 0.0000" >> $cometparam
    echo "add_B_user_amino_acid = 0.0000" >> $cometparam
    echo "add_J_user_amino_acid = 0.0000" >> $cometparam
    echo "add_X_user_amino_acid = 0.0000" >> $cometparam
    echo -e "add_Z_user_amino_acid = 0.0000\n" >> $cometparam

    echo "[COMET_ENZYME_INFO]" >> $cometparam
    echo "0.  NoEnzyme               0      -           -" >> $cometparam
    echo "1.  Trypsin                1      KR          P" >> $cometparam
    echo "2.  Trypsin/P              1      KR          -" >> $cometparam
    echo "3.  Lys_C                  1      K           P" >> $cometparam
    echo "4.  Lys_N                  0      K           -" >> $cometparam
    echo "5.  Arg_C                  1      R           P" >> $cometparam
    echo "6.  Asp_N                  0      D           -" >> $cometparam
    echo "7.  CNBr                   1      M           -" >> $cometparam
    echo "8.  Glu_C                  1      DE          P" >> $cometparam
    echo "9.  PepsinA                1      FL          P" >> $cometparam
    echo "10. Chymotrypsin           1      FWYL        P" >> $cometparam

#   End of Comet parameter generation
    echo "Comet parameter file has been generated. located at: $cometparam"
}


MSGFPlus ()
{
    MSGFPlusparam="$output_dir"MSGFPlusparam_PPG
    local temp_MSGFPlusparam=$output_dir/.temp_MSGFPlusparam_PPG
    local Shared_param_file=$(echo $Shared_param_file | tr "[" "=")
    for param in $Shared_param_file
    do
    #   Check if the parameter is usable with MSGFPlus
        local param_program=$(echo ${param} | awk -F\= '{print $3}')
        if [[ $param_program == *"MSGFPlus"* ]]; then
        #   If the parameter is usable with MSGFPlus extract the parameter name and value from the file
            local param_name=$(echo ${param} | awk -F\= '{print $1}')
            local param_value=$(echo ${param} | awk -F\= '{print $2}')
        #   Set the parameter value in a variable with the parameter name
            declare local "$param_name"="$param_value"
        fi
    done


    echo "DatabaseFile -d $fasta_file" > $MSGFPlusparam
    if [[ "$MassUnit" == "Daltons" ]]; then
        local MassUnit="Da"
    fi
    echo "PrecursorMassTolerance -t $PrecursorMassTolerance$MassUnit" >> $MSGFPlusparam
    echo "IsotopeErrorRange -ti $IsotopeErrorRange" >> $MSGFPlusparam
    echo "NumThreads -thread $NumThreads" >> $MSGFPlusparam
    echo "NumTasks -tasks $NumTasks" >> $MSGFPlusparam

    if [[ $Mem_Use == "" ]]; then
        Mem_Use="4G"
    fi
    echo "Mem_Use $Mem_Use" >> $MSGFPlusparam

    echo "verbose -verbose 0" >> $MSGFPlusparam
    echo "Decoy_search -tda 1" >> $MSGFPlusparam

    echo "FragmentMethodID -m $FragmentMethodID" >> $MSGFPlusparam
    echo "MS2DetectorID -inst $MS2DetectorID" >> $MSGFPlusparam

    local search_enzyme_number=$(grep "^#enzyme: $search_enzyme_number " $LOC_Shared_param_file | awk '{print $7}')
    echo "EnzymeID -e $search_enzyme_number" >> $MSGFPlusparam
    echo "ProtocolID -protocol $ProtocolID" >> $MSGFPlusparam
    echo "Tolerable_Termini -ntt $num_enzyme_termini" >> $MSGFPlusparam

    echo "MinPepLength -minLength $MinPepLength" >> $MSGFPlusparam
    echo "MaxPepLength -maxLength $MaxPepLength" >> $MSGFPlusparam
    echo "MinCharge -minCharge $MinCharge" >> $MSGFPlusparam
    echo "MaxCharge -maxCharge $MaxCharge " >> $MSGFPlusparam
    echo "NumMatchesPerSpec -n $NumMatchesPerSpec" >> $MSGFPlusparam
    echo "AddFeatures -addFeatures 1" >> $MSGFPlusparam
    echo "ChargeCarrierMass -ccm $ChargeCarrierMass" >> $MSGFPlusparam

#   If any parameters are left empty they wil be commented out in the parameter file
    local MSGFPlus_paramlist=$(sed 's/ /=/g' $MSGFPlusparam)
    for parameter in $MSGFPlus_paramlist
    do
        local MSGFparam=$(echo ${parameter} | sed 's/=/ /g')
        MSGFparam_column3=$(echo $MSGFparam | awk '{print $3}')
        if [[ "$MSGFparam_column3" == "" ]]; then
            sed "s/$MSGFparam/#&/g" $MSGFPlusparam > $temp_MSGFPlusparam
            cat $temp_MSGFPlusparam > $MSGFPlusparam
            rm $temp_MSGFPlusparam
        fi
    done
#   End of MS-GF+ parameter generation
    echo "MS-GF+ parameter file has been generated. located at: $MSGFPlusparam"
}


Tandem ()
{

    Tandemparam=$(grep "tandem_default_input.xml" $LOC_Shared_param_file | awk '{print $3}')
    cp "$Tandemparam" "$output_dir"Tandemparam_PPG.xml

    Tandemparam_input="$output_dir"Tandem_input_PPG.xml
    Tandem_taxonomy="$output_dir"Tandem_taxonomy_PPG.xml

    Tandemparam="$output_dir"Tandemparam_PPG.xml
    local temp_Tandemparam=$output_dir/.temp_Tandemparam_PPG
    local Shared_param_file=$(echo $Shared_param_file | tr "[" "=")
    for param in $Shared_param_file
    do
    #   Check if the parameter is usable with Tandem
        local param_program=$(echo ${param} | awk -F\= '{print $3}')
        if [[ $param_program == *"tandem"* ]]; then
        #   If the parameter is usable with Tandem extract the parameter name and value from the file
            local param_name=$(echo ${param} | awk -F\= '{print $1}')
            local param_value=$(echo ${param} | awk -F\= '{print $2}')
        #   Set the parameter value in a variable with the parameter name
            declare local "$param_name"="$param_value"
        fi
    done
#   taxonomy: generates the taxonomy.xml like file
    echo -e "<?xml version=\"1.0\"?>\n"\
            "<bioml label=\"x! taxon-to-file matching list\">\n"\
            "    <taxon label=\""$Taxon"_decoy\">\n"\
            "        <file format=\"peptide\" URL=\"$decoy_fasta_file\" />\n"\
            "    </taxon>\n"\
            "    <taxon label=\"$Taxon\">\n"\
            "        <file format=\"peptide\" URL=\"$fasta_file\" />\n"\
            "    </taxon>\n"\
            "</bioml>" > $Tandem_taxonomy

#   input: generates the input.xml like file
    echo -e "<?xml version=\"1.0\"?>\n"\
            "<bioml>\n"\
            "    <note type=\"input\" label=\"list path, default parameters\">$Tandemparam</note>\n"\
            "    <note type=\"input\" label=\"list path, taxonomy information\">$Tandem_taxonomy</note>\n"\
            "    <note type=\"input\" label=\"protein, taxon\">$Taxon</note>\n"\
            "    <note type=\"input\" label=\"spectrum, path\">/path/to/input</note>\n"\
            "    <note type=\"input\" label=\"output, path\">/path/to/output</note>\n"\
            "</bioml>" > $Tandemparam_input
# The spectrum, path and output, path will be edited by the pipeline.


#   start of the main parameter file (default_input.xml)

#   spectrum parameters
    sed "s/label=\"spectrum, fragment monoisotopic mass error\">.*</label=\"spectrum, fragment monoisotopic mass error\">$fragment_ion_tolerance</g" $Tandemparam > $temp_Tandemparam
    sed "s/label=\"spectrum, parent monoisotopic mass error plus\">.*</label=\"spectrum, parent monoisotopic mass error plus\">$PrecursorMassTolerance</g" $temp_Tandemparam > $Tandemparam
    sed "s/label=\"spectrum, parent monoisotopic mass error minus\">.*</label=\"spectrum, parent monoisotopic mass error minus\">$PrecursorMassTolerance</g" $Tandemparam > $temp_Tandemparam

    if [[ $IsotopeErrorRange == "0" ]]; then
        local IsotopeErrorRange="no"
    else
        local IsotopeErrorRange="yes"
    fi
    sed "s/label=\"spectrum, parent monoisotopic mass isotope error\">.*</label=\"spectrum, parent monoisotopic mass isotope error\">$IsotopeErrorRange</g" $temp_Tandemparam > $Tandemparam
    sed "s/label=\"spectrum, fragment monoisotopic mass error units\">.*</label=\"spectrum, fragment monoisotopic mass error units\">$Fragment_MassUnit</g" $Tandemparam > $temp_Tandemparam
    sed "s/label=\"spectrum, parent monoisotopic mass error units\">.*</label=\"spectrum, parent monoisotopic mass error units\">$MassUnit</g" $temp_Tandemparam > $Tandemparam
    if [[ $mass_type_fragment == "0" ]]; then
        mass_type_fragment="average"
    else
        mass_type_fragment="monoisotopic"
    fi
    sed "s/label=\"spectrum, fragment mass type\">.*</label=\"spectrum, fragment mass type\">$mass_type_fragment</g" $Tandemparam > $temp_Tandemparam
#   end of spectrum parameters put the changes in $Tandemparam allows for a line to be added in the middle.
    cat $temp_Tandemparam > $Tandemparam

#   spectrum conditioning parameters
#    label="spectrum, dynamic range">100.0<
#    label="spectrum, total peaks">50<
#    sed "s/label=\"spectrum, maximum parent charge\">.*</label=\"spectrum, maximum parent charge\">$MaxCharge</g" $Tandemparam > $temp_Tandemparam

#    label="spectrum, use noise suppression">yes<

#    sed "s/label=\"spectrum, minimum parent m+h\">.*</label=\"spectrum, minimum parent m+h\">$MinPepMass</g" $temp_Tandemparam > $Tandemparam
#    sed "s/label=\"spectrum, minimum fragment mz\">.*</label=\"spectrum, minimum fragment mz\"></g" $Tandemparam > $temp_Tandemparam

#    label="spectrum, minimum peaks">10<
#    sed "s/label=\"spectrum, threads\">.*</label=\"spectrum, threads\">$NumThreads</g" $temp_Tandemparam > $Tandemparam
#    sed "s/label=\"spectrum, sequence batch size\">.*</label=\"spectrum, sequence batch size\">$spectrum_batch_size</g" $Tandemparam > $temp_Tandemparam

    cat $temp_Tandemparam > $Tandemparam
#   model refinement parameters

#   label="refine">yes</note>
#    label="refine, modification mass"><
#    label="refine, sequence path"><
#    label="refine, tic percent">20<
#    label="refine, spectrum synthesis">yes<
#    label="refine, maximum valid expectation value">0.1<
#    label="refine, unanticipated cleavage">yes<
#    label="refine, point mutations">no<
#    label="refine, use potential modifications for full refinement">no<
#    label="refine, point mutations">no<

#   Enzyme
#   Takes the cleavage info from the Shared parameter file and puts it in the correct format
    local Cleaveinfo=$(grep "^#enzyme: $search_enzyme_number" $LOC_Shared_param_file | awk '{print $4,$5,$6}')
    local Cleaveinfo1=$(echo $Cleaveinfo | awk '{print $1}')
    local Cleaveinfo2=$(echo $Cleaveinfo | awk '{print $2}')
    local Cleaveinfo3=$(echo $Cleaveinfo | awk '{print $3}')

    if [[ $Cleaveinfo3 == "X" ]]; then
        local Cleaveinfo3="[X]"
    else
        local Cleaveinfo3="{$Cleaveinfo3}"
    fi
    local Cleaveinfo2="[$Cleaveinfo2]"

    if [[ $Cleaveinfo1 == "1" ]]; then
        local search_enzyme_number=$(echo "$Cleaveinfo2|$Cleaveinfo3")
    else
        local search_enzyme_number=$(echo "$Cleaveinfo3|$Cleaveinfo2")
    fi

#   protein parameters
#   label=\"protein, taxon\">.*<
    sed "s/label=\"protein, cleavage site\">.*</label=\"protein, cleavage site\">$search_enzyme_number</g" $Tandemparam > $temp_Tandemparam 
#   label="protein, modified residue mass file"></note>
#   label="protein, homolog management">no</note>

    cat $temp_Tandemparam > $Tandemparam
#   scoring parameters

#   label="scoring, minimum ion count">4</note>
#   label="scoring, maximum missed cleavage sites">50</note>
#   Changes the 1 to yes and everything else to no (e.g. 0).
    ions="use_A_ions use_B_ions use_C_ions use_X_ions use_Y_ions use_Z_ions"
    value="$use_A_ions $use_B_ions $use_C_ions $use_X_ions $use_Y_ions $use_Z_ions"
    for ion in $ions
    do
        yes_no=$(echo $value | awk '{print $1}')
        value=$(echo $value | awk '{$1="";print $0}')
        if [[ $yes_no == "1" ]]; then
            local declare ${ion}="yes"
        else
            local declare ${ion}="no"
        fi
    done

    sed "s/label=\"scoring, a ions\">.*</label=\"scoring, a ions\">$use_A_ions</g" $Tandemparam > $temp_Tandemparam
    sed "s/label=\"scoring, b ions\">.*</label=\"scoring, b ions\">$use_B_ions</g" $temp_Tandemparam > $Tandemparam
    sed "s/label=\"scoring, c ions\">.*</label=\"scoring, c ions\">$use_C_ions</g" $Tandemparam > $temp_Tandemparam
    sed "s/label=\"scoring, x ions\">.*</label=\"scoring, x ions\">$use_X_ions</g" $temp_Tandemparam > $Tandemparam
    sed "s/label=\"scoring, y ions\">.*</label=\"scoring, y ions\">$use_Y_ions</g" $Tandemparam > $temp_Tandemparam
    sed "s/label=\"scoring, z ions\">.*</label=\"scoring, z ions\">$use_Z_ions</g" $temp_Tandemparam > $Tandemparam

#   label="scoring, cyclic permutation">no</note>
#   label="scoring, include reverse">no</note>
#   label="scoring, cyclic permutation">no</note>
#   label="scoring, include reverse">no</note>


#   TODO: either remove or add the parameters that are currently unedited (#    label=)

#   End of tandem param generator
    echo "Tandem parameter file has been generated. located at: $Tandemparam"
}


MSFragger ()
{

    MSFraggerparam="$output_dir"fraggerparam_PPG
    local Shared_param_file=$(echo $Shared_param_file | tr "[" "=")
    for param in $Shared_param_file
    do
    #   Check if the parameter is usable with comet
        local param_program=$(echo ${param} | awk -F\= '{print $3}')
        if [[ $param_program == *"MSFragger"* ]]; then
        #   If the parameter is usable with comet extract the parameter name and value from the file
            local param_name=$(echo ${param} | awk -F\= '{print $1}')
            local param_value=$(echo ${param} | awk -F\= '{print $2}')
        #   Set the parameter value in a variable with the parameter name
            declare local "$param_name"="$param_value"
        fi
    done


    echo "database_name =  $fasta_file " > $MSFraggerparam
    echo "num_threads = 0" >> $MSFraggerparam
    if [[ $MemUse == "" ]]; then
        Mem_Use="4G"
    fi
    echo "#Mem_Use $Mem_Use" >> $MSFraggerparam

    echo "precursor_mass_tolerance = 500.00" >> $MSFraggerparam
    echo "precursor_mass_units = 0" >> $MSFraggerparam
    echo "precursor_true_tolerance = 20.00" >> $MSFraggerparam
    echo "precursor_true_units = 1" >> $MSFraggerparam
    echo "fragment_mass_tolerance = 20.00" >> $MSFraggerparam
    echo "fragment_mass_units = 1" >> $MSFraggerparam

    echo "isotope_error = 0" >> $MSFraggerparam

    echo "search_enzyme_name = NoEnzyme" >> $MSFraggerparam
    echo "search_enzyme_cutafter = X" >> $MSFraggerparam
    echo "search_enzyme_butnotafter = X" >> $MSFraggerparam

    echo "num_enzyme_termini = 0" >> $MSFraggerparam
    echo "allowed_missed_cleavage = 1" >> $MSFraggerparam

    echo "clip_nTerm_M = 1" >> $MSFraggerparam

    echo "allow_multiple_variable_mods_on_residue = 1" >> $MSFraggerparam
    echo "max_variable_mods_per_mod = 3" >> $MSFraggerparam
    echo "max_variable_mods_combinations = 1000" >> $MSFraggerparam

    echo "output_file_extension = pepXML" >> $MSFraggerparam
    echo "output_format = pepXML" >> $MSFraggerparam
    echo "output_report_topN = 1" >> $MSFraggerparam
    echo "output_max_expect = 50" >> $MSFraggerparam

    echo "precursor_charge = 0 0" >> $MSFraggerparam
    echo "override_charge = 0" >> $MSFraggerparam

    echo "digest_min_length = 6" >> $MSFraggerparam
    echo "digest_max_length = 25" >> $MSFraggerparam
    echo "digest_mass_range = 600.0 3000.0" >> $MSFraggerparam
    echo "max_fragment_charge = 2" >> $MSFraggerparam

#open search parameters
    echo "track_zero_topN = 0" >> $MSFraggerparam
    echo "zero_bin_accept_expect = 0" >> $MSFraggerparam
    echo "zero_bin_mult_expect = 1" >> $MSFraggerparam
    echo "add_topN_complementary = 0" >> $MSFraggerparam

# spectral processing

    echo "minimum_peaks = 15" >> $MSFraggerparam
    echo "use_topN_peaks = 100" >> $MSFraggerparam
    echo "min_fragments_modelling = 3" >> $MSFraggerparam
    echo "min_matched_fragments = 6" >> $MSFraggerparam
    echo "minimum_ratio = 0.01" >> $MSFraggerparam
    echo "clear_mz_range = 0.0 0.0" >> $MSFraggerparam

# additional modifications

    echo "add_Cterm_peptide = 0.0" >> $MSFraggerparam
    echo "add_Nterm_peptide = 0.0" >> $MSFraggerparam
    echo "add_Cterm_protein = 0.0" >> $MSFraggerparam
    echo "add_Nterm_protein = 0.0" >> $MSFraggerparam
    echo "add_G_glycine = 0.0000" >> $MSFraggerparam
    echo "add_A_alanine = 0.0000" >> $MSFraggerparam
    echo "add_S_serine = 0.0000" >> $MSFraggerparam
    echo "add_P_proline = 0.0000" >> $MSFraggerparam
    echo "add_V_valine = 0.0000" >> $MSFraggerparam
    echo "add_T_threonine = 0.0000" >> $MSFraggerparam
    echo "add_C_cysteine = 0.0000" >> $MSFraggerparam
    echo "add_L_leucine = 0.0000" >> $MSFraggerparam
    echo "add_I_isoleucine = 0.0000" >> $MSFraggerparam
    echo "add_N_asparagine = 0.0000" >> $MSFraggerparam
    echo "add_D_aspartic_acid = 0.0000" >> $MSFraggerparam
    echo "add_Q_glutamine = 0.0000" >> $MSFraggerparam
    echo "add_K_lysine = 0.0000" >> $MSFraggerparam
    echo "add_E_glutamic_acid = 0.0000" >> $MSFraggerparam
    echo "add_M_methionine = 0.0000" >> $MSFraggerparam
    echo "add_O_ornithine = 0.0000" >> $MSFraggerparam
    echo "add_H_histidine = 0.0000" >> $MSFraggerparam
    echo "add_F_phenylalanine = 0.0000" >> $MSFraggerparam
    echo "add_U_selenocysteine = 0.0000" >> $MSFraggerparam
    echo "add_R_arginine = 0.0000" >> $MSFraggerparam
    echo "add_Y_tyrosine = 0.0000" >> $MSFraggerparam
    echo "add_W_tryptophan = 0.0000" >> $MSFraggerparam
    echo "add_B_user_amino_acid = 0.0000" >> $MSFraggerparam
    echo "add_J_user_amino_acid = 0.0000" >> $MSFraggerparam
    echo "add_X_user_amino_acid = 0.0000" >> $MSFraggerparam
    echo -e "add_Z_user_amino_acid = 0.0000\n" >> $MSFraggerparam

}

PeptideProphet ()
{
#   for possible use later currently need input in the Shared parameter file
PepProphParam=$(grep "^PeptideProphet_parameter" $LOC_Shared_param_file | awk '{print $3}')

}

Percolator ()
{
#   for possible use later currently need input in the Shared parameter file
PercolatorParam=$(grep "^Percolator_parameter" $LOC_Shared_param_file | awk '{print $3}')

}
