********************************************************************************
* PROJECT:              SImPaths EU 
* DO-FILE NAME:         01_prepare_pooled_data.do
* DESCRIPTION:          Compiles panel dataset from EU-SILC  
********************************************************************************
* COUNTRY:              Poland
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
(eusilcpanel.ado; eusilcpanel.sthlp; totalpopulation.dta), that is able to 
merge these chunks of data into one cumulative dataset (separately for the 
D-,H-,R- and P-data).
*/
/*
STRUCTURE OF THIS FILE

  The script builds a person-level panel dataset for a single country by
  sequentially merging the four EU-SILC master files produced by the panel
  construction scripts (01-04 in eu_silc_do_2025/).

  Files are merged in the following order, with R as the base:

    R (Personal Register) — loaded first as the base. Contains all persons
      in the sample including children under 16. Key identifiers: upid
      (unique person ID across releases), uhid (unique household ID), year.

    P (Personal Data) — merged 1:1 on year+upid+uhid. Contains income and
      personal variables for adults aged 16 and above only. After this merge:
      - Adults (in both R and P): have full R and P variables
      - Children (in R only, not P): retained with R variables only
      - Records in P but not R: dropped (should not occur in clean data)

    D (Household Register) — merged 1:m on year+uhid. D is household-level
      so one D row maps to multiple persons. keep if _merge==3 retains only
      persons whose household appears in D. A small number of households may
      not merge — this is suspected to be an edge case from the cross-release
      deduplication in 01_create_masterD.do but has not been fully investigated.

    H (Household Data) — merged 1:m on year+uhid, same logic as D.

  KEY IDENTIFIERS
    upid  — unique personal ID across releases (country + rotation group +
             dropout year + pid). Not the same as the raw pid in the source data
    uhid  — unique household ID across releases (same construction logic).
    year  — income reference year.

  OUTPUT
    ${country}-SILC_pooled_all_obs_01.dta — person-level panel for the target
    country, containing all household members (adults and children) with
    combined R, P, D, and H variables. Flag variables (*_f, *_i) are dropped.
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

