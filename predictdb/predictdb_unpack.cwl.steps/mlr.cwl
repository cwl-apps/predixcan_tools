cwlVersion: v1.1
class: CommandLineTool
label: MLR
$namespaces:
  sbg: https://sevenbridges.com

requirements:
- class: ShellCommandRequirement
- class: DockerRequirement
  dockerPull: r-base
- class: InitialWorkDirRequirement
  listing:
  - entryname: MLR.R
    writable: false
    entry: |-
      # R Script used for the Multiple Linear Regression


      # Script will loop through all the columns of the transposed gene expression which correspond to each 
      # gene and for each gene it runs linear regression on the PEER factors & covariates. Then
      # it sets the residuals to the new expression for that gene.


      # Install Dependencies
      install.packages("optparse")
      library(optparse, quietly = T)



      # Generate usage doc and retrieve command line arguments
      p <- OptionParser(usage = "\n%prog [options] --omic_file <omic_file> --covariates_data_file <covariates_data_file> --PEER_covariates <PEER_covariates> --output_prefix <output_prefix>",
                        description = "\nScript will loop through all the columns of the transposed gene expression which correspond to each 
                              gene and for each gene it runs linear regression on the PEER factors & seperate covariates file is entered. Then
                              it sets the residuals to the new expression for that gene",
                        prog = "Rscript MLR.R")

      p <- add_option(object = p, opt_str = c("--omic_file"), default = NULL, type = "character",
                      help = "[REQUIRED] A tab delimited file with .tab file extension containing N + 1 rows and G + 1 columns, where N is the number of samples, and G is the number of features (genes, methylation sites, chromatin accessibility windows, etc.). The first row and column must contain sample IDs and feature IDs respectively. Feature values should be normalized across samples and variance stabilized.")
      p <- add_option(object = p, opt_str = c("--covariates_file"), default = NULL, type = "character",
                      help = "A tab deliminated file with N+1 rows and K+1 columns, where N is the number of samples, and K is the desired covariates.")
      p <- add_option(object = p, opt_str = c("--PEER_covariates"), type = "character", default = NULL,
                      help = "[REQUIRED] PEER - Probabilistic Estimation of Expression Residuals obtained from PEER tool. Expected to be a tab deliminated file with N+1 by M+1, where N is the number of samples, and M the number of PEER factors ")
      p <- add_option(object = p, opt_str = c("--output_prefix"), default = NULL, type = "character",
                      help = "[REQUIRED] File name prefix for output files.")


      argv <- parse_args(p)


      # Check if positional arguments were given 
      if(is.null(argv$omic_file)){
        stop("Error: Please provide a value for --omic_file")
      }
      if(is.null(argv$PEER_covariates)){
        stop("Error: Please provide a value for --PEER_covariates")
      }
      if(is.null(argv$output_prefix)){
        stop("Error: Please provide a value for --output_prefix")
      }

      # Read in data
      gene.exp <- read.table(argv$omic_file, sep = "\t", header = T, 
                             check.names = F, comment.char = "", row.names = 1)

      peer.covariates <- read.table(argv$PEER_covariates, sep = "\t", header = T, 
                                 check.names = F, comment.char = "", row.names = 1)


      covar.data = NULL
      if(!is.null(argv$covariates_file)){
        covar.data <- read.table(argv$covariates_file, sep = "\t", header = T, 
                                 check.names = F, comment.char = "", row.names = 1)
      }


      # Make a copy of the gene.exp df and fill in with the residuals
      expression <- gene.exp


      # Run MLR


      # If covariate data entered, merge peer covariates file with extra covariates file
      # Then run the MLR

      if(!is.null(argv$covariates_file)){
        # Will merge by rownames
        merged.covar <- merge(peer.covariates, covar.data, by = 0)
        
        # Make first column rownames and get rid of extra first column
        rownames(merged.covar) <- merged.covar[,1]
        merged.covar <- merged.covar[,-1]
        
        # Run the MLR
        for (i in 1:length(colnames(gene.exp))) {
          fit <- lm(gene.exp[,i] ~ as.matrix(merged.covar))
          expression[,i] <- fit$residuals
        }
        
      }else{ 

        for (i in 1:length(colnames(gene.exp))) {
        fit <- lm(gene.exp[,i] ~ as.matrix(peer.covariates))
        expression[,i] <- fit$residuals
      }
      }
       


      # Write results
      write.table(expression, row.names = T, sep = "\t", col.names = T, file = paste0(argv$output_prefix, "_adjusted_omics_residuals.txt"))
               
          
                  

