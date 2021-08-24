cwlVersion: v1.2
class: Workflow
label: Predictdb_Split_by_Chromsome
$namespaces:
  sbg: https://sevenbridges.com

requirements:
- class: ScatterFeatureRequirement
- class: InlineJavascriptRequirement
- class: StepInputExpressionRequirement

inputs:
- id: Omics_Data_File
  label: Omics Data File
  doc: |-
    A tab delimited file with .tab file extension containing N + 1 rows and G + 1 columns, where N is the number of samples, and G is the number of features (genes, methylation sites, chromatin accessibility windows, etc.). The first row and column must contain sample IDs and feature IDs respectively. Feature values should be normalized across samples and variance stabilized.
  type: File
  sbg:x: -632.8408813476562
  sbg:y: 266.8882141113281
- id: genotype_file
  doc: |-
    Input file is expected to be a tab-delimited text file including a
    header row, where the header field is ID (for snp varID) and then a
    variable number of fields with the sample ID numbers.  The first column
    has the snp ID in the format of (chr_pos_refAll_effAll_build) and the
    dosages are encoded on a 0-2 scale representing the number or imputed
    number of the effect alleles the sample possesses.
  type: File
  sbg:x: -367.69915771484375
  sbg:y: -222.9619140625
- id: snp_annotation
  doc: |-
    Input snp annotation file is expected to be a tab-delimited text file,
    with a header row, with fields for chromosome, position, variantID,
    reference allele, alternative allele, rsid_label1, rsid_label2, and 
    number of alternative alleles per site.
  type: File
  sbg:x: -230.09579467773438
  sbg:y: -412.2391052246094
- id: gene_annotation
  type: File
  sbg:x: 33.34193420410156
  sbg:y: -73.43011474609375
- id: Hidden_Factors
  label: NUM_FACTORS
  doc: |-
    Number of hidden factors to estimate. PEER uses automatic relevance determination to choose a suitable effective number of factors, so this parameter needs only to be set to a sufficiently large value. Without prior information available, a general recommendation is to use 25% of the number of samples but no more than 100 factors.
  type: int
  sbg:exposed: true
- id: Output_File_Prefix
  label: Output File Prefrix
  doc: File name prefix for output files.
  type: string
  sbg:x: -727.713134765625
  sbg:y: -129.49014282226562
- id: Covariates
  label: Covariate_Data
  doc: |-
    --Covariates_File

    [REQUIRED]: A tab delimited file with a .tab file extension containing a matrix of size M + 1 × K + 1, where M >= N and is the number of samples for which covariate data is provided. .
  type: File?
  sbg:x: -180.50250244140625
  sbg:y: 305.5856628417969
- id: tissue_name
  type: string
  sbg:x: 346.3424987792969
  sbg:y: -463.78082275390625
- id: population_name
  type: string
  sbg:x: 327.73529052734375
  sbg:y: 177.88607788085938
- id: chr_list
  doc: |-
    Enter the chromosome number for which you want to perform the nested elastic models for every gene in that desired chromosome. Please enter at least 1 chromosome and each chromosome will be in its own line.
  type: string[]
  sbg:exposed: true
- id: model_prefix
  doc: |-
    This prefix will be added to the beginning of all the summary, covariance, and weights files produced.
  type: string?
  sbg:exposed: true
- id: seed
  type: int?
  sbg:exposed: true
- id: RAM
  doc: In  MB
  type: int?
  sbg:exposed: true

outputs:
- id: weights
  type: File[]?
  outputSource:
  - model_bulding/weights
  sbg:x: 720.01806640625
  sbg:y: -386.60723876953125
- id: summary
  type: File[]?
  outputSource:
  - model_bulding/summary
  sbg:x: 771.1414184570312
  sbg:y: -1.123328447341919
- id: covariances
  type: File[]?
  outputSource:
  - model_bulding/covariances
  sbg:x: 762.0408325195312
  sbg:y: 193.58444213867188
- id: db_output
  type: File[]?
  outputSource:
  - database_summary/db_output
  sbg:x: 1056.5301513671875
  sbg:y: -189.76544189453125

steps:
- id: peer
  label: peer
  in:
  - id: Omics_Data_File
    source: Omics_Data_File
  - id: Output_File_Prefix
    source: Output_File_Prefix
  - id: Hidden_Factors
    source: Hidden_Factors
  run: predictdb_unpack.cwl.steps/peer.cwl
  out:
  - id: std_out
  - id: peer_covariates
  - id: peer_weights
  - id: peer_precisions
  - id: peer_residuals
  sbg:x: -185.70863342285156
  sbg:y: 21.889673233032227
