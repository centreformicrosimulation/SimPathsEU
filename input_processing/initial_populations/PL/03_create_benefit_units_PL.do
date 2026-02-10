/*******************************************************************************
* PROJECT:              SimPaths EU
* DO-FILE NAME:         03_create_benefit_units.do
* DESCRIPTION:          Screens data and creates benefit units 
********************************************************************************
* COUNTRY:              PL
* DATA:         	    EU-SILC panel dataset  
* AUTHORS: 				Daria Popova, Ashley Burdett
* LAST UPDATE:          Jan 2026 
* NOTE:					
* 						This do-file: 
* 							1. Creates benefit units ensuring the 
*							characteristics are consistent with the simulation
* 							assumptions.
*
* 							2. Identifies household to be dropped in the sample 
* 							due to missing values. 
*
* 							3. Creates benefit level homeownership variable. 					
*******************************************************************************/

cap log close 
//log using "$dir_log/03_drop_hholds_create_benefit_units.log", replace

use "$dir_data/${country}-SILC_pooled_all_obs_02.dta", clear 

fre swv 

/********************* SPLIT HOUSEHOLD INTO BENEFIT UNITS *********************/

/*
RULES AND ASSUMPTIONS:

1. Each HH can contain: Responsible Male and/or Responsible Female, Children, 
Other members. In the simulation everyone starts as "Other member" and is 
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

* Adult is defined as 18 or over, or if married, or has their own kids 
// DP: last condition added to avoid splitting kids from their teenager parents 
gen child = dag < ${age_becomes_responsible} & dcpst != 1   

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

count if child == 1 & n_child > 0 // 14 obs who are kids but have their own kids 
replace child = 0 if n_child > 0  // convert teenage parents into adults   

gen adult = 1 - child 

sum child adult // 82% adults 
tab adult child, col

gen partnered = (idpartner > 0) 

tab child partnered 

* Check if there are hhlds without adult(s)
assert child == 1 - adult 
cap drop num_adults  

bys swv idhh: egen num_adults = total(adult)

fre num_adults // 11 households don't contain any adults

fre idhh if num_adults == 0 
/*.
--------------------------------------------------------------------
                       |      Freq.    Percent      Valid       Cum.
-----------------------+--------------------------------------------
Valid   120131607501   |          1       8.33       8.33       8.33
        220142378001   |          1       8.33       8.33      16.67
        220142482401   |          1       8.33       8.33      25.00
        320117060501   |          1       8.33       8.33      33.33
        320117065902   |          1       8.33       8.33      41.67
        320117468301   |          1       8.33       8.33      50.00
        320153025101   |          1       8.33       8.33      58.33
        420128104401   |          1       8.33       8.33      66.67
        12022118890201 |          1       8.33       8.33      75.00
        12022120440001 |          1       8.33       8.33      83.33
        22023263590000 |          1       8.33       8.33      91.67
        32020742660001 |          1       8.33       8.33     100.00
        Total          |         12     100.00     100.00           
--------------------------------------------------------------------
*/

/* 
This is due to errors in their idhh ==> these kids have different idhh from 
their mothers/fathers ==> correct manually, put children in their parent's 
(mother's) home 
*/
replace idhh = 220142378000 if idperson == 22014237800101 & swv == 2012
replace idhh = 220142482400 if idperson == 22014248240101 & swv == 2013
replace idhh = 320117060500 if idperson == 32011706050101 & swv == 2010
replace idhh = 320117065900 if idperson == 32011706590201 & swv == 2010
replace idhh = 320117468300 if idperson == 32011746830101 & swv == 2011
replace idhh = 320153025100 if idperson == 32015302510101 & swv == 2015
replace idhh = 420128104400 if idperson == 42012810440101 & swv == 2010
replace idhh = 12022118890200 if idperson == 1202211889020101 & swv == 2019
replace idhh = 12022120440000 if idperson == 1202212044000101 & swv == 2021
replace idhh = 32020742660000 if idperson == 3202074266000101 & swv == 2018

