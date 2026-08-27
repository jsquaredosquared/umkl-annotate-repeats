configfile: "config/config.yaml"


import os

batch = os.path.basename(config["pathvars"]["samples_dir"])


rule unzip_sv_vcf:
    input:
        "<samples_dir>/{sample}/{sample}.sv.vcf.gz",
    output:
        temp("<samples_dir>/{sample}/{sample}.sv.vcf"),
    conda:
        "../envs/sv_analysis.yaml"
    shell:
        "zcat {input} > {output}"


rule merge_sv_calls:
    input:
        vcfs=collect(
            "<samples_dir>/{SAMPLE}/{SAMPLE}.sv.vcf",
            SAMPLE=os.listdir(config["pathvars"]["samples_dir"]),
        ),
    output:
        vcfgz="<results>/sv/{batch}.sv.vcf.gz",
        index="<results>/sv/{batch}.sv.vcf.gz.tbi",
    log:
        "<logs>/{batch}/merge_sv_calls.log",
    conda:
        "../envs/sv_analysis.yaml"
    script:
        "../scripts/merge_svs.xsh"


rule create_sv_bed_file:
    input:
        rules.merge_sv_calls.output.vcfgz,
    output:
        "<results>/sv/{batch}.sv.bed",
    log:
        "<logs>/{batch}/create_sv_bed_file.log",
    conda:
        "../envs/sv_analysis.yaml"
    params:
        max_len=1_000_000,
    shell:
        """
        bcftools query \
            -f '%CHROM\t%POS0\t%END\t%INFO/SVTYPE\t%ID' \
            -i 'INFO/SVLEN<{params.max_len}' \
            -o {output} {input} 2>{log}
        """


rule annotate_sv_calls:
    input:
        rules.create_sv_bed_file.output,
    output:
        annotations="<results>/sv/{batch}.sv.annotated.tsv",
    log:
        "<logs>/{batch}/annotate_sv_calls.log",
    conda:
        "../envs/sv_analysis.yaml"
    params:
        genome_build="GRCh38",
        transcript_origin="ENSEMBL",
        output_dir=subpath(output.annotations, parent=True),
        annotations_dir=config["pathvars"]["annotsv_dir"],
        svtype_col=4,
    shell:
        """
        AnnotSV \
            -annotationsDir {input.annotations_dir} \
            -genomeBuild {params.genome_build} \
            -outputDir {params.output_dir} \
            -outputFile {output.annotations} \
            -SVinputFile {input} \
            -svtBEDcol {params.svtype_col} \
            -tx {params.transcript_origin} \
            >&{log}
        """


rule create_caddsv_input:
    input:
        rules.create_sv_bed_file.output,
    output:
        temp("<results>/sv/caddsv_results/{batch}.sv.bed"),
    log:
        "<logs>/{batch}/create_caddsv_bed_file.log",
    shell:
        r"""
        cut -f 1,2,3,4 {input} >{output} 2>{log}
        """


# TODO: Sort out environments OR containers.
# TODO: Sort out snakemake working directory conflict.
rule score_with_caddsv:
    input:
        bed=rules.create_caddsv_input.output,
    output:
        "<results>/sv/caddsv_results/scored/{batch}.sv_score.tsv",
    log:
        "<logs>/{batch}/score_with_caddsv.log",
    conda:
        "../envs/caddsv.yaml"
    params:
        annotations_dir=config["pathvars"]["caddsv_dir"],
        output_dir=subpath(output, ancestor=2),
    shell:
        """
        caddsv run {input.bed} \
            --annotations_dir {params.annotations_dir} \
            --output-dir {params.output_dir} \
            --threads {resources.threads} \
            2>{log}
        """


rule create_phenosv_input:
    input:
        rules.create_sv_bed_file.output,
    output:
        temp("<results>/sv/phenosv_results/{batch}.sv.bed"),
    log:
        "<logs>/{batch}/create_phenosv_bed_file.log",
    shell:
        r"""
        cut -f 1,2,3,5,4 {input} \
            | sed -E 's/\bDEL\b/deletion/g; s/\bDUP\b/duplication/g; s/\bINS\b/insertion/g; s/\bINV\b/inversion/g; s/\bTRA\b/translocation/g' \
                >{output} 2>{log}
        """


rule score_with_phenosv:
    input:
        bed=rules.create_phenosv_input.output,
    output:
        "<results>/sv/phenosv_results/{batch}.sv_score.tsv",
    log:
        "<logs>/{batch}/score_with_phenosv.log",
    conda:
        f"{config["pathvars"]["phenosv_dir"]}/phenosv.yml"
    params:
        genome="hg38",
        inference="full",
        inference_mode="tad",
        model="PhenoSV-light",
        target_folder=subpath(output, parent=True),
        hpo="HP:0001300",
    shell:
        """
        python {params.phenosv_dir}/model/phenosv.py \
            --genome {params.genome} \
            --inference {params.inference} \
            --noncoding {params.inference_mode} \
            --model {params.model} \
            --HPO {params.hpo} \
            --sv_file {input.bed} \
            --target_folder {params.output_dir} \
            --target_file_name {output} \
            2>{log}
        """
