import marimo

__generated_with = "0.24.0"
app = marimo.App(width="medium")


@app.cell
def _():
    import marimo as mo
    import polars as pl

    return mo, pl


@app.cell(hide_code=True)
def _(mo):
    mo.md(r"""
    ## Load data and master key
    """)
    return


@app.cell
def _(pl, snakemake):
    master_key = pl.read_csv(
        snakemake.input.master_key,
        separator="\t",
        infer_schema_length=10000,
    )
    return (master_key,)


@app.cell
def _(pl, snakemake):
    umkl_str_data = pl.read_csv(
        snakemake.input.annotations_table,
        separator="\t",
    )
    umkl_str_data.sort(by="SAMPLE")
    return (umkl_str_data,)


@app.cell
def _(master_key, pl, umkl_str_data):
    master_key_with_sample_id = master_key.with_columns(
        SAMPLE=pl.when(pl.col("GP2ID").is_in(umkl_str_data["SAMPLE"].implode()))
        .then(pl.col("GP2ID"))
        .otherwise(
            pl.when(pl.col("alternative_id1").is_in(umkl_str_data["SAMPLE"].implode()))
            .then(pl.col("alternative_id1"))
            .otherwise(None)
        )
    )
    return (master_key_with_sample_id,)


@app.cell
def _(master_key_with_sample_id, pl, umkl_str_data):
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
    return (str_data_with_phenotypes,)


@app.cell
def _(snakemake, str_data_with_phenotypes):
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
    ).sort(by="SAMPLE").write_csv(snakemake.output)
    return


if __name__ == "__main__":
    app.run()
