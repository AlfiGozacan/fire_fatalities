import pandas as pd
import numpy as np
from sklearn.model_selection import train_test_split
from sklearn.ensemble import AdaBoostClassifier
from sklearn.ensemble import RandomForestClassifier
from sklearn.linear_model import LogisticRegression
from sklearn.ensemble import GradientBoostingClassifier
from sklearn.metrics import classification_report
import scikitplot as skplt
import matplotlib.pyplot as plt

df = pd.read_csv("C:\\Users\\agozacan\\OneDrive - Humberside Fire and Rescue Service\\Fire Fatality Profiling\\Data\\model_data.csv")

ncols = len(df.columns)

training_set, test_set = train_test_split(df, test_size = 0.3)

X_train = training_set.iloc[:,:ncols-1]
y_train = training_set.iloc[:,ncols-1]
X_test = test_set.iloc[:,:ncols-1]
y_test = test_set.iloc[:,ncols-1]

adaboost = AdaBoostClassifier(n_estimators = 100, base_estimator = None, learning_rate = 1)
adaboost.fit(X_train, y_train)

rf = RandomForestClassifier()
rf.fit(X_train, y_train)

logreg = LogisticRegression()
logreg.fit(X_train, y_train)

xgboost = GradientBoostingClassifier()
xgboost.fit(X_train, y_train)

y_ada_pred = adaboost.predict(X_test)
test_set.insert(ncols, "AdaBoost Predictions", y_ada_pred)

y_rf_pred = rf.predict(X_test)
test_set.insert(ncols+1, "RF Predictions", y_rf_pred)

y_lr_pred = logreg.predict(X_test)
test_set.insert(ncols+2, "LogReg Predictions", y_lr_pred)

y_xg_pred = xgboost.predict(X_test)
test_set.insert(ncols+3, "XGBoost Predictions", y_xg_pred)

print("AdaBoost:", classification_report(test_set.iloc[:,ncols-1], test_set.iloc[:,ncols]))
print("Random Forest:", classification_report(test_set.iloc[:,ncols-1], test_set.iloc[:,ncols+1]))
print("Logistic Regression:", classification_report(test_set.iloc[:,ncols-1], test_set.iloc[:,ncols+2]))
print("XGBoost:", classification_report(test_set.iloc[:,ncols-1], test_set.iloc[:,ncols+3]))

length = len(test_set.iloc[:,ncols-1])

ada_no_matched = sum([(test_set.iloc[i,ncols-1] * test_set.iloc[i,ncols]) + ((1-test_set.iloc[i,ncols-1]) * (1-test_set.iloc[i,ncols])) for i in range(length)])
rf_no_matched = sum([(test_set.iloc[i,ncols-1] * test_set.iloc[i,ncols+1]) + ((1-test_set.iloc[i,ncols-1]) * (1-test_set.iloc[i,ncols+1])) for i in range(length)])
lr_no_matched = sum([(test_set.iloc[i,ncols-1] * test_set.iloc[i,ncols+2]) + ((1-test_set.iloc[i,ncols-1]) * (1-test_set.iloc[i,ncols+2])) for i in range(length)])
xg_no_matched = sum([(test_set.iloc[i,ncols-1] * test_set.iloc[i,ncols+3]) + ((1-test_set.iloc[i,ncols-1]) * (1-test_set.iloc[i,ncols+3])) for i in range(length)])

ada_accuracy = ada_no_matched / length
rf_accuracy = rf_no_matched / length
lr_accuracy = lr_no_matched / length
xg_accuracy = xg_no_matched / length

print("AdaBoost Proportion Correctly Guessed:", ada_accuracy)
print("Random Forest Proportion Correctly Guessed:", rf_accuracy)
print("Logistic Regression Proportion Correctly Guessed:", lr_accuracy)
print("XGBoost Proportion Correctly Guessed:", xg_accuracy)

adaprobs = adaboost.predict_proba(X_test)
rfprobs = rf.predict_proba(X_test)
lrprobs = logreg.predict_proba(X_test)
xgprobs = xgboost.predict_proba(X_test)

#### PLOTS

probas = [adaprobs, rfprobs, lrprobs, xgprobs]
titles = ["AdaBoost", "Random Forest", "Logistic Regression", "XGBoost"]

for i in range(len(probas)):
    
    skplt.metrics.plot_roc(y_test, probas[i], title=titles[i])
 
plt.show()