$XONSH_TRACEBACK_LOGFILE = snakemake.log[0]

# TODO: properly handle temp files.
echo @('\n'.join(snakemake.input.vcfs)) > /tmp/sample_file_list.txt

SURVIVOR merge /tmp/sample_file_list.txt 1000 1 1 1 0 50 /tmp/output.vcf

bcftools sort -o /tmp/output.vcf -O z @(snakemake.output.vcfgz)

tabix @(snakemake.output.index)


rm /tmp/sample_file_list.txt
rm /tmp/output.vcf
