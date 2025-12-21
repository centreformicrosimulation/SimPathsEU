********************************************************************************
* PROJECT:              ESPON
* DO-FILE NAME:         03_create_benefit_units.do
* DESCRIPTION:          Screens data and identifies benefit units 
********************************************************************************
* COUNTRY:              HU
* DATA:         	    EU-SILC panel dataset  
* AUTHORS: 				Daria Popova, Ashley Burdett
* LAST UPDATE:          Jan 2025
* NOTE:					Called from 00_master.do - see master file for further 
* 						details
*						Use -9 for missing values 
* 						Dropping so many observations due to lack of education 
* 						information 
********************************************************************************

cap log close 
//log using "$dir_log/03_drop_hholds_create_benefit_units.log", replace

use "$dir_data/${country}-SILC_pooled_all_obs_02.dta", clear 

fre swv 

/******************** Split households in to benefit units ********************/

/************************** Rules and assumptions ******************************
1. Each HH can contain: Responsible Male, and/or Responsible Female, Children, 
Other members.In the simulation everyone starts as "Other member" and is 
assigned one of the roles in the HH.

	1.1. Responsible male and female create a partnership couple leading the HH.
	Any additional couple creates new HH. A couple with / composed of people 
	under the age to leave home (18) will still live together and set up a new 
	HH. Underage (<18) parents will be considered adults. 
		 
		 1.1.1. Children should follow the mother if she's moving to a new HH. 
		 
	1.2. After the above there should be only singles left in addition to the 
	leading couple. If they are above 18, they will leave and set up their own 
	HH. 
	
	1.3. After the above there should only be children left in addition to the 
	original HH. Children will live with mother if defined in the data, 
	otherwise with father. If neither exists, they will be considered as orphans 
	
	1.4. Orphans are assigned a woman or a man from the household in which they 
	live as a parent (defined by age difference being closest to a desired 
	target).  
*/

* Recode same sex couples as singles
replace idpartner = -9 if (ssscp == 1)
replace dcpst = 2 if (ssscp == 1)