/* 
Leftovers: 
These hholds are kids < 18 living without adults, will deal with then later
	120131607501
	22023263590000
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

* Assign single adults iving with parents to their own ben unit 
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

** Assign remaining children to benefit units
* Assign children to their mothers' benefit unit (where they are head or prtnr) 
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

* Assign remaining kids to their father's ben unit 
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
count if child == 1 & idbenefitunit == . //1 ,703 kids are still not assigned 

cap gen orphan = (idfather < 0 & idmother < 0 & child == 1)
fre orphan if idbenefitunit == . // 1,703
/*
=> all remaining are orphans i.e. don't have any information in the dataset 
about the mother or the father. 
*/

gen flag_orphan = (orphan == 1)
lab var flag_orphan ///
	"FLAG: Number of children in dataset that don't report mother or father id"

cap drop n_orphan
bys stm idhh: egen n_orphan = sum(orphan)  
fre n_orphan	
/* 
-----------------------------------------------------------
              |      Freq.    Percent      Valid       Cum.
--------------+--------------------------------------------
Valid   0     |     541036      98.88      98.88      98.88
        1     |       4259       0.78       0.78      99.66
        2     |       1343       0.25       0.25      99.90
        3     |        299       0.05       0.05      99.96
        4     |         75       0.01       0.01      99.97
        5     |        104       0.02       0.02      99.99
        6     |         10       0.00       0.00      99.99
        8     |         22       0.00       0.00     100.00
        9     |         13       0.00       0.00     100.00
        Total |     547161     100.00     100.00           
-----------------------------------------------------------

*/
order stm idhh idperson idpartner idfather idmother dag dgn adult orphan ///
	n_orphan 

/*
Assign orphans to adults in hh according that are most likely to be the parent 
by age. Assume an age difference of twenty years. 

Note: Could add an additional condition imposing a min age at which the 
theoretical birth is allowed to have taken place to to avoid theretical births 
happening too young. May have some cases in which the orphn is assigned to 
someone in their late teens/early twenties instead of their parents. 
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

* Assign orphans to their new mother's ben unit (they are heads or partners) 
gsort swv idhh -dag -partnered -idperson

forvalues i = 1/13 {
	
	replace idbenefitunit = idbenefitunit[_n-`i'] if idmother > 0 & ///
		missing(idbenefitunit) & orphan == 1 & ///
		(idmother == idbenefitunit[_n-`i'] | idmother == idbupartner[_n-`i']) 
		
} 

* If some orphans are still not assigned - assign them to father's ben unit 
forvalues i = 1/13 {
	
	replace idbenefitunit = idbenefitunit[_n-`i'] if idfather > 0 & ///
		missing(idbenefitunit) & orphan == 1 & ///
		(idfather == idbenefitunit[_n-`i'] | idfather == idbupartner[_n-`i'])  
		
} 

* Fill in benefit unit partner info for previous orphans
bys stm idhh idbenefitunit (idperson): egen temp_idbupartner = max(idbupartner) 
fre temp_idbupartner if orphan == 1 
replace idbupartner = temp_idbupartner if orphan == 1 
	
* Assign them a second parent if first parent partnered
replace idfather = idbenefitunit if idmother == idbupartner & orphan == 1 
replace idfather = idbupartner if idmother == idbenefitunit & orphan == 1 

replace idfather = -9 if idfather == . 
replace idmother = -9 if idmother == . 

** Run checks 
* Any remaining orphans?
count if idbenefitunit == . // 2 obs
count if child == 1 & idbenefitunit == . // 2 obs
count if child == 1 & idbenefitunit == . & orphan == 1 // 2 orphan obs 

fre adult child orphan dag if idbenefitunit == . 
fre idperson if orphan == 1 & missing(idbenefitunit) 
fre idhh if orphan == 1 & missing(idbenefitunit) 


* Drop remaining unassigned children 
drop if orphan == 1 & idbenefitunit == . 

/* Alternatively could make the eldest an adult? */
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


