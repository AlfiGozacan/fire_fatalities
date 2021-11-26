import pandas as pd
import numpy as np
from sklearn.model_selection import train_test_split
from sklearn.ensemble import GradientBoostingClassifier
import matplotlib.pyplot as plt
import seaborn as sns

nRUNS = 100

df = pd.read_csv("C:\\Users\\agozacan\\OneDrive - Humberside Fire and Rescue Service\\Fire Fatality Profiling\\Data\\model_data_onehot.csv")

df.drop("FATALITY_0", axis=1, inplace=True)

ncols = len(df.columns)

for i in range(nRUNS):

    training_set, test_set = train_test_split(df, test_size = 0.3)

    X_train = training_set.iloc[:,:-1]
    y_train = training_set.iloc[:,-1]
    X_test = test_set.iloc[:,:-1]
    y_test = test_set.iloc[:,-1]

    xgboost = GradientBoostingClassifier()
    xgboost.fit(X_train, y_train)

    features = xgboost.feature_importances_

    if i == 0:

        ftrs = pd.DataFrame({"column_name": df.columns[:-1], "score_0": features})

    else:

        ftrs.insert(i+1, "score_"+str(i), features)

for rowno in range(len(ftrs)):

    ftrs.loc[rowno, "avg"] = np.mean(list(ftrs.iloc[rowno, 1:nRUNS+1]))

ftrs = ftrs.sort_values(by="avg", ascending=False).reset_index(drop=True)

# ftrs.to_csv("C:\\Users\\agozacan\\OneDrive - Humberside Fire and Rescue Service\\Fire Fatality Profiling\\Data\\ranked_features_averaged.csv", index=False)

plt.figure(figsize=(10,8))
sns.barplot(y = ftrs.loc[:15, "column_name"], x = ftrs.loc[:15, "avg"])
plt.title("XGBoost Feature Importance")
plt.xlabel("Score")
plt.ylabel("Column Names")
# plt.savefig("C:\\Users\\agozacan\\OneDrive - Humberside Fire and Rescue Service\\Fire Fatality Profiling\\Reports\\Pictures\\features_levels_average.png", dpi = 200, bbox_inches = "tight")
plt.show()