- id: split_snp_annot_by_chromosome
  label: Split SNP Annot By Chromosome
  in:
  - id: snp_annotation
    source: snp_annotation
  - id: output_prefrix
    default: snp_annot
  run: predictdb_unpack.cwl.steps/split_snp_annot_by_chromosome.cwl
  out:
  - id: snp_annot_split_by_chr_files
  sbg:x: 73.9994888305664
  sbg:y: -381.50750732421875
- id: split_chromosome
  label: Split Genotype by Chromosome
  in:
  - id: genotype_file
    source: genotype_file
  - id: out_prefix
    default: genotype
  run: predictdb_unpack.cwl.steps/split_chromosome.cwl
  out:
  - id: geno_split_by_chr_files
  sbg:x: -57.45125961303711
  sbg:y: -223.16526794433594
- id: mlr
  label: MLR
  in:
  - id: Peer_Covariates
    source: peer/peer_covariates
  - id: Covariates
    source: Covariates
  - id: Omic_Data
    source: Omics_Data_File
  - id: Output_Prefix
    source: Output_File_Prefix
  run: predictdb_unpack.cwl.steps/mlr.cwl
  out:
  - id: Adjusted_Omics_Residuals
  sbg:x: 126.4817123413086
  sbg:y: 115.21794891357422
- id: model_bulding
  label: Elastic Models
  in:
  - id: population_name
    source: population_name
  - id: tissue_name
    source: tissue_name
  - id: gene_annotation
    source: gene_annotation
  - id: snp_annotation
    source:
    - split_snp_annot_by_chromosome/snp_annot_split_by_chr_files
  - id: genotype_file
    source:
    - split_chromosome/geno_split_by_chr_files
  - id: adjusted_expression_file
    source: mlr/Adjusted_Omics_Residuals
  - id: chr_list
    source:
    - chr_list
  - id: model_prefix
    source: model_prefix
  - id: seed
    source: seed
  - id: RAM
    source: RAM
  scatter:
  - chr_list
  run: predictdb_unpack.cwl.steps/model_bulding.cwl
  out:
  - id: weights
  - id: covariances
  - id: summary
  sbg:x: 464.46112060546875
  sbg:y: -121.70777893066406
- id: database_summary
  label: Database_Summary
  in:
  - id: population_name
    source: population_name
  - id: tissue_name
    source: tissue_name
  - id: summary
    source:
    - model_bulding/summary
  - id: covariances
    source:
    - model_bulding/covariances
  - id: weights
    source:
    - model_bulding/weights
  run: predictdb_unpack.cwl.steps/database_summary.cwl
  out:
  - id: db_output
  sbg:x: 844.292236328125
  sbg:y: -175.3652801513672
sbg:appVersion:
- v1.2
- v1.1
sbg:content_hash: a8a254bb5dc8b0ef3ef1c8c43219dd5e77425a2c6251cb4f1ec9b7e463e06d821
sbg:contributors:
- e.esquinca
sbg:createdBy: e.esquinca
sbg:createdOn: 1613684057
sbg:id: rk.johnson/predictdb/predictdb-split-by-chromsome/55
sbg:image_url: |-
  https://platform.sb.biodatacatalyst.nhlbi.nih.gov/ns/brood/images/rk.johnson/predictdb/predictdb-split-by-chromsome/55.png
sbg:latestRevision: 55
sbg:modifiedBy: e.esquinca
sbg:modifiedOn: 1628791571
sbg:original_source: |-
  https://api.sb.biodatacatalyst.nhlbi.nih.gov/v2/apps/rk.johnson/predictdb/predictdb-split-by-chromsome/55/raw/
sbg:project: rk.johnson/predictdb
sbg:projectName: predictdb
sbg:publisher: sbg
sbg:revision: 55
sbg:revisionNotes: added more descriptions
sbg:revisionsInfo:
- sbg:modifiedBy: e.esquinca
  sbg:modifiedOn: 1613684057
  sbg:revision: 0
  sbg:revisionNotes:
- sbg:modifiedBy: e.esquinca
  sbg:modifiedOn: 1613685221
  sbg:revision: 1
  sbg:revisionNotes: ''
