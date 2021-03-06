#' @title Extended Cosinor Model for Circadian Rhythmicity
#' @description A parametric approach to study circadian rhythmicity assuming cosinor shape.
#' Here we used the anti logistic transformed cosine curves, which provided 5 parameters.
#'
#'
#' @param x \code{vector} vector of dimension n*1440 which reprsents n days of 1440 minute activity data
#' @param logtransform Conduct log transfomation before. Default is \code{TRUE}.
#'
#' @importFrom minpack.lm nls.lm nls.lm.control
#' @importFrom stats coef residuals
#'
#' @return A list with elements
#' \item{min}{minimum}
#' \item{amp}{amplitude}
#' \item{alpha}{alpha parameter:determines whether the peaks of the curve are wider than the troughs}
#' \item{beta}{beta parameter: determines whether the function rises and falls more steeply than the cosine curve}
#' \item{acro}{acrophase}
#' \item{F_imp}{pseudo-F statistics}
#'
#' @export
#' @examples
#' count.days = rpois(1440*5, lambda = 5)
#' extcos = ExtCos(x = count.days, logtransform  = TRUE)
#'
#'



ExtCos <- function(
  x,
  logtransform = TRUE){

  if(logtransform){
    x = log(x + 1)
  }
  n.days <- length(x)/1440
  tmp.dat <- data.frame(time = rep(1:1440, n.days) / 60, Y = x)
  #fit <- cosinor.lm(Y ~ time(time) + 1, data = tmp.dat, period = 24)
  #####stage 1#####
  par <- c(1, 1, 1)
  fit.nls <- nls.lm(par = par, fn = fn.res1, tmp.dat = tmp.dat)
  coef.nls <- coef(fit.nls)
  #####stage 2#######
  newpar <- c(coef.nls[1] - abs(coef.nls[2]), 2 * abs(coef.nls[2]), 0, 2, coef.nls[3])
  fit2.nls <- nls.lm(newpar, fn = fn.res2, tmp.dat = tmp.dat, control = nls.lm.control(maxiter = 1000))

  cosinor.stat = as.numeric(coef(fit2.nls))

  rss_cos = sum(residuals(fit.nls)^2)
  rss_ext = sum(residuals(fit2.nls)^2)
  F_imp = ((rss_cos - rss_ext)/2)/(rss_ext/(nrow(tmp.dat) - 5))


  return(  list(min = cosinor.stat[1],
                amp = abs(cosinor.stat[2]),
                alpha = cosinor.stat[3],
                beta = cosinor.stat[4],
                acro = cosinor.stat[5],
                F_imp = F_imp))
}

fn.res1 <- function(par, tmp.dat) {
  tmp.dat[, 2] - (par[1] + par[2] * cos((tmp.dat[, 1] - par[3]) * 2 * pi / 24))
}

fn.res2 <- function(par, tmp.dat) {
  ct <- cos((tmp.dat[, 1] - par[5]) * 2 * pi / 24)
  lct <- exp(par[4] * (ct - par[3])) / (1 + exp(par[4] * (ct - par[3])))
  rt <- par[1] + par[2] * lct
  tmp.dat[, 2] - rt
}
