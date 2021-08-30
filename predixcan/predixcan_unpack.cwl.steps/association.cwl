cwlVersion: v1.2
class: CommandLineTool
label: Association
$namespaces:
  sbg: https://sevenbridges.com

requirements:
- class: ShellCommandRequirement
- class: DockerRequirement
  dockerPull: r-base
- class: InitialWorkDirRequirement
  listing:
  - entryname: Lmekin_Code.R
    writable: false
    entry: |-
      # Lmekin & Lm Code
      
      # Erika Esquinca
      # Last Modified: 8/29/21
      
      
      install.packages("coxme")
      install.packages("dplyr")
      install.packages("data.table")
      install.packages("optparse")
      
      # Load libraries 
      library(coxme, quietly = T)
      library(dplyr, quietly = T)
      library(data.table, quietly = T)
      library(optparse, quietly = T)
      
      # Generate usage doc and retrieve command line args
      
      p <- OptionParser(usage = "\n%prog [options] --gene_expression_file <gene_expression_file> --output_prefix <output_prefix>                  --phenotype_file <phenotype_file>",
                        description = "\n Association of Predicted Gene Expression Values)\n\nRun the association using the R interface.",
                        prog = "Rscript Lmekin_Code.R")
      
      p <- add_option(object = p, opt_str = c("--output_prefix"), default = NULL, type = "character",
                      help = "[REQUIRED] File name prefix for output files.")
      
      p <- add_option(object = p, opt_str = c("--gene_expression_file"), default = NULL, type = "character",
                      help = "[REQUIRED] A text delimited file with .txt file extension containing N + 1 rows and G + 2 columns, where N is the number of samples, and G is the number of genes. The first row must contain the headers and the first two columns contain the Individual ID (IID) & the Family ID (FID) followed by genes respectively. Should be the predict output from Predict.py. If there is not FID repeat the IID column.")
      
      p <- add_option(object = p, opt_str = c("--phenotype_file"),
                      help = "[REQUIRED] A text delimited file with a .txt file extension containing a matrix of size M + 1 × C + 1, where M >= N and is the number of samples for which covariate data is provided.")
      
      
      p <- add_option(object = p, opt_str = c("--kinship_matrix"),
                      help = "A text delimited file with a .txt file extension or an R data file with a .RData file extension containing a matrix of size M × M, where rows and columns are the sample/subject IDs")
      
      argv <- parse_args(p)
      
      
      # Check if positional arguments were given 
      if(is.null(argv$gene_expression_file)){
        stop("Error: Please provide a value for --gene_expression_file")
      }
      if(is.null(argv$output_prefix)){
        stop("Error: Please provide a value for --output_prefix")
      }
      if(is.null(argv$phenotype_file)){
        stop("Error: Please provide a value for --phenotype_file")
      }
      
      
      # Get inputs from user
      source("cwl_inputs.R")
      
      # Load Gene Expression Data
      cat(paste0("Loading data from ", argv$gene_expression_file, " ..."))
      ge.data <- read.table(file = argv$gene_expression_file, sep = "\t", header = T)
      
      n.samples <- nrow(ge.data)
      n.features <- ncol(ge.data)
      cat("Done.\n")
      cat(paste0("Loaded gene expression data with ", n.samples, " rows and ", 
                 n.features, " genes.\n"))
      
      
      # Load Phenotype file
      cat(paste0("Loading data from ", argv$phenotype_file, " ..."))
      
      pheno.data <- read.table(file = argv$phenotype_file, sep = "\t", header = T)
      cat("Done.\n")
      #cat(paste0("Loaded phenotype data with ", blank, " rows and ", 
      #           blank, " columns.\n"))
      
      
      
      ## STEPS
      
      #### inner_join gene expression and phenotypes both should have IID column
      
      data <- inner_join(pheno.data, ge.data, by = "IID")
      
      # Set blanks to NA
      data[data == ""] <- NA
      
      
      ### Define these in the function
      # gene_names = the list of gene names that the function iterates over
      # covs = list of covariates
      # main_pheno = name of main association variable
      # df = data frame including the samples down the rows, and phenotype variables followed by gene names across the columns
      # id = name of person/sample ID variable that matches between the ge.data, pheno.data, and kinship matrix
      # kinship = the kinship matrix if given will do lmekin instead of lm
      
      
      # List of tests we want to make
      # ie: names of gene columns, this is what we're looping over in the function
      # If there's time I will make this an additonal input
      
      genes <- colnames(ge.data)[3:ncol(ge.data)] 
      
      
      ##########################################################
      # Now if a kinship matrix is included we want to use lmekin
      #
      if(!is.null(argv$kinship_matrix)){
        
        # Load Kinship Matrix
        if(grepl(x = argv$kinship_matrix, pattern = "\\.RData$", perl = T)){ 
          load(argv$kinship_matrix)
        }
        
        if(grepl(x = argv$kinship_matrix, pattern = "\\.txt$", perl = T)){
          
          kin <-  read.table(file = argv$kinship_matrix, sep = "\t", header = T,
                             row.names = 1)
        }
      
      
      # lmekin function
      lmekin.script = function(gene_names, covs, main_pheno, df, id, kinship){
        
        # Define model formula
        fml <- as.formula(paste0(gene_names,"~",paste0(main_pheno,"+"), paste0(covs,collapse="+"),"+ (1|",id,")"))
        
        # FYI second way to generate formula
        #form = reformulate(c(main, covs,"(1|numberID)"), response = g)
        
        #run linear mixed model and save model output
        mod = coxme::lmekin(fml, data=df, varlist = as.matrix(kinship))
        
        #define model output for writing out results
        # note that we are saving the first variable in the table only, so will only work for a dichotomous or continuous phenotype. 
        # If someone used a categorical variable with more than 2 levels, they would only get the first row of estimates as currently coded.
        
        beta <- as.numeric(mod$coefficients$fixed)  
        nvar <- length(beta)
        nfrail <- nrow(mod$var) - nvar
        se <- as.numeric(sqrt(diag(mod$var)[nfrail + 1:nvar]))
        z <- as.numeric(round(beta/se, 5))
        p <- as.numeric(signif(1-pchisq((beta/se)^2,1), 5))
        n <- mod$n
        
        beta.lme = as.numeric(beta[2])
        se.lme = as.numeric(se[2])
        z.lme = as.numeric(z[2])
        pval.lme = as.numeric(p[2])
        covariates = paste(covs,collapse=",")
        
        results = data.frame(gene_names, n, main_pheno, covariates, beta.lme, se.lme, z.lme, pval.lme)
        
        return(results)
      }
      
      
      # Call function, define function parameters, and create output data frame in two steps
      results.list = lapply(X = genes, FUN = lmekin.script,
                            covs = covs_input,
                            main_pheno = main_pheno_input,
                            df=data,
                            id="numberID",
                            kinship=kin)
      results = dplyr::bind_rows(results.list)
      
      
      
      # Write Results
      cat("Exporting results ... ")
      write.table(results, file = paste0(argv$output_prefix, "_lmekin_results.txt"),
                  col.names = T,
                  row.names = F,
                  quote = F,
                  sep = "\t")
      cat("Done.\n")
      
      }
      
      # If no kinship matrix is included, use lm 
      if(is.null(argv$kinship_matrix)){
        
        # Make sure main pheno is factor to be categorical in lm; required in description
      
        lm.script = function(gene_names, covs, main_pheno, df){
          
          # Define model formula
          fml <- as.formula(paste0(gene_names,"~",paste0(main_pheno,"+"), paste0(covs,collapse="+")))
        
          
          #run linear mixed model and save model output
          # Will automatically make smallest number reference category
          mod = lm(fml, data=df)
          
          #define model output for writing out results
          # note that we are saving the first variable in the table only, so will only work for a dichotomous or continuous phenotype. 
          # If someone used a categorical variable with more than 2 levels, they would only get the first row of estimates as currently coded.
          
          beta.lm <- as.numeric(mod$coefficients[2])  
          se.lm <- as.numeric(summary(mod)$coefficients[2,2])
          t.lm<- as.numeric(summary(mod)$coefficients[2,3])
          pval.lm <- as.numeric(summary(mod)$coefficients[2,4])
          covariates = paste(covs,collapse=",")
          n <- nobs(mod)
          
          results = data.frame(gene_names, n, main_pheno, covariates, beta.lm, se.lm, t.lm, pval.lm)
          
          return(results)
        }
        
        
        # Call function, define function parameters, and create output data frame in two steps
        results.list = lapply(X = genes, FUN = lm.script,
                              covs = covs_input,
                              main_pheno = main_pheno_input,
                              df=data)
        results = dplyr::bind_rows(results.list)
        
        
        
        # Write Results
        cat("Exporting results ... ")
        write.table(results, file = paste0(argv$output_prefix, "_lm_results.txt"),
                    col.names = T,
                    row.names = F,
                    quote = F,
                    sep = "\t")
        cat("Done.\n")   
        
        
      }
  - entryname: cwl_inputs.R
    writable: false
    entry: |2-

      covs_input = c($(inputs.covariates))

      main_pheno_input = "$(inputs.main_phenotype_of_interest)"
