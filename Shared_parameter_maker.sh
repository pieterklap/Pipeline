#!/bin/bash

Header="# Parameter file to be used with the Proteomic Pipeline Generator. "
Header_ver="(v0.x)"
Header_file_ver=$(head -n1 $LOC_Shared_param_file | awk '{print $NF}')
Header_file=$(head -n1 $LOC_Shared_param_file | awk '{$NF="";print $0}')

echo "$Header"
echo "$Header_file"

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
    if [[ $PrecursorMassUnit == "Daltons" ]]; then
        PrecursorMassUnit="0"
    fi
    if [[ $PrecursorMassUnit == "ppm" ]]; then
        PrecursorMassUnit="2"
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
    echo "peptide_mass_units = $PrecursorMassUnit" >> $cometparam
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
    echo "max_precursor_charge = 6" >> $cometparam
    echo "nucleotide_reading_frame = 0" >> $cometparam
    echo "clip_nterm_methionine = 0" >> $cometparam
    echo "spectrum_batch_size = 10000" >> $cometparam
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


#   TODO: Add modification to the list

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
    if [[ "$PrecursorMassUnit" == "Daltons" ]]; then
        local PrecursorMassUnit="Da"
    fi
    echo "PrecursorMassTolerance -t $PrecursorMassTolerance$PrecursorMassUnit" >> $MSGFPlusparam
    echo "IsotopeErrorRange -ti $IsotopeErrorRange" >> $MSGFPlusparam
    echo "NumThreads -thread $NumThreads" >> $MSGFPlusparam
    echo "NumTasks -tasks $NumTasks" >> $MSGFPlusparam

    echo "verbose -verbose 0" >> $MSGFPlusparam
    echo "Decoy_search -tda 1" >> $MSGFPlusparam

    echo "FragmentMethodID -m $FragmentMethodID" >> $MSGFPlusparam
    echo "MS2DetectorID -inst $MS2DetectorID" >> $MSGFPlusparam

    local search_enzyme_number=$(grep "^#enzyme: $search_enzyme_number" $LOC_Shared_param_file | awk '{print $7}')
    echo "EnzymeID -e $search_enzyme_number" >> $MSGFPlusparam
    echo "ProtocolID -protocol $ProtocolID" >> $MSGFPlusparam
    echo "Tolerable_Termini -ntt $Tolerable_Termini" >> $MSGFPlusparam

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
#   taxonomy
    echo -e "<?xml version=\"1.0\"?>\n"\
            "<bioml label=\"x! taxon-to-file matching list\">\n"\
            "    <taxon label=\""$Taxon"_decoy\">\n"\
            "        <file format=\"peptide\" URL=\"$decoy_fasta_file\" />\n"\
            "    </taxon>\n"\
            "    <taxon label=\"$Taxon\">\n"\
            "        <file format=\"peptide\" URL=\"/home/pieter/pipeline/fasta/up000005640.fasta\" />\n"\
            "    </taxon>\n"\
            "</bioml>" > $Tandem_taxonomy

    echo -e "<?xml version=\"1.0\"?>\n"\
            "<bioml>\n"\
            "    <note type=\"input\" label=\"list path, default parameters\">$Tandemparam</note>\n"\
            "    <note type=\"input\" label=\"list path, taxonomy information\">$Tandem_taxonomy</note>\n"\
            "    <note type=\"input\" label=\"protein, taxon\">$Taxon</note>\n"\
            "    <note type=\"input\" label=\"spectrum, path\">/path/to/input</note>\n"\
            "    <note type=\"input\" label=\"output, path\">/path/to/output</note>\n"\
            "</bioml>" > $Tandemparam_input



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
    sed "s/label=\"spectrum, fragment monoisotopic mass error units\">.*</label=\"spectrum, fragment monoisotopic mass error units\">$MassUnit</g" $Tandemparam > $temp_Tandemparam
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

#   End of tandem param generator
    echo "Tandem parameter file has been generated. located at: $Tandemparam"
}

