% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/P.hv.par.R
\name{P.hv.par}
\alias{P.hv.par}
\title{Parallel Hemispherical-Voronoi Gap Fraction}
\usage{
P.hv.par(las = NA, models = "all", thresh.vals = seq(1, 4, 0.5),
  thresh.var = "height", reprojection = NA, pol.deg = 5, azi.deg = 45,
  col = "height", plots = TRUE, plots.each = FALSE, plots.save = FALSE)
}
\arguments{
\item{las}{String vector or list of LAS files. Defaults to NA.}

\item{models}{String vector or list of hemispherical lens models to use. Options include equi-distant (\code{"equidist"}), equi-angular (\code{"equiangle"}), stereographic (\code{"stereo"}), orthographic (\code{"ortho"}), or \code{"all"}. Defaults to \code{"all"}.}

\item{thresh.vals}{String vector or list of height thresholds to use. Defaults to 2.}

\item{thresh.var}{Specifies the LiDAR metric to use for thresholding canopy points. Options include height, intensity, nreturn, and class. Defaults to height.}

\item{reprojection}{Proj4 projection string to use for reprojection. Defaults to NA.}

\item{pol.deg}{Specifies the polar resolution for the radial plot lines. Defaults to 5.}

\item{azi.deg}{Specifies the azimuthal resolution for the radial plot lines. Defaults to 45.}

\item{col}{Specifies the LiDAR metric to use to color points of first plot in display. Options include height, intensity, nreturn, and class. Defaults to height.}

\item{plots}{Boolean switch for the interactive display of plots. Defaults to FALSE.}

\item{plots.each}{Boolean switch for displaying individual of plots. Defaults to FALSE.}

\item{plots.save}{Boolean switch for the saving of plot files to the las.path folder. Defaults to FALSE.}
}
\value{
The results of \code{P.hv.par}
}
\description{
This function is a wrapper that allows you to run \code{P.hv} on multiple plots in parallel using multi-core CPUs with \code{snow}
}
\examples{
P.hv.par(las='C:/plot.las', models=c('equidist','stereo'), threshs=seq(1,4,0.5))
P.hv.par(las=las.list, models='all', thresh.vals=1.25, thresh.var='height', reprojection=NA, pol.deg=5, azi.deg=45, col='height', plots=TRUE, plots.each=FALSE, plots.save=FALSE)
}
\references{
Forthcoming
}
\author{
Adam Erickson, \email{adam.erickson@ubc.ca}
}
\keyword{Voronoi,}
\keyword{fraction,}
\keyword{gap}
\keyword{hemispherical}
\keyword{parallel,}
\keyword{tesselation}
