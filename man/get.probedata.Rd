% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/get.probedata.R
\name{get.probedata}
\alias{get.probedata}
\title{Description: Get probedata}
\usage{
get.probedata(
  hybridization.ids,
  rmoligos,
  dbuser,
  dbpwd,
  dbname,
  host = NULL,
  port = NULL
)
}
\arguments{
\item{hybridization.ids}{Specify the hybridizations to retrieve}

\item{rmoligos}{oligos to exclude}

\item{dbuser}{MySQL user}

\item{dbpwd}{MySQL password}

\item{dbname}{MySqL database name}

\item{host}{host; needed with FTP connections}

\item{port}{port; needed with FTP connections}
}
\value{
list with data (features x hybridizations matrix) and info (features x info) fields
}
\description{
Description: Get probedata
}
\references{
See citation("microbiome")
}
\author{
Contact: Leo Lahti \email{microbiome-admin@googlegroups.com}
}
\keyword{utilities}
