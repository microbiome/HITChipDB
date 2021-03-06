#' @title Run profiling script
#' @description Profiling main script
#' @param dbuser MySQL username
#' @param dbpwd  MySQL password
#' @param dbname MySQL database name (HITChip: "Phyloarray"; MITChip: "Phyloarray_MIT";
#'                                PITChip old: "Phyloarray_PIT"; PITChip new: "pitchipdb")
#' @param verbose verbose
#' @param host host; needed with FTP connections
#' @param port port; needed with FTP connections
#' @param summarization.methods List summarization methods to be included in output. For HITChip frpa always used; for other chips, rpa always used. Other options: sum, ave
#' @param which.projects Optionally specify the projects to extract. All samples from these projects will be included.
#' @param probe.parameters probe.parameters
#' @param save.dir Output data folder                                        
#' @param use.default.parameters use.default.parameters
#' @return Profiling parameters. Also writes output to the user-specified directory.
#' @export
#' @references See citation("microbiome") 
#' @author Contact: Leo Lahti \email{microbiome-admin@@googlegroups.com}
#' @keywords utilities
run.profiling.script <- function (dbuser, dbpwd, dbname, verbose = TRUE, host = NULL, port = NULL, summarization.methods = c("frpa", "sum"), which.projects = NULL, probe.parameters = NULL, save.dir = NULL, use.default.parameters = FALSE) {

  htree.plot <- NULL		     

  message("Fetch and preprocess the data")
  chipdata  <- preprocess.chipdata(dbuser, dbpwd, dbname, 
  	       				verbose = verbose,
					   host = host,
					   port = port, 
		 	  summarization.methods = summarization.methods, 
			         which.projects = which.projects, 
				       save.dir = save.dir, 
 			     use.default.parameters = use.default.parameters)

  if (is.null(chipdata)) {
    return(NULL)
  }

  message("---Preprocessing ready")
  probedata <- chipdata$probedata
  params    <- chipdata$params

  # Phylogeny used for L1/L2/species summarization
  taxonomy <- chipdata$taxonomy

  # Complete phylogeny before melting temperature etc. filters
  taxonomy.full <- chipdata$taxonomy.full

  # Create sample metadata template
  meta <- data.frame(list(index = 1:ncol(probedata), 
       	                  sample = colnames(probedata)), 
			  stringsAsFactors = FALSE)

  message("Write preprocessed probe-level data, taxonomy and metadata template in tab-delimited file")
  outd <- WriteChipData(list(oligo = probedata), params$wdir, 
       	  	taxonomy, taxonomy.full, meta, verbose = verbose)

  message("Summarize probes into species abundance table")
  abundance.tables <- list()
  abundance.tables$oligo <- probedata

  message("Go through methods")
  for (method in params$summarization.methods) {
  
    # print(method)

    output.dir <- params$wdir
    level <- "species"

    # ("If the data is not given as input, read it from the data directory")
    if (method == "frpa") {

      message("Loading pre-calculated RPA preprocessing parameters")
      probes <- unique(taxonomy[, "oligoID"])
      rpa.hitchip.species.probe.parameters <- list()
      load(system.file("extdata/probe.parameters.rda", package = "HITChipDB"))
      probe.parameters <- rpa.hitchip.species.probe.parameters
      # Ensure we use only those parameters that are in the filtered phylogeny
      for (bac in names(probe.parameters)) {
        probe.parameters[[bac]] <- probe.parameters[[bac]][intersect(names(probe.parameters[[bac]]), probes)]
      }
    }

    message("Summarize probes through species level")
    if (method %in% c("rpa", "frpa")) {
      spec <- summarize.rpa(taxonomy, level, probedata, verbose = TRUE, probe.parameters = probe.parameters)$abundance.table
    } else if (method == "sum") {
      spec <- summarize.sum(taxonomy, level, probedata, verbose = TRUE, downweight.ambiguous.probes = TRUE)$abundance.table
    }
    
    abundance.tables[["species"]][[method]] <- spec

    message("Higher-level tables")
    for (level in setdiff(colnames(taxonomy), c("species", "specimen", "oligoID", "pmTm"))) {
      
      taxo <- unique(taxonomy[, c(level, "species")])
      rownames(taxo) <- as.character(taxo$species)

      # This includes pseudocount +1 in each cell
      # pseq <- hitchip2physeq(t(spec), meta, taxo, detection.limit = 0)
      # This not; compatible with earlier
      #pseq <- hitchip2physeq(t(spec) - 1, meta, taxo, detection.limit = 0)
      #tg <- tax_glom(pseq, level)
      #ab <- tg@otu_table
      #rownames(ab) <- as.character(as.data.frame(tax_table(tg))[[level]])
      #ab <- ab[order(rownames(ab)),]
      #abundance.tables[[level]][[method]] <- ab

      #ab2 <- species2higher(spec, taxonomy, level, method)
      levs <- unique(taxonomy[[level]])
      ab2 <- matrix(NA, nrow = length(levs), ncol = ncol(spec))
      rownames(ab2) <- levs
      colnames(ab2) <- colnames(spec)
      for (pt in levs) {
        # Species associated with this level
        specs <- unique(taxonomy[which(taxonomy[[level]] == pt), "species"])
	ab2[pt, ] <- colSums(matrix(spec[specs,], nrow = length(specs)))
      }

      abundance.tables[[level]][[method]] <- ab2

    }

  }   

  message("Write preprocessed data in tab delimited file")
  outd <- WriteChipData(abundance.tables, params$wdir, taxonomy, taxonomy.full, meta, verbose = verbose)
  
  # Add oligo heatmap into output directory
  # Provide oligodata in the _original (non-log) domain_
  hc.params <- add.heatmap(log10(probedata), 
  	          output.dir = params$wdir, taxonomy = taxonomy)

  # Plot hierachical clustering trees into the output directory
  dat <- abundance.tables[["oligo"]]

  if (ncol(dat) > 2) { 

    if (params$chip == "MITChip") {
      # With MITChip, use the filtered phylogeny for hierarchical clustering
      dat <- dat[unique(taxonomy$oligoID),]
    }

    # Clustering
    # Save into file
    method <- "complete"
    hc <- hclust(as.dist(1 - cor(log10(dat), use = "pairwise.complete.obs", method = "pearson")), method = method)
    pdf(paste(params$wdir, "/hclust_oligo_pearson_", method, "_", nrow(dat), "probes", ".pdf", sep = ""), height = 800, width = 800 * ncol(dat)/20)
    plot(hc, hang = -1, main = "hclust/pearson/oligo/log10/complete", xlab = "Samples", ylab = "1 - Correlation")
    dev.off()

  }

  # Plot hclust trees on screen
  tmp <- htree.plot(dat)

  # Write parameters into log file
  tmp <- WriteLog(chipdata$naHybs, params)
  params$logfilename <- tmp$log.file
  params$paramfilename <- tmp$parameter.file

  params

}




