********************************************************************************
* PROJECT:              ESPON:
* DO-FILE NAME:         02_create_variables_EL.do
* DESCRIPTION:          Creates panel dataset used for estimating the processes. 
********************************************************************************
* COUNTRY:              EL
* DATA:         	    EU-SILC panel dataset  
* AUTHORS: 				Claire Fenwick, Daria Popova, Ashley Burdett
* LAST UPDATE:          25 May 2025
* NOTE:					Called from 00_master.do - see master file for further 
* 						details
* 						Creates the dataset used to obtain the regression 
* 						estimates for all of the processes used as inputs in 
* 						SimPaths. 
* 
*						Use -9 for missing values 
* 						Impute missing values of health status (dhe)
* 						"upid uhid year" uniquely identifies observations in the 
* 						loaded dataset
* 
* 						Things to change for each country: 
* 						- CPI
* 						- Fertility rate 
* 						- Check if any bugs in the rotation groups when 
* 							constructing the weights. 
* 						- NUTS1 regions (Check if have remained constant 
*							throughout the observation window)
* 						- Country code 
* 						- Pension age
*
*						Discrepancies: 
* 						- Labour income economic status and hours worked 
* 						
* 					
* TO DO: 				Correct hours work and employment status 
* 						Plug in my version of partnership duration 
********************************************************************************

cap log close 
//log using "${dir_log}/02_create_variables.log", replace

cd "${dir_data}"

set seed 98765

/* Obtain values of variables that change between 2020 and 2023 from the 
original panel */
 
do "$dir_do/extra_var_info/vars_05_20_${country}2.do"


use "$dir_data/${country}-SILC_pooled_all_obs_01.dta", clear

lab define dummy 1 "yes" 0 "no"

/**************************** DATA COLLECTION WAVE ****************************/
/* 
swv >> used to set the panel. The variable 'year' is unique to this 
cumulative dataset made by GESIS, not the EU-SILC panel. pb010/hb010/db010/rb010 
is the original 'year of the survey' variable. 
*/
gen swv = year

lab var swv "Data collection wave"

fre swv

/*********************** YEAR OF THE PERSONAL INTERVIEW ***********************/
/* 
stm: year of the personal interview (pb110) or year of the household 
interview could be used (hb060) 
*/
gen stm = pb110

lab var stm "Interview year"

sort upid uhid year 

* Assign missings year of the personal interview
sort uhid upid year

bysort uhid year: egen pb110_max = max(pb110)
replace stm = pb110_max if missing(stm)

drop pb110_max

* Any futher missing values are filled in using the household interview variable
replace stm = hb060 if missing(stm)

fre stm

/*
Data quirk: The interview year and data collection year are not aligned for a 
subset of observations stm == 2022 and swv == 2023. 
Alter stm to align with swv to minize the creation of duplicates. 
*/

replace stm = swv  if swv != stm 

assert swv == stm 

/******************************** INTERVIEW DATE ******************************/
/* 
The exact date of interview is not available in EU-SILC (no day recorded, only 
the quarter and the year of the personal interview). Therefore date is made so 
that all interviews happened on the 1st of the last month in the quarter. e.g. 
an interview recorded as taking place in January, February, March, 2015 is 
recorded in Int_Date as 1st March 2005. Any missing variables in the quarter 
have been reported as 06 (June) as it is in the middle of the year, and any 
missing variables in the year have been recorded as the year the survey 
took place. 
*/
gen intdatd_dv = 01 

gen intdatm_dv = 00
replace intdatm_dv = 03 if pb100 == 1
replace intdatm_dv = 06 if pb100 == 2
replace intdatm_dv = 06 if pb100 == .
replace intdatm_dv = 09 if pb100 == 3
replace intdatm_dv = 12 if pb100 == 4

gen intdaty_dv = 0000
replace intdaty_dv = pb110
replace intdaty_dv = year if intdaty_dv == .
gen Int_Date = mdy(intdatm_dv, intdatd_dv, intdaty_dv) 
format Int_Date %d

lab var Int_Date "Interview Date"

fre Int_Date

/**************************** HOUSEHOLD IDENTIFIER ****************************/
/* 
In the original EU-SILC longitudinal wave files, a household is identified 
with the Household ID variable px030/db030/hb030/rb040, in this dataset - 
created from the cumulative longitidutional dataset by GESIS - the variable 
uhid uniquely identifies households.
*/
clonevar idhh = uhid 

lab var idhh "Household identifier"

destring idhh, replace ignore($country)
format idhh %-18.0g

bysort year: sum idhh 

/********************************* INDIVIDUALS ID *****************************/ 
/* 
In the original EU-SILC longitudinal wave files, a person is identified with 
the variable rb030/pb030 (their personal ID) in this dataset - the cumulative 
longitidutional dataset - the created variable upid uniquely identifies 
observations. 
*/
clonevar idperson = upid
 
lab var idperson "Unique cross wave identifier"

destring idperson, replace ignore($country)
format idperson %-20.0g

bysort year: sum idperson

/******************************** SET PANEL ***********************************/
duplicates report year idperson 

/* 
Duplicates	in terms of swv	idperson

--------------------------------------
   Copies | Observations       Surplus
----------+---------------------------
        1 |       464750             0
        2 |         1452           726
--------------------------------------

The unique identifier of observations is idperson idhh and year not just 
idperson year. Therefore need a standard rule to rule out people residing in two 
household in a single year, generating two observations for the individual for 
that year. 		
The duplicates command in Stata preserves the first occurence of each duplicate, 
so sorting uniquely before runing the duplicates command should ensure the same 
dataset is generated everytime the do file is run. 
*/	

sort upid year uhid // AB: added to ensure drop the same duplicates each time 

duplicates drop swv idperson, force //(726 observations deleted)
xtset idperson swv 

sort upid year 

/********************************* GENDER *************************************/
gen dgn = rb090
recode dgn 2 = 0 	//dgn = 0 is female, 1 is male

lab var dgn "Gender" 
lab define dgn 1 "male" 0 "female"
lab val dgn dgn

sort idperson swv
xtset idperson swv

forvalues i = 1/18 {
	
	replace dgn = l`i'.dgn if missing(dgn) & ///
		!missing(l`i'.dgn) & idperson == l`i'.idperson 
		
}

fre year dgn // all missing from 2021 
bysort year: sum dgn  

/********************************* ID PARTNER *********************************/ 
/* 
Dataset quirks: the original variable that identifies an individual's
partner in the EU-SILC is rb240/pb180. However, GESIS made a new unique personal 
identifier (upid) for all individuals in this cumulative longitudional dataset, 
and as a result rb240 may no longer be unique and does not match-up with upid 
(required for future merging). As upid is simply a combination of urtgrp 
(a variable made by GESIS that identifies the rotational group and dropout year 
an individual belongs to) and the original unique personal identifier (rb030) it 
is possible to update rb240 to be consistent with GESIS's new unique personal 
identifier. TITs, I combine urtgrp and rb240 to ensure idpartner aligns with 
upid and do the same for idfather and idmother. 

Note on the variable: rb240 includes married people and partners in a 
consensual union (with or without a legal basis).
*/
tostring rb240, replace format(%-18.0g) 
gen idpartner = (urtgrp + rb240)
destring rb240, replace
destring idpartner, replace ignore($country)
replace idpartner = . if rb240 == .

lab var idpartner "Unique cross wave identifier of partner"

recode idpartner . = -9
format idpartner %-18.0g

/**************** ID FATHER (includes natural/step/adoptive) ******************/
tostring rb220, replace format(%-18.0g)   
gen idfather = (urtgrp + rb220)
destring rb220, replace
destring idfather, replace ignore($country)
replace idfather = . if rb220 == .

lab var idfather "Father unique identifier"

format idfather %-18.0g
recode idfather . = -9

/******************* ID MOTHER (includes natural/step/adoptive) ***************/
tostring rb230, replace format(%-18.0g)  
gen idmother = (urtgrp + rb230)
destring rb230, replace
destring idmother, replace ignore($country)
replace idmother = . if rb230 == .

lab var idmother "Mother unique identifier"

recode idmother . = -9
format idmother %-18.0g

sort idperson year 

/******************************* AGE ******************************************/ 
/* 
EU-SILC has a number of possible variables that could be used to create age. 
Age at end of inc ref period (px020), age at the time of the interview (rx010), 
as well as year of birth (rb080). 

Method 1: For the 'age at time of...' variable, those over 80 are recorded as 
'over 80' rather than providing their true age. 
Using 'age at time of...' means that we need to manually age up individuals 
recorded as 'over 80' over time. 
Unfortunately, there is definitely some measurement error of some kind as using 
this method to create age shows that ages 80-82 are overrepresented and there is
no one over age 82 in the dataset. 

Method 2: On the other hand, using year of birth to create age means that there 
are too many 78-80 year olds recorded and there is no one older than 81 present 
in the dataset. 
In addition, for some countries (e.g. Malta) this wouldn't work as year of birth
 is coded inside age groups. 

For the final code, we chose Method 2 - the option with less imputation (year of
the personal interview - year of birth). 
As a bonus, there are no missing observations with this method. I also provide 
Method 1 below (coded out) in case you would like to switch methods in the 
future.

AB: Not only is the raw data top coded but also the topcoding is enforced on the 
last observation of any of each rotation group. Consequently, the top coded age
for a specific roation group varies through time (79-81). To ccount for this we
decided to implement a top-coding at age 79. 

I added some imputation methods to correct for some of the inconsistencies 
and flags so that remaining issues are accounted for when constructing later 
variables that relay on transitions and age. 

*/

gen dag = stm - rb080

lab var dag "Age"

fre dag
tab dag year 

* Enforce 78 top coding 
replace dag = 78 if dag > 78 & dag != . 

* Check age
sort idperson swv 
gen age_dif = dag - dag[_n-1] if idperson == idperson[_n-1] & ///
	swv == swv[_n-1] + 1
	
tab age_dif	

count if age_dif != 0 & age_dif != 1 & age_dif != . // 1,235 obs

order idperson swv rb080 rx010 rx020 dag age_dif

tab rb080 if age_d != 1 & age_d != . 	// most come from old people... 
tab swv if age_d != 1 & age_d != . 	// ...at the beginningor end of the dataset

* Imputation using surrounding values and set flag 
/*
Logic of 3 methods 
- If age in last and next observations are consistent force age into alignment 
- If last two consecutive observations are consistent force age into alignment
- If last observation consistent has a reported age force age into alignment

Leave remaining but create a flag to ensure accounted for when constructing 
later variables that have age conditions. 
*/

gen dag_flag = 0 

* Use consistnecy of surrounding observations 
replace dag_flag = 1 if dag != dag[_n-1] + 1 & age_d != 1 & age_d != 0 & ///
	age_d != . & idperson[_n-1] == idperson[_n+1] & swv[_n-1] == swv[_n+1] - 2 

replace dag = dag[_n-1] + 1 if age_d != 1 & age_d != 0 & ///
	age_d != . & idperson[_n-1] == idperson[_n+1] & swv[_n-1] == swv[_n+1] -2 
	
* Use consistency in previous two years 		
replace dag_flag = 1 if dag != dag[_n-1] + 1 & age_d != 1 & age_d != 0 & ///
	age_d != . & idperson[_n-2] == idperson & dag[_n-2] == dag[_n-1] - 1
	
replace dag = dag[_n-1] + 1 if age_d != 1 & age_d != 0 & ///
	age_d != . & idperson[_n-2] == idperson & dag[_n-2] == dag[_n-1] - 1 

* Use previous age observation 	
replace dag_flag = 1 if dag != dag[_n-1] + 1 & age_dif != 0 & age_dif != 1 & ///
	 age_dif != . & rx010[_n-1] != . & idperson[_n-1] == idperson
 
replace dag = dag[_n-1] + 1 if  age_dif != 0 & age_dif != 1 & age_dif != . & ///
	rx010[_n-1] != . & idperson[_n-1] == idperson

lab var dag_flag "=1 if dag is imputed"
	
* Create flag for individual with remaining age concerns	
drop age_dif	
 
gen age_dif = dag - dag[_n-1] if idperson == idperson[_n-1] & ///
	swv == swv[_n-1] + 1

order idperson swv rb080 rx010 dag age_dif

tab age_dif
	
count if age_dif != 0 & age_dif != 1 & age_dif != . // 0 obs 

drop  age_dif dag_flag

fre dag 
bys swv: sum dag 
	
/* Method 1: this option creates 149 missing values in the IT data and so we 
need to do some imputations alongside aging up those recorded as 'over 80'
gen dag = rx010
recode dag (.=-9)
//fre dag

* Impute values for the few missings:
	sort idperson swv
	forvalues i = 1/12 {
	
		replace dag = f`i'.dag-`i' if dag==-9 & (f`i'.dag !=-9) & ///
			idperson==f`i'.idperson
			
	}
	
* Impute values for those recorded in the 'over 80' category:
	sort idperson swv
	forvalues i = 1/12 {
	
		replace dag = l`i'.dag+`i' if dag<=80 & idperson==l`i'.idperson
		
	}
//fre dag
*/

* Age squared 
gen dagsq = dag^2

lab var dagsq "Age squared"

/************************* REGION (NUTS 1) ************************************/ 
//fre db040

/*
In 2013 Thessaly became part of Central Greece. In exchange Epirus became part   
of Northern Greece. Therefore the NUTS1 codes changed: 
	EL1 -> EL5
	EL2 -> EL6

In 2011, the population of the region of Thessaly was 732,762 and represented 
6.8% of the total population of Greece. 
Given this si a non-negligable change I have combined the NOrthern and central 
regions to ensure geographical consistency. 

EL7 = EL5 + EL6	(Northern and Central Greece)

*/

clonevar drgn1 = db040 

replace drgn1 = subinstr(drgn1, "$country", "", .)
destring drgn1, replace

tab drgn1 year  
 
replace drgn1 = 7 if drgn1 == 1 | drgn1 == 2 | drgn1 == 5 | drgn1 == 6

tab drgn1 year, col 

lab var drgn1 "Region"
lab def drgn1 ///
	3 "Attika" ///
	4 "Aegean Islands" ///
	7 "Central and Northern Greece" 
	
lab val drgn1 drgn1

recode drgn1 (. = -9)

fre drgn1
tab drgn1 year, col

/***************************** COUNTRY ****************************************/
gen dct = .
lab var dct "Country code: $country"

/********************************* UNION **************************************/
/* 
Generate union variable to indicate if there is a partner in the hh; dun should 
not distinguish between partners with and without legal recognition and tITs 
include both cohabiting couples and married couples. 

PB200 - Consensual union 
	1	Yes, on a legal basis	
	2	Yes, without a legal basis	
	3	No

In EU-SILC: a family `nuclei' is constituted when two persons (of either sex) 
choose to live together as a married couple, in a registered partnership, or in 
a consensual union, whether or not they have children; single parents with 
children also constitute a family unit, while people living alone do not, nor do 
groups of unrelated people who choose to share a house together (for example, 
students).
  
Consensual union with a legal basis includes both married couples and registered
partners and without refers to a "de facto" partner. 
Both modalities have to live in the same household in both instances.  
From my understanding, this includes same sex couples. 

In variable construction assume that not married if missing information unless
partner information is missing. 
*/
/*
//fre pb200
gen dun = 0
replace dun = 1 if pb200 < 3
*/
/* 
Alternative is to use idpartner - this is consistent with partnership variable 
below 
*/
gen dun = (idpartner > 0)

lab var dun "Has a partner"
lab val dun dummy 

