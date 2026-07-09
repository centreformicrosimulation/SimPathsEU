/*******************************************************************************
SUMMARY — 03_create_masterP.do 

This file builds the master personal data (P) panel for EU-SILC 2005–2023.
It follows the same two-step structure as 03_create_masterR.do, but P is
linked to the R file (not directly to D) because person IDs in P are defined
at the person level while household membership is captured in R.

STEP 1 
	Create clean annual P files (one block per release year, 2023 down to 2005)
	For each year, the raw P data file is read and merged 1:m with the 
	corresponding YYYYR.dta on year, country, and pid. Because R can contain a 
	person in multiple households (pid not unique in R), the merge is 1:m. 
	After keeping _merge == 3, duplicates on year, country, pid are dropped 
	(force) since P contains one row per person. 
	The clean sample is thus inherited from the R file, which in turn inherited 
	it from the D file. 
	Each block saves a YYYYP.dta file.

STEP 2 
	Assemble the full panel
	The 2023P.dta is loaded and annual YYYYP files from 2022 back to 2005 are 
	merged in one at a time using year, upid, country, and uhid, with an 
	intermediate save after each step. 
	The one-year-at-a-time approach manages memory. 
	R-file and D-file variables carried over from the merge in Step 1 are 
	dropped at the end before the final masterP.dta is saved .

NOTE: This file must be run after 03_create_masterR.do. Sample selection flows
D → R → P; this file trusts the output of the upstream files.

*******************************************************************************/

/* 2023 */
	clear
	local filen : dir "${datapath}/EU-SILC/19 L-2023/"  files "udb_l23p_ver*"
	display `filen'
	local filel "${datapath}/EU-SILC/19 L-2023/"
	display `"`filel'"'
	local fileln : display `"`filel'"' `filen'
	use `"`fileln'"', clear
	
	local new_var=lower("`var'")

    foreach var of varlist _all {
    	local new_var = lower("`var'")
    	cap rename `var' `new_var'
    }
	
	tostring pb030, replace format("%15.0f")
	gen year = pb010
	gen pid = pb030   
	gen country = pb020
	sort year country pid 
	
	/*checking for duplicates/errors in pid (should be unique)*/
	duplicates report year country pid
	
	/*merge with R files to keep only obs from selcted rotational groups*/
	merge 1:m year country pid using "${datapath}/EU-SILC/19 L-2023/2023R.dta"
	keep if _merge == 3 
	drop _merge
	
	/* R file contains combinations in pid and hid, so pids are not unique. In P pids are unique, so we can drop the duplicates */
	duplicates drop year country pid, force
	
	/*this is the masterfileR where to add data from previous releases to */
	save "${datapath}/EU-SILC/19 L-2023/2023P", replace

/* 2022 */
	clear
	local filen : dir "${datapath}/EU-SILC/18 L-2022/"  files "udb_l22p_ver*"
	display `filen'
	local filel "${datapath}/EU-SILC/18 L-2022/"
	display `"`filel'"'
	local fileln : display `"`filel'"' `filen'
	use `"`fileln'"', clear
	
	local new_var=lower("`var'")

    foreach var of varlist _all {
    	local new_var = lower("`var'")
    	cap rename `var' `new_var'
    }
	
	tostring pb030, replace format("%15.0f")
	gen year = pb010
	gen pid = pb030   
	gen country = pb020
	sort year country pid 
	/*checking for duplicates/errors in pid (should be unique)*/
	duplicates report year country pid
	/*merge with R files to keep only obs from selcted rotational groups*/
	merge 1:m year country pid using "${datapath}/EU-SILC/18 L-2022/2022R.dta"
	keep if _merge == 3 
	drop _merge
	/* R file contains combinations in pid and hid, so pids are not unique. In P pids are unique, so we can drop the duplicates */
	duplicates drop year country pid, force
	/*this is the masterfileR where to add data from previous releases to */
	save "${datapath}/EU-SILC/18 L-2022/2022P", replace

