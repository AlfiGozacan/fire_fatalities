### Load libraries --------------------------
print("Loading libraries...")

import pyodbc
import pandas as pd
import numpy as np
import datetime

from tqdm import tqdm
from thefuzz import process
from itertools import compress

### Load and create local data --------------
print("Loading and creating local data...")

file_path = "C:\\Users\\agozacan\\OneDrive - Humberside Fire and Rescue Service\\Fire Fatality Profiling\\Input and Output\\"

mosaic_means = pd.read_csv(file_path+"mosaic_means.csv")

exeter = pd.read_csv(file_path+"exeter_data.csv")

initial_length = len(exeter)

exeter.drop(exeter.index[exeter["Address_Line_1"].str.contains("care home", case=False, regex=True).replace(np.nan, False)], axis=0, inplace=True)

exeter.drop(exeter.index[exeter["Address_Line_1"].str.contains("residential", case=False, regex=True).replace(np.nan, False)], axis=0, inplace=True)

final_length = len(exeter)

print(f"{initial_length - final_length} entries in the Exeter dataset have been dropped due to them referencing care homes.")

exeter.reset_index(drop=True, inplace=True)

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

dwellings.drop(dwellings.index[dwellings["Type_Desc"] == "U-99"], axis=0, inplace=True)
dwellings.reset_index(drop=True, inplace=True)

exeter.replace(np.nan, "", inplace=True)
exeter["UPRN"].replace("", 0, inplace=True)

dwellings["UPRN"] = [int(x) for x in dwellings["UPRN"]]
exeter["UPRN"] = [int(x) for x in exeter["UPRN"]]

bad_indices = exeter.index[~exeter["UPRN"].isin(dwellings["UPRN"])]

dwellings["Postcode"].replace(" ", "", regex=True, inplace=True)
exeter["Postcode"].replace(" ", "", regex=True, inplace=True)

address_strings = []

for i in tqdm(range(len(dwellings))):

    string = " ".join(entry for entry in dwellings.iloc[i, 1:10])

    address_strings.append(string)

exeter_strings = []

for i in tqdm(bad_indices):

    string = " ".join(entry for entry in exeter.iloc[i, [2, 3, 4, 5, 7]])

    exeter_strings.append(string)

matching_indices = []

final_fuzz_ratios = []

for i in tqdm(range(len(exeter_strings))):

    viable_addresses = list(compress(address_strings, [x[-7:] == exeter_strings[i][-7:] for x in address_strings]))

    if len(viable_addresses) == 0:

        matching_indices.append(0)

        final_fuzz_ratios.append(0)

        continue

    pair = process.extractOne(exeter_strings[i], viable_addresses)

    address = pair[0]

    match_score = pair[1]

    matching_indices.append(address_strings.index(address))

    final_fuzz_ratios.append(match_score)

exeter.loc[bad_indices, "UPRN"] = list(dwellings.loc[matching_indices, "UPRN"])

exeter.loc[bad_indices, "is_Matched"] = 1

exeter.loc[bad_indices, "Match_Score"] = final_fuzz_ratios

remove_indices = exeter.index[exeter["Match_Score"] < 75]

exeter.drop(remove_indices, axis=0, inplace=True)

print(f"{len(remove_indices)} entries in the Exeter dataset have been dropped due to their UPRNs not having a match.")

exeter.reset_index(drop=True, inplace=True)

exeter.rename(columns={"Postcode" : "Postcode_2"}, inplace=True)

now = datetime.datetime.now()
year = now.year
exeter["Age"] = [year - x for x in exeter["Year_Of_Birth"]]

df = dwellings.merge(right=exeter, on="UPRN", how="left")

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

### Tidy up columns and split into quantiles
print("Tidying output and splitting into quantiles...")

df.drop(["Group_Desc",
         "Type_Desc",
         "Exeter",
         "Total_Mosa",
         "Total_Prio",
         "Final_Prio",
         "Address_Line_5",
         "firearea",
         "firename",
         "Frailty_Score",
         "Frailty_Group"], axis=1, inplace=True)

df.rename(columns = {
    "SubBuildin" : "Sub_Building",
    "BuildingNa" : "Building_Name",
    "StreetNumb" : "Street_Number",
    "DependentS" : "Dependent_Street",
    "DoubleDepe" : "Double_Dependent_Locality",
    "DependentL" : "Dependent_Locality",
    "NAME" : "Local_Authority",
    "STNNAME" : "Station_Number",
    "NAME_1" : "Ward"
}, inplace=True)

df.insert(df.columns.get_loc("Ward")+1, "is_Exeter", [int(x) for x in ~df["Gender"].isnull()])

initial_length = len(df)

df = df.sort_values(by="Final_Score", ascending=False).drop_duplicates(subset="UPRN", keep="first").reset_index(drop=True)

final_length = len(df)

num_exeter = len(df[df["is_Exeter"] == 1])

print(f"{initial_length - final_length} entries in the dataset have been dropped due to them having duplicate UPRNs (highest risk is kept).")
print(f"There are {len(df)} dwellings in the final output, of which {num_exeter} are from the Exeter list.")

noisy_score = (np.array(df["Final_Score"]) + np.random.random(size=len(df)) * 1e-5)

df["Quantile"] = pd.qcut(noisy_score, q=9, labels=["NR", "F", "E", "D", "C", "B", "B+", "A", "A+"])

### Save file
print("Saving final dataframe...")

df.to_csv(file_path+"output.csv", index=False)

### Complete
print("Done.")