/*************************** DROPPING BENEFIT UNITS ***************************/
/*
Remaining to benefit units necessary to make consistent with simluation 
	assumptions: 

Can only leave the parental home at 18. Therefore )nly adults (18+) can be head 
of a benefit unit: 
	- Remains some children without idenitifed parents. 
		=> Remove from sample 
	- Currently teenage mothers who live with their parents are in the sample 
		and head of their own benefit unit. 
		=> Assign the young child to the 
		grandparents effectively making the mother and child siblings. 
		
Only adults can form partnerships
	- There are some partnerships that involve individuals <18.
		=> Convert the underage teenager into an 18 yo. 
		
Partnerships require two indiviudals 
	- There are some non-reciprocated partnerships. 
		=> Remove the ben unit of the individuals that say their in an 
		unrecognized partnership. 
*/

* Check for benefit units with multiple adults of same sex
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


* Idenitfy benefit units to drop due to benefit unit inconsistencies

cap gen dropObs = . 

* Child (<18) living without a parent 
/*
Age <age that can leave the parental home and do not have an adult in the 
benefit unit 
	==> Drop orphans from sample 
*/
gen orphan_check = 1 if (idfather < 0 & idmother < 0) & ///
	(dag > 0 & dag < ${age_leave_parental_home}) 
	
gen flag_orphan_drop = (orphan_check == 1)

lab var flag_orphan_drop "FLAG: Number of orphan obs unassigned to adult"	
	
fre dag if orphan_check == 1 

replace dropObs = 1 if orphan_check == 1 

drop orphan_check 


* Teenage parent (<18) living with parents 
/* 
Above assumed head own benefit unit if a parent. Therefore teenage mothers (<18)
who with live in thier parents home are included in the sample as the head of 
a benefit unit with their child even though they are a chid themselves. 
	==> Assign the new child to their grandparents (idmother & idfather) thus 
	effectively treat the teenage mum and their child as siblings in the code. 
	
*/     
bys swv idbenefitunit: gen childhead = (idperson == idbenefitunit & ///
	dag < ${age_becomes_responsible})
	
fre childhead // 29 obs 

gen flag_child_parent = (childhead == 1)	

lab var flag_child_parent "FLAG: Child parent"

bys swv idbenefitunit: egen childhead_bu = max(childhead) 

gen x = (childhead == 1)

replace x = 1 if x[_n-1] == 1 & idperson == idperson[_n-1] 

sort idperson swv 

count if x == 1 & idhh != idhh[_n-1] & idperson == idperson[_n-1]
// no teenage mothers observed leaving their parental home

* Make the grandparents the parents 
* Select the household in the relevant year 
gen childhead_hh = (childhead == 1)
bysort idhh swv (childhead_hh): replace childhead_hh = childhead_hh[_N] 

sort idperson swv 

* Replace benefit unit id
* Select relevant individual ids
gen idchildhead = 0 
gen idnewmum = 0 
gen idnewdad = 0 

replace idchildhead = idperson if childhead == 1 
replace idnewmum = idmother if childhead == 1 
replace idnewdad = idfather if childhead == 1 

* Populate across the household 
bysort idhh swv (idchildhead): replace idchildhead = idchildhead[_N]
bysort idhh swv (idnewmum): replace idnewmum = idnewmum[_N]
bysort idhh swv (idnewdad): replace idnewdad = idnewdad[_N]

* Select relevant new benefit id
gen idnewbu = 0 

replace idnewbu = idbenefitunit if childhead_hh == 1 & idperson == idnewmum

bysort idhh swv (idnewbu): replace idnewbu = idnewbu[_N]

