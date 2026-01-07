********************************************************************************
* PROJECT:              ESPON
* DO-FILE NAME:         05_drop_hhold_an_slice_EL.do
* DESCRIPTION:          This file generates data for importing into SimPaths
********************************************************************************
* COUNTRY:              EL
* DATA:         	    EU-SILC panel dataset  
* AUTHORS: 				Daria Popova
* LAST UPDATE:         	Jan 2025
* NOTE:					Called from 00_master.do - see master file for further 
* 						details
*						Use -9 for missing values 
* 						For a new country update the population figures 
********************************************************************************

cap log close 
//log using "${dir_log}/05_finalise_input_data.log", replace

use "$dir_data/${country}-SILC_pooled_all_obs_04.dta", clear


********************************************************************************
* Limit sample
********************************************************************************

* If any person in the household has missing values, drop the whole household:
drop if dropHH == 1 // 30,730 obs

drop dropObs dropHH 
	
* Drop if hh weight = 0:
count if dwt == 0 
drop if dwt == 0 // 56 obs

* Final check for same sex households
assert ssscp != 1 
assert dgn != dgnsp if idpartner > 0

* Final check for number of adults 
drop adult child  //drop old vars 
gen child = dag < $age_become_responsible 
gen adult = 1 - child 

bys stm idhh: egen adult_count = sum(adult)
bys stm idbenefitunit: egen adult_count2 = sum(adult)

tab adult_count 
tab adult_count2

assert adult_count >= 1 
assert adult_count2 >= 1 

* Final check for orphans 
assert  (idfather > 0 | idmother > 0) if ///
	(dag > 0 & dag < $age_become_responsible )

* Check for duplicates in terms of stm and idperson
cap drop duplicate 
duplicates tag stm idperson , generate(duplicate)
assert duplicate == 0 

cap drop duplicate 
duplicates tag swv idperson , generate(duplicate)
assert duplicate == 0 

save "$dir_data/${country}_pooled_ipop.dta", replace 
/*panel dataset with missing values removed*/

********************************************************************************
* Generate frequency weights
********************************************************************************
/*
Total population figures for Greece from 2011 to 2023:
https://ec.europa.eu/eurostat/databrowser/view/demo_pjan/default/...
	table?lang=en&category=demo.demo_pop
	
EUROSTAT demo_gind	
*/
cap gen el_pop = 0 
replace el_pop = 11104899 if stm == 2011 
replace el_pop = 11045011 if stm == 2012
replace el_pop = 10965211 if stm == 2013
replace el_pop = 10892413 if stm == 2014
replace el_pop = 10820883 if stm == 2015
replace el_pop = 10775971 if stm == 2016
replace el_pop = 10754679 if stm == 2017 
replace el_pop = 10732882 if stm == 2018
replace el_pop = 10721582 if stm == 2019
replace el_pop = 10698599 if stm == 2020
replace el_pop = 10569207 if stm == 2021
replace el_pop = 10436882 if stm == 2022
replace el_pop = 10407351 if stm == 2023

cap drop surv_pop
//bys stm: gen surv_pop = _N //gen survey hhs population for each calendar year 
bys stm: egen surv_pop = total(dwt_adjusted)
bys stm: sum surv_pop

cap drop  multiplier
gen multiplier = el_pop / surv_pop 

cap gen dwtfq = round(dwt * multiplier) 
//cap drop dwt_sampling
//rename dwt dwt_sampling
replace dwt = dwtfq 
bys stm: sum dwt*

save "$dir_data/${country}_pooled_ipop.dta", replace 
/*panel dataset with missing values removed*/

