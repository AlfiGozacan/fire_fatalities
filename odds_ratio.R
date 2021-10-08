odds.ratio <- function(x, conf.level=0.95, theta0=1, alternative="two.sided") {
  
  if(any(x == 0)) x = x + 0.5
  
  theta = (x[1,1]*x[2,2]) / (x[1,2]*x[2,1])
  
  log.estimator <- log(theta)
  
  asympt.SE <- sqrt(1/x[1,1] + 1/x[1,2] + 1/x[2,1] + 1/x[2,2])
  
  alpha = 1 - conf.level
  
  Ztest <- (log.estimator - log(theta0)) / asympt.SE
  
  p.value <- 2 * pnorm(abs(Ztest), lower.tail=FALSE)
  
  log.conf.interval <- log.estimator + c(-1,1) * qnorm(1-alpha/2) * asympt.SE
  
  conf.interval <- exp(log.conf.interval)
  
  if (alternative == "two.sided") {
    
    return(list(estimator = theta,
                log.estimator = log.estimator,
                asympt.SE = asympt.SE,
                log.conf.interval = log.conf.interval,
                conf.interval = conf.interval,
                Ztest = Ztest,
                p.value = p.value))
    
  } else if (alternative == "less") {
    
    Zcrit <- - qnorm(conf.level, lower.tail=TRUE)
    
    return(list(estimator = theta,
                asympt.SE = asympt.SE,
                Ztest = Ztest,
                Zcrit=Zcrit))
    
  } else if (alternative == "greater") {
    
    Zcrit <- qnorm(conf.level, lower.tail=TRUE)
    
    return(list(estimator = theta,
                asympt.SE = asympt.SE,
                Ztest = Ztest,
                Zcrit=Zcrit))
    
  }
  
}