$XONSH_TRACEBACK_LOGFILE = snakemake.log[0]

# TODO: properly handle temp files.

with open("/tmp/sample_file_list.txt", "w") as samples:
  samples.write("\n".join(snakemake.input.vcfs))

SURVIVOR merge /tmp/sample_file_list.txt 1000 1 1 1 0 50 /tmp/output.vcf

bcftools sort -o @(snakemake.output.vcfgz) -O z /tmp/output.vcf 

tabix @(snakemake.output.vcfgz)

rm /tmp/sample_file_list.txt
rm /tmp/output.vcf
