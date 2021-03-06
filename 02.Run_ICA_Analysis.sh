#!bin/bash

# Set directory containing nifti data
data_dir=/data/coins/data/

# Set directory containing fsl scripts and templates
code_dir=/data/coins/code/

# Loop over subjects
for subj in 0{01..32}

do

        echo "Working on subject ${subj}"

        for run in 1 2 3 4 5 6

        do

                # Number of volumes in current run
                nvols=`fslnvols ${data_dir}${subj}/run${run}/MB_run${run}_reoriented.nii.gz`

                # Edit template
                cp ${code_dir}melodic_single_run_template.fsf ${code_dir}melodic_single_run_scripts/melodic_single_run_template_sub${subj}_run${run}.fsf
                
                # Replace subject index
                sed -i -e 's/001/'$subj'/g' ${code_dir}melodic_single_run_scripts/melodic_single_run_template_sub${subj}_run${run}.fsf
                
                # Replace session (run) index
                sed -i -e 's/run1/'run$run'/g' ${code_dir}melodic_single_run_scripts/melodic_single_run_template_sub${subj}_run${run}.fsf
                
                # Replace number of time points for current session
                sed -i -e 's/620/'$nvols'/' ${code_dir}melodic_single_run_scripts/melodic_single_run_template_sub${subj}_run${run}.fsf
                
                # Subject 030 only has T2 scan available
                exclude=030
                if [ "${subj}" -ne "${exclude}" ]
                then
                        sed -i -e 's/T1/T2/g' ${code_dir}melodic_single_run_scripts/melodic_single_run_template_sub${subj}_run${run}.fsf
                fi

                # Edit script
                cp ${code_dir}melodic_single_run_template_script.sh ${code_dir}melodic_single_run_scripts/melodic_single_run_template_script_sub${subj}_run${run}.sh
                sed -i -e 's/001/'$subj'/g' ${code_dir}melodic_single_run_scripts/melodic_single_run_template_script_sub${subj}_run${run}.sh
                sed -i -e 's/run1/'run$run'/g' ${code_dir}melodic_single_run_scripts/melodic_single_run_template_script_sub${subj}_run${run}.sh

                # Run ICA analysis script
                feat ${code_dir}melodic_single_run_scripts/melodic_single_run_template_script_sub${subj}_run${run}.sh

        done

done


  
