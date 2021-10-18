setwd("C:/Users/agozacan/OneDrive - Humberside Fire and Rescue Service/Fire Fatality Profiling/Data")
df <- read.csv("model_data.csv")

for(i in 1:(ncol(df)-1)){
  df[,i] <- as.factor(df[,i])
}

training_indices = sample(1:length(df$FATALITY), round(0.7 * length(df$FATALITY)), replace=FALSE)

training_data = df[training_indices,]
test_data = df[-training_indices,]

logreg <- glm(FATALITY ~ ., data = training_data, family = binomial(link = "logit"))
logreg
summary(logreg)
anova(logreg)

#### BEHIND THE SCENES ####

# library(caret)
# dummy <- dummyVars(" ~ .", data = df[,1:ncol(df)-1])
# X <- data.frame(predict(dummy, newdata = df))
# library(dplyr) 
# X <- X %>% select(-contains(".0"))
# X <- cbind(rep(1), X)
# 
# X <- as.matrix(X)
# coeffs <- as.vector(logreg$coefficients)
# dim(t(X))
# length(coeffs)
# 
# predictors <- as.vector(logreg$coefficients) %*% t(X)
# 
# response <- function(eta){
#   return(exp(eta) / (1 + exp(eta)))
# }
# 
# probabilities <- sapply(predictors, FUN = response)
# 
# hist(predictors)
# hist(probabilities)

#### OR.......... ####

probabilities2 <- predict(logreg, newdata = test_data, type = "response")
hist(probabilities2)

#### PLOT ####

test_data$PREDICTION <- probabilities2
library(pROC)
roc(FATALITY ~ PREDICTION, data = test_data, plot = TRUE)

#### CONFUSION MATRIX ####

for(i in 1:length(test_data$FATALITY)){
  test_data$PREDICTION_BINARY[i] = round(test_data$PREDICTION[i])
}

library(caret)
confusionMatrix(as.factor(test_data$FATALITY), as.factor(test_data$PREDICTION_BINARY), positive = "1")

# counts <- c(sum(df$VICTIM_LOCATION_FOUND == 0 & df$FATALITY == 0 & df$VICTIM_LOCATION_START == 0),
#             sum(df$VICTIM_LOCATION_FOUND == 1 & df$FATALITY == 0 & df$VICTIM_LOCATION_START == 0),
#             sum(df$VICTIM_LOCATION_FOUND == 0 & df$FATALITY == 1 & df$VICTIM_LOCATION_START == 0),
#             sum(df$VICTIM_LOCATION_FOUND == 1 & df$FATALITY == 1 & df$VICTIM_LOCATION_START == 0),
#             sum(df$VICTIM_LOCATION_FOUND == 0 & df$FATALITY == 0 & df$VICTIM_LOCATION_START == 1),
#             sum(df$VICTIM_LOCATION_FOUND == 1 & df$FATALITY == 0 & df$VICTIM_LOCATION_START == 1),
#             sum(df$VICTIM_LOCATION_FOUND == 0 & df$FATALITY == 1 & df$VICTIM_LOCATION_START == 1),
#             sum(df$VICTIM_LOCATION_FOUND == 1 & df$FATALITY == 1 & df$VICTIM_LOCATION_START == 1))
# 
# df2 <- data.frame(expand.grid(VICTIM_LOCATION_FOUND = c("0", "1"),
#                               FATALITY = c("0", "1"),
#                               VICTIM_LOCATION_START = c("0", "1")),
#                               COUNT = counts)
# 
# cont_table <- xtabs(COUNT ~ VICTIM_LOCATION_START + FATALITY + VICTIM_LOCATION_FOUND, data = df2)
# 
# mantelhaen.test(cont_table)