/* 2021 */
	clear
	local filen : dir "${datapath}/EU-SILC/17 L-2021/"  files "udb_l21p_ver*"
	display `filen'
	local filel "${datapath}/EU-SILC/17 L-2021/"
	display `"`filel'"'
	local fileln : display `"`filel'"' `filen'
	use `"`fileln'"', clear
	
	local new_var=lower("`var'")

    foreach var of varlist _all {
    	local new_var = lower("`var'")
    	cap rename `var' `new_var'
    }
	
	tostring pb030, replace format("%15.0f")
	gen year = pb010
	gen pid = pb030   
	gen country = pb020
	sort year country pid 
	/*checking for duplicates/errors in pid (should be unique)*/
	duplicates report year country pid
	/*merge with R files to keep only obs from selcted rotational groups*/
	merge 1:m year country pid using "${datapath}/EU-SILC/17 L-2021/2021R.dta"
	keep if _merge == 3 
	drop _merge
	/* R file contains combinations in pid and hid, so pids are not unique. In P pids are unique, so we can drop the duplicates */
	duplicates drop year country pid, force
	/*this is the masterfileR where to add data from previous releases to */
	save "${datapath}/EU-SILC/17 L-2021/2021P", replace	
	
/* 2020 */
	clear
	local filen : dir "${datapath}/EU-SILC/16 L-2020/"  files "udb_l20p_ver*"
	display `filen'
	local filel "${datapath}/EU-SILC/16 L-2020/"
	display `"`filel'"'
	local fileln : display `"`filel'"' `filen'
	use `"`fileln'"', clear
	
	local new_var=lower("`var'")

    foreach var of varlist _all {
    	local new_var = lower("`var'")
    	cap rename `var' `new_var'
    }
	
	tostring pb030, replace format("%15.0f")
	gen year = pb010
	gen pid = pb030   
	gen country = pb020
	sort year country pid 
	/*checking for duplicates/errors in pid (should be unique)*/
	duplicates report year country pid
	/*merge with R files to keep only obs from selcted rotational groups*/
	merge 1:m year country pid using "${datapath}/EU-SILC/16 L-2020/2020R.dta"
	keep if _merge == 3 
	drop _merge
	/* R file contains combinations in pid and hid, so pids are not unique. In P pids are unique, so we can drop the duplicates */
	duplicates drop year country pid, force
	/*this is the masterfileR where to add data from previous releases to */
	save "${datapath}/EU-SILC/16 L-2020/2020P", replace

/* 2019 */
	clear
	local filen : dir "${datapath}/EU-SILC/15 L-2019/"  files "udb_l19p_ver*"
	display `filen'
	local filel "${datapath}/EU-SILC/15 L-2019/"
	display `"`filel'"'
	local fileln : display `"`filel'"' `filen'
	use `"`fileln'"', clear
	
	local new_var=lower("`var'")

    foreach var of varlist _all {
    	local new_var = lower("`var'")
    	cap rename `var' `new_var'
    }
	
	tostring pb030, replace format("%15.0f")
	gen year = pb010
	gen pid = pb030   
	gen country = pb020
	sort year country pid 
	/*checking for duplicates/errors in pid (should be unique)*/
	duplicates report year country pid
	/*merge with R files to keep only obs from selcted rotational groups*/
	merge 1:m year country pid using "${datapath}/EU-SILC/15 L-2019/2019R.dta"
	keep if _merge == 3 
	drop _merge
	/* R file contains combinations in pid and hid, so pids are not unique. In P pids are unique, so we can drop the duplicates */
	duplicates drop year country pid, force
	/*this is the masterfileR where to add data from previous releases to */
	save "${datapath}/EU-SILC/15 L-2019/2019P", replace

	
/* 2018 */
	clear
	local filen : dir "${datapath}/EU-SILC/14 L-2018/"  files "udb_l18p_ver*"
	display `filen'
	local filel "${datapath}/EU-SILC/14 L-2018/"
	display `"`filel'"'
	local fileln : display `"`filel'"' `filen'
	use `"`fileln'"', clear
	
	local new_var=lower("`var'")

    foreach var of varlist _all {
    	local new_var = lower("`var'")
    	cap rename `var' `new_var'
    }
	
	tostring pb030, replace format("%15.0f")
	gen year = pb010
	gen pid = pb030   
	gen country = pb020
	sort year country pid 
	/*checking for duplicates/errors in pid (should be unique)*/
	duplicates report year country pid
	/*merge with R files to keep only obs from selcted rotational groups*/
	merge 1:m year country pid using "${datapath}/EU-SILC/14 L-2018/2018R.dta"
	keep if _merge == 3 
	drop _merge
	/* R file contains combinations in pid and hid, so pids are not unique. In P pids are unique, so we can drop the duplicates */
	duplicates drop year country pid, force
	/*this is the masterfileR where to add data from previous releases to */
	save "${datapath}/EU-SILC/14 L-2018/2018P", replace

	
