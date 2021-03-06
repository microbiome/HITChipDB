% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/read_hitchip.R
\name{read_hitchip}
\alias{read_hitchip}
\title{Read HITChip}
\usage{
read_hitchip(
  data.dir,
  method = "rpa",
  detection.threshold = 0,
  verbose = F,
  taxonomy = NULL
)
}
\arguments{
\item{data.dir}{Profiling script output directory for reading the data.}

\item{method}{Probe summarization method ("rpa", "frpa", or "sum")}

\item{detection.threshold}{Taxon absence/presence thresholds (typically 10^1.8 for HITChip)}

\item{verbose}{verbose}
}
\value{
data matrix (phylo x samples)
}
\description{
Read HITChip output and preprocess into phyloseq format.
}
\details{
Converts the probe-level data matrix and probe-level taxonomy table to phylotype-level 
HITChip data. Returns the probe-level data (data matrix and taxonomies) and the phylotype-level 
phyloseq object. There are two versions of probe-level taxonomy. The full version includes all probes 
in the probe-level data. The filtered version includes those probes that have been used to aggregate
probes into phylotype level.
}
\examples{
 \dontrun{
  data.dir <- system.file("extdata", package = "microbiome")
  dat <- read_hitchip(data.dir)
}
}
\references{
See citation('microbiome')
}
\author{
Contact: Leo Lahti \email{microbiome-admin@googlegroups.com}
}
\keyword{utilities}
