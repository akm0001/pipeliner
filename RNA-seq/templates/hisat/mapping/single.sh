hisat2 -p ${params.hisat_mapping.cpus} --summary-file '${sampleid}.hisat.log' --new-summary -x '${params.outdir}/hisat/index/part' -U ${reads[0]} -S '${sampleid}.sam'
samtools view -S -b '${sampleid}.sam'
samtools sort '${sampleid}.sam' -o '${sampleid}.sorted.bam'