foreach vv in dgnsp dagsp dehsp_c3 dhesp lessp_c3 lessp_c4 {
	
	replace `vv' = -9 if (ssscp == 1)
	
}
replace ssscp = 0 if idpartner == -9   
//fre ssscp

* Adult is defined as 18 or over, or if married or has their own kids 
// DP: last condition added to avoid splitting kids from their teenager parents 
gen child = dag < $age_become_responsible & dcpst != 1   

* Count number of dep children of each person 
* For mother 
count 
preserve
sort swv idhh idperson

save "$dir_data/motherinfo.dta", replace

keep swv idhh idmother child
rename idmother idperson
bysort swv idperson: egen int n_child_mother = total(child) 
	//number of dependent children who have this idmother
	
duplicates drop swv idperson, force
drop child 

save "$dir_data/motherinfo.dta", replace
restore 
	
sort swv idhh idperson
merge m:1 swv idhh idperson using "$dir_data/motherinfo.dta"
fre _merge 

drop if _merge == 2 
drop _merge
count 
recode n_child_mother (. = 0)
    
* For father 
count 
preserve
sort swv idhh idperson

save "$dir_data/fatherinfo.dta", replace

keep swv idhh idfather child  
rename idfather idperson
bysort swv idperson: egen int n_child_father = total(child) 
	//number of dependent children who have this idfather
		
duplicates drop swv idperson, force
drop child 

save "$dir_data/fatherinfo.dta", replace
restore 
	
sort swv idhh idperson
merge m:1 swv idhh idperson using "$dir_data/fatherinfo.dta"
fre _merge 

drop if _merge == 2 
drop _merge
count 
recode n_child_father (. = 0)
	
gen n_child = n_child_mother + n_child_father 
/*
n of kids this individual has ==> no double count because father's kids will 
be in their line while mothers kids will be in their line 
*/
	
sum n_child_mother if n_child_mother > 0 
sum n_child_father if n_child_father > 0 
sum n_child if n_child > 0 
	
order swv idhh idperson idpartner idmother idfather dag n_child, last 

count if child == 1 & n_child > 0 // 8 obs who are kids but have their own kids 
replace child = 0 if n_child > 0  // convert teenage parents into adults   

gen adult = 1 - child 

sum child adult // 82% adults 
tab adult child 

gen partnered = (idpartner > 0) 

tab child partnered 

* Check if there are hhlds without adult(s)
assert child == 1 - adult 
cap drop num_adults  

bys swv idhh: egen num_adults = total(adult)

fre num_adults // 17 households don't contain any adults

fre idhh if num_adults == 0 
/*.
-------------------------------------------------------------------
                      |      Freq.    Percent      Valid       Cum.
----------------------+--------------------------------------------
Valid   1201757310171 |          1       5.88       5.88       5.88
        1201757709152 |          1       5.88       5.88      11.76
        1201759461162 |          1       5.88       5.88      17.65
        2201446858100 |          4      23.53      23.53      41.18 
        2201447158121 |          1       5.88       5.88      47.06
        3201553248151 |          1       5.88       5.88      52.94 
		3202397530121 |          3      17.65      17.65      70.59      
		4201237234111 |          2      11.76      11.76      82.35		
        4201237890111 |          1       5.88       5.88      88.24     
		4201239497101 |          1       5.88       5.88      94.12
		4202074940191 |          1       5.88       5.88     100.00
	
        Total         |         17     100.00     100.00           
-------------------------------------------------------------------

	
*/

/* 
This is due to errors in their idhh ==> these kids have different idhh from 
their mothers/fathers ==> correct manually, put children in their parent's 
(mother's) home 
*/
replace idhh = 1201757310100 if idperson == 120175731017101 & swv == 2017
replace idhh = 1201757709100 if idperson == 120175770915201 & swv == 2015
replace idhh = 1201759461100 if idperson == 120175946116201 & swv == 2016
replace idhh = 2201447158100 if idperson == 220144715812101 & swv == 2012
replace idhh = 3201553248100 if idperson == 320155324815113 & swv == 2015
replace idhh = 3202397530100 if idperson == 320239753012102 & swv == 2022
replace idhh = 3202397530100 if idperson == 320239753012103 & swv == 2022
replace idhh = 3202397530100 if idperson == 320239753012104 & swv == 2022
replace idhh = 4201237234100 if idperson == 420123723411116 & swv == 2011
replace idhh = 4201237234100 if idperson == 420123723411117 & swv == 2011
replace idhh = 4201237890100 if idperson == 420123789011107 & swv == 2011
replace idhh = 4201239497100 if idperson == 420123949710101 & swv == 2010
replace idhh = 4202074940100 if idperson == 420207494019101 & swv == 2019
/* 
Leftovers: 
These hholds are kids < 18 living without adults, will deal with then later
	2201446858100
*/

* Set benefit units
cap gen long idbenefitunit = .
cap gen long idbupartner = .

format idbenefitunit %19.0g
format idbupartner %19.0g

** Populate benefit units 
* Assign first couples 
/*
Logic of code here is to populate all in the hh and remove if not not in the 
same benefit unit. 
*/ 
order swv idhh idbenefitunit idbupartner idperson idpartner idmother ///
	idfather dag n_child partnered
	
gsort swv idhh -partnered -dag idperson 
/*
Sort hh members in descending order by partnership status and then age 
(this ensures that partnered adults go first) 
*/

bys swv idhh: replace idbenefitunit = idperson[1] 
	//oldest person becomes head of first benefit unit 

bys swv idhh: replace idbupartner = idpartner[1] 
	//partner of oldest person becomes first benefit unit partner 

replace idbupartner = . if idbupartner == -9

* Remove those who do not belong to first benefit unit  
* Adults 
replace idbupartner = . if (adult == 1 & idperson != idbenefitunit & ///
	idpartner != idbenefitunit) 
	//remove partner id for other adults in hh who are not head or partner 

replace idbenefitunit = . if (adult == 1 & idperson != idbenefitunit & ///
	idpartner != idbenefitunit) 
	//remove bu id or other adults in hh who are not head or partner 

* Children
replace idbupartner = . if (child == 1 & idfather != idbenefitunit & ///
	idmother != idbenefitunit & ((idfather != idbupartner & ///
	idmother != idbupartner) | idbupartner < 0)) 
	//remove partner id for kids that are not head's or partner's

replace idbenefitunit = . if (child == 1 & idfather != idbenefitunit & ///
	idmother != idbenefitunit & ((idfather != idbupartner & ///
	idmother != idbupartner) & idbupartner > 0)) 
	//remove bu id for kids that are not head's or partner's

//count if idhh == idhh[_n-1] & partnered == 0 & partner[_n-1] == 1 & ///
//	idbenefitunit[_n-1] == . 

* Assign single adult children to their own ben unit 
/* 
Their children are assigned to them later.
*/	

replace idbenefitunit = idperson if (missing(idbenefitunit) & adult == 1 & ///
	(missing(idpartner) | idpartner < 0)) 	
				
/* 
Create new ben unit for adults in hh who are partnered but not in the first 
ben unit 
*/
// Loop over number of couples in a hh that constitute an additional ben unit 
forvalues i = 1/3 {
		
	gsort swv idhh partnered idbenefitunit -dag idperson 
		/* 
		Sort so those without a partner go before those with and partnered
		individual who have been assigned a ben unit come before those who 
		haven't. Have children adn sinlge adults before the partnered so that 
		they are not impacted by the fill down. 
		*/
			
	* Create next benefit unit id 		
	bys swv idhh: replace idbenefitunit = idperson if ///
		(missing(idbenefitunit) & adult == 1 & partnered == 1 & ///
		!missing(idbenefitunit[_n-1]) & !missing(idbupartner[_n-1]))
		
	* Assign ben unit partner id 
	replace idbupartner = idpartner if (missing(idbupartner) & ///
		idbenefitunit == idperson & !missing(idpartner) & idpartner > 0)  

	* Fill down idbu to the rest of the unassigned couples in the hh 
	replace idbenefitunit = idbenefitunit[_n-1] if idhh == idhh[_n-1] & ///
		swv == swv[_n-1] & idbenefitunit == .  & partnered == 1 
	
	* Only keep benefit unit id for the partner 
	replace idbenefitunit = . if idbenefitunit != idpartner & ///
		idbupartner == . & partnered == 1 	
	
	* Assign ben unit partner id to the partner 
	replace idbupartner = idperson if idbenefitunit != . & ///
		idbupartner == . & partnered == 1 
	
} 

* Done? Any unassigned couples? 
count if adult == 1 & idbenefitunit == . & partnered == 1  
	// 0 partnered adults still have no benefit unit
recode idbupartner (. = -9) 

* Check if all adults are assigned to ben units 
count  if adult == 1 & idbenefitunit == .  // 0 
assert idbenefitunit != . if adult == 1 

gsort swv idhh -partnered idbenefitunit -dag idperson 

** Assign remaining children to the ben unit
* Assign children to their mothers' ben units (where they are heads or partners) 
gen count = 1 
bysort swv idhh: gen ttl_hh = sum(count)
replace ttl_hh = . if idbenefitunit == . 

gsort swv idhh -partnered idbenefitunit -dag idperson 

sum ttl_hh 
local max_n_bu = r(max)

forvalues i = 1/`max_n_bu' {
	
	replace idbenefitunit = idbenefitunit[_n-`i'] if idmother > 0 & ///
		missing(idbenefitunit) & child == 1 & ///
		(idmother == idbenefitunit[_n-`i'] | idmother == idbupartner[_n-`i'])
		
	replace idbupartner = idbupartner[_n-`i'] if idmother > 0 & ///
		idbupartner == -9 & child == 1 & ///
		(idmother == idbenefitunit[_n-`i'] | idmother == idbupartner[_n-`i'])	
	
} 