- class: InlineJavascriptRequirement

inputs:
- id: gene_expression_file
  doc: |-
    [REQUIRED] A text delimited file with .txt file extension containing N + 1 rows and G + 2 columns, where N is the number of samples, and G is the number of genes. The first row must contain sample IDs and the first two columns contain the IID & FID followed by feature IDs respectively. Should be the predict output from Predict.py

    Make sure phenotype file and gene expression file have matching IID column.
  type: File
  inputBinding:
    prefix: --gene_expression_file
    position: 0
    shellQuote: false
- id: main_phenotype_of_interest
  doc: |-
    [REQUIRED] A string value defining the column name of the phenotype of interest. Should be a dichotomous or continuous variable. Please enter in exactly as it appears in phenotype file not surrounded by quotations. 
    ex) main_interest

    If dichotomous, make sure that in the file the main phenotype of interest is coded as a categorical variable where 0 is absence and 1 is presence of phenotype of interest. 0 will then be the reference and the output will reflect this.
  type: string
- id: output_prefix
  doc: '[REQUIRED] File name prefix for output files.'
  type: string
  inputBinding:
    prefix: --output_prefix
    position: 0
    shellQuote: false
- id: kinship_matrix
  doc: |-
    A text delimited file with a .txt file extension or an R data file with a .RData file extension containing a matrix of size M × M, where rows and columns are the sample/subject IDs
  type: File?
  inputBinding:
    prefix: --kinship_matrix
    position: 0
    shellQuote: false
