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
  run:
    cwlVersion: v1.1
    class: CommandLineTool
    label: peer
    doc: |-
      ```
      Usage: 
      Rscript run_peer.R [options] --omic_data file <omic_data_file> --output_prefix <output_prefix> --num_factors <num_factors>

      Probabilistic Estimation of Expression Residuals (PEER)

      Run PEER using the R interface. PEER is a method designed to estimate surrogate variables/latent factors/hidden factors that contribute to gene expression variability, but it can be applied to other data types as well. For more information, please refer to https://doi.org/10.1038/nprot.2011.457.

      Options:
              -h, --help
                      Show this help message and exit

              --omic_data_file=OMIC_DATA_FILE
                      [REQUIRED] A tab delimited file with .tab file extension containing N + 1 rows and G + 1 columns, where N is the number of samples, and G is the number of features (genes, methylation sites, chromatin accessibility windows, etc.). The first row and column must contain sample IDs and feature IDs respectively. Feature values should be normalized across samples and variance stabilized.

              --output_prefix=OUTPUT_PREFIX
                      [REQUIRED] File name prefix for output files. To specify an output directory as well, use --output_dir.

              --num_factors=NUM_FACTORS
                      [REQUIRED] Number of hidden factors to estimate. PEER uses automatic relevance determination to choose a suitable effective number of factors, so this parameter needs only to be set to a sufficiently large value. Without prior information available, a general recommendation is to use 25% of the number of samples but no more than 100 factors.

              --cov_file=COV_FILE
                      A tab delimited file with a .tab file extension containing a matrix of size M + 1 × C + 1, where M >= N and is the number of samples for which covariate data is provided. If this file is input, the set of samples used in the hidden factor estimation procedure will be the intersection of samples in the covariate matrix and omic data matrix. C is the number of known covariates to be included in association test regression models of downstream analyses. Examples of common covariates include sex, age, batch variables, and quality metrics. Categorical variables (e.g., batch number) have to be encoded as D - 1 indicator/binary variables, where D is the number of categories for a given categorical variable. For the indicator variables, a value of 1 signifies membership in the category and a value of 0 indicates otherwise. The first row and column must contain sample IDs and covariate IDs respectively [default=NULL].

              --alphaprior_a=ALPHAPRIOR_A
                      Shape parameter of the gamma distribution prior of the model noise distribution [default=0.001].

      root@80bc4504de2b:/opt# Rscript run_peer.R --help
      Usage: 
      Rscript run_peer.R [options] --omic_data file <omic_data_file> --output_prefix <output_prefix> --num_factors <num_factors>

      Probabilistic Estimation of Expression Residuals (PEER)

      Run PEER using the R interface. PEER is a method designed to estimate surrogate variables/latent factors/hidden factors that contribute to gene expression variability, but it can be applied to other data types as well. For more information, please refer to https://doi.org/10.1038/nprot.2011.457.

      Options:
              -h, --help
                      Show this help message and exit

              --omic_data_file=OMIC_DATA_FILE
                      [REQUIRED] A tab delimited file with .tab file extension containing N + 1 rows and G + 1 columns, where N is the number of samples, and G is the number of features (genes, methylation sites, chromatin accessibility windows, etc.). The first row and column must contain sample IDs and feature IDs respectively. Feature values should be normalized across samples and variance stabilized.

              --output_prefix=OUTPUT_PREFIX
                      [REQUIRED] File name prefix for output files. To specify an output directory as well, use --output_dir.

              --num_factors=NUM_FACTORS
                      [REQUIRED] Number of hidden factors to estimate. PEER uses automatic relevance determination to choose a suitable effective number of factors, so this parameter needs only to be set to a sufficiently large value. Without prior information available, a general recommendation is to use 25% of the number of samples but no more than 100 factors.

              --cov_file=COV_FILE
                      A tab delimited file with a .tab file extension containing a matrix of size M + 1 × C + 1, where M >= N and is the number of samples for which covariate data is provided. If this file is input, the set of samples used in the hidden factor estimation procedure will be the intersection of samples in the covariate matrix and omic data matrix. C is the number of known covariates to be included in association test regression models of downstream analyses. Examples of common covariates include sex, age, batch variables, and quality metrics. Categorical variables (e.g., batch number) have to be encoded as D - 1 indicator/binary variables, where D is the number of categories for a given categorical variable. For the indicator variables, a value of 1 signifies membership in the category and a value of 0 indicates otherwise. The first row and column must contain sample IDs and covariate IDs respectively [default=NULL].

              --alphaprior_a=ALPHAPRIOR_A
                      Shape parameter of the gamma distribution prior of the model noise distribution [default=0.001].

              --alphaprior_b=ALPHAPRIOR_B
                      Scale parameter of the gamma distribution prior of the model noise distribution. [default=0.01]

              --epsprior_a=EPSPRIOR_A
                      Shape parameter of the gamma distribution prior of the model weight distribution. [default=0.1]

              --epsprior_b=EPSPRIOR_B
                      Scale parameter of the gamma distribution prior of the model weight distribution. [default=10]

              --tol=TOL
                      Threshold for the increase in model evidence when optimizing hidden factor values. Estimation completes for a hidden factor when the increase in model evidence exceeds this value [default=0.001].

              --var_tol=VAR_TOL
                      Threshold for the variance of model residuals when optimizing hidden factor values. Estimation completes for a hidden factor when the variance of residuals is smaller than this value [default=1e-05].

              --max_iter=MAX_ITER
                      Max number of iterations for updating values of each hidden factor [default=1000].

              -o OUTPUT_DIR, --output_dir=OUTPUT_DIR
                      Directory in which to save outputs [default=.].

              -v, --version
                      Print PEER version number.




      ``
    $namespaces:
      sbg: https://sevenbridges.com

    requirements:
    - class: ShellCommandRequirement
    - class: DockerRequirement
      dockerPull: davidroberson/peer:20.10.14
    - class: InitialWorkDirRequirement
      listing:
      - entryname: run_new_peer.R
        writable: false
        entry: |-
          # Modified from https://github.com/broadinstitute/gtex-pipeline/blob/master/qtl/src/run_PEER.R
          # Original Author: Francois Aguet
          # Modified by: Bryan Quach <bquach@rti.org>

          library(peer, quietly = T)
          library(optparse, quietly = T)
          peer.version <- 1.3 #software version

          WriteTable <- function(data, filename, index.name) {
              datafile <- file(filename, open = "wt")
              on.exit(close(datafile))
              header <- c(index.name, colnames(data))
              writeLines(paste0(header, collapse = "\t"), con = datafile, sep = "\n")
              write.table(data, datafile, sep = "\t", col.names = F, quote = F)
          }

          # Generate usage doc and retrieve command line args
          p <- OptionParser(usage = "\n%prog [options] --omic_data file <omic_data_file> --output_prefix <output_prefix> --num_factors <num_factors>",
              description = "\nProbabilistic Estimation of Expression Residuals (PEER)\n\nRun PEER using the R interface. PEER is a method designed to estimate surrogate variables/latent factors/hidden factors that contribute to gene expression variability, but it can be applied to other data types as well. For more information, please refer to https://doi.org/10.1038/nprot.2011.457.",
              prog = "Rscript run_peer.R")
          p <- add_option(object = p, opt_str = c("--omic_data_file"), default = NULL, type = "character",
              help = "[REQUIRED] A tab delimited file with .tab file extension containing N + 1 rows and G + 1 columns, where N is the number of samples, and G is the number of features (genes, methylation sites, chromatin accessibility windows, etc.). The first row and column must contain sample IDs and feature IDs respectively. Feature values should be normalized across samples and variance stabilized.")
          p <- add_option(object = p, opt_str = c("--output_prefix"), default = NULL, type = "character",
              help = "[REQUIRED] File name prefix for output files. To specify an output directory as well, use --output_dir.")
          p <- add_option(object = p, opt_str = c("--num_factors"), type = "integer", default = NULL,
              help = "[REQUIRED] Number of hidden factors to estimate. PEER uses automatic relevance determination to choose a suitable effective number of factors, so this parameter needs only to be set to a sufficiently large value. Without prior information available, a general recommendation is to use 25% of the number of samples but no more than 100 factors.")
          p <- add_option(object = p, opt_str = c("--cov_file"), help = "A tab delimited file with a .tab file extension containing a matrix of size M + 1 × C + 1, where M >= N and is the number of samples for which covariate data is provided. If this file is input, the set of samples used in the hidden factor estimation procedure will be the intersection of samples in the covariate matrix and omic data matrix. C is the number of known covariates to be included in association test regression models of downstream analyses. Examples of common covariates include sex, age, batch variables, and quality metrics. Categorical variables (e.g., batch number) have to be encoded as D - 1 indicator/binary variables, where D is the number of categories for a given categorical variable. For the indicator variables, a value of 1 signifies membership in the category and a value of 0 indicates otherwise. The first row and column must contain sample IDs and covariate IDs respectively [default=%default].")
          p <- add_option(object = p, opt_str = c("--alphaprior_a"), type = "double", default = 0.001,
              help = "Shape parameter of the gamma distribution prior of the model noise distribution [default=%default].")
          p <- add_option(object = p, opt_str = c("--alphaprior_b"), type = "double", default = 0.01,
              help = "Scale parameter of the gamma distribution prior of the model noise distribution. [default=%default]")
          p <- add_option(object = p, opt_str = c("--epsprior_a"), type = "double", default = 0.1,
              help = "Shape parameter of the gamma distribution prior of the model weight distribution. [default=%default]")
          p <- add_option(object = p, opt_str = c("--epsprior_b"), type = "double", default = 10,
              help = "Scale parameter of the gamma distribution prior of the model weight distribution. [default=%default]")
          p <- add_option(object = p, opt_str = c("--tol"), type = "double", default = 0.001,
              help = "Threshold for the increase in model evidence when optimizing hidden factor values. Estimation completes for a hidden factor when the increase in model evidence exceeds this value [default=%default].")
          p <- add_option(object = p, opt_str = c("--var_tol"), type = "double", default = 0.00001,
              help = "Threshold for the variance of model residuals when optimizing hidden factor values. Estimation completes for a hidden factor when the variance of residuals is smaller than this value [default=%default].")
          p <- add_option(object = p, opt_str = c("--max_iter"), type = "double", default = 1000,
              help = "Max number of iterations for updating values of each hidden factor [default=%default].")
          p <- add_option(object = p, opt_str = c("--output_dir", "-o"), default = ".",
              help = "Directory in which to save outputs [default=%default].")
          p <- add_option(object = p, opt_str = c("--version", "-v"), action = "store_true", default = F, 
              help = "Print PEER version number.")
          argv <- parse_args(p)

          # Quick execution for printing version number
          if(argv$version){
              cat(paste0("PEER v", peer.version))
              quit(save = "no")
          }

          # Check if positional arguments were given 
          if(is.null(argv$omic_data_file)){
              stop("Error: Please provide a value for --omic_data_file")
          }
          if(is.null(argv$output_prefix)){
              stop("Error: Please provide a value for --output_prefix")
          }
          if(is.null(argv$num_factors)){
              stop("Error: Please provide a value for --num_factors")
          }


          # Check validity of argument inputs
          if(!file.exists(argv$omic_data_file)){ 
              stop(paste0("Error: ", argv$omic_data_file, 
                  " not found. Check your file path and name.")) 
          }
          if(!grepl(x = argv$omic_data_file, pattern = "\\.tab$", perl = T)){ 
              stop("Error: --omic_data_file requires .tab extension.")
          }
          if(!is.null(argv$cov_file) && !file.exists(argv$cov_file)){ 
              stop(paste0("Error: ", argv$cov_file, 
                  " not found. Check your file path and name.")) 
          }
          if(!is.null(argv$cov_file) &&
              !grepl(x = argv$cov_file, pattern = "\\.tab$", perl = T)){ 
              stop("Error: --cov_file requires .tab extension.")
          }
          if(is.na(argv$num_factors) | argv$num_factors <= 0 | 
             !is.finite(argv$num_factors) | argv$num_factors != as.integer(argv$num_factors)){ 
              stop(paste0("Error: Please provide a valid number for 'num_factors'. Use --help for more details."))
          }
          if(argv$max_iter <= 0 | !is.finite(argv$max_iter) | 
             argv$max_iter != as.integer(argv$max_iter)){ 
              stop(paste0("Error: Please provide a valid number for --max_iter. Use --help for more details."))
          }
          if(argv$tol <= 0 | !is.finite(argv$tol)){ 
              stop(paste0("Error: Please provide a valid value for --tol. Use --help for more details."))
          }
          if(argv$var_tol <= 0 | !is.finite(argv$var_tol)){ 
              stop(paste0("Error: Please provide a valid value for --var_tol. Use --help for more details."))
          }
          if(argv$alphaprior_a < 0 | !is.finite(argv$alphaprior_a)){ 
              stop(paste0("Error: Please provide a valid value for --alphaprior_a. Use --help for more details."))
          }
          if(argv$alphaprior_b < 0 | !is.finite(argv$alphaprior_b)){ 
              stop(paste0("Error: Please provide a valid value for --alphaprior_b. Use --help for more details."))
          }
          if(argv$epsprior_a < 0 | !is.finite(argv$epsprior_a)){ 
              stop(paste0("Error: Please provide a valid value for --epsprior_a. Use --help for more details."))
          }
          if(argv$epsprior_b < 0 | !is.finite(argv$epsprior_b)){ 
              stop(paste0("Error: Please provide a valid value for --epsprior_b. Use --help for more details."))
          }

          # Create output directory if needed
          dir.create(argv$output_dir, showWarnings = F)

          # Load omic data
          cat(paste0("Loading data from ", argv$omic_data_file, " ..."))
          omic.data <- read.table(argv$omic_data_file, sep = "\t", header = T, 
              check.names = F, comment.char = "", row.names = 1)
          omic.data <- as.matrix(omic.data)
          n.samples <- nrow(omic.data)
          n.features <- ncol(omic.data)
          cat("Done.\n")
          cat(paste0("Loaded data matrix with ", n.samples, " rows and ", 
              n.features, " columns.\n"))

          # Load covariate data
          cov.data <- NULL
          if(!is.null(argv$cov_file)){
              cat(paste0("Loading covariate data from ", argv$cov_file, " ..."))
              cov.data <- read.table(argv$cov_file, sep = "\t", header = T, as.is = T, 
                  check.names = F, comment.char = "", row.names = 1)
              cov.data <- as.matrix(cov.data)
              n.vars <- ncol(cov.data)
              cat("Done.\n")
              cat(paste0("Loaded ", n.vars, " covariates.\n"))
              # Subset and match rows between covariate and omic data matrix
              cov.subset <- cov.data[rownames(cov.data) %in% rownames(omic.data), , drop = F]
              omic.subset <- omic.data[rownames(omic.data) %in% rownames(cov.subset), , drop = F]
              match.order <- match(rownames(cov.subset), table = rownames(omic.subset))
              cov.subset <- cov.subset[match.order, , drop = F]
              if(nrow(omic.subset) < nrow(omic.data)){
                  cat(paste0("Data reduced to ", nrow(omic.subset), 
                  " samples after matching with covariate data.\n"))
              }
              omic.data <- omic.subset
              cov.data <- cov.subset
          }

          # Set method parameters
          cat(paste0("Setting initialization parameters ..."))
          model <- PEER()
          invisible(PEER_setNk(model, argv$num_factors))
          invisible(PEER_setPhenoMean(model, omic.data))
          invisible(PEER_setPriorAlpha(model, argv$alphaprior_a, argv$alphaprior_b))
          invisible(PEER_setPriorEps(model, argv$epsprior_a, argv$epsprior_b))
          invisible(PEER_setTolerance(model, argv$tol))
          invisible(PEER_setVarTolerance(model, argv$var_tol))
          invisible(PEER_setNmax_iterations(model, argv$max_iter))
          if(!is.null(cov.data)){
              invisible(PEER_setCovariates(model, cov.data))
          }
          cat("Done.\n")

          # Run inference routine
          cat(paste0("Beginning estimation of ", argv$num_factors, " hidden factors.\n"))
          time <- system.time(PEER_update(model))
          cat("Finished estimation procedure.\n")
          cat(paste0("Hidden factor estimation completed in ", round(time[3], 2) , " seconds (", round(time[3]/60, 2) ," minutes).\n"))

          # Retrieve results
          factor.mat <- PEER_getX(model)  # samples x PEER factors
          weight.mat <- PEER_getW(model)  # omic features x PEER factors
          precision.mat <- PEER_getAlpha(model)  # PEER factors x 1
          resid.mat <- t(PEER_getResiduals(model))  # omic features x samples

          # Add relevant row/column names
          peer.var.names <- paste0("peer.factor", 1:ncol(factor.mat))
          rownames(factor.mat) <- rownames(omic.data)
          colnames(factor.mat) <- peer.var.names
          colnames(weight.mat) <- peer.var.names
          rownames(weight.mat) <- colnames(omic.data)
          rownames(precision.mat) <- peer.var.names
          colnames(precision.mat) <- "alpha"
          precision.mat <- as.data.frame(precision.mat)
          precision.mat$relevance <- 1.0 / precision.mat$alpha
          rownames(resid.mat) <- colnames(omic.data)
          colnames(resid.mat) <- rownames(omic.data)

          # Write results
          cat("Exporting results ... ")
          WriteTable(factor.mat, file.path(argv$output_dir, paste0(argv$output_prefix, "_peer_covariates.txt")), "ID")  
          WriteTable(weight.mat, file.path(argv$output_dir, paste0(argv$output_prefix, "_peer_weights.txt")), "ID")
          WriteTable(precision.mat, file.path(argv$output_dir, paste0(argv$output_prefix, "_peer_precisions.txt")), "ID")
          WriteTable(resid.mat, file.path(argv$output_dir, paste0(argv$output_prefix, "_peer_residuals.txt")), "ID")
          cat("Done.\n")

    inputs:
    - id: Omics_Data_File
      label: Omics Data File
      doc: |-
        A tab delimited file with .tab file extension containing N + 1 rows and G + 1 columns, where N is the number of samples, and G is the number of features (genes, methylation sites, chromatin accessibility windows, etc.). The first row and column must contain sample IDs and feature IDs respectively. Feature values should be normalized across samples and variance stabilized.
      type: File
      inputBinding:
        prefix: --omic_data_file
        position: 0
        shellQuote: false
    - id: Output_File_Prefix
      label: Output File Prefrix
      doc: File name prefix for output files.
      type: string
      inputBinding:
        prefix: --output_prefix
        position: 0
        shellQuote: false
    - id: Output_Directory
      label: Output Directory
      doc: To specify an output directory
      type: string?
      inputBinding:
        prefix: --output_dir
        position: 0
        shellQuote: false
    - id: Hidden_Factors
      label: NUM_FACTORS
      doc: |-
        Number of hidden factors to estimate. PEER uses automatic relevance determination to choose a suitable effective number of factors, so this parameter needs only to be set to a sufficiently large value. Without prior information available, a general recommendation is to use 25% of the number of samples but no more than 100 factors.
      type: int
      inputBinding:
        prefix: --num_factors
        position: 0
        shellQuote: false
    - id: Covariates_File
      label: Covariates File
      doc: |-
        A tab delimited file with a .tab file extension containing a matrix of size M + 1 × C + 1, where M >= N and is the number of samples for which covariate data is provided. If this file is input, the set of samples used in the hidden factor estimation procedure will be the intersection of samples in the covariate matrix and omic data matrix. C is the number of known covariates to be included in association test regression models of downstream analyses. Examples of common covariates include sex, age, batch variables, and quality metrics. Categorical variables (e.g., batch number) have to be encoded as D - 1 indicator/binary variables, where D is the number of categories for a given categorical variable. For the indicator variables, a value of 1 signifies membership in the category and a value of 0 indicates otherwise. The first row and column must contain sample IDs and covariate IDs respectively. 
        [Default = NULL]
      type: File?
      inputBinding:
        prefix: --cov_file
        position: 0
        shellQuote: false
    - id: Alpha_Prior_A
      doc: |-
        Shape parameter of the gamma distribution prior of the model noise distribution [Default=0.001].
      type: float?
      default: 0.001
      inputBinding:
        prefix: --alphaprior_a
        position: 0
        shellQuote: false
    - id: Alpha_Prior_B
      doc: |-
        Scale parameter of the gamma distribution prior of the model noise distribution. [default=0.01]
      type: float?
      default: 0.01
      inputBinding:
        prefix: --alphaprior_b
        position: 0
        shellQuote: false
    - id: Eps_Prior_A
      doc: |-
        Shape parameter of the gamma distribution prior of the model weight distribution. [Default=0.1]
      type: float?
      default: 0.1
      inputBinding:
        prefix: --epsprior_a
        position: 0
        shellQuote: false
    - id: Eps_Prior_B
      doc: |-
        Scale parameter of the gamma distribution prior of the model weight distribution. [default=10]
      type: float?
      default: 10
      inputBinding:
        prefix: --epsprior_b
        position: 0
        shellQuote: false
    - id: Tol
      doc: |-
        Threshold for the increase in model evidence when optimizing hidden factor values. Estimation completes for a hidden factor when the increase in model evidence exceeds this value [default=0.001].
      type: float?
      default: 0.001
      inputBinding:
        prefix: --tol
        position: 0
        shellQuote: false
    - id: Max_Iteration
      doc: |-
        Max number of iterations for updating values of each hidden factor [default=1000].
      type: float?
      default: 1000
      inputBinding:
        prefix: --max_iter
        position: 0
        shellQuote: false

    outputs:
    - id: std_out
      type: File?
      outputBinding:
        glob: std.out
    - id: peer_covariates
      type: File?
      outputBinding:
        glob: '*peer_covariates.txt'
    - id: peer_weights
      type: File?
      outputBinding:
        glob: '*peer_weights.txt'
    - id: peer_precisions
      type: File?
      outputBinding:
        glob: '*peer_precisions.txt'
    - id: peer_residuals
      type: File?
      outputBinding:
        glob: '*peer_residuals.txt'
    stdout: std.out

    baseCommand:
    - Rscript run_new_peer.R
    id: dave/peer-development/peer/27
    sbg:appVersion:
    - v1.1
    sbg:content_hash: a25c6d4875eb1d525dd7f3a89371fb389d55b0971bfdf57ee9951b729caf9df63
    sbg:contributors:
    - rk.johnson
    - e.esquinca
    - dave
    sbg:createdBy: dave
    sbg:createdOn: 1602689199
    sbg:id: dave/peer-development/peer/27
    sbg:image_url:
    sbg:latestRevision: 27
    sbg:modifiedBy: e.esquinca
    sbg:modifiedOn: 1607574135
    sbg:project: dave/peer-development
    sbg:projectName: PEER Development
    sbg:publisher: sbg
    sbg:revision: 27
    sbg:revisionNotes: Transpose Peer Factor Results
    sbg:revisionsInfo:
    - sbg:modifiedBy: dave
      sbg:modifiedOn: 1602689199
      sbg:revision: 0
      sbg:revisionNotes:
    - sbg:modifiedBy: dave
      sbg:modifiedOn: 1602689235
      sbg:revision: 1
      sbg:revisionNotes: added help text
    - sbg:modifiedBy: dave
      sbg:modifiedOn: 1602689438
      sbg:revision: 2
      sbg:revisionNotes: ''
    - sbg:modifiedBy: dave
      sbg:modifiedOn: 1602689466
      sbg:revision: 3
      sbg:revisionNotes: ''
    - sbg:modifiedBy: dave
      sbg:modifiedOn: 1602689579
      sbg:revision: 4
      sbg:revisionNotes: ''
    - sbg:modifiedBy: dave
      sbg:modifiedOn: 1602689985
      sbg:revision: 5
      sbg:revisionNotes: ''
    - sbg:modifiedBy: dave
      sbg:modifiedOn: 1602690267
      sbg:revision: 6
      sbg:revisionNotes: std out
    - sbg:modifiedBy: dave
      sbg:modifiedOn: 1602690736
      sbg:revision: 7
      sbg:revisionNotes: ''
    - sbg:modifiedBy: dave
      sbg:modifiedOn: 1602690866
      sbg:revision: 8
      sbg:revisionNotes: ''
    - sbg:modifiedBy: dave
      sbg:modifiedOn: 1602690914
      sbg:revision: 9
      sbg:revisionNotes: ''
    - sbg:modifiedBy: dave
      sbg:modifiedOn: 1602691010
      sbg:revision: 10
      sbg:revisionNotes: ''
    - sbg:modifiedBy: e.esquinca
      sbg:modifiedOn: 1603125039
      sbg:revision: 11
      sbg:revisionNotes: ''
    - sbg:modifiedBy: e.esquinca
      sbg:modifiedOn: 1603125227
      sbg:revision: 12
      sbg:revisionNotes: ''
    - sbg:modifiedBy: e.esquinca
      sbg:modifiedOn: 1603125661
      sbg:revision: 13
      sbg:revisionNotes: ''
    - sbg:modifiedBy: e.esquinca
      sbg:modifiedOn: 1603127020
      sbg:revision: 14
      sbg:revisionNotes: ''
    - sbg:modifiedBy: e.esquinca
      sbg:modifiedOn: 1603128327
      sbg:revision: 15
      sbg:revisionNotes: ''
    - sbg:modifiedBy: e.esquinca
      sbg:modifiedOn: 1603128415
      sbg:revision: 16
      sbg:revisionNotes: ''
    - sbg:modifiedBy: e.esquinca
      sbg:modifiedOn: 1603911381
      sbg:revision: 17
      sbg:revisionNotes: ''
    - sbg:modifiedBy: e.esquinca
      sbg:modifiedOn: 1603911497
      sbg:revision: 18
      sbg:revisionNotes: ''
    - sbg:modifiedBy: e.esquinca
      sbg:modifiedOn: 1603911583
      sbg:revision: 19
      sbg:revisionNotes: ''
    - sbg:modifiedBy: e.esquinca
      sbg:modifiedOn: 1603923045
      sbg:revision: 20
      sbg:revisionNotes: ''
    - sbg:modifiedBy: e.esquinca
      sbg:modifiedOn: 1603924351
      sbg:revision: 21
      sbg:revisionNotes: ''
    - sbg:modifiedBy: e.esquinca
      sbg:modifiedOn: 1604007308
      sbg:revision: 22
      sbg:revisionNotes: ''
    - sbg:modifiedBy: rk.johnson
      sbg:modifiedOn: 1604509981
      sbg:revision: 23
      sbg:revisionNotes: Added output port for PEER covariates
    - sbg:modifiedBy: e.esquinca
      sbg:modifiedOn: 1604535891
      sbg:revision: 24
      sbg:revisionNotes: ''
    - sbg:modifiedBy: e.esquinca
      sbg:modifiedOn: 1604535931
      sbg:revision: 25
      sbg:revisionNotes: ''
    - sbg:modifiedBy: e.esquinca
      sbg:modifiedOn: 1604535981
      sbg:revision: 26
      sbg:revisionNotes: ''
    - sbg:modifiedBy: e.esquinca
      sbg:modifiedOn: 1607574135
      sbg:revision: 27
      sbg:revisionNotes: Transpose Peer Factor Results
    sbg:sbgMaintained: false
    sbg:validationErrors: []
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
  run:
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
  run:
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
  run:
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
  run:
    cwlVersion: v1.2
    class: CommandLineTool
    label: Elastic Models
    doc: |-
      Program runs elastic net prediction models following PredictDB_Pipeline_GTEx_v7, 
      as described here: https://github.com/hakyimlab/PredictDB_Pipeline_GTEx_v7

      1. Functions defined
      2. Define inputs, directories, & call functions

      Part 3 is conducted in the Database Summary Tool

      3. Combine models for all chromosomes entered in one database file. Then the database will be filtered for use in PrediXcan

      Nested Cross Validated Elastic-Net - In previous versions of PredictDB, we employed 10-fold cross-validated elastic-net to tune the parameter lambda, and then estimated the significance of the model. It recently became apparent that this was biasing the significance measures because we were using the same data to tune the parameter lambda and assess the performance. To correct for this problem, we used the following "nested" cross validation procedure:

      Randomly split the data into 5 folds.

      For each fold:

      a. Remove the fold from the data.

      b. Use the remaining data to train an elastic-net model using 10-fold cross-validation to tune the lambda parameter.

      c. With the trained model, predict on the hold out fold, and get various test statistics for how the model performs.

      Calculate the average and standard deviation of each of the significance statistics, where applicable. This should provide a reasonable estimate for how well the model will generalize to new data.

      Train a new elastic-net model using all of the data. Again, use 10-fold cross validation to tune the lambda parameter. The non-zero weights from this final model are what are saved in the database, provided the model meets significance criteria.

      A model was determined to be "significant" if the average pearson correlation between predicted and observed during nested cross validation was greater than 0.1 (equivalent to R2 > 0.01) and the estimated p-value for this statistic was less than 0.05. See below for how the p-value was calculated.
    $namespaces:
      sbg: https://sevenbridges.com

    requirements:
    - class: ResourceRequirement
      ramMin: $(inputs.RAM)
    - class: DockerRequirement
      dockerPull: images.sb.biodatacatalyst.nhlbi.nih.gov/dave/predictdb:v2021_02_13
    - class: InitialWorkDirRequirement
      listing:
      - entryname: gtex_v7_nested_cv_elnet_training_combined.R
        writable: false
        entry: |
          #! /usr/bin/env Rscript
          
          # Program runs elastic net prediction models following PredictDB_Pipeline_GTEx_v7, 
          # as described here: https://github.com/hakyimlab/PredictDB_Pipeline_GTEx_v7
          
          # 1. Functions defined
          # 2. Define inputs, directories, call functions
          # 3. Combine models for all chromosomes, create and filter database for use in PrediXcan
          
          suppressMessages(library(dplyr))
          suppressMessages(library(glmnet))
          suppressMessages((library(reshape2)))
          suppressMessages(library(methods))
          suppressMessages(library(RSQLite))
          suppressMessages(library(data.table))
          
          "%&%" <- function(a,b) paste(a,b, sep='')
          
          
          ##################################
          # 1. Define all functions for prediction models
          
          get_filtered_snp_annot <- function(snp_annot_file) {
            snp_annot <- read.table(snp_annot_file, header = T, stringsAsFactors = F) %>%
              filter(!((ref_vcf == 'A' & alt_vcf == 'T') |
                         (ref_vcf == 'T' & alt_vcf == 'A') |
                         (ref_vcf == 'C' & alt_vcf == 'G') |
                         (ref_vcf == 'G' & alt_vcf == 'C')) &
                       !(is.na(rsid))) %>%
              distinct(varID, .keep_all = TRUE)
            snp_annot
          }
          
          
          get_maf_filtered_genotype <- function(genotype_file,  maf, samples) {
            gt_df <- read.table(genotype_file, header = T, stringsAsFactors = F, row.names = 1)
            gt_df <- gt_df[,(colnames(gt_df) %in% samples )] %>% t() %>% as.data.frame()
            effect_allele_freqs <- colMeans(gt_df) / 2
            gt_df <- gt_df[,which((effect_allele_freqs >= maf) & (effect_allele_freqs <= 1 - maf))]
            gt_df
          }
          
          get_gene_annotation <- function(gene_annot_file, chrom, gene_types=c('protein_coding', 'pseudogene', 'lincRNA')){
            gene_df <- read.table(gene_annot_file, header = TRUE, stringsAsFactors = FALSE) %>%
              filter((chr == chrom) & gene_type %in% gene_types)
            gene_df
          }
          
          get_gene_type <- function(gene_annot, gene) {
            filter(gene_annot, gene_id == gene)$gene_type
          }
          
          # Got rid of t() done twice which should cancel out. 
          get_gene_expression <- function(expression_file, gene_annot) {
            expr_df <- as.data.frame((read.table(expression_file, header = T, stringsAsFactors = F, row.names = 1)))
            #expr_df <- expr_df %>% t() %>% as.data.frame()
            expr_df <- expr_df %>% select(one_of(intersect(gene_annot$gene_id, colnames(expr_df))))
            expr_df
          }
          
          get_gene_coords <- function(gene_annot, gene) {
            row <- gene_annot[which(gene_annot$gene_id == gene),]
            c(row$start, row$end)
          }
          
          get_cis_genotype <- function(gt_df, snp_annot, coords, cis_window) {
            snp_info <- snp_annot %>% filter((pos >= (coords[1] - cis_window) & !is.na(rsid)) & (pos <= (coords[2] + cis_window)))
            if (nrow(snp_info) == 0)
              return(NA)
            #Check if the varID exist in the data
            if (TRUE %in% (snp_info$varID %in% names(gt_df))) {
              cis_gt <- gt_df %>% select(one_of(intersect(snp_info$varID, colnames(gt_df))))
            } else {
              return(NA) # the varID doesn't exist in the gt_df dataset
            }
            column_labels <- colnames(cis_gt)
            row_labels <- rownames(cis_gt)
            # Convert cis_gt to a matrix for glmnet
            cis_gt <- matrix(as.matrix(cis_gt), ncol=ncol(cis_gt))
            colnames(cis_gt) <- column_labels
            rownames(cis_gt) <- row_labels
            cis_gt
          }
          
          #get_covariates <- function(covariates_file, samples) {
          #  cov_df <- read.table(covariates_file, header = TRUE, stringsAsFactors = FALSE, row.names = 1)
          #  cov_df <- cov_df[(rownames(cov_df) %in% samples),] %>% as.data.frame() # %&% t() 
            # We have peer covariates coming out as samples as rows from the tool so deleted the extra t()
            # and adjusted reading in rownames instead
          #  cov_df
          #}
          
          generate_fold_ids <- function(n_samples, n_folds=10) {
            n <- ceiling(n_samples / n_folds)
            fold_ids <- rep(1:n_folds, n)
            sample(fold_ids[1:n_samples])
          }
          
          # adjust_for_covariates <- function(expression_vec, cov_df) {
          #  combined_df <- cbind(expression_vec, cov_df)
          #  expr_resid <- summary(lm(expression_vec ~ ., data=combined_df))$residuals
          #  expr_resid <- scale(expr_resid, center = TRUE, scale = TRUE)
          #  expr_resid
          # }
          
          calc_R2 <- function(y, y_pred) {
            tss <- sum(y**2)
            rss <- sum((y - y_pred)**2)
            1 - rss/tss
          }
          
          calc_corr <- function(y, y_pred) {
            sum(y*y_pred) / (sqrt(sum(y**2)) * sqrt(sum(y_pred**2)))
          }
          
          nested_cv_elastic_net_perf <- function(x, y, n_samples, n_train_test_folds, n_k_folds, alpha, samples) {
            # Gets performance estimates for k-fold cross-validated elastic-net models.
            # Splits data into n_train_test_folds disjoint folds, roughly equal in size,
            # and for each fold, calculates a n_k_folds cross-validated elastic net model. Lambda parameter is
            # cross validated. Then get performance measures for how the model predicts on the hold-out
            # fold. Get the coefficient of determination, R^2, and a p-value, where the null hypothesis
            # is there is no correlation between prediction and observed.
            #
            # The mean and standard deviation of R^2 over all folds is then reported, and the p-values
            # are combined using Fisher's method.
            
            # for testing line by line only
            # x = cis_gt
            # y = adj_expression
            # n_k_folds = n_folds
            
            R2_folds <- rep(0, n_train_test_folds)
            corr_folds <- rep(0, n_train_test_folds)
            zscore_folds <- rep(0, n_train_test_folds)
            pval_folds <- rep(0, n_train_test_folds)
            # Outer-loop split into training and test set.
            train_test_fold_ids <- generate_fold_ids(n_samples, n_folds=n_train_test_folds)
            for (test_fold in 1:n_train_test_folds) {
              train_idxs <- which(train_test_fold_ids != test_fold)
              test_idxs <- which(train_test_fold_ids == test_fold)
              x_train <- x[(rownames(x) %in% samples[train_idxs]), ]
              y_train <- y[(rownames(y) %in% rownames(x_train))]
              x_test <- x[(rownames(x) %in% samples[test_idxs]), ]
              y_test <- y[(rownames(y) %in% rownames(x_test))]
              # Inner-loop - split up training set for cross-validation to choose lambda.
              cv_fold_ids <- generate_fold_ids(length(y_train), n_k_folds)
              y_pred <- tryCatch({
                # Fit model with training data.
                  # Parallel
                  library(doMC)
                  registerDoMC(cores = 16)
                fit <- cv.glmnet(x_train, y_train, nfolds = n_k_folds, alpha = alpha, type.measure='mse', foldid = cv_fold_ids,
                  parallel = TRUE)
                # Predict test data using model that had minimal mean-squared error in cross validation.
                predict(fit, x_test, s = 'lambda.min')},
                # if the elastic-net model did not converge, predict the mean of the y_train (same as all non-intercept coef=0)
                error = function(cond) rep(mean(y_train), length(y_test)))
              R2_folds[test_fold] <- calc_R2(y_test, y_pred)
              # Get p-value for correlation test between predicted y and actual y.
              # If there was no model, y_pred will have var=0, so cor.test will yield NA.
              # In that case, give a random number from uniform distribution, which is what would
              # usually happen under the null.
              corr_folds[test_fold] <- ifelse(sd(y_pred) != 0, cor(y_pred, y_test), 0)
              zscore_folds[test_fold] <- atanh(corr_folds[test_fold])*sqrt(length(y_test) - 3) # Fisher transformation
              pval_folds[test_fold] <- ifelse(sd(y_pred) != 0, cor.test(y_pred, y_test)$p.value, runif(1))
            }
            R2_avg <- mean(R2_folds)
            R2_sd <- sd(R2_folds)
            rho_avg <- mean(corr_folds)
            rho_se <- sd(corr_folds)
            rho_avg_squared <- rho_avg**2
            # Stouffer's method for combining z scores.
            zscore_est <- sum(zscore_folds) / sqrt(n_train_test_folds)
            zscore_pval <- 2*pnorm(abs(zscore_est), lower.tail = FALSE)
            # Fisher's method for combining p-values: https://en.wikipedia.org/wiki/Fisher%27s_method
            pval_est <- pchisq(-2 * sum(log(pval_folds)), 2*n_train_test_folds, lower.tail = F)
            list(R2_avg=R2_avg, R2_sd=R2_sd, pval_est=pval_est, rho_avg=rho_avg, rho_se=rho_se, rho_zscore=zscore_est, rho_avg_squared=rho_avg_squared, zscore_pval=zscore_pval)
          }
          
          do_covariance <- function(gene_id, cis_gt, rsids, varIDs) {
            model_gt <- cis_gt[,varIDs, drop=FALSE]
            colnames(model_gt) <- rsids
            geno_cov <- cov(model_gt)
            geno_cov[lower.tri(geno_cov)] <- NA
            cov_df <- reshape2::melt(geno_cov, varnames = c("rsid1", "rsid2"), na.rm = TRUE) %>%
              mutate(gene=gene_id) %>%
              select(GENE=gene, RSID1=rsid1, RSID2=rsid2, VALUE=value) %>%
              arrange(GENE, RSID1, RSID2)
            cov_df
          }
          
          # Refine eventually: will want to make the fields defined here to be optional input parameters (maf, n_folds, etc.), and behave similarly to seed where there is a default input unless user-defined.
          main <- function(snp_annot_file, gene_annot_file, genotype_file, expression_file,
                            chrom, prefix, summary_path, weights_path, covariances_path, maf=0.01, n_folds=10, n_train_test_folds=5,
                           seed=NA, cis_window=1e6, alpha=0.5, null_testing=FALSE) {
            gene_annot <- get_gene_annotation(gene_annot_file, chrom)
            expr_df <- get_gene_expression(expression_file, gene_annot)
            samples <- rownames(expr_df)
            n_samples <- length(samples)
            genes <- colnames(expr_df)
            n_genes <- length(expr_df)
            snp_annot <- get_filtered_snp_annot(snp_annot_file)
            gt_df <- get_maf_filtered_genotype(genotype_file, maf, samples)
            #covariates_df <- get_covariates(covariates_file, samples)
            
            #Update: order all subject-level data frames to have sampleids in the same order as the expr_df
            gt_df = gt_df[match(samples, rownames(gt_df)),]
            #covariates_df = covariates_df[match(samples, rownames(covariates_df)),]
            
            # Set seed----
            seed <- ifelse(is.na(seed), sample(1:1000000, 1), seed)
            set.seed(seed)
            
            # Prepare output data----
            model_summary_file <- summary_path %&% prefix %&% '_chr' %&% chrom %&% '_model_summaries.txt'
            model_summary_cols <- c('chrom','gene_id', 'gene_name', 'gene_type', 'alpha', 'n_snps_in_window', 'n_snps_in_model', 'lambda_min_mse',
                                    'test_R2_avg', 'test_R2_sd', 'cv_R2_avg', 'cv_R2_sd', 'in_sample_R2',
                                    'nested_cv_fisher_pval', 'rho_avg', 'rho_se', 'rho_zscore', 'rho_avg_squared', 'zscore_pval',
                                    'cv_rho_avg', 'cv_rho_se', 'cv_rho_avg_squared', 'cv_zscore_est', 'cv_zscore_pval', 'cv_pval_est')
            write(model_summary_cols, file = model_summary_file, ncol = 25, sep = '\t')
            
            weights_file <- weights_path %&% prefix %&% '_chr' %&% chrom %&% '_weights.txt'
            weights_col <- c('gene_id', 'rsid', 'varID', 'ref', 'alt', 'beta')
            write(weights_col, file = weights_file, ncol = 6, sep = '\t')
            
            tiss_chr_summ_f <- summary_path %&% prefix %&% '_chr' %&% chrom %&% '_summary.txt'
            tiss_chr_summ_col <- c('n_samples', 'chrom', 'cv_seed', 'n_genes')
            tiss_chr_summ <- data.frame(n_samples, chrom, seed, n_genes)
            colnames(tiss_chr_summ) <- tiss_chr_summ_col
            write.table(tiss_chr_summ, file = tiss_chr_summ_f, quote = FALSE, row.names = FALSE, sep = '\t')
            
            covariance_file <- covariances_path %&% prefix %&% '_chr' %&% chrom %&% '_covariances.txt'
            covariance_col <- c('GENE', 'RSID1', 'RSID2', 'VALUE')
            write(covariance_col, file = covariance_file, ncol = 4, sep = '\t')
            
            # #for testing line by line only
            # i = 1
            
            # Attempt to build model for each gene----
            for (i in 1:n_genes) {
              cat(i, "/", n_genes, "\n")
              gene <- genes[i]
              gene_name <- gene_annot$gene_name[gene_annot$gene_id == gene]
              gene_type <- get_gene_type(gene_annot, gene)
              coords <- get_gene_coords(gene_annot, gene)
              cis_gt <- get_cis_genotype(gt_df, snp_annot, coords, cis_window)
              if (all(is.na(cis_gt))) {
                # No snps within window for gene.
                model_summary <- c(chrom,gene, gene_name, gene_type, alpha, 0, 0, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA)
                write(model_summary, file = model_summary_file, append = TRUE, ncol = 25, sep = '\t')
                next
              }
              model_summary <- c(chrom,gene, gene_name, gene_type, alpha, ncol(cis_gt), 0, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA)
              if (ncol(cis_gt) >= 2) {
                # expression_vec <- expr_df[,i]
                # adj_expression <- adjust_for_covariates(expression_vec, covariates_df) #cautious using the adjust_for_covariates function because it assumes covariates and expression have same sample id order/sorting
                
                adj_expression1 <- expr_df[,i, drop = F] # use this instead of the adjust for covariates so we don't adjust twice
                
                # will try to center and scale residuals as that was done in adjust for covariates function
                adj_expression <- scale(adj_expression1, center = TRUE, scale = TRUE)
                
                adj_expression <- as.matrix(adj_expression[(rownames(adj_expression) %in% rownames(cis_gt)),])
                
                if (null_testing)
                  adj_expression <- sample(adj_expression)
                perf_measures <- nested_cv_elastic_net_perf(cis_gt, adj_expression, n_samples, n_train_test_folds, n_folds, alpha, samples)
                R2_avg <- perf_measures$R2_avg
                R2_sd <- perf_measures$R2_sd
                pval_est <- perf_measures$pval_est
                rho_avg <- perf_measures$rho_avg
                rho_se <- perf_measures$rho_se
                rho_zscore <- perf_measures$rho_zscore
                rho_avg_squared <- perf_measures$rho_avg_squared
                zscore_pval <- perf_measures$zscore_pval
                # Fit on all data
                 # Parallel
                  library(doMC)
                  registerDoMC(cores = 16)
                cv_fold_ids <- generate_fold_ids(length(adj_expression), n_folds)
                fit <- tryCatch(cv.glmnet(cis_gt, adj_expression, nfolds = n_folds, alpha = 0.5, type.measure='mse', foldid = cv_fold_ids, keep = TRUE,  parallel = TRUE),
                                error = function(cond) {message('Error'); message(geterrmessage()); list()})
                if (length(fit) > 0) {
                  cv_R2_folds <- rep(0, n_folds)
                  cv_corr_folds <- rep(0, n_folds)
                  cv_zscore_folds <- rep(0, n_folds)
                  cv_pval_folds <- rep(0, n_folds)
                  best_lam_ind <- which.min(fit$cvm)
                  for (j in 1:n_folds) {
                    fold_idxs <- which(cv_fold_ids == j)
                    adj_expr_fold_pred <- fit$fit.preval[fold_idxs, best_lam_ind]
                    cv_R2_folds[j] <- calc_R2(adj_expression[fold_idxs], adj_expr_fold_pred)
                    cv_corr_folds[j] <- ifelse(sd(adj_expr_fold_pred) != 0, cor(adj_expr_fold_pred, adj_expression[fold_idxs]), 0)
                    cv_zscore_folds[j] <- atanh(cv_corr_folds[j])*sqrt(length(adj_expression[fold_idxs]) - 3) # Fisher transformation
                    cv_pval_folds[j] <- ifelse(sd(adj_expr_fold_pred) != 0, cor.test(adj_expr_fold_pred, adj_expression[fold_idxs])$p.value, runif(1))
                  }
                  cv_R2_avg <- mean(cv_R2_folds)
                  cv_R2_sd <- sd(cv_R2_folds)
                  adj_expr_pred <- predict(fit, as.matrix(cis_gt), s = 'lambda.min')
                  training_R2 <- calc_R2(adj_expression, adj_expr_pred)
                  
                  cv_rho_avg <- mean(cv_corr_folds)
                  cv_rho_se <- sd(cv_corr_folds)
                  cv_rho_avg_squared <- cv_rho_avg**2
                  # Stouffer's method for combining z scores.
                  cv_zscore_est <- sum(cv_zscore_folds) / sqrt(n_folds)
                  cv_zscore_pval <- 2*pnorm(abs(cv_zscore_est), lower.tail = FALSE)
                  cv_pval_est <- pchisq(-2 * sum(log(cv_pval_folds)), 2*n_folds, lower.tail = F)
                  
                  if (fit$nzero[best_lam_ind] > 0) {
                    
                    weights <- fit$glmnet.fit$beta[which(fit$glmnet.fit$beta[,best_lam_ind] != 0), best_lam_ind]
                    weighted_snps <- names(fit$glmnet.fit$beta[,best_lam_ind])[which(fit$glmnet.fit$beta[,best_lam_ind] != 0)]
                    weighted_snps_info <- snp_annot %>% filter(varID %in% weighted_snps) %>% select(rsid, varID, ref_vcf, alt_vcf)
                    weighted_snps_info$gene <- gene
                    weighted_snps_info <- weighted_snps_info %>%
                      merge(data.frame(weights = weights, varID=weighted_snps), by = 'varID') %>%
                      select(gene, rsid, varID, ref_vcf, alt_vcf, weights)
                    write.table(weighted_snps_info, file = weights_file, append = TRUE, quote = FALSE, col.names = FALSE, row.names = FALSE, sep = '\t')
                    covariance_df <- do_covariance(gene, cis_gt, weighted_snps_info$rsid, weighted_snps_info$varID)
                    write.table(covariance_df, file = covariance_file, append = TRUE, quote = FALSE, col.names = FALSE, row.names = FALSE, sep = "\t")
                    model_summary <- c(chrom, gene, gene_name, gene_type, alpha, ncol(cis_gt), fit$nzero[best_lam_ind], fit$lambda[best_lam_ind], R2_avg, R2_sd, cv_R2_avg, cv_R2_sd, training_R2, pval_est,
                                       rho_avg, rho_se, rho_zscore, rho_avg_squared, zscore_pval, cv_rho_avg, cv_rho_se, cv_rho_avg_squared, cv_zscore_est, cv_zscore_pval, cv_pval_est)
                  } else {
                    model_summary <- c(chrom, gene, gene_name, gene_type, alpha, ncol(cis_gt), 0, fit$lambda[best_lam_ind], R2_avg, R2_sd,
                                       cv_R2_avg, cv_R2_sd, training_R2, pval_est, rho_avg, rho_se, rho_zscore, rho_avg_squared, zscore_pval,
                                       cv_rho_avg, cv_rho_se, cv_rho_avg_squared, cv_zscore_est, cv_zscore_pval, cv_pval_est)
                  }
                } else {
                  model_summary <- c(chrom, gene, gene_name, gene_type, alpha, ncol(cis_gt), 0, NA, R2_avg, R2_sd, NA, NA, NA, pval_est, rho_avg, rho_se, rho_zscore, rho_avg_squared, zscore_pval,
                                     NA, NA, NA, NA, NA, NA)
                }
              }
              write(model_summary, file = model_summary_file, append = TRUE, ncol = 25, sep = '\t')
            }
          }
          
          #############################################
          # 2. Define inputs and calls to run functions for each chromosome
          
          # define which chromosomes to run entered by user
          source("cwl_inputs.R")
          
          cat(chrom)
           
          snp_annot_file <- "snp_annot.chr" %&% chrom %&% ".txt"
          genotype_file <- "genotype.chr" %&% chrom %&% ".txt"
          
          summary_path <- "summary/"
          covariances_path <- "covariances/"
          weights_path <- "weights/"
          
          
          main(snp_annot_file, gene_annot_file, genotype_file, expression_file, seed=seed, maf=as.numeric(maf), n_folds=as.numeric(n_folds), n_train_test_folds=as.numeric(n_train_test_folds), alpha=as.numeric(alpha), chrom=as.numeric(chrom), prefix, summary_path, weights_path, covariances_path, cis_window=1e6, null_testing=FALSE)
          
          
          
          # Check inputs
          'maf' = maf
          'n_folds' = n_folds
          'n_train_test_folds' = n_train_test_folds
          'alpha' = alpha
          'seed' = seed
          
          
      - entryname: elnet.sh
        writable: false
        entry: |2-

          mkdir summary
          mkdir weights
          mkdir covariances

          Rscript gtex_v7_nested_cv_elnet_training_combined.R
      - entryname: cwl_inputs.R
        writable: false
        entry: |2

          chrom = $(inputs.chr_list)

          gene_annot_file = "$(inputs.gene_annotation.path)"
          expression_file = "$(inputs.adjusted_expression_file.path)"

          expression_path = "$(inputs.adjusted_expression_file.path)"


          pop_name = "$(inputs.population_name)"
          tiss_name = "$(inputs.tissue_name)"
          prefix = "$(inputs.model_prefix)"
          seed = "$(inputs.seed)"
          maf = "$(inputs.MAF)"
          n_folds = "$(inputs.n_folds)"
          n_train_test_folds = "$(inputs.n_train_test_folds)"
          alpha =  "$(inputs.alpha)"
      - $(inputs.snp_annotation)
      - $(inputs.genotype_file)
    - class: InlineJavascriptRequirement

    inputs:
    - id: population_name
      doc: Population from which the samples originated from.
      type: string
    - id: tissue_name
      doc: The tissue the expression was measured in
      type: string
    - id: gene_annotation
      type: File
    - id: snp_annotation
      type: File[]
    - id: genotype_file
      type: File[]
    - id: adjusted_expression_file
      doc: |-
        Expression was adjusted by performing a multivariate linear regression with all covariates, pulling the residual values, and then assigning the residuals to be the new expression values.
      type: File
    - id: chr_list
      doc: |-
        Enter the chromosome number for which you want to perform the nested elastic models for every gene in that desired chromosome. Please enter at least 1 chromosome and each chromosome will be in its own line.
      type: string[]
    - id: model_prefix
      doc: |-
        This prefix will be added to the beginning of all the summary, covariance, and weights files produced.
      type: string?
      default: '"Model_Training"'
    - id: seed
      type: int?
    - id: MAF
      type: float?
      default: 0.01
    - id: n_folds
      type: int?
      default: 10
    - id: n_train_test_folds
      type: int?
      default: 5
    - id: alpha
      doc: |-
        The alpha parameter used with the R package glmnet to train the elastic net model.
      type: float?
      default: 0.5
    - id: RAM
      doc: In  MB
      type: int?

    outputs:
    - id: weights
      type: File[]?
      outputBinding:
        glob: weights/*
    - id: covariances
      type: File[]?
      outputBinding:
        glob: covariances/*
    - id: summary
      type: File[]?
      outputBinding:
        glob: summary/*
    stdout: standard.out

    baseCommand:
    - bash elnet.sh

    hints:
    - class: sbg:SaveLogs
      value: '*.R'
    - class: sbg:SaveLogs
      value: '*.sh'
    - class: sbg:SaveLogs
      value: '*.Rda'
    - class: sbg:SaveLogs
      value: standard.out
    id: rk.johnson/predictdb-development/model-creation/50
    sbg:appVersion:
    - v1.2
    sbg:content_hash: aad4bc0e7fb2c2a61018ba625032577ab38ad53175d960ebba651ac3f19a103f3
    sbg:contributors:
    - e.esquinca
    sbg:createdBy: e.esquinca
    sbg:createdOn: 1613684407
    sbg:id: rk.johnson/predictdb-development/model-creation/50
    sbg:image_url:
    sbg:latestRevision: 50
    sbg:modifiedBy: e.esquinca
    sbg:modifiedOn: 1628791479
    sbg:project: rk.johnson/predictdb-development
    sbg:projectName: Predictdb Development
    sbg:publisher: sbg
    sbg:revision: 50
    sbg:revisionNotes: ''
    sbg:revisionsInfo:
    - sbg:modifiedBy: e.esquinca
      sbg:modifiedOn: 1613684407
      sbg:revision: 0
      sbg:revisionNotes: Copy of rk.johnson/predictdb/model-creation/47
    - sbg:modifiedBy: e.esquinca
      sbg:modifiedOn: 1613684552
      sbg:revision: 1
      sbg:revisionNotes: edited script
    - sbg:modifiedBy: e.esquinca
      sbg:modifiedOn: 1613684971
      sbg:revision: 2
      sbg:revisionNotes: adjusted expression file input in cwl
    - sbg:modifiedBy: e.esquinca
      sbg:modifiedOn: 1613685129
      sbg:revision: 3
      sbg:revisionNotes: add code to part 3
    - sbg:modifiedBy: e.esquinca
      sbg:modifiedOn: 1613685196
      sbg:revision: 4
      sbg:revisionNotes: change name to know the difference
    - sbg:modifiedBy: e.esquinca
      sbg:modifiedOn: 1613687567
      sbg:revision: 5
      sbg:revisionNotes: ''
    - sbg:modifiedBy: e.esquinca
      sbg:modifiedOn: 1613689092
      sbg:revision: 6
      sbg:revisionNotes: ''
    - sbg:modifiedBy: e.esquinca
      sbg:modifiedOn: 1614021874
      sbg:revision: 7
      sbg:revisionNotes: took out adjusting twice for covariates
    - sbg:modifiedBy: e.esquinca
      sbg:modifiedOn: 1614040923
      sbg:revision: 8
      sbg:revisionNotes: fixed seed to 2421 for comparison
    - sbg:modifiedBy: e.esquinca
      sbg:modifiedOn: 1614042657
      sbg:revision: 9
      sbg:revisionNotes: same edit as last time
    - sbg:modifiedBy: e.esquinca
      sbg:modifiedOn: 1614101174
      sbg:revision: 10
      sbg:revisionNotes: removed lapply
    - sbg:modifiedBy: e.esquinca
      sbg:modifiedOn: 1614111498
      sbg:revision: 11
      sbg:revisionNotes: ''
    - sbg:modifiedBy: e.esquinca
      sbg:modifiedOn: 1614111556
      sbg:revision: 12
      sbg:revisionNotes: readded double adjust line 235
    - sbg:modifiedBy: e.esquinca
      sbg:modifiedOn: 1614484814
      sbg:revision: 13
      sbg:revisionNotes: remove adjust for covariates
    - sbg:modifiedBy: e.esquinca
      sbg:modifiedOn: 1614488470
      sbg:revision: 14
      sbg:revisionNotes: ''
    - sbg:modifiedBy: e.esquinca
      sbg:modifiedOn: 1614489468
      sbg:revision: 15
      sbg:revisionNotes: cleaned up script
    - sbg:modifiedBy: e.esquinca
      sbg:modifiedOn: 1614489471
      sbg:revision: 16
      sbg:revisionNotes: ''
    - sbg:modifiedBy: e.esquinca
      sbg:modifiedOn: 1614489558
      sbg:revision: 17
      sbg:revisionNotes: ''
    - sbg:modifiedBy: e.esquinca
      sbg:modifiedOn: 1614527381
      sbg:revision: 18
      sbg:revisionNotes: added back in adjust for covariates
    - sbg:modifiedBy: e.esquinca
      sbg:modifiedOn: 1614640295
      sbg:revision: 19
      sbg:revisionNotes: removed adjust for covariates
    - sbg:modifiedBy: e.esquinca
      sbg:modifiedOn: 1614705235
      sbg:revision: 20
      sbg:revisionNotes: scale and center
    - sbg:modifiedBy: e.esquinca
      sbg:modifiedOn: 1614799550
      sbg:revision: 21
      sbg:revisionNotes: updated script so sample ID's match
    - sbg:modifiedBy: e.esquinca
      sbg:modifiedOn: 1614829387
      sbg:revision: 22
      sbg:revisionNotes: set same seed
    - sbg:modifiedBy: e.esquinca
      sbg:modifiedOn: 1614833511
      sbg:revision: 23
      sbg:revisionNotes: ''
    - sbg:modifiedBy: e.esquinca
      sbg:modifiedOn: 1614833563
      sbg:revision: 24
      sbg:revisionNotes: ''
    - sbg:modifiedBy: e.esquinca
      sbg:modifiedOn: 1617211818
      sbg:revision: 25
      sbg:revisionNotes: ''
    - sbg:modifiedBy: e.esquinca
      sbg:modifiedOn: 1617649134
      sbg:revision: 26
      sbg:revisionNotes: added parallel code
    - sbg:modifiedBy: e.esquinca
      sbg:modifiedOn: 1617649340
      sbg:revision: 27
      sbg:revisionNotes: update parallel code
    - sbg:modifiedBy: e.esquinca
      sbg:modifiedOn: 1617649553
      sbg:revision: 28
      sbg:revisionNotes: added extra ports
    - sbg:modifiedBy: e.esquinca
      sbg:modifiedOn: 1617650205
      sbg:revision: 29
      sbg:revisionNotes: added extra ports
    - sbg:modifiedBy: e.esquinca
      sbg:modifiedOn: 1617650690
      sbg:revision: 30
      sbg:revisionNotes: Added some descriptions
    - sbg:modifiedBy: e.esquinca
      sbg:modifiedOn: 1617650857
      sbg:revision: 31
      sbg:revisionNotes: Updated app info
    - sbg:modifiedBy: e.esquinca
      sbg:modifiedOn: 1617651437
      sbg:revision: 32
      sbg:revisionNotes: ''
    - sbg:modifiedBy: e.esquinca
      sbg:modifiedOn: 1617651542
      sbg:revision: 33
      sbg:revisionNotes: delete unnecessary
    - sbg:modifiedBy: e.esquinca
      sbg:modifiedOn: 1617821262
      sbg:revision: 34
      sbg:revisionNotes: added chrom column for analysis
    - sbg:modifiedBy: e.esquinca
      sbg:modifiedOn: 1617821440
      sbg:revision: 35
      sbg:revisionNotes: ''
    - sbg:modifiedBy: e.esquinca
      sbg:modifiedOn: 1617834672
      sbg:revision: 36
      sbg:revisionNotes: ''
    - sbg:modifiedBy: e.esquinca
      sbg:modifiedOn: 1617899297
      sbg:revision: 37
      sbg:revisionNotes: ''
    - sbg:modifiedBy: e.esquinca
      sbg:modifiedOn: 1618432345
      sbg:revision: 38
      sbg:revisionNotes: ''
    - sbg:modifiedBy: e.esquinca
      sbg:modifiedOn: 1618631011
      sbg:revision: 39
      sbg:revisionNotes: Remove Covariates file
    - sbg:modifiedBy: e.esquinca
      sbg:modifiedOn: 1618631210
      sbg:revision: 40
      sbg:revisionNotes: Edited Readme
    - sbg:modifiedBy: e.esquinca
      sbg:modifiedOn: 1618663885
      sbg:revision: 41
      sbg:revisionNotes: remove covariates file path
    - sbg:modifiedBy: e.esquinca
      sbg:modifiedOn: 1618803112
      sbg:revision: 42
      sbg:revisionNotes: remove covariates file in main
    - sbg:modifiedBy: e.esquinca
      sbg:modifiedOn: 1618803456
      sbg:revision: 43
      sbg:revisionNotes: remove all covariate code
    - sbg:modifiedBy: e.esquinca
      sbg:modifiedOn: 1618804194
      sbg:revision: 44
      sbg:revisionNotes: edit inputs
    - sbg:modifiedBy: e.esquinca
      sbg:modifiedOn: 1618810016
      sbg:revision: 45
      sbg:revisionNotes: edit inputs
    - sbg:modifiedBy: e.esquinca
      sbg:modifiedOn: 1618861365
      sbg:revision: 46
      sbg:revisionNotes: remove coriate code
    - sbg:modifiedBy: e.esquinca
      sbg:modifiedOn: 1618873969
      sbg:revision: 47
      sbg:revisionNotes: ''
    - sbg:modifiedBy: e.esquinca
      sbg:modifiedOn: 1618874013
      sbg:revision: 48
      sbg:revisionNotes: ''
    - sbg:modifiedBy: e.esquinca
      sbg:modifiedOn: 1628790945
      sbg:revision: 49
      sbg:revisionNotes: added descriptions
    - sbg:modifiedBy: e.esquinca
      sbg:modifiedOn: 1628791479
      sbg:revision: 50
      sbg:revisionNotes: ''
    sbg:sbgMaintained: false
    sbg:validationErrors: []
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
  run:
    cwlVersion: v1.2
    class: CommandLineTool
    label: Database_Summary
    doc: |-
      After the Nested Elastic Net Models are run for each chromosome, we take the summary, covariance, and weights file. 
      Combine models for all chromosomes entered in one database file. Then the database will be filtered for use in PrediXcan
    $namespaces:
      sbg: https://sevenbridges.com

    requirements:
    - class: LoadListingRequirement
    - class: DockerRequirement
      dockerPull: images.sb.biodatacatalyst.nhlbi.nih.gov/dave/predictdb:v2021_02_13
    - class: InitialWorkDirRequirement
      listing:
      - entryname: summary.R
        writable: false
        entry: |
          #############################################
          suppressMessages(library(dplyr))
          suppressMessages(library(glmnet))
          suppressMessages((library(reshape2)))
          suppressMessages(library(methods))
          suppressMessages(library(RSQLite))
          suppressMessages(library(data.table))

          "%&%" <- function(a,b) paste(a,b, sep='')

          # 3. Combine summaries of all chromosomes, and create database of results

          summary_path <- "summary/"
          covariances_path <- "covariances/"
          weights_path <- "weights/"

          source("cwl_inputs.R")



          driver <- dbDriver('SQLite')

          filenames = list.files(path = summary_path, pattern = "*_model_summaries.txt", full.names = TRUE)
          model_summaries <- rbindlist(lapply(filenames, fread))

          filenames2 =list.files(path = summary_path, pattern = "*_summary.txt", full.names = TRUE)
          tiss_summary = rbindlist(lapply(filenames2, fread))

          n_samples = unique(tiss_summary$n_samples)

          model_summaries <- rename(model_summaries, gene = gene_id)
          conn <- dbConnect(drv = driver, 'dbs/'%&%pop_name%&%'_'%&%tiss_name%&%'_ncvelnet_'%&%n_samples%&% '.db')
          dbWriteTable(conn, 'model_summaries', model_summaries, overwrite = TRUE)
          dbExecute(conn, "CREATE INDEX gene_model_summary ON model_summaries (gene)")

          # Weights Table -----
          filenames3 = list.files(path = weights_path, pattern = "*_weights.txt", full.names = TRUE)
          weights = rbindlist(lapply(filenames3, fread))
          weights <- rename(weights, gene = gene_id)
          dbWriteTable(conn, 'weights', weights, overwrite = TRUE)
          dbExecute(conn, "CREATE INDEX weights_rsid ON weights (rsid)")
          dbExecute(conn, "CREATE INDEX weights_gene ON weights (gene)")
          dbExecute(conn, "CREATE INDEX weights_rsid_gene ON weights (rsid, gene)")

          # Sample_info Table ----
          sample_info <- data.frame(n_samples = n_samples, population = pop_name, tissue = tiss_name)
          dbWriteTable(conn, 'sample_info', sample_info, overwrite = TRUE)

          # Construction Table ----
          construction <- tiss_summary %>%
            select(chrom, cv_seed) %>%
            rename(chromosome = chrom)
          dbWriteTable(conn, 'construction', construction, overwrite = TRUE)
          dbDisconnect(conn)



          # Filter the databases to get significant values
          unfiltered_db <- 'dbs/' %&% pop_name %&% '_' %&% tiss_name %&% '_ncvelnet_' %&% n_samples %&%  '.db'
          filtered_db <-  'dbs/' %&% pop_name %&% '_' %&% tiss_name %&% '_ncvelnet_' %&% n_samples %&% '_filtered_signif' %&% '.db'

          in_conn <- dbConnect(driver, unfiltered_db)
          out_conn <- dbConnect(driver, filtered_db)

          model_summaries <- dbGetQuery(in_conn, 'select * from model_summaries where zscore_pval < 0.05 and rho_avg_squared > 0.01')
          model_summaries <- model_summaries %>% 
            rename(pred.perf.R2 = rho_avg_squared, genename = gene_name, pred.perf.pval = zscore_pval, n.snps.in.model = n_snps_in_model)
          model_summaries$pred.perf.qval <- NA
          dbWriteTable(out_conn, 'extra', model_summaries, overwrite = TRUE)

          construction <- dbGetQuery(in_conn, 'select * from construction')
          dbWriteTable(out_conn, 'construction', construction, overwrite = TRUE)

          sample_info <- dbGetQuery(in_conn, 'select * from sample_info')
          dbWriteTable(out_conn, 'sample_info', sample_info, overwrite = TRUE)

          weights <- dbGetQuery(in_conn, 'select * from weights')
          weights <- weights %>%
              filter(gene %in% model_summaries$gene) %>%
              rename(eff_allele = alt, ref_allele = ref, weight = beta)
          dbWriteTable(out_conn, 'weights', weights, overwrite = TRUE)

          dbExecute(out_conn, "CREATE INDEX weights_rsid ON weights (rsid)")
          dbExecute(out_conn, "CREATE INDEX weights_gene ON weights (gene)")
          dbExecute(out_conn, "CREATE INDEX weights_rsid_gene ON weights (rsid, gene)")
          dbExecute(out_conn, "CREATE INDEX gene_model_summary ON extra (gene)")

          dbDisconnect(in_conn)
          dbDisconnect(out_conn)
      - entryname: cwl_inputs.R
        writable: false
        entry: "pop_name = \"$(inputs.population_name)\"\ntiss_name = \"$(inputs.tissue_name)\""
      - entryname: summary.sh
        writable: false
        entry: |-
          mkdir dbs
          mkdir weights
          mkdir summary
          mkdir covariances

          mv *weights.txt weights
          mv *model_summaries.txt summary
          mv *_summary.txt summary
          mv *covariances.txt covariances

          Rscript summary.R
      - $(inputs.summary)
      - $(inputs.covariances)
      - $(inputs.weights)
    - class: InlineJavascriptRequirement

    inputs:
    - id: population_name
      doc: Population from which the samples originated from.
      type: string
    - id: tissue_name
      doc: The tissue the expression was measured in
      type: string
    - id: summary
      doc: |-
        Summary files from the Nested Elastic Net Models split by chromosome that output from the tool.
      type: File[]
    - id: covariances
      doc: |-
        Covariance files from the Nested Elastic Net Models split by chromosome that output from the tool.
      type: File[]
    - id: weights
      doc: |-
        Weight files from the Nested Elastic Net Models split by chromosome that output from the tool.
      type: File[]

    outputs:
    - id: db_output
      type: File[]?
      outputBinding:
        glob: dbs/*.db
    stdout: standard.out

    baseCommand:
    - bash summary.sh

    hints:
    - class: sbg:SaveLogs
      value: '*.R'
    - class: sbg:SaveLogs
      value: '*.Rda'
    - class: sbg:SaveLogs
      value: '*.sh'
    - class: sbg:SaveLogs
      value: standard.out
    id: rk.johnson/predictdb/database-summary/33
    sbg:appVersion:
    - v1.2
    sbg:content_hash: af62c9ec347cc1e56438178451672aa86dcaa7d281216ac9132e00b6d13876ddb
    sbg:contributors:
    - dave
    - e.esquinca
    sbg:createdBy: e.esquinca
    sbg:createdOn: 1612889428
    sbg:id: rk.johnson/predictdb/database-summary/33
    sbg:image_url:
    sbg:latestRevision: 33
    sbg:modifiedBy: e.esquinca
    sbg:modifiedOn: 1628791365
    sbg:project: rk.johnson/predictdb
    sbg:projectName: predictdb
    sbg:publisher: sbg
    sbg:revision: 33
    sbg:revisionNotes: ''
    sbg:revisionsInfo:
    - sbg:modifiedBy: e.esquinca
      sbg:modifiedOn: 1612889428
      sbg:revision: 0
      sbg:revisionNotes:
    - sbg:modifiedBy: e.esquinca
      sbg:modifiedOn: 1612889505
      sbg:revision: 1
      sbg:revisionNotes: ''
    - sbg:modifiedBy: e.esquinca
      sbg:modifiedOn: 1613688240
      sbg:revision: 2
      sbg:revisionNotes: added inputs
    - sbg:modifiedBy: e.esquinca
      sbg:modifiedOn: 1613688788
      sbg:revision: 3
      sbg:revisionNotes: ''
    - sbg:modifiedBy: e.esquinca
      sbg:modifiedOn: 1613688926
      sbg:revision: 4
      sbg:revisionNotes: added directories from previous tool
    - sbg:modifiedBy: dave
      sbg:modifiedOn: 1613752519
      sbg:revision: 5
      sbg:revisionNotes: ''
    - sbg:modifiedBy: dave
      sbg:modifiedOn: 1613752825
      sbg:revision: 6
      sbg:revisionNotes: ''
    - sbg:modifiedBy: dave
      sbg:modifiedOn: 1613753925
      sbg:revision: 7
      sbg:revisionNotes: mv
    - sbg:modifiedBy: e.esquinca
      sbg:modifiedOn: 1613760110
      sbg:revision: 8
      sbg:revisionNotes: added library
    - sbg:modifiedBy: e.esquinca
      sbg:modifiedOn: 1613762514
      sbg:revision: 9
      sbg:revisionNotes: ''
    - sbg:modifiedBy: dave
      sbg:modifiedOn: 1613769966
      sbg:revision: 10
      sbg:revisionNotes: removed unnecessary args files from command line.
    - sbg:modifiedBy: dave
      sbg:modifiedOn: 1613769968
      sbg:revision: 11
      sbg:revisionNotes: ''
    - sbg:modifiedBy: dave
      sbg:modifiedOn: 1613770124
      sbg:revision: 12
      sbg:revisionNotes: ''
    - sbg:modifiedBy: e.esquinca
      sbg:modifiedOn: 1614109689
      sbg:revision: 13
      sbg:revisionNotes: added dbs/
    - sbg:modifiedBy: e.esquinca
      sbg:modifiedOn: 1614109953
      sbg:revision: 14
      sbg:revisionNotes: ''
    - sbg:modifiedBy: e.esquinca
      sbg:modifiedOn: 1614187886
      sbg:revision: 15
      sbg:revisionNotes: commented out code
    - sbg:modifiedBy: e.esquinca
      sbg:modifiedOn: 1614188620
      sbg:revision: 16
      sbg:revisionNotes: save logs
    - sbg:modifiedBy: e.esquinca
      sbg:modifiedOn: 1614188724
      sbg:revision: 17
      sbg:revisionNotes: ''
    - sbg:modifiedBy: e.esquinca
      sbg:modifiedOn: 1614189634
      sbg:revision: 18
      sbg:revisionNotes: ''
    - sbg:modifiedBy: e.esquinca
      sbg:modifiedOn: 1614190553
      sbg:revision: 19
      sbg:revisionNotes: ''
    - sbg:modifiedBy: e.esquinca
      sbg:modifiedOn: 1614192972
      sbg:revision: 20
      sbg:revisionNotes: ''
    - sbg:modifiedBy: e.esquinca
      sbg:modifiedOn: 1614194099
      sbg:revision: 21
      sbg:revisionNotes: ''
    - sbg:modifiedBy: e.esquinca
      sbg:modifiedOn: 1614194811
      sbg:revision: 22
      sbg:revisionNotes: ''
    - sbg:modifiedBy: e.esquinca
      sbg:modifiedOn: 1614195226
      sbg:revision: 23
      sbg:revisionNotes: ''
    - sbg:modifiedBy: e.esquinca
      sbg:modifiedOn: 1614195711
      sbg:revision: 24
      sbg:revisionNotes: ''
    - sbg:modifiedBy: e.esquinca
      sbg:modifiedOn: 1614262773
      sbg:revision: 25
      sbg:revisionNotes: ''
    - sbg:modifiedBy: dave
      sbg:modifiedOn: 1614277370
      sbg:revision: 26
      sbg:revisionNotes: fixing dbs output
    - sbg:modifiedBy: dave
      sbg:modifiedOn: 1614277382
      sbg:revision: 27
      sbg:revisionNotes: ''
    - sbg:modifiedBy: e.esquinca
      sbg:modifiedOn: 1617821777
      sbg:revision: 28
      sbg:revisionNotes: changed t0 (rho_avg_squared) > 0.01
    - sbg:modifiedBy: e.esquinca
      sbg:modifiedOn: 1619632116
      sbg:revision: 29
      sbg:revisionNotes: rename databases
    - sbg:modifiedBy: e.esquinca
      sbg:modifiedOn: 1619647551
      sbg:revision: 30
      sbg:revisionNotes: update name
    - sbg:modifiedBy: e.esquinca
      sbg:modifiedOn: 1621981733
      sbg:revision: 31
      sbg:revisionNotes: ''
    - sbg:modifiedBy: e.esquinca
      sbg:modifiedOn: 1622131779
      sbg:revision: 32
      sbg:revisionNotes: ''
    - sbg:modifiedBy: e.esquinca
      sbg:modifiedOn: 1628791365
      sbg:revision: 33
      sbg:revisionNotes: ''
    sbg:sbgMaintained: false
    sbg:validationErrors: []
  out:
  - id: db_output
  sbg:x: 844.292236328125
  sbg:y: -175.3652801513672
id: |-
  https://api.sb.biodatacatalyst.nhlbi.nih.gov/v2/apps/rk.johnson/predictdb/predictdb-split-by-chromsome/55/raw/
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