fre dun 
tab dun year, col 
bys dun: sum idpartner if idpartner == -9 
bys dun: sum idpartner if idpartner > 0 

/***************************** PARTNER'S GENDER *******************************/
/* 
In the cumulative longitidutional dataset created by GESIS, a unique 
household ID (uhid) and unique personal id (upid) were created. 
This no longer matches partner IDs/mother & father IDs/etc. 
*/
duplicates report idpartner swv if idpartner > 0 
//swv, stm or year are all equal, so any of this could be used for merging 

/*
Duplicates in terms of idpartner swv

--------------------------------------
   Copies | Observations       Surplus
----------+---------------------------
        1 |       247393             0
--------------------------------------

*/

preserve
keep swv idperson dgn
rename idperson idpartner
rename dgn dgnsp
save "$dir_data/temp_dgn", replace 
restore

merge m:1 idpartner swv using "$dir_data/temp_dgn" 
	//m:1 because some people have idpartner = -9
	
lab var dgnsp "Partner's gender"
keep if _merge == 1 | _merge == 3
drop _merge

lab values dgnsp dgn
recode dgnsp (. = -9)

fre dgnsp if idpartner > 0 
tab dgnsp year, col 


/**************************** PARTNER'S AGE ***********************************/ 
preserve

keep swv idperson dag  

rename idperson idpartner
rename dag dagsp 

save "$dir_data/temp_age", replace

restore

merge m:1 swv idpartner using "$dir_data/temp_age"

lab var dagsp "Partner's age"

keep if _merge == 1 | _merge == 3
drop _merge

sort idperson swv 
fre dagsp if idpartner > 0  
	// 2 people in a relationship with a partner 16 or younger 
	// 6 people in a relationship with a partner 17 or younger
bys swv: sum dagsp 
	
/******************************* HEALTH STATUS ********************************/

//fre ph010
/* Use ph010 (general health) variable: 
-----------------------------------------------------------------
                    |      Freq.    Percent      Valid       Cum.
--------------------+--------------------------------------------
Valid   1 Very good |     164603      35.36      41.72      41.72
        2 Good      |     116981      25.13      29.65      71.37
        3 Fair      |      70723      15.19      17.92      89.29
        4 Bad       |      31384       6.74       7.95      97.25
        5 Very bad  |      10862       2.33       2.75     100.00
        Total       |     394553      84.76     100.00           
Missing .           |      70923      15.24                      
Total               |     465476     100.00                      
-----------------------------------------------------------------
Reverse code so 5 = excellent and higher number means better health
*/

* Reverse code
recode ph010 (5 = 1 "Poor") ///
	(4 = 2 "Fair") ///
	(3 = 3 "Good") ///
	(2 = 4 "Very good") ///
	(1 = 5 "Excellent") ///
	, into(dhe)
	
lab var dhe "Health status"
fre dhe 
tab dhe year, col 

* Impute missing values
fre dag if missing(dhe) 

* Ordered probit model
recode dgn dag dagsq drgn1 (-9 = .), gen (dgn2 dag2 dagsq2 drgn12)
fre dgn2 dag2 dagsq2 drgn12
xi: oprobit dhe i.dgn2 dag2 dagsq ib3.drgn12 i.swv if dhe < ., vce(robust)

//AB: added stochastic imputation method 

predict p1 p2 p3 p4 p5

* Create CDF
gen p1p2 = p1 + p2 
gen p1p2p3 = p1p2 + p3
gen p1p2p3p4 = p1p2p3 + p4 

* Add heterogenity
gen rnd = runiform()

* Create imputation
gen imp_dhe = cond((rnd < p1), 1, cond(rnd < p1p2, 2, ///
	cond(rnd < p1p2p3, 3, cond(rnd < p1p2p3p4, 4, 5))))

sum imp_dhe if missing(dhe) & dag > 0 & dag < 16 // all children missing data
sum imp_dhe if !missing(dhe) & dag > 0 & dag < 16
sum imp_dhe if missing(dhe) & dag >= 16
sum imp_dhe if !missing(dhe) & dag >= 16

gen dhe_flag = missing(dhe)
lab var dhe_flag "=1 if dhe is imputed"
replace dhe = round(imp_dhe) if missing(dhe)

bys dhe_flag: fre dhe if dag <= 16
bys dhe_flag: fre dhe if dag > 16 

drop dgn2 dag2 dagsq2 drgn12 _Idgn2_1 _Iswv_* p1* p2 p3 p4 p5 rnd imp_dhe

fre dhe 
tab dhe year, col 
bys swv: sum dhe 

/************************** PARTNER'S HEALTH STATUS ***************************/
preserve

keep swv idperson dhe dhe_flag

rename idperson idpartner
rename dhe dhesp
rename dhe_flag dhesp_flag

save "$dir_data/temp_dhe", replace

restore

merge m:1 swv idpartner using "$dir_data/temp_dhe"

lab var dhesp "Partner's health status"
keep if _merge == 1 | _merge == 3
drop _merge

cap lab define dhe 1 "Poor" 2 "Fair" 3 "Good" 4 "Very good" 5 "Excellent"
lab values dhesp dhe 

replace dhesp = -9 if missing(dhesp) & idpartner > 0

fre dhesp if idpartner > 0 
tab dhesp year, col 
bys swv: sum dhesp 

/**************************** SUBJECTIVE WELL-BEING ***************************/
/*
There are no variables in the EU-SILC that could be used to make this. 
The only variables pertaining to health are: 
(1) ph010 - general health, 
(2) ph020 - suffer from a chronic illness or condition, and 
(3) ph030 - limitation in activities because of health problems.
*/

/************************* EDUCATIONAL ATTAINMENT *****************************/
/* 
Use pe040 variable, code negative values to missing
	Low education: 		Other qualification, no qualification
	Medium education: 	Other higher degree, A-level etc, GCSE etc
	High education: 	Degree
	
EU SILC variables: Variables top coded 
PE040 - Highest ISCED evel attained
	0		Pre-primary education	
	1		Primary education	
	2		Lower secondary education	
	3		(Upper) secondary education	
	4		Post-secondary non-tertiary education	
	5		1st & 2nd stage of tertiary education	
	100		Primary education	
	200		Lower secondary education 
	300		Upper secondary education (not further specified)
	344		Level completion, with direct access to tertiary education	
	353		Level completion, without direct access to tertiary education	
	354		Level completion, with direct access to tertiary education	
	400		Post-secondary non-tertiary education (not further specified) 
	450		Vocational education	
	500		Short cycle tertiary	

PE041- Highest ISCED evel attained
	0		No formal education or below ISCED 1	
	100		ISCED 1 Primary education	161	0.6	1.9
	200		ISCED 2 Lower secondary education 
	340		ISCED 3 Upper secondary education- general
	344		ISCED 3 Upper secondary education (general) 
			- level completion, w/ direct access to tertiary education 
	350		ISCED 3 Upper secondary education - vocational (age 35 and over)	
	353		ISCED 3 Upper secondary education (vocational) 
			- level completion, w/o direct access to tertiary education 
	354		ISCED 3 Upper secondary education (vocational) 
			- level completion, w/ direct access to tertiary education 
	450		ISCED 4 Post-secondary non-tertiary education - vocational	
	500		IT: ISCED 5 
	
AB: In 2021 pe041 replaced pe040. However for IT the values for earlier years 
in which pe040 was collected have not been converted into pe041 and pe040 is not 
in the dataset. Therefore many values for 2018-2020 missing for the later 
panels. For now merging observations from Clare's original panel which only goes 
up to 2020 and therefore doesn't have this problem because only includes pe040. 
*/

replace pe040 = . if pe040 < 0
sort  idperson swv

* Merge in values from 2020 panel 
merge 1:1 year pid hid using "$dir_data/temp_orig_edu"

replace pe040 = pe040_orig if pe040 == . & pe040_orig != . 

drop if _m == 2 
drop _m pe040_orig

* 2005-2020
gen deh_c3 = .
replace deh_c3 = 3 if pe040 == 0 | pe040 == 1 | pe040 == 2 | pe040 == 100 ///
	| pe040 == 200
replace deh_c3 = 2 if pe040 == 3 | pe040 == 4 | (pe040 >= 300 & pe040 < 500)
replace deh_c3 = 1 if pe040 == 5 | (pe040 >= 500 & pe040 <= 1000)
		
* 2021-2023		
replace deh_c3 = 3 if pe041 == 0 | pe041 == 100 | pe041 == 200
replace deh_c3 = 2 if pe041 >= 300 &  pe041 < 500
replace deh_c3 = 1 if pe041 >= 500 &  pe041 <= 800
		
lab var deh_c3 "Education status"
lab define l_deh_c3 3 "low" 2 "medium" 1 "high"
lab values deh_c3 l_deh_c3
		
* Assumed in school until 17 		
replace deh_c3 = 3 if dag <= 16 & dag > -9 
replace deh_c3 = -9 if deh_c3 == . 

* Impute missing values 
/* 
Impute missing values using lagged values of up to 18 previous waves
pl031 and pl032 are the variables for self-defined current economic status. 
*/
sort idperson swv
xtset idperson swv 