* Assign remaining kids to their father's ben units 
forvalues i = 1/`max_n_bu' {
	
	replace idbenefitunit = idbenefitunit[_n-`i'] if idfather > 0 & ///
		missing(idbenefitunit) & child == 1 & ///
		(idfather == idbenefitunit[_n-`i'] | idfather == idbupartner[_n-`i']) 
		
	replace idbupartner = idbupartner[_n-`i'] if idfather > 0 & ///
		idbupartner == -9 & child == 1 & ///
		(idfather == idbenefitunit[_n-`i'] | idfather == idbupartner[_n-`i'])	
	
} 

drop ttl_hh count 

gsort swv idhh -partnered idbenefitunit -dag idperson 

* Check if all kids are assigned 
count if child == 1 & idbenefitunit == . //1,235 kids are still not assigned 

cap gen orphan = (idfather < 0 & idmother < 0 & child == 1)
fre orphan if idbenefitunit == . //1,235 
/*
=> all remaining are orphans i.e. don't have any information in the dataset 
about the mother or the father. 
*/

cap drop n_orphan
bys stm idhh: egen n_orphan = sum(orphan)  
fre n_orphan	
/* 
-----------------------------------------------------------
              |      Freq.    Percent      Valid       Cum.
--------------+--------------------------------------------
Valid   0     |     279936      98.48      98.48      98.48
        1     |       2905       1.02       1.02      99.50
        2     |        887       0.31       0.31      99.81
        3     |        320       0.11       0.11      99.93
        4     |        153       0.05       0.05      99.98
        5     |         47       0.02       0.02     100.00
        7     |          9       0.00       0.00     100.00
        Total |     284257     100.00     100.00           
-----------------------------------------------------------

*/
order stm idhh idperson idpartner idfather idmother dag dgn adult orphan ///
	n_orphan 

