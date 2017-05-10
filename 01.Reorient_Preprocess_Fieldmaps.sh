#!/bin/bash

############################################################################################################
# Set useful directories and paths

# Set directory containing raw data
data_dir=/data/coins/raw_data/

# Set directory containing fsl scripts and templates
code_dir=/data/coins/code/

# Set output directory for preprocessed files
output_dir=/data/coins/data/

############################################################################################################

# Loop over subjects
for subj in 0{01..32}

do

	echo "Working on subject ${subj}"

	############################################################################################################
	# Work on T2 anatomical scan

	echo "Working on T2 scan"
  
        # Reorient T2 scan to standard
        fslreorient2std ${data_dir}${subj}/T2/T2.nii.gz ${output_dir}${subj}/T2_reoriented.nii.gz

        # Apply BET to reoriented T2
        bet ${output_dir}${subj}/T2_reoriented.nii.gz ${output_dir}${subj}/T2_reoriented_brain.nii.gz -B -f 0.2
        ############################################################################################################

  	############################################################################################################
	# Work on T1 anatomical scan

        # Subject 30 does not have a T1 scan
        exclude=030

        if [ "${subj}" -ne "${exclude}" ]

        then

        	echo "Working on T1 scan"

        	# Reorient T1 scan to standard
       	 	fslreorient2std ${data_dir}${subj}/T1/T1.nii.gz ${output_dir}${subj}/T1_reoriented.nii.gz

        	# Apply BET to reoriented T1
        	bet ${output_dir}${subj}/T1_reoriented.nii.gz ${output_dir}${subj}/T1_reoriented_brain.nii.gz -B -f 0.2

    	fi
        ############################################################################################################  

        # Loop over runs and pre-process fieldmap images
        for run in 1 2 3 4 5 6

        do

    	############################################################################################################
        echo "Preparing fieldmaps for run ${run} for future unwarping"

        # Reorient FM scans to standard
        fslreorient2std ${data_dir}${subj}/FM_run${run}/FM_pos_run${run}.nii.gz ${output_dir}${subj}/run${run}/FM_pos_run${run}_reoriented.nii.gz
        fslreorient2std ${data_dir}${subj}/FM_run${run}/FM_neg_run${run}.nii.gz ${output_dir}${subj}/run${run}/FM_neg_run${run}_reoriented.nii.gz

        # Merge 2 FM files into single file
        fslmerge -t ${output_dir}${subj}/run${run}/FM_pos_run${run}_reoriented_merged.nii.gz ${output_dir}${subj}/run${run}/FM_pos_run${run}_reoriented.nii.gz ${output_dir}${subj}/run${run}/FM_neg_run${run}_re$

        # Run TOPUP to generate fieldmap
        topup --imain=${output_dir}${subj}/run${run}/FM_pos_run${run}_reoriented_merged --datain=${code_dir}fieldmaps_datain.txt --config=b02b0.cnf --fout=${output_dir}${subj}/run${run}/fieldmap_sub${subj}_run$

        # Scale fieldmap from Hz to rad/s
        fslmaths ${output_dir}${subj}/run${run}/fieldmap_sub${subj}_run${run} -mul 6.28 ${output_dir}${subj}/run${run}/fieldmap_sub${subj}_run${run}_rads

        # Create a single, brain extracted magnitude image for unwarping
        fslmaths ${output_dir}${subj}/run${run}/FM_pos_run${run}_reoriented_merged_unwarped -Tmean ${output_dir}${subj}/run${run}/fieldmap_sub${subj}_run${run}_mag
        bet ${output_dir}${subj}/run${run}/fieldmap_sub${subj}_run${run}_mag ${output_dir}${subj}/run${run}/fieldmap_sub${subj}_run${run}_mag_brain
        ############################################################################################################

        ############################################################################################################
        echo "Reorienting functional data to standard orientation"   

        fslreorient2std ${data_dir}${subj}/MB_run${run}/MB_run${run}.nii.gz ${output_dir}${subj}/run${run}/MB_run${run}_reoriented.nii.gz
        ############################################################################################################

    done

done