format idchildhead %18.0g
format idnewmum %18.0g
format idnewdad %18.0g
format idnewbu %18.0g

gen agenewchild = -9 
replace agenewchild = dag if idmother == idchildhead & childhead == 1 
bysort idhh swv (agenewchild): replace agenewchild = agenewchild[_N]

sort idperson swv 

replace adult = 0 if idperson == idchildhead
replace child = 1 if idperson == idchildhead

* Change benefit unit id for teen mum and their child
replace idbenefitunit = idnewbu if childhead == 1 
replace idbenefitunit = idnewbu if childhead_hh == 1 & idmother == idchildhead
replace idbenefitunit = idnewbu if childhead_hh == 1 & idfather == idchildhead

* Change parent ids for teen mum and their child
replace idfather = idnewdad if childhead_hh == 1 & idfather == idchildhead
replace idmother = idnewmum if childhead_hh == 1 & idmother == idchildhead
 
* Tidy up 
drop x childhead childhead_bu childhead_hh idchildhead idnewmum idnewdad idnewbu
 
 
* Inconsistency with partnership status 
 
* Reports being partnered but one adult in ben unit
/*
Descrepancy about whether in a partnership or not, one partner doesn't report. 
	==> Make the partner reporting the relationship single to preserve 
	benefit unit strucutres
	
	Altetnatively could just delete these individuals and their benefit units 
	
NOTE: Don't update the idmother/idfather information to -9 of the non-resident 	
parent. 
*/
bys stm idbenefitunit : egen num_adult = sum(adult)

gen partner1 = (num_adult == 1 & dcpst == 1 & adult == 1) 

bys stm idbenefitunit : egen partner1_bu = max(partner1)

fre partner1 // 168 obs 
fre partner1_bu // 225 obs 

gen flag_1partner = (partner1_bu)

lab var flag_1partner ///
	"FLAG: Number of benefit unit obervations adjusted to single because individual reports being  in a partnership but partner does not recognise"

* Update partnership related variables
xtset idperson swv 
sort idperson swv

replace dcpst = 2 if partner1 == 1

replace idpartner = -9 if partner1 == 1

replace dcpen = -9 if l.dcpst != 2 & partner1 == 1 
replace dcpen = 0 if l.dcpst == 2 & partner1 == 1 

replace dcpex = -9 if partner1 == 1 
replace dcpex = 1 if l.dcpst == 1 & partner1 == 1 
replace dcpagdf = -9 if partner1 == 1

replace lesdf_c4 = -9 if partner1 == 1

replace ssscp = 0 if partner1 == 1

replace dcpyy = -9 if partner1 == 1
replace dcpyy_st = -9 if partner1 == 1

replace dhhtp_c4 = 3 if dhhtp_c4 == 1 & partner1 == 1
replace dhhtp_c4 = 4 if dhhtp_c4 == 2 & partner1 == 1

replace dagsp = -9 if partner1 == 1 

replace dgnsp = -9 if partner1 == 1 

replace dhesp = -9 if partner1 == 1 

replace dlltsd_sp = -9 if partner1 == 1 

replace lessp_c3 = -9 if partner1 == 1 

replace lessp_c4 = -9 if partner1 == 1 

replace dagpns_sp = -9 if partner1 == 1  
replace dagpns_y_sp = -9 if partner1 == 1 
replace dagpns_y1_sp = -9 if partner1 == 1 

replace dehsp_c3 = -9 if partner1 == 1 
replace dehsp_c4 = -9 if partner1 == 1 

replace partnered = 0 if partner1 == 1

drop partner1 partner1_bu


* Reports being single but more than one adult in benenfit unit 
/*
In a relationship and one partner 17 so not indicated in dcpst 
	==> Turn the teenage partner into an 18 year old 
	
*/
gen part1adult = (num_adult == 2 & dcpst == 2 & adult == 1) 

bys stm idbenefitunit : egen part1adult_bu = max(part1adult)

