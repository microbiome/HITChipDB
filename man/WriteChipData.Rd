% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/internal.R
\name{WriteChipData}
\alias{WriteChipData}
\title{Description: Writed data into the output directory}
\usage{
WriteChipData(
  finaldata,
  output.dir,
  tax.table,
  tax.table.full,
  meta,
  verbose = TRUE
)
}
\arguments{
\item{finaldata}{preprocessed data matrices in absolute scale (from the chipdata function)}

\item{output.dir}{output directory}

\item{tax.table}{tax.table used in summarization}

\item{tax.table.full}{tax.table.full unfiltered phylogenyinfo}

\item{meta}{sample metadata samples x features}

\item{verbose}{verbose}
}
\value{
Preprocessed data in absolute scale, tax.table, and parameters
}
\description{
Description: Writed data into the output directory
}
\references{
See citation("microbiome")
}
\author{
Contact: Leo Lahti \email{microbiome-admin@googlegroups.com}
}
\keyword{utilities}
