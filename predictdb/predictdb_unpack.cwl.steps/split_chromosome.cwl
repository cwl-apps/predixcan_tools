cwlVersion: v1.1
class: CommandLineTool
label: Split Genotype by Chromosome
doc: |-
  Script to split a GTEx genotype file into multiple files by chromosome.
  From commandline, first argument is the genotype file, second is the
  prefix for the output files.  The suffix 'chrN.txt' will be added to the
  prefix provided, where N is the chromosome number.

  In splitting, script will only keep unambiguously stranded SNPs. I.e.,
  no INDELs and no SNPs with polymorphisms A->T and vice-versa, or C->G
  and vice-versa.

  The input file is expected to be a tab-delimited text file including a
  header row, where the header field is ID (for snp varID) and then a
  variable number of fields with the sample ID numbers.  The first column
  has the snp ID in the format of (chr_pos_refAll_effAll_build) and the
  dosages are encoded on a 0-2 scale representing the number or imputed
  number of the effect alleles the sample possesses.
$namespaces:
  sbg: https://sevenbridges.com

requirements:
- class: ShellCommandRequirement
- class: DockerRequirement
  dockerPull: python:3.10.0a4-slim
- class: InitialWorkDirRequirement
  listing:
  - entryname: split_genotype_by_chr.py
    writable: false
    entry: |-
      #! /usr/bin/env python3

      import os
      import sys

      '''
      Script to split a GTEx genotype file into multiple files by chromosome.
      From commandline, first argument is the genotype file, second is the
      prefix for the output files.  The suffix 'chrN.txt' will be added to the
      prefix provided, where N is the chromosome number.
      In splitting, script will only keep unambiguously stranded SNPs. I.e.,
      no INDELs and no SNPs with polymorphisms A->T and vice-versa, or C->G
      and vice-versa.
      The input file is expected to be a tab-delimited text file including a
      header row, where the header field is ID (for snp varID) and then a
      variable number of fields with the sample ID numbers.  The first column
      has the snp ID in the format of (chr_pos_refAll_effAll_build) and the
      dosages are encoded on a 0-2 scale representing the number or imputed
      number of the effect alleles the sample posseses.
      '''

      SNP_COMPLEMENT = {'A':'T', 'C':'G', 'G':'C', 'T':'A'}

      def split_genotype(geno_file, out_prefix):
          # Make output file names from prefix.
          geno_by_chr_fns = [out_prefix + '.chr' + str(i) + '.txt' for i in range(1,23)]
          # Open connection to each output file.
          geno_by_chr = [open(f, 'w') for f in geno_by_chr_fns]

          with open(geno_file, 'r') as geno:
              # Write header in each file
              header = geno.readline()
              snps = set()
              for f in geno_by_chr:
                  f.write(header)

              for line in geno:
                  # First attribute of line is is chr_pos_refAllele_effAllele_build
                  # Extract this attribute and parse into list
                  varID_list = (line.split()[0].split('_'))
                  chr = varID_list[0]
                  refAllele = varID_list[2]
                  effectAllele = varID_list[3]
                  # Skip non_single letter polymorphisms
                  if len(refAllele) > 1 or len(effectAllele) > 1:
                      continue
                  # Skip ambiguous strands
                  if SNP_COMPLEMENT[refAllele] == effectAllele:
                      continue
                  varID = '_'.join(varID_list)
                  # Some snps have 2 rows for some reason. Attributes are nearly
                  # identical. Only keep the first one found.
                  if varID in snps:
                      continue
                  snps.add(varID)
                  # Write line to appropriate file
                  index = int(chr) - 1
                  geno_by_chr[index].write(line)

          for f in geno_by_chr:
              f.close()

      if __name__ == '__main__':
          genotype_file = sys.argv[1]
          out_prefix = sys.argv[2]
          split_genotype(genotype_file, out_prefix)
- class: InlineJavascriptRequirement
  expressionLib:
  - |2-

    var setMetadata = function(file, metadata) {
        if (!('metadata' in file)) {
            file['metadata'] = {}
        }
        for (var key in metadata) {
            file['metadata'][key] = metadata[key];
        }
        return file
    };
    var inheritMetadata = function(o1, o2) {
        var commonMetadata = {};
        if (!o2) {
            return o1;
        };
        if (!Array.isArray(o2)) {
            o2 = [o2]
        }
        for (var i = 0; i < o2.length; i++) {
            var example = o2[i]['metadata'];
            for (var key in example) {
                if (i == 0)
                    commonMetadata[key] = example[key];
                else {
                    if (!(commonMetadata[key] == example[key])) {
                        delete commonMetadata[key]
                    }
                }
            }
            for (var key in commonMetadata) {
                if (!(key in example)) {
                    delete commonMetadata[key]
                }
            }
        }
        if (!Array.isArray(o1)) {
            o1 = setMetadata(o1, commonMetadata)
            if (o1.secondaryFiles) {
                o1.secondaryFiles = inheritMetadata(o1.secondaryFiles, o2)
            }
        } else {
            for (var i = 0; i < o1.length; i++) {
                o1[i] = setMetadata(o1[i], commonMetadata)
                if (o1[i].secondaryFiles) {
                    o1[i].secondaryFiles = inheritMetadata(o1[i].secondaryFiles, o2)
                }
            }
        }
        return o1;
    };

