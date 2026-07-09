********************************************************************************
* PROJECT:              SimPaths EU
* DO-FILE NAME:         04_reweight_PL.do
* DESCRIPTION:          Weight adjustment to account for using households 
* 						without missing values. 
********************************************************************************
* COUNTRY:              PL
* DATA:         	    EU-SILC panel dataset  
* AUTHORS: 				Daria Popova 
* LAST UPDATE:          Jan 2025
* NOTE:					Called from 00_master.do - see master file for further 
* 						details
*						Use -9 for missing values 
* 						Adjust weights using the inverse probability of not 
* 						having missing data at the household level. 
* 						HH mean individual weights, shared across hh? 
********************************************************************************

cap log close 
//log using "$dir_log/06_reweight_and_slice.log", replace

use "$dir_data/${country}-SILC_pooled_all_obs_03.dta", clear

* 1. Adjust weights by estimating a probit model for inclusion in the 
* restricted sample of households without missing values.
assert stm == swv //swv = year 
sort stm idhh

* 1.1. Define a dummy variable classifying households as complete or not
cap gen complete_hh = (dropHH != 1)

* 1.2. Define independent variables for probit
sum dgn dag drgn1
cap gen drop_indicator = .
replace drop_indicator = 1 if dgn < 0 | dag < 0 | drgn1 < 0

by stm idhh: egen max_drop_indicator = max(drop_indicator)
drop if max_drop_indicator == 1 // 40 observations deleted

recode deh_c3 dcpst stm (-9 = .)
sum deh_c3 dcpst

tab deh_c3, gen(educ) //Generate education level dummies
egen dagcat = cut(dag), at(0,20,30,40,50,60,70,80,120)
tab dagcat, gen(dagcat) //Generate age group dummies
tab dcpst, gen(dcpstcat) //Marital status categories

cap drop hh_size
bys stm idhh: gen hh_size = _N
sum hh_size

* Generate dummies for education and age categories & interact them with gender 
* (1 = male)
xi i.deh_c3*i.dagcat
foreach var in _IdehXdag_2_20 _IdehXdag_2_30 _IdehXdag_2_40 _IdehXdag_2_50 ///
	_IdehXdag_2_60 _IdehXdag_2_70 /*_IdehXdag_2_80*/ _IdehXdag_3_20 ///
	_IdehXdag_3_30 _IdehXdag_3_40 _IdehXdag_3_50 _IdehXdag_3_60 ///
	_IdehXdag_3_70 /*_IdehXdag_3_80*/  {
	
		replace `var' = `var'*dgn

}
 
* 1.3. Create hh level dataset 
collapse (firstnm) drgn1 (max) _IdehXdag* dcpstcat* complete_hh (mean) ///
	hh_size dwt, by(stm idhh)
	
duplicates report idhh stm 

replace complete_hh = 1 if complete_hh >= 0.5 & complete_hh < 1 
replace complete_hh = 0 if complete_hh < 0.5 & complete_hh > 0  
bys stm: sum drgn1 _IdehXdag* dcpstcat* hh_size dwt
bys stm: fre complete_hh

recode hh_size (1=1) (2=2) (3=3) (4=4) (5/max=5), gen(hhsize_cat)
recode hh_size (1=1) (2=2) (3=3) (4/max=4) , gen(hhsize_cat2)
fre hhsize_cat*


* 1.4. Household-level probit
/* 
Model probabiltiy of being a complete household conditional on presence of
people of certain education age gender combination, marital status and region.
*/
probit complete_hh _Ideh* dcpstcat* i.hhsize_cat2 ib10.drgn1 i.stm , ///
	vce(robust) /*iterate(20)*/ 

* Predict probability of being a complete household
predict pr_comphh

sum pr_comphh if complete_hh == 0
sum pr_comphh if complete_hh == 1

gen inv_pr_comphh = 1/pr_comphh
sum inv_pr_comphh

/*
Need to only adjust the weights for complete households included in the 
sample, so drop the rest 
*/
keep if complete_hh == 1 // (11,611 observations deleted)

*2. Multiply ind weights by the inverse of the predicted prob of inclusion
gen dwt_adjusted = dwt*inv_pr_comphh

replace dwt_adjusted = dwt if missing(dwt_adjusted) 

sum dwt*

keep stm idhh dwt_adjusted

count

save "$dir_data/temp_adjusted_dwt", replace

*3. Weight adjustment to account for using household without missing values  	
use "$dir_data/${country}-SILC_pooled_all_obs_03.dta", clear 

count  //547,160 obs 

cap drop _merge

merge m:1 stm idhh using "$dir_data/temp_adjusted_dwt.dta", ///
	keepusing (dwt_adjusted)
/*
    Result                      Number of obs
    -----------------------------------------
    Not matched                        21,228
        from master                    21,228  (_merge==1)
        from using                          0  (_merge==2)

    Matched                           525,931  (_merge==3)
    -----------------------------------------

*/	
keep if _merge == 1 | _merge == 3

gen dwt_sampling = dwt //keep original weights before any adjustment 

replace dwt = dwt_adjusted if (!missing(dwt_adjusted)) 
	//keep weights adjusted for probability of being complete hhs 

	drop _merge

sum dwt dwt_adjusted dwt_sampling
/*	
Cannot have missing values in continuous variables - recode to 0 for now: 
(But note this treatment of missings is generally valid - e.g. people without 
a partner don't have years in partnership etc.)

recode dcpyy dcpagdf ynbcpdf_dv dnc02 dnc ypnbihs_dv yptciihs_dv ypncp ///
	ypnoab yplgrs_dv stm swv /*dhe dhesp*/ (-9 . = 0)
*/
 
* Ensure consistency of benefit unit data
// nto fully sorted so can result in slightly different dataset each time 
gsort stm idbenefitunit -dag

foreach vv of varlist dwt drgn1 dhhtp_c4 ydses_c5 dnc02 dnc {
	
	bys stm idbenefitunit /*(`vv')*/: replace `vv' = `vv'[1] if (`vv'!=`vv'[1])

}

/*********************************** SAVE *************************************/
sort idperson swv 

//cf _all using "$dir_data/${country}-SILC_pooled_all_obs_04.dta"	
	
save "$dir_data/${country}-SILC_pooled_all_obs_04.dta", replace  



* Slice the original pooled dataset into years 
forvalues yy = $first_sim_year/$last_sim_year {

	use "$dir_data/${country}-SILC_pooled_all_obs_04.dta", clear

	drop if dwt == 0

	* limit year
	keep if stm == `yy' 

	save "$dir_data/population_initial_fs_${country}_`yy'.dta", replace
	
}

cap log close

/***************************** CLEAN UP AND EXIT ******************************/

#delimit ;
local files_to_drop 
	temp_adjusted_dwt.dta
	;
#delimit cr // cr stands for carriage return

foreach file of local files_to_drop {
	 
	erase "$dir_data/`file'"

}