forvalues i = 1/18 {
	
	replace deh_c3 = l`i'.deh_c3 if missing(deh_c3) & ///
		!missing(l`i'.deh_c3) & pl031 != 6 &  pl032 != 5 & ///
		idperson == l`i'.idperson 

}

fre deh_c3	// 16,866 = 3.62% missing
fre dag if deh_c3 == -9  
fre year if deh_c3 == -9 // 37% of missing are in 2020  
tab deh_c3 year, col mis 
bys swv: sum deh_c3 if deh_c3 > 0 

/************************* PARTNER'S EDUCATION STATUS *************************/
preserve

keep swv idperson deh_c3

rename idperson idpartner
rename deh_c3 dehsp_c3 

save "$dir_data/temp_deh", replace

restore

merge m:1 swv idpartner using "$dir_data/temp_deh"

lab var dehsp_c3 "Education status partner"
	
keep if _merge == 1 | _merge == 3
drop _merge
replace dehsp_c3 = -9 if missing(dehsp_c3) & idpartner > 0

fre dehsp_c3 if idpartner > 0 // 2.32% missing 
tab dehsp_c3 year, col // 26% missig from 2020 
bys swv: sum dehsp_c3 if dehsp_c3 > 0 

/*************************** PARENT'S EDUCATION STATUS ************************/ 
/* 
There is no variable for parent's education status in EU-SILC, but can be 
made for those with parent IDs in the data.
1. Create mothers and fathers education levels in new file with person and hh id 
2. Merge by father and mother id and hh id 
*/

gen dehm_c3 = .
gen dehf_c3 = .

preserve
keep swv idperson idhh deh_c3
drop if missing(deh_c3)
rename idperson idmother
rename deh_c3 mother_educ
save "$dir_data/mother_edu", replace

rename idmother idfather
rename mother_educ father_educ
save "$dir_data/father_edu", replace
restore

merge m:1 swv idmother idhh using "$dir_data/mother_edu" 
keep if _merge == 1 | _merge == 3
drop _merge
merge m:1 swv idfather idhh using "$dir_data/father_edu"
keep if _merge == 1 | _merge == 3
drop _merge

replace dehm_c3 = mother_educ
replace dehf_c3 = father_educ

fre dehm_c3 if dgn > 0 & dag > 0
fre dehf_c3 if dgn > 0 & dag > 0

* Identify the highest parental education status 
//recode dehm_c3 dehf_c3 (.=0) 
egen dehmf_c3 = rowmax(dehm_c3 dehf_c3)
lab var dehmf_c3 "highest parental education status"
fre dehmf_c3
//recode dehm_c3 dehf_c3 (0 = .) 
fre dehmf_c3 if dehm_c3 == . 
fre dehmf_c3 if dehf_c3 == . 

/* Only a third of the dataset has an observation for parental education and so 
the following code used to predict the value is not very accurate. 
Perhaps it could be improved using income or other related factors? For now, it 
is coded out.
 
*Predict highest parental education status if missing 
*Recode education level (outcome variable) so 1 = Low education, 
* 2 = Medium education, 3 = High education
recode dehmf_c3 ///
	(1 = 3) ///
	(3 = 1) ///
	, gen(dehmf_c3_recoded)
	
la def dehmf_c3_recoded 1 "Low" 2 "Medium" 3 "High"
la val dehmf_c3_recoded dehmf_c3_recoded
fre dehmf_c3_recoded

*ordered probit model to replace missing values  
recode dgn dag drgn1 (-9=.) , gen (dgn2 dag2 drgn12)
fre dgn2 dag2 drgn12

xi: oprobit dehmf_c3_recoded i.dgn2 dag2 ib8.drgn12 i.swv, vce(robust)
predict pred_probs1 pred_probs2 pred_probs3, pr

//Identify the category with the highest predicted probability
egen max_prob = rowmax(pred_probs1 pred_probs2 pred_probs3)
//Impute missing values based on predicted probabilities
gen imp_dehmf_c3_recoded = .
replace imp_dehmf_c3_recoded = 1 if max_prob == pred_probs1
replace imp_dehmf_c3_recoded = 2 if max_prob == pred_probs2
replace imp_dehmf_c3_recoded = 3 if max_prob == pred_probs3

fre imp_dehmf_c3_recoded if missing(dehmf_c3_recoded) 
fre imp_dehmf_c3_recoded if !missing(dehmf_c3_recoded)

recode imp_dehmf_c3_recoded ///
	(1 = 3) ///
	(3 = 1) ///
	, gen(imp_dehmf_c3)

tab2 imp_dehmf_c3_recoded imp_dehmf_c3

cap gen dehmf_c3_flag = missing(dehmf_c3) 
lab var dehmf_c3_flag "=1 if dehmf_c3 is imputed"
replace dehmf_c3 = round(imp_dehmf_c3) if missing(dehmf_c3) 
lab define dehmf_c3 1 "High" 2 "Medium" 3 "Low"

bys dehmf_c3_flag: fre dehmf_c3

drop dehmf_c3_recoded dgn2 dag2 drgn12 _Idgn2_1 _Iswv_* pred_probs* max_prob ///
	imp_dehmf_c3_recoded imp_dehmf_c3
*/

/************************** PARTNERSHIP STATUS ********************************/
/* 
pb190 -- Marital status (MT: 3,5=3)
	1 	Never married	
	2 	Married	
	3 	Separated 
	4 	Widowed	
	5 	Divorced	
*/
gen dcpst = . 
replace dcpst = 1 if idpartner > 0 //partnered 
replace dcpst = 2 if idpartner < 0 & pb190 == 1 
	//no partner in hh and is single 
replace dcpst = 3 if idpartner < 0 & pb190 != 1 
	//no partner and previously partnered 
	
lab var dcpst "Partnership status"
lab def dcpst 1 "partnered" 2 "single" 3 "previously partnered" 
lab val dcpst dcpst 

recode dcpst (. = -9)

fre dcpst // no missing values 
tab dcpst year, col
bys swv: sum dcpst if dcpst > 0 

* Children coded as "Never Married" 
/*
Can only marry from age 18 onwards in the simulation 
*/
replace dcpst = 2 if dag <= 17 & idpartner < 0

* Check consistency 
tab dun dcpst

/**************************** ENTER PARTNERSHIP *******************************/
sort idperson swv 
xtset idperson swv 

gen dcpen = -9
replace dcpen = 0 if (l.dcpst == 2 | l.dcpst == 3)
replace dcpen = 1 if (dcpst == 1 & (l.dcpst == 2 | l.dcpst == 3))

lab val dcpen dummy
lab var dcpen "Enter partnership"

fre dcpen // 68% missing
tab dcpen year, col
bys swv: sum dcpen if dcpen >= 0 

* Check consistency 
tab dcpen dcpst
tab dcpen dun


/*
* Check why there are so many missing values : all good  
preserve 
xtset idperson swv
bysort idperson: egen interview_count = count(swv)
bysort idperson (swv): gen first_appearance = (swv == swv[1])

tab2 dcpst dcpen if swv>=2011, m
tab2 dcpst dcpen if swv>=2011, m r nof 
tab2 dcpst dcpen if swv>=2011 & interview_count>=2 & first_appearance!=1, m
tab2 dcpst dcpen if swv>=2011 & interview_count>=2 & first_appearance!=1, ///
	m r nof
restore 
*/
/****************************** NEW PARTNERSHIP *******************************/
gen new_rel = 0 if dcpst == 1
replace new_rel = 1 if dcpen == 1

lab var new_rel "Partnerhip in first year"

tab new_rel year, col 
bys swv: sum new_rel if new_rel >= 0 

/**************************** EXIT PARTNERSHIP ********************************/
/*
Only populated if can transition out of a relationship, i.e. need to be observed 
in a relationship
*/
sort idperson swv 
xtset idperson swv 

gen dcpex = -9
replace dcpex = 0 if l.dcpst == 1
replace dcpex = 1 if dcpst == 3 & l.dcpst == 1 

lab val dcpex dummy
lab var dcpex "Exit partnership" 

fre dcpex 
tab dcpex year, col
bys swv: sum dcpex if dcpex >= 0 

* Check consistency 
tab dun dcpex

/* 
Some of the observations are reported as single instead of previously partnered
leading to inconsistency. Recode to previosuly partnered 
*/

replace dcpst = 3 if dun == 0 & dcpex == 0 

* Update 
sort idperson swv 
xtset idperson swv 

replace dcpex = 1 if dcpst == 3 & l.dcpst == 1 

tab dun dcpex

/**************************** PARTNER AGE DIFFERENCE **************************/
gen dcpagdf = dag - dagsp if (dag > 0 & dagsp > 0) 

lab var dcpagdf "Partner's age difference"

fre dcpagdf // 46.85% missing  
tab dcpagdf year, col
bys swv: sum dcpagdf

/************************ ECONOMIC ACTIVITY STATUS ****************************/
/* 
Activity status is coded very differently in EU-SILC to Understanding Society
** pl030/pl031 is "self-defined economic status" and has the most detail but 
many missings, 
I use rb210 "basic activity status", which is less granular (i.e. information 
on students is not available), to fill in some of the missings 
*/

/* AB: In 2021 pl032 replaced pl031. However for PL the values for earlier years 
in which pl031 was collected have not been converted into pl032 and pl031 is not 
in the dataset. Therefore many values for 2018-2020 missing for the later 
panels. For now merging observations from Clare's original panel which only goes 
up to 2020 and therefore doesn't have this problem becuase only includes pl031.

PL031 - Self defined current economic status 
	1	Employee working full-time	
	2	Employee working part-time	
	3	Self-employed working full-time (including family worker)	
	4	Self-employed working part-time (including family worker)	
	5	Unemployed		
	6	Pupil, student, further training, unpaid work experience	
	7	In retirement or in early retirement or has given up business	
	8	Permanently disabled or/and unfit to work	
	10	Fulfilling domestic tasks and care responsibilities	
	11	Other inactive person	
	
RB210 - Basic activity status
	1	At work	
	2	Unemployed	
	3	In retirement or early retirement	
	4	Other inactive person	

PL032 - Self defined current economic status 	
	1	Employed	
	2	Unemployed	
	3	Retired	
	4	Unable to work due to long-standing health problems	
	5	Student, pupil	
	6	Fulfilling domestic tasks	
	7	Compulsory military or civilian service	
	8	Other

RB211 - Main activity status (self-defined)
	1	Employed	
	2	Unemployed	
	3	Retired	
	4	Unable to work due to long-standing health problems	
	5	Student, pupil	
	6	Fulfilling domestic tasks	
	8	Other	

PL040A - Status in employement 	
	1	Self-employed with employees	
	2	Self-employed without employees	
	3	Employee	
	4	Family worker (unpaid)
*/

* Add in values of variables from 2020 and before 
merge 1:1 pid hid year using "$dir_data/temp_orig_econ_status"

replace pl031 = pl031_orig if pl031 == . & pl031_orig != . 
replace rb210 = rb210_orig if rb210 == . & rb210_orig != . 

drop if _m == 2 
drop _m *_orig

* 2009-2020
recode pl031 (1 2 3 4 = 1 "Employed or self-employed") ///
	(6 = 2 "Student") /// 
	(5 7 8 9 10 11 = 3 "Not employed") /// 
	, into(les_c3)
	
lab var les_c3 "LABOUR MARKET: Activity status"

* 2005-2008 
replace les_c3 = 1 if (pl030 == 1 | pl030 == 2) & les_c3 == .
replace les_c3 = 2 if (pl030 == 4) & les_c3 == .
replace les_c3 = 3 if (pl030 == 5 | pl030 == 6 | pl030 == 8 | pl030 == 9) & ///
	les_c3 == .

* 2021-2023
replace les_c3 = 1 if les_c3 == . & pl032 == 1
replace les_c3 = 2 if les_c3 == . & pl032 == 5
replace les_c3 = 3 if les_c3 == . & inrange(pl032,2,4)
replace les_c3 = 3 if les_c3 == . & inrange(pl032,6,8)

replace les_c3 = 1 if les_c3 == . & pl040a == 1
replace les_c3 = 1 if les_c3 == . & pl040a == 2
replace les_c3 = 1 if les_c3 == . & pl040a == 3

* Utilizing alternative raw variables 

* 2005-2020 
replace les_c3 = 1 if rb210 == 1 & les_c3 == .
replace les_c3 = 3 if inrange(rb210,2,4) & les_c3 == .

* 2021-2023
replace les_c3 = 1 if rb211 == 1 & les_c3 == .
replace les_c3 = 2 if rb211 == 5 & les_c3 == . 	
replace les_c3 = 3 if (inrange(rb211,2,4) | rb211 == 6 | rb211 == 8 ) & ///
	les_c3 == .
	
* For people 16 and under set activity status to student
replace les_c3 = 2 if dag <= 16 

* In simulation only permitted to return to education until the age of 35 
replace les_c3 = 3 if les_c3 == 2 & dag > 35 

* In simulation can only work when can leave home (18+)
replace les_c3 = 3 if dag < 18 & les_c3 != 2 
 
tab year if !missing(les_c3) 
tab year if missing(les_c3) 

fre les_c3 // 2.52% missing 
tab les_c3 year, col
bys swv: sum les_c3

/******************** ECONOMIC ACTIVITY STATUS WITH RETIREMENT ****************/ 
/*
Variable construction choice seems to matter here. 
At present, the pl* vars take precedent when constructing les_c3, however this 
precidence was not imposed when coding les_c4. 
Explored imposing pl* priority over rb* in les_c4 as well. 
Comparing the two approaches makes some difference (10,000 more retired when 
use original method)

Also note that the original method of no priority to pl* vars creates a some 
retired people who are working or students according to les_c3. 

Implemented the new suggested method below. Helps with consistency.
*/
clonevar les_c4 = les_c3
/*
replace les_c4 = 4 if pl031 == 7 | pl030 == 5 | pl032 == 3 | rb210 == 3 | ///
	rb211 == 3 
*/

replace les_c4 = 4 if pl031 == 7 | pl030 == 5 | pl032 == 3 

replace les_c4 = 4 if pl031 == . &  pl030 == . & rb210 == 3 
replace les_c4 = 4 if pl032 == . & rb211 == 3 

lab var les_c4 "LABOUR MARKET: Activity status, inc retirement"
lab define les_c4  1 "Employed or self-employed"  2 "Student"  ///
	3 "Not employed"  4 "Retired"
lab val les_c4 les_c4

tab2 les_c3 les_c4

// AB: Some students/working are retired, corrected so report not employed 
* Impose consistency across les_c3 and les_c4
replace les_c3 = 3 if les_c4 == 4  //0 changes

* Make retirement an absorbing state to align with simulation 
sort idperson swv 

gen retire_absorb = 1 if les_c4 == 1 
replace retire_absorb = 1 if idperson == idperson[_n-1] & ///
	retire_absorb[_n-1] == 4 

replace les_c4 = 4 if idperson == idperson[_n-1] & les_c4[_n-1] == 4 & ///
	les_c4 != 4  //5,197 changes 

* Make consistent with les_c3 
replace les_c3 = 3 if les_c4 == 4 //2,652 changes 	

* Check consistency 
tab2 les_c3 les_c4, row

fre les_c4 // 2.12% missing 
tab les_c4 year, col
bys swv: sum les_c4

/************************ LONG-TERM SICK OR DISABLED **************************/
gen dlltsd = 0
replace dlltsd = 1 if pl030 == 6 | pl031 == 8 | pl032 == 4

* Imputation - assume persistent for two/three years if missing 
sort idperson swv 
xtset idperson swv

/*
replace dlltsd = 1 if (pl030 == . & pl031 == . & pl032 == .) & ///
	(l.pl030 == 6 | l.pl031 == 8 | l.pl032 == 4) 
replace dlltsd = 1 if (pl030 == . & pl031 == . & pl032 == .) & ///
	(l.pl030 == . & l.pl031 == . & l.pl032 == .) & ///
	(l2.pl030 == 6 | l2.pl031 == 8 | l2.pl032 == 4) 
*/

lab var dlltsd "DEMOGRAPHIC: LT sick or disabled"

* Check consistency with les_c3
tab dlltsd les_c3
count if dlltsd == 1 & les_c3 == . 

* Impose consistency 	
replace dlltsd = 0 if les_c3 == 1 // 0 changes 
	
* Impose consistency 
replace les_c3 = 3 if dlltsd == 1 & les_c3 == . // 315 changes

* Check consistency with les_c4
tab dlltsd les_c4
count if dlltsd == 1 & les_c4 == . // imputation 
/*
Some individuals coded as retired and long-term disabled. 
Appears to be due to forcing retirement to be an absorbing state. 
	=> alter dlltsd dummy 
Also missing values due to imputation as with les_c3 
*/	

* Impose consistency with les_c4
replace les_c4 = 3 if dlltsd == 1 & les_c4 == .
replace dlltsd = 0 if les_c4 == 4
	
tab les_c3 les_c4
	
fre dlltsd //5.09%
tab dlltsd year, col 
bys swv: sum dlltsd

tab les_c3 dll 
tab les_c4 dll

/******************************* UNEMPLOYMENT *********************************/
fre pl020 pl031

gen unemp = (pl031 == 5 | pl032 == 2)

replace unemp = . if les_c3 == . 
replace unemp = . if dag < 18 

lab var unemp "Unemployed dummy"

fre unemp
tab unemp year, col 
bys swv: sum unemp

* Check consistency 
tab unemp les_c3 
tab unemp les_c4 

replace unemp = 0 if les_c4 == 4 & unemp == 1 // retirement imputation 

tab unemp les_c4 

/*********************** IN INITIAL EDUCATION SPELL ***************************/
/* 
In the understanding society data notes from codebook differ from the code 
below: In education from jbstat variable, where jbstat = 7 then in education. 
If missing then used previous or next wave's labour force status and dates left
education to fill in.
If have returned to education following a break then ded = 0.

sort idperson swv 
cap gen ded = 0 
replace ded = 1 if pl031 == 6 & (l.pl031==6 ) //| l.pl031 == .
replace ded = 1 if pl030 == 4 & (l.pl030==4 ) //| l.pl030 == .

/*is a full-time student now and was full-time student in previous wave*/

la val ded dummy
la var ded "DEMOGRAPHIC : In Continuous Education"
//fre ded
//bys ded: fre dag 
*/

/*
Decision 25/10/2024: We opted to revise this variable to ensure that individuals 
who are observed out of their initial education spell in one year, aren't 
recorded as being in initial education spell in future years. 
We include current students who were not observed in the previous wave if 
they are aged <= 25  because the average age of those entering a masters degree 
24.2
(https://gpseducation.oecd.org/CountryProfile?primaryCountry=ITA&treshold=10&topic=EO) 
*/
sort idperson swv 
xtset idperson swv
gen ded = 0 

* Everyone under 16 should be in education 
replace ded = 1 if dag <= 16 
/*
DP: 16 years olds are included as otherwise they are more likely to be out of 
education compared to 17 yo etc.
 */

replace ded = 1 if pl030 == 4 & idperson != idperson[_n-1] & dag <= 26
replace ded = 1 if pl031 == 6 & idperson != idperson[_n-1] & dag <= 26 
replace ded = 1 if pl032 == 5 & idperson != idperson[_n-1] & dag <= 26 

replace ded = 1 if l.ded == 1 & pl030 == 4 
replace ded = 1 if l.ded == 1 & pl031 == 6 
replace ded = 1 if l.ded == 1 & pl032 == 5 

lab var ded "In initial education spell"

fre ded // 20.9% obs 
tab ded year, col 
tab dag ded, row
bys swv: sum ded

* Ensure that don't return to initial education spell once left 
sort idperson swv 

count if ded == 1 & ded[_n-1] == 0 & idperson == idperson[_n-1] // 0 obs 

* Check consistency 
tab ded les_c3 
tab ded les_c4 

tab ded unemp
tab ded dlltsd 

/**************************** HOURS OF WORK ***********************************/
/*
PL060 - Number of hours usually worked per week in current main job 
*/
clonevar lhw = pl060

lab var lhw "Hours worked per week"

* Check consistency - how many non-workers report positive hours? 
bys les_c3: fre lhw 
	// AB: 482 cases with positive hours of work who are not employed 
	// AB: 2113 cases of missing les_c3 info but positive hours of work recorded
sort idperson swv 
tab les_c4 if lhw > 0 & lhw != . // AB: mostly retired ppl 
count if les_c4 == 4 & lhw < . & les_c4[_n-1] == 4 & lhw[_n-1] == . & ///
	idperson == idperson[_n-1] // 337 observations
	
/*
Most contradictions are from the retired, a small number among the not 
employed

Contradictions amoung the retired appears to be due to making retirement an 
absorbing state. 
 
Contradictions with those that are not employed are 17 year olds not permitted 
in the labour market yet to align with the simulation. 

Decision: Because activity status is more important, prioritize this information
=> If activity status implies not working, give zero working hours 
=> If activity status says should be working but missing working hrs info,  
	impute the missing values using the mode of part-time/fulll-time workers 
	with hours work information.  

Relevate variables: 
2009-2020
pl031 - Self defined current economic activity 
1	Employee working full-time	
2	Employee working part-time	
3	Self-employed working full-time (including family worker)	
4	Self-employed working part-time (including family worker)	
5	Unemployed	
6	Pupil, student, further training, unpaid work experience 
7	In retirement or in early retirement or has given up business	
8	Permanently disabled or/and unfit to work	
9	In compulsory military community or service	
10	Fulfilling domestic tasks and care responsibilities	
11	Other inactive person	

2021-2023
pl145 - Fill-time/part-time job
1	Full-time job	
2	Part-time job	

Impute missing value as the mode of corresponding subsample. 
*/ 

* Impose consistency  
replace lhw = . if les_c4 == . // 2,113

* Those that aren't recorded as working, set hours equal to zero. 
replace lhw = 0 if les_c4 == 4 
replace lhw = 0 if les_c4 == 2 
replace lhw = 0 if les_c4 == 3 

* Address missing values of the employed with missing hours info 
gen lhw_flag = 1 if les_c3 == 1 & lhw == . 

* Full-time 
gen ft = .  
replace ft = 1 if pl031 == 1 | pl031 == 3
replace ft = 1 if pl145 == 1 

* Part-time 
gen pt = . 
replace pt = 1 if pl031 == 2 | pl031 == 4
replace pt = 1 if pl145 == 2

tab les_c4 ft if year > 2008 
replace ft = . if les_c3 != 1
replace pt = . if les_c3 != 1

* Collect the mode of both types of workers
egen mode_ft = mode(lhw) if ft == 1 & ft != . 
egen mode_pt = mode(lhw) if pt == 1 & pt != . 

tab mode_ft
tab mode_pt

* Replace the missing hours 
replace lhw = mode_ft if ft == 1 & lhw == . & les_c3 == 1 
replace lhw = mode_pt if pt == 1 & lhw == . & les_c3 == 1 

count if lhw == . & les_c3 == 1 //1,1469

* Assume the leftovers work ft 
replace lhw = 40 if lhw == . & les_c3 == 1 

* Check consistency - how many workers do not report hours? 
tab les_c3 if lhw == . 
tab les_c3 if lhw > 0 
tab les_c3 if lhw == 0 

tab les_c4 if lhw == . 
tab les_c4 if lhw > 0 
tab les_c4 if lhw == 0 

* Check consistency 
tab les_c3 les_c4

count if les_c3 == . 
count if les_c4 == . 

tab les_c3 ded

tab les_c3 dlltsd
tab les_c4 dlltsd

tab les_c4 unemp 

tab les_c4 ded 

tab les_c3 unemp 

// baseline economic activity variables do not change from here on 

/********************* LAGGED ECONOMIC ACTIVITY STATUS ************************/
* Without retirement 
xtset idperson swv
sort idperson swv 

gen l1_les_c3 = l.les_c3 

lab def l1_les_c3 1 "Employed or self_employed" 2 "Student" 3 "Not employed"
lab val l1_les_c3 l1_les_c3
lab var l1_les_c3"LABOUR MARKET: Activity status, t-1"

* With retirement 
xtset idperson swv
sort idperson swv 

gen l1_les_c4 = l.les_c4 

lab def l1_les_c4 1 "Employed or self_employed" 2 "Student" ///
	3 "Not employed" 4 "Retired"
lab val l1_les_c4 l1_les_c4
lab var l1_les_c4 "LABOUR MARKET: Activity status, inc retirement, t-1"

/************************** PARTNER'S ACTIVITY STATUS *************************/
preserve

keep swv idperson idhh les_c3

rename les_c3 lessp_c3
rename idperson idpartner

save "$dir_data/temp_lesc3", replace

restore

merge m:1 swv idpartner idhh using "$dir_data/temp_lesc3"
keep if _merge == 1 | _merge == 3
lab var lessp_c3 "Partner's activity status"
drop _merge

fre lessp_c3
tab lessp_c3 year, col 

/******************* PARTNER'S ACTIVITY STATUS WITH RETIREMENT ****************/
preserve

keep swv idperson idhh les_c4

rename les_c4 lessp_c4
rename idperson idpartner

save "$dir_data/temp_lesc4", replace

restore

merge m:1 swv idpartner idhh using "$dir_data/temp_lesc4"
keep if _merge == 1 | _merge == 3 

lab var lessp_c4 "LABOUR MARKET: Partner's activity status"
lab val lessp_c4 les_c4
drop _merge

fre lessp_c4
tab lessp_c4 year, col 

/********************** OWN AND SPOUSE ACTIVITY LEVELS ************************/
gen lesdf_c4 = -9
replace lesdf_c4 = 1 if les_c3 == 1 & lessp_c3 == 1 & dcpst == 1 //Both employed
replace lesdf_c4 = 2 if les_c3 == 1 & (lessp_c3 == 2 | lessp_c3 == 3) & ///
	dcpst == 1 //Employed, spouse not employed
replace lesdf_c4 = 3 if (les_c3 == 2 | les_c3 == 3) & lessp_c3 == 1 & ///
	dcpst == 1 //Not employed, and spouse employed
replace lesdf_c4 = 4 if (les_c3 == 2 | les_c3 == 3) & ///
	(lessp_c3 == 2 | lessp_c3 == 3) & dcpst == 1 //Both not employed

lab def lesdf_c4 1 "Both employed" 2 "Employed and spouse not employed" ///
	3 "Not employed and spouse employed" 4 "Both not employed" -9 "Missing"
lab val lesdf_c4 lesdf_c4

lab var lesdf_c4 "Own and spouse activity status"

fre lesdf_c4
tab lesdf_c4 year, col
bys swv: sum lesdf_c4 if lesdf_c4 >= 0

/*************************** EMPLOYMENT EXPERIENCE ****************************/
gen liwwh = -9
replace liwwh = pl200 if pl200 >= 0 & pl200 != . 
replace liwwh = 55 if pl200 > 55 & pl200 != . //make upper censoring consistent

lab var liwwh "Number of years spent in paid work"

fre liwwh 
tab liwwh year, col 
bys swv: sum liwwh if liwwh >= 0

/*************************** RETURN TO EDUCATION ******************************/
/*
Only populated when at risk of transitioning into education 
*/
xtset idperson swv
sort idperson swv 

cap gen der = -9
replace der = 0 if l.les_c3 != 2 & l.les_c3 < . 
replace der = 1 if les_c3 == 2 & l.les_c3 != 2 & l.les_c3 < . 

lab val der dummy
lab var der "Return to education"

fre der // 67% of observation missing value 
tab der year, col 
bys swv: sum der if der >= 0

* Check consistency 
tab der ded 

* Age in estimation 16-35
tab dag der

/**************************** CIVIL SERVANT STATUS ****************************/
/*
There is no variable for civil servant status in EU-SILC
**occupation is found in pl051/pl050 and follows ISCO-08/88.
*/
//fre pl051
	
/***************************** ADULT CHILD FLAG *******************************/
preserve 

keep if dgn == 0
keep swv idhh idperson dag

rename idperson idmother
rename dag dagmother

save "$dir_data/temp_mother_dag", replace

restore, preserve

keep if dgn == 1
keep swv idhh idperson dag

rename idperson idfather
rename dag dagfather

save "$dir_data/temp_father_dag", replace 

restore

merge m:1 swv idhh idmother using "$dir_data/temp_mother_dag"
keep if _merge == 1 | _merge == 3
drop _merge

merge m:1 swv idhh idfather using "$dir_data/temp_father_dag"
keep if _merge == 1 | _merge == 3
drop _merge

/* 
Adult child is identified on the successful merge with mother/father in 
the same household and age 
*/
gen adultchildflag = (!missing(dagmother) | !missing(dagfather)) & ///
	(dag >= 18 & dag <= 30) & idpartner <= 0
	
* Adult children cannot be older than parents-15 years of age
replace adultchildflag = 0 if dag >= dagfather - 15 | dag >= dagmother - 15 

fre adultchildflag
tab adultchildflag year, col
bys adultchildflag: fre dag 

/**************************** NUMBER OF CHILDREN ******************************/
/* 
18+ is considered an adult -> can marry/divorce/etc.

AB: Unclear what the definition of the variable should be. At present it seems
that this is the number of children (0-17) in the household in which the mother
or father also resides. 
Perhaps instead we want it to capture the number of dependent children each 
individual lives with? 
To implement this could bysort over year and mother/father id? Done so below
but not adjusted for fertility feasibility by age. 
*/

* Flag identifying children aged 0-17 
gen depChild = 1 if dag <= 17 & (idfather > 0 | idmother > 0)
gen depChild02 = 1 if depChild == 1 & dag <= 2

/*
* Number of dependent children in hh aged 0-17
bys swv idhh: egen dnc = sum(depChild)
//drop depChild

lab var dnc "Number of dependent children 0 - 17"

* Number of children aged 0-2
gen child02 = 1 if dag <= 2 & (idfather > 0 | idmother > 0)
bys swv idhh: egen dnc02 = sum(child02)
//drop child02

lab var dnc02 "Number of children aged 0-2"
*/
* Alternative approach requiring stated as mother or father 
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
drop _m

gen dnc = 0 
gen dnc02 = 0 

replace dnc = dnc_m if dgn == 0 & dnc_m < . 
replace dnc02 = dnc02_m if dgn == 0 & dnc_m < . 

replace dnc = dnc_f if dgn == 1 & dnc_f < . 
replace dnc02 = dnc02_f if dgn == 1 & dnc_f < . 

lab var dnc "Number of own dependent children 0-17 in hh"
lab var dnc02 "Number of own dependent children aged 0-2 in hh"

drop dnc_* dnc02_*
*/
fre dnc dnc02
tab dnc year, col
tab dnc02 year, col

sum dag if dnc != 0 , de
// older parents are men which in principle is fine 

/************************ HOUSEHOLD COMPOSITION *******************************/
/*
Note: For consistency with the simulation adult children and children above
age to become responsible should be assigned "no children" category, even if 
there are some children in the household 
*/
* Without economics activity 
cap gen dhhtp_c4 = -9
replace dhhtp_c4 = 1 if dcpst == 1 & dnc == 0 //Coupled, no children
replace dhhtp_c4 = 2 if dcpst == 1 & dnc > 0 //Coupled, children
replace dhhtp_c4 = 3 if (dcpst == 2 | dcpst == 3) & (dnc == 0 | dag <= 18 | ///
	adultchildflag == 1) //Not partnered, no children 
replace dhhtp_c4 = 4 if (dcpst == 2 | dcpst == 3) & dnc > 0 & dhhtp_c4 != 3 
	//Not partnered, children

lab def dhhtp_c4_lb 1 "Coupled with no dep children" ///
	2 "Coupled with dep children" 3 "Single with no dep children" ///
	4 "Single with dep children"
lab val dhhtp_c4 dhhtp_c4_lb
lab var dhhtp_c4 "Household composition"

fre dhhtp_c4 // 3.53% single parents
tab dhhtp_c4 year, col 

* With economic activity 
gen dhhtp_c8 = . 

replace dhhtp_c8 = 1 if dhhtp_c4 == 1 & lessp_c3 == 1
replace dhhtp_c8 = 2 if dhhtp_c4 == 1 & lessp_c3 == 2
replace dhhtp_c8 = 3 if dhhtp_c4 == 1 & lessp_c3 == 3	
replace dhhtp_c8 = 4 if dhhtp_c4 == 2 & lessp_c3 == 1
replace dhhtp_c8 = 5 if dhhtp_c4 == 2 & lessp_c3 == 2
replace dhhtp_c8 = 6 if dhhtp_c4 == 2 & lessp_c3 == 3	
replace dhhtp_c8 = 7 if dhhtp_c4 == 3
replace dhhtp_c8 = 8 if dhhtp_c4 == 4

lab def dhhtp_c8 	1 "Couple with no children, spouse employed" ///
					2 "Couple with no children, spouse student" ///
					3 "Couple with no children, spouse not employed" ///
					4 "Couple with children, spouse employed" ///
					5 "Couple with children, spouse student" ///
					6 "Couple with children, spouse not employed" ///
					7 "Single with no children" ///
					8 "Single with children" 
lab val dhhtp_c8 dhhtp_c8	

lab var dhhtp_c8 "Household composition with economic activity info"

fre dhhtp_c8 // 0.80% single parents
tab dhhtp_c8 year, col 	
bys swv: fre dhhtp_c8 

/******************* PARTNER LONG-TERM SICK OR DISABLED ***********************/
preserve

keep swv idperson dlltsd
rename idperson idpartner
rename dlltsd dlltsd_sp

save "$dir_data/temp_dlltsd", replace

restore

merge m:1 swv idpartner using "$dir_data/temp_dlltsd"

lab var dlltsd_sp "Partner's long-term sick"

keep if _merge == 1 | _merge == 3
drop _merge

fre dlltsd_sp if idpartner > 0 
tab dlltsd_sp year, col 

/****************************** RETIRED ***************************************/
gen dlrtrd = 0
replace dlrtrd = 1 if les_c4 == 4
replace dlrtrd = -9 if les_c4 == . 
sort idperson swv 

lab var dlrtrd "DEMOGRAPHIC : Retired"

fre dlrtrd // 31.36% retired
tab dlrtrd year, col

tab les_c3 dlrtrd
tab les_c4 dlrtrd

/**************************** ENTER RETIREMENT ********************************/
/* 
Only populated if at risk of transition.
*/
sort idperson swv 
gen drtren = -9 

replace drtren = 0 if l.dlrtrd == 0 
replace drtren = 1 if dlrtrd == 1 & l.dlrtrd == 0 

lab val drtren dummy
lab var drtren "DEMOGRAPHIC: Enter retirement"

fre drtren //54.5% missing
tab drtren year, col

tab drtren les_c4

/**************************** PENSION AGE *************************************/

/*State Retirement Ages for Men in the EL (2009-2024):

2005-2006: 65
2006-2007: 65
2007-2008: 65
2008-2009: 65
2009-2010: 65
2010-2011: 65
2011-2012: 65
2012-2013: 65
2013-2014: 67
2014-2015: 67
2015-2016: 67
2016-2017: 67
2017-2018: 67
2018-2019: 67
2019-2020: 67
2020-2021: 67
2021-2022: 67
2022-2023: 67

State Retirement Ages for Women in the EL (2005-2023):

2005-2006: 60
2006-2007: 60
2007-2008: 60
2008-2009: 60
2009-2010: 60
2009-2010: 60
2010-2011: 61
2011-2012: 63
2012-2013: 65
2013-2014: 67
2014-2015: 67
2015-2016: 67
2016-2017: 67
2017-2018: 67
2018-2019: 67
2019-2020: 67
2020-2021: 67
2021-2022: 67
2022-2023: 67

Ages are approximate. Greece had various options and loop holes for taking early  
retirement and various stages of resisitence to implementation of the reforms. 
https://www.etui.org/covid-social-impact/greece/pension-reform-in-greece-background-summary#:~:text=In%202010%20Law%203863%20set,been%20contributing%20for%2040%20years.
*/

gen dagpns = 0

* Men
replace dagpns = 1 if dgn == 1 & dag >= 65 & stm >= 2005 & stm < 2013
replace dagpns = 1 if dgn == 1 & dag >= 67 & stm >= 2013 & stm <= 2023 
 
* Women 
replace dagpns = 1 if dgn == 0 & dag >= 60 & stm >= 2005 & stm < 2010
replace dagpns = 1 if dgn == 0 & dag >= 61 & stm == 2010 
replace dagpns = 1 if dgn == 0 & dag >= 63 & stm == 2011
replace dagpns = 1 if dgn == 0 & dag >= 65 & stm == 2012
replace dagpns = 1 if dgn == 0 & dag >= 67 & stm >= 2013 & stm <= 2023 

fre dagpns //25% of retirement age 

* Become eligable for the state pension dummy 
gen dagpns_y = 0 

* Men 
replace dagpns_y = 1 if dgn == 1 & dag == 65 & stm >= 2005 & stm < 2013
replace dagpns_y = 1 if dgn == 1 & dag == 67 & stm >= 2013 & stm <= 2023 

* Women
replace dagpns_y = 1 if dgn == 0 & dag == 60 & stm >= 2005 & stm < 2010
replace dagpns_y = 1 if dgn == 0 & dag == 61 & stm == 2010
replace dagpns_y = 1 if dgn == 0 & dag == 63 & stm == 2011
replace dagpns_y = 1 if dgn == 0 & dag == 65 & stm == 2012
replace dagpns_y = 1 if dgn == 0 & dag == 67 & stm >= 2013 & stm <= 2023 


* Became eligable for state pension last year 
gen dagpns_y1 = 0 

* Men 
replace dagpns_y1 = 1 if dgn == 1 & dag == 66 & stm >= 2005 & stm < 2013
replace dagpns_y1 = 1 if dgn == 1 & dag == 68 & stm >= 2013 & stm <= 2023 

* Women
replace dagpns_y1 = 1 if dgn == 0 & dag == 61 & stm >= 2005 & stm < 2010
replace dagpns_y1 = 1 if dgn == 0 & dag == 62 & stm == 2010
replace dagpns_y1 = 1 if dgn == 0 & dag == 64 & stm == 2011
replace dagpns_y1 = 1 if dgn == 0 & dag == 66 & stm == 2012
replace dagpns_y1 = 1 if dgn == 0 & dag == 68 & stm >= 2013 & stm <= 2023 


lab var dagpns_y "Age became eligable for full state pension"
lab var dagpns_y1 "Age+1 became eligable for full state pension"

tab dag dagpns_y
tab dag dagpns_y

/**************************** PENSION AGE OF SPOUSE ***************************/
* Above state pension age dummy 
preserve

keep swv idperson idhh dagpns
rename dagpns dagpns_sp
rename idperson idpartner

save "$dir_data/temp_dagpns", replace

restore

merge m:1 swv idpartner idhh using "$dir_data/temp_dagpns"
keep if _merge == 1 | _merge == 3
drop _merge

lab var dagpns_sp "Pension age - partner"

replace dagpns_sp = -9 if idpartner < 0

* At age when can first claim state pension or year after
preserve

keep swv idperson idhh dagpns_y dagpns_y1 
rename dagpns_y dagpns_y_sp
rename dagpns_y1 dagpns_y1_sp
rename idperson idpartner

save "$dir_data/temp_dagpns_y", replace

restore

merge m:1 swv idpartner idhh using "$dir_data/temp_dagpns_y"
keep if _merge == 1 | _merge == 3
drop _merge

lab var dagpns_y_sp "Age became eligable for pension - partner"
lab var dagpns_y1_sp "Age+1 became eligable for pension - partner"

replace dagpns_y_sp = -9 if idpartner < 0
replace dagpns_y1_sp = -9 if idpartner < 0

fre dagpns_sp 
fre dagpns_y_sp
fre dagpns_y1_sp

/****************************** NOT RETIRED ***********************************/
gen lesnr_c2 = . 
replace lesnr_c2 = 0 if les_c4 == 1
replace lesnr_c2 = 1 if inrange(les_c4,2,3)
	
lab var lesnr_c2 "Not retired work status"
lab define lesnr_c2 0 "in work" 1 "not in work"
lab val lesnr_c2 lesnr_c2 

fre lesnr_c2 
tab lesnr_c2 year, col

/************************ EXITED THE PARENTAL HOME ****************************/
/* 
Generated from parent ids. 1 means that individual no longer lives with a 
parent when in the previous wave they lived with a parent.
*/
sort idperson swv

gen dlftphm = -9 if (l.idmother < 0 & l.idfather < 0) 
replace dlftphm = 0 if (l.idmother > 0 | l.idfather > 0) 
replace dlftphm = 1 if (idmother < 0 & idfather < 0) & ///
	(l.idmother > 0 | l.idfather > 0) 
by idperson: replace dlftphm = -9 if _n == 1

lab val dlftphm dummy
lab var dlftphm "DEMOGRAPHIC: Exited Parental Home"

bys swv: fre dlftphm // 78% missing
tab dlftphm year, col

tab dlftphm dun 

/******************************** LEFT EDUCATION ******************************/
/*
Only populated if can transition out of education 
*/
sort idperson swv 

gen sedex = -9 
replace sedex = 0 if l.les_c3 == 2
replace sedex = 1 if les_c3 != 2 & sedex == 0 & les_c3 != . 
	
lab val sedex dummy
lab var sedex "Left education"

fre sedex // 96% missing
fre sedex if sedex > -9 // 29% leave
tab sedex year, col

* Check consistency 
tab ded sedex
tab sedex les_c3
tab sedex les_c4

/*************************** SAME SEX PARTNERSHIP *****************************/
gen ssscp = 0 if idpartner > 0
replace ssscp = 1 if dcpst == 1 & dgn == dgnsp & dgnsp != .

lab val ssscp dummy
lab var ssscp "Partnership is same sex"

fre ssscp //0.06%
tab ssscp year, col

/*********************** YEAR PRIOR TO ENDING RELATIONSHIP ********************/
/* 
Impossible to know for the most recent wave so set to 0 to keep the variable.
All observations populated, not just those in a relationship 
*/

sort idperson swv 

gen scpexpy = 0
replace scpexpy = 1 if f.dcpex == 1 
replace scpexpy = -9 if swv == 2023

lab val scpexpy dummy
lab var scpexpy "Year prior to exiting partnership"

fre scpexpy // 1%
tab scpexpy year, col 

/*************************** WOMEN AGED 18 - 45 *******************************/
gen sprfm = 0
replace sprfm = 1 if dgn == 0 &  dag >= 18 & dag <= 45

lab val sprfm dummy
lab var sprfm "Woman in fertility range dummy (18-45)"

fre sprfm 
tab sprfm year, col

/************************** EL GENERAL FERTILITY RATE *************************/

/* General fertility rate in ITngary covers the age range 15-49, statistics are 
from the ITngarian Central Statistical Office (KSH) */

gen dukfr = .
/*
replace dukfr = 39.8 if stm == 2005 
replace dukfr = 41.1 if stm == 2006
replace dukfr = 40.5 if stm == 2007 
replace dukfr = 41.3 if stm == 2008
replace dukfr = 40.3 if stm == 2009 
replace dukfr = 37.9 if stm == 2010
replace dukfr = 37.1 if stm == 2011
replace dukfr = 38.7 if stm == 2012
replace dukfr = 38.2 if stm == 2013
replace dukfr = 39.7 if stm == 2014
replace dukfr = 40.0 if stm == 2015
replace dukfr = 40.9 if stm == 2016
replace dukfr = 40.6 if stm == 2017
replace dukfr = 40.2 if stm == 2018
replace dukfr = 40.2 if stm == 2019
replace dukfr = 42.0 if stm == 2020
replace dukfr = 42.7 if stm == 2021
replace dukfr = 40.9 if stm == 2022
replace dukfr = 40.1 if stm == 2023
lab var dukfr "$country general fertility rate (KSH)"
*/
//fre dukfr

/*********************** NUMBER OF NEW BORN CHILDREN **************************/
gen child0 = 0
replace child0 = 1 if dag <= 1 
bysort idmother swv: egen dchpd = total(child0) if idmother > 0

fre dchpd

preserve 

keep swv idmother dchpd
rename idmother idperson 
rename dchpd mother_dchpd

drop if idperson < 0

collapse (max) mother_dchpd, by(idperson swv)
duplicates report idperson swv

save "$dir_data/mother_dchpd", replace

restore 

merge 1:1 swv idperson using "$dir_data/mother_dchpd", keepusing (mother_dchpd)

keep if _merge == 1 | _merge == 3
drop _merge

replace mother_dchpd = 0 if dgn == 1
drop dchpd

rename mother_dchpd dchpd

lab var dchpd "Women's number of new born children"

fre dchpd 
tab dchpd year, col

tab dchpd dnc02 if dgn == 0 

/************************** IN EDUCATIONAL AGE RANGE **************************/
gen sedag = 1 if dag > 16 & dag <= 29
replace sedag = 0 if missing(sedag)

lab val sedag dummy
lab var sedag "Eduation age range"

fre sedag 
tab sedag year, col 

/*************************** PARTNERSHIP DURATION *****************************/
/*
There are no equivalent variables in the EU-SILC for partnership duration 
prior to the entry into the panel.
Max duration is 4 years
*/
preserve 
keep idperson idpartner swv 
replace idpartner = . if idpartner < 0

xtset idperson swv //Set panel
tsspell idpartner //Count spells of having partner with the same id. 
rename _seq partnershipDuration 
replace partnershipDuration = . if idpartner == .
//keep if swv == 13
keep swv idperson partnershipDuration 
save "$dir_data/tmp_partnershipDuration", replace
restore

merge 1:1 swv idperson using "$dir_data/tmp_partnershipDuration", keep(1 3) ///
	nogen 

gen dcpyy = partnershipDuration if idpartner > 0
replace dcpyy = partnershipDuration if (idpartner > 0)
lab var dcpyy "Years in partnership"

by swv: fre dcpyy

* Alternative - observed with partnered status for x consecutive years
sort idperson swv 
gen dcpyy_st = 1 if dcpst == 1 
replace dcpyy_st = dcpyy_st + dcpyy_st[_n-1] if idperson == idperson[_n-1] & ///
	idpartner == idpartner[_n-1] & swv == swv[_n-1] + 1 & dcpyy_st != . & ///
	dcpyy_st[_n-1] != . 
	
lab var dcpyy_st "Observed with partnered status for x consecutive years"

tab dcpyy_st swv, col

tab dcpst dcpyy_st

/************************** OECD EQUIVALENCE SCALE ****************************/
* Temporary number of children 0-13 and 14-18 to create OECD hh equiv scale
gen depChild_013 = 1 if (dag >= 0 & dag <= 13) & (idmother > 0 | idfather > 0) 

gen depChild_1418 = 1 if (dag >= 14 & dag <= 18) & (idmother > 0 | idfather > 0) 

bys swv idhh: egen dnc013 = sum(depChild_013)
bys swv idhh: egen dnc1418 = sum(depChild_1418)
drop depChild_013 depChild_1418

gen moecd_eq = . //Modified OECD equivalence scale
replace moecd_eq = 1.5 if dhhtp_c4 == 1
replace moecd_eq = 0.3*dnc013 + 0.5*dnc1418 + 1.5 if dhhtp_c4 == 2
replace moecd_eq = 1 if dhhtp_c4 == 3
replace moecd_eq = 0.3*dnc013 + 0.5*dnc1418 + 1 if dhhtp_c4 == 4

drop dnc013 dnc1418

/**************************** INCOME VARIABLES ********************************/
/*
A key difference here appears to be that income in EU-SILC is yearly, whereas 
USoc has monthly income. Further, net income is usually not recorded, so all 
figures are gross. Also the income information covers the previous calender year 
and therefore actually is more relevant for the previous year. 

Note that for wages there is an inconsistency. Details about the adjustment 
below. 

Generate individual income variables:
*/
/*************** GROSS PERSONAL NON-BENEFIT MONTHLY INCOME ********************/
/* 
UK version: egen ypnb = rowtotal(fimnlabgrs_dv fimnpen_dv fimnmisc_dv ///
	inc_stp inc_tu inc_ma); 
inc_stp, inc_tu and inc_ma generated at the beginning from income file

1 - fimnlabgrs_dv: 	total personal monthly labour income gross: employee 
						cash or near cash income (gross). 
						
DP: Note that in UKHLS the variable fimnlabgrs_dv  contains “labour income” 
(see here: https://www.understandingsociety.ac.uk/documentation/...
mainstage/variables/fihhmnlabgrs_dv/_) 
so my understanding is that self-employment income should also be included here. 
SILC also has a variable py020g – fringe benefits – currently not included here 
(neither inlcuded in the EUROMOD definition of original income)  

EU-SILC version: 

py010g py050g py020g
					
py010g :  	Employee cash or near cash income 
py050g :	Cash benefits or losses from self-employment 
py020g : 	Non-cash employee income [Omitted]

These variables correspond to a the previous calender year. 

2 - fimnpen_dv: 	Monthly amount of net pension income		

DP: The Usoc description says that this variable includes receipts reported in 
the income data file where w_ficode equals [2] pension from a previous employer,
or [3]  pension from a spouse’s previous employer.  
This is assumed to be reported net of tax. So in the UK these are occupational 
pensions.  
I think it is correct to use py080g in SILC as an equivalent. 
EU-SILC version: 

py080g 
												
py080g: 	Pension from individual	private	plans	

3 - fimnmisc_dv: 	monthly amount of net miscellaneous income

DP: The Usoc description says this includes receipts reported in the income data 
file where w_ficode equals 
-  educational grant (not student loan or tuition fee loan), 
-  payments from a family member not living here, or 
-  any other regular payment (not asked in Wave 1). This is assumed to be 
	reported net of tax. 

During our last discussion it became clear that this variable was meaning to 
approximate EUROMOD market income, which does not include scholarships 
(they are considered as benefits) ==> 
==> they have to be removed from the market income in the UK as well.   

4 -  "inc_stp" "inc_tu" "inc_ma" are generated in the UK  do-file called 
"01_prepare_ukhls_pooled_data" 
gen inc_stp = frmnthimp_dv if ficode == 1 (NI Retirement/State Retirement 
(Old Age) Pension) ==> the decision was not to include state pensions  

gen inc_tu = frmnthimp_dv if ficode == 25 (Trade Union / 
Friendly Society Payment)

gen inc_ma = frmnthimp_dv if ficode == 26 (Maintenance or Alimony)

EU SILC variables: 

hy080g hy081g hy110g hy040g hy090g

hy080g: 	Regular interhousehold cash transfer received
hy081g: 	Alimony and maintenance payments 
hy110g: 	Income received by people aged under 16
hy040g: 	Income frm rental of a property or land 
hy090g: 	Intrst, div, prof frm cptl inv in uncorp bsn

DP: Household level variables so should  be split equally among all adults. 
Could be attributed to individuals by splitting it among all eligible children 
in relation to child income.  (in EUROMOD these types of incomes are split 
between the oldest couple in the household). 
*/

* Household level variables are assigned to all adult hh members 
* ==> split them equally among all adults in hh
gen adult = (dag >= $age_become_responsible) //18 yo and over 
bysort stm idhh : egen n_adults = total(adult) 

lab var n_adults "Number of adults (18+) in hh" 

gen child = (dag < $age_become_responsible) //below 18 yo 
bysort stm idhh : egen n_child = total(child) 

lab var n_child "Number of children (<18) in hh" 

foreach var in hy080g hy110g hy040g hy090g {
	
	gen `var'_pc = `var'/n_adults
	replace `var'_pc = 0 if child == 1
	
} 

//order stm idhh dag hy080g hy110g hy040g hy090g hy080g_pc hy110g_pc ///
//	hy040g_pc hy090g_pc, last

egen ypnb_temp = rowtotal(py010g py050g py080g hy080g_pc hy110g_pc ///
	hy040g_pc hy090g_pc)
gen ypnb = ypnb_temp / 12

fre ypnb if ypnb < 0 
/* obs with negative income (due to negative self-employment income) but many of 
these are close to zero ==> recode them to zero */

* Impose non-negativity 
replace ypnb = 0 if  ypnb < 0 

sum ypnb 
assert ypnb >= 0 

sum ypnb if year == 2013
sum ypnb if year == 2016
sum ypnb if year == 2019
sum ypnb if year == 2023

* Check for missing values == if missing on all the components 
count if py010g >= . &  py050g >= . &  py080g >= . & hy080g >= . & ///
	hy110g >= . & hy040g >= . & hy090g >= . // 4,739 obs 
	
count if py010g >= . &  py050g >= . &  py080g >= . & hy080g >= . & ///
	hy110g >= . & hy040g >= . & hy090g >= .	& dag >= 16 // 4,010
	
tab year if py010g >= . &  py050g >= . &  py080g >= . & hy080g >= . & ///
	hy110g >= . & hy040g >= . & hy090g >= .	& dag >= 16	
/*	
All obs missing all income info are from 2006, which we do not use
therefore not a problem. 
*/	
count if (py010g >= . |  py050g >= . | py080g >= . | hy080g >= . | ///
	hy110g >= . | hy040g >= . | hy090g >= .) & dag >= 16 //   17,056

tab year  if (py010g >= . |  py050g >= . | py080g >= . | hy080g >= . | ///
	hy110g >= . | hy040g >= . | hy090g >= .) & dag >= 16 
/*
A quarter are from 2006, 10% from 2018. 
*/	
	
count if dag >= 16 // 332,907

/********** GROSS PERSONAL NON-EMPLOYMENT NON-BENEFIT MONTHLY INCOME **********/
/*
UK version:  egen yptc = rowtotal(fimnpen_dv fimnmisc_dv inc_stp inc_tu inc_ma)

EU SILC use the same variables as indicated above.  
*/

egen yptc = rowtotal(py080g hy080g_pc hy110g_pc hy040g_pc hy090g_pc)
replace yptc = yptc / 12

sum yptc
sum yptc if year == 2013
sum yptc if year == 2016
sum yptc if year == 2019
sum yptc if year == 2023

* Check for missing values == if missing on all the components 
count if py080g >= . & hy080g >= . & hy110g >= . & hy040g >= . & ///
	hy090g >= . // 4,739 obs with all missing elements  

count if (py080g >= . | hy080g >= . | hy110g >= . | hy040g >= . | ///
	hy090g >= .) & dag >= 16 
	//  17,055 adult obs with at least one missing element 
	
tab year if (py080g >= . | hy080g >= . | hy110g >= . | hy040g >= . | ///
	hy090g >= .) & dag >= 16 	
/*
A quarter are from 2006 
*/	

/***************** GROSS PERSONAL EMPLOYMENT MONTHLY INCOME *******************/
/*
UK version: gen yplgrs = fimnlabgrs_dv 
EU SILC version: As above. 
*/
egen yplgrs = rowtotal(py010g py050g)
replace yplgrs =  yplgrs/ 12

fre yplgrs if yplgrs < 0 // 494 obs

* Impose non-negativity
replace yplgrs = 0 if yplgrs < 0 

drop *_temp

* Check for missing values == if missing on all the components 
count if py010g >= . & py050g >= .  & dag >= 16 // 17,056  
count if (py010g >= . & py050g >= . ) & dag >= 16 & les_c3 == 1 
	//  2,837 employed adults missing information 
	
replace yplgrs = -9 if (py010g >= . & py050g >= . ) & dag >= 16 & les_c3 == 1

sum yplgrs
sum yplgrs if year == 2013
sum yplgrs if year == 2016
sum yplgrs if year == 2019
sum yplgrs if year == 2023

/************* SPOUSE GROSS PERSONAL NON-BENEFIT MONTHLY INCOME ***************/
preserve
keep swv idperson idhh ypnb
rename ypnb ypnbsp
rename idperson idpartner
save "$dir_data/temp_ypnb", replace
restore

merge m:1 swv idpartner idhh using "$dir_data/temp_ypnb"
keep if _merge == 1 | _merge == 3
drop _merge

/****************** HH/BEN UNIT GROSS NON-BENEFIT MONTHLY INCOME **************/
/* 
Couples = sum of partners incomes. Singles = own income 
*/ 
sum ypnb ypnbsp

egen yhhnb = rowtotal(ypnb ypnbsp) if dhhtp_c4 == 1 | dhhtp_c4 == 2 

replace yhhnb = ypnb if dhhtp_c4 == 3 | dhhtp_c4 == 4 

sum yhhnb
sum yhhnb if year == 2013
sum yhhnb if year == 2016
sum yhhnb if year == 2019
sum yhhnb if year == 2023

/************************************ CPI *************************************/
/* 
Harmonised index of consumer prices (HICP)
Annual data (annual average index) 2015=100
All-items HICP
Source dataset: Eurostat (prc_hicp_aind)	
Unit Index, base year = 100
Last data update: April 2025
https://ec.europa.eu/eurostat/databrowser/view/prc_hicp_aind__custom_16864932/default/table?lang=en
*/
gen CPI = .

replace CPI = 84.35  if stm == 2005
replace CPI = 87.14  if stm == 2006
replace CPI = 89.75  if stm == 2007
replace CPI = 93.55  if stm == 2008
replace CPI = 94.81  if stm == 2009
replace CPI = 99.27  if stm == 2010
replace CPI = 102.36 if stm == 2011
replace CPI = 103.42 if stm == 2012
replace CPI = 102.54 if stm == 2013
replace CPI = 101.11 if stm == 2014
replace CPI = 100    if stm == 2015
replace CPI = 100.02 if stm == 2016
replace CPI = 101.15 if stm == 2017
replace CPI = 101.94 if stm == 2018
replace CPI = 102.46 if stm == 2019
replace CPI = 101.17 if stm == 2020
replace CPI = 101.75 if stm == 2021
replace CPI = 111.21 if stm == 2022
replace CPI = 115.84 if stm == 2023

lab var CPI "HICP, all items, base 2015"

/************************ REAL MONTHLY GROSS INCOMES **************************/
* For household income, equivalise and adjust for inflation
replace yhhnb = (yhhnb/moecd_eq)/(CPI/100)

* Adjust for inflation:
replace ypnb = ypnb/(CPI/100)
replace yptc = yptc/(CPI/100)
replace yplgrs = yplgrs/(CPI/100) 
replace ypnbsp = ypnbsp/(CPI/100)

lab var ypnb "Gross monthy real personal non-benefit income " 
lab var yptc "Gross real monthly personal non-employment, non-benefit income"
lab var yplgrs "Gross monthly real personal employment income"
lab var ypnbsp "Spoues gross real monthly personal non-benefit income"

/************** INVERSE HYPERBOLIC SINE REAL MONTHLY GROSS INCOME *************/
/* 
This (monotonic) transformation is useful for data that exhibit highly skewed 
distributions, as it can help stabilize variance and normalise the 
distribution.
*/
gen yhhnb_asinh = asinh(yhhnb)
gen ypnbihs_dv = asinh(ypnb)
gen ypnbihs_dv_sp = asinh(ypnbsp)
gen yptciihs_dv = asinh(yptc)
gen yplgrs_dv = asinh(yplgrs)

replace yplgrs_dv = -9 if yplgrs_dv < 0 
	// to account for missing values in the raw data coded as -9 in yplgrs 
	// (626 real changes made)

lab var yhhnb_asinh "Gross real monthly household non-benefit income, ish"
lab var ypnbihs_dv 	"Gross real monthly personal non-benefit income, ihs"
lab var ypnbihs_dv_sp ///
	"Spoues gross real monthly personal non-benefit income, ihs"
lab var yptciihs_dv ///
	"Gross real monthly personal non-employment, non-benefit income, ihs"
lab var yplgrs_dv 	"Gross real monthly personal employment income, ihs"	
	
/*
sum ypnbihs_dv ypnbihs_dv_sp yptciihs_dv yplgrs_dv

    Variable |        Obs        Mean    Std. dev.       Min        Max
-------------+---------------------------------------------------------
  ypnbihs_dv |    465,476    3.141857    3.609443          0   12.47783
ypnbihs_dv~p |    247,208     3.87895    3.704686          0   12.47783
 yptciihs_dv |    465,476    1.022787     2.15214          0   9.601944
   yplgrs_dv |    465,476    2.434998    3.701341         -9   12.47502
*/ 

/*********** HOUSEHOLD GROSS NON-BENEFIT MONTHLY INCOME QUINTILES *************/
sum yhhnb_asinh

/*
    Variable |        Obs        Mean    Std. dev.       Min        Max
-------------+---------------------------------------------------------
 yhhnb_asinh |    465,476    3.630621    3.656069          0   12.07667

*/

/*
cap drop ydses*
forvalues stm=2005/2020 {
	xtile ydses_c5_`stm' = yhhnb_asinh if depChild != 1 & stm==`stm', nq(5)
	bys idhh: egen ydses_c5_tmp_`stm' = max(ydses_c5_`stm') if stm==`stm'
	replace ydses_c5_`stm' = ydses_c5_tmp_`stm' if missing(ydses_c5_`stm')
	drop ydses_c5_tmp_`stm'
} 

egen ydses_c5 = rowtotal(ydses_c5_2005 ydses_c5_2006 ydses_c5_2007 ///
	ydses_c5_2008 ydses_c5_2009 ydses_c5_2010 ydses_c5_2011 ydses_c5_2012 ///
	ydses_c5_2013 ydses_c5_2014 ydses_c5_2015 ydses_c5_2016 ydses_c5_2017 ///
	ydses_c5_2018 ydses_c5_2019 ydses_c5_2020)
recode ydses_c5 (0=-9) 
drop ydses_c5_2*
bys stm: fre ydses_c5
*/

/*
Problem: if many observations in yhhnb_asinh have exactly the same value, 
xtile would group them into a single quintile, causing one or more quintiles to 
have very few observations. 
This results in 2nd quintile being extremely small compared to the first 
quintile, which probably has many similar values 
Adding a very small random amount to yhhnb_asinh can help differentiate tied 
values enough to distribute them more evenly across quintiles without distorting 
the data meaningfully.
*/

gen yhhnb_asinh_jittered = yhhnb_asinh + runiform() * 1e-5

cap drop ydses*
forvalues stm = 2006/2023 {
	
	xtile ydses_c5_`stm' = yhhnb_asinh_jittered if depChild != 1 & ///
		stm == `stm', nq(5)
	bys idhh: egen ydses_c5_tmp_`stm' = max(ydses_c5_`stm') if stm == `stm'
	replace ydses_c5_`stm' = ydses_c5_tmp_`stm' if missing(ydses_c5_`stm')
	drop ydses_c5_tmp_`stm'
	
} 

