import polars as pl


dataframes = [pl.read_csv(table, separator="\t") for table in snakemake.input]

pl.concat(dataframes).write_csv(snakemake.output[0], separator="\t")
