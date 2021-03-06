% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/mysql.R
\name{get.phylogeny.info}
\alias{get.phylogeny.info}
\title{get.phylogeny.info}
\usage{
get.phylogeny.info(
  phylogeny = "16S",
  dbuser,
  dbpwd,
  dbname,
  verbose = TRUE,
  chip = "HITChip",
  host = NULL,
  port = NULL,
  rmoligos = NULL
)
}
\arguments{
\item{phylogeny}{phylogeny (default: 16S)}

\item{dbuser}{MySQL user}

\item{dbpwd}{MySQL password}

\item{dbname}{MySqL database name}

\item{verbose}{verbose}

\item{chip}{chip type}

\item{host}{host; needed with FTP connections}

\item{port}{port; needed with FTP connections}

\item{rmoligos}{oligos to exclude}
}
\value{
phylogeny.info
}
\description{
Description: Get phylogeny
}
\details{
Arguments:
}
\references{
See citation("microbiome")
}
\author{
Contact: Leo Lahti \email{microbiome-admin@googlegroups.com}
}
\keyword{utilities}
