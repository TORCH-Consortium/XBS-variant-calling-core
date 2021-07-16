#!/bin/bash

# compleX Bacterial Sample (XBS) variant caller: variant calling core step 1
# Paper: Comprehensive and accurate genetic variant identification from contaminated and low coverage Mycobacterium tuberculosis whole genome sequencing data.
# Authors: Tim H. Heupink, Lennert Verboven, Robin M. Warren, Annelies Van Rie.
# Contact: tim.heupink@uantwerpen.be and lennert.verboven@uantwerpen.be

# This script will map the fastq sequence reads to the reference genome, create a GVCF and gather some stats used for QC.

# required programs
BWA='/path/to/bwa'
JAVA='/path/to/java'
GATK='/patk/to/gatk.jar'
SAMTOOLS='/path/to/samtools'

# required files
REFERENCE='/path/to/H37RV.fa'

# required info
SAMPLE_ID='sample1'
FLOWCELL='1'
LANE='1'
SAMPLE='sample1'
LIBRARY='1'
INDEX='1'
SEQ_R1='/path/to/sample1.R1.fastq.gz'
SEQ_R2='/path/to/sample1.R2.fastq.gz'
OUT_DIR='/the/output/directory/'

# make dirs
mkdir $OUT_DIR/mapped/ $OUT_DIR/gvcf/ $OUT_DIR/stats/

# generate readgroup name
RG="@RG\tID:$FLOWCELL.$LANE\tSM:$SAMPLE\tPL:illumina\tLB:lib$LIBRARY\tPU:$FLOWCELL.$LANE.$INDEX"

# mapping
$BWA mem -M -t $BWA_THREADS -R $RG $REFERENCE $SEQ_R1 $SEQ_R2 | $SAMTOOLS sort -@ $SAMTOOLS_THREADS -O BAM -o $OUT_DIR/mapped/$SAMPLE_ID.recal_reads.bam -
$SAMTOOLS index $OUT_DIR/mapped/$SAMPLE_ID.recal_reads.bam

# haplotype calling and indel realignment
$JAVA -Xmx64G -jar $GATK HaplotypeCaller -R $REFERENCE -I $OUT_DIR/mapped/$SAMPLE_ID.recal_reads.bam -ploidy 1 -ERC GVCF --read-filter MappingQualityNotZeroReadFilter -G StandardAnnotation -G AS_StandardAnnotation -O $OUT_DIR/gvcf/$SAMPLE_ID.g.vcf.gz

# stats
$SAMTOOLS stats -F DUP,SUPPLEMENTARY,SECONDARY,UNMAP,QCFAIL $OUT_DIR/mapped/$SAMPLE_ID.recal_reads.bam -r $REFERENCE > $OUT_DIR/stats/$SAMPLE_ID.recal_reads.SamtoolStats

$JAVA -Xmx64G -jar $GATK CollectWgsMetrics -R $REFERENCE -I $OUT_DIR/mapped/$SAMPLE_ID.recal_reads.bam -O $OUT_DIR/stats/$SAMPLE_ID.recal_reads.WgsMetrics --READ_LENGTH 0 --COVERAGE_CAP 10000 --COUNT_UNPAIRED

$JAVA -Xmx64G -jar $GATK FlagStat -R $REFERENCE -I $OUT_DIR/mapped/$SAMPLE_ID.recal_reads.bam > $OUT_DIR/stats/$SAMPLE_ID.recal_reads.FlagStat