gen flag_adult_child_rel = (part1adult == 1)

lab var flag_adult_child_rel ///
	"Number of adults that report being in a relationship with someone under the age of responsibility"

fre part1adult_bu // 11 obs 

replace dag = 18 if part1adult == 1

drop part1adult part1adult_bu 


* Identify benefit units to drop due to missing values 

* Missing region 
count if drgn1 == -9 // 0 obs 
replace dropObs = 1 if drgn1 == -9

* Missing age 
count if dag == -9 // 13 obs 
replace dropObs = 1 if dag == -9

* Missing age of partner (but has a partner)
count if dagsp == -9 & idpartner != -9 // 0 obs 
replace dropObs = 1 if dagsp == -9 & idpartner != -9

* Health status - remove household if missing for those 16+ 
count if (dhe == -9 ) & dag > ${age_sample_min} 
	// 0 obs due to imputation  
count if (dhe == -9 ) & dag > 0 & dag <= ${age_sample_min} 
	// 0 obs due to imputation 
replace dropObs = 1 if (dhe == -9) & dag > ${age_sample_min}

* Health status of spouse - remove household if missing but ind has a spouse 
count if dhesp == -9 & idpartner != -9 // 0 obs
replace dropObs = 1 if (dhesp == -9) & idpartner != -9

* Education - remove household if missing education level for 16+
count if deh_c3 == -9 & dag >= ${age_sample_min} & ded == 0 
replace dropObs = 1 if deh_c3 == -9 & dag >= ${age_sample_min} & ///
	ded == 0

* Education of spouse - remove household if missing but individual has a spouse 
count if dehsp_c3 == -9 & idpartner != -9 // 2,896 obs 
replace dropObs = 1 if dehsp_c3 == -9 & idpartner != -9

* Partnership status 
count if dcpst == -9 // 0 obs  
replace dropObs = 1 if dcpst == -9 

* Activity status 
count if les_c3 == -9 & dag >= ${age_sample_min} 
replace dropObs = 1 if les_c3 == -9 & dag >= ${age_sample_min}

* Activity status with retirement as a separate category 
count if les_c4 == -9 & dag >= ${age_sample_min} 
replace dropObs = 1 if les_c4 == -9 & dag >= ${age_sample_min}

* Partner's activity status 
count if lessp_c3 == -9 & idpartner != -9 // 2,536 obs 
replace dropObs = 1 if lessp_c3 == -9 & idpartner != -9

* Own and spousal activity status 
count if lesdf_c4 == -9 & idpartner != -9 // 2,601 obs
replace dropObs = 1 if lesdf_c4 == -9 & idpartner != -9

* Household composition 
count if dhhtp_c4 == -9 // 0 obs 
replace dropObs = 1 if dhhtp_c4 == -9

* Income 
* Gross personal non-benefit income 
//==> no missing values by construction, theoretically can be zero 
count if ypnbihs_dv == 0 & dag >= ${age_sample_min} 
count if ypnbihs_dv > 0 & dag >= ${age_sample_min} 

* Gross personal employment income 
//==> no missing values by construction but theoretically can be zero 
count if yplgrs_dv < 0 & dag >= ${age_sample_min}  
count if yplgrs_dv == 0 & dag >= ${age_sample_min}  
count if yplgrs_dv > 0 & dag >= ${age_sample_min}  

* Household income quintile
//==> a few missing values for kids who live w/t other adults
count if ydses_c5 == -9 & dag >= ${age_sample_min}  // 0 obs 

* Gross personal non-employment capital income 
//==> no missing values by construction 
count if ypncp < 0 & dag >= ${age_sample_min} // 0 obs 
count if ypncp == 0 & dag >= ${age_sample_min} 
count if ypncp > 0 & dag >= ${age_sample_min} 

