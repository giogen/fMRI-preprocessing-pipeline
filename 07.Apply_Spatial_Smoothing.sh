#!bin/bash

# Set data location
data_dir=/data/coins/data/

# Set smoothing kernel
gausskernel=3.39731612

# Loop over subjects and runs and apply smoothing
for subj in 0{01..32}

do

        for run in 1 2 3 4 5 6

        do

                echo "Applying smoothing to subject ${subj}, session ${run}"

                fslmaths ${data_dir}${subj}/run${run}_melodic.ica/filtered_func_data_clean_unwarped_ANTsWarp \
                -kernel gauss ${gausskernel} \
                -fmean ${data_dir}${subj}/run${run}_melodic.ica/filtered_func_data_clean_unwarped_ANTsWarp_s8

        done

done
