import polars as pl

master_key = pl.read_csv(
    snakemake.input.master_key,
    separator="\t",
    infer_schema_length=10000,
)


umkl_str_data = pl.read_csv(
    snakemake.input.annotations_table,
    separator="\t",
)


master_key_with_sample_id = master_key.with_columns(
    SAMPLE=pl.when(pl.col("GP2ID").is_in(umkl_str_data["SAMPLE"].implode()))
    .then(pl.col("GP2ID"))
    .otherwise(
        pl.when(pl.col("alternative_id1").is_in(umkl_str_data["SAMPLE"].implode()))
        .then(pl.col("alternative_id1"))
        .otherwise(None)
    )
)


str_data_with_phenotypes = (
    umkl_str_data.join(
        master_key_with_sample_id.select(
            "SAMPLE",
            "FID",
            "GP2_PHENO",
        ),
        on="SAMPLE",
        how="left",
    )
    .with_columns(
        pl.col("REPCN")
        .str.extract_all(r"(\d+)")
        .list.to_struct(fields=["ALLELE_1", "ALLELE_2"])
    )
    .with_columns(
        pl.col("REPCN").struct["ALLELE_1"],
        pl.col("REPCN").struct["ALLELE_2"],
    )
)


str_data_with_phenotypes.select(
    [
        "SAMPLE",
        "FID",
        "GP2_PHENO",
        "REPID",
        "DISEASE",
        "STATUS",
        "ALLELE_1",
        "ALLELE_2",
        "STR_NORMAL_MAX",
        "STR_PATHOLOGIC_MIN",
    ]
).sort(by="SAMPLE").write_csv(snakemake.output[0], separator="\t")