#' @title add.heatmap
#' @description Add oligprofile heatmap into output directory.
#' @param dat oligoprofile data in original (non-log) domain
#' @param output.dir output data directory
#' @param output.file output file name
#' @param taxonomy oligo-phylotype mappings
#' @param ppcm figure size
#' @param hclust.method hierarchical clustering method
#' @param palette color palette ("white/black" / "white/blue" / "black/yellow/white")
#' @param level taxonomic level to show
#' @param metric clustering metric
#' @param figureratio figure ratio
#' @param fontsize font size
#' @param tree.display tree.display
#' @return Plotting parameters
#' @export
#' @examples # data(peerj32); hc <- add.heatmap(peerj32$microbes[, 1:4])
#' @references See citation("microbiome")
#' @author Contact: Leo Lahti \email{microbiome-admin@@googlegroups.com}
#' @keywords utilities
add.heatmap <- function (dat, output.dir, output.file = NULL, taxonomy, ppcm = 150, 
	         hclust.method = "complete", palette = "white/black", level = "L1", metric = "pearson", 
  		 figureratio = 10, fontsize = 40, tree.display = TRUE) {

  # dat <- finaldata[["oligo"]]; output.dir = params$wdir;  output.file = NULL; taxonomy = taxonomy; ppcm = 150; hclust.method = "complete"; palette = "white/blue"; level = "L2"; metric = "pearson"; figureratio = 12; fontsize = 12; tree.display = TRUE
  #output.dir = "~/tmp/";  output.file = NULL; taxonomy = taxonomy; ppcm = 150; hclust.method = "complete"; palette = "white/blue"; level = "L2"; metric = "pearson"; figureratio = 12; fontsize = 12; tree.display = TRUE

  if (is.null(output.file)) {
    output.file <- paste(output.dir,"/", gsub(" ", "", level), "-oligoprofileClustering.pdf",sep="")
  }		 

  hc.params <- list()
  if( ncol(dat) >= 3 ) {

    message(paste("Storing oligo heatmap in", output.file))  
    hc.params$ppcm <- ppcm
    hc.params$output.file <- output.file

    # PLOT THE HEATMAP
    # figure width as a function of the number of the samples
    plotdev <- pdf(output.file, 
  	    width = max(trunc(ppcm*21), trunc(ppcm*21*ncol(dat)/70)), 
	    height = trunc(ppcm*29.7)) 
    try(hc.params <- PlotPhylochipHeatmap(data = dat,
                taxonomy = taxonomy,
                metric = metric,
                level = level,
                tree.display = tree.display,
                palette = palette,
                fontsize = fontsize,
                figureratio = figureratio, 
		hclust.method = hclust.method)) 

    dev.off()
  }

  hc.params

}