egen ydses_c5 = rowtotal(ydses_c5_2006 ydses_c5_2007 ///
	ydses_c5_2008 ydses_c5_2009 ydses_c5_2010 ydses_c5_2011 ydses_c5_2012 ///
	ydses_c5_2013 ydses_c5_2014 ydses_c5_2015 ydses_c5_2016 ///
	ydses_c5_2017 ydses_c5_2018 ydses_c5_2019 ydses_c5_2020 ydses_c5_2021 ///
	ydses_c5_2022 ydses_c5_2023)
recode ydses_c5 (0 = -9) 
drop ydses_c5_2*
bys stm: fre ydses_c5

lab var ydses_c5 "Gross real monthly household non-benefit income quintiles"

/********** COUPLE DIFFERENCE IN GROSS PERSONAL NON-BENEFIT INCOME ************/
gen ynbcpdf_dv = ypnbihs_dv - ypnbihs_dv_sp
recode ynbcpdf_dv (. = -999) if idpartner < 0
recode ynbcpdf_dv (. = -999) 
sum ynbcpdf_dv 

lab var ynbcpdf_dv 	///
"Difference between own and spouse's gross personal non-benefit income, asinh"

/****************************** GROSS NET RATIO  ******************************/
/* 
There are no net incomes in EU-SILC, will be computed using EUROMOD anyway
*/  
gen gross_net_ratio = 1 

