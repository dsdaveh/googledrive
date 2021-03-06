% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/drive_rename.R
\name{drive_rename}
\alias{drive_rename}
\title{Rename a Drive file}
\usage{
drive_rename(file = NULL, name = NULL, verbose = TRUE)
}
\arguments{
\item{file}{Drive File, something that identifies the file of interest
on your Google Drive. This can be name(s)/path(s), marked file id(s),
or a \code{dribble}.}

\item{name}{Character. Name you would like the file to have.}

\item{verbose}{Logical, indicating whether to print informative messages
(default \code{TRUE}).}
}
\value{
An object of class \code{\link{dribble}}, a tibble with
   one row per file.
}
\description{
This is a wrapper for \code{\link[=drive_mv]{drive_mv()}} that only renames a file.
If you would like to rename AND move the file, see \code{\link[=drive_mv]{drive_mv()}}.
}
\examples{
\dontrun{
drive_rename("chickwts.csv", name = "my_chickwts.csv")
}
}