replace dropObs = 1 if ypnbihs_dv == -9 & dag >= ${age_sample_min}
replace dropObs = 1 if yplgrs_dv == -9 & dag >= ${age_sample_min} 
replace dropObs = 1 if ydses_c5 == -9 
replace dropObs = 1 if ypncp == -9 & dag >= ${age_sample_min}
	
	
* Indicator for households with missing values 
cap drop dropHH
bys swv idhh: egen dropHH = max(dropObs)
tab dropHH, mis

gen flag_drop_obs = (dropHH == 1)

lab var flag_drop_obs ///
	"FLAG: Number of observations dropped in data construction"

sort idperson swv 


/**************************** UPDATE VARIABLES ********************************/

* Number of children variables 

rename dnc dncold 
rename dnc02 dnc02old 

* Flag identifying children aged 0-17 
gen depChild = 1 if dag <= ${age_max_dep_child} & (idfather > 0 | idmother > 0)
gen depChild02 = 1 if depChild == 1 & inrange(dag,0,2)

* Mother
preserve 

drop if idmother == -9 
drop if depChild != 1 

keep idmother depChild depChild02 swv 

rename depChild has_child
rename depChild02 has_child02
rename idmother idperson 

bysort swv idperson : egen dnc_m = sum(has_child)
bysort swv idperson : egen dnc02_m = sum(has_child02)

sort idperson swv
drop if idperson == idperson[_n-1] & swv == swv[_n-1] 

drop has_child*

save "$dir_data/temp_depChild_mother", replace 

restore 

merge 1:m idperson swv using "$dir_data/temp_depChild_mother"
drop _m

* Father 
preserve 

drop if idfather == -9 
drop if depChild != 1 

keep idfather depChild depChild02 swv 

rename depChild has_child
rename depChild02 has_child02
rename idfather idperson 

bysort swv idperson : egen dnc_f = sum(has_child)
bysort swv idperson : egen dnc02_f = sum(has_child02)

sort idperson swv
drop if idperson == idperson[_n-1] & swv == swv[_n-1] 

drop has_child*

save "$dir_data/temp_depChild_father", replace 

restore 

merge 1:m idperson swv using "$dir_data/temp_depChild_father"
drop if _m == 2
drop _m

gen dnc = 0 
gen dnc02 = 0 

replace dnc = dnc_m if dgn == 0 & dnc_m < . 
replace dnc02 = dnc02_m if dgn == 0 & dnc_m < . 

replace dnc = dnc_f if dgn == 1 & dnc_f < . 
replace dnc02 = dnc02_f if dgn == 1 & dnc_f < . 

lab var dnc "Number of own dependent children 0-${age_max_dep_child} in hh"
lab var dnc02 "Number of own dependent children aged 0-2 in hh"

drop dnc_* dnc02_*

drop dncold dnc02old

// not updated new born variable 


* Home ownership variable 
preserve

egen tag_bu_wave = tag(idbenefitunit swv)
count if tag_bu_wave
local n_bu_before = r(N)
display "Number of benefit unit–wave combinations BEFORE selecting head: `n_bu_before'"


* Sort benefit unit members within each wave:
* 1. Highest non-benefit income (ypnbihs_dv)
* 2. Highest age (dag)
* 3. Lowest idperson (idperson)
gsort idbenefitunit swv -ypnbihs_dv -dag idperson 

* Tag the first person (the "head") per benefit unit and wave
bysort idbenefitunit swv: gen benunit_head = (_n == 1)

* Keep only benefit unit heads
keep if benunit_head == 1

* Count unique benefit-unit–wave combinations AFTER head selection
drop tag_bu_wave
egen tag_bu_wave = tag(idbenefitunit swv)
count if tag_bu_wave
local n_bu_after = r(N)
display "Number of benefit unit–wave combinations AFTER selecting head: `n_bu_after'"

* Ensure benefit unit–wave counts match before and after head selection
assert `n_bu_before' == `n_bu_after'

