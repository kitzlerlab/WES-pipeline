#!/bin/bash
#SBATCH --account=def-tkitzler
#SBATCH --time=03:00:00
#SBATCH --mem=6G
#SBATCH --cpus-per-task=3
#SBATCH --array=0-2

module load gatk/4.1.8.1
export GATK_JAR=/cvmfs/soft.mugqic/CentOS6/software/GenomeAnalysisTK/GenomeAnalysisTK-4.1.8.1/gatk-package-4.1.8.1-local.jar
export reference=$MUGQIC_INSTALL_HOME/genomes/species/Homo_sapiens.GRCh38/genome/Homo_sapiens.GRCh38.fa

exome=sureselectV5_padded_hg38.bed

# Specify the path to the config file
config=config.txt

# Extract the sample name for the current $SLURM_ARRAY_TASK_ID
name=$(awk -v ArrayTaskID=$SLURM_ARRAY_TASK_ID '$1==ArrayTaskID {print $2}' $config)

java -Xmx6g -jar $GATK_JAR HaplotypeCaller \
-R $reference \
-I "BAM/aligned_${name}_markdup_bqsr.bam" \
-O "${name}_raw_variants.g.vcf.gz" \
-L $exome \
-ip 0 \
-ERC GVCF