********************************************************************************
* Slice the pooled dataset into intitial populations
********************************************************************************
forvalues yy = $firstSimYear/$lastSimYear {
	
	* Load pooled data with missing values removed  
	use "$dir_data/${country}_pooled_ipop.dta", clear
	rename *, l
	
	* Limit year
	global year = `yy'
	keep if stm == $year 

	* Check for duplicates 
	duplicates report idhh idperson
	cap drop duplicate 
	duplicates tag idhh idperson , generate(duplicate)
	duplicates drop idperson, force
	assert duplicate == 0 

	duplicates report idperson
	cap drop duplicate 
	duplicates tag idperson , generate(duplicate)
	duplicates drop idperson, force
	assert duplicate == 0 

	* Check for same sex households
    assert ssscp != 1 
    assert dgn != dgnsp if idpartner > 0

    * Check for number of adults 
    drop adult child adult_count adult_count2 //drop old vars 
    gen child = dag < $age_become_responsible 
    gen adult = 1 - child 
	
    bys stm idhh: egen adult_count = sum(adult)
    bys stm idbenefitunit: egen adult_count2 = sum(adult)	
    assert adult_count >= 1 
    assert adult_count2 >= 1 
    
	* Check for orphans 
    assert  (idfather > 0 | idmother > 0) if ///
		(dag > 0 & dag < $age_become_responsible)

	* Check weight is not zero and non-missing 
	assert dwt > 0 & dwt < . 
	//sum of weights
	cap gen one = 1
	sum one [w = dwt]

	*Limit saved variables
	keep idhh idbenefitunit idperson idpartner idmother idfather swv dgn dag ///
	dcpst dnc02 dnc ded deh_c3 sedex les_c3 dlltsd dhe ydses_c5 yplgrs_dv ///
	ypnbihs_dv yptciihs_dv dhhtp_c8 ssscp dcpen dcpyy dcpex dcpagdf ///
	ynbcpdf_dv der sedag sprfm dagsp dehsp_c3 dhesp lessp_c3 ///
	dehm_c3 dehf_c3 stm lesdf_c4 dhh_owned lhw drgn1 dct dwt_sampling ///
	les_c4 lessp_c4 adultchildflag dwt obs_earnings_hourly ///
	l1_obs_earnings_hourly ypncp ypnoab l1_les_c3 l1_les_c4 liwwh
	
	order idhh idbenefitunit idperson idpartner idmother idfather swv dgn ///
	dag dcpst dnc02 dnc ded deh_c3 sedex les_c3 dlltsd dhe ydses_c5 ///
	yplgrs_dv ypnbihs_dv yptciihs_dv dhhtp_c8 ssscp dcpen dcpyy dcpex ///
	dcpagdf ynbcpdf_dv der sedag sprfm dagsp dehsp_c3 dhesp lessp_c3  ///
	dehm_c3 dehf_c3 stm lesdf_c4 dhh_owned lhw drgn1 dct dwt_sampling  ///
	les_c4 lessp_c4 adultchildflag dwt obs_earnings_hourly ///
	l1_obs_earnings_hourly ypncp ypnoab l1_les_c3 l1_les_c4 liwwh
	
	recode idhh idbenefitunit idperson idpartner idmother idfather swv dgn ///
	dag dcpst dnc02 dnc ded deh_c3 sedex les_c3 dlltsd dhe ydses_c5 ///
	yplgrs_dv ypnbihs_dv yptciihs_dv dhhtp_c8 ssscp dcpen dcpyy dcpex ///
	dcpagdf ynbcpdf_dv der sedag sprfm dagsp dehsp_c3 dhesp lessp_c3 ///
	dehm_c3 dehf_c3 stm lesdf_c4 dhh_owned lhw drgn1 dct dwt_sampling ///
	les_c4 lessp_c4 adultchildflag dwt obs_earnings_hourly  ///
	l1_obs_earnings_hourly ypncp ypnoab l1_les_c3 l1_les_c4 liwwh (missing = -9)
	
	gsort idhh idbenefitunit idperson
	save "$dir_data/population_initial_${country}_${year}.dta", replace
	
	recode dgn (-9 = 0)
	export delimited using ///
		"$dir_data/population_initial_${country}_${year}.csv", nolabel replace
}

cap log close

********************************************************************************
* Finalise
********************************************************************************
#delimit ;
local files_to_drop 
	//was_wealthdata.dta
	;
#delimit cr // cr stands for carriage return
/*
foreach file of local files_to_drop { 
	erase "$dir_data/`file'"
}
*/

