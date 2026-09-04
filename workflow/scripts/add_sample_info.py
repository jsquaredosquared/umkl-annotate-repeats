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
            "GP2ID",
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
        pl.col("REPCN").struct["ALLELE_1"].cast(int),
        pl.col("REPCN").struct["ALLELE_2"].cast(int),
    )
    .with_columns(
        STATUS_2=pl.when(
            pl.max_horizontal("ALLELE_1", "ALLELE_2") >= pl.col("STR_PATHOLOGIC_MIN")
        )
        .then(pl.lit("full_mutation"))
        .otherwise(
            pl.when(
                pl.max_horizontal("ALLELE_1", "ALLELE_2") <= pl.col("STR_NORMAL_MAX")
            )
            .then(pl.lit("normal"))
            .otherwise(pl.lit("pre_mutation"))
        )
    )
)


str_data_with_phenotypes.select(
    [
        "SAMPLE",
        "GP2ID",
        "FID",
        "GP2_PHENO",
        "REPID",
        "DISEASE",
        pl.col("STATUS").alias("STATUS_stranger"),
        pl.col("STATUS_2").alias("STATUS_manual"),
        "ALLELE_1",
        "ALLELE_2",
        "STR_NORMAL_MAX",
        "STR_PATHOLOGIC_MIN",
    ]
).sort(by="SAMPLE").write_csv(snakemake.output[0], separator="\t")