- sbg:modifiedBy: e.esquinca
  sbg:modifiedOn: 1613685563
  sbg:revision: 2
  sbg:revisionNotes: connected ports
- sbg:modifiedBy: e.esquinca
  sbg:modifiedOn: 1613685651
  sbg:revision: 3
  sbg:revisionNotes: expose ports
- sbg:modifiedBy: e.esquinca
  sbg:modifiedOn: 1613685848
  sbg:revision: 4
  sbg:revisionNotes: set default out_put prefixes from snp_annot and genotype
- sbg:modifiedBy: e.esquinca
  sbg:modifiedOn: 1613687599
  sbg:revision: 5
  sbg:revisionNotes: ''
- sbg:modifiedBy: e.esquinca
  sbg:modifiedOn: 1613687739
  sbg:revision: 6
  sbg:revisionNotes: add covariate descriptionl
- sbg:modifiedBy: e.esquinca
  sbg:modifiedOn: 1613688848
  sbg:revision: 7
  sbg:revisionNotes: ''
- sbg:modifiedBy: e.esquinca
  sbg:modifiedOn: 1613689076
  sbg:revision: 8
  sbg:revisionNotes: ''
- sbg:modifiedBy: e.esquinca
  sbg:modifiedOn: 1613761206
  sbg:revision: 9
  sbg:revisionNotes: ''
- sbg:modifiedBy: e.esquinca
  sbg:modifiedOn: 1613884302
  sbg:revision: 10
  sbg:revisionNotes: ''
- sbg:modifiedBy: e.esquinca
  sbg:modifiedOn: 1614021511
  sbg:revision: 11
  sbg:revisionNotes: ''
- sbg:modifiedBy: e.esquinca
  sbg:modifiedOn: 1614040976
  sbg:revision: 12
  sbg:revisionNotes: updated tool with fixed seed for comparison
- sbg:modifiedBy: e.esquinca
  sbg:modifiedOn: 1614042687
  sbg:revision: 13
  sbg:revisionNotes: same edit as last time
- sbg:modifiedBy: e.esquinca
  sbg:modifiedOn: 1614101239
  sbg:revision: 14
  sbg:revisionNotes: ''
- sbg:modifiedBy: e.esquinca
  sbg:modifiedOn: 1614110017
  sbg:revision: 15
  sbg:revisionNotes: ''
- sbg:modifiedBy: e.esquinca
  sbg:modifiedOn: 1614111578
  sbg:revision: 16
  sbg:revisionNotes: ''
- sbg:modifiedBy: e.esquinca
  sbg:modifiedOn: 1614187925
  sbg:revision: 17
  sbg:revisionNotes: ''
- sbg:modifiedBy: e.esquinca
  sbg:modifiedOn: 1614188702
  sbg:revision: 18
  sbg:revisionNotes: ''
- sbg:modifiedBy: e.esquinca
  sbg:modifiedOn: 1614188739
  sbg:revision: 19
  sbg:revisionNotes: ''
- sbg:modifiedBy: e.esquinca
  sbg:modifiedOn: 1614189650
  sbg:revision: 20
  sbg:revisionNotes: ''
- sbg:modifiedBy: e.esquinca
  sbg:modifiedOn: 1614190571
  sbg:revision: 21
  sbg:revisionNotes: ''
- sbg:modifiedBy: e.esquinca
  sbg:modifiedOn: 1614192989
  sbg:revision: 22
  sbg:revisionNotes: ''
- sbg:modifiedBy: e.esquinca
  sbg:modifiedOn: 1614194114
  sbg:revision: 23
  sbg:revisionNotes: ''
- sbg:modifiedBy: e.esquinca
  sbg:modifiedOn: 1614194828
  sbg:revision: 24
  sbg:revisionNotes: ''
- sbg:modifiedBy: e.esquinca
  sbg:modifiedOn: 1614195244
  sbg:revision: 25
  sbg:revisionNotes: ''
- sbg:modifiedBy: e.esquinca
  sbg:modifiedOn: 1614195724
  sbg:revision: 26
  sbg:revisionNotes: ''
- sbg:modifiedBy: e.esquinca
  sbg:modifiedOn: 1614264981
  sbg:revision: 27
  sbg:revisionNotes: ''
- sbg:modifiedBy: e.esquinca
  sbg:modifiedOn: 1614279787
  sbg:revision: 28
  sbg:revisionNotes: ''
