#!/bin/bash

# compleX Bacterial Sample (XBS) variant caller: variant calling core step 2
# Paper: Comprehensive and accurate genetic variant identification from contaminated and low coverage Mycobacterium tuberculosis whole genome sequencing data.
# Authors: Tim H. Heupink, Lennert Verboven, Robin M. Warren, Annelies Van Rie.
# Contact: tim.heupink@uantwerpen.be and lennert.verboven@uantwerpen.be

# This script will combine the sample GVCFs, genotype and filter SNPs and INDELs

# required programs
JAVA='/path/to/java'
GATK='/patk/to/gatk.jar'

# required files
REFERENCE='/path/to/H37RV.fa'
SNP_TRUTH='/path/to/TruthSet.SNP.vcf'
INDEL_TRUTH='/path/to/TruthSet.INDEL.vcf'

# required info
OUT_DIR='/the/output/directory/'
JOINT_NAME='YourStudyName'
GVCFs='-V $OUT_DIR/gvcf/sample1.g.vcf.gz -V $OUT_DIR/gvcf/sample2.g.vcf.gz -V $OUT_DIR/gvcf/sample3.g.vcf.gz' # here it is possible to select only the samples that pass QC, e.g. based on minimum mean depth


# make dirs
mkdir $OUT_DIR/vcf/ $OUT_DIR/SNPvqsr/ $OUT_DIR/INDELvqsr/

# combine GVCFs
$JAVA -Xmx64G -jar $GATK CombineGVCFs -R $REFERENCE -G StandardAnnotation -G AS_StandardAnnotation $GVCFs -O $OUT_DIR/vcf/$JOINT_NAME.combined.vcf.gz

# genotype
$JAVA -Xmx64G -jar $GATK GenotypeGVCFs -R $REFERENCE -V $OUT_DIR/vcf/$JOINT_NAME.combined.vcf.gz -O $OUT_DIR/vcf/$JOINT_NAME.raw_variants.vcf.gz -G StandardAnnotation -G AS_StandardAnnotation --sample-ploidy 1

# SNP selection
$JAVA -Xmx64G -jar $GATK SelectVariants -R $REFERENCE -V $OUT_DIR/vcf/$JOINT_NAME.raw_variants.vcf.gz --select-type-to-include SNP -O $OUT_DIR/vcf/$JOINT_NAME.raw_snps.vcf.gz --remove-unused-alternates --exclude-non-variants

# SNP VQSR
$JAVA -Xmx64G -jar $GATK VariantRecalibrator -R $REFERENCE -V $OUT_DIR/vcf/$JOINT_NAME.raw_snps.vcf.gz -AS --resource:5000SNP,known=false,training=true,truth=true,prior=20.0 $SNP_TRUTH -an AS_MQRankSum -an AS_QD -an AS_MQ -an DP -mode SNP --output $OUT_DIR/SNPvqsr/$JOINT_NAME.recal.vcf.gz --tranches-file $OUT_DIR/SNPvqsr/$JOINT_NAME.tranches --target-titv 1.85 --truth-sensitivity-tranche 100.0 --truth-sensitivity-tranche 99.9 --truth-sensitivity-tranche 99.8 --truth-sensitivity-tranche 99.7 --truth-sensitivity-tranche 99.6 --truth-sensitivity-tranche 99.5 --truth-sensitivity-tranche 99.4 --truth-sensitivity-tranche 99.3 --truth-sensitivity-tranche 99.2 --truth-sensitivity-tranche 99.1 --truth-sensitivity-tranche 99.0 --max-gaussians 4 -mq-cap 60 --output-model $OUT_DIR/SNPvqsr/$JOINT_NAME.model --rscript-file $OUT_DIR/SNPvqsr/$JOINT_NAME.R

# SNP apply filter
$JAVA -Xmx64G -jar $GATK ApplyVQSR -R $REFERENCE -V $OUT_DIR/vcf/$JOINT_NAME.raw_snps.vcf.gz -O $OUT_DIR/vcf/$JOINT_NAME.FilteredSNPs.vcf.gz --tranches-file $OUT_DIR/SNPvqsr/$JOINT_NAME.tranches --recal-file $OUT_DIR/SNPvqsr/$JOINT_NAME.recal.vcf.gz --ts-filter-level 99.9 -AS --exclude-filtered -mode SNP

# INDEL selection
$JAVA -Xmx64G -jar $GATK SelectVariants -R $REFERENCE -V $OUT_DIR/vcf/$JOINT_NAME.raw_variants.vcf.gz --select-type-to-include INDEL -O $OUT_DIR/vcf/$JOINT_NAME.raw_indels.vcf.gz --remove-unused-alternates --exclude-non-variants

# INDEL VQSR
# On failure exclude '-an MQRanksum' and lower guassians if necessary.
$JAVA -Xmx64G -jar $GATK VariantRecalibrator -R $REFERENCE -V $OUT_DIR/vcf/$JOINT_NAME.raw_indels.vcf.gz --resource:500INDEL,known=false,training=true,truth=true,prior=20.0 $INDEL_TRUTH -an MQRankSum -an QD -an DP -mode INDEL --output $OUT_DIR/INDELvqsr/$JOINT_NAME.recal.vcf.gz --tranches-file $OUT_DIR/INDELvqsr/$JOINT_NAME.tranches --target-titv 1.85 --truth-sensitivity-tranche 100.0 --truth-sensitivity-tranche 99.9 --truth-sensitivity-tranche 99.8 --truth-sensitivity-tranche 99.7 --truth-sensitivity-tranche 99.6 --truth-sensitivity-tranche 99.5 --truth-sensitivity-tranche 99.4 --truth-sensitivity-tranche 99.3 --truth-sensitivity-tranche 99.2 --truth-sensitivity-tranche 99.1 --truth-sensitivity-tranche 99.0 --max-gaussians 2 -mq-cap 60 --output-model $OUT_DIR/INDELvqsr/$JOINT_NAME.model --rscript-file $OUT_DIR/INDELvqsr/$JOINT_NAME.R

# INDEL apply filter
$JAVA -Xmx64G -jar $GATK ApplyVQSR -R $REFERENCE -V $OUT_DIR/vcf/$JOINT_NAME.raw_indels.vcf.gz -O $OUT_DIR/vcf/$JOINT_NAME.FilteredINDELs.vcf.gz --tranches-file $OUT_DIR/INDELvqsr/$JOINT_NAME.tranches --recal-file $OUT_DIR/INDELvqsr/$JOINT_NAME.recal.vcf.gz --lod-score-cutoff 0.0000 --exclude-filtered -mode INDEL
