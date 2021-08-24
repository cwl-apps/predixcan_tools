cwlVersion: v1.1
class: CommandLineTool
label: Split SNP Annot By Chromosome
doc: |-
  Script to split a SNP annotation file into multiple files by chromosome.
  From commandline, first argument is the snp annotation file, second is
  the prefix for the output files.  The suffix 'chrN.txt' will be added
  to the prefix provided, where N is the chromosome number.
  In splitting, script will only keep unambiguously stranded SNPs. I.e.,
  no INDELs and no SNPs with polymorphisms A->T and vice-versa, or C->G
  and vice-versa.

  Input snp annotation file is expected to be a tab-delimited text file,
  with a header row, with fields for chromosome, position, variantID,
  reference allele, alternative allele, rsid_label1, rsid_label2, and 
  number of alternative alleles per site. See file
  GTEx_Analysis_v6_OMNI_genot_1KG_imputed_var_chr1to22_info4_maf01_CR95_CHR_POSb37_ID_REF_ALT.txt.gz
  from gtexportal.org for an example of such a file.

  The output files will be tab-delimited text files with chromosome,
  position, variantID, reference allele, effect allele, and rsid.
  NOTE: the rsid number chosen is from rsidlabel2.
$namespaces:
  sbg: https://sevenbridges.com

requirements:
- class: ShellCommandRequirement
- class: DockerRequirement
  dockerPull: python:3.10.0a4-slim
- class: InitialWorkDirRequirement
  listing:
  - entryname: split_snp_annot_by_chr.py
    writable: false
    entry: |-
      #! /usr/bin/env python3

      import sys

      '''
      Script to split a SNP annotation file into multiple files by chromosome.
      From commandline, first argument is the snp annotation file, second is
      the prefix for the output files.  The suffix 'chrN.txt' will be added
      to the prefix provided, where N is the chromosome number.
      In splitting, script will only keep unambiguously stranded SNPs. I.e.,
      no INDELs and no SNPs with polymorphisms A->T and vice-versa, or C->G
      and vice-versa.
      Input snp annotation file is expected to be a tab-delimited text file,
      with a header row, with fields for chromosome, position, variantID,
      reference allele, alternative allele, rsid_label1, rsid_label2, and 
      number of alternative alleles per site. See file
      GTEx_Analysis_v6_OMNI_genot_1KG_imputed_var_chr1to22_info4_maf01_CR95_CHR_POSb37_ID_REF_ALT.txt.gz
      from gtexportal.org for an example of such a file.
      The output files will be tab-delimited text files with chromosome,
      position, variantID, reference allele, effect allele, and rsid.
      NOTE: the rsid number chosen is from rsidlabel2.
      '''

      SNP_COMPLEMENT = {'A':'T', 'C':'G', 'G':'C', 'T':'A'}
      HEADER_FIELDS = ['chr','pos','varID','ref_vcf','alt_vcf','rsid']

      def split_snp_annot(annot_file, out_prefix):
          # Make output file names from prefix.
          snps_by_chr_files= [out_prefix + '.chr' + str(i) + '.txt' for i in range(1,23)]
          # Open connection to each output file
          snp_by_chr = [open(f, 'w') for f in snps_by_chr_files]
          # Write header in each file.
          header = '\t'.join(HEADER_FIELDS)+'\n'
          for f in snp_by_chr:
              f.write(header)
          with open(annot_file, 'r') as ann:
              # Skip header from input file
              ann.readline()
              # Extract rows from input and write to body in appropriate output.
              for line in ann:
                  attrs = line.split()
                  chr = attrs[0]
                  pos = attrs[1]
                  varID = attrs[2]
                  refAllele = attrs[3]
                  effectAllele = attrs[4]
                  rsid = attrs[5]
                  # Skip non-single letter polymorphisms
                  if len(refAllele) > 1 or len(effectAllele) > 1:
                      continue
                  # Skip ambiguous strands
                  if SNP_COMPLEMENT[refAllele] == effectAllele:
                      continue
                  if rsid == '.':
                      continue
                  index = int(chr) - 1
                  row = '\t'.join([chr,pos,varID,refAllele,effectAllele,rsid])+'\n'
                  snp_by_chr[index].write(row)
          # Close connection to each output file.
          for f in snp_by_chr:
              f.close()

      if __name__ == '__main__':
          annot_file = sys.argv[1]
          out_prefix = sys.argv[2]
          split_snp_annot(annot_file, out_prefix)

