* Compare datasets 
* Why fewer observations in the recent initial populations? 

* Load new file from which the drop if done. 

use "$dir_data/${country}-SILC_pooled_all_obs_04.dta", clear


* Merge in comparison data from previous version
merge 1:1 idperson swv using "$dir_data/prior_comparison_data.dta"
	// condensed version of previous dataset
drop _m 

order idperson swv dropHH dropHH_old dwt dwt_old

* How distributed across years? 
tab swv dropHH 
tab swv dropHH_old

replace dropHH = 0 if dropHH == . 
replace dropHH_old = 0 if dropHH_old == . 

tab dropHH dropHH_old

tab swv dropHH, row
tab swv dropHH_old, row

gen drop_in_new_only = (dropHH == 1 & dropHH_old == 0)

tab drop_in_new_only


* Investigate 2011 

keep if swv == 2011

tab drop_in_new_only //3,707

* Who are these 3,707 individuals? 

/* 
dropHH comes from dropObs. Work thorugh variables used in 03 and to see 
which variables are causing this 
Code taken from original code just adjusting names 
*/

* Identify orphans   
count if idfather < 0 & idmother < 0 & ///
	(dag > 0 & dag < $age_become_responsible) //0

* Benefit unit headed by a child 
/* 
These are below 18 yo heads who have their own kids or live with other kids)
	==> they can be kept if this condition coded out 
*/     
bys swv idbenefitunit: gen childhead_drop = 1 if idperson == idbenefitunit & ///
	dag < $age_become_responsible
fre childhead_drop  
bys swv idbenefitunit: egen childhead_bu_drop = max(childhead) 
fre childhead_bu_drop //0
 
* Inconsistency in union status 
/*
dcpst	-- Partnership	status
	1 partnered	
	2 single		
	3 previously	
*/

* Reports being partnered but one adult in ben unit
bys stm idbenefitunit : egen num_adult_drop = sum(adult)
gen chk_drop = (num_adult_drop == 1 & dcpst == 1 & adult == 1) 
bys stm idbenefitunit : egen chk2_drop = max(chk_drop)
fre chk2_drop // 28

* Reports being single but more than two adults in ben unit 
gen chk3_drop = (num_adult_drop == 2 & dcpst != 1 & adult == 1) 
bys stm idbenefitunit : egen chk4_drop = max(chk3_drop)
fre chk4_drop // 0 obs 

** Check missing values 
* Missing region 
count if drgn1 == -9  & drop_in_new_only == 1 //0

* Missing age 
count if dag == -9 & drop_in_new_only == 1  // 0 obs 

* Missing age of partner (but has a partner)
count if dagsp == -9 & idpartner != -9 & drop_in_new_only == 1 //0

* Health status - remove household if missing for adults 
count if (dhe == -9 ) & dag > $age_become_responsible & drop_in_new_only == 1 //0
count if (dhe == -9 ) & dag > 0 & dag <= $age_become_responsible & ///
	 drop_in_new_only == 1 //0

* Health status of spouse - remove household if missing but ind has a spouse 
count if dhesp == -9 & idpartner != -9 & drop_in_new_only == 1 //0

* Education - remove household if missing education level for adults out of edu
count if deh_c3 == -9 & dag >= $age_become_responsible & ded == 0 & ///
	drop_in_new_only == 1 //0

* Education of spouse - remove household if missing but individual has a spouse 
count if dehsp_c3 == -9 & idpartner != -9 & drop_in_new_only == 1 //0

* Partnership status 
count if dcpst == -9 & drop_in_new_only == 1 //0

* Activity status 
count if les_c3 == -9 & dag >= $age_become_responsible & drop_in_new_only == 1 //1,188

* Activity status with retirement as a separate category 
count if les_c4 == -9 & dag >= $age_become_responsible & drop_in_new_only == 1 //1,188

* Partner's activity status 
count if lessp_c3 == -9 & idpartner != -9 & drop_in_new_only == 1 //641

* Own and spousal activity status 
count if lesdf_c4 == -9 & idpartner != -9 & drop_in_new_only == 1 //1,158

* Household composition 
count if dhhtp_c4 == -9 & drop_in_new_only == 1

* Income 
* Gross personal non-benefit income 
//==> no missing values by construction but theoretically can be zero 


* Gross personal employment income 
//==> no missing values by construction but theoretically can be zero 


* Household income quintile
//==> a few missing values for kids who live w/t other adults

* Gross personal non-employment capital income 
//==> no missing values by construction 

count if ypnbihs_dv == -9 & dag >= $age_become_responsible & drop_in_new_only == 1
count if yplgrs_dv == -9 & dag >= $age_become_responsible & drop_in_new_only == 1
count if ydses_c5 == -9 & drop_in_new_only == 1
count if ypncp == -9 & dag >= $age_become_responsible & drop_in_new_only == 1

/*
Almost all coming from activity status differences
*/

order idperson idhh drop_in_new_only les_c3* les_c4* lessp* lesdf*

gsort -drop_in_new_only

keep if drop_in == 1 & les_c3 == -9 
gen missing_les_c3 = 1 

keep idperson swv missing_les_c3

save "$dir_data/missing_les_c3.dta", replace



* See what's going on for these variables in the full dataset? 

use "$dir_data/02_pre_drop.dta", clear 

merge 1:1 idperson swv using  "$dir_data/missing_les_c3.dta"

order idperson swv missing_les_c3 dag les_c3 pl031 rb210 les_c4 dlltsd unemp ded lhw 

sort missing_les_c3

********************************************************************************

//seems to mainly be when imposing consistency between hours worked and activity 