/* 2017 */
	clear
	local filen : dir "${datapath}/EU-SILC/13 L-2017/"  files "udb_l17p_ver*"
	display `filen'
	local filel "${datapath}/EU-SILC/13 L-2017/"
	display `"`filel'"'
	local fileln : display `"`filel'"' `filen'
	use `"`fileln'"', clear
	
	local new_var=lower("`var'")

    foreach var of varlist _all {
    	local new_var = lower("`var'")
    	cap rename `var' `new_var'
    }
	
	tostring pb030, replace format("%15.0f")
	gen year = pb010
	gen pid = pb030   
	gen country = pb020
	sort year country pid 
	/*checking for duplicates/errors in pid (should be unique)*/
	duplicates report year country pid
	/*merge with R files to keep only obs from selcted rotational groups*/
	merge 1:m year country pid using "${datapath}/EU-SILC/13 L-2017/2017R.dta"
	keep if _merge == 3 
	drop _merge
	/* R file contains combinations in pid and hid, so pids are not unique. In P pids are unique, so we can drop the duplicates */
	duplicates drop year country pid, force
	/*this is the masterfileR where to add data from previous releases to */
	save "${datapath}/EU-SILC/13 L-2017/2017P", replace

/* 2016 */
	clear
	local filen : dir "${datapath}/EU-SILC/12 L-2016/"  files "udb_l16p_ver*"
	display `filen'
	local filel "${datapath}/EU-SILC/12 L-2016/"
	display `"`filel'"'
	local fileln : display `"`filel'"' `filen'
	use `"`fileln'"', clear
	
	local new_var=lower("`var'")

    foreach var of varlist _all {
    	local new_var = lower("`var'")
    	cap rename `var' `new_var'
    }
	
	tostring pb030, replace format("%15.0f")
	gen year = pb010
	gen pid = pb030   
	gen country = pb020
	sort year country pid 
	/*checking for duplicates/errors in pid (should be unique)*/
	duplicates report year country pid
	/*merge with R files to keep only obs from selcted rotational groups*/
	merge 1:m year country pid using "${datapath}/EU-SILC/12 L-2016/2016R.dta"
	keep if _merge == 3 
	drop _merge
	/* R file contains combinations in pid and hid, so pids are not unique. In P pids are unique, so we can drop the duplicates */
	duplicates drop year country pid, force
	/*this is the masterfileR where to add data from previous releases to */
	save "${datapath}/EU-SILC/12 L-2016/2016P", replace

	