#' @title Default list of removed phylotypes and oligos
#' @description Default list of removed phylotypes and oligos
#' @param chip Chip name (HIT/MIT/PIT/Chick)Chip
#' @return List of removed oligos and phylotypes
#' @export
#' @references See citation("microbiome") 
#' @author Contact: Leo Lahti \email{microbiome-admin@@googlegroups.com}
#' @keywords utilities
phylotype.rm.list <- function (chip) {

  rm.phylotypes <- list()

  if (chip == "HITChip") {
    
    rm.phylotypes[["oligos"]] <- c("UNI 515", "HIT 5658", "HIT 1503", "HIT 1505", "HIT 1506")
    rm.phylotypes[["species"]] <- c("Victivallis vadensis")
    rm.phylotypes[["L1"]] <- c("Lentisphaerae")
    rm.phylotypes[["L2"]] <- c("Victivallis")

  } else if (chip == "MITChip") {

    rm.phylotypes[["oligos"]] <- c("Bacteria", "DHC_1", "DHC_2", "DHC_3", "DHC_4", "DHC_5", "DHC_6", "Univ_1492")
    rm.phylotypes[["species"]] <- c()
    rm.phylotypes[["L1"]] <- c()
    rm.phylotypes[["L2"]] <- c()

  } else if (chip == "PITChip") {

    # Based on JZ mail 9/2012; LL

    rm.old.oligos <- c("Bacteria", "DHC_1", "DHC_2", "DHC_3", "DHC_4", "DHC_5", "DHC_6", "Univ_1492")
    rm.new.oligos <- c("PIT_1083", "PIT_1022", "PIT_1057", "PIT_1023", "PIT_1118", "PIT_1040", "PIT_1058", "PIT_1119", "PIT_122", "PIT_1221", "PIT_1322", "PIT_1367", "PIT_1489", "PIT_160", "PIT_1628", "PIT_1829", "PIT_1855", "PIT_1963", "PIT_1976", "PIT_1988", "PIT_2002", "PIT_2027", "PIT_2034", "PIT_2101", "PIT_2196", "PIT_2209", "PIT_2281", "PIT_2391", "PIT_2392", "PIT_2418", "PIT_2425", "PIT_2426", "PIT_2498", "PIT_2555", "PIT_2563", "PIT_2651", "PIT_2654", "PIT_2699", "PIT_2741", "PIT_2777", "PIT_2786", "PIT_2936", "PIT_35", "PIT_425", "PIT_427", "PIT_428", "PIT_429", "PIT_435", "PIT_481", "PIT_605", "PIT_7", "PIT_733", "PIT_734", "PIT_892")
    rm.phylotypes[["oligos"]] <- c(rm.old.oligos, rm.new.oligos)
    rm.phylotypes[["species"]] <- c()
    rm.phylotypes[["L0"]] <- c("Nematoda", "Apicomplexa", "Euryarchaeota", "Ascomycota", "Parabasalidea", "Chordata")
    rm.phylotypes[["L1"]] <- c("Chromadorea", "Coccidia", "Methanobacteria", "Saccharomycetales", "Trichomonada", "Mammalia")
    rm.phylotypes[["L2"]] <- c("Ascaris suum et rel.", "Eimeria  et rel.", "Methanobrevibacter et rel.", "Saccharomyces et rel.", "Trichomonas et rel.", "Uncultured Mammalia", "Uncultured methanobacteria")

  } else if (chip == "ChickChip") {
    warning("No universal probes excluded from ChichChip yet!")
  }

  rm.phylotypes

}

