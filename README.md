# Herrnstadt & Sweeney (2019): Data and code for replication

This repo contains the data and code for replication for "Housing Market Capitalization of Pipeline Risk: Evidence from the San Bruno Explosion"

A draft of the paper is available [here](draft/HS_Pipelines.pdf).

### DATA DISCLOSURE NOTE
Please note that the core analysis relies on two proprietary datasets that we are unable to share publicly. The first dataset, containing housing transactions in California was obtained from DataQuick (now CoreLogic). The second dataset, a shapefile of natural gas transmission pipeline locations was purchased from Platts. Both datasets can be purchased by contacting these parties directly. 

For any researchers who do obtain access to these data, you can find a description how to run the code in this repo below.

## NOTES ON ORDER OF RUNNING FILES

### BUILD FILES
- FIRST RUN:
build/clean_history_data.do
build/clean_assessor_data.do

- THEN RUN: 
build/create_sample.do


### ANALYSIS FILES
- FIRST RESTRICT SAMPLE:
analysis/prep_pdd_data.do

- THEN RUN REGRESSION FILES:
pdd_PGE_xs_1k_singfam
pdd_BayArea_xs_1k
pdd_BayArea_xs_1k_ddd
pdd_PGE_pfe_1k
pdd_PGE_xs_1k
pdd_PGE_xs_1k_covars
pdd_PGE_xs_1k_ddd
pdd_PGE_xs_1k_qtr
PGE_letter_RD_for_draft

- THEN RUN FILES TO MAKE TABLES AND FIGURES IN PAPER
regression_tables
tabs_n_figs_sample
tabs_n_figs_qtr_export_exec_sum
tabs_n_figs_signfam
platts_positional_accuracy_fordraft
tabs_n_figs_pfe
tabs_n_figs_qtr
pdd_sample_descriptives
balance_PGE_postcrash