- id: phenotype_file
  doc: |-
    [REQUIRED] A text delimited file with a .txt file extension containing a matrix of size M + 1 × C + 1, where M >= N and is the number of samples for which covariate data is provided.

    Make sure phenotype file and gene expression file have matching IID column.
  type: File
  inputBinding:
    prefix: --phenotype_file
    position: 0
    shellQuote: false
- id: covariates
  doc: |-
    Please type in the column names of any additional covariates you would like to account for. Please input covariates exactly as they appear in the phenotype file with quotations around each input and separate by a comma, no spaces.
    ex) "sex","age","PC1"
  type: string

outputs:
- id: Association_output
  type: File
  outputBinding:
    glob: '*_results.txt'

baseCommand:
- Rscript
- Lmekin_Code.R

hints:
- class: sbg:SaveLogs
  value: '*.R'
- class: sbg:SaveLogs
  value: standard.out
id: e.esquinca/individual-level-predixcan-development/association/50
sbg:appVersion:
- v1.2
sbg:content_hash: ad03370641e4d2de6f09d43135d407b6ce3cfba5991d8ad578a6c89f4b9e03706
sbg:contributors:
- e.esquinca
sbg:createdBy: e.esquinca
sbg:createdOn: 1625775902
sbg:id: e.esquinca/individual-level-predixcan-development/association/50
sbg:image_url:
sbg:latestRevision: 50
sbg:modifiedBy: e.esquinca
sbg:modifiedOn: 1630283238
sbg:project: e.esquinca/individual-level-predixcan-development
sbg:projectName: 'BUILD: Individual Level PrediXcan Development'
sbg:publisher: sbg
sbg:revision: 50
sbg:revisionNotes: ''
sbg:revisionsInfo:
- sbg:modifiedBy: e.esquinca
  sbg:modifiedOn: 1625775902
  sbg:revision: 0
  sbg:revisionNotes:
