setwd("C:/Users/agozacan/OneDrive - Humberside Fire and Rescue Service/Fire Fatality Profiling/Data")
df <- read.csv("model_data.csv")

for(i in 1:(ncol(df)-1)){
  df[,i] <- as.factor(df[,i])
}

logreg <- glm(FATALITY ~ ., data = df, family = binomial(link = "logit"))
logreg
summary(logreg)
anova(logreg)

#### BEHIND THE SCENES ####

library(caret)
dummy <- dummyVars(" ~ .", data = df[,1:ncol(df)-1])
X <- data.frame(predict(dummy, newdata = df))
library(dplyr) 
X <- X %>% select(-contains(".0"))
X <- cbind(rep(1), X)

X <- as.matrix(X)
coeffs <- as.vector(logreg$coefficients)
dim(t(X))
length(coeffs)

predictors <- as.vector(logreg$coefficients) %*% t(X)

response <- function(eta){
  return(exp(eta) / (1 + exp(eta)))
}

probabilities <- sapply(predictors, FUN = response)

hist(predictors)
hist(probabilities)

#### OR.......... ####

probabilities2 <- predict(logreg, newdata = df, type = "response")
hist(probabilities2)

#### PLOT ####

df$PREDICTION <- probabilities
library(pROC)
roc(FATALITY ~ PREDICTION, data = df, plot = TRUE)

#### CONFUSION MATRIX ####

for(i in 1:length(df$FATALITY)){
  df$PREDICTION_BINARY[i] = round(df$PREDICTION[i])
}

confusionMatrix(as.factor(df$FATALITY), as.factor(df$PREDICTION_BINARY), positive = "1")