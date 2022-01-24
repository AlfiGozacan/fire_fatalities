### Load libraries --------------------------
print("Loading libraries...")

import pyodbc
import pandas as pd
import numpy as np
import math
import datetime

from tqdm import tqdm

### Load and create local data --------------
print("Loading and creating local data...")

mosaic_means = pd.read_csv("C:\\Users\\agozacan\\OneDrive - Humberside Fire and Rescue Service\\Experian Data\\mosaic_means.csv")

exeter = pd.read_csv("C:\\Users\\agozacan\\OneDrive - Humberside Fire and Rescue Service\\Exeter Data\\exeter_data.csv")

multipliers = pd.DataFrame({
    "Attribute" : ["Base score",
                   "Is living alone",
                   "Is aged 80 or over and female",
                   "Is aged 65 to 79 and male",
                   "Is aged 65 to 79 and female",
                   "Is aged 80 or over and male",
                   "Is a smoker and male",
                   "Is a smoker and female"],
    "Multiplier" : [1.00, 1.78, 2.00, 2.08, 2.37, 2.63, 4.52, 6.68]})

### Connect to SQL Server -------------------
print("Connecting to SQL Server (HQCFRMISSQL)...")

server = "HQCFRMISSQL"
database = "CFRMIS_HUMBS"

cnxn = pyodbc.connect("DRIVER={SQL Server};SERVER="+server+";DATABASE="+database)

### Load server data
print("Loading server data...")

query = '''
select *
from MosaicCurrent
'''

dwellings = pd.read_sql(query, cnxn)

### Clean data
print("Cleaning data...")

exeter.dropna(axis=0, subset=["UPRN"], inplace=True)
exeter.rename(columns={"Postcode": "postcode"}, inplace=True)

exeter["UPRN"] = [int(x) for x in exeter["UPRN"]]
dwellings["UPRN"] = [int(x) for x in dwellings["UPRN"]]

now = datetime.datetime.now()
year = now.year
exeter["Age"] = [year - x for x in exeter["Year_Of_Birth"]]

df = dwellings.merge(right=exeter, on="UPRN", how="left")
df.drop(df.index[df["Type_Desc"] == "99"], axis=0, inplace=True)

df["Type_Desc"].replace("-", "", regex=True, inplace=True)

### Assign scores
print("Assigning scores to all households...")

mosaic_scores = pd.DataFrame({
    "Mosaic_Type" : mosaic_means.columns[-66:]
})

for i in range(-66, 0):

    if mosaic_means.iloc[0, i] > mosaic_means.iloc[0, -82]:

        mosaic_scores.loc[i+66, "Male"] = 1

for i in range(-66, 0):

    if mosaic_means.iloc[31, i] > mosaic_means.iloc[31, -82]:

        mosaic_scores.loc[i+66, "Single"] = 1

    if mosaic_means.iloc[1033, i] > mosaic_means.iloc[1033, -82]:

        mosaic_scores.loc[i+66, "Smoker"] = 1

mosaic_scores.replace(np.nan, 0, inplace=True)

df = df.merge(right=mosaic_scores, left_on="Type_Desc", right_on="Mosaic_Type", how="left")

for i in tqdm(range(len(df))):

    score = multipliers.iloc[0, 1]

    if df.loc[i, "Single"] == 1:

        score = score * multipliers.iloc[1, 1]

    if df.loc[i, "Gender"] == np.nan:

        if df.loc[i, "Smoker"] == 1:

            if df.loc[i, "Male"] == 1:

                score = score * multipliers.iloc[6, 1]

            else:

                score = score * multipliers.iloc[7, 1]

    else:

        if df.loc[i, "Gender"] == "M":

            if df.loc[i, "Smoker"] == 1:

                score = score * multipliers.iloc[6, 1]

            if df.loc[i, "Age"] >= 65 and df.loc[i, "Age"] <= 79:

                score = score * multipliers.iloc[3, 1]

            elif df.loc[i, "Age"] >= 80:

                score = score * multipliers.iloc[5, 1]

        else:

            if df.loc[i, "Smoker"] == 1:

                score = score * multipliers.iloc[7, 1]

            if df.loc[i, "Age"] >= 65 and df.loc[i, "Age"] <= 79:

                score = score * multipliers.iloc[4, 1]

            elif df.loc[i, "Age"] >= 80:

                score = score * multipliers.iloc[2, 1]
    
    df.loc[i, "Final_Score"] = score

### Save file
print("Saving dataframe of assigned scores...")

df.to_csv("C:\\Users\\agozacan\\OneDrive - Humberside Fire and Rescue Service\\Fire Fatality Profiling\\Data\\final_scores.csv", index=False)

### Complete
print("Done.")