/******************** GROSS PERSONAL CAPITAL INCOME ***************************/
/* 
UK version:  
gen ypncp = ///
	asinh((fimninvnet_dv+fimnmisc_dv+fimnprben_dv)*gross_net_ratio*(1/CPI)) 
	
1 - fimninvnet_dv: 	Investment income

2 -  fimnmisc_dv: 	Net miscellaneous income. Educational grant 
					(not student loan or tuition fee loan), payments from a 
					family member not living here, or any other regular payment 
					(not asked in Wave 1).
					
3 -  fimnprben_dv: 	Net private benefit income. Trade union/friendly society 
					payment, maintenance or alimony, or sickness and accident
					insurance.  

EU SILC version see above. 					
*/
egen ypncp_temp = rowtotal(hy080g_pc hy110g_pc hy040g_pc hy090g_pc)
gen ypncp = ypncp_temp / 12
replace ypncp = asinh(ypncp*(1/CPI)) 

lab var ypncp "Gross real monthly personal non-employment capital income, asinh"

sum ypncp
sum ypncp if year == 2013
sum ypncp if year == 2016
sum ypncp if year == 2019
sum ypncp if year == 2023

* Check for missing values == if missing on all the components 
count if hy080g >= . & hy110g >= . &  hy040g >= . &  hy090g >= . //  4,739
count if hy080g >= . | hy110g >= . |  hy040g >= . |  hy090g >= . 
	//   4,739 obs have some missing capital income information 
