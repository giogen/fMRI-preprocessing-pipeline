#!/bin/bash

# Set directory containing FSL preprocessed files
output_dir=/data/coins/data/

# Loop over subjects and apply spatial unwarping
for subj in 0{01..32}

do

  for run in 1 2 3 4 5 6

  do

        # Set fieldmap magnitude image for current subject and session
        mag_image=${output_dir}${subj}/run${run}/fieldmap_sub${subj}_run${run}_mag_brain

        # Set functional 4D data for current subject and session
        func_series=${output_dir}${subj}/run${run}_melodic.ica/filtered_func_data_clean

        # Set fieldmap data for current subject and session
        fieldmap=${output_dir}${subj}/run${run}/fieldmap_sub${subj}_run${run}_rads.nii.gz

        echo "unwarping subject ${subj}, run ${run}"

        # Warp fieldmap magnitude image
        fugue -i ${mag_image} --dwell=0.00054 --loadfmap=${fieldmap} --unwarpdir=y --nokspace -s 0.5 -w ${mag_image}_warped

        # Compute mean functional from 4D series
        fslmaths ${func_series} -Tmean ${func_series}_mean

        # Apply bias correction to mean functional
        /usr/local/antsbin/bin/N4BiasFieldCorrection -i ${func_series}_mean.nii.gz -o ${func_series}_mean_nobias.nii.gz --convergence [50x50x30x20,0.0] -d 3

        # Apply bias correction to warped magnitude image
        /usr/local/antsbin/bin/N4BiasFieldCorrection -i ${mag_image}_warped.nii.gz -o ${mag_image}_warped_nobias.nii.gz --convergence [50x50x30x20,0.0] -d 3

        # Register the mean functional to the fieldmap magnitude image (using the latter as a reference since it is higher quality)
        flirt -in ${func_series}_mean_nobias -ref ${mag_image}_warped_nobias -dof 6 -cost normcorr -out ${mag_image}_EPIalign -omat ${mag_image}_EPIalign.mat

        # Invert the transformation matrix computed above
        convert_xfm -omat ${mag_image}_EPIalign_inverted.mat -inverse ${mag_image}_EPIalign.mat

        # Apply transformation matrix computed above to the fieldmap image
        flirt -in ${fieldmap} -ref ${func_series}_mean_nobias -init ${mag_image}_EPIalign_inverted.mat -applyxfm -out ${fieldmap}_EPIalign
        
        # Unwarp the functional scans
        fugue -i ${func_series} --dwell=0.00054 --loadfmap=${fieldmap}_EPIalign --unwarpdir=y -u ${func_series}_unwarped

  done

done

