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
