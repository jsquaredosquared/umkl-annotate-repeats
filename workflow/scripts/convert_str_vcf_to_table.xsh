import polars as pl
from io import StringIO


sample_id = $(grep -m 1 "#CHROM" @(snakemake.input.vcf)).split("\t")[-1]

table = $(vembrane table \
            f"INFO['REPID'], INFO['Disease'], INFO['STR_STATUS'], FORMAT['REPCN']['{sample_id}'], INFO['STR_NORMAL_MAX'], INFO['STR_PATHOLOGIC_MIN']" \
            --header "REPID,DISEASE,STATUS,REPCN,STR_NORMAL_MAX,STR_PATHOLOGIC_MIN" \
            @(snakemake.input.vcf))

pl.read_csv(StringIO(table), separator="\t").sort("REPID").write_csv(snakemake.output.tsv, separator="\t")
