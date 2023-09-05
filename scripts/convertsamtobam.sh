#!/bin/bash
#SBATCH --account=def-tkitzler
#SBATCH --time=03:00:00
#SBATCH --mem=2G

module load samtools

sm=$1

samtools view --threads 16 \
    -O BAM \
    -o "aligned_$sm.bam" \
    results_$sm.sam \
    2> "samtools-$sm.log"

sbatch gatk_markdup.sh $sm