#!/bin/bash

# Set directory containing FSL preprocessed files
output_dir=/data/coins/data/

# Set directory containing fsl scripts and templates
code_dir=/data/coins/code/

# Set location of FIX code
fix_dir=/data/fix1.06/

# Set classifier to use
classifier=FIX_giovanniCoins_jeffCasinoUSA.RData

# Set threshold for cleanup procedure
threshold=10

# Run classifier on unseen session, classify components, and apply cleanup

for subj in 0{01..32}

do

  for run in 1 2 3 4 5 6

  do

        # Run classifier
        ${fix_dir}fix -c ${output_dir}${subj}/run${run}_melodic.ica ${code_dir}${classifier} ${threshold}

        # Apply cleanup 
        ${fix_dir}fix -a ${output_dir}${subj}/run${run}_melodic.ica/fix4melview_${classifier}_thr${threshold}.txt

  done 
  
done