count if hy080g >= . & hy110g >= . &  hy040g >= . &  hy090g >= . & year > 2010 
	// 0 obs 
count if (hy080g >= . | hy110g >= . |  hy040g >= . |  hy090g >= .) & year > 2010
	// 0 obs

/************************* PRIVATE PENSION INCOME *****************************/
/*
UK version: 
fimnpen_dv:	 Monthly amount of net pension income	

Eu SILC version 
py080g: 	Pension from individual private plans (gross) 
*/
gen ypnoab_lvl = (py080g/12)*(1/CPI)
recode ypnoab_lvl (. = 0) 
gen ypnoab = asinh(ypnoab_lvl)

lab var ypnoab "Gross real monthly personal private pension income"

sum ypnoab
sum ypnoab if year == 2013
sum ypnoab if year == 2016
sum ypnoab if year == 2019
sum ypnoab if year == 2023

count if py080g >= . & dag >= 16 & year > 2010 //  13,965 obs

* Final check there are no missing values in income vars 
drop if year == 2004 

foreach var in ydses_c5 ypnbihs_dv yptciihs_dv yplgrs_dv ynbcpdf_dv ///
	ypncp ypnoab {
	
	assert `var' != . 
	
} 

// very few positive private pensioon amounts

/***************************** HOME OWNERSHIP *********************************/
/* 
Dhh_owned is the definition used in the initial population and in the model 
predicting house ownership in the homeownership process of the simulation. 
*/
// bys swv: fre hh021
gen dhh_owned = 0 
replace dhh_owned = 1 if hh021 == 1 | hh021 == 2 | hh020 == 1 

lab var dhh_owned "Home ownership dummy"

fre dhh_owned
tab dhh_owned year, col 

/**************************** DISABILITY BENEFIT ******************************/
/* 
In EU-SILC, the variables 
- py130n: 	(disability benefits net), 
- py130g: 	(disability benefits gross), 
- py131g: 	(contributory and means-tested), 
- py132g: 	(contributory and non means-tested), 
- py133g: 	(non-contributory and means-tested), 
- py134g: 	(non-contributory and non means-tested) 

All may contain information on disability benefits. 

For ITngary, py130g is better recorded than py130n, and py132g & py134g also 
contain information, whereas py131g and py133g only have missings. 

The code below may well be IT specific as some of the coding of these variables 
changes between countries. 
I expect that there is probably a better/more efficient way of constructing this 
code.
*/
recode py130n (0 = -9)(. = -9), gen(py130nr)
recode py130g (0 = -9)(. = -9), gen(py130gr)
recode py132g (0 = -9)(. = -9), gen(py132gr)
recode py134g (0 = -9)(. = -9), gen(py134gr)

gen bdi = 0
replace bdi = 1 if py130gr >= 1 | py130gr >= 1 | py132gr >= 1 | py134gr >= 1 
lab val bdi dummy

lab var bdi "Disability benefits (dummy)"

drop py130nr py130gr py132gr py134gr

fre bdi
tab bdi year, col 

/************************* LAGGED HOURLY LABOUR INCOME ************************/
/*
There are data issues here: 
	- Data is collected at the annual level 
	- The annual information corresponds to the previous calender year 
	- Income from self-employment can be negative 
	
Have decided on the following: 

wage_hr 	= Annual employemnt income / Annual # hours worked 
			= Annual employemnt income / (# months worked * # hours worked ...
											a week * 4.33)										
	
Data year:	T-1		T 		T+1
Hrs:		T-1		T		T+1
Income:		T-2		T-1		T
# month: 	T-2		T-1		T

# Months worked last year can be constructed using the PL211* variables 

PY211A - Main activity January 

1	Employee working full-time	
2	Employee working part-time	
3	Self-employed working full-time (including family worker)	
4	Self-employed working part-time (including family worker)	
5	Unemployed	
6	Student, pupil	
7	Retired	
8	Unable to work due to long-standing health problems	
10	Fulfilling domestic tasks	
11	Other


=> Create a measure of hourly wages for year T using hour info from yr T 
and wage info and number of months worked info from T+1
*/

xtset idperson swv
sort idperson swv 

* Create monthly income for T-1 
* Annual gross real labour income in T-1
egen yplgrs_annual = rowtotal(py010g py050g)

replace yplgrs_annual = 0 if yplgrs_annual < 0

* Turn into real gross labour income 
replace yplgrs_annual = yplgrs_annual/(l.CPI/100)

* Months worked in T-1
// do not account for ft or pt here
foreach month in a b c d e f g h i j k l {
	
	gen wrk_`month' = (inrange(pl211`month',1,4))
	replace wrk_`month' = . if pl211`month' == . 
	
}

