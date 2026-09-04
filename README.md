# DRAGEN STR VCF annotation

1. Provide the required paths in the `config/config.yaml` file.
2. Run the workflow from this directory. For example:

    - If you are on the HPC, run the following command:

        ```sh
        nohup snakemake --workflow-profile workflow/profiles/umhpc/ &
        ```

    - If you are on your own device, run the following command:

        ```sh
        snakemake -c 4 --sdm conda
        ```

The results of this workflow will be in a folder called results.