- sbg:modifiedBy: e.esquinca
  sbg:modifiedOn: 1625777612
  sbg:revision: 1
  sbg:revisionNotes: ''
- sbg:modifiedBy: e.esquinca
  sbg:modifiedOn: 1625778258
  sbg:revision: 2
  sbg:revisionNotes: ''
- sbg:modifiedBy: e.esquinca
  sbg:modifiedOn: 1625779281
  sbg:revision: 3
  sbg:revisionNotes: ''
- sbg:modifiedBy: e.esquinca
  sbg:modifiedOn: 1625780462
  sbg:revision: 4
  sbg:revisionNotes: ''
- sbg:modifiedBy: e.esquinca
  sbg:modifiedOn: 1625781379
  sbg:revision: 5
  sbg:revisionNotes: ''
- sbg:modifiedBy: e.esquinca
  sbg:modifiedOn: 1625784170
  sbg:revision: 6
  sbg:revisionNotes: ''
- sbg:modifiedBy: e.esquinca
  sbg:modifiedOn: 1626283266
  sbg:revision: 7
  sbg:revisionNotes: ''
- sbg:modifiedBy: e.esquinca
  sbg:modifiedOn: 1626283409
  sbg:revision: 8
  sbg:revisionNotes: ''
- sbg:modifiedBy: e.esquinca
  sbg:modifiedOn: 1626285829
  sbg:revision: 9
  sbg:revisionNotes: ''
- sbg:modifiedBy: e.esquinca
  sbg:modifiedOn: 1626287901
  sbg:revision: 10
  sbg:revisionNotes: ''
- sbg:modifiedBy: e.esquinca
  sbg:modifiedOn: 1626289048
  sbg:revision: 11
  sbg:revisionNotes: ''
- sbg:modifiedBy: e.esquinca
  sbg:modifiedOn: 1626291663
  sbg:revision: 12
  sbg:revisionNotes: ''
- sbg:modifiedBy: e.esquinca
  sbg:modifiedOn: 1626291914
  sbg:revision: 13
  sbg:revisionNotes: ''
- sbg:modifiedBy: e.esquinca
  sbg:modifiedOn: 1626292737
  sbg:revision: 14
  sbg:revisionNotes: ''
- sbg:modifiedBy: e.esquinca
  sbg:modifiedOn: 1626293172
  sbg:revision: 15
  sbg:revisionNotes: ''
- sbg:modifiedBy: e.esquinca
  sbg:modifiedOn: 1626293572
  sbg:revision: 16
  sbg:revisionNotes: ''
- sbg:modifiedBy: e.esquinca
  sbg:modifiedOn: 1626293675
  sbg:revision: 17
  sbg:revisionNotes: ''
- sbg:modifiedBy: e.esquinca
  sbg:modifiedOn: 1626294501
  sbg:revision: 18
  sbg:revisionNotes: ''
- sbg:modifiedBy: e.esquinca
  sbg:modifiedOn: 1626295268
  sbg:revision: 19
  sbg:revisionNotes: ''
- sbg:modifiedBy: e.esquinca
  sbg:modifiedOn: 1626295693
  sbg:revision: 20
  sbg:revisionNotes: ''
- sbg:modifiedBy: e.esquinca
  sbg:modifiedOn: 1626296250
  sbg:revision: 21
  sbg:revisionNotes: ''
- sbg:modifiedBy: e.esquinca
  sbg:modifiedOn: 1626366680
  sbg:revision: 22
  sbg:revisionNotes: ''
- sbg:modifiedBy: e.esquinca
  sbg:modifiedOn: 1626380399
  sbg:revision: 23
  sbg:revisionNotes: ''
- sbg:modifiedBy: e.esquinca
  sbg:modifiedOn: 1626380771
  sbg:revision: 24
  sbg:revisionNotes: ''
- sbg:modifiedBy: e.esquinca
  sbg:modifiedOn: 1626381561
  sbg:revision: 25
  sbg:revisionNotes: ''