/*
Assign orphans to adults in hh according that are most likely to be the parent 
by age. Assume an age differnce of twenty years. 
*/	
	
* Create variables storing ages for all orphans in hh 
preserve 
keep if n_orphan > 0 
keep stm idhh idperson idpartner idfather idmother dag dgn adult orphan n_orphan
keep if orphan == 1
bys stm idhh: gen orphan_number = _n if orphan == 1  

sum n_orphan
local max_orphan = r(max)

// Loop over each orphan in hh and create corresponding age variables
forvalues i = 1/`max_orphan' {  
	
	bys stm idhh: egen temp_dag_orphan`i' = sum(dag) if orphan_number == `i'  
	bys stm idhh: egen dag_orphan`i' = sum(temp_dag_orphan`i')
	drop temp_dag_orphan`i'
	
}

save "$dir_data/orphans.dta", replace 
restore 

count // 284,257

* Add info on orphan's age to the main dataset 
merge 1:1 stm idhh idperson using "$dir_data/orphans.dta",	///
	keepusing(dag_orphan* orphan_number)

keep if _merge == 1 | _merge == 3 

drop _merge 

count // 284,257

sum n_orphan
local max_orphan = r(max)

// Loop over the number of orphans in hh 
forvalues i = 1/`max_orphan' {
	
	* Create age difference between them and each adult in the hh 
	gen temp_target_age`i' = dag_orphan`i' + 20 if dag_orphan`i' > 0
	bys stm idhh: egen target_age`i' = mean(temp_target_age`i')
	gen agediff`i' = abs(dag - target_age`i') if adult == 1
	
	* Select new parent for each orphan who's age is closest to target age
	sort stm idhh agediff`i' idperson 
	by stm idhh: gen newparent`i' = _n 
	by stm idhh: replace newparent`i' = 0 if _n > 1 
	replace newparent`i' = . if n_orphan == 0

	//drop dag_orphan`i' temp_target_age`i' target_age`i' agediff`i'

	* Assign this parent's idperson as orphan's idmother or idfather 
	cap drop temp_idmother_orphan`i' 
	gen double temp_idmother_orphan`i' = idperson if newparent`i' == 1 & ///
		dgn == 0
	bys stm idhh: egen idmother_orphan`i' = max(temp_idmother_orphan`i')
	format idmother_orphan`i' %19.0g
	replace idmother_orphan`i' = 0 if orphan == 0 
	//drop temp_idmother_orphan`i'

	cap drop temp_idfather_orphan`i'
	gen double temp_idfather_orphan`i' = idperson if newparent`i' == 1 & ///
		dgn == 1
	bys stm idhh: egen idfather_orphan`i' = max(temp_idfather_orphan`i')
	format idfather_orphan`i' %19.0g
	replace idfather_orphan`i' = 0 if orphan == 0 
	//drop temp_idfather_orphan`i' 

}