* Investigate 2019 

* Compare datasets 
* Why fewer observations in the recent initial populations? 

* Load new file from which the drop if done. 

use "$dir_data/${country}-SILC_pooled_all_obs_04.dta", clear


* Merge in comparison data from previous version
merge 1:1 idperson swv using "$dir_data/prior_comparison_data.dta"
	// condensed version of previous dataset
drop _m 

order idperson swv dropHH dropHH_old dwt dwt_old

* How distributed across years? 
tab swv dropHH 
tab swv dropHH_old

replace dropHH = 0 if dropHH == . 
replace dropHH_old = 0 if dropHH_old == . 

tab dropHH dropHH_old

tab swv dropHH 
tab swv dropHH_old

gen drop_in_new_only = (dropHH == 1 & dropHH_old == 0)

tab drop_in_new_only


* Investigate 2019 

keep if swv == 2019

tab drop_in_new_only //10,158

* Who are these 3,707 individuals? 

/* 
dropHH comes from dropObs. Work thorugh variables used in 03 and to see 
which variables are causing this 
Code taken from original code just adjusting names 
*/

* Identify orphans   
count if idfather < 0 & idmother < 0 & ///
	(dag > 0 & dag < $age_become_responsible) //2

* Benefit unit headed by a child 
/* 
These are below 18 yo heads who have their own kids or live with other kids)
	==> they can be kept if this condition coded out 
*/     
bys swv idbenefitunit: gen childhead_drop = 1 if idperson == idbenefitunit & ///
	dag < $age_become_responsible
fre childhead_drop  
bys swv idbenefitunit: egen childhead_bu_drop = max(childhead) 
fre childhead_bu_drop //4
 
* Inconsistency in union status 
/*
dcpst	-- Partnership	status
	1 partnered	
	2 single		
	3 previously	
*/

* Reports being partnered but one adult in ben unit
bys stm idbenefitunit : egen num_adult_drop = sum(adult)
gen chk_drop = (num_adult_drop == 1 & dcpst == 1 & adult == 1) 
bys stm idbenefitunit : egen chk2_drop = max(chk_drop)
fre chk2_drop // 9

* Reports being single but more than two adults in ben unit 
gen chk3_drop = (num_adult_drop == 2 & dcpst != 1 & adult == 1) 
bys stm idbenefitunit : egen chk4_drop = max(chk3_drop)
fre chk4_drop // 0 obs 

** Check missing values 
* Missing region 
count if drgn1 == -9  & drop_in_new_only == 1 //0

* Missing age 
count if dag == -9 & drop_in_new_only == 1  // 0 obs 

* Missing age of partner (but has a partner)
count if dagsp == -9 & idpartner != -9 & drop_in_new_only == 1 //0

* Health status - remove household if missing for adults 
count if (dhe == -9 ) & dag > $age_become_responsible & drop_in_new_only == 1 //0
count if (dhe == -9 ) & dag > 0 & dag <= $age_become_responsible & ///
	 drop_in_new_only == 1 //0

* Health status of spouse - remove household if missing but ind has a spouse 
count if dhesp == -9 & idpartner != -9 & drop_in_new_only == 1 //0

* Education - remove household if missing education level for adults out of edu
count if deh_c3 == -9 & dag >= $age_become_responsible & ded == 0 & ///
	drop_in_new_only == 1 //0

* Education of spouse - remove household if missing but individual has a spouse 
count if dehsp_c3 == -9 & idpartner != -9 & drop_in_new_only == 1 //0

* Partnership status 
count if dcpst == -9 & drop_in_new_only == 1 //0

* Activity status 
count if les_c3 == -9 & dag >= $age_become_responsible & drop_in_new_only == 1 //3,480

* Activity status with retirement as a separate category 
count if les_c4 == -9 & dag >= $age_become_responsible & drop_in_new_only == 1 //3,480

* Partner's activity status 
count if lessp_c3 == -9 & idpartner != -9 & drop_in_new_only == 1 //2,157

* Own and spousal activity status 
count if lesdf_c4 == -9 & idpartner != -9 & drop_in_new_only == 1 //3,910

* Household composition 
count if dhhtp_c4 == -9 & drop_in_new_only == 1

* Income 
* Gross personal non-benefit income 
//==> no missing values by construction but theoretically can be zero 


* Gross personal employment income 
//==> no missing values by construction but theoretically can be zero 


* Household income quintile
//==> a few missing values for kids who live w/t other adults

* Gross personal non-employment capital income 
//==> no missing values by construction 

count if ypnbihs_dv == -9 & dag >= $age_become_responsible & drop_in_new_only == 1
count if yplgrs_dv == -9 & dag >= $age_become_responsible & drop_in_new_only == 1
count if ydses_c5 == -9 & drop_in_new_only == 1
count if ypncp == -9 & dag >= $age_become_responsible & drop_in_new_only == 1


/*
Again almost all coming from activity status differences
*/

order idperson idhh drop_in_new_only les_c3* les_c4* lessp* lesdf*

gsort -drop_in_new_only

keep if drop_in == 1 & les_c3 == -9 
gen missing_les_c3 = 1 

keep idperson swv missing_les_c3

save "$dir_data/missing_les_c3.dta", replace



* See what's going on for these variables in the full dataset? 

use "$dir_data/02_pre_drop.dta", clear 

merge 1:1 idperson swv using  "$dir_data/missing_les_c3.dta"

order idperson swv missing_les_c3 les_c3 pl031 rb210 pl060 les_c4 dlltsd unemp ded lhw dag 

sort missing_les_c3
