********************************************************************************
* PROJECT:  		ESPON
* SECTION:			Validation
* AUTHORS:			Daria Popova, Ashley Burdett
* LAST UPDATE:		Feb 2025 (AB)
* COUNTRY: 			Greece 

* DESCRIPTION:      Screens data and identifies benefit units 

* NOTES: 			
********************************************************************************

cd "${dir_data}" 	

use "${country}-eusilc_validation_sample_prep1.dta", clear 

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

/*
* Recode same sex couples as singles
replace idpartner = -9 if (ssscp == 1)
replace dcpst = 2 if (ssscp == 1)

foreach vv in dgnsp dagsp dehsp_c3 dhesp lessp_c3 lessp_c4 {
	
	replace `vv' = -9 if (ssscp == 1)
	
}
replace ssscp = 0 if idpartner == -9   
//fre ssscp
*/

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

count if child == 1 & n_child > 0 // 0 obs who are kids but have their own kids 
replace child = 0 if n_child > 0  // convert teenage parents into adults   

gen adult = 1 - child 

sum child adult // 85% adults 
tab adult child 

gen partnered = (idpartner > 0) 

tab child partnered // partnered children

* Check if there are hhlds without adult(s)
assert child == 1 - adult 
cap drop num_adults  

bys swv idhh: egen num_adults = total(adult)

fre num_adults // 15 households don't contain any adults

fre idhh if num_adults == 0  // 15 cases 

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
forvalues i = 1/4 {
		
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
count if adult == 1 & idbenefitunit == .  // 0 
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
count if child == 1 & idbenefitunit == . //307 kids are still not assigned 

cap gen orphan = (idfather < 0 & idmother < 0 & child == 1)
fre orphan if idbenefitunit == . //all 307 
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
Valid   0     |     402123      99.80      99.80      99.80
        1     |        612       0.15       0.15      99.95
        2     |        174       0.04       0.04      99.99
        3     |         40       0.01       0.01     100.00
        Total |     402949     100.00     100.00           
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

count 

* Add info on orphan's age to the main dataset 
merge 1:1 stm idhh idperson using "$dir_data/orphans.dta",	///
	keepusing(dag_orphan* orphan_number)

keep if _merge == 1 | _merge == 3 

drop _merge 

count 

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
count if idbenefitunit == . // 15 obs
count if child == 1 & idbenefitunit == . // 15 obs
count if child == 1 & idbenefitunit == . & orphan == 1 // 15 orphan obs 

fre adult child orphan dag if idbenefitunit == . 
fre idperson if orphan == 1 & missing(idbenefitunit) 
fre idhh if orphan == 1 & missing(idbenefitunit) // all in the same hh 

/* The remaining children live alone but are 16/17 years old.*/

* Drop remaining unassigned children 
drop if orphan == 1 & idbenefitunit == . 

/* Alternatively could assign the eldest an adult? */
/*
* Recode the first child in benunit as adult
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
if ${use_assert} assert sumMen < 2 & sumWomen < 2 
	//this is not the case I suppose because we kept same sex couples 

* Check for duplicates in terms of swv and idperson
duplicates report swv idperson 
duplicates report stm idperson // no cases 
 
sort swv idbenefitunit idperson 

drop child n_child_mother n_child_father partnered num_adults n_child orphan ///
	adult n_orphan orphan_number newidmother newidfather temp_idbupartner ///
	adultMan adultWoman sumMen sumWomen

save "${country}-eusilc_validation_sample_prep2.dta", replace  

/*
************************************************************************
* Clean-up and exit
************************************************************************
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
