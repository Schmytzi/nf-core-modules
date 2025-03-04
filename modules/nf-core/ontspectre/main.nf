process ONTSPECTRE {
    tag "$meta.id"
    label 'process_medium'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/73/73e5ebe79fbffbe451a05bf9182220a70f46ed3187891d8ab9033119f4919dc8/data':
        'community.wave.seqera.io/library/ont-spectre:0.3.2--adfae189059be3d9' }"

    input:
    tuple val(meta), path(summary), path(regions_bed), path(vcf), path(tbi)
    tuple val(meta2), path(fasta)
    tuple val(meta3), path(fai)
    tuple val(meta4), path(metadata)  // reference metadata, optional
    tuple val(meta5), path(blacklist) // optional
    val bin_size


    output:
    tuple val(meta), path("out/*.bed")                  , emit: bed
    tuple val(meta), path("out/*.vcf.gz")               , emit: vcf
    tuple val(meta), path("out/*.tbi")                  , emit: tbi
    tuple val(meta), path("out/*.spc.gz")               , emit: spc
    tuple val(meta), path("out/windows_stats/*.csv")    , emit: windows_stats
    tuple val(meta), path("out/predicted_karyotype.txt"), emit: karyotype
    path "versions.yml"                             , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def meta_arg = args.contains("--metadata") || !metadata ? "" : "--metadata $metadata"
    def blacklist_arg = args.contains("--blacklist") || !blacklist ? "" : "--blacklist $blacklist"
    """
    spectre \\
        CNVCaller \\
        $args \\
        $meta_arg \\
        $blacklist_arg \\
        --bin-size $bin_size \\
        --threads $task.cpus \\
        --sample-id $prefix \\
        --coverage . \\
        --snv $vcf \\
        --reference $fasta \\
        --output-dir out \\


    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        ont-spectre: \$(spectre version |& sed '1!d ; s/spectre::INFO> Spectre version: //')
    END_VERSIONS
    """

    stub:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    mkdir out
    cd out
    mkdir windows_stats
    touch ${prefix}.bed ${prefix}.vcf.gz.tbi predicted_karyotype.txt windows_stats/${prefix}.csv
    echo "" | gzip > ${prefix}.vcf.gz
    echo "" | gzip > ${prefix}.spc.gz
    cd ..

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        ont-spectre: \$(spectre version |& sed '1!d ; s/spectre::INFO> Spectre version: //')
    END_VERSIONS
    """
}
