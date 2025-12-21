/*
This file pre-processes observed data from EU-SILC, which will be used for validation of SimPaths .

Author: Daria Popova 
Last modified: Nov 2024 

This file produces eusilc_validation_sample.dta file which provides validation targets for the simulated data.
Notes: 
In the UKHLS version children <16 were dropped because they did not have weights ==> in EUSILC we will use household weight which is defined for everyone so children will remain in the sample  
*/


// Run on VM
forvalues year = 11/23 { //beginning of year loop 
	global silc_yr = `year' 
	//global silc_yr = 11
	
	************************************************************************
	* Define EUSILC data files 
	* (specific release and date, corresponding to the files stored in the sub-folder "Data"):	
	************************************************************************

	* Household Register (D-FILE)
	global d_file "${EUSILC_original_crosssection}\\${country}\20${silc_yr}\UDB_c${country}${silc_yr}D.csv"		

	* Personal Register (R-FILE), i.e. all people
	global r_file "${EUSILC_original_crosssection}\\${country}\20${silc_yr}\UDB_c${country}${silc_yr}R.csv"		

	* Household Data (H-FILE)
	global h_file "${EUSILC_original_crosssection}\\${country}\20${silc_yr}\UDB_c${country}${silc_yr}H.csv"		

	* Personal Data (P-FILE), i.e. people aged 16 and above
	global p_file "${EUSILC_original_crosssection}\\${country}\20${silc_yr}\UDB_c${country}${silc_yr}P.csv"		

	cd "$dir_data" 	

	************************************************************************
	* Import SILC files and save in Stata format
	************************************************************************

	* Household Register (D-FILE)
	insheet using "${d_file}", clear   	
	gen double idhh = db030
	keep if db020 == "${country}"
	qui count
	display in y "D-FILE - number of observations (households): " r(N)
	sort idhh
	save D-${country}.dta, replace

	* Personal Register (R-FILE), i.e. all people
	insheet using "${r_file}", clear	
	gen double idhh = rx030
	gen double idperson = rb030
	keep if rb020 == "${country}"
	qui count
	display in y "R-FILE - number of observations (individuals): " r(N)
	sort idhh idperson 
	save R-${country}.dta, replace

	* Household Data (H-FILE)
	insheet using "${h_file}", clear	
	gen double idhh = hb030
	keep if hb020 == "${country}"
	qui count
	display in y "H-FILE - number of observations: " r(N)
	sort idhh
	save H-${country}.dta, replace

	* Personal Data (P-FILE), i.e. people aged 16 and above
	insheet using "${p_file}", clear	
	gen double idhh = px030
	gen double idperson = pb030
	keep if pb020 == "${country}"
	qui count
	display in y "P-FILE - number of observations: " r(N)
	sort idhh idperson 
	save P-${country}.dta, replace

	************************************************************************
	* Merge files
	************************************************************************

	* Household register & Personal Register
	use D-${country}, clear
	merge 1:m idhh using R-${country}
	noi di in y "CHECK: variable _merge must be equal to 3"
	if ${use_assert} assert _merge == 3
	drop _merge

	* Household Data
	sort idhh idperson 
	merge m:m idhh using H-${country}
	noi di in y "CHECK: variable _merge must be equal to 3"
	if ${use_assert} assert _merge == 3
	drop _merge

	* Personal Data
	sort idhh idperson 
	merge 1:m idhh idperson using P-${country}
	noi di in y "CHECK: variable _merge must be equal to 1 or 3"
	if ${use_assert} assert _merge == 1 | _merge == 3
	tab _merge
	drop _merge
	sort idhh idperson 

	************************************************************************
	* Save output
	************************************************************************

	format idhh idperson %12.0f
	save ${country}-SILC20${silc_yr}.dta, replace

	*clean up 
	erase D-${country}.dta
	erase R-${country}.dta
	erase H-${country}.dta
	erase P-${country}.dta
}
*/

cd "$dir_data"

// Run on Mac
forvalues year = 11/23 { //beginning of year loop 
	global silc_yr = `year'
	//global silc_yr = 11
	
	use "$dir_data/${country}-SILC20${silc_yr}.dta", clear
		
	gen stm = 20${silc_yr}
	gen swv = stm


	************************************************************************
	* idfather			Father ID	
	************************************************************************

	di in y "CHECK: father ID in R-file and P-file must match"
	qui count if rb220 != pb160 & pb160 != . 
	if (r(N) > 0) noi di in r "FATHER IDs DO NOT MATCH!"

	recode rb220 (. = -9)
	gen double idfather = rb220 
	format idfather %12.0f

	sum idfather if idfather > 0

	************************************************************************
	* idmother			Mother ID	
	************************************************************************

	di in y "CHECK: mother ID in R-file and P-file must match"
	qui count if rb230 != pb170 & pb170 != . 
	if (r(N) > 0) noi di in r "MOTHER IDs DO NOT MATCH!"

	recode rb230 (. = -9)
	gen double idmother = rb230 
	format idmother %12.0f

	sum idmother if idmother > 0

	************************************************************************
	* idpartner			Partner ID	
	************************************************************************

	di in y "CHECK: partner ID in R-file and P-file must match"
	qui count if rb240 != pb180 & pb180 != . 
	if (r(N) > 0) noi di in r "PARTNER IDs DO NOT MATCH!"

	gen double idpartner = rb240 
	recode idpartner (. = -9)
	format idpartner %12.0f

	sum idpartner if idpartner > 0

	************************************************************************
	* dag				Age
	************************************************************************

	di in y "CHECK: age variable in R-file and P-file must match"
	qui count if rx020 != px020 & px020 != . 
	if (r(N) > 0) noi di in r "AGE VARs DO NOT MATCH!"

	gen dag = rx020

	qui count if dag == .
	di in y "Number of observations where age is missing (dag): " r(N)
	if (r(N) > 0) noi di in r "MUST BE IMPUTED!"

	sum dag 

	************************************************************************
	* dgn 			Gender 
	*
	* 0: Female
	* 1: Male	
	************************************************************************

	di in y "CHECK: gender variable in R-file and P-file must match"
	qui count if rb090 != pb150 & pb150 != . 
	if (r(N) > 0) noi di in r "GENDER VARs DO NOT MATCH!"

	gen dgn = rb090
	recode dgn (2=0)

	qui count if !(dgn == 0 | dgn == 1)
	di in y "Number of observations where gender is invalid or missing (dgn): " r(N)
	if (r(N) > 0) noi di in r "MUST BE IMPUTED!"

	sum dgn
	tab dgn rb090, m 

	***************************************************************************
	* dcpst           Partnership status
	* 1 partnered 
	* 2 single
	* 3 previously partnered
	***************************************************************************
	
	gen dcpst = . 
	replace dcpst = 1 if idpartner > 0 //partnered 
	replace dcpst = 2 if idpartner < 0 & pb190 == 1 //no partner in hh and is single 
	replace dcpst = 3 if idpartner < 0 & pb190 != 1 //no partner and previously partnered 
	lab var dcpst "Partnership status"
	lab define dcpst 1 "partnered" 2 "single" 3 "previously partnered" 
	lab values dcpst dcpst 
	recode dcpst (. = -9)

	*children coded as "Never Married" (17 and under chosen as can marry from 18 years onwards)
	replace dcpst = 2 if dag <= 17 & idpartner < 0

	************************************************************************
	* dwt		Grossing-up weight	
	************************************************************************
	gen dwt = db090 

	sum dwt

	************************************************************************
	* drgn1		Region (NUTS 1 level) 
	************************************************************************ 
	//fre db040
	clonevar drgn1=db040 
	destring drgn1, replace ignore(HU)

	la var drgn1 "Region"
	lab define drgn1 ///
	1 "Central Hungary (Közép-Magyarország)" ///
	2 "Transdanubia (Dunántúl)" ///
	3 "Great Plain and North (Alföld és Észak)"
	lab values drgn1 drgn1
	recode drgn1 (.=-9)
	//fre drgn1
	
	*************************************************************************
	* dhe 		Self-rated health status
	*************************************************************************
	
	recode ph010 (5 = 1 "Poor") ///
		(4 = 2 "Fair") ///
		(3 = 3 "Good") ///
		(2 = 4 "Very good") ///
		(1 = 5 "Excellent") ///
		, into(dhe)
	lab var dhe "Health status"
	fre dhe 

	*impute missing values
	fre dag if missing(dhe) 

	*ordered probit model
	gen dagsq = dag^2

	recode dgn dag dagsq drgn1 (-9=.) , gen (dgn2 dag2 dagsq2 drgn12)
	fre dgn2 dag2 dagsq2 drgn12
	xi: oprobit dhe i.dgn2 dag2 dagsq i.drgn12 i.swv if dhe < ., vce(robust)
	predict pred_probs1 pred_probs2 pred_probs3 pred_probs4 pred_probs5, pr

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

	drop dgn2 dag2 dagsq2 drgn12 p1* p2 p3 p4 rnd imp_dhe		
	
	*************************************************************************
	* dlltsd  	Disability/Long-term health problems 
	*************************************************************************
	
	gen dlltsd = 0
	lab var dlltsd "LT sick or disabled"		
	
	if `year' < 21 {
		replace dlltsd = 1 if pl031 == 8 
	}
	
	else {
		replace dlltsd = 1 if pl032 == 4 
	}	
	
	
	save ${country}-SILC20${silc_yr}a.dta, replace  
	
} 
	
********************************************
* Create a pooled cross-sectional dataset  *
********************************************

cd "$dir_data"

use ${country}-SILC2011a.dta, clear 
keep stm swv idhh idperson idfather idpartner idmother dag dgn dcpst dwt ///
	drgn1 dhe hy010 py021g py010g py050g py080g hy080g hy110g hy040g ///
	hy090g hy020 pl060 pl031 rb210 pe040 pb190 py010g_f py010g_i dlltsd

forvalues silcyr = 2012/2020 {
	append using ${country}-SILC`silcyr'a.dta, nolabel keep(stm swv idhh ///
	idperson idfather idpartner idmother dag dgn dcpst dwt drgn1 dhe hy010 ///
	py021g py010g py050g py080g hy080g hy110g hy040g hy090g hy020 pl060 ///
	pl031 rb210 pe040 pb190 py010g_f py010g_i dlltsd) force
} 