egen months_wrk = rowtotal(wrk_a wrk_b wrk_c wrk_d wrk_e wrk_f wrk_g wrk_h ///
	wrk_i wrk_j wrk_k wrk_l) // treats missing as 0
	
egen months_wrk_missing = rowmiss(wrk_a wrk_b wrk_c wrk_d wrk_e wrk_f wrk_g ///
	wrk_h wrk_i wrk_j wrk_k wrk_l)	
	
tab months_wrk_missing 
/*
 almost all observations that report monthly info, have info for the whole yr
*/
tab months_wrk if months_wrk_missing == 0 & yplgrs_annual != 0 
/*
 6,440 say they worked no months last year and yet have labour income 
 mainly self-employed income so distribute across the year 
*/

sum months_wrk if months_wrk_missing == 0 & les_c3 == 1 
// mean 11.44 months worked on average across workers
count if yplgrs_annual > 0 & months_wrk_missing != 0 // 39,879
/*
 => many missing values 
 => assume those with missing values work for 12 months in the previous 
		calender year and that those with missing month observations were 
		working in those months	
		
wage information missing if don't work any hours 		
*/
 	
* Monthly gross real labour income T-1	
gen yplgrs_mnth = yplgrs_annual / months_wrk if months_wrk_missing == 0 

* Missing values 
/*
If missing some months assume not working those months
*/
replace yplgrs_mnth = yplgrs_annual / months_wrk if ///
	inrange(months_wrk_missing,1,11)

/*
If missing all monthly information assume the mode number of work months 
*/
tab months_wrk if months_wrk_missing == 0 & les_c3 == 1
replace yplgrs_mnth = yplgrs_annual / 12 if months_wrk_missing == 12 

/*
If have annual income and report working zero months assume the mode number of 
work months. Note this income is mainly solely from self employed income 
*/
replace yplgrs_mnth = yplgrs_annual / 12 if months_wrk == 0 

* Check 
sum yplgrs_mnth 
sum yplgrs
sum yplgrs if yplgrs_mnth != .

bys stm: sum yplgrs_mnth

sort idperson swv 

gen obs_earnings_hourly = .
gen l1_obs_earnings_hourly = .

replace obs_earnings_hourly = f.yplgrs_mnth/(lhw*4.33) if les_c4 == 1

replace l1_obs_earnings_hourly = l.obs_earnings_hourly

lab var obs_earnings_hourly ///
	"Observed hourly wages, emp and self-emp, adjusted for timing"
lab var l1_obs_earnings_hourly ///
	"Observed hourly wages, emp and self-emp, t-1, adjusted for timing"

* Impose non-negativity 
replace obs_earnings_hourly = 0 if obs_earnings_hourly < 0 
replace l1_obs_earnings_hourly = 0 if l1_obs_earnings_hourly < 0 

replace obs_earnings_hourly = -9 if obs_earnings_hourly == .  
replace l1_obs_earnings_hourly = -9 if l1_obs_earnings_hourly == . 

sum obs_earnings_hourly if les_c3 == 1 & obs != -9 

/***************** WAS IN INITIAL EDUCATION SPELL SAMPLE **********************/
/* 
Consists of those bserved in education in all preceding periods t-1,t-2,t-n, 
where n is the number of observations of a particular individual we have.
1 includes first instance of not being in education.
*/
sort idperson swv 
gen sedcsmpl = 0
replace sedcsmpl = 1 if (dag >= 16 & dag <= 29) & l.ded == 1 

lab var sedcsmpl "SYSTEM: Continuous education sample"
lab def sedcsmpl  1 "Aged 16-29 and were in continuous education"	
lab val sedcsmpl sedcsmpl

/********************** RETURN TO EDUCATION SAMPLE ****************************/
/*
Consists of those who have left their initial education spell and are age
18-35? 
*/
gen sedrsmpl = 0 
replace sedrsmpl = 1 if (dag >= 16 & dag <= 35 & ded == 0) 

lab var sedrsmpl "SYSTEM : Return to education sample"
lab def  sedrsmpl  1 "Aged 16-35 and not in continuous education"
lab val sedrsmpl sedrsmpl

/******************* IN INITIAL EDUCATION SPELL SAMPLE ************************/
/* 
Generated from sedcsmpl and ded variables. Sample: Respondents who were in 
initial education spell and left it. 
*/
//fre ded
gen scedsmpl = 0 
replace scedsmpl = 1 if sedcsmpl == 1 & ded == 0 

lab var scedsmpl "SYSTEM : Not in continuous education sample"
lab def scedsmpl  1 "Left continuous education"
lab val scedsmpl scedsmpl

/***************************** WEIGHTS ****************************************/
/*
Clare's notes: 
The EU-SILC panel contains a series of weights to ensure the sample is 
representative. 
The documentation (Eurostat, 2015) and Verma (2006) discuss how these weights 
are calculated. 
Unfortunately, for this cumulative longitudinal dataset created by GESIS, the 
original weights are no longer appropriate. 
However, GESIS discusses how to rescale two of the weights (RB060: individual 
base weight & RB064: individual longitudinal weight)

1. RB060, the so-called "modified base-weight". 
Each observation in the EU-SILC data set (R file) comes with this weight. 
In the first year of observation it equals the design weight, calibrated and 
In the first year of observation it equals the design weight, calibrated and 
modified to take non-responses into account. The base-weight of the years that 
follow is given by the previous year's base-weight adjusted for non-response 
rates.

2. RB064, the longitudinal weights.  
Created to be used with datasets made up of one rotational group covering four 
years (within a given release). 
They are built with the intent of making sure that this sub-sample is 
representative of the longitudinal population of the year in which the 
rotational group had been surveyed for the first time. 
RB064 is reported only during the last year of a rotational group covering four 
years. It is constant with respect to the year of observation, but varies across 
individuals. 
Since both weights are built based on single rotational groups, they can be used 
to calculate weights for a larger, cumulative sample. 

RB060 can be simply rescaled. The same goes for RB064, but in this case, one 
must restrict the merged sample to rotational groups that cover 4 years, which 
leads to loss of data. 
Also, RB064 makes sure that the sample is representative with respect to the 
longitudinal population of the year in which the rotational group was first 
surveyed. 
This means that the final result becomes something resembling a "moving sample", 
a set of sub-samples representative of different longitudinal populations. 
In practice, even though RB064 and RB060 take on very different values in some 
cases, on average, the difference is not much.

More information on the rescaling of rb060 and rb064 can be found in the GESIS 
documentation (Marwin Borst & Heike Wirth, EU-SILC Tools: eusilcpanel_2020 
First computational steps towards a cumulative sample based on the EU-SILC 
longitudinal datasets - update. GESIS Papers 2022|10)
*/

/*
DP: We decided to use Individual Cross-sectional Weight rescaled weight, RB060, 
for the initial populations. As can be seen below the popuatlion numbers closely
align with the totals of the resclaed RB060 but not with the rescaled RB062. 
For the regression estimates ==> either RB060 or RB062 or RB064 can be used, or 
no weights at all. 
*/

/* 
Weights available in the original cross-sectional EU-SILC data: 

- RB050: 	Personal cross-sectional weight (from individual roster)
			==> all current household members (of any age)
- DB090:    Household cross-sectional weight 
			==> the final estimation weights. Only the households that are 
			accepted into the database (DB135 = 1) have a cross-sectional 
			weight; the others are assigned a weight of 0. 
			
The calibration is done taking all rotational groups together. [...] (Eurostat 
(2023): Methodological Guidelines and Description of EU-SILC Target Variables. 
2022 operation (Version 7), p. 108).

Weights available in the original longitudinal EU-SILC data: 

- RB060:	 Personal base weight
- RB062:	 Longitudinal weight (two-year duration)
- RB063:	 Longitudinal weight (three-year duration)
- RB064:	 Longitudinal weight (four-year duration)
- DB095:	 Household longitudinal weight
*/ 

/*
Total population figures for Greece from 2011 to 2021 (EUROSTAT demo_gind):

Year	Total Population
2005	10,987,314
2006	11,020,362	
2007	11,048,473	
2008	11,077,841	
2009	11,107,017	
2010	11,121,341	
2011	11,104,899	
2012	11,045,011	
2013	10,965,211	
2014	10,892,413	
2015	10,820,883	
2016	10,775,971	
2017	10,754,679
2018	10,732,882
2019	10,721,582	
2020	10,698,599	
2021	10,569,207	
2022	10,436,882	
2023	10,407,351
*/

* EUROMOD weight based on DB090, sums up to the population of EL, see below: 
/*	

*/

/* 
RB060 - Individual Cross-sectional Weight 

The RB060 weight is referred to as the "modified base-weight" in EU-SILC. It is 
designed to ensure that observations are representative of the sample for a 
specific year and country. 

1/ In the first year of observation, RB060 is equivalent to the design weight. 
This design weight is calibrated and adjusted for non-response rates.
2/ In the following years, RB060 is adjusted based on non-response rates in the 
subsequent waves of the survey. This ensures that the weight reflects the 
participation of individuals over time.
3/ Rescaling Process: When combining multiple waves or rotational groups 
(which cover multiple years), you need to rescale RB060 by multiplying it by a 
scaling factor (rscale) that accounts for the relative size of each rotational 
group compared to the total sample. This helps maintain proportionality across t
he cumulative dataset.

The steps for rescaling RB060:
1. Sort data by rotation group and year 
2. Calculate the sum of RB060 for each rotation group within each year
3. Calculate the total RB060 for each year 
4. Rescale the RB060 weights

This scaling ensures that each rotation group contributes appropriately to the 
overall sample, and helps prevent over-representation or under-representation of
specific groups.

DB075 - Rotation Group  
"This variable must be filled only for the countries using a rotational design.
Rotational design: Refers to any sample selection which is based on a fixed 
number of sub-samples, called replications, each one representative of the 
target population at the time of their selection. 
Each year, one sub-sample rotates out and a new one is drawn as a substitute. 
In the case of a rotational design based on four replications with a rotation of
one replication per year, one of the replications must be dropped immediately 
after the first year, the second must be retained for 2 years, the third for 3 
years, and the fourth for 4 years. 
From the second year onwards, at the start of each new year one replication must 
be introduced and retained for 4 years.
Rotation group: Each replication is called a rotational group and the 
information on the group to which the household belongs is especially useful for
controlling the implementation of the sample over time. 
Regarding the numbering of the rotation groups over time, it is recommended that 
each rotation group keeps the same number throughout the period of the survey." 
[...] (Eurostat (2023): Methodological Guidelines and Description of EU-SILC 
Target Variables. 2022 operation (Version 7), p. 105).
					
 bysort stm: tab db075

----------------------------------------------------------------------------------------------------------------------------------
-> stm = 2006

 Rotational |
      group |      Freq.     Percent        Cum.
------------+-----------------------------------
          3 |      4,739      100.00      100.00
------------+-----------------------------------
      Total |      4,739      100.00

----------------------------------------------------------------------------------------------------------------------------------
-> stm = 2007

 Rotational |
      group |      Freq.     Percent        Cum.
------------+-----------------------------------
          3 |      4,221       49.99       49.99
          4 |      4,223       50.01      100.00
------------+-----------------------------------
      Total |      8,444      100.00

----------------------------------------------------------------------------------------------------------------------------------
-> stm = 2008

 Rotational |
      group |      Freq.     Percent        Cum.
------------+-----------------------------------
          1 |      6,397       45.60       45.60
          3 |      3,885       27.69       73.29
          4 |      3,748       26.71      100.00
------------+-----------------------------------
      Total |     14,030      100.00

----------------------------------------------------------------------------------------------------------------------------------
-> stm = 2009

 Rotational |
      group |      Freq.     Percent        Cum.
------------+-----------------------------------
          1 |      5,611       30.72       30.72
          2 |      5,865       32.11       62.84
          3 |      3,510       19.22       82.06
          4 |      3,277       17.94      100.00
------------+-----------------------------------
      Total |     18,263      100.00

----------------------------------------------------------------------------------------------------------------------------------
-> stm = 2010

 Rotational |
      group |      Freq.     Percent        Cum.
------------+-----------------------------------
          1 |      4,907       27.50       27.50
          2 |      5,225       29.28       56.77
          3 |      4,692       26.29       83.07
          4 |      3,022       16.93      100.00
------------+-----------------------------------
      Total |     17,846      100.00

----------------------------------------------------------------------------------------------------------------------------------
-> stm = 2011

 Rotational |
      group |      Freq.     Percent        Cum.
------------+-----------------------------------
          1 |      3,888       25.24       25.24
          2 |      4,112       26.69       51.93
          3 |      3,621       23.50       75.43
          4 |      3,785       24.57      100.00
------------+-----------------------------------
      Total |     15,406      100.00

----------------------------------------------------------------------------------------------------------------------------------
-> stm = 2012

 Rotational |
      group |      Freq.     Percent        Cum.
------------+-----------------------------------
          1 |      3,932       28.60       28.60
          2 |      3,520       25.60       54.20
          3 |      3,067       22.31       76.51
          4 |      3,229       23.49      100.00
------------+-----------------------------------
      Total |     13,748      100.00

----------------------------------------------------------------------------------------------------------------------------------
-> stm = 2013

 Rotational |
      group |      Freq.     Percent        Cum.
------------+-----------------------------------
          1 |      3,817       21.18       21.18
          2 |      7,976       44.27       65.45
          3 |      3,057       16.97       82.42
          4 |      3,168       17.58      100.00
------------+-----------------------------------
      Total |     18,018      100.00

----------------------------------------------------------------------------------------------------------------------------------
-> stm = 2014

 Rotational |
      group |      Freq.     Percent        Cum.
------------+-----------------------------------
          1 |      3,415       16.16       16.16
          2 |      7,220       34.16       50.32
          3 |      7,704       36.45       86.77
          4 |      2,797       13.23      100.00
------------+-----------------------------------
      Total |     21,136      100.00

----------------------------------------------------------------------------------------------------------------------------------
-> stm = 2015

 Rotational |
      group |      Freq.     Percent        Cum.
------------+-----------------------------------
          1 |      3,041        8.77        8.77
          2 |      6,462       18.64       27.41
          3 |      7,045       20.32       47.73
          4 |     18,124       52.27      100.00
------------+-----------------------------------
      Total |     34,672      100.00

----------------------------------------------------------------------------------------------------------------------------------
-> stm = 2016

 Rotational |
      group |      Freq.     Percent        Cum.
------------+-----------------------------------
          1 |     17,301       38.81       38.81
          2 |      5,392       12.10       50.91
          3 |      5,962       13.38       64.28
          4 |     15,920       35.72      100.00
------------+-----------------------------------
      Total |     44,575      100.00

----------------------------------------------------------------------------------------------------------------------------------
-> stm = 2017

 Rotational |
      group |      Freq.     Percent        Cum.
------------+-----------------------------------
          1 |     17,201       31.45       31.45
          2 |     16,253       29.72       61.17
          3 |      5,770       10.55       71.72
          4 |     15,470       28.28      100.00
------------+-----------------------------------
      Total |     54,694      100.00

----------------------------------------------------------------------------------------------------------------------------------
-> stm = 2018

 Rotational |
      group |      Freq.     Percent        Cum.
------------+-----------------------------------
          1 |     15,272       26.49       26.49
          2 |     13,441       23.31       49.80
          3 |     15,307       26.55       76.34
          4 |     13,642       23.66      100.00
------------+-----------------------------------
      Total |     57,662      100.00

----------------------------------------------------------------------------------------------------------------------------------
-> stm = 2019

 Rotational |
      group |      Freq.     Percent        Cum.
------------+-----------------------------------
          1 |     11,710       28.93       28.93
          2 |     10,788       26.66       55.59
          3 |     12,241       30.25       85.84
          4 |      5,732       14.16      100.00
------------+-----------------------------------
      Total |     40,471      100.00

----------------------------------------------------------------------------------------------------------------------------------
-> stm = 2020

 Rotational |
      group |      Freq.     Percent        Cum.
------------+-----------------------------------
          1 |      6,608       19.69       19.69
          2 |     10,194       30.37       50.06
          3 |     11,392       33.94       84.01
          4 |      5,368       15.99      100.00
------------+-----------------------------------
      Total |     33,562      100.00

----------------------------------------------------------------------------------------------------------------------------------
-> stm = 2021

 Rotational |
      group |      Freq.     Percent        Cum.
------------+-----------------------------------
          1 |      6,616       23.56       23.56
          2 |      5,141       18.31       41.87
          3 |     11,099       39.53       81.40
          4 |      5,224       18.60      100.00
------------+-----------------------------------
      Total |     28,080      100.00

----------------------------------------------------------------------------------------------------------------------------------
-> stm = 2022

 Rotational |
      group |      Freq.     Percent        Cum.
------------+-----------------------------------
          1 |      6,511       28.72       28.72
          2 |      5,136       22.66       51.38
          3 |      5,886       25.97       77.35
          4 |      5,134       22.65      100.00
------------+-----------------------------------
      Total |     22,667      100.00

----------------------------------------------------------------------------------------------------------------------------------
-> stm = 2023

 Rotational |
      group |      Freq.     Percent        Cum.
------------+-----------------------------------
          1 |      6,412       36.72       36.72
          2 |      5,100       29.20       65.92
          3 |      5,951       34.08      100.00
------------+-----------------------------------
      Total |     17,463      100.00



*/

