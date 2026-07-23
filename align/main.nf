// Alignment with minimap2, 


process MINIMAP2_ALIGN {
    tag "${meta.id}"

    input:
    tuple val(meta), path(reads)
    tuple path(fasta), path(fai)

    output:
    tuple val(meta), path("${meta.id}.sorted.bam"), emit: bam

    script:
    def args = task.ext.args ?: ''
    """
    minimap2 -a \\
        ${args} \\
        -x ${meta.preset} \\
        -t ${task.cpus} \\
        -R "@RG\\tID:${meta.id}\\tSM:${meta.id}\\tPL:${meta.platform}\\tLB:${meta.id}" \\
        ${fasta} \\
        ${reads} \\
        | samtools sort -@ ${task.cpus} -o ${meta.id}.sorted.bam
    """

    stub:
    """
    touch ${meta.id}.sorted.bam
    """
}