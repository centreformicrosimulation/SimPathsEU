********************************************************************************
* PROJECT:              ESPON
* DO-FILE NAME:         01_prepare_pooled_data.do
* DESCRIPTION:          Compiles panel dataset from EU-SILC  
********************************************************************************
* COUNTRY:              HU 
* DATA:         	    EU-SILC panel based on the EU-SILC longitudinal datasets 
* 						created using GESIS Stata script: 
* 						https://www.gesis.org/gml/european-microdata/eu-silc.
******************************************************************************** 
* AUTHORS: 				Daria Popova, Ashley Burdett
* LAST UPDATE:          March 2025 
* NOTE:					Called from 00_master.do - see master file for further 
* 						details
********************************************************************************
/* This script uses a cumulative panel sample created following the GESIS 
set-ups written by Borst, Marwin/Wirth, Heike (2022); 
Each year, Eurostat publishes a series of separate datasets covering only up to 
4 years, even though it has been collecting data since 2003. 
“eusilcpanel” is a script written by Marwin Borst in the form of a Stata package
 (eusilcpanel.ado; eusilcpanel.sthlp; totalpopulation.dta), 
that is able to merge these chunks of data into one cumulative dataset 
(separately for the D-,H-,R- and P-data).
*/
/*
Initial populations: cross-sectional SILC for 2011-2023 (income 2010-2022), 
2023 (income 2022)
Estimation sample: longitudinal SILC with observations from 2011-2023 
(income 2010-2022)
*/

********************************************************************************
cap log close 
//log using "$dir_log/01_prepare_pooled_data.log", replace

cd "$dir_data"

* Load Personal Register (R-FILE), i.e. all people incl children 
use "$dir_long_eusilc/MasterR", clear
keep if country == "$country" 
drop *_f
sort year uhid upid
count //629,932
save ${country}-SILC_pooled_all_obs_01.dta, replace


* Load and merge Personal Data (P-FILE), i.e. people aged 16 and above 
clear
use "$dir_long_eusilc/MasterP"
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
use "$dir_long_eusilc/MasterD"
keep if country == "$country"
drop *_f
sort year uhid
duplicates drop year uhid, force
count 
merge 1:m year uhid using "${country}-SILC_pooled_all_obs_01.dta"
fre _merge

			
keep if _merge == 3 
//not sure why some households are not merged, maybe investigate later?  
drop _merge		
sort year uhid upid
save ${country}-SILC_pooled_all_obs_01.dta, replace
	
* Load and merge Household Data (H-FILE) 
clear
use "$dir_long_eusilc/MasterH"
keep if country == "$country"
drop *_f *_i
		
duplicates drop year uhid, force
count 

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