* Create newidmother for orphans  
cap gen newidmother = .
cap gen newidfather = .

// Loop over the number of orphan in a hh 
forvalues i = 1/`max_orphan' {
	
	replace newidmother = idmother_orphan`i' if orphan_number == `i'
	replace newidfather = idfather_orphan`i' if orphan_number == `i'
	
}

format newidmother %19.0g
format newidfather %19.0g

* Replace idmother/idfather of former orphans 
replace idmother = newidmother if orphan == 1 
replace idfather = newidfather if orphan == 1 

drop newparent* idmother_orphan* idfather_orphan*

* Assign orphans to their new mothers' ben units (they are heads or partners) 
gsort swv idhh -dag -partnered -idperson

forvalues i = 1/13 {
	
	replace idbenefitunit = idbenefitunit[_n-`i'] if idmother > 0 & ///
		missing(idbenefitunit) & orphan == 1 & ///
		(idmother == idbenefitunit[_n-`i'] | idmother == idbupartner[_n-`i']) 
		
} 

* If some orphans are still not assigned - asign them to father's benunits 
forvalues i = 1/13 {
	
	replace idbenefitunit = idbenefitunit[_n-`i'] if idfather > 0 & ///
		missing(idbenefitunit) & orphan == 1 & ///
		(idfather == idbenefitunit[_n-`i'] | idfather == idbupartner[_n-`i'])  
		
} 

* Fill in ben unit partner info for previous orphans
bys stm idhh idbenefitunit (idperson): egen temp_idbupartner = max(idbupartner) 
fre temp_idbupartner if orphan == 1 
replace idbupartner = temp_idbupartner if orphan == 1 
	
* Assign them a second parent if first parent partnered
replace idfather = idbenefitunit if idmother == idbupartner & orphan == 1 
replace idfather = idbupartner if idmother == idbenefitunit & orphan == 1 

** Run checks 
* Any remaining orphans?
count if idbenefitunit == . // 4 obs
count if child == 1 & idbenefitunit == . // 4 obs
count if child == 1 & idbenefitunit == . & orphan == 1 // 4 orphan obs 

fre adult child orphan dag if idbenefitunit == . 
fre idperson if orphan == 1 & missing(idbenefitunit) 
fre idhh if orphan == 1 & missing(idbenefitunit) // all in the same hh 

/* The remaining unassigns children live in a house together without an adult */

* Drop remaining unassigned children 
drop if orphan == 1 & idbenefitunit == . 

/* Alternatively could assign the eldest an adult? */
/*
* Recode the first child in be nunit as adult
bys swv idhh: replace child = 0 if child == 1 & idperson == idperson[1] & ///
	orphan == 1 & num_adults == 0  
bys swv idhh: replace adult = 1 if idperson == idperson[1] & orphan == 1 & ///
	num_adults == 0 
*/