/* 2015 */
	clear
	local filen : dir "${datapath}/EU-SILC/11 L-2015/"  files "udb_l15p_ver*"
	display `filen'
	local filel "${datapath}/EU-SILC/11 L-2015/"
	display `"`filel'"'
	local fileln : display `"`filel'"' `filen'
	use `"`fileln'"', clear
	
	
	local new_var=lower("`var'")

    foreach var of varlist _all {
    	local new_var = lower("`var'")
    	cap rename `var' `new_var'
    }
	
	tostring pb030, replace format("%15.0f")
	gen year = pb010
	gen pid = pb030   
	gen country = pb020
	sort year country pid 
	/*checking for duplicates/errors in pid (should be unique)*/
	duplicates report year country pid
	/*merge with R files to keep only obs from selcted rotational groups*/
	merge 1:m year country pid using "${datapath}/EU-SILC/11 L-2015/2015R.dta"
	keep if _merge == 3 
	drop _merge
	/* R file contains combinations in pid and hid, so pids are not unique. In P pids are unique, so we can drop the duplicates */
	duplicates drop year country pid, force
	/*this is the masterfileR where to add data from previous releases to */
	save "${datapath}/EU-SILC/11 L-2015/2015P", replace

	/*selecting 2014 release data*/
	clear
	local filen : dir "${datapath}/EU-SILC/10 L-2014/"  files "udb_l14p_ver*"
	display `filen'
	local filel "${datapath}/EU-SILC/10 L-2014/"
	display `"`filel'"'
	local fileln : display `"`filel'"' `filen'
	use `"`fileln'"', clear
	
	
	local new_var=lower("`var'")

    foreach var of varlist _all {
    	local new_var = lower("`var'")
    	cap rename `var' `new_var'
    }
	
	tostring pb030, replace format("%15.0f")
	gen year = pb010
	gen pid = pb030   
	gen country = pb020
	sort year country pid 
	/*checking for duplicates/errors in hid*/
	duplicates report year country pid
	/*merge with IDs from house hold register (R file), keep matches */
	merge 1:m year country pid using "${datapath}/EU-SILC/10 L-2014/2014R.dta"
	keep if _merge == 3 
	drop _merge 
	/* R file contains combinations in pid and hid, so pids are not unique. In P pids are unique, so we can drop the duplicates */
	duplicates drop year country pid, force
	save "${datapath}/EU-SILC/10 L-2014/2014P.dta", replace

	/*selecting 2013 release data*/
	clear
	local filen : dir "${datapath}/EU-SILC/9 L-2013/"  files "udb_l13p_ver*"
	display `filen'
	local filel "${datapath}/EU-SILC/9 L-2013/"
	display `"`filel'"'
	local fileln : display `"`filel'"' `filen'
	use `"`fileln'"', clear
	
	
	local new_var=lower("`var'")

    foreach var of varlist _all {
    	local new_var = lower("`var'")
    	cap rename `var' `new_var'
    }
	
	tostring pb030, replace format("%15.0f")
	gen year = pb010
	gen pid = pb030   
	gen country = pb020
	sort year country pid 
	/*checking for duplicates/errors in pid*/
	duplicates report year country pid
	/*merge with IDs from household register (R file), keep the matches */
	merge 1:m year country pid using "${datapath}/EU-SILC/9 L-2013/2013R.dta"
	keep if _merge == 3 
	drop _merge 
	/* R file contains combinations in pid and hid, so pids are not unique. In P pids are unique, so drop duplicates from R*/
	duplicates drop year country pid, force
	save "${datapath}/EU-SILC/9 L-2013/2013P.dta", replace

	/*selecting 2012 release data*/
	clear
	local filen : dir "${datapath}/EU-SILC/8 L-2012/"  files "udb_l12p_ver*"
	display `filen'
	local filel "${datapath}/EU-SILC/8 L-2012/"
	display `"`filel'"'
	local fileln : display `"`filel'"' `filen'
	use `"`fileln'"', clear
	
	
	local new_var=lower("`var'")

    foreach var of varlist _all {
    	local new_var = lower("`var'")
    	cap rename `var' `new_var'
    }
	
	tostring pb030, replace format("%15.0f")
	gen year = pb010
	gen pid = pb030   
	gen country = pb020
	sort year country pid 
	/*checking for duplicates/errors in hid*/
	duplicates report year country pid
	/* R file contains combinations in pid and hid, so pids are not unique. In P pids are unique, so we can drop the duplicates */
	merge 1:m year country pid using "${datapath}/EU-SILC/8 L-2012/2012R.dta"
	keep if _merge == 3 
	drop _merge 
	duplicates drop year country pid, force
	save "${datapath}/EU-SILC/8 L-2012/2012P.dta", replace

	/*selecting 2011 release data*/
	clear
	local filen : dir "${datapath}/EU-SILC/7 L-2011/"  files "udb_l11p_ver*"
	display `filen'
	local filel "${datapath}/EU-SILC/7 L-2011/"
	display `"`filel'"'
	local fileln : display `"`filel'"' `filen'
	use `"`fileln'"', clear
	
	
	local new_var=lower("`var'")

    foreach var of varlist _all {
    	local new_var = lower("`var'")
    	cap rename `var' `new_var'
    }
	
	tostring pb030, replace format("%15.0f")
	gen year = pb010
	gen pid = pb030   
	gen country = pb020
	sort year country pid 
	/*checking for duplicates/errors in hid*/
	duplicates report year country pid
	/* R file contains combinations in pid and hid, so pids are not unique. In P pids are unique, so we can drop the duplicates */
	merge 1:m year country pid using "${datapath}/EU-SILC/7 L-2011/2011R.dta"
	keep if _merge == 3 
	drop _merge 
	duplicates drop year country pid, force
	save "${datapath}/EU-SILC/7 L-2011/2011P.dta", replace

	/*selecting 2010 release data*/
	clear
	local filen : dir "${datapath}/EU-SILC/6 L-2010/"  files "udb_l10p_ver*"
	display `filen'
	local filel "${datapath}/EU-SILC/6 L-2010/"
	display `"`filel'"'
	local fileln : display `"`filel'"' `filen'
	use `"`fileln'"', clear
	
	
	local new_var=lower("`var'")

    foreach var of varlist _all {
    	local new_var = lower("`var'")
    	cap rename `var' `new_var'
    }
	
	tostring pb030, replace format("%15.0f")
	gen year = pb010
	gen pid = pb030   
	gen country = pb020
	sort year country pid 
	/*checking for duplicates/errors in hid*/
	duplicates report year country pid
	/* R file contains combinations in pid and hid, so pids are not unique. In P pids are unique, so we can drop the duplicates */
	merge 1:m year country pid using "${datapath}/EU-SILC/6 L-2010/2010R.dta"
	keep if _merge == 3 
	drop _merge 
	duplicates drop year country pid, force
	save "${datapath}/EU-SILC/6 L-2010/2010P.dta", replace
	
	/*selecting 2009 release data*/
	clear
	local filen : dir "${datapath}/EU-SILC/5 L-2009/"  files "udb_l09p_ver*"
	display `filen'
	local filel "${datapath}/EU-SILC/5 L-2009/"
	display `"`filel'"'
	local fileln : display `"`filel'"' `filen'
	use `"`fileln'"', clear
	
	
	local new_var=lower("`var'")

    foreach var of varlist _all {
    	local new_var = lower("`var'")
    	cap rename `var' `new_var'
    }
	
	tostring pb030, replace format("%15.0f")
	gen year = pb010
	gen pid = pb030   
	gen country = pb020
	sort year country pid 
	/*checking for duplicates/errors in hid*/
	duplicates report year country pid
	/* R file contains combinations in pid and hid, so pids are not unique. In P pids are unique, so we can drop the duplicates */
	merge 1:m year country pid using "${datapath}/EU-SILC/5 L-2009/2009R.dta"
	keep if _merge == 3 
	drop _merge 
	duplicates drop year country pid, force
	save "${datapath}/EU-SILC/5 L-2009/2009P.dta", replace

	/*selecting 2008 release data*/
	clear
	local filen : dir "${datapath}/EU-SILC/4 L-2008/"  files "udb_l08p_ver*"
	display `filen'
	local filel "${datapath}/EU-SILC/4 L-2008/"
	display `"`filel'"'
	local fileln : display `"`filel'"' `filen'
	use `"`fileln'"', clear
	
	
	local new_var=lower("`var'")

    foreach var of varlist _all {
    	local new_var = lower("`var'")
    	cap rename `var' `new_var'
    }
	
	tostring pb030, replace format("%15.0f")
	rename pb010 year
	rename pb030 pid   
	rename pb020 country
	sort year country pid 
	/*checking for duplicates/errors in hid*/
	duplicates report year country pid
	/* R file contains combinations in pid and hid, so pids are not unique. In P pids are unique, so we can drop the duplicates */
	merge 1:m year country pid using "${datapath}/EU-SILC/4 L-2008/2008R.dta"
	keep if _merge == 3 
	drop _merge 
	duplicates drop year country pid, force
	save "${datapath}/EU-SILC/4 L-2008/2008P.dta", replace

