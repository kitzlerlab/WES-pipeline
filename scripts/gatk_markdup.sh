#!/bin/bash
#SBATCH --account=def-tkitzler
#SBATCH --time=01:00:00
#SBATCH --mem=40G
#SBATCH --cpus-per-task=14

module load java/1.8.0_192
export GATK_JAR=/cvmfs/soft.mugqic/CentOS6/software/GenomeAnalysisTK/GenomeAnalysisTK-4.1.8.1/gatk-package-4.1.8.1-local.jar

sm=$1

java -Xms60G -Xmx60G -jar $GATK_JAR MarkDuplicatesSpark \
  -I aligned_${sm}.bam \
  -O aligned_${sm}"_"markdup.bam \
  --spark-master local[12]

sbatch gatk_bqsr.sh $sm