- sbg:modifiedBy: e.esquinca
  sbg:modifiedOn: 1627319265
  sbg:revision: 26
  sbg:revisionNotes: ''
- sbg:modifiedBy: e.esquinca
  sbg:modifiedOn: 1627321040
  sbg:revision: 27
  sbg:revisionNotes: ''
- sbg:modifiedBy: e.esquinca
  sbg:modifiedOn: 1627322834
  sbg:revision: 28
  sbg:revisionNotes: ''
- sbg:modifiedBy: e.esquinca
  sbg:modifiedOn: 1627348710
  sbg:revision: 29
  sbg:revisionNotes: testing data
- sbg:modifiedBy: e.esquinca
  sbg:modifiedOn: 1627348742
  sbg:revision: 30
  sbg:revisionNotes: ''
- sbg:modifiedBy: e.esquinca
  sbg:modifiedOn: 1627350003
  sbg:revision: 31
  sbg:revisionNotes: ''
- sbg:modifiedBy: e.esquinca
  sbg:modifiedOn: 1627350349
  sbg:revision: 32
  sbg:revisionNotes: ''
- sbg:modifiedBy: e.esquinca
  sbg:modifiedOn: 1627351108
  sbg:revision: 33
  sbg:revisionNotes: ''
- sbg:modifiedBy: e.esquinca
  sbg:modifiedOn: 1627352173
  sbg:revision: 34
  sbg:revisionNotes: ''
- sbg:modifiedBy: e.esquinca
  sbg:modifiedOn: 1627410480
  sbg:revision: 35
  sbg:revisionNotes: test using bash
- sbg:modifiedBy: e.esquinca
  sbg:modifiedOn: 1627410844
  sbg:revision: 36
  sbg:revisionNotes: ''
- sbg:modifiedBy: e.esquinca
  sbg:modifiedOn: 1627411436
  sbg:revision: 37
  sbg:revisionNotes: back to r-base
- sbg:modifiedBy: e.esquinca
  sbg:modifiedOn: 1627411821
  sbg:revision: 38
  sbg:revisionNotes: ''
- sbg:modifiedBy: e.esquinca
  sbg:modifiedOn: 1627412474
  sbg:revision: 39
  sbg:revisionNotes: ''
- sbg:modifiedBy: e.esquinca
  sbg:modifiedOn: 1627413782
  sbg:revision: 40
  sbg:revisionNotes: ''
- sbg:modifiedBy: e.esquinca
  sbg:modifiedOn: 1627414240
  sbg:revision: 41
  sbg:revisionNotes: ''
- sbg:modifiedBy: e.esquinca
  sbg:modifiedOn: 1627422196
  sbg:revision: 42
  sbg:revisionNotes: ''
- sbg:modifiedBy: e.esquinca
  sbg:modifiedOn: 1630279141
  sbg:revision: 43
  sbg:revisionNotes: updated requirements and descriptions
- sbg:modifiedBy: e.esquinca
  sbg:modifiedOn: 1630279278
  sbg:revision: 44
  sbg:revisionNotes: ''
- sbg:modifiedBy: e.esquinca
  sbg:modifiedOn: 1630279637
  sbg:revision: 45
  sbg:revisionNotes: ''
- sbg:modifiedBy: e.esquinca
  sbg:modifiedOn: 1630279972
  sbg:revision: 46
  sbg:revisionNotes: ''
- sbg:modifiedBy: e.esquinca
  sbg:modifiedOn: 1630281140
  sbg:revision: 47
  sbg:revisionNotes: ''
- sbg:modifiedBy: e.esquinca
  sbg:modifiedOn: 1630281629
  sbg:revision: 48
  sbg:revisionNotes: ''
- sbg:modifiedBy: e.esquinca
  sbg:modifiedOn: 1630282714
  sbg:revision: 49
  sbg:revisionNotes: ''
- sbg:modifiedBy: e.esquinca
  sbg:modifiedOn: 1630283238
  sbg:revision: 50
  sbg:revisionNotes: ''
sbg:sbgMaintained: false
sbg:validationErrors: []
