######################################################################
## Kernel support estimate - contour-based or convex hull 
######################################################################

ksupp <- function(fhat, cont=95, abs.cont, convex.hull=FALSE)
{
    if (missing(abs.cont)) abs.cont <- contourLevels(fhat, cont=cont)
    supp <- expand.grid(fhat$eval.points)[as.vector(fhat$estimate > abs.cont),]
    if (convex.hull) supp <- supp[chull(supp),]
    return(supp)
}


## Devroye-Wise support estimate

dwsupp <- function(x, H, h, gridsize, gridtype, xmin, xmax, supp=3.7, binned, bgridsize, verbose=FALSE, w)
{
  if (is.vector(x))
  {
    if (missing(H)) {d <- 1; n <- length(x)}
    else
    {
      if (is.vector(H)) { d <- 1; n <- length(x)}
      else {x <- matrix(x, nrow=1); d <- ncol(x); n <- nrow(x)}
    }
  }
  else {d <- ncol(x); n <- nrow(x)}

  if (!missing(w))
    if (!(identical(all.equal(sum(w), n), TRUE)))
    {
      warning("Weights don't sum to sample size - they have been scaled accordingly\n")
      w <- w*n/sum(w)
    }

  if (missing(binned)) binned <- default.bflag(d=d, n=n)
  if (missing(w)) w <- rep(1,n)
  if (d==1)
  {  
    ##if (missing(adj.positive)) adj.positive <- abs(min(x))
    ##if (positive) y <- log(x + adj.positive)  ## transform positive data x to real line
      ##else
      y <- x
    if (missing(h)) h <- hpi(x=y, binned=default.bflag(d=d, n=n), bgridsize=bgridsize)
  }
  if (missing(H) & d>1)
  {
      H <- Hpi(x=x, binned=default.bflag(d=d, n=n), bgridsize=bgridsize, verbose=verbose)
  }

  if (missing(bgridsize)) bgridsize <- default.gridsize(d)
  if (missing(gridsize)) gridsize <- default.gridsize(d)
  
  ## initialise grid 
  n <- nrow(x)
  gridx <- make.grid.ks(x, matrix.sqrt(H), tol=supp, gridsize=gridsize, xmin=xmin, xmax=xmax, gridtype=gridtype) 

  suppx <- make.supp(x, matrix.sqrt(H), tol=supp)

  grid.pts <- find.gridpts(gridx, suppx)    
  fhat.grid <- matrix(0, nrow=length(gridx[[1]]), ncol=length(gridx[[2]]))
  if (verbose) pb <- txtProgressBar()
  
  for (i in 1:n)
  {
    ## compute evaluation points 
    eval.x <- gridx[[1]][grid.pts$xmin[i,1]:grid.pts$xmax[i,1]]
    eval.y <- gridx[[2]][grid.pts$xmin[i,2]:grid.pts$xmax[i,2]]
    eval.x.ind <- c(grid.pts$xmin[i,1]:grid.pts$xmax[i,1])
    eval.y.ind <- c(grid.pts$xmin[i,2]:grid.pts$xmax[i,2])
    eval.x.len <- length(eval.x)
    eval.pts <- expand.grid(eval.x, eval.y)
    fhat <- rep(1, nrow(eval.pts)) ##dmvnorm(eval.pts, x[i,], H)
    ## place vector of density estimate values `fhat' onto grid 'fhat.grid' 
    for (j in 1:length(eval.y))
      fhat.grid[eval.x.ind, eval.y.ind[j]] <- 
        fhat.grid[eval.x.ind, eval.y.ind[j]] + 
          w[i]*fhat[((j-1) * eval.x.len + 1):(j * eval.x.len)]
    if (verbose) setTxtProgressBar(pb, i/n)
  }
  if (verbose) close(pb)
  ##fhat.grid <- fhat.grid/n
  gridx1 <- list(gridx[[1]], gridx[[2]]) 
  
  fhat <- list(x=x, eval.points=gridx1, estimate=fhat.grid>=1, H=H, gridtype=gridx$gridtype, gridded=TRUE)

  fhat$binned <- binned
  fhat$names <- parse.name(x)  ## add variable names
  fhat$w <- w
  class(fhat) <- "kde"
  
  return(fhat)
}