inputs:
- id: genotype_file
  doc: |-
    Input file is expected to be a tab-delimited text file including a
    header row, where the header field is ID (for snp varID) and then a
    variable number of fields with the sample ID numbers.  The first column
    has the snp ID in the format of (chr_pos_refAll_effAll_build) and the
    dosages are encoded on a 0-2 scale representing the number or imputed
    number of the effect alleles the sample possesses.
  type: File
  inputBinding:
    position: 1
    shellQuote: false
- id: out_prefix
  doc: |-
    String appended to out put files. The suffix 'chrN.txt' will be added
    to the prefix provided, where N is the chromosome number.
  type: string
  inputBinding:
    position: 2
    shellQuote: false

outputs:
- id: geno_split_by_chr_files
  type: File[]
  outputBinding:
    glob: '*.txt'
    outputEval: $(inheritMetadata(self, inputs.text_file_input))

baseCommand:
- python split_genotype_by_chr.py

hints:
- class: sbg:SaveLogs
  value: '*.py'
id: rk.johnson/predictdb/split-chromosome/14
sbg:appVersion:
- v1.1
sbg:content_hash: a4028e06034916fcea0a56bde1b41e03949812bb51c9718a4d3bb2e2c93b298b1
sbg:contributors:
- e.esquinca
- dave
sbg:createdBy: e.esquinca
sbg:createdOn: 1608313025
sbg:id: rk.johnson/predictdb/split-chromosome/14
sbg:image_url:
sbg:latestRevision: 14
sbg:modifiedBy: e.esquinca
sbg:modifiedOn: 1611000955
sbg:project: rk.johnson/predictdb
sbg:projectName: predictdb
sbg:publisher: sbg
sbg:revision: 14
sbg:revisionNotes: ''
sbg:revisionsInfo:
- sbg:modifiedBy: e.esquinca
  sbg:modifiedOn: 1608313025
  sbg:revision: 0
  sbg:revisionNotes:
- sbg:modifiedBy: e.esquinca
  sbg:modifiedOn: 1608313253
  sbg:revision: 1
  sbg:revisionNotes: ''
- sbg:modifiedBy: dave
  sbg:modifiedOn: 1610122612
  sbg:revision: 2
  sbg:revisionNotes: added input output ports
- sbg:modifiedBy: dave
  sbg:modifiedOn: 1610122648
  sbg:revision: 3
  sbg:revisionNotes: ''
- sbg:modifiedBy: dave
  sbg:modifiedOn: 1610123685
  sbg:revision: 4
  sbg:revisionNotes: added sed
- sbg:modifiedBy: dave
  sbg:modifiedOn: 1610123960
  sbg:revision: 5
  sbg:revisionNotes: sed 's/Id/varID/g'
- sbg:modifiedBy: dave
  sbg:modifiedOn: 1610124281
  sbg:revision: 6
  sbg:revisionNotes: '> added'
- sbg:modifiedBy: dave
  sbg:modifiedOn: 1610124422
  sbg:revision: 7
  sbg:revisionNotes: python:3.10.0a4-slim
- sbg:modifiedBy: dave
  sbg:modifiedOn: 1610125209
  sbg:revision: 8
  sbg:revisionNotes: removed sed
- sbg:modifiedBy: e.esquinca
  sbg:modifiedOn: 1610151487
  sbg:revision: 9
  sbg:revisionNotes: ''
- sbg:modifiedBy: e.esquinca
  sbg:modifiedOn: 1610153190
  sbg:revision: 10
  sbg:revisionNotes: update name
- sbg:modifiedBy: e.esquinca
  sbg:modifiedOn: 1610154527
  sbg:revision: 11
  sbg:revisionNotes: ''
- sbg:modifiedBy: e.esquinca
  sbg:modifiedOn: 1610155359
  sbg:revision: 12
  sbg:revisionNotes: ''
- sbg:modifiedBy: e.esquinca
  sbg:modifiedOn: 1610392664
  sbg:revision: 13
  sbg:revisionNotes: ''
- sbg:modifiedBy: e.esquinca
  sbg:modifiedOn: 1611000955
  sbg:revision: 14
  sbg:revisionNotes: ''
sbg:sbgMaintained: false
sbg:validationErrors: []
