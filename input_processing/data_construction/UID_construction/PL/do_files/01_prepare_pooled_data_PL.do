/*******************************************************************************
* PROJECT:              SimPaths EU
* DO-FILE NAME:         01_prepare_pooled_data_PL.do
* DESCRIPTION:          Compiles panel dataset from EU-SILC from GESIS data 
* 						files.  
* COUNTRY:              Poland
* DATA:         	    EU-SILC panel based on the EU-SILC longitudinal datasets 
* 						created using GESIS Stata script: 
* 						https://www.gesis.org/gml/european-microdata/eu-silc. 
* AUTHORS: 				Daria Popova, Ashley Burdett
* LAST UPDATE:          March 2025 
********************************************************************************
* NOTES:					
* 
* 	This file combines the panel datasets created using the files in folder 
* 	"input_processing/data_construction/SILC_panel_construction" for years 
* 	2005-2023.  
* 
*   -----------------------------------------------------------------------
*    File structure 
*   -----------------------------------------------------------------------
*
*  Files are merged in the following order, with R as the base:
*
*    R (Personal Register) — loaded first as the base. Contains all persons
*      in the sample including children under 16. Key identifiers: upid
*      (unique person ID across releases), uhid (unique household ID), year.
*
*    P (Personal Data) — merged 1:1 on year+upid+uhid. Contains income and
*      personal variables for adults aged 16 and above only. After this merge:
*      - Adults (in both R and P): have full R and P variables
*      - Children (in R only, not P): retained with R variables only
*      - Records in P but not R: dropped (should not occur in clean data)
*
*    D (Household Register) — merged 1:m on year+uhid. D is household-level
*      so one D row maps to multiple persons. keep if _merge==3 retains only
*      persons whose household appears in D. A small number of households may
*      not merge — this is suspected to be an edge case from the cross-release
*      deduplication in 01_create_masterD.do but has not been fully 
* 	   investigated.
*
*    H (Household Data) — merged 1:m on year+uhid, same logic as D.
*
*   -----------------------------------------------------------------------
*    Key identifiers 
*   -----------------------------------------------------------------------
*    upid  — unique personal ID across releases (country + rotation group +
*             dropout year + pid). Not the same as the raw pid in the source data
*    uhid  — unique household ID across releases (same construction logic).
*    year  — income reference year.
*/

*******************************************************************************/
cap log close 
//log using "$dir_log/01_prepare_pooled_data.log", replace


* Load Personal Register (R-FILE), i.e. all people incl children 
use "$dir_long_eusilc/MasterR", clear
keep if country == "$country" 
drop *_f
sort year uhid upid
count 
save "$dir_data/${country}-SILC_pooled_all_obs_01.dta", replace

* Load and merge Personal Data (P-FILE), i.e. people aged 16 and above 
use "$dir_long_eusilc/MasterP", clear
keep if country == "$country"
drop *_f *_i
duplicates drop year upid, force
count 
merge 1:1 year upid uhid using ///
	"$dir_data/${country}-SILC_pooled_all_obs_01.dta", force
fre _merge
			
drop if _merge == 1
drop _merge
sort year uhid upid
save "$dir_data/${country}-SILC_pooled_all_obs_01.dta", replace

* Load and merge Household Register (D-FILE) 
use "$dir_long_eusilc/MasterD", clear
keep if country == "$country"
drop *_f
sort year uhid
duplicates drop year uhid, force
count 
merge 1:m year uhid using "$dir_data/${country}-SILC_pooled_all_obs_01.dta"
fre _merge
		
keep if _merge == 3 
drop _merge		
sort year uhid upid
save "$dir_data/${country}-SILC_pooled_all_obs_01.dta", replace
	
* Load and merge Household Data (H-FILE) 
use "$dir_long_eusilc/MasterH", clear
keep if country == "$country"
drop *_f *_i
		
duplicates drop year uhid, force
count 

merge 1:m year uhid using "$dir_data/${country}-SILC_pooled_all_obs_01.dta"
fre _merge
		
keep if _merge == 3
drop _merge
drop db050 //db050 -- Primary strata (Only CH)
sort year uhid upid
save "$dir_data/${country}-SILC_pooled_all_obs_01.dta", replace
	
label variable db010 "year"
label variable db020 "country"
label variable db040 "region"
label variable db090 "household cross-sectional weight"

capture log close
