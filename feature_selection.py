import pandas as pd
import numpy as np
from sklearn.model_selection import train_test_split
from sklearn.ensemble import GradientBoostingClassifier
import matplotlib.pyplot as plt
import seaborn as sns

df = pd.read_csv("C:\\Users\\agozacan\\OneDrive - Humberside Fire and Rescue Service\\Fire Fatality Profiling\\Data\\model_data_dummy.csv")

ncols = len(df.columns)

training_set, test_set = train_test_split(df, test_size = 0.3)

X_train = training_set.iloc[:,:-1]
y_train = training_set.iloc[:,-1]
X_test = test_set.iloc[:,:-1]
y_test = test_set.iloc[:,-1]

xgboost = GradientBoostingClassifier()
xgboost.fit(X_train, y_train)

features = xgboost.feature_importances_

ftrs = pd.DataFrame({"column_name": df.columns[:-1], "score": features}).sort_values(by = "score", ascending = False).reset_index(drop=True)
print(ftrs)

plt.figure(figsize=(10,8))
sns.barplot(y = ftrs.loc[:15, "column_name"], x = ftrs.loc[:15, "score"])
plt.title("XGBoost Feature Importance")
plt.xlabel("Score")
plt.ylabel("Column Names")
# plt.savefig("C:\\Users\\agozacan\\OneDrive - Humberside Fire and Rescue Service\\Fire Fatality Profiling\\Reports\\Pictures\\features_levels.png", dpi = 200, bbox_inches = "tight")
plt.show()