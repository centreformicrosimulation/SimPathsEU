Construction of the SimPaths Input Datasets 

Date: 6/6/26
Author: A Burdett

Workflow summary: 

1. Obtain the required longitudinal EU-SILC releases. 

2. Run the GESIS compilation program using the earlier longitudinal release to produce the harmonised 2005-2020 D, H, R, and P datasets. 

3. Run the extended version of the GESIS compilation program using the 2024 longitudinal release to produce the harmonised 2005-2023 D, H, R, and P datasets. (Compilation files contained in …./data_construction/SILC_construction/2005_2023_panel/.)

4. Run the SimPaths UID construction files for the country of interest, contained in the ”data_construction/UID_construction/” folder. During this process, the variables affected by post-2020 coding changes are merged from the 2005-2020 dataset into the 2005-2023 dataset. This creates the UID file (“…ipop.dta”) which is used to both process estimation and for internal validation of SimPaths, as well as the annual cross-sections used to initialise the model. 

