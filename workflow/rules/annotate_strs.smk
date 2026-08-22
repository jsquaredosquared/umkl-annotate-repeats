configfile: "config/config.yaml"


import os

group = os.path.basename(config["pathvars"]["samples_dir"])


rule all:
    input:
        f"<results>/{group}.repeats.annotated.pathogenic.tsv",


rule annotate_str_vcf:
    input:
        multiext(
            "<samples_dir>/{sample}/{sample}.repeats.vcf", file=".gz", index=".gz.tbi"
        ),
        catalog=config["catalog"],
    output:
        temp("<results>/{sample}.repeats.annotated.vcf"),
    log:
        "<logs>/annotate_str_vcf_{sample}.log",
    conda:
        "../envs/str_analysis.yaml"
    shell:
        "stranger -f {input.catalog} {input.file} > {output} 2> {log}"


rule filter_for_pathogenic_strs:
    input:
        "<results>/{sample}.repeats.annotated.vcf",
    output:
        "<results>/{sample}.repeats.annotated.pathogenic.vcf",
    log:
        "<logs>/filter_for_pathogenic_strs_{sample}.log",
    conda:
        "../envs/str_analysis.yaml"
    shell:
        """
        vembrane filter "'Disease' in INFO" {input} >{output} 2>{log}
        """


rule convert_vcf_to_table:
    input:
        vcf="<results>/{sample}.repeats.annotated.pathogenic.vcf",
    output:
        tsv="<results>/{sample}.repeats.annotated.pathogenic.tsv",
    log:
        "<logs>/convert_vcf_to_table_{sample}.log",
    conda:
        "../envs/str_analysis.yaml"
    script:
        "../scripts/convert_str_vcf_to_table.xsh"


rule combine_tables:
    input:
        collect(
            "<results>/{SAMPLE}.repeats.annotated.pathogenic.tsv",
            SAMPLE=os.listdir(config["pathvars"]["samples_dir"]),
        ),
    output:
        f"<results>/{group}.repeats.annotated.pathogenic.tsv",
    log:
        "<logs>/combine_tables.log",
    conda:
        "../envs/str_analysis.yaml"
    script:
        "../scripts/combine_str_tables.py"