* Distribution of RB060 before rescaling  
preserve 
collapse (sum) rb060, by(stm)
format rb060 %15.0f
list stm rb060
restore 
/*		
     +-----------------+
     |  stm      rb060 |
     |-----------------|
  1. | 2006   10764222 |
  2. | 2007   21450345 |
  3. | 2008   31602054 |
  4. | 2009   41758695 |
  5. | 2010   41860585 |
     |-----------------|
  6. | 2011   41315472 |
  7. | 2012   40396624 |
  8. | 2013   40362447 |
  9. | 2014   41247865 |
 10. | 2015   41604908 |
     |-----------------|
 11. | 2016   41808511 |
 12. | 2017   41440068 |
 13. | 2018   40944956 |
 14. | 2019   39046817 |
 15. | 2020   39024994 |
     |-----------------|
 16. | 2021   40014381 |
 17. | 2022   40694861 |
 18. | 2023   30363655 |
     +-----------------+

*/

* Rescaling RB060
order stm db075 rb060, last
sort stm db075

bys stm db075: egen total_group_rb060 = total(rb060)
bys stm: egen total_rb060 = total(rb060)

cap drop rscale
gen rscale = total_group_rb060/total_rb060
//replace rscale  = rscale/2 if stm == 2011 & db075 == 2 
/*
!!! bug in db075 in 2011 - as can be seen above, two rotational groups have the 
same id so need to adjust the rescaling factor 
*/

tab rscale 

bys stm db075: sum rscale 

gen dimxwt = rb060 * rscale 
lab var dimxwt ///
	"DEMOGRAPHIC : Individual Cross-sectional Weight based on rb060, rescaled "	

* Distribution after rescaling 
preserve 
collapse (sum) dimxwt, by(stm)
format dimxwt %15.0f
list stm dimxwt
restore 

/*			
     +-----------------+
     |  stm     dimxwt |
     |-----------------|
  1. | 2006   10764222 |
  2. | 2007   10725825 |
  3. | 2008   10539173 |
  4. | 2009   10454717 |
  5. | 2010   10485817 |
     |-----------------|
  6. | 2011   10344273 |
  7. | 2012   10131141 |
  8. | 2013   10142061 |
  9. | 2014   10342759 |
 10. | 2015   10415951 |
     |-----------------|
 11. | 2016   10457623 |
 12. | 2017   10366940 |
 13. | 2018   10247334 |
 14. | 2019    9783382 |
 15. | 2020    9793113 |
     |-----------------|
 16. | 2021   10033116 |
 17. | 2022   10180520 |
 18. | 2023   10122271 |
     +-----------------+
*/

* Household Cross-sectional Weight	
/*
Cross-sectional household weight created by combining individual rescaled 
cross-sectional weights 
*/
gen one = 1 
bysort stm idhh: egen hhsize = total(one)

cap drop dhhwt
bysort stm idhh: egen dhhwt = total(dimxwt)
replace dhhwt = dhhwt/hhsize
lab var dhhwt "DEMOGRAPHIC : Household Cross-sectional Weight based on rb060"

* Distribution 
preserve 
collapse (sum) dhhwt, by(stm)
format dhhwt %15.0f
list stm dhhwt
restore 
/*
     +-----------------+
     |  stm      dhhwt |
     |-----------------|
  1. | 2006   10764222 |
  2. | 2007   10725825 |
  3. | 2008   10539173 |
  4. | 2009   10454717 |
  5. | 2010   10485817 |
     |-----------------|
  6. | 2011   10344273 |
  7. | 2012   10131141 |
  8. | 2013   10142061 |
  9. | 2014   10342759 |
 10. | 2015   10415951 |
     |-----------------|
 11. | 2016   10457623 |
 12. | 2017   10366940 |
 13. | 2018   10247334 |
 14. | 2019    9783382 |
 15. | 2020    9793113 |
     |-----------------|
 16. | 2021   10033116 |
 17. | 2022   10180520 |
 18. | 2023   10122271 |
     +-----------------+

*/		

* Cross-sectional Grossing Up Weight
gen dwt = dimxwt 
lab var dwt "DEMOGRAPHIC : Grossing-up Weight"

* Individual Longitudinal Weight RB064
/*
The GESIS documentation paper suggests how to rescale RB064 
(four-year duration weight) : 
The same rescaling logic applies to RB064 with a minor tweak: RB064 is
reported only in the last year of panel covering four years. So, the first step 
is to copy RB064 to all years of all rotational groups that come with RB064. 
Second, analysts should drop all observations with RB064s missing to make sure 
that only rotational groups covering four years are in the sample.

Since we estimate models with one lag max I tried to use RB062 
(two-year duration weight) instead of RB064
*/
count if rb062 < . 

* Copy rb062 to all years of the rotational group
cap drop rb062_imputed
bys idperson db075 (stm): gen rb062_imputed  = rb062[_N] if missing(rb062)
replace rb062_imputed = rb062 if !missing(rb062) & missing(rb062_imputed)

* Compute rescaling factor 
cap drop total_rb062_group total_rb062
bys stm db075: egen total_rb062_group = total(rb062_imputed)
bys stm: egen total_rb062 = total(rb062_imputed)

cap drop rscale 
gen rscale = total_rb062_group / total_rb062
fre rscale 

* Rescale as in rb060
cap drop dimlwt
gen dimlwt = rb062_imputed *rscale  

lab var dimlwt "DEMOGRAPHIC : Individual Longitudinal Weight  based on rb062"	

* Distribution after rescaling
preserve 
collapse (sum) dimlwt, by(stm)
format dimlwt %15.0f
list stm dimlwt
restore 

/*	
     +----------------+
     |  stm    dimlwt |
     |----------------|
  1. | 2006   3296214 |
  2. | 2007   3264354 |
  3. | 2008   3293385 |
  4. | 2009   3313302 |
  5. | 2010   3246550 |
     |----------------|
  6. | 2011   3224403 |
  7. | 2012   3215102 |
  8. | 2013   3233004 |
  9. | 2014   3294472 |
 10. | 2015   3372222 |
     |----------------|
 11. | 2016   3335852 |
 12. | 2017   3246365 |
 13. | 2018   3185301 |
 14. | 2019   3124753 |
 15. | 2020   3160228 |
     |----------------|
 16. | 2021   3253606 |
 17. | 2022   3337751 |
 18. | 2023   3369633 |
     +----------------+

Using the rescaled longitudinal weight did not work => use the rescaled base 
weight
*/

/*************************** CONSISTENCY CHECKS *******************************/
* Economic activity 
tab les_c3 les_c4 
count if les_c3 == . 
count if les_c4 == . 

tab les_c3 ded
tab les_c4 ded

tab les_c3 der
tab les_c4 der

sum lhw if les_c3 == 1
sum lhw if les_c3 != 1
sum lhw if les_c4 == 1
sum lhw if les_c4 != 1

tab les_c3 dlltsd
tab les_c4 dlltsd

tab les_c3 dlrtrd
tab les_c4 dlrtrd

tab les_c3 sedex
tab les_c4 sedex

tab les_c3 unemp 
tab les_c4 unemp 

sum obs_earnings_hourly if les_c3 == 1 
sum obs_earnings_hourly if les_c3 != 1
sum obs_earnings_hourly if les_c4 == 1 
sum obs_earnings_hourly if les_c4 != 1

* Partnership 
tab dun dcpst

gen temp_idp_pop = (idpartner> -9)

tab dun temp_idp_pop 
tab dcpst temp_idp_pop 

/*************************** KEEP RELEVANT WAVES ******************************/
/* 
Initial populations: cross-sectional SILC for 2011-2023 
Estimation sample: longitudinal SILC with observations from 2011-2023 
 (income 2010-2022) 
*/
keep if swv >= 2010

save "$dir_data/02_pre_drop_${country}.dta", replace

/**************************** SENSE CHECK PLOTS *******************************/

//do "$dir_do/02_01_checks"

graph drop _all 

/*************************** KEEP REQUIRED VARIABLES **************************/
keep idhh idperson idpartner idfather idmother dct drgn1 dnc02 dnc dgn dgnsp ///
	dag dagsq dhe dhesp dcpst ded deh_c3 der dehsp_c3 dehm_c3 dehf_c3 ///
	dehmf_c3 dcpen dcpyy dcpex dcpagdf dlltsd dlrtrd drtren dlftphm ///
	dhhtp_c4 dimlwt dimxwt dhhwt dwt les_c3 les_c4 lessp_c3 lessp_c4 ///
	lesdf_c4 ydses_c5 ypnbihs_dv yptciihs_dv yplgrs_dv ynbcpdf_dv ypncp ///
	ypnoab swv sedex ssscp sprfm sedag stm dagsp lhw der adultchildflag ///
	sedcsmpl sedrsmpl scedsmpl dhh_owned dukfr dchpd dagpns dagpns_sp ///
	CPI lesnr_c2 dlltsd_sp ypnoab_lvl *_flag Int_Date unemp yplgrs liwwh ///
	dagpns_y dagpns_y1 dagpns_y_sp dagpns_y1_sp obs_earnings_hourly ///
	l1_obs_earnings_hourly l1_les_c3 l1_les_c4 new_rel dcpyy_st new_rel ///
	dcpyy_st dhhtp_c8 

sort swv idhh idperson 

/************************* RECODE MISSING VALUES ******************************/
foreach var in idhh idperson idpartner idfather idmother dct drgn1 dnc02 ///
	dnc dgn dgnsp dag dagsq dhe dhesp dcpst ded deh_c3 der dehsp_c3 ///
	dehm_c3 dehf_c3 dehmf_c3 dcpen dcpyy dcpex dlltsd dlrtrd drtren ///
	dlftphm dhhtp_c4 les_c3 les_c4 lessp_c3 lessp_c4 lesdf_c4 ydses_c5 ///
	swv sedex ssscp sprfm sedag stm dagsp lhw der dhh_owned ///
	dchpd dagpns dagpns_sp CPI lesnr_c2 dlltsd_sp *_flag unemp liwwh ///
	dagpns_y dagpns_y1 dagpns_y_sp dagpns_y1_sp obs_earnings_hourly ///
	l1_obs_earnings_hourly l1_les_c3 l1_les_c4 new_rel dcpyy_st new_rel ///
	dcpyy_st dhhtp_c8 {
	
		qui recode `var' (-9/-1 = -9) (. = -9) 

}

* Recode missings in weights to zero 
foreach var in dimlwt dimxwt dhhwt dwt {
	
	qui recode `var' (. = 0) (-9/-1 = 0) 
	sum `var' if `var' < 0 
	
} 
	
* Initialise wealth to missing 
gen liquid_wealth = -9
gen smp = -9
gen rnk = -9
gen mtc = -9

* Check for duplicates in the pooled dataset 
duplicates tag idperson idhh swv, gen(dup)
fre dup
drop if dup == 1 // 0 duplicates 
drop dup
isid idperson idhh swv	

* Check create same dataset each time 
/*
Only differences should come from stochastic imputation variables 
*/
sort idperson swv 

//cf _all using ${country}-SILC_pooled_all_obs_02.dta

/*******************************************************************************
* Save the whole pooled dataset that will be used for regression estimates
*******************************************************************************/
save "$dir_data/${country}-SILC_pooled_all_obs_02.dta", replace 
cap log close 

/*******************************************************************************
* Clean-up and exit
*******************************************************************************/
#delimit ;
local files_to_drop 
	temp_age.dta
	temp_dagpns.dta
	temp_deh.dta
	temp_dgn.dta
	temp_dhe.dta
	temp_dlltsd.dta
	temp_father_dag.dta
	temp_lesc3.dta
	temp_lesc4.dta
	temp_mother_dag.dta
	temp_ypnb.dta
	tmp_partnershipDuration.dta
	father_edu.dta 
	mother_edu.dta
	mother_dchpd.dta
	temp_orig_econ_status.dta
	temp_orig_edu.dta
	temp_dagpns_y.dta
	temp_depChild_mother.dta
	temp_depChild_father.dta
	;
#delimit cr 

foreach file of local files_to_drop { 
	erase "$dir_data/`file'"
}