forvalues silcyr = 2021/2023 {
	append using ${country}-SILC`silcyr'a.dta, nolabel keep(stm swv idhh ///
	idperson idfather idpartner idmother dag dgn dcpst dwt drgn1 dhe hy010 ///
	py021g py010g py050g py080g hy080g hy110g hy040g hy090g hy020 pl060 ///
	pl032 rb211 pe041 pb190 py010g_f py010g_i dlltsd) force
} 

preserve 

collapse (sum) dwt, by(stm)
format dwt %15.0f
list stm dwt

restore 

/*	


*/

save "${country}-eusilc_validation_sample_prep1.dta", replace

************************************************************************
* Clean-up and exit
************************************************************************

#delimit ;
local files_to_drop 
	${country}-SILC2011a.dta
	${country}-SILC2012a.dta
	${country}-SILC2013a.dta
	${country}-SILC2014a.dta
	${country}-SILC2015a.dta
	${country}-SILC2016a.dta
	${country}-SILC2017a.dta
	${country}-SILC2018a.dta
	${country}-SILC2019a.dta
	${country}-SILC2020a.dta
	${country}-SILC2021a.dta
	${country}-SILC2022a.dta
	${country}-SILC2023a.dta
	;
#delimit cr // cr stands for carriage return

foreach file of local files_to_drop { 
	erase "$dir_data/`file'"
}



