#!/bin/bash

# Set directory containing antsRegistration scripts
ANTSPATH=/usr/local/antsbin/bin

# Set ITK thread count
ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS=1
export ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS

# Loop over subjects and run ANTs normalization
for sbj in 0{01..32}

do

  echo "Running subject: ${sbj}"

  cd /data/coins/data/${sbj}

  # Path to afine transform tool
  c3d_affine_tool=/data/c3d-1.0.0-Linux-x86_64/bin/c3d_affine_tool

  # Set paths to the T1 structural scan, and the standard anatomical image
  struct_path=/data/coins/data/${sbj}
  anat_path=/data/templates/CIT168toMNI152_700um

  # Align T2 scan to the T1 structural scan
  echo "started T1/T2 alignment at $(date +"%T")"
  flirt -in ${struct_path}/T2_reoriented_brain.nii.gz -ref ${struct_path}/T1_reoriented_brain.nii.gz -out ${struct_path}/T2_reoriented_brain_aligned_T1.nii.gz
  echo "finished T1/T2 alignment at $(date +"%T")"

  # Assign arguments
  fixed_t1=`imglob -extension .nii.gz ${anat_path}/CIT168_T1w_MNI.nii.gz`
  fixed_t2=`imglob -extension .nii.gz ${anat_path}/CIT168_T2w_MNI.nii.gz`
  moving_t1=`imglob -extension .nii.gz ${struct_path}/T1_reoriented_brain.nii.gz`
  moving_t2=`imglob -extension .nii.gz ${struct_path}/T2_reoriented_brain_aligned_T1.nii.gz`

  fixed_mask=${anat_path}/`basename ${fixed_t1} .nii.gz`_mask.nii.gz
  moving_mask=${struct_path}/`basename ${moving_t1} .nii.gz`_mask.nii.gz

  # Create fixed_t1 mask
  fslmaths $fixed_t1 -thr .1 -bin $fixed_mask

  echo "Registering $moving_t1 to $fixed_t1"

  # Prefix for output transform files
  outPrefix=${moving_t1%%.nii.gz}

  echo "Output prefix : $outPrefix"

  dim=3
  echo "Registration dimensionality: $dim"

  echo "Running initial Flirt affine at $(date +"%T")"
  flirt -ref $fixed_t1 -in $moving_t1 -out tmp_${sbj} -omat tmp_${sbj}.mat

  echo "Converting fsl transformation to ras format at $(date +"%T")"
  c3d_affine_tool -ref $fixed_t1 -src $moving_t1 tmp_${sbj}.mat -fsl2ras -oitk itk_transformation_${sbj}.txt

  echo "Applying affine transformation to mask at $(date +"%T")"
  ${ANTSPATH}/WarpImageMultiTransform 3 $fixed_mask $moving_mask -R $moving_t1 -i itk_transformation_${sbj}.txt

  # Mattes metric parameters
  metricWeight=1
  numberOfBins=32
  radius=4

  echo  "Running ants registration at $(date +"%T")"
  # Deformable
  ${ANTSPATH}/antsRegistration \
   --verbose 1 \
   --dimensionality $dim \
   --initial-moving-transform itk_transformation_${sbj}.txt \
   --metric CC[ $fixed_t1, $moving_t1, .8, $radius] \
   --metric CC[ $fixed_t2, $moving_t2, .2, $radius] \
   --transform Syn[0.1,3,0] \
   --convergence [100x100x70x50x20, 1.e-6, 10] \
   --smoothing-sigmas 5x3x2x1x0vox \
   --shrink-factors 10x6x4x2x1 \
   --use-histogram-matching 1 \
   -x [ $fixed_mask, $moving_mask ] \
   --interpolation Linear \
   -o [ ${outPrefix}_xfm, ${outPrefix}_warped.nii.gz ]

  echo  "Finished ants registration for subject ${subj} at $(date +"%T")"
  
  cd /data/coins/data
 
done
