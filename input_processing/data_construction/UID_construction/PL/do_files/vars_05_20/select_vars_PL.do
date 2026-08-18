/*******************************************************************************
* PROJECT:              SimPaths EU
* DO-FILE NAME:         select_vars_PL.do
* DESCRIPTION:          Collects variables from 2005-2020 panel to merge in
* COUNTRY:              PL
* AUTHORS: 				Daria Popova, Ashley Burdett
* LAST UPDATE:          Feb 2025
********************************************************************************
* NOTE:
*   Called from 02_create_variables_PL.do - see that file for further
*   details.
*
*   Collects specific variables from the 2005-2020 panel to merge into the
*   2005-2023 panel. Relevant for variables that were replaced since 2020,
*   but the replacements have not been backcoded, resulting in missing
*   data. Patch.
*
*   If input data missing, run "prepare_pooled_data _05_20_PL.do".
*
*   -----------------------------------------------------------------------
*    Output
*   -----------------------------------------------------------------------
*   temp_orig_econ_status.dta (pl030, pl031, rb210) and temp_orig_edu.dta
*   (pe040) - both merged into 02_create_variables_PL.do.
*
*   temp_orig_occu.dta (pl051) - used elsewhere, not merged in
*   02_create_variables_PL.do.
*******************************************************************************/


* Collect economic status information from previous panel 
use "$dir_data_05_20/${country}-SILC_pooled_all_obs_01.dta", clear 

keep  hid pid year pl030 pl031 rb210 

rename * *_orig
rename  pid_orig pid 
rename  year_orig year 
rename  hid_orig  hid

save "$dir_data/temp_orig_econ_status", replace 


* Collect education information from previous panel 
use "$dir_data_05_20/${country}-SILC_pooled_all_obs_01.dta", clear 

keep  hid pid year pe040

rename * *_orig
rename  pid_orig pid 
rename  year_orig year 
rename  hid_orig  hid

save "$dir_data/temp_orig_edu", replace 


* Collect occupation information 

use "$dir_data_05_20/${country}-SILC_pooled_all_obs_01.dta", clear 

keep  hid pid year pl051

rename * *_orig
rename  pid_orig pid 
rename  year_orig year 
rename  hid_orig  hid

save "$dir_data/temp_orig_occu", replace 