/*
forvalues year=11/20 { //beginning of year loop 
global silc_yr = `year' 

************************************************************************
* Define EUSILC data files 
* (specific release and date, corresponding to the files stored in the sub-folder "Data"):	
************************************************************************
* Household Register (D-FILE)
global d_file "${EUSILC_original_crosssection}\\${country}\\20${silc_yr}\UDB_c${country}${silc_yr}D.csv"		

* Personal Register (R-FILE), i.e. all people
global r_file "${EUSILC_original_crosssection}\\${country}\\20${silc_yr}\UDB_c${country}${silc_yr}R.csv"		

* Household Data (H-FILE)
global h_file "${EUSILC_original_crosssection}\\${country}\\20${silc_yr}\UDB_c${country}${silc_yr}H.csv"		

* Personal Data (P-FILE), i.e. people aged 16 and above
global p_file "${EUSILC_original_crosssection}\\${country}\\20${silc_yr}\UDB_c${country}${silc_yr}P.csv"		

************************************************************************
cd "${dir_data}" 	
************************************************************************
* Import SILC files and save in Stata format
************************************************************************

* Household Register (D-FILE)
insheet using "${d_file}", clear   	
gen double idhh = db030
keep if db020 == "${country}"
qui count
display in y "D-FILE - number of observations (households): " r(N)
sort idhh
save D-${country}.dta, replace

* Personal Register (R-FILE), i.e. all people
insheet using "${r_file}", clear	
gen double idhh = rx030
gen double idperson = rb030
keep if rb020 == "${country}"
qui count
display in y "R-FILE - number of observations (individuals): " r(N)
sort idhh idperson 
save R-${country}.dta, replace

* Household Data (H-FILE)
insheet using "${h_file}", clear	
gen double idhh = hb030
keep if hb020 == "${country}"
qui count
display in y "H-FILE - number of observations: " r(N)
sort idhh
save H-${country}.dta, replace

* Personal Data (P-FILE), i.e. people aged 16 and above
insheet using "${p_file}", clear	
gen double idhh = px030
gen double idperson = pb030
keep if pb020 == "${country}"
qui count
display in y "P-FILE - number of observations: " r(N)
sort idhh idperson 
save P-${country}.dta, replace

************************************************************************
* Merge files
************************************************************************

* Household register & Personal Register
use D-${country}, clear
merge 1:m idhh using R-${country}
noi di in y "CHECK: variable _merge must be equal to 3"
if ${use_assert} assert _merge == 3
drop _merge

* Household Data
sort idhh idperson 
merge m:m idhh using H-${country}
noi di in y "CHECK: variable _merge must be equal to 3"
if ${use_assert} assert _merge == 3
drop _merge

* Personal Data
sort idhh idperson 
merge 1:m idhh idperson using P-${country}
noi di in y "CHECK: variable _merge must be equal to 1 or 3"
if ${use_assert} assert _merge == 1 | _merge == 3
tab _merge
drop _merge
sort idhh idperson 


************************************************************************
* Save output
************************************************************************

format idhh idperson %12.0f
save ${country}-SILC20${silc_yr}.dta, replace

*clean up 
erase D-${country}.dta
erase R-${country}.dta
erase H-${country}.dta
erase P-${country}.dta

gen stm=20${silc_yr}
gen swv=stm


************************************************************************
* idfather			Father ID	
************************************************************************

di in y "CHECK: father ID in R-file and P-file must match"
qui count if rb220 != pb160 & pb160 != . 
if (r(N) > 0) noi di in r "FATHER IDs DO NOT MATCH!"

recode rb220 (. = -9)
gen double idfather = rb220 
format idfather %12.0f

sum idfather if idfather > 0

************************************************************************
* idmother			Mother ID	
************************************************************************

di in y "CHECK: mother ID in R-file and P-file must match"
qui count if rb230 != pb170 & pb170 != . 
if (r(N) > 0) noi di in r "MOTHER IDs DO NOT MATCH!"

recode rb230 (. = -9)
gen double idmother = rb230 
format idmother %12.0f

sum idmother if idmother > 0

************************************************************************
* idpartner			Partner ID	
************************************************************************

di in y "CHECK: partner ID in R-file and P-file must match"
qui count if rb240 != pb180 & pb180 != . 
if (r(N) > 0) noi di in r "PARTNER IDs DO NOT MATCH!"

gen double idpartner = rb240 
recode idpartner (. = -9)
format idpartner %12.0f

sum idpartner if idpartner > 0

************************************************************************
* dag				Age
************************************************************************

di in y "CHECK: age variable in R-file and P-file must match"
qui count if rx020 != px020 & px020 != . 
if (r(N) > 0) noi di in r "AGE VARs DO NOT MATCH!"

gen dag = rx020

qui count if dag == .
di in y "Number of observations where age is missing (dag): " r(N)
if (r(N) > 0) noi di in r "MUST BE IMPUTED!"

sum dag 

************************************************************************
* dgn 			Gender 
*
* 0: Female
* 1: Male	
************************************************************************

di in y "CHECK: gender variable in R-file and P-file must match"
qui count if rb090 != pb150 & pb150 != . 
if (r(N) > 0) noi di in r "GENDER VARs DO NOT MATCH!"

gen dgn = rb090
recode dgn (2=0)

qui count if !(dgn == 0 | dgn == 1)
di in y "Number of observations where gender is invalid or missing (dgn): " r(N)
if (r(N) > 0) noi di in r "MUST BE IMPUTED!"

sum dgn
tab dgn rb090, m 

***************************************************************************
* dcpst           Partnership status
* 1 partnered 
* 2 single
* 3 previously partnered
***************************************************************************
gen dcpst=. 
replace dcpst = 1 if idpartner>0 //partnered 
replace dcpst = 2 if idpartner<0 & pb190==1 //no partner in hh and is single 
replace dcpst = 3 if idpartner<0 & pb190!=1 //no partner and previously partnered 
la var dcpst "Partnership status"
lab define dcpst 1 "partnered" 2 "single" 3 "previously partnered" 
lab values dcpst dcpst 
recode dcpst (. = -9)

*children coded as "Never Married" (17 and under chosen as can marry from 18 years onwards)
replace dcpst = 2 if dag <= 17 & idpartner<0

************************************************************************
* dwt		Grossing-up weight	
************************************************************************
gen dwt = db090 

sum dwt

************************************************************************
* drgn1	Region (NUTS 1 level) 
*
************************************************************************ 
//fre db040
clonevar drgn1=db040 
destring drgn1, replace ignore(HU)

la var drgn1 "Region"
lab define drgn1 ///
1 "Central Hungary (Közép-Magyarország)" ///
2 "Transdanubia (Dunántúl)" ///
3 "Great Plain and North (Alföld és Észak)"
lab values drgn1 drgn1
recode drgn1 (.=-9)
//fre drgn1

*************************************************************************
* dhe Self-rated health status
*************************************************************************
/*Use ph010 (general health) variable: 
-----------------------------------------------------------------
                    |      Freq.    Percent      Valid       Cum.
--------------------+--------------------------------------------
Valid   1 Very good |      41058      12.18      14.86      14.86
        2 Good      |     103680      30.77      37.52      52.38
        3 Fair      |      81427      24.17      29.47      81.85
        4 Bad       |      38358      11.38      13.88      95.74
        5 Very bad  |      11783       3.50       4.26     100.00
        Total       |     276306      82.00     100.00           
Missing .           |      60652      18.00                      
Total               |     336958     100.00                      
-----------------------------------------------------------------
code negative values to missing, reverse code so 5 = excellent and higher number means better health
*/
*************************************************************************
recode ph010 (5 = 1 "Poor") ///
	(4 = 2 "Fair") ///
	(3 = 3 "Good") ///
	(2 = 4 "Very good") ///
	(1 = 5 "Excellent") ///
	, into(dhe)