/* 2007 */
	clear
	local filen : dir "${datapath}/EU-SILC/3 L-2007/"  files "udb_l07p_ver*"
	display `filen'
	local filel "${datapath}/EU-SILC/3 L-2007/"
	display `"`filel'"'
	local fileln : display `"`filel'"' `filen'
	use `"`fileln'"', clear
	
	
	local new_var=lower("`var'")

    foreach var of varlist _all {
    	local new_var = lower("`var'")
    	cap rename `var' `new_var'
    }
	
	tostring pb030, replace format("%15.0f")
	gen year = pb010
	gen pid = pb030   
	gen country = pb020
	sort year country pid 
	/*checking for duplicates/errors in pid*/
	duplicates report year country pid
	/* R file contains combinations in pid and hid, so pids are not unique. In P pids are unique, so we can drop the duplicates */
	merge 1:m year country pid using "${datapath}/EU-SILC/3 L-2007/2007R.dta"
	keep if _merge == 3 
	drop _merge 
	duplicates drop year country pid, force
	save "${datapath}/EU-SILC/3 L-2007/2007P.dta", replace

/* 2006 */
	clear
	local filen : dir "${datapath}/EU-SILC/2 L-2006/"  files "udb_l06p_ver*"
	display `filen'
	local filel "${datapath}/EU-SILC/2 L-2006/"
	display `"`filel'"'
	local fileln : display `"`filel'"' `filen'
	use `"`fileln'"', clear
	
	
	local new_var=lower("`var'")

    foreach var of varlist _all {
    	local new_var = lower("`var'")
    	cap rename `var' `new_var'
    }
	
	tostring pb030, replace format("%15.0f")
	gen year = pb010
	gen pid = pb030   
	gen country = pb020
	sort year country pid 
	/*checking for duplicates/errors in pid*/
	duplicates report year country pid
	/* R file contains combinations in pid and hid, so pids are not unique. In P pids are unique, so we can drop the duplicates */
	merge 1:m year country pid using "${datapath}/EU-SILC/2 L-2006/2006R.dta"
	keep if _merge == 3 
	drop _merge 
	duplicates drop year country pid, force
	save "${datapath}/EU-SILC/2 L-2006/2006P.dta", replace

