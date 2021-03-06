# fire_fatalities
A machine learning approach to profiling fire-related incidents where a fatality is most likely to occur.

This project uses data available from the UK government's fire statistics catalogue: https://www.gov.uk/government/statistics/fire-statistics-incident-level-datasets. In particular, the "casualties in fires" dataset and "fire-related fatalities" dataset.

If following my R code, run odds_ratio.R, casualties_clean.R, and fatalities_clean.R before running casualties.R and fatalities.R.

If following my Python code, run clean_combine.ipynb or clean_combine_dummy.ipynb (for dummy encoding) before ml_models.py or feature_selection.py. Alternatively, combined_code.py contains all the model code together in one place.

The score assigning code is available in assign_scores.py, which produces final output in terms of a .csv file, with UPRN and final score.