la var dhe "Health status"
fre dhe 

*impute missing values
fre dag if missing(dhe) 

*ordered probit model
gen dagsq = dag^2

recode dgn dag dagsq drgn1 (-9=.) , gen (dgn2 dag2 dagsq2 drgn12)
fre dgn2 dag2 dagsq2 drgn12
xi: oprobit dhe i.dgn2 dag2 dagsq ib3.drgn12 i.swv if dhe < ., vce(robust)
predict pred_probs1 pred_probs2 pred_probs3 pred_probs4 pred_probs5, pr

*Identify the category with the highest predicted probability
egen max_prob = rowmax(pred_probs1 pred_probs2 pred_probs3 pred_probs4 pred_probs5)
*Impute missing values of dhe based on predicted probabilities
gen imp_dhe = .
replace imp_dhe = 1 if max_prob == pred_probs1
replace imp_dhe = 2 if max_prob == pred_probs2
replace imp_dhe = 3 if max_prob == pred_probs3
replace imp_dhe = 4 if max_prob == pred_probs4
replace imp_dhe = 5 if max_prob == pred_probs5

sum imp_dhe if missing(dhe) & dag>0 & dag<16
sum imp_dhe if !missing(dhe) & dag>0 & dag<16
sum imp_dhe if missing(dhe) & dag>=16
sum imp_dhe if !missing(dhe) & dag>=16