* Check if everyone is assigned to ben units 
count if idbenefitunit == .  // 0 obs unassigned
assert idbenefitunit != . 

* Check that everyone in ben unit has the same benunit partner id assigned 
//AB: idbupartner added as a secondary sorting variable to ensure replicability   
assert idbupartner != . 

replace idbupartner = . if idbupartner == -9
bys swv idbenefitunit (idbupartner): replace idbupartner = idbupartner[1] if ///
	idbupartner != idbupartner[1] //0 changes

replace idbupartner = -9 if idbupartner == .
assert idbupartner != idbenefitunit

* Screen out benefit units with multiple adults of same sex
gen adultMan = adult * (dgn == 1)
gen adultWoman = adult * (dgn == 0)

gsort swv idbenefitunit

bys swv idbenefitunit: egen sumMen = sum(adultMan)
bys swv idbenefitunit: egen sumWomen = sum(adultWoman)
tab swv sumMen
tab swv sumWomen
assert sumMen < 2 & sumWomen < 2 

* Check for duplicates in terms of swv and idperson
duplicates report swv idperson 
duplicates report stm idperson // no cases 

sort swv idbenefitunit idperson 

* Identify hholds with missing values 
cap gen dropObs = . 

* Identify orphans   
gen orphan_check = 1 if (idfather < 0 & idmother < 0) & ///
	(dag > 0 & dag < $age_become_responsible) // 18 obs 
fre dag if orphan_check == 1 // these are kids (16,17 yo) with adult partners
replace dropObs = 1 if orphan_check == 1 

* Benefit unit headed by a child 
/* 
These are below 18 yo heads who have their own kids or live with other kids)
	==> they can be kept if this condition coded out 
*/     
bys swv idbenefitunit: gen childhead = 1 if idperson == idbenefitunit & ///
	dag < $age_become_responsible
fre  childhead // 10 obs 
bys swv idbenefitunit: egen childhead_bu = max(childhead) 
replace dropObs = 1 if childhead_bu == 1 
 
* Inconsistency in union status 
/*
dcpst	-- Partnership	status
	1 partnered	
	2 single		
	3 previously	
*/

* Reports being partnered but one adult in ben unit
bys stm idbenefitunit : egen num_adult = sum(adult)
gen chk = (num_adult == 1 & dcpst == 1 & adult == 1) 
bys stm idbenefitunit : egen chk2 = max(chk)
fre chk2 // 199 obs 
/* 
This seems to be because there is a descrepancy about whether in a 
partnership or not, the other partner doesn't report partner info in raw data 
*/

replace dropObs = 1 if chk2 == 1
//AB: could preserve and just let them have their own bu without a partner 

* Reports being single but more than two adults in ben unit 
gen chk3 = (num_adult == 2 & dcpst != 1 & adult == 1) 
bys stm idbenefitunit : egen chk4 = max(chk3)
fre chk4 // 0 obs 

replace dropObs = 1 if chk4 == 1
drop num_adult chk chk2 chk3

** Check missing values 
* Missing region 
count if drgn1 == -9 // 0 obs 
replace dropObs = 1 if drgn1 == -9

* Missing age 
count if dag == -9 // 0 obs 
replace dropObs = 1 if dag == -9

* Missing age of partner (but has a partner)
count if dagsp == -9 & idpartner != -9 // 0 obs 
replace dropObs = 1 if dagsp == -9 & idpartner != -9

* Health status - remove household if missing for adults 
count if (dhe == -9 ) & dag > $age_become_responsible 
	// 0 obs due to imputation  
count if (dhe == -9 ) & dag > 0 & dag <= $age_become_responsible 
	// 0 obs due to imputation 
replace dropObs = 1 if (dhe == -9) & dag > $age_become_responsible