inputs:
- id: Peer_Covariates
  label: PEER_Covariates
  doc: |-
    --PEER_Covariates
    (Also known as PEER Factors)

    [REQUIRED]: PEER - Probabilistic Estimation of Expression Residuals obtained from PEER tool. Expected to be a tab delimited file with N+1 by M+1, where N is the number of samples, and M the number of PEER factors
  type: File
  inputBinding:
    prefix: --PEER_covariates
    position: 3
    shellQuote: false
- id: Covariates
  label: Covariate_Data
  doc: |-
    --Covariates_File

    [REQUIRED]: A tab delimited file with a .tab file extension containing a matrix of size M + 1 × K + 1, where M >= N and is the number of samples for which covariate data is provided. .
  type: File?
  inputBinding:
    prefix: --covariates_file
    position: 2
    shellQuote: false
- id: Omic_Data
  doc: |-
    --Omic_Data_File

    [REQUIRED] A tab delimited file with .tab file extension containing N + 1 rows and G + 1 columns, where N is the number of samples, and G is the number of features (genes, methylation sites, chromatin accessibility windows, etc.).
  type: File
  inputBinding:
    prefix: --omic_file
    position: 1
    shellQuote: false
- id: Output_Prefix
  doc: "--Output_Prefix\n\n[REQUIRED] File name prefix for output files."
  type: string
  inputBinding:
    prefix: --output_prefix
    position: 4
    shellQuote: false

outputs:
- id: Adjusted_Omics_Residuals
  doc: |-
    After the MLR is done on every column of the peer factors, the residuals will be store in the matrix of size m x n. The rows are the samples and the columns will be the residuals.
    These are the adjusted omics data residuals.
  type: File
  outputBinding:
    glob: '*residuals.txt'

baseCommand:
- Rscript MLR.R
id: rk.johnson/predictdb/mlr/37
sbg:appVersion:
- v1.1
sbg:content_hash: ac6dff55ea6f0a7e9332b7698514032bb6944d9b157ada845d603747d6012dade
sbg:contributors:
- e.esquinca
sbg:createdBy: e.esquinca
sbg:createdOn: 1607551910
sbg:id: rk.johnson/predictdb/mlr/37
sbg:image_url:
sbg:latestRevision: 37
sbg:modifiedBy: e.esquinca
sbg:modifiedOn: 1612853548
sbg:project: rk.johnson/predictdb
sbg:projectName: predictdb
sbg:publisher: sbg
sbg:revision: 37
sbg:revisionNotes: ''
sbg:revisionsInfo:
- sbg:modifiedBy: e.esquinca
  sbg:modifiedOn: 1607551910
  sbg:revision: 0
  sbg:revisionNotes:
- sbg:modifiedBy: e.esquinca
  sbg:modifiedOn: 1607552400
  sbg:revision: 1
  sbg:revisionNotes: ''
- sbg:modifiedBy: e.esquinca
  sbg:modifiedOn: 1607552562
  sbg:revision: 2
  sbg:revisionNotes: ''
- sbg:modifiedBy: e.esquinca
  sbg:modifiedOn: 1608318765
  sbg:revision: 3
  sbg:revisionNotes: ''
- sbg:modifiedBy: e.esquinca
  sbg:modifiedOn: 1608318898
  sbg:revision: 4
  sbg:revisionNotes: ''
- sbg:modifiedBy: e.esquinca
  sbg:modifiedOn: 1610153154
  sbg:revision: 5
  sbg:revisionNotes: ''
- sbg:modifiedBy: e.esquinca
  sbg:modifiedOn: 1610653560
  sbg:revision: 6
  sbg:revisionNotes: ''
- sbg:modifiedBy: e.esquinca
  sbg:modifiedOn: 1610653637
  sbg:revision: 7
  sbg:revisionNotes: ''
- sbg:modifiedBy: e.esquinca
  sbg:modifiedOn: 1610653786
  sbg:revision: 8
  sbg:revisionNotes: ''
- sbg:modifiedBy: e.esquinca
  sbg:modifiedOn: 1610654249
  sbg:revision: 9
  sbg:revisionNotes: ''
- sbg:modifiedBy: e.esquinca
  sbg:modifiedOn: 1610654330
  sbg:revision: 10
  sbg:revisionNotes: Updated Script