gen dhe_flag = missing(dhe)
lab var dhe_flag "=1 if dhe is imputed"
replace dhe = round(imp_dhe) if missing(dhe)

bys dhe_flag: fre dhe if dag<=16
bys dhe_flag: fre dhe if dag>16 

drop dgn2 dag2 dagsq2 drgn12 _Idgn2_1 pred_probs* max_prob imp_dhe

***************************************************************************




save ${country}-SILC20${silc_yr}.dta, replace  


					
} //end of year loop 
	
************************************************	
* now create a pooled cross-sectional dataset  *
************************************************

use ${country}-SILC2011.dta, clear 
keep stm swv idhh idperson idfather idpartner idmother dag dgn dcpst dwt drgn1 dhe hy010 py021g py010g py050g py080g hy080g hy110g hy040g hy090g hy020 pl060 pl031 rb210 pe040 pb190
forvalues silcyr = 2012/2020 {
append using ${country}-SILC`silcyr'.dta, nolabel keep(stm swv idhh idperson idfather idpartner idmother dag dgn dcpst dwt drgn1 dhe hy010 ///
 py021g py010g py050g py080g hy080g hy110g hy040g hy090g hy020 pl060 pl031 rb210 pe040 pb190) force
} 


preserve 
collapse (sum) dwt, by(stm)
format dwt %15.0f
list stm dwt
restore 

/*	
	stm       dwt	
		
1.	2011   9805384	
2.	2012   9778447	
3.	2013   9751464	
4.	2014   9725522	
5.	2015   9695142	
		
6.	2016   9669282	
7.	2017   9638327	
8.	2018   9609413	
9.	2019   9592359	
10.	2020   9578774	
		
11.	2021   9598972	
*/



save "${country}-eusilc_validation_sample.dta", replace



/**************************************************************************************
* clean-up and exit
**************************************************************************************/
#delimit ;
local files_to_drop 
	HU-SILC2011.dta
	HU-SILC2012.dta
	HU-SILC2013.dta
	HU-SILC2014.dta
	HU-SILC2015.dta
	HU-SILC2016.dta
	HU-SILC2017.dta
	HU-SILC2018.dta
	HU-SILC2019.dta
	HU-SILC2020.dta
	//HU-SILC2021.dta
	;
#delimit cr // cr stands for carriage return

foreach file of local files_to_drop { 
	erase "$dir_data/`file'"
}

