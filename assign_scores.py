### Load libraries --------------------------
print("Loading libraries...")

import pyodbc
import pandas as pd
import numpy as np
import datetime

from tqdm import tqdm

### Load and create local data --------------
print("Loading and creating local data...")

file_path = "C:\\Users\\agozacan\\OneDrive - Humberside Fire and Rescue Service\\Fire Fatality Profiling\\Input and Output\\"

mosaic_means = pd.read_csv(file_path+"mosaic_means.csv")

exeter = pd.read_csv(file_path+"exeter_data.csv")

multipliers = pd.DataFrame({
    "Attribute" : ["Base score",
                   "Is living alone",
                   "Is aged 80 or over and female",
                   "Is aged 65 to 79 and male",
                   "Is aged 65 to 79 and female",
                   "Is aged 80 or over and male",
                   "Is a smoker and male",
                   "Is a smoker and female",
                   "Has restricted mobility",
                   "Regularly drinks alcohol once or more per day",
                   "Is living in social rented housing",
                   "Lives outside of 8 minute response zone"],
    "Multiplier" : [1.00, 1.78, 2.00, 2.08, 2.37, 2.63, 4.52, 6.68, 1.10, 1.10, 3.89, 1.10],
    "Mosaic_Index" : ["--", 31, "--", "--", "--", "--", [1033, 0], [1033, 0], 1278, 1049, 102, "--"]})

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

    if mosaic_means.iloc[31, i] > mosaic_means.iloc[31, -82]:

        mosaic_scores.loc[i+66, "Single"] = 1

    if mosaic_means.iloc[1033, i] > mosaic_means.iloc[1033, -82]:

        mosaic_scores.loc[i+66, "Smoker"] = 1

    if mosaic_means.iloc[1278, i] > mosaic_means.iloc[1278, -82]:

        mosaic_scores.loc[i+66, "Restricted_Mobility"] = 1

    if mosaic_means.iloc[1049, i] > mosaic_means.iloc[1049, -82]:

        mosaic_scores.loc[i+66, "Alcohol"] = 1

    if mosaic_means.iloc[102, i] > mosaic_means.iloc[102, -82]:

        mosaic_scores.loc[i+66, "Rented"] = 1

mosaic_scores.replace(np.nan, 0, inplace=True)

df = df.merge(right=mosaic_scores, left_on="Type_Desc", right_on="Mosaic_Type", how="left")

for i in tqdm(range(len(df))):

    score = multipliers.iloc[0, 1]

    if df.loc[i, "Response"] == "Outside":

        score = score * multipliers.iloc[11, 1]

    if df.loc[i, "Restricted_Mobility"] == 1:

        score = score * multipliers.iloc[8, 1]

    if df.loc[i, "Alcohol"] == 1:

        score = score * multipliers.iloc[9, 1]

    if df.loc[i, "Rented"] == 1:

        score = score * multipliers.iloc[10, 1]

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

df.to_csv(file_path+"output.csv", index=False)

### Complete
print("Done.")