inputs:
- id: snp_annotation
  doc: |-
    Input snp annotation file is expected to be a tab-delimited text file,
    with a header row, with fields for chromosome, position, variantID,
    reference allele, alternative allele, rsid_label1, rsid_label2, and 
    number of alternative alleles per site.
  type: File
  inputBinding:
    position: 1
    shellQuote: false
- id: output_prefrix
  doc: |-
    The suffix 'chrN.txt' will be added
    to the prefix provided, where N is the chromosome number
  type: string
  inputBinding:
    position: 2
    shellQuote: false

outputs:
- id: snp_annot_split_by_chr_files
  doc: |-
    The output files will be tab-delimited text files with chromosome,
    position, variantID, reference allele, effect allele, and rsid.
    NOTE: the rsid number chosen is from rsidlabel2.
  type: File[]
  outputBinding:
    glob: '*.txt'

baseCommand:
- python split_snp_annot_by_chr.py

hints:
- class: sbg:SaveLogs
  value: '*.py'
id: rk.johnson/predictdb/split-snp-annot-by-chromosome/12
sbg:appVersion:
- v1.1
sbg:content_hash: af4ad9b477a5714209b27c4c225acbecd68a56758d640c0f02fa22ff60cdb544b
sbg:contributors:
- e.esquinca
sbg:createdBy: e.esquinca
sbg:createdOn: 1610154582
sbg:id: rk.johnson/predictdb/split-snp-annot-by-chromosome/12
sbg:image_url:
sbg:latestRevision: 12
sbg:modifiedBy: e.esquinca
sbg:modifiedOn: 1612209538
sbg:project: rk.johnson/predictdb
sbg:projectName: predictdb
sbg:publisher: sbg
sbg:revision: 12
sbg:revisionNotes: changed back to 5
sbg:revisionsInfo:
- sbg:modifiedBy: e.esquinca
  sbg:modifiedOn: 1610154582
  sbg:revision: 0
  sbg:revisionNotes:
- sbg:modifiedBy: e.esquinca
  sbg:modifiedOn: 1610155165
  sbg:revision: 1
  sbg:revisionNotes: ''
- sbg:modifiedBy: e.esquinca
  sbg:modifiedOn: 1610999467
  sbg:revision: 2
  sbg:revisionNotes: ''
- sbg:modifiedBy: e.esquinca
  sbg:modifiedOn: 1611004492
  sbg:revision: 3
  sbg:revisionNotes: update for our data
- sbg:modifiedBy: e.esquinca
  sbg:modifiedOn: 1611341601
  sbg:revision: 4
  sbg:revisionNotes: ''
- sbg:modifiedBy: e.esquinca
  sbg:modifiedOn: 1611344004
  sbg:revision: 5
  sbg:revisionNotes: ''
- sbg:modifiedBy: e.esquinca
  sbg:modifiedOn: 1611601137
  sbg:revision: 6
  sbg:revisionNotes: ''
- sbg:modifiedBy: e.esquinca
  sbg:modifiedOn: 1611601532
  sbg:revision: 7
  sbg:revisionNotes: match names
- sbg:modifiedBy: e.esquinca
  sbg:modifiedOn: 1611851797
  sbg:revision: 8
  sbg:revisionNotes: saved 5 for tutorial data run
- sbg:modifiedBy: e.esquinca
  sbg:modifiedOn: 1611852471
  sbg:revision: 9
  sbg:revisionNotes: ''
- sbg:modifiedBy: e.esquinca
  sbg:modifiedOn: 1612206342
  sbg:revision: 10
  sbg:revisionNotes: rsID -> rsid
- sbg:modifiedBy: e.esquinca
  sbg:modifiedOn: 1612206826
  sbg:revision: 11
  sbg:revisionNotes: needed to rerun tutorial data changed from 5 to 6
- sbg:modifiedBy: e.esquinca
  sbg:modifiedOn: 1612209538
  sbg:revision: 12
  sbg:revisionNotes: changed back to 5
sbg:sbgMaintained: false
sbg:validationErrors: []
