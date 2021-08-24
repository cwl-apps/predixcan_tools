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