* Health status of spouse - remove household if missing but ind has a spouse 
count if dhesp == -9 & idpartner != -9 // 0 obs
replace dropObs = 1 if (dhesp == -9) & idpartner != -9

* Education - remove household if missing education level for adults out of edu
count if deh_c3 == -9 & dag >= $age_become_responsible & ded == 0 // 10,194 obs
replace dropObs = 1 if deh_c3 == -9 & dag >= $age_become_responsible & ded == 0

* Education of spouse - remove household if missing but individual has a spouse 
count if dehsp_c3 == -9 & idpartner != -9 // 2,896 obs 
replace dropObs = 1 if dehsp_c3 == -9 & idpartner != -9

* Partnership status 
count if dcpst == -9 // 0 obs  
replace dropObs = 1 if dcpst == -9 

* Activity status 
count if les_c3 == -9 & dag >= $age_become_responsible 
replace dropObs = 1 if les_c3 == -9 & dag >= $age_become_responsible

* Activity status with retirement as a separate category 
count if les_c4 == -9 & dag >= $age_become_responsible 
replace dropObs = 1 if les_c4 == -9 & dag >= $age_become_responsible

* Partner's activity status 
count if lessp_c3 == -9 & idpartner != -9 
replace dropObs = 1 if lessp_c3 == -9 & idpartner != -9

* Own and spousal activity status 
count if lesdf_c4 == -9 & idpartner != -9 
replace dropObs = 1 if lesdf_c4 == -9 & idpartner != -9

* Household composition 
count if dhhtp_c4 == -9 // 0 obs 
replace dropObs = 1 if dhhtp_c4 == -9

* Income 
* Gross personal non-benefit income 
//==> no missing values by construction but theoretically can be zero 
count if ypnbihs_dv == 0 & dag >= $age_become_responsible // 81,108 obs 
count if ypnbihs_dv > 0 & dag >= $age_become_responsible // 156,843 obs

* Gross personal employment income 
//==> no missing values by construction but theoretically can be zero 
count if yplgrs_dv < 0 & dag >= $age_become_responsible  // 0 obs 
count if yplgrs_dv == 0 & dag >= $age_become_responsible  // 98,386 obs 
count if yplgrs_dv > 0 & dag >= $age_become_responsible  // 139,565 obs

* Household income quintile
//==> a few missing values for kids who live w/t other adults
count if ydses_c5 == -9 & dag >= $age_become_responsible  // 0 obs 

* Gross personal non-employment capital income 
//==> no missing values by construction 
count if ypncp < 0 & dag >= $age_become_responsible // 0 obs 
count if ypncp == 0 & dag >= $age_become_responsible // 193,418 obs 
count if ypncp > 0 & dag >= $age_become_responsible // 44,533 obs

replace dropObs = 1 if ypnbihs_dv == -9 & dag >= $age_become_responsible
replace dropObs = 1 if yplgrs_dv == -9 & dag >= $age_become_responsible 
replace dropObs = 1 if ydses_c5 == -9 
replace dropObs = 1 if ypncp == -9 & dag >= $age_become_responsible
	
* Indicator for households with missing values 
cap drop dropHH
bys swv idhh: egen dropHH = max(dropObs)
tab dropHH, mis

/*

     dropHH |      Freq.     Percent        Cum.
------------+-----------------------------------
          1 |     23,963        8.43        8.43
          . |    260,290       91.57      100.00
------------+-----------------------------------
      Total |    284,253      100.00
	  
*/
 
tab dropHH swv , mis col
 
 
save "$dir_data/${country}-SILC_pooled_all_obs_03.dta", replace  
cap log close 

/*******************************************************************************
* Clean-up and exit
*******************************************************************************/
#delimit ;
local files_to_drop 
	motherinfo.dta
	fatherinfo.dta
	orphans.dta
	;
#delimit cr // cr stands for carriage return

foreach file of local files_to_drop { 
	
	erase "$dir_data/`file'"

}