* Verify only one head per benefit unit per wave
by idbenefitunit swv, sort: gen n = _N
assert n == 1

keep idperson swv dhh_owned 

save "$dir_data/temp_dhh_owned", replace 

restore 

rename dhh_owned dhh_owned_orig

merge 1:1 idperson swv using "$dir_data/temp_dhh_owned"

drop _m 

replace dhh_owned = 0 if dhh_owned == . 

rename dhh_owned dhh_owned_ind

lab var dhh_owned_ind "Home ownership flag, only = 1 for benefit unit head"

gen dhh_owned = dhh_owned_ind

bysort idbenefitunit swv (dhh_owned): replace dhh_owned = dhh_owned[_N]
	
lab var dhh_owned "Home ownership flag, = 1 for all benefit unit members"

sort idperson swv 


/*************************** UPDATE FLAG EXCEL FILE ***************************/

* Orphans before assigning to adults
tab flag_orphan if dag < ${age_becomes_responsible}, matcell(freq) matrow(names)

scalar total = r(N)

matrix percent = (freq/total)*100

putexcel set "$dir_work/flag_descriptives", sheet("PL") modify
putexcel A72 = ("Number of orphans in dataset")
putexcel A73 = matrix(names) B73 = matrix(freq) C73 = matrix(percent) 
putexcel D73 = ("Children")


* Orphans dropped
tab flag_orphan_drop if dag < ${age_becomes_responsible}, matcell(freq) ///
	matrow(names)

scalar total = r(N)

matrix percent = (freq/total)*100

putexcel set "$dir_work/flag_descriptives", sheet("PL") modify
putexcel A75 = ("Number of orphans dropped")
putexcel A76 = matrix(names) B76 = matrix(freq) C76 = matrix(percent) 
putexcel D76 = ("Children")


* Individuals that report a partnership that is not recognized 
tab flag_1partner if dag >= ${age_becomes_responsible}, matcell(freq) ///
	matrow(names)

scalar total = r(N)

matrix percent = (freq/total)*100

putexcel set "$dir_work/flag_descriptives", sheet("PL") modify
putexcel A78 = ("Number of individuals that report a partnership that is not recognized by the other partner")
putexcel A79 = matrix(names) B79 = matrix(freq) C79 = matrix(percent) 
putexcel D79 = ("Adults")


* Individuals that report a partnership that is not recognized 
tab flag_adult_child_rel if dag >= ${age_becomes_responsible}, matcell(freq) ///
	matrow(names)

scalar total = r(N)

matrix percent = (freq/total)*100

putexcel set "$dir_work/flag_descriptives", sheet("PL") modify
putexcel A81 = ("Number of adults in a partnership with someone below the age of responsibility")
putexcel A82 = matrix(names) B82 = matrix(freq) C82 = matrix(percent) 
putexcel D82 = ("Adults")


* Dropped obs 
tab flag_drop_obs, matcell(freq) matrow(names)

scalar total = r(N)

matrix percent = (freq/total)*100

putexcel set "$dir_work/flag_descriptives", sheet("PL") modify
putexcel A84 = ("Number of dropped observatioons (dropped at hh level)")
putexcel A85 = matrix(names) B85 = matrix(freq) C85 = matrix(percent) 
putexcel D85 = ("All")


/*********************************** SAVE *************************************/

sort idperson swv 

//cf _all using "$dir_data/${country}-SILC_pooled_all_obs_03.dta"
 
save "$dir_data/${country}-SILC_pooled_all_obs_03.dta", replace  
cap log close 


/***************************** CLEAN UP AND EXIT ******************************/

#delimit ;
local files_to_drop 
	motherinfo.dta
	fatherinfo.dta
	orphans.dta
	temp_depChild_mother.dta
	temp_depChild_father.dta
	;
#delimit cr // cr stands for carriage return

foreach file of local files_to_drop  { 
	
	erase "$dir_data/`file'"

}
