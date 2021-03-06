#' Point-density-normalized Gap Fraction, Effective LAI, and ACI
#'
#' This function implements Erickson's point-density-normalized gap fraction along with effective LAI and ACI algorithms
#' @param las Path or name of LAS file. Defaults to NA.
#' @param pol.deg Resolution of polar window in degrees. Defaults to 5.
#' @param azi.deg Resolution of azimuthal window in degrees. Defaults to 45.
#' @param reprojection Proj4 projection string to use for reprojection. Defaults to NA.
#' @param silent Boolean switch for the interactive display of plots. Defaults to TRUE.
#' @param plots Boolean switch for the saving of plot files to the las.path folder. Defaults to FALSE.
#' @author Adam Erickson, \email{adam.erickson@@ubc.ca}
#' @references Forthcoming
#' @references \url{http://www.sciencedirect.com/science/article/pii/S0168192310000328}
#' @keywords gap fraction, lai, aci
#' @export
#' @return The results of \code{P.pdn} in the form c(Ppdn, Le, ACI)
#' @examples
#' P.pdn(las='C:/plot.las', pol.deg=15, azi.deg=45, reprojection=NA, silent=FALSE, plots=FALSE)

P.pdn <- function(las=NA, pol.deg=5, azi.deg=45, reprojection=NA, silent=TRUE, plots=FALSE) {

  if(length(las)==1 & any(is.na(eval(las)))) stop('Please input a full file path to the LAS file')

  myColorRamp <- function(colors, values) {
    v <- (values - min(values))/diff(range(values))
    x <- colorRamp(colors)(v)
    rgb(x[,1], x[,2], x[,3], maxColorValue=255)
  }

  crt2sph <- function(m) {
    x     <- m[,1]
    y     <- m[,2]
    z     <- m[,3]
    r     <- sqrt(x^2 + y^2 + z^2)
    theta <- acos(z/r)
    phi   <- atan2(y=y,x=x)
    phi[phi<0] <- phi[phi<0]+2*pi
    nrows <- length(x)
    out   <- matrix(c(theta,phi,r), nrow=nrows, ncol=3, dimnames=list(c(1:nrows),c('theta','phi','r')))
    return(out)
  }

  if(!exists("las")) {
    LAS       <- lidR::readLAS(las)
    LASfolder <- dirname(las)
    LASname   <- strsplit(basename(las),'\\.')[[1]][1]
  } else LAS  <- las

  LAS <- LAS[LAS[,'ReturnNumber']==1,]

  if(!is.na(reprojection)) {
    try(if(length(reprojection) != 2) stop('Please supply input and output CRS strings in the form: c(input,output)'))
    CRSin  <- reprojection[1]
    CRSout <- reprojection[2]
    spLAS  <- sp::SpatialPoints(LAS[,c(1:3)], proj4string=CRS(CRSin))
    tmLAS  <- sp::spTransform(spLAS, CRSobj=CRS(CRSout))
    rpLAS  <- sp::coordinates(tmLAS)
    LAS    <- cbind(rpLAS, LAS[,c(4:12)])
  }

  x <- (LAS[,1]-min(LAS[,1])) - (diff(range(LAS[,1]))/2)
  y <- (LAS[,2]-min(LAS[,2])) - (diff(range(LAS[,2]))/2)
  z <-  LAS[,3]

  nrows <- length(x)
  m     <- matrix(c(x,y,z), nrow=nrows, ncol=3, dimnames=list(c(1:nrows),c('X','Y','Z')))
  a     <- crt2sph(m=m)

  deg2rad <- function(x) return(x*(pi/180))
  rad2deg <- function(x) return(x*(180/pi))

  pol.res <- deg2rad(pol.deg)
  azi.res <- deg2rad(azi.deg)

  theta  <- a[,1]
  phi    <- a[,2]
  r      <- a[,3]

  R      <- max(r)
  n.pts  <- nrow(LAS)
  n.pol  <- (pi/2)/pol.res
  n.azi  <- (pi*2)/azi.res
  n.win  <- n.pol*n.azi

  pol <- c(0, seq(from=pol.res, to=(pi/2), by=pol.res))
  azi <- c(0, seq(from=azi.res, to=(pi*2), by=azi.res))

  circ.area  <- pi*R*R
  pt.density <- n.pts/circ.area

  # Calculate returns for each spherical quadrangle interval on the hemisphere
  n.returns <- matrix(nrow=n.pol, ncol=n.azi)
  for(i in 1:(length(pol)-1)) {
    for(j in 1:(length(azi)-1)) {
      n.returns[i,j] <- length(r[which(findInterval(theta,c(pol[i],pol[i+1]))==1 & findInterval(phi,c(azi[j],azi[j+1]))==1)])
    }
  }
  message('Estimated ground plane points: ',round((1-(sum(n.returns)/n.pts))*100,2),'%')
  message('Canopy-to-total-return ratio: ', round((sum(n.returns)/n.pts)*100,2),'%')

  # Calculate area of sperical quadrangles for a hemisphere (non-negative latitudes in 5-degree steps)
  #   spherical cap:  http://mathworld.wolfram.com/SphericalCap.html
  #   spherical zone: http://mathworld.wolfram.com/Zone.html
  #   lat = polar angle
  #   lon = azimuth angle
  #   A = (R^2) * (sin(lat1)-sin(lat2)) * (lon1-lon2)
  #   Modifed from: NOAA and http://mathforum.org/library/drmath/view/63767.html
  #   I reversed (pi/180) to (180/pi) to calculate area based on degrees
  #   Error-checked with: hemisphere.area <- (4*pi*R^2)/2; hemisphere.area == sum(quad.area)
  #   The hemisphere radius (R) is derived from the empirical maximum radial distance (r)
  #   hemisphere.area <- (4*pi*R^2)/2

  # Calculate area of each spherical quadrangle, reverse to start from nadir
  hemi.area <- (4*pi*R*R)/2
  quad.area <- matrix(nrow=n.pol, ncol=n.azi)
  for(i in 1:(length(pol)-1)) {
    for(j in 1:(length(azi)-1)) {
      quad.area[i,j] <- ((R^2) * (sin(pol[i+1])-sin(pol[i])) * (azi[j+1]-azi[j]))
    }
  }
  quad.area <- quad.area[nrow(quad.area):1,]
  if(sum(quad.area) != hemi.area) message('Caution: Quadrangles do not sum to the hemisphere area')

  # Calculate sphere volume for wedge quadrangles: http://mathworld.wolfram.com/SphericalWedge.html
  hemi.volume <- (4/3)*pi*(R*R*R)/2
  quad.prop   <- quad.area/hemi.area
  quad.volume <- quad.prop*hemi.volume
  #if(sum(quad.volume) != hemi.volume) message('Caution: Wedge quadrangles do not sum to the hemisphere volume')

  # Normalize point frequency by spherical quadrangle area to estimate the true gap fraction (canopy closure)
  gf1     <- 1-(n.returns/pt.density/quad.area)
  gf1.out <- sum(gf1*quad.prop)
  message('Density-normalized gap fraction: ',round(gf1.out,2),'%')

  # LAI integrand for theta: lai <- -2*ln(gf1)*cos(theta)*sin(theta)
  # Source: Miller (1967);  Ryu et al. (2010); Maltamo, Naesset, and Vauhkonen (2014)
  # Final Source: Korhonen & Morsdorf (2014)
  e.lai <- c()
  for(i in (1:length(pol)-1)[-1]) {
    log.gap1 <- suppressWarnings(-log(mean(gf1[i,])))
    log.gap2 <- ifelse(is.finite(log.gap1), log.gap1, 0)
    e.lai[i] <- log.gap2*cos(pol[i+1])*(sin(pol[i+1])/sum(sin(pol)))
  }
  e.lai.out <- 2*sum(e.lai)
  message('Mean effective LAI: ',round(e.lai.out,2))

  # Calculate the apparent clumping index
  # Source: Ryu et al. (2010)
  e.lai2 <- c()
  for(i in (1:length(pol)-1)[-1]) {
    log.gap1 <- suppressWarnings(-mean(log(gf1[i,])))
    log.gap2 <- ifelse(is.finite(log.gap1), log.gap1, 0)
    e.lai2[i] <- log.gap2*cos(pol[i+1])*(sin(pol[i+1])/sum(sin(pol)))
  }
  e.lai2.out <- 2*sum(e.lai2)
  aci <-e.lai.out/e.lai2.out
  message('ACI: ',round(aci,2))

  gf2 <- c()
  pol.prop <- c()
  for(i in (1:length(pol)-1)[-1]) {
    gf2[i] <- exp((-e.lai.out*0.5)/cos(pol[i+1]))
    pol.prop[i] <- sin(pol[i+1])/sum(sin(pol))
  }
  gf2.out <- sum(gf2*pol.prop)

  pol.mean <- apply(gf1, 1, mean)
  names(pol.mean) <- rad2deg(pol[-1])

  azi.mean <- apply(gf1, 2, mean)
  names(azi.mean) <- rad2deg(azi[-1])

  result <- c(P.pdn=gf1.out, P.bl=gf2.out, lai.e.miller=e.lai.out, aci=aci)

  if (plots==TRUE) {
    jpeg(file.path(LASfolder, paste(LASname,'_gf_lai_aci.jpg',sep='')), width=8, height=8, units='in', res=300, quality=100)
    par(mfrow=c(2,2), mar=c(2,2,3,2), pty='s', xpd=TRUE)

    plot(pol.sum, type='b', xaxt='n', xlab='Zenith Angle', ylab='Gap Fraction', lwd=2, main='Gap Fraction by Zenith Angle')
    axis(1, at=1:length(pol.sum), labels=names(pol.sum))

    plot(azi.sum, type='b', xaxt='n', xlab='Azimuth Angle', ylab='Gap Fraction', lwd=2, main='Gap Fraction by Azimuth Angle')
    axis(1, at=1:length(azi.sum), labels=names(azi.sum))

    plot(e.lai, type='b', xaxt='n', xlab='Zenith Angle', ylab='Effective LAI', lwd=2, main='Effective LAI by Zenith Angle')
    axis(1, at=1:length(pol.sum), labels=names(pol.sum))

    plot(aci, type='b', xaxt='n', xlab='Zenith Angle', ylab='Apparent Clumping Index', lwd=2, main='Apparent Clumping Index by Zenith Angle')
    axis(1, at=1:length(pol.sum), labels=names(pol.sum))
    dev.off()
  }
  if(silent==FALSE) {
    par(mfrow=c(2,2), mar=c(2,2,3,2), pty='s', xpd=TRUE)

    plot(pol.mean, type='b', xaxt='n', xlab='Zenith Angle', ylab='Gap Fraction', lwd=2, main='Gap Fraction by Zenith Angle')
    axis(1, at=1:length(pol.mean), labels=names(pol.mean))

    plot(azi.mean, type='b', xaxt='n', xlab='Azimuth Angle', ylab='Gap Fraction', lwd=2, main='Gap Fraction by Azimuth Angle')
    axis(1, at=1:length(azi.mean), labels=names(azi.mean))

    plot(e.lai, type='b', xaxt='n', xlab='Zenith Angle', ylab='Effective LAI', lwd=2, main='Effective LAI by Zenith Angle')
    axis(1, at=1:length(pol.mean), labels=names(pol.mean))

    plot(gf2, type='b', xaxt='n', xlab='Zenith Angle', ylab='Gap Fraction', lwd=2, main='Beer-Lambert Law Gap Fraction by Zenith Angle')
    axis(1, at=1:length(pol.mean), labels=names(pol.mean))
    par(mfrow=c(1,1))
  }
  return(result)
}
