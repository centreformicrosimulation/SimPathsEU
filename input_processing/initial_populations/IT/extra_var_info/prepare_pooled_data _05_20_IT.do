********************************************************************************
* PROJECT:              ESPON
* DO-FILE NAME:         prepare_pooled_data_05_20.do
* DESCRIPTION:          Compiles 2005-2020 panel dataset from 2005-2020 EU-SILC  
********************************************************************************
* COUNTRY:              IT 
* DATA:         	    EU-SILC panel based on the EU-SILC longitudinal datasets 
* 						created using GESIS Stata script: 
* 						https://www.gesis.org/gml/european-microdata/eu-silc.
******************************************************************************** 
* AUTHORS: 				Daria Popova, Ashley Burdett
* LAST UPDATE:          Feb 2025
* NOTE:					Constructs the 2005-2020 EU-SILC panel that contains 
* 						information about variables that change when the panel
* 						was extended to 2023 but the variables weren't back 
* 						coded. Temporary fix. 
* 						Need to run to obtain PL-SILC_pooled_all_obs_01 for 
* 						2005-2020 used as an input for file 
* 						"economic_status_2005_2020.do". 
********************************************************************************

cap log close 
//log using "$dir_log/01_prepare_pooled_data.log", replace

cd "$dir_data_05_20"

* Load Personal Register (R-FILE), i.e. all people incl children 
use "$dir_long_eusilc_05_20/MasterR", clear
keep if country == "$country" 
drop *_f
sort year uhid upid
count //629,932
save ${country}-SILC_pooled_all_obs_01.dta, replace


* Load and merge Personal Data (P-FILE), i.e. people aged 16 and above 
clear
use "$dir_long_eusilc_05_20/MasterP"
keep if country == "$country"
drop *_f *_i
duplicates drop year upid, force
count //509,299
merge 1:1 year upid uhid using "${country}-SILC_pooled_all_obs_01.dta", force
fre _merge
					
drop if _merge == 1
drop _merge
sort year uhid upid
save ${country}-SILC_pooled_all_obs_01.dta, replace

	
* Load and merge Household Register (D-FILE) 
clear
use "$dir_long_eusilc_05_20/MasterD"
keep if country == "$country"
drop *_f
sort year uhid
duplicates drop year uhid, force
count //288,400
merge 1:m year uhid using "${country}-SILC_pooled_all_obs_01.dta"
fre _merge
				
keep if _merge == 3 //not sure why some households are not merged, maybe investigate later?  
drop _merge		
sort year uhid upid
save ${country}-SILC_pooled_all_obs_01.dta, replace
	
* Load and merge Household Data (H-FILE) 
clear
use "$dir_long_eusilc_05_20/MasterH"
keep if country == "$country"
drop *_f *_i
		
duplicates drop year uhid, force
count //220,808

merge 1:m year uhid using "${country}-SILC_pooled_all_obs_01.dta"
fre _merge
			
keep if _merge == 3
drop _merge
drop db050 //db050 -- Primary strata (Only CH)
sort year uhid upid
save ${country}-SILC_pooled_all_obs_01.dta, replace
	
label variable db010 "year"
label variable db020 "country"
label variable db040 "region"
label variable db090 "household cross-sectional weight"

display "Run finished on $S_DATE at $S_TIME"
capture log close