/* 2005 */
	clear
	local filen : dir "${datapath}/EU-SILC/1 L-2005/"  files "udb_l05p_ver*"
	display `filen'
	local filel "${datapath}/EU-SILC/1 L-2005/"
	display `"`filel'"'
	local fileln : display `"`filel'"' `filen'
	use `"`fileln'"', clear
	
	
	local new_var=lower("`var'")

    foreach var of varlist _all {
    	local new_var = lower("`var'")
    	cap rename `var' `new_var'
    }
	
	tostring pb030, replace format("%15.0f")
	gen year = pb010
	gen pid = pb030   
	gen country = pb020
	sort year country pid 
	/*checking for duplicates/errors in pid*/
	duplicates report year country pid
	/* R file contains combinations in pid and hid, so pids are not unique. In P pids are unique, so we can drop the duplicates */
	merge 1:m year country pid using "${datapath}/EU-SILC/1 L-2005/2005R.dta"
	keep if _merge == 3 
	drop _merge 
	duplicates drop year country pid, force
	save "${datapath}/EU-SILC/1 L-2005/2005P.dta", replace

	/*merge data from all releases with masterfile. 
	!! this process is memory intensive. */

use "${datapath}/EU-SILC/19 L-2023/2023P.dta", clear
	merge 1:1 year upid country uhid using "${datapath}/EU-SILC/18 L-2022/2022P.dta"
	drop _merge
	merge 1:1 year upid country uhid using "${datapath}/EU-SILC/17 L-2021/2021P.dta"
	drop _merge
	merge 1:1 year upid country uhid using "${datapath}/EU-SILC/16 L-2020/2020P.dta"
	drop _merge

	save "${datapath}/EU-SILC/19 L-2023/masterP.dta", replace
	clear
	use "${datapath}/EU-SILC/19 L-2023/masterP.dta"

	merge 1:1 year upid country uhid using "${datapath}/EU-SILC/15 L-2019/2019P.dta"
	drop _merge
	merge 1:1 year upid country uhid using "${datapath}/EU-SILC/14 L-2018/2018P.dta"
	drop _merge
	merge 1:1 year upid country uhid using "${datapath}/EU-SILC/13 L-2017/2017P.dta"
	drop _merge
	
	save "${datapath}/EU-SILC/19 L-2023/masterP.dta", replace
	clear
	use "${datapath}/EU-SILC/19 L-2023/masterP.dta"

	merge 1:1 year upid country uhid using "${datapath}/EU-SILC/12 L-2016/2016P.dta"
	drop _merge
	
	save "${datapath}/EU-SILC/19 L-2023/masterP.dta", replace
	clear
	use "${datapath}/EU-SILC/19 L-2023/masterP.dta"

	merge 1:1 year upid country uhid using "${datapath}/EU-SILC/11 L-2015/2015P.dta"
	drop _merge
	
	save "${datapath}/EU-SILC/19 L-2023/masterP.dta", replace
	clear
	use "${datapath}/EU-SILC/19 L-2023/masterP.dta"
	
	merge 1:1 year upid country uhid using "${datapath}/EU-SILC/10 L-2014/2014P.dta"
	drop _merge

	save "${datapath}/EU-SILC/19 L-2023/masterP.dta", replace
	clear
	use "${datapath}/EU-SILC/19 L-2023/masterP.dta"

	merge 1:1 year upid country uhid using "${datapath}/EU-SILC/9 L-2013/2013P.dta"
	drop _merge
	
	save "${datapath}/EU-SILC/19 L-2023/masterP.dta", replace
	clear
	use "${datapath}/EU-SILC/19 L-2023/masterP.dta"

	merge 1:1 year upid country uhid using "${datapath}/EU-SILC/8 L-2012/2012P.dta"
	drop _merge
	
	save "${datapath}/EU-SILC/19 L-2023/masterP.dta", replace
	clear
	use "${datapath}/EU-SILC/19 L-2023/masterP.dta"

	merge 1:1 year upid country uhid using "${datapath}/EU-SILC/7 L-2011/2011P.dta"
	drop _merge
	
	save "${datapath}/EU-SILC/19 L-2023/masterP.dta", replace
	clear
	use "${datapath}/EU-SILC/19 L-2023/masterP.dta"
	
	merge 1:1 year upid country uhid using "${datapath}/EU-SILC/6 L-2010/2010P.dta"
	drop _merge
	
	save "${datapath}/EU-SILC/19 L-2023/masterP.dta", replace
	clear
	use "${datapath}/EU-SILC/19 L-2023/masterP.dta"
	
	merge 1:1 year upid country uhid using "${datapath}/EU-SILC/5 L-2009/2009P.dta"
	drop _merge
	
	save "${datapath}/EU-SILC/19 L-2023/masterP.dta", replace
	clear
	use "${datapath}/EU-SILC/19 L-2023/masterP.dta"
	
	merge 1:1 year upid country uhid using "${datapath}/EU-SILC/4 L-2008/2008P.dta"
	drop _merge
	
	save "${datapath}/EU-SILC/19 L-2023/masterP.dta", replace
	clear
	use "${datapath}/EU-SILC/19 L-2023/masterP.dta"
	
	merge 1:1 year upid country uhid using "${datapath}/EU-SILC/3 L-2007/2007P.dta"
	drop _merge
	
	save "${datapath}/EU-SILC/19 L-2023/masterP.dta", replace
	clear
	use "${datapath}/EU-SILC/19 L-2023/masterP.dta"
	
	merge 1:1 year upid country uhid using "${datapath}/EU-SILC/2 L-2006/2006P.dta"
	drop _merge
	
	save "${datapath}/EU-SILC/19 L-2023/masterP.dta", replace
	clear
	use "${datapath}/EU-SILC/19 L-2023/masterP.dta"
	
	merge 1:1 year upid country uhid using "${datapath}/EU-SILC/1 L-2005/2005P.dta"
	drop _merge
	
	/*eliminate variables from the R file*/
	drop rb010 rb010 rb020 rb030 rb040 rb060 rb060_f rb062 rb062_f rb063 rb063_f rb064 rb064_f rb070 rb070_f rb080 rb080_f rb090 rb090_f rb100 ///
	     rb100_f rb110 rb110_f rb120 rb120_f rb140 rb140_f rb150 rb150_f rb160 rb160_f rb170 rb170_f rb180 rb180_f rb190 rb190_f rb200 rb200_f ///
		 rb210 rb210_f rb220 rb220_f rb230 rb230_f rb240 rb240_f rb245 rb245_f rb250 rb250_f rb260 rb260_f rb270 rb270_f rx010 rx020 hid db010 ///
		 db020 db030 db040 db040_f db060 db060_f db062 db062_f db070 db070_f db075 db075_f db095 db095_f db100 db100_f db110 db110_f

	/*drop superflous variables */
	drop drpout_year* slctd_urtgrp* slctd_uhid*  merge* nrtgrp*  lgstgrp maxgrp drpout_year slctd_rtgrp 

	/* This is the personal data file (P) file 2005 - 2023 */
	save "${datapath}/EU-SILC/19 L-2023/masterP.dta", replace
