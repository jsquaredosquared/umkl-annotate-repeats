configfile: "config/config.yaml"


import os

batch = os.path.basename(config["pathvars"]["samples_dir"])


rule all:
    input:
        f"<results>/{batch}.repeats.annotated.pathogenic.grouped.tsv",


rule annotate_str_vcf:
    input:
        multiext(
            "<samples_dir>/{sample}/{sample}.repeats.vcf",
            file=".gz",
            index=".gz.tbi",
        ),
        catalog=config["catalog"],
    output:
        temp("<results>/{batch}/{sample}/{sample}.repeats.annotated.vcf"),
    log:
        "<logs>/{batch}/annotate_str_vcf_{sample}.log",
    conda:
        "../envs/str_analysis.yaml"
    shell:
        "stranger -f {input.catalog} {input.file} > {output} 2> {log}"


rule filter_for_pathogenic_strs:
    input:
        "<results>/{batch}/{sample}/{sample}.repeats.annotated.vcf",
    output:
        "<results>/{batch}/{sample}/{sample}.repeats.annotated.pathogenic.vcf",
    log:
        "<logs>/{batch}/filter_for_pathogenic_strs_{sample}.log",
    conda:
        "../envs/str_analysis.yaml"
    shell:
        """
        vembrane filter "'Disease' in INFO" {input} >{output} 2>{log}
        """


rule convert_vcf_to_table:
    input:
        vcf="<results>/{batch}/{sample}/{sample}.repeats.annotated.pathogenic.vcf",
    output:
        tsv="<results>/{batch}/{sample}/{sample}.repeats.annotated.pathogenic.tsv",
    log:
        "<logs>/{batch}/convert_vcf_to_table_{sample}.log",
    conda:
        "../envs/str_analysis.yaml"
    script:
        "../scripts/convert_str_vcf_to_table.xsh"


rule combine_tables:
    input:
        collect(
            "<results>/{{batch}}/{SAMPLE}/{SAMPLE}.repeats.annotated.pathogenic.tsv",
            SAMPLE=os.listdir(config["pathvars"]["samples_dir"]),
        ),
    output:
        "<results>/{batch}.repeats.annotated.pathogenic.grouped.tsv",
    log:
        "<logs>/{batch}/combine_tables.log",
    conda:
        "../envs/str_analysis.yaml"
    script:
        "../scripts/combine_str_tables.py"
