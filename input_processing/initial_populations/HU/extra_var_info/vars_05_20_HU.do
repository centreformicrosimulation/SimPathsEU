********************************************************************************
* PROJECT:              ESPON
* DO-FILE NAME:         vars_05_20.do
* DESCRIPTION:          Collects varaibles from 2005-2020 panel to merge in 
********************************************************************************
* COUNTRY:              HU
* DATA:         	    EU-SILC panel based on the EU-SILC longitudinal datasets 
* 						created using GESIS Stata script: 
* 						https://www.gesis.org/gml/european-microdata/eu-silc.
******************************************************************************** 
* AUTHORS: 				Ashley Burdett
* LAST UPDATE:          Feb 2025
* NOTE:					Collects variables from the 2005-2020 panel to merge in 
* 						into 2005-2023 panel. Relevant for variables that were
* 						replaced since 2020 as don't have updated seet up files. 
* 						The replacements have not been backcoded resulting in 
* 						missing data. 
* 						Temporary fix. 
* 						Need older version of  "PL-SILC_pooled_all_obs_01.dta" 
* 						to run this file. Construct using 
* 						"prepare_pooled_data _05_20.do" first. 
********************************************************************************

* Collect economic status information from previous panel 
use "$dir_data_05_20/HU-SILC_pooled_all_obs_01.dta", clear 

keep  hid pid year pl030 pl031 rb210 

rename * *_orig
rename  pid_orig pid 
rename  year_orig year 
rename  hid_orig  hid

gsort year hid pid 

drop if year == year[_n-1] & hid == hid[_n-1] & pid == pid[_n-1]  

save "$dir_data/temp_orig_econ_status", replace 

* Collect education information from previous panel 
use "$dir_data_05_20/HU-SILC_pooled_all_obs_01.dta", clear 

keep  hid pid year pe040

rename * *_orig
rename  pid_orig pid 
rename  year_orig year 
rename  hid_orig  hid

gsort year hid pid -pe040_orig 

drop if year == year[_n-1] & hid == hid[_n-1] & pid == pid[_n-1]  

save "$dir_data/temp_orig_edu", replace 

/*
use "$dir_data_05_20/PL-SILC_pooled_all_obs_02.dta", clear 

keep  hid pid year les_c3

rename * *_orig
rename  pid_orig pid 
rename  year_orig year 
rename  hid_orig  hid

save "$dir_data/temp_orig_econ_status2", replace 
*/

* Collect occupation information 

use "$dir_data_05_20/HU-SILC_pooled_all_obs_01.dta", clear 

keep  hid pid year pl051

rename * *_orig
rename  pid_orig pid 
rename  year_orig year 
rename  hid_orig  hid

drop if pl051_orig == . 

save "/Users/ashleyburdett/Library/CloudStorage/Box-Box/CeMPA shared area/ESPON - OVERLAP/_countries/Digital_skills/data/temp_orig_occu_HU", replace 