- sbg:modifiedBy: e.esquinca
  sbg:modifiedOn: 1614484872
  sbg:revision: 29
  sbg:revisionNotes: ''
- sbg:modifiedBy: e.esquinca
  sbg:modifiedOn: 1614489607
  sbg:revision: 30
  sbg:revisionNotes: ''
- sbg:modifiedBy: e.esquinca
  sbg:modifiedOn: 1614527442
  sbg:revision: 31
  sbg:revisionNotes: ''
- sbg:modifiedBy: e.esquinca
  sbg:modifiedOn: 1614705275
  sbg:revision: 32
  sbg:revisionNotes: ''
- sbg:modifiedBy: e.esquinca
  sbg:modifiedOn: 1614705391
  sbg:revision: 33
  sbg:revisionNotes: ''
- sbg:modifiedBy: e.esquinca
  sbg:modifiedOn: 1614799639
  sbg:revision: 34
  sbg:revisionNotes: ''
- sbg:modifiedBy: e.esquinca
  sbg:modifiedOn: 1614833310
  sbg:revision: 35
  sbg:revisionNotes: ''
- sbg:modifiedBy: e.esquinca
  sbg:modifiedOn: 1614833589
  sbg:revision: 36
  sbg:revisionNotes: ''
- sbg:modifiedBy: e.esquinca
  sbg:modifiedOn: 1617685150
  sbg:revision: 37
  sbg:revisionNotes: ''
- sbg:modifiedBy: e.esquinca
  sbg:modifiedOn: 1617821369
  sbg:revision: 38
  sbg:revisionNotes: ''
- sbg:modifiedBy: e.esquinca
  sbg:modifiedOn: 1617821402
  sbg:revision: 39
  sbg:revisionNotes: ''
- sbg:modifiedBy: e.esquinca
  sbg:modifiedOn: 1617821455
  sbg:revision: 40
  sbg:revisionNotes: ''
- sbg:modifiedBy: e.esquinca
  sbg:modifiedOn: 1617821801
  sbg:revision: 41
  sbg:revisionNotes: ''
- sbg:modifiedBy: e.esquinca
  sbg:modifiedOn: 1617834744
  sbg:revision: 42
  sbg:revisionNotes: ''
- sbg:modifiedBy: e.esquinca
  sbg:modifiedOn: 1618432399
  sbg:revision: 43
  sbg:revisionNotes: ''
- sbg:modifiedBy: e.esquinca
  sbg:modifiedOn: 1618631425
  sbg:revision: 44
  sbg:revisionNotes: deleted covariates file
- sbg:modifiedBy: e.esquinca
  sbg:modifiedOn: 1618663936
  sbg:revision: 45
  sbg:revisionNotes: ''
- sbg:modifiedBy: e.esquinca
  sbg:modifiedOn: 1618803141
  sbg:revision: 46
  sbg:revisionNotes: ''
- sbg:modifiedBy: e.esquinca
  sbg:modifiedOn: 1618810083
  sbg:revision: 47
  sbg:revisionNotes: ''
- sbg:modifiedBy: e.esquinca
  sbg:modifiedOn: 1618861397
  sbg:revision: 48
  sbg:revisionNotes: ''
- sbg:modifiedBy: e.esquinca
  sbg:modifiedOn: 1618874047
  sbg:revision: 49
  sbg:revisionNotes: ''
- sbg:modifiedBy: e.esquinca
  sbg:modifiedOn: 1619633125
  sbg:revision: 50
  sbg:revisionNotes: ''
- sbg:modifiedBy: e.esquinca
  sbg:modifiedOn: 1619647582
  sbg:revision: 51
  sbg:revisionNotes: ''
- sbg:modifiedBy: e.esquinca
  sbg:modifiedOn: 1622050998
  sbg:revision: 52
  sbg:revisionNotes: ''
- sbg:modifiedBy: e.esquinca
  sbg:modifiedOn: 1622131825
  sbg:revision: 53
  sbg:revisionNotes: ''
- sbg:modifiedBy: e.esquinca
  sbg:modifiedOn: 1628790975
  sbg:revision: 54
  sbg:revisionNotes: added more descriptions
- sbg:modifiedBy: e.esquinca
  sbg:modifiedOn: 1628791571
  sbg:revision: 55
  sbg:revisionNotes: added more descriptions
sbg:sbgMaintained: false
sbg:validationErrors: []
