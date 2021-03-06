# Method regarima for the function plot (documentation in the file sa_plot.R)
#' @name plot
#' @rdname plot
#' @export
plot.regarima = function(x, which = c(1:6), dec_zoom=FALSE,
     caption = list("Residuals","Histogram of residuals","Normal Q-Q","ACF of residuals",
                    "PACF of residuals","Decomposition"),
     ask = prod(par("mfcol")) < length(which) && dev.interactive(),
     ...){

if (!inherits(x, "regarima"))
  stop("use only with \"regarima\" object")
if (!is.numeric(which) || any(which < 1) || any(which > 6))
  stop("'which' must be in 1:6")
show <- rep(FALSE, 6)
show[which] <- TRUE
op <- par()
sub.caption = NULL
cex.caption = 1
cex.oma.main = 1.25
# Define additional variables for selected graphs:
if (any(show[2L:3L])) {
  sres <- (x$residuals - mean(x$residuals))/sd(x$residuals)
}
if (any(show[4L:5L])) {
  freq<- attributes(x$residuals)$tsp[3]
  maxlag <- freq*3
  res_acf<- acf(as(x$residuals,"numeric"), lag.max = maxlag, type = c("correlation"), plot = FALSE)
  res_pcf<-pacf(as(x$residuals,"numeric"), lag.max = maxlag, plot = FALSE)
  nlags<-min(c(length(res_acf$lag),maxlag))
  lablags<-seq(0, nlags, freq/2)
}
  if (show[6L]) {
  model <- x$model$effects
  y_lin <- model[,1]
  cal.effect <- model[,2]+model[,3]+model[,4]
  out.effect <- model[,8]
  y_lin_cal <- y_lin + cal.effect
  y_lin_out <- y_lin + out.effect
  y <- y_lin + cal.effect + out.effect
  decomp<-cbind(y_lin,cal.effect,out.effect,y_lin_cal,y_lin_out,y)
  colnames(decomp)<-c("y_linearized","calendar","outliers","y_linearized_cal","y_linearized_out","y")
}
getCaption <- function(k) {if (length(caption) < k)
{NA_character_}
  else
    as.graphicsAnnot(caption[[k]])}

one.fig <- prod(par("mfcol")) == 1
if (ask) {
  oask <- devAskNewPage(TRUE)
  on.exit(devAskNewPage(oask))
}
if (show[1L]) {
  plot.ts(x$residuals, type="h", ylab="Residuals")
  abline(h=rep(0,length(x$residuals)))
  if (one.fig)
    title(sub = sub.caption, ...)
  mtext(getCaption(1), 3, 0.25, cex = cex.caption)
  dev.flush()
}
if (show[2L]) {
  histv <- hist(sres,plot = FALSE)
  ylim<- max(max(histv$density),0.45)
  plot(histv,freq=FALSE, xlab="Standardized residuals", main="", ylim=c(0,ylim))
  curve(dnorm(x, mean=0, sd=1), add=TRUE, col=3)
  if (one.fig)
    title(sub = sub.caption, ...)
  mtext(getCaption(2), 3, 0.25, cex = cex.caption)
  dev.flush()
}
if (show[3L]) {
  ylim <- range(sres, na.rm = TRUE)
  ylim[2L] <- ylim[2L] + diff(ylim) * 0.075
  dev.hold()
  qq <- qqnorm(sres, main = "", ylab = "Standardized residuals", ylim = ylim,
               ...)
  qqline(sres, lty = 3, col = "gray50")
  if (one.fig)
    title(sub = sub.caption, ...)
  mtext(getCaption(3), 3, 0.25, cex = cex.caption)
  dev.flush()
}
if (show[4L]) {
  plot(res_acf[1: (length(res_acf$lag)-1)],xaxt="n",main="")
  axis(1,lablags,labels=lablags)
  if (one.fig)
    title(sub = sub.caption, ...)
  mtext(getCaption(4), 3, 0.25, cex = cex.caption)
  dev.flush()
}
if (show[5L]) {
  plot(res_pcf,xaxt="n", main="")
  axis(1,lablags,labels=lablags)

  if (one.fig)
    title(sub = sub.caption, ...)
  mtext(getCaption(5), 3, 0.25, cex = cex.caption)
  dev.flush()
}

if (show[6L]) {

  plot.ts(decomp[,c(1,6)],type="l",pch=1, col=c(1:2), ylab="",plot.type = "single")
  legend("topleft", legend = c("y linearised","y (= y lin. + cal. + out.)"), col=1:2, bty="n",lty = 1)


  if (one.fig)
    title(sub = sub.caption, ...)
  mtext(getCaption(6), 3, 0.25, cex = cex.caption)
  dev.flush()
  # Decomposition - zoom
  if (dec_zoom == TRUE){
    owind<-dev.cur()
    #x11()
    dev.new()
    layout((1:3))
    plot.ts(decomp[,1], type="l", ylab="y linearised", col=c(1), main ="Decomposition - zoom")
    plot.ts(decomp[,2], type="l", ylab="calendar effects", col=c(2),main="")
    plot.ts(decomp[,3], type="l", ylab="outliers effects", col=c(3),main="")
    rcoef <- x$regression.coefficients

    desc_i<-grep("(",rownames(rcoef), fixed=TRUE)
    if (length(desc_i)>0 & length(desc_i)<10 ){
      desc<-c()
      for (i in 1: length(desc_i))
        desc<-c(desc,paste(rownames(rcoef)[desc_i[i]],as.character(round(rcoef[desc_i[i]],2),sep=": ")))
      legend("bottomright", legend = desc, col=1, pch=NA_integer_, ncol=if (length(desc_i)<6) {1} else {2},bty="n")
    }
    dev.set(owind)
  }
}
if (!one.fig && par("oma")[3L] >= 1)
  mtext(sub.caption, outer = TRUE, cex = cex.oma.main)
par(ask = op$ask)
invisible()
}