- sbg:modifiedBy: e.esquinca
  sbg:modifiedOn: 1610655503
  sbg:revision: 11
  sbg:revisionNotes: Update Script
- sbg:modifiedBy: e.esquinca
  sbg:modifiedOn: 1610656726
  sbg:revision: 12
  sbg:revisionNotes: ''
- sbg:modifiedBy: e.esquinca
  sbg:modifiedOn: 1610657587
  sbg:revision: 13
  sbg:revisionNotes: added out log file
- sbg:modifiedBy: e.esquinca
  sbg:modifiedOn: 1610657913
  sbg:revision: 14
  sbg:revisionNotes: ''
- sbg:modifiedBy: e.esquinca
  sbg:modifiedOn: 1610658907
  sbg:revision: 15
  sbg:revisionNotes: ''
- sbg:modifiedBy: e.esquinca
  sbg:modifiedOn: 1610663483
  sbg:revision: 16
  sbg:revisionNotes: ''
- sbg:modifiedBy: e.esquinca
  sbg:modifiedOn: 1610663915
  sbg:revision: 17
  sbg:revisionNotes: ''
- sbg:modifiedBy: e.esquinca
  sbg:modifiedOn: 1610664251
  sbg:revision: 18
  sbg:revisionNotes: binding
- sbg:modifiedBy: e.esquinca
  sbg:modifiedOn: 1610751467
  sbg:revision: 19
  sbg:revisionNotes: update script
- sbg:modifiedBy: e.esquinca
  sbg:modifiedOn: 1610751592
  sbg:revision: 20
  sbg:revisionNotes: ''
- sbg:modifiedBy: e.esquinca
  sbg:modifiedOn: 1610752059
  sbg:revision: 21
  sbg:revisionNotes: update script
- sbg:modifiedBy: e.esquinca
  sbg:modifiedOn: 1610752826
  sbg:revision: 22
  sbg:revisionNotes: Descriptions
- sbg:modifiedBy: e.esquinca
  sbg:modifiedOn: 1610753016
  sbg:revision: 23
  sbg:revisionNotes: ''
- sbg:modifiedBy: e.esquinca
  sbg:modifiedOn: 1610753180
  sbg:revision: 24
  sbg:revisionNotes: ''
- sbg:modifiedBy: e.esquinca
  sbg:modifiedOn: 1610993763
  sbg:revision: 25
  sbg:revisionNotes: output script
- sbg:modifiedBy: e.esquinca
  sbg:modifiedOn: 1610994304
  sbg:revision: 26
  sbg:revisionNotes: write.table edit
- sbg:modifiedBy: e.esquinca
  sbg:modifiedOn: 1610995238
  sbg:revision: 27
  sbg:revisionNotes: output
- sbg:modifiedBy: e.esquinca
  sbg:modifiedOn: 1612832140
  sbg:revision: 28
  sbg:revisionNotes: made covariates optional
- sbg:modifiedBy: e.esquinca
  sbg:modifiedOn: 1612842028
  sbg:revision: 29
  sbg:revisionNotes: edited output
- sbg:modifiedBy: e.esquinca
  sbg:modifiedOn: 1612848474
  sbg:revision: 30
  sbg:revisionNotes: edited names
- sbg:modifiedBy: e.esquinca
  sbg:modifiedOn: 1612849368
  sbg:revision: 31
  sbg:revisionNotes: ''
- sbg:modifiedBy: e.esquinca
  sbg:modifiedOn: 1612851486
  sbg:revision: 32
  sbg:revisionNotes: ''
- sbg:modifiedBy: e.esquinca
  sbg:modifiedOn: 1612851877
  sbg:revision: 33
  sbg:revisionNotes: ''
- sbg:modifiedBy: e.esquinca
  sbg:modifiedOn: 1612851919
  sbg:revision: 34
  sbg:revisionNotes: ''
- sbg:modifiedBy: e.esquinca
  sbg:modifiedOn: 1612851953
  sbg:revision: 35
  sbg:revisionNotes: ''
- sbg:modifiedBy: e.esquinca
  sbg:modifiedOn: 1612853089
  sbg:revision: 36
  sbg:revisionNotes: ''
- sbg:modifiedBy: e.esquinca
  sbg:modifiedOn: 1612853548
  sbg:revision: 37
  sbg:revisionNotes: ''
sbg:sbgMaintained: false
sbg:validationErrors: []
