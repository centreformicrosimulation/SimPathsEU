/*******************************************************************************
SUMMARY — 01_create_masterD.do (2024 release, extended to 2023)
 
This file is based on the program from the above. It extends the logic beyond
2020 and no longer uses a program but a series of do files called in the master.
This was only to facilitate understanding of the code logic. 
 
This file builds the master household register (D) panel for EU-SILC 2005–2023.
Unlike the H, R, and P files, the masterD is assembled incrementally: each 
annual block appends its records directly into masterD.dta building the sample 
rather than saving intermediate files that are merged at the end. 

NOTE: The data in each release comes with all of the historic data for each 
current individual. Therefore there will be repeated observations across 
annual datasets if the individual has been observed more than once. This 
requires a procedure to identify and drop the duplicates. here the logic is to 
take the most recent data release that contains all avaialble information for 
individuals currently in the survey. Then moving backwards in time, add data
from the rotation group that is just about to exit the survey, i.e. the rotation 
group with the longest individual panels. By doing this each year you avoid 
adding duplicates. 

The file works as follows:

2023 block (master year):
   Reads all rotation groups. All groups are selected 
   (no filtering). Builds unique household (uhid) and rotation group (urtgrp) 
   identifiers that encode country, rotation group number, planned dropout year, 
   and household ID. Saves masterD.dta and 2023D.dta to the 19 L-2023 folder.

2022 block (and all earlier blocks):
   Reads the raw D data for the release year. 
   Counts rotation groups (nrtgrpYYYY) and identifies the longest rotation 
   groups (lgstgrp). 
   Builds uhid/urtgrp using the same logic as the 2023 block. 
   Merges against 2023D.dta (and for older blocks, against additional more 
   recent release files) to isolate records not already captured in a later 
   release (keep if _merge == 1). 
   Updates drpout_year, urtgrp, and uhid to be consistent with the most recent 
   release conventions. 
   Runs balance and duplicate checks to catch cross-release inconsistencies 
   (e.g. rotation groups changing numbers across releases).
   Merges the surviving records into masterD.dta and saves both the updated
   masterD.dta and a YYYYD.dta for use by downstream files (02, 03, 04).

Rolling window rule:
   Each block merges against the three releases immediately following it, 
   consistent with the 4-year rotation design (a group can extend at most 3 
   years beyond any given release). 

Output:
   masterD.dta — full panel 2005–2023, saved in 20 L-2023
   YYYYD.dta   — one file per release year, saved in the corresponding release 
				folder.
                 Used by 02_create_masterH.do, 03_create_masterR.do, 
				 04_create_masterP.do to select the correct sample for the H, 
				 R, and P files.
*/

	
/* D-FILES */


/* 2023 */
	/* open the 2023 Household register to get list of rotation groups with max obs and starting point for masterfile */
	clear
	set more off
	local filen : dir "${do_dir}/EU-SILC/19 L-2023/"  files "udb_l23d_ver*"
	display `filen'
	local filel "${datapath}/EU-SILC/19 L-2023/"
	display `"`filel'"'
	local fileln : display `"`filel'"' `filen'
  
	use `"`fileln'"', clear
	
	local new_var = lower("`var'")

    foreach var of varlist _all {
    	local new_var = lower("`var'")
    	cap rename `var' `new_var'
    }
	
	/* block Stata from displaying IDs in exponential format */ 
	tostring db030, replace
	gen year = db010
	gen country = db020
	gen hid = db030
	gen rotation_group = db075
	replace country = "EL" if country == "GR"
	sort country hid year
	
	/* count the number of rotational groups for each country in this release */
	bysort country rotation_group: gen nvals = _n == 1
	bysort country : egen nrtgrp2023 = total(nvals)
	drop nvals 
	
	/* mark selected rotation group (this is the most recent release, so all rotationgroups are selected) */
	gen slctd_rtgrp = rotation_group
	
	/* build household and rotationgroup IDs, unique across releases. contains country, rotation group, drouput year and hid */
	tostring rotation_group, generate(rotation_groupstr)
	egen maxyear = max(year) 
	bysort country rotation_group : egen minyear = min(year)
	gen years_cov = maxyear - minyear + 1
	gen drpout_year = maxyear
	replace drpout_year = drpout_year + 4 - years_cov
	
		/* check for rotation groups that ended earlier than the latest year*/
		bysort country rotation_group : egen maxyear_grp = max(year)
		replace drpout_year = maxyear_grp if maxyear_grp < maxyear
		
	tostring drpout_year, replace
	gen uhid = country + rotation_groupstr + drpout_year + hid
	gen urtgrp = country + rotation_groupstr + drpout_year
	drop rotation_groupstr maxyear_grp minyear years_cov maxyear_grp maxyear
	destring drpout_year, replace 
	
	/* for later checks */
	gen drpout_year2023 = drpout_year
	gen slctd_urtgrp2023 = urtgrp 	
	gen slctd_uhid2023 = uhid
	
	/* this is the masterfile to build the dataset on */
	gen merge2023 = 1
	save "${datapath}/EU-SILC/19 L-2023/masterD.dta", replace
	/* this is the the 2023D file for later control.*/
	drop merge2023
	save "${datapath}/EU-SILC/19 L-2023/2023D.dta", replace


/* 2022 */
	/* open the 2022 Household register to get data from rotational groups that are inactive in 2020 and their uhid */
	clear
	local filen : dir "${datapath}/EU-SILC/18 L-2022/"  files "udb_l22d_ver*"
	display `filen'
	local filel "${datapath}/EU-SILC/18 L-2022/"
	display `"`filel'"'
	local fileln : display `"`filel'"' `filen'
	
	use `"`fileln'"', clear
	
	local new_var = lower("`var'")

	 foreach var of varlist _all {
		local new_var = lower("`var'")
		cap rename `var' `new_var'
	}
	
	/* block Stata from displaying IDs in exponential format */
	tostring db030, replace
	gen year = db010
	gen country = db020
	gen hid = db030
	gen rotation_group = db075
	sort country hid year
	replace country = "EL" if country == "GR"
	
	/* count the number of rotational groups for each country in this release */
	bysort country rotation_group: gen nvals = _n == 1
	bysort country : egen nrtgrp2022 = total(nvals)
	drop nvals 
	
	/* get the rotation group(s) that cover most years - rotationl group to be added to create panel */
	bysort country rotation_group : egen maxyear = max(year) 
	bysort country rotation_group : egen minyear = min(year)
	gen years_cov = maxyear - minyear + 1
	bysort country : egen maxgrp = max(years_cov) 
	gen slctd_rtgrp = 0
	bysort country rotation_group: replace slctd_rtgrp = rotation_group if years_cov == maxgrp
	gen lgstgrp = 0
	bysort country rotation_group: replace lgstgrp = 1 if years_cov == maxgrp
	
	/* build household and rotationgroup IDs that are unique across releases */
	tostring rotation_group, generate(rotation_groupstr)
	gen drpout_year = 0
	replace drpout_year = maxyear + 4 - years_cov
	
		/* check for rotation groups that dropped out before planned */
		bysort country rotation_group : egen maxyear_grp = max(year)
		replace drpout_year = maxyear_grp if maxyear_grp < maxyear
		
	tostring drpout_year, replace
	gen uhid = country + rotation_groupstr + drpout_year + hid
	gen urtgrp = country + rotation_groupstr + drpout_year
	destring drpout_year, replace 	
	
		/* make sure all groups not observed in later releases are included. this accounts for daps in the data releases */
		sort year country rotation_group hid 
		merge m:m year country rotation_group using "${datapath}/EU-SILC/19 L-2023/2023D.dta" //merging on all 3 variables permits the inclusion of extended panels
		replace slctd_rtgrp = rotation_group if _merge == 1
				
		/* update urtgrp and uhid to account for later drop out year, allows for extended rotation panels */
		drop maxyear rotation_groupstr
		bysort country rotation_group: egen maxyear = max(drpout_year)
		replace drpout_year = maxyear 
		tostring drpout_year, replace 
		tostring rotation_group, generate(rotation_groupstr)
		replace uhid = country + rotation_groupstr + drpout_year + hid
		replace urtgrp = country + rotation_groupstr + drpout_year
		
	/* preserve observations to be appended (observations not found in later data releases whether from new households or due to extended panel) */
	keep if _merge == 1
	drop rotation_groupstr		
	drop _merge maxyear_grp minyear years_cov maxyear_grp maxyear
	destring drpout_year, replace 
	drop if slctd_rtgrp == 0
	
	/* for later checks */
	gen drpout_year2022 = drpout_year
	gen slctd_urtgrp2022 = urtgrp 	
	gen slctd_uhid2022 = uhid
	
	/* merge to masterfile */
	merge 1:1 year uhid using "${datapath}/EU-SILC/19 L-2023/masterD.dta"
	
	/* check for duplicates caused by same rotational groups changing numbers across releases - in same hid, different rotation_group. Catches the LV cases 2020-2019.*/
		duplicates report year country hid
		duplicates tag year country hid, generate(test2)
		tab country year if test2 != 0 	
		tab urtgrp year  if test2 != 0
		
			/* check if the problem regards a large portion of the rotational group, if the portion is small ignore */
			gen tag1 = 0 
			replace tag1 = 1 if test2 != 0 
			bysort year country urtgrp : egen ndups = total(tag1)
			gen tag2 = 1 
			bysort year country urtgrp : egen tot = total(tag2)
			gen rdups = ndups / tot
			gen tag3 = 0 
			replace tag3 = 1 if rdups > 0.5
			drop tag1 tag2 ndups tot rdups
			
			/* extend selection to whole rotational group */
			bysort year country urtgrp : egen taga = max(tag3)
			drop tag3
			
			/* check if the rotational group with duplicates is the one covering most years in current release. If yes ignore. Still leaves us with duplicates? E.g. Pt */ 
			tab urtgrp year if taga == 1  & lgstgrp == 0 & _merge == 1
			drop if taga == 1 & lgstgrp == 0 & _merge == 1
			drop  test2 taga
			
			/* check for unbalances */
			bysort country : egen test3 = total(nrtgrp2023)
			replace test3 = 0 if test3 == .
			tab urtgrp year if ( test3 != 0 & lgstgrp == 0 & _merge == 1 )  	
			drop if (test3 != 0 & lgstgrp == 0 & _merge == 1)
			drop test3
			
		/* this is the updated masterfile */
		gen merge2022 = _merge
		drop _merge
		save "${datapath}/EU-SILC/19 L-2023/masterD.dta", replace
		
		/* this is 2022D file for later control */
		keep if merge2022 == 1 
		drop merge2022
		save "${datapath}/EU-SILC/18 L-2022/2022D.dta", replace
		
		
/* 2021 */
	/* open the 2021 Household register to get data from rotational groups inactive in 2019 and their uhid */ 
	clear
	local filen : dir "${datapath}/EU-SILC/17 L-2021/"  files "udb_l21d_ver*"
	display `filen'
	local filel "${datapath}/EU-SILC/17 L-2021/"
	display `"`filel'"'
	local fileln : display `"`filel'"' `filen'
			
	use `"`fileln'"', clear
	
	local new_var = lower("`var'")

	 foreach var of varlist _all {
		local new_var = lower("`var'")
		cap rename `var' `new_var'
	}
		
	/* block Stata from displaying IDs in exponential format */ 
	tostring db030, replace
	gen year = db010
	gen country = db020
	gen hid = db030
	gen rotation_group = db075 
	sort country hid year
	replace country = "EL" if country == "GR"
	
	/* count the number of rotational groups for each country in this release */
	bysort country rotation_group: gen nvals = _n == 1
	bysort country : egen nrtgrp2021 = total(nvals)
	drop nvals 
	
	/* get the rotation group(s) that cover most years - rotational group to be added to create panel */
	bysort country rotation_group : egen maxyear = max(year) 
	bysort country rotation_group : egen minyear = min(year)
	gen years_cov = maxyear - minyear + 1
	bysort country : egen maxgrp = max(years_cov) 
	gen slctd_rtgrp = 0
	bysort country rotation_group: replace slctd_rtgrp = rotation_group if years_cov == maxgrp 
	gen lgstgrp = 0
	bysort country rotation_group: replace lgstgrp = 1 if years_cov == maxgrp
	
	/* build household and rotationgroup IDs that are unique across releases */
	tostring rotation_group, generate(rotation_groupstr)
	gen drpout_year = 0
	replace drpout_year = maxyear + 4 - years_cov
	
		/* check for rotation groups that dropped out before planned */
		bysort country rotation_group : egen maxyear_grp = max(year)
		replace drpout_year = maxyear_grp if maxyear_grp < maxyear
	
	tostring drpout_year, replace
	gen uhid = country + rotation_groupstr + drpout_year + hid
	gen urtgrp = country + rotation_groupstr + drpout_year
	destring drpout_year, replace 	
	
		/* check if any groups have been selected in the more recent 2019 release ("prolonged rotation groups") Ensure rotation groups that are not in next data release are selected to be preserved */
		sort year country rotation_group hid 
		merge m:m year country rotation_group using "${datapath}/EU-SILC/18 L-2022/2022D.dta"
		replace slctd_rtgrp = rotation_group if _merge == 1
		
		/* tag rotation groups that have already been selected in the more recent release in some years (overlapping) [How France is dealt with - 9 yr rotational panel but onyl 4 years worth of data released each year] */
		gen atag = 0
		replace atag = 1 if _merge == 3
		bysort country rotation_group : egen btag = max(atag) 
		bysort country rotation_group : egen ndrpoy = max(drpout_year2022)
		replace drpout_year = ndrpoy if btag == 1
		drop atag btag ndrpoy
		
		/* update IDs urtgrp and uhid so that "prolonged rotation groups" maintain their urtgrp across different releases - update the drpout_year to the latest recorded */ 
		tostring drpout_year, replace
		replace uhid = country + rotation_groupstr + drpout_year + hid
		replace urtgrp = country + rotation_groupstr + drpout_year
		destring drpout_year, replace	
		drop rotation_groupstr maxyear_grp minyear years_cov maxgrp maxyear_grp maxyear
		
		/* drop overlapping rotation group years and data from the more recent release */
		keep if _merge == 1 
		drop _merge 
		
		/* check if any selected groups have been selected in the more recent 2020 release ("prolonged rotation groups") */
		merge m:m year country urtgrp using "${datapath}/EU-SILC/19 L-2023/2023D.dta"
		replace slctd_rtgrp = rotation_group if _merge == 1
		keep if _merge == 1 
		drop _merge 
	
	/* preserve observations to be appended */
	destring drpout_year, replace 
	drop if slctd_rtgrp == 0
	
	/* for later checks */
	gen drpout_year2021 = drpout_year
	gen slctd_urtgrp2021 = urtgrp 	
	gen slctd_uhid2021 = uhid
	
	/* merge to masterfile */
	merge 1:1 year uhid using "${datapath}/EU-SILC/19 L-2023/masterD.dta"
	
		/* check for duplicates caused by same rotational groups changing code across releases - in same hid, different rotation_group */
		duplicates report year country hid
		duplicates tag year country hid, generate(test2)
		tab country year if test2 != 0 	
		tab urtgrp year  if test2 != 0 
		
			/* check if the problem regards a large portion of the rotational group, if the portion is small ignor e */
			gen tag1 = 0 
			replace tag1 = 1 if test2 != 0 
			bysort year country urtgrp : egen ndups = total(tag1)
			gen tag2 = 1 
			bysort year country urtgrp : egen tot = total(tag2)
			gen rdups = ndups / tot
			gen tag3 = 0 
			replace tag3 = 1 if rdups > 0.5
			drop tag1 tag2 ndups tot rdups
			
			/* extend selection to whole rotational group */
			bysort year country urtgrp : egen taga = max(tag3)
			drop tag3
			
			/* check if the rotational group with duplicates is the one covering most years in current release. If yes ignore */
			tab urtgrp year if taga == 1  & lgstgrp == 0 & _merge == 1
			drop if taga == 1 & lgstgrp == 0 & _merge == 1
			drop  test2 taga
			
			/* check for unbalances */
			bysort country : egen test3 = total(nrtgrp2022)
			bysort country : egen test4 = total(nrtgrp2023)
			replace test3 = 0 if test3 == .
			replace test4 = 0 if test4 == .
			tab urtgrp year if ( test3 != 0 & lgstgrp == 0 & _merge == 1 ) & ( test4 != 0 & lgstgrp == 0 & _merge == 1 ) 	
			drop if ( test3 != 0 & lgstgrp == 0 & _merge == 1 ) & ( test4 != 0 & lgstgrp == 0 & _merge == 1 )
			drop test3 test4
			
		/* this is the updated masterfile */
		gen merge2021 = _merge
		drop _merge
		save "${datapath}/EU-SILC/19 L-2023/masterD.dta", replace
		
		/* this is 2021D file for later control */
		keep if merge2021 == 1 
		drop merge2021
		save "${datapath}/EU-SILC/17 L-2021/2021D.dta", replace

/* 2020 */
	/* open the 2020 Household register to get data from rotational groups inactive in more recent releases and their uhid */
	clear
	local filen : dir "${datapath}/EU-SILC/16 L-2020/"  files "udb_l20d_ver*"
	display `filen'
	local filel "${datapath}/EU-SILC/16 L-2020/"
	display `"`filel'"'
	local fileln : display `"`filel'"' `filen'
	
	use `"`fileln'"', clear
	
	local new_var = lower("`var'")

	foreach var of varlist _all {
		local new_var = lower("`var'")
		cap rename `var' `new_var'
	}
	
	/* block Stata from displaying IDs in exponential format */
	tostring db030, replace
	gen year = db010
	gen country = db020
	gen hid = db030
	gen rotation_group = db075
	sort country hid year
	replace country = "EL" if country == "GR"
	
	/* count the number of rotational groups for each country in this release */
	bysort country rotation_group: gen nvals = _n == 1
	bysort country : egen nrtgrp2020 = total(nvals)
	drop nvals 
	
	/* get the rotation group(s) that cover most years */
	bysort country rotation_group : egen maxyear = max(year) 
	bysort country rotation_group : egen minyear = min(year)
	gen years_cov = maxyear - minyear + 1
	bysort country : egen maxgrp = max(years_cov) 
	gen slctd_rtgrp = 0
	bysort country rotation_group: replace slctd_rtgrp = rotation_group if years_cov == maxgrp 
	gen lgstgrp = 0
	bysort country rotation_group: replace lgstgrp = 1 if years_cov == maxgrp
	
	/* build household and rotationgroup IDs that are unique across releases */
	tostring rotation_group, generate(rotation_groupstr)
	gen drpout_year = 0
	replace drpout_year = maxyear + 4 - years_cov
	
		/* check for rotation groups that dropped out before planned */
		bysort country rotation_group : egen maxyear_grp = max(year)
		replace drpout_year = maxyear_grp if maxyear_grp < maxyear
		
	tostring drpout_year, replace
	gen uhid = country + rotation_groupstr + drpout_year + hid
	gen urtgrp = country + rotation_groupstr + drpout_year
	destring drpout_year, replace 	
	
		/* check if any selected groups have been selected in the more recent 2021 release ("prolonged rotation groups") */
		sort year country rotation_group hid 
		merge m:m year country rotation_group using "${datapath}/EU-SILC/17 L-2021/2021D.dta"
		replace slctd_rtgrp = rotation_group if _merge == 1
		
		/* tag rotation groups that have already been selected in the more recent release in some years (overlapping) */
		gen atag = 0
		replace atag = 1 if _merge == 3
		bysort country rotation_group : egen btag = max(atag) 
		bysort country rotation_group : egen ndrpoy = max(drpout_year2021)
		replace drpout_year = ndrpoy if btag == 1
		drop atag btag ndrpoy
		
		/* update urtgrp and uhid so that "prolonged rotation groups" maintain their urtgrp across different releases */
		tostring drpout_year, replace
		replace uhid = country + rotation_groupstr + drpout_year + hid
		replace urtgrp = country + rotation_groupstr + drpout_year
		destring drpout_year, replace	
		drop rotation_groupstr maxyear_grp minyear years_cov maxgrp maxyear_grp maxyear
		
		/* drop overlapping rotation group years and data from the more recent release */
		keep if _merge == 1 
		drop _merge 
		
		/* check if any selected groups have been selected in the more recent 2022 release ("prolonged rotation groups") */
		merge m:m year country urtgrp using "${datapath}/EU-SILC/18 L-2022/2022D.dta"
		replace slctd_rtgrp = rotation_group if _merge == 1
		keep if _merge == 1 
		drop _merge
		
		/* check if any selected groups have been selected in the more recent 2023 release ("prolonged rotation groups") */
		merge m:m year country urtgrp using "${datapath}/EU-SILC/19 L-2023/2023D.dta"
		replace slctd_rtgrp = rotation_group if _merge == 1
		keep if _merge == 1 
		drop _merge
	destring drpout_year, replace 
	drop if slctd_rtgrp == 0
	
	/* for later checks */
	gen drpout_year2020 = drpout_year
	gen slctd_urtgrp2020 = urtgrp 	
	gen slctd_uhid2020 = uhid
	
	/* merge to masterfile */
	merge 1:1 year uhid using "${datapath}/EU-SILC/19 L-2023/masterD.dta"
	
		/* check for duplicates caused by same rotational groups in terms of same hid, different rotation_group */
		duplicates report year country hid
		duplicates tag year country hid, generate(test2)
		tab country year if test2 != 0 	
		tab urtgrp year  if test2 != 0 
		
			/* check if the problem regards a large portion of the rotational group, if the portion is small ignore */
			gen tag1 = 0 
			replace tag1 = 1 if test2 != 0 
			bysort year country urtgrp : egen ndups = total(tag1)
			gen tag2 = 1 
			bysort year country urtgrp : egen tot = total(tag2)
			gen rdups = ndups / tot
			gen tag3 = 0 
			replace tag3 = 1 if rdups > 0.5
			drop tag1 tag2 ndups tot rdups
			
			/* extend selection to whole rotational group */
			bysort year country urtgrp : egen taga = max(tag3)
			drop tag3
			
			/* check if the rotational group with duplicates is the one covering most years in current release. If yes ignore */
			tab urtgrp year if taga == 1  & lgstgrp == 0 & _merge == 1
			drop if taga == 1 & lgstgrp == 0 & _merge == 1
			drop  test2 taga
			
			/* check for unbalances */
			bysort country : egen test3 = total(nrtgrp2021)
			bysort country : egen test4 = total(nrtgrp2022)
			bysort country : egen test5 = total(nrtgrp2023)
			replace test3 = 0 if test3 == .
			replace test4 = 0 if test4 == .
			replace test5 = 0 if test5 == .
			tab urtgrp year if ( test3 != 0 & lgstgrp == 0 & _merge == 1 ) & ( test4 != 0 & lgstgrp == 0 & _merge == 1 ) &( test5 != 0 & lgstgrp == 0 & _merge == 1 )	
			drop if ( test3 != 0 & lgstgrp == 0 & _merge == 1 ) & ( test4 != 0 & lgstgrp == 0 & _merge == 1 ) & ( test5 != 0 & lgstgrp == 0 & _merge == 1 )
			drop test3 test4 test5
			
		/* this is the updated masterfile */
		gen merge2020 = _merge
		drop _merge
		save "${datapath}/EU-SILC/19 L-2023/masterD.dta", replace
		
		/* this is 2020D file for later control */
		keep if merge2020 == 1 
		drop merge2020
		save "${datapath}/EU-SILC/16 L-2020/2020D.dta", replace

		
/* 2019 */
	/* open the 2019 Household register to get data from rotational groups inactive in more recent releases and their uhid */ 
	clear
	local filen : dir "${datapath}/EU-SILC/15 L-2019/"  files "udb_l19d_ver*"
	display `filen'
	local filel "${datapath}/EU-SILC/15 L-2019/"
	display `"`filel'"'
	local fileln : display `"`filel'"' `filen'


	use `"`fileln'"', clear
	
	local new_var = lower("`var'")

    foreach var of varlist _all {
    	local new_var = lower("`var'")
    	cap rename `var' `new_var'
    }
	
	/* block Stata from displaying IDs in exponential format */
	tostring db030, replace
	gen year = db010
	gen country = db020
	gen hid = db030
	gen rotation_group = db075
	sort country hid year
	replace country = "EL" if country == "GR"
	
	/* count the number of rotational groups for each country in this release */
	bysort country rotation_group: gen nvals = _n == 1
	bysort country : egen nrtgrp2019 = total(nvals)
	drop nvals 
	
	/* get the rotation group(s) that cover most years */
	bysort country rotation_group : egen maxyear = max(year) 
	bysort country rotation_group : egen minyear = min(year)
	gen years_cov = maxyear - minyear + 1
	bysort country : egen maxgrp = max(years_cov) 
	gen slctd_rtgrp = 0
	bysort country rotation_group: replace slctd_rtgrp = rotation_group if years_cov == maxgrp 
	gen lgstgrp = 0
	bysort country rotation_group: replace lgstgrp = 1 if years_cov == maxgrp
	
	/* build household and rotationgroup IDs that are unique across releases */
	tostring rotation_group, generate(rotation_groupstr)
	gen drpout_year = 0
	replace drpout_year = maxyear + 4 - years_cov
	
		/* check for rotation groups that dropped out before planned */
		bysort country rotation_group : egen maxyear_grp = max(year)
		replace drpout_year = maxyear_grp if maxyear_grp < maxyear
		
	tostring drpout_year, replace
	gen uhid = country + rotation_groupstr + drpout_year + hid
	gen urtgrp = country + rotation_groupstr + drpout_year
	destring drpout_year, replace 	
	
		/* check if any selected groups have been selected in the more recent 2020 release ("prolonged rotation groups") */
		sort year country rotation_group hid 
		merge m:m year country rotation_group using "${datapath}/EU-SILC/16 L-2020/2020D.dta"
		replace slctd_rtgrp = rotation_group if _merge == 1
		
		/* tag rotation groups that have already been selected in the more recent release in some years (overlapping) */
		gen atag = 0
		replace atag = 1 if _merge == 3
		bysort country rotation_group : egen btag = max(atag) 
		bysort country rotation_group : egen ndrpoy = max(drpout_year2020)
		replace drpout_year = ndrpoy if btag == 1
		drop atag btag ndrpoy
		
		/* update urtgrp and uhid so that "prolonged rotation groups" maintain their urtgrp across different releases */
		tostring drpout_year, replace
		replace uhid = country + rotation_groupstr + drpout_year + hid
		replace urtgrp = country + rotation_groupstr + drpout_year
		destring drpout_year, replace	
		drop rotation_groupstr maxyear_grp minyear years_cov maxgrp maxyear_grp maxyear
		
		/* drop overlapping rotation group years and data from the more recent release */
		keep if _merge == 1 
		drop _merge 
		
		/* check if any selected groups have been selected in the more recent 2021 release ("prolonged rotation groups") */
		merge m:m year country urtgrp using "${datapath}/EU-SILC/17 L-2021/2021D.dta"
		replace slctd_rtgrp = rotation_group if _merge == 1
		keep if _merge == 1 
		drop _merge
		
		/* check if any selected groups have been selected in the more recent 2022 release ("prolonged rotation groups") */
		merge m:m year country urtgrp using "${datapath}/EU-SILC/18 L-2022/2022D.dta"
		replace slctd_rtgrp = rotation_group if _merge == 1
		keep if _merge == 1 
		drop _merge
	destring drpout_year, replace 
	drop if slctd_rtgrp == 0
	
	/* for later checks */
	gen drpout_year2019 = drpout_year
	gen slctd_urtgrp2019 = urtgrp 	
	gen slctd_uhid2019 = uhid
	
	/* merge to masterfile */
	merge 1:1 year uhid using "${datapath}/EU-SILC/19 L-2023/masterD.dta"
	
		/* check for duplicates caused by same rotational groups in terms of same hid, different rotation_group */
		duplicates report year country hid
		duplicates tag year country hid, generate(test2)
		tab country year if test2 != 0 	
		tab urtgrp year  if test2 != 0 
		
			/* check if the problem regards a large portion of the rotational group, if the portion is small ignore */
			gen tag1 = 0 
			replace tag1 = 1 if test2 != 0 
			bysort year country urtgrp : egen ndups = total(tag1)
			gen tag2 = 1 
			bysort year country urtgrp : egen tot = total(tag2)
			gen rdups = ndups / tot
			gen tag3 = 0 
			replace tag3 = 1 if rdups > 0.5
			drop tag1 tag2 ndups tot rdups
			
			/* extend selection to whole rotational group */
			bysort year country urtgrp : egen taga = max(tag3)
			drop tag3
			
			/* check if the rotational group with duplicates is the one covering most years in current release. If yes ignore */
			tab urtgrp year if taga == 1  & lgstgrp == 0 & _merge == 1
			drop if taga == 1 & lgstgrp == 0 & _merge == 1
			drop  test2 taga
			
			/* check for unbalances */
			bysort country : egen test3 = total(nrtgrp2020)
			bysort country : egen test4 = total(nrtgrp2021)
			bysort country : egen test5 = total(nrtgrp2022)
			replace test3 = 0 if test3 == .
			replace test4 = 0 if test4 == .
			replace test5 = 0 if test5 == .
			tab urtgrp year if ( test3 != 0 & lgstgrp == 0 & _merge == 1 ) & ( test4 != 0 & lgstgrp == 0 & _merge == 1 ) &( test5 != 0 & lgstgrp == 0 & _merge == 1 )
			drop if ( test3 != 0 & lgstgrp == 0 & _merge == 1 ) & ( test4 != 0 & lgstgrp == 0 & _merge == 1 ) &( test5 != 0 & lgstgrp == 0 & _merge == 1 )
			drop test3 test4 test5
			
		/* this is the updated masterfile */
		gen merge2019 = _merge
		drop _merge
		save "${datapath}/EU-SILC/19 L-2023/masterD.dta", replace
		
		/* this is 2016D file for later control */
		keep if merge2019 == 1 
		drop merge2019
		save "${datapath}/EU-SILC/15 L-2019/2019D.dta", replace

		
/* 2018 */
	/* open the 2018 Household register to get data from rotational groups inactive in 2019 and their uhid */ 
	clear
	local filen : dir "${datapath}/EU-SILC/14 L-2018/"  files "udb_l18d_ver*"
	display `filen'
	local filel "${datapath}/EU-SILC/14 L-2018/"
	display `"`filel'"'
	local fileln : display `"`filel'"' `filen'
			
	use `"`fileln'"', clear
	
	local new_var = lower("`var'")

	 foreach var of varlist _all {
		local new_var = lower("`var'")
		cap rename `var' `new_var'
	}
		
	/* block Stata from displaying IDs in exponential format */ 
	tostring db030, replace
	gen year = db010
	gen country = db020
	gen hid = db030
	gen rotation_group = db075 
	sort country hid year
	replace country = "EL" if country == "GR"
	
	/* count the number of rotational groups for each country in this release */
	bysort country rotation_group: gen nvals = _n == 1
	bysort country : egen nrtgrp2018 = total(nvals)
	drop nvals 
	
	/* get the rotation group(s) that cover most years - rotational group to be added to create panel */
	bysort country rotation_group : egen maxyear = max(year) 
	bysort country rotation_group : egen minyear = min(year)
	gen years_cov = maxyear - minyear + 1
	bysort country : egen maxgrp = max(years_cov) 
	gen slctd_rtgrp = 0
	bysort country rotation_group: replace slctd_rtgrp = rotation_group if years_cov == maxgrp 
	gen lgstgrp = 0
	bysort country rotation_group: replace lgstgrp = 1 if years_cov == maxgrp
	
	/* build household and rotationgroup IDs that are unique across releases */
	tostring rotation_group, generate(rotation_groupstr)
	gen drpout_year = 0
	replace drpout_year = maxyear + 4 - years_cov
	
		/* check for rotation groups that dropped out before planned */
		bysort country rotation_group : egen maxyear_grp = max(year)
		replace drpout_year = maxyear_grp if maxyear_grp < maxyear
	
	tostring drpout_year, replace
	gen uhid = country + rotation_groupstr + drpout_year + hid
	gen urtgrp = country + rotation_groupstr + drpout_year
	destring drpout_year, replace 	
	
		/* check if any groups have been selected in the more recent 2019 release ("prolonged rotation groups") Ensure rotation groups that are not in next data release are selected to be preserved */
		sort year country rotation_group hid 
		merge m:m year country rotation_group using "${datapath}/EU-SILC/15 L-2019/2019D.dta"
		replace slctd_rtgrp = rotation_group if _merge == 1
		
		/* tag rotation groups that have already been selected in the more recent release in some years (overlapping) [How France is dealt with - 9 yr rotational panel but onyl 4 years worth of data released each year] */
		gen atag = 0
		replace atag = 1 if _merge == 3
		bysort country rotation_group : egen btag = max(atag) 
		bysort country rotation_group : egen ndrpoy = max(drpout_year2019)
		replace drpout_year = ndrpoy if btag == 1
		drop atag btag ndrpoy
		
		/* update IDs urtgrp and uhid so that "prolonged rotation groups" maintain their urtgrp across different releases - update the drpout_year to the latest recorded */
		tostring drpout_year, replace
		replace uhid = country + rotation_groupstr + drpout_year + hid
		replace urtgrp = country + rotation_groupstr + drpout_year
		destring drpout_year, replace	
		drop rotation_groupstr maxyear_grp minyear years_cov maxgrp maxyear_grp maxyear
		
		/* drop overlapping rotation group years and data from the more recent release */
		keep if _merge == 1 
		drop _merge 
		
		/* check if any selected groups have been selected in the more recent 2020 release ("prolonged rotation groups") */
		merge m:m year country urtgrp using "${datapath}/EU-SILC/16 L-2020/2020D.dta"
		replace slctd_rtgrp = rotation_group if _merge == 1
		keep if _merge == 1 
		drop _merge 
		
		/* check if any selected groups have been selected in the more recent 2021 release ("prolonged rotation groups") */
		merge m:m year country urtgrp using "${datapath}/EU-SILC/17 L-2021/2021D.dta"
		replace slctd_rtgrp = rotation_group if _merge == 1
		keep if _merge == 1 
		drop _merge 
	
	/* preserve observations to be appended */
	destring drpout_year, replace 
	drop if slctd_rtgrp == 0
	
	/* for later checks */
	gen drpout_year2018 = drpout_year
	gen slctd_urtgrp2018 = urtgrp 	
	gen slctd_uhid2018 = uhid
	
	/* merge to masterfile */
	merge 1:1 year uhid using "${datapath}/EU-SILC/19 L-2023/masterD.dta"
	
		/* check for duplicates caused by same rotational groups changing code across releases - in same hid, different rotation_group */
		duplicates report year country hid
		duplicates tag year country hid, generate(test2)
		tab country year if test2 != 0 	
		tab urtgrp year  if test2 != 0 
		
			/* check if the problem regards a large portion of the rotational group, if the portion is small ignore */
			gen tag1 = 0 
			replace tag1 = 1 if test2 != 0 
			bysort year country urtgrp : egen ndups = total(tag1)
			gen tag2 = 1 
			bysort year country urtgrp : egen tot = total(tag2)
			gen rdups = ndups / tot
			gen tag3 = 0 
			replace tag3 = 1 if rdups > 0.5
			drop tag1 tag2 ndups tot rdups
			
			/* extend selection to whole rotational group */
			bysort year country urtgrp : egen taga = max(tag3)
			drop tag3
			
			/* check if the rotational group with duplicates is the one covering most years in current release. If yes ignore */
			tab urtgrp year if taga == 1  & lgstgrp == 0 & _merge == 1
			drop if taga == 1 & lgstgrp == 0 & _merge == 1
			drop  test2 taga
			
			/* check for unbalances */
			bysort country : egen test3 = total(nrtgrp2019)
			bysort country : egen test4 = total(nrtgrp2020)
			bysort country : egen test5 = total(nrtgrp2021)
			replace test3 = 0 if test3 == .
			replace test4 = 0 if test4 == .
			replace test5 = 0 if test5 == .
			tab urtgrp year if ( test3 != 0 & lgstgrp == 0 & _merge == 1 ) & ( test4 != 0 & lgstgrp == 0 & _merge == 1 ) &( test5 != 0 & lgstgrp == 0 & _merge == 1 )
			drop if ( test3 != 0 & lgstgrp == 0 & _merge == 1 ) & ( test4 != 0 & lgstgrp == 0 & _merge == 1 ) &( test5 != 0 & lgstgrp == 0 & _merge == 1 )
			drop test3 test4 test5

		/* this is the updated masterfile */
		gen merge2018 = _merge
		drop _merge
		save "${datapath}/EU-SILC/19 L-2023/masterD.dta", replace
		
		/* this is 2018D file for later control */
		keep if merge2018 == 1 
		drop merge2018
		save "${datapath}/EU-SILC/14 L-2018/2018D.dta", replace
	

/* 2017 */
	/* open the 2017 Household register to get data from rotational groups inactive in more recent releases and their uhid */
	clear
	local filen : dir "${datapath}/EU-SILC/13 L-2017/"  files "udb_l17d_ver*"
	display `filen'
	local filel "${datapath}/EU-SILC/13 L-2017/"
	display `"`filel'"'
	local fileln : display `"`filel'"' `filen'
	
	use `"`fileln'"', clear
	
	local new_var = lower("`var'")

	foreach var of varlist _all {
		local new_var = lower("`var'")
		cap rename `var' `new_var'
	}
	
	/* block Stata from displaying IDs in exponential format */
	tostring db030, replace
	gen year = db010
	gen country = db020
	gen hid = db030
	gen rotation_group = db075
	sort country hid year
	replace country = "EL" if country == "GR"
	
	/* count the number of rotational groups for each country in this release */
	bysort country rotation_group: gen nvals = _n == 1
	bysort country : egen nrtgrp2017 = total(nvals)
	drop nvals 
	
	/* get the rotation group(s) that cover most years */
	bysort country rotation_group : egen maxyear = max(year) 
	bysort country rotation_group : egen minyear = min(year)
	gen years_cov = maxyear - minyear + 1
	bysort country : egen maxgrp = max(years_cov) 
	gen slctd_rtgrp = 0
	bysort country rotation_group: replace slctd_rtgrp = rotation_group if years_cov == maxgrp 
	gen lgstgrp = 0
	bysort country rotation_group: replace lgstgrp = 1 if years_cov == maxgrp
	
	/* build household and rotationgroup IDs that are unique across releases */
	tostring rotation_group, generate(rotation_groupstr)
	gen drpout_year = 0
	replace drpout_year = maxyear + 4 - years_cov
	
		/* check for rotation groups that dropped out before planned */
		bysort country rotation_group : egen maxyear_grp = max(year)
		replace drpout_year = maxyear_grp if maxyear_grp < maxyear
		
	tostring drpout_year, replace
	gen uhid = country + rotation_groupstr + drpout_year + hid
	gen urtgrp = country + rotation_groupstr + drpout_year
	destring drpout_year, replace 	
	
		/* check if any selected groups have been selected in the more recent 2018 release ("prolonged rotation groups") */
		sort year country rotation_group hid 
		merge m:m year country rotation_group using "${datapath}/EU-SILC/14 L-2018/2018D.dta"
		replace slctd_rtgrp = rotation_group if _merge == 1
		
		/* tag rotation groups that have already been selected in the more recent release in some years (overlapping) */
		gen atag = 0
		replace atag = 1 if _merge == 3
		bysort country rotation_group : egen btag = max(atag) 
		bysort country rotation_group : egen ndrpoy = max(drpout_year2018)
		replace drpout_year = ndrpoy if btag == 1
		drop atag btag ndrpoy
		
		/* update urtgrp and uhid so that "prolonged rotation groups" maintain their urtgrp across different releases */
		tostring drpout_year, replace
		replace uhid = country + rotation_groupstr + drpout_year + hid
		replace urtgrp = country + rotation_groupstr + drpout_year
		destring drpout_year, replace	
		drop rotation_groupstr maxyear_grp minyear years_cov maxgrp maxyear_grp maxyear
		
		/* drop overlapping rotation group years and data from the more recent release */
		keep if _merge == 1 
		drop _merge 
		
		/* check if any selected groups have been selected in the more recent 2019 release ("prolonged rotation groups") */
		merge m:m year country urtgrp using "${datapath}/EU-SILC/15 L-2019/2019D.dta"
		replace slctd_rtgrp = rotation_group if _merge == 1
		keep if _merge == 1 
		drop _merge
		
		/* check if any selected groups have been selected in the more recent 2020 release ("prolonged rotation groups") */
		merge m:m year country urtgrp using "${datapath}/EU-SILC/16 L-2020/2020D.dta"
		replace slctd_rtgrp = rotation_group if _merge == 1
		keep if _merge == 1 
		drop _merge
	destring drpout_year, replace 
	drop if slctd_rtgrp == 0
	
	/* for later checks */
	gen drpout_year2017 = drpout_year
	gen slctd_urtgrp2017 = urtgrp 	
	gen slctd_uhid2017 = uhid
	
	/* merge to masterfile */
	merge 1:1 year uhid using "${datapath}/EU-SILC/19 L-2023/masterD.dta"
	
		/* check for duplicates caused by same rotational groups in terms of same hid, different rotation_group */
		duplicates report year country hid
		duplicates tag year country hid, generate(test2)
		tab country year if test2 != 0 	
		tab urtgrp year  if test2 != 0 
		
			/* check if the problem regards a large portion of the rotational group, if the portion is small ignore */
			gen tag1 = 0 
			replace tag1 = 1 if test2 != 0 
			bysort year country urtgrp : egen ndups = total(tag1)
			gen tag2 = 1 
			bysort year country urtgrp : egen tot = total(tag2)
			gen rdups = ndups / tot
			gen tag3 = 0 
			replace tag3 = 1 if rdups > 0.5
			drop tag1 tag2 ndups tot rdups
			
			/* extend selection to whole rotational group */
			bysort year country urtgrp : egen taga = max(tag3)
			drop tag3
			
			/* check if the rotational group with duplicates is the one covering most years in current release. If yes ignore */
			tab urtgrp year if taga == 1  & lgstgrp == 0 & _merge == 1
			drop if taga == 1 & lgstgrp == 0 & _merge == 1
			drop  test2 taga
			
			/* check for unbalances */
			bysort country : egen test3 = total(nrtgrp2018)
			bysort country : egen test4 = total(nrtgrp2019)
			bysort country : egen test5 = total(nrtgrp2020)
			replace test3 = 0 if test3 == .
			replace test4 = 0 if test4 == .
			replace test5 = 0 if test5 == .
			tab urtgrp year if ( test3 != 0 & lgstgrp == 0 & _merge == 1 ) & ( test4 != 0 & lgstgrp == 0 & _merge == 1 ) &( test5 != 0 & lgstgrp == 0 & _merge == 1 )	
			drop if ( test3 != 0 & lgstgrp == 0 & _merge == 1 ) & ( test4 != 0 & lgstgrp == 0 & _merge == 1 ) & ( test5 != 0 & lgstgrp == 0 & _merge == 1 )
			drop test3 test4 test5
			
		/* this is the updated masterfile */
		gen merge2017 = _merge
		drop _merge
		save "${datapath}/EU-SILC/19 L-2023/masterD.dta", replace
		
		/* this is 2017D file for later control */
		keep if merge2017 == 1 
		drop merge2017
		save "${datapath}/EU-SILC/13 L-2017/2017D.dta", replace


/* 2016 */
	/* open the 2016 Household register to get data from rotational groups inactive in more recent releases and their uhid */ 
	clear
	local filen : dir "${datapath}/EU-SILC/12 L-2016/"  files "udb_l16d_ver*"
	display `filen'
	local filel "${datapath}/EU-SILC/12 L-2016/"
	display `"`filel'"'
	local fileln : display `"`filel'"' `filen'


	use `"`fileln'"', clear
	
	local new_var = lower("`var'")

    foreach var of varlist _all {
    	local new_var = lower("`var'")
    	cap rename `var' `new_var'
    }
	
	/* block Stata from displaying IDs in exponential format */
	tostring db030, replace
	gen year = db010
	gen country = db020
	gen hid = db030
	gen rotation_group = db075
	sort country hid year
	replace country = "EL" if country == "GR"
	
	/* count the number of rotational groups for each country in this release */
	bysort country rotation_group: gen nvals = _n == 1
	bysort country : egen nrtgrp2016 = total(nvals)
	drop nvals 
	
	/* get the rotation group(s) that cover most years */
	bysort country rotation_group : egen maxyear = max(year) 
	bysort country rotation_group : egen minyear = min(year)
	gen years_cov = maxyear - minyear + 1
	bysort country : egen maxgrp = max(years_cov) 
	gen slctd_rtgrp = 0
	bysort country rotation_group: replace slctd_rtgrp = rotation_group if years_cov == maxgrp 
	gen lgstgrp = 0
	bysort country rotation_group: replace lgstgrp = 1 if years_cov == maxgrp
	
	/* build household and rotationgroup IDs that are unique across releases */
	tostring rotation_group, generate(rotation_groupstr)
	gen drpout_year = 0
	replace drpout_year = maxyear + 4 - years_cov
	
		/* check for rotation groups that dropped out before planned */
		bysort country rotation_group : egen maxyear_grp = max(year)
		replace drpout_year = maxyear_grp if maxyear_grp < maxyear
		
	tostring drpout_year, replace
	gen uhid = country + rotation_groupstr + drpout_year + hid
	gen urtgrp = country + rotation_groupstr + drpout_year
	destring drpout_year, replace 	
	
		/* check if any selected groups have been selected in the more recent 2017 release ("prolonged rotation groups") */
		sort year country rotation_group hid 
		merge m:m year country rotation_group using "${datapath}/EU-SILC/13 L-2017/2017D.dta"
		replace slctd_rtgrp = rotation_group if _merge == 1
		
		/* tag rotation groups that have already been selected in the more recent release in some years (overlapping) */
		gen atag = 0
		replace atag = 1 if _merge == 3
		bysort country rotation_group : egen btag = max(atag) 
		bysort country rotation_group : egen ndrpoy = max(drpout_year2017)
		replace drpout_year = ndrpoy if btag == 1
		drop atag btag ndrpoy
		
		/* update urtgrp and uhid so that "prolonged rotation groups" maintain their urtgrp across different releases */
		tostring drpout_year, replace
		replace uhid = country + rotation_groupstr + drpout_year + hid
		replace urtgrp = country + rotation_groupstr + drpout_year
		destring drpout_year, replace	
		drop rotation_groupstr maxyear_grp minyear years_cov maxgrp maxyear_grp maxyear
		
		/* drop overlapping rotation group years and data from the more recent release */
		keep if _merge == 1 
		drop _merge 
		
		/* check if any selected groups have been selected in the more recent 2018 release ("prolonged rotation groups") */
		merge m:m year country urtgrp using "${datapath}/EU-SILC/14 L-2018/2018D.dta"
		replace slctd_rtgrp = rotation_group if _merge == 1
		keep if _merge == 1 
		drop _merge
		
		/* check if any selected groups have been selected in the more recent 2019 release ("prolonged rotation groups") */
		merge m:m year country urtgrp using "${datapath}/EU-SILC/15 L-2019/2019D.dta"
		replace slctd_rtgrp = rotation_group if _merge == 1
		keep if _merge == 1 
		drop _merge
		
	destring drpout_year, replace 
	drop if slctd_rtgrp == 0
	
	/* for later checks */
	gen drpout_year2016 = drpout_year
	gen slctd_urtgrp2016 = urtgrp 	
	gen slctd_uhid2016 = uhid
	
	/* merge to masterfile */
	merge 1:1 year uhid using "${datapath}/EU-SILC/19 L-2023/masterD.dta"
	
		/* check for duplicates caused by same rotational groups in terms of same hid, different rotation_group */
		duplicates report year country hid
		duplicates tag year country hid, generate(test2)
		tab country year if test2 != 0 	
		tab urtgrp year  if test2 != 0 
		
			/* check if the problem regards a large portion of the rotational group, if the portion is small ignore */
			gen tag1 = 0 
			replace tag1 = 1 if test2 != 0 
			bysort year country urtgrp : egen ndups = total(tag1)
			gen tag2 = 1 
			bysort year country urtgrp : egen tot = total(tag2)
			gen rdups = ndups / tot
			gen tag3 = 0 
			replace tag3 = 1 if rdups > 0.5
			drop tag1 tag2 ndups tot rdups
			
			/* extend selection to whole rotational group */
			bysort year country urtgrp : egen taga = max(tag3)
			drop tag3
			
			/* check if the rotational group with duplicates is the one covering most years in current release. If yes ignore */
			tab urtgrp year if taga == 1  & lgstgrp == 0 & _merge == 1
			drop if taga == 1 & lgstgrp == 0 & _merge == 1
			drop  test2 taga
			
			/* check for unbalances */
			bysort country : egen test3 = total(nrtgrp2017)
			bysort country : egen test4 = total(nrtgrp2018)
			bysort country : egen test5 = total(nrtgrp2019)
			replace test3 = 0 if test3 == .
			replace test4 = 0 if test4 == .
			replace test5 = 0 if test5 == .
			tab urtgrp year if ( test3 != 0 & lgstgrp == 0 & _merge == 1 ) & ( test4 != 0 & lgstgrp == 0 & _merge == 1 ) &( test5 != 0 & lgstgrp == 0 & _merge == 1 )
			drop if ( test3 != 0 & lgstgrp == 0 & _merge == 1 ) & ( test4 != 0 & lgstgrp == 0 & _merge == 1 ) &( test5 != 0 & lgstgrp == 0 & _merge == 1 )
			drop test3 test4 test5
			
		/* this is the updated masterfile */
		gen merge2016 = _merge
		drop _merge
		save "${datapath}/EU-SILC/19 L-2023/masterD.dta", replace
		
		/* this is 2016D file for later control */
		keep if merge2016 == 1 
		drop merge2016
		save "${datapath}/EU-SILC/12 L-2016/2016D.dta", replace

		
/* 2015 */	 
	/* open the 2015 Household register to get data from rotational groups inactive in more recent releases and their uhid */
	clear
	local filen : dir "${datapath}/EU-SILC/11 L-2015/"  files "udb_l15d_ver*"
	display `filen'
	local filel "${datapath}/EU-SILC/11 L-2015/"
	display `"`filel'"'
	local fileln : display `"`filel'"' `filen'
	use `"`fileln'"', clear
	
	local new_var = lower("`var'")

	foreach var of varlist _all {
		local new_var = lower("`var'")
		cap rename `var' `new_var'
	}
	
	/* block Stata from displaying IDs in exponential format */
	tostring db030, replace
	gen year = db010
	gen country = db020
	gen hid = db030
	gen rotation_group = db075
	sort country hid year
	replace country = "EL" if country == "GR"
	
	/* count the number of rotational groups for each country in this release */
	bysort country rotation_group: gen nvals = _n == 1
	bysort country : egen nrtgrp2015 = total(nvals)
	drop nvals 
	
	/* get the rotation group(s) that cover most years */
	bysort country rotation_group : egen maxyear = max(year) 
	bysort country rotation_group : egen minyear = min(year)
	gen years_cov = maxyear - minyear + 1
	bysort country : egen maxgrp = max(years_cov) 
	gen slctd_rtgrp = 0
	bysort country rotation_group: replace slctd_rtgrp = rotation_group if years_cov == maxgrp 
	gen lgstgrp = 0
	bysort country rotation_group: replace lgstgrp = 1 if years_cov == maxgrp
	
	/* build household and rotationgroup IDs that are unique across releases */
	tostring rotation_group, generate(rotation_groupstr)
	gen drpout_year = 0
	replace drpout_year = maxyear + 4 - years_cov
	
		/* check for rotation groups that dropped out before planned */
		bysort country rotation_group : egen maxyear_grp = max(year)
		replace drpout_year = maxyear_grp if maxyear_grp < maxyear
		
	tostring drpout_year, replace
	gen uhid = country + rotation_groupstr + drpout_year + hid
	gen urtgrp = country + rotation_groupstr + drpout_year
	destring drpout_year, replace 	
	
		/* check if any selected groups have been selected in the more recent 2016 release ("prolonged rotation groups") */
		sort year country rotation_group hid 
		merge m:m year country rotation_group using "${datapath}/EU-SILC/12 L-2016/2016D.dta"
		replace slctd_rtgrp = rotation_group if _merge == 1
		
		/* tag rotation groups that have already been selected in the more recent release in some years (overlapping) */
		gen atag = 0
		replace atag = 1 if _merge == 3
		bysort country rotation_group : egen btag = max(atag) 
		bysort country rotation_group : egen ndrpoy = max(drpout_year2016)
		replace drpout_year = ndrpoy if btag == 1
		drop atag btag ndrpoy
		
		/* update urtgrp and uhid so that "prolonged rotation groups" maintain their urtgrp across different releases */
		tostring drpout_year, replace
		replace uhid = country + rotation_groupstr + drpout_year + hid
		replace urtgrp = country + rotation_groupstr + drpout_year
		destring drpout_year, replace	
		drop rotation_groupstr maxyear_grp minyear years_cov maxgrp maxyear_grp maxyear
		
		/* drop overlapping rotation group years and data from the more recent release */
		keep if _merge == 1 
		drop _merge 
		
		/* check if any selected groups have been selected in the more recent 2017 release ("prolonged rotation groups") */
		merge m:m year country urtgrp using "${datapath}/EU-SILC/13 L-2017/2017D.dta"
		replace slctd_rtgrp = rotation_group if _merge == 1
		keep if _merge == 1 
		drop _merge
		
		/* check if any selected groups have been selected in the more recent 2018 release ("prolonged rotation groups") */
		merge m:m year country urtgrp using "${datapath}/EU-SILC/14 L-2018/2018D.dta"
		replace slctd_rtgrp = rotation_group if _merge == 1
		keep if _merge == 1 
		drop _merge
		
	destring drpout_year, replace 
	drop if slctd_rtgrp == 0
	
	/* for later checks */
	gen drpout_year2015 = drpout_year
	gen slctd_urtgrp2015 = urtgrp 	
	gen slctd_uhid2015 = uhid
	
	/* merge to masterfile */
	merge 1:1 year uhid using "${datapath}/EU-SILC/19 L-2023/masterD.dta"
	
		/* check for duplicates caused by same rotational groups in terms of same hid, different rotation_group */
		duplicates report year country hid
		duplicates tag year country hid, generate(test2)
		tab country year if test2 != 0 	
		tab urtgrp year  if test2 != 0 
			/* check if the problem regards a large portion of the rotational group, if the portion is small ignore */
			gen tag1 = 0 
			replace tag1 = 1 if test2 != 0 
			bysort year country urtgrp : egen ndups = total(tag1)
			gen tag2 = 1 
			bysort year country urtgrp : egen tot = total(tag2)
			gen rdups = ndups / tot
			gen tag3 = 0 
			replace tag3 = 1 if rdups > 0.5
			drop tag1 tag2 ndups tot rdups
			/* extend selection to whole rotational group */
			bysort year country urtgrp : egen taga = max(tag3)
			drop tag3
			/* check if the rotational group with duplicates is the one covering most years in current release. If yes ignore */
			tab urtgrp year if taga == 1  & lgstgrp == 0 & _merge == 1
			drop if taga == 1 & lgstgrp == 0 & _merge == 1
			drop  test2 taga
			/* check for unbalances */
			bysort country : egen test3 = total(nrtgrp2016)
			bysort country : egen test4 = total(nrtgrp2017)
			bysort country : egen test5 = total(nrtgrp2018)
			replace test3 = 0 if test3 == .
			replace test4 = 0 if test4 == .
			replace test5 = 0 if test5 == .
			tab urtgrp year if ( test3 != 0 & lgstgrp == 0 & _merge == 1 ) & ( test4 != 0 & lgstgrp == 0 & _merge == 1 ) &( test5 != 0 & lgstgrp == 0 & _merge == 1 )
			drop if ( test3 != 0 & lgstgrp == 0 & _merge == 1 ) & ( test4 != 0 & lgstgrp == 0 & _merge == 1 ) &( test5 != 0 & lgstgrp == 0 & _merge == 1 )
			drop test3 test4 test5
		/* this is the updated masterfile */
		gen merge2015 = _merge
		drop _merge
		save "${datapath}/EU-SILC/19 L-2023/masterD.dta", replace
		/* this is 2015D file for later control */
		keep if merge2015 == 1 
		drop merge2015
		save "${datapath}/EU-SILC/11 L-2015/2015D.dta", replace

/* 2014 */	
	/* open the 2014 Household register to get data from rotational groups inactive in more recent releases and their uhid */ 
	clear
	local filen : dir "${datapath}/EU-SILC/10 L-2014/"  files "udb_l14d_ver*"
	display `filen'
	local filel "${datapath}/EU-SILC/10 L-2014/"
	display `"`filel'"'
	local fileln : display `"`filel'"' `filen'
	use `"`fileln'"', clear
	
	local new_var = lower("`var'")

	foreach var of varlist _all {
		local new_var = lower("`var'")
		cap rename `var' `new_var'
	}
	
	*/ block Stata from displaying IDs in exponential format */ 
	tostring db030, replace
	gen year = db010
	gen country = db020
	gen hid = db030
	gen rotation_group = db075
	sort country hid year
	replace country = "EL" if country == "GR"
	
	/* count the number of rotational groups for each country in this release */
	bysort country rotation_group: gen nvals = _n == 1
	bysort country : egen nrtgrp2014 = total(nvals)
	drop nvals 
	
	/* get the rotation group(s) that cover most years */
	bysort country rotation_group : egen maxyear = max(year) 
	bysort country rotation_group : egen minyear = min(year)
	gen years_cov = maxyear - minyear + 1
	bysort country : egen maxgrp = max(years_cov) 
	gen slctd_rtgrp = 0
	bysort country rotation_group: replace slctd_rtgrp = rotation_group if years_cov == maxgrp 
	gen lgstgrp = 0
	bysort country rotation_group: replace lgstgrp = 1 if years_cov == maxgrp
	
	/* build household and rotationgroup IDs that are unique across releases */
	tostring rotation_group, generate(rotation_groupstr)
	gen drpout_year = 0
	replace drpout_year = maxyear + 4 - years_cov
	
		/* check for rotation groups that dropped out before planned */
		bysort country rotation_group : egen maxyear_grp = max(year)
		replace drpout_year = maxyear_grp if maxyear_grp < maxyear
		
	tostring drpout_year, replace
	gen uhid = country + rotation_groupstr + drpout_year + hid
	gen urtgrp = country + rotation_groupstr + drpout_year
	destring drpout_year, replace 	
	
		/* check if any selected groups have been selected in the more recent 2016 release ("prolonged rotation groups") */
		sort year country rotation_group hid 
		merge m:m year country rotation_group using "${datapath}/EU-SILC/12 L-2016/2016D.dta"
		replace slctd_rtgrp = rotation_group if _merge == 1
		
		/* tag rotation groups that have already been selected in the more recent release in some years (overlapping) */
		gen atag = 0
		replace atag = 1 if _merge == 3
		bysort country rotation_group : egen btag = max(atag) 
		bysort country rotation_group : egen ndrpoy = max(drpout_year2016)
		replace drpout_year = ndrpoy if btag == 1
		drop atag btag ndrpoy
		
		/* update urtgrp and uhid so that "prolonged rotation groups" maintain their urtgrp across different releases */
		tostring drpout_year, replace
		replace uhid = country + rotation_groupstr + drpout_year + hid
		replace urtgrp = country + rotation_groupstr + drpout_year
		destring drpout_year, replace	
		drop rotation_groupstr maxyear_grp minyear years_cov maxgrp maxyear_grp maxyear
		
		/* drop overlapping rotation group years and data from the more recent release */
		keep if _merge == 1 
		drop _merge 
		
		/* check if any selected groups have been selected in the more recent 2017 release ("prolonged rotation groups") */
		merge m:m year country urtgrp using "${datapath}/EU-SILC/13 L-2017/2017D.dta"
		replace slctd_rtgrp = rotation_group if _merge == 1
		keep if _merge == 1 
		drop _merge
		
		/* check if any selected groups have been selected in the more recent 2015 release ("prolonged rotation groups") */
		merge m:m year country urtgrp using "${datapath}/EU-SILC/11 L-2015/2015D.dta"
		replace slctd_rtgrp = rotation_group if _merge == 1
		keep if _merge == 1 
		drop _merge
		
	destring drpout_year, replace 
	drop if slctd_rtgrp == 0
	
	/* for later checks */
	gen drpout_year2014 = drpout_year
	gen slctd_urtgrp2014 = urtgrp 	
	gen slctd_uhid2014 = uhid
	
	/* merge to masterfile */
	merge 1:1 year uhid using "${datapath}/EU-SILC/19 L-2023/masterD.dta"
	
		/* check for duplicates caused by same rotational groups in terms of same hid, different rotation_group */
		duplicates report year country hid
		duplicates tag year country hid, generate(test2)
		tab country year if test2 != 0 	
		tab urtgrp year  if test2 != 0 
		
			/* check if the problem regards a large portion of the rotational group, if the portion is small ignore */
			gen tag1 = 0 
			replace tag1 = 1 if test2 != 0 
			bysort year country urtgrp : egen ndups = total(tag1)
			gen tag2 = 1 
			bysort year country urtgrp : egen tot = total(tag2)
			gen rdups = ndups / tot
			gen tag3 = 0 
			replace tag3 = 1 if rdups > 0.5
			drop tag1 tag2 ndups tot rdups
			
			/* extend selection to whole rotational group */
			bysort year country urtgrp : egen taga = max(tag3)
			drop tag3
			
			/* check if the rotational group with duplicates is the one covering most years in current release. If yes ignore */
			tab urtgrp year if taga == 1  & lgstgrp == 0 & _merge == 1
			drop if taga == 1 & lgstgrp == 0 & _merge == 1
			drop  test2 taga
			
			/* check for unbalances */
			bysort country : egen test3 = total(nrtgrp2016)
			bysort country : egen test4 = total(nrtgrp2017)
			bysort country : egen test5 = total(nrtgrp2015)
			replace test3 = 0 if test3 == .
			replace test4 = 0 if test4 == .
			replace test5 = 0 if test5 == .
			tab urtgrp year if ( test3 != 0 & lgstgrp == 0 & _merge == 1 ) & ( test4 != 0 & lgstgrp == 0 & _merge == 1 ) &( test5 != 0 & lgstgrp == 0 & _merge == 1 )
			drop if ( test3 != 0 & lgstgrp == 0 & _merge == 1 ) & ( test4 != 0 & lgstgrp == 0 & _merge == 1 ) &( test5 != 0 & lgstgrp == 0 & _merge == 1 )
			drop test3 test4 test5
			
		/* this is the updated masterfile */
		gen merge2014 = _merge
		drop _merge
		save "${datapath}/EU-SILC/19 L-2023/masterD.dta", replace
		
		/* this is 2014D file for later control */
		keep if merge2014 == 1 
		drop merge2014
		save "${datapath}/EU-SILC/10 L-2014/2014D.dta", replace

/* 2013 */
	/* open the 2013 Household register to get data from rotational groups inactive in more recent releases and their uhid */ 
	clear
	local filen : dir "${datapath}/EU-SILC/9 L-2013/"  files "udb_l13d_ver*"
	display `filen'
	local filel "${datapath}/EU-SILC/9 L-2013/"
	display `"`filel'"'
	local fileln : display `"`filel'"' `filen'
	use `"`fileln'"', clear
	
	local new_var = lower("`var'")

	foreach var of varlist _all {
		local new_var = lower("`var'")
		cap rename `var' `new_var'
	}
	
	*/ block Stata from displaying IDs in exponential format */ 
	tostring db030, replace
	gen year = db010
	gen country = db020
	gen hid = db030
	gen rotation_group = db075
	sort country hid year
	replace country = "EL" if country == "GR"
	
	/* count the number of rotational groups for each country in this release */
	bysort country rotation_group: gen nvals = _n == 1
	bysort country : egen nrtgrp2013 = total(nvals)
	drop nvals 
	
	/* get the rotation group(s) that cover most years */
	bysort country rotation_group : egen maxyear = max(year) 
	bysort country rotation_group : egen minyear = min(year)
	gen years_cov = maxyear - minyear + 1
	bysort country : egen maxgrp = max(years_cov) 
	gen slctd_rtgrp = 0
	bysort country rotation_group: replace slctd_rtgrp = rotation_group if years_cov == maxgrp 
	gen lgstgrp = 0
	bysort country rotation_group: replace lgstgrp = 1 if years_cov == maxgrp
	
	/* build household and rotationgroup IDs that are unique across releases */
	tostring rotation_group, generate(rotation_groupstr)
	gen drpout_year = 0
	replace drpout_year = maxyear + 4 - years_cov
	
		/* check for rotation groups that dropped out before planned */
		bysort country rotation_group : egen maxyear_grp = max(year)
		replace drpout_year = maxyear_grp if maxyear_grp < maxyear
	tostring drpout_year, replace
	gen uhid = country + rotation_groupstr + drpout_year + hid
	gen urtgrp = country + rotation_groupstr + drpout_year
	destring drpout_year, replace 	
	
		/* check if any selected groups have been selected in the more recent 2016 release ("prolonged rotation groups") */
		sort year country rotation_group hid 
		merge m:m year country rotation_group using "${datapath}/EU-SILC/12 L-2016/2016D.dta"
		replace slctd_rtgrp = rotation_group if _merge == 1
		
		/* tag rotation groups that have already been selected in the more recent release in some years (overlapping) */
		gen atag = 0
		replace atag = 1 if _merge == 3
		bysort country rotation_group : egen btag = max(atag) 
		bysort country rotation_group : egen ndrpoy = max(drpout_year2016)
		replace drpout_year = ndrpoy if btag == 1
		drop atag btag ndrpoy
		/* update urtgrp and uhid so that "prolonged rotation groups" maintain their urtgrp across different releases */
		tostring drpout_year, replace
		replace uhid = country + rotation_groupstr + drpout_year + hid
		replace urtgrp = country + rotation_groupstr + drpout_year
		destring drpout_year, replace	
		drop rotation_groupstr maxyear_grp minyear years_cov maxgrp maxyear_grp maxyear
		
		/* drop overlapping rotation group years and data from the more recent release */
		keep if _merge == 1 
		drop _merge 
		
		/* check if any selected groups have been selected in the more recent 2014 release ("prolonged rotation groups") */
		merge m:m year country urtgrp using "${datapath}/EU-SILC/10 L-2014/2014D.dta"
		replace slctd_rtgrp = rotation_group if _merge == 1
		keep if _merge == 1 
		drop _merge
		
		/* check if any selected groups have been selected in the more recent 2015 release ("prolonged rotation groups") */
		merge m:m year country urtgrp using "${datapath}/EU-SILC/11 L-2015/2015D.dta"
		replace slctd_rtgrp = rotation_group if _merge == 1
		keep if _merge == 1 
		drop _merge
		
	destring drpout_year, replace 
	drop if slctd_rtgrp == 0
	
	/* for later checks */
	gen drpout_year2013 = drpout_year
	gen slctd_urtgrp2013 = urtgrp 	
	gen slctd_uhid2013 = uhid
	
	/* merge to masterfile */
	merge 1:1 year uhid using "${datapath}/EU-SILC/19 L-2023/masterD.dta"
	
		/* check for duplicates caused by same rotational groups in terms of same hid, different rotation_group */
		duplicates report year country hid
		duplicates tag year country hid, generate(test2)
		tab country year if test2 != 0 	
		tab urtgrp year  if test2 != 0 
		
			/* check if the problem regards a large portion of the rotational group, if the portion is small ignore */
			gen tag1 = 0 
			replace tag1 = 1 if test2 != 0 
			bysort year country urtgrp : egen ndups = total(tag1)
			gen tag2 = 1 
			bysort year country urtgrp : egen tot = total(tag2)
			gen rdups = ndups / tot
			gen tag3 = 0 
			replace tag3 = 1 if rdups > 0.5
			drop tag1 tag2 ndups tot rdups
			
			/* extend selection to whole rotational group */
			bysort year country urtgrp : egen taga = max(tag3)
			drop tag3
			
			/* check if the rotational group with duplicates is the one covering most years in current release. If yes ignore */
			tab urtgrp year if taga == 1  & lgstgrp == 0 & _merge == 1
			drop if taga == 1 & lgstgrp == 0 & _merge == 1
			drop  test2 taga
			
			/* check for unbalances */
			bysort country : egen test3 = total(nrtgrp2016)
			bysort country : egen test4 = total(nrtgrp2014)
			bysort country : egen test5 = total(nrtgrp2015)
			replace test3 = 0 if test3 == .
			replace test4 = 0 if test4 == .
			replace test5 = 0 if test5 == .
			tab urtgrp year if ( test3 != 0 & lgstgrp == 0 & _merge == 1 ) & ( test4 != 0 & lgstgrp == 0 & _merge == 1 ) &( test5 != 0 & lgstgrp == 0 & _merge == 1 )
			drop if ( test3 != 0 & lgstgrp == 0 & _merge == 1 ) & ( test4 != 0 & lgstgrp == 0 & _merge == 1 ) &( test5 != 0 & lgstgrp == 0 & _merge == 1 )
			drop test3 test4 test5
			
		/* this is the updated masterfile */
		gen merge2013 = _merge
		drop _merge
		save "${datapath}/EU-SILC/19 L-2023/masterD.dta", replace
		
		/* this is 2013D file for later control */
		keep if merge2013 == 1 
		drop merge2013
		save "${datapath}/EU-SILC/9 L-2013/2013D.dta", replace

/* 2012 */	
	/* open the 2012 Household register to get data from rotational groups inactive in more recent releases and their uhid */ 
	clear
	local filen : dir "${datapath}/EU-SILC/8 L-2012/"  files "udb_l12d_ver*"
	display `filen'
	local filel "${datapath}/EU-SILC/8 L-2012/"
	display `"`filel'"'
	local fileln : display `"`filel'"' `filen'
use `"`fileln'"', clear
	
	
	local new_var = lower("`var'")

    foreach var of varlist _all {
    	local new_var = lower("`var'")
    	cap rename `var' `new_var'
    }

	*/ block Stata from displaying IDs in exponential format */ 
	tostring db030, replace
	gen year = db010
	gen country = db020
	gen hid = db030
	gen rotation_group = db075
	sort country hid year
	replace country = "EL" if country == "GR"
	
	/* count the number of rotational groups for each country in this release */
	bysort country rotation_group: gen nvals = _n == 1
	bysort country : egen nrtgrp2012 = total(nvals)
	drop nvals 
	
	/* get the rotation group(s) that cover most years */
	bysort country rotation_group : egen maxyear = max(year) 
	bysort country rotation_group : egen minyear = min(year)
	gen years_cov = maxyear - minyear + 1
	bysort country : egen maxgrp = max(years_cov) 
	gen slctd_rtgrp = 0
	bysort country rotation_group: replace slctd_rtgrp = rotation_group if years_cov == maxgrp 
	gen lgstgrp = 0
	bysort country rotation_group: replace lgstgrp = 1 if years_cov == maxgrp
	
	/* build household and rotationgroup IDs that are unique across releases */
	tostring rotation_group, generate(rotation_groupstr)
	gen drpout_year = 0
	replace drpout_year = maxyear + 4 - years_cov
	
		/* check for rotation groups that dropped out before planned */
		bysort country rotation_group : egen maxyear_grp = max(year)
		replace drpout_year = maxyear_grp if maxyear_grp < maxyear
	tostring drpout_year, replace
	
	gen uhid = country + rotation_groupstr + drpout_year + hid
	gen urtgrp = country + rotation_groupstr + drpout_year
	destring drpout_year, replace 	
	
		/* check if any selected groups have been selected in the more recent 2013 release ("prolonged rotation groups") */
		sort year country rotation_group hid 
		merge m:m year country rotation_group using "${datapath}/EU-SILC/9 L-2013/2013D.dta"
		replace slctd_rtgrp = rotation_group if _merge == 1
		
		/* tag rotation groups that have already been selected in the more recent release in some years (overlapping) */
		gen atag = 0
		replace atag = 1 if _merge == 3
		bysort country rotation_group : egen btag = max(atag) 
		bysort country rotation_group : egen ndrpoy = max(drpout_year2013)
		replace drpout_year = ndrpoy if btag == 1
		drop atag btag ndrpoy
		
		/* update urtgrp and uhid so that "prolonged rotation groups" maintain their urtgrp across different releases */
		tostring drpout_year, replace
		replace uhid = country + rotation_groupstr + drpout_year + hid
		replace urtgrp = country + rotation_groupstr + drpout_year
		destring drpout_year, replace	
		drop rotation_groupstr maxyear_grp minyear years_cov maxgrp maxyear_grp maxyear
		
		/* drop overlapping rotation group years and data from the more recent release */
		keep if _merge == 1 
		drop _merge 
		
		/* check if any selected groups have been selected in the more recent 2014 release ("prolonged rotation groups") */
		merge m:m year country urtgrp using "${datapath}/EU-SILC/10 L-2014/2014D.dta"
		replace slctd_rtgrp = rotation_group if _merge == 1
		keep if _merge == 1 
		drop _merge
		
		/* check if any selected groups have been selected in the more recent 2015 release ("prolonged rotation groups") */
		merge m:m year country urtgrp using "${datapath}/EU-SILC/11 L-2015/2015D.dta"
		replace slctd_rtgrp = rotation_group if _merge == 1
		keep if _merge == 1 
		drop _merge
		
	destring drpout_year, replace 
	drop if slctd_rtgrp == 0
	
	/* for later checks */
	gen drpout_year2012 = drpout_year
	gen slctd_urtgrp2012 = urtgrp 	
	gen slctd_uhid2012 = uhid
	
	/* merge to masterfile */
	merge 1:1 year uhid using "${datapath}/EU-SILC/19 L-2023/masterD.dta"
	
		/* check for duplicates caused by same rotational groups in terms of same hid, different rotation_group */
		duplicates report year country hid
		duplicates tag year country hid, generate(test2)
		tab country year if test2 != 0 	
		tab urtgrp year  if test2 != 0
		
			/* check if the problem regards a large portion of the rotational group, if the portion is small ignore */
			gen tag1 = 0 
			replace tag1 = 1 if test2 != 0 
			bysort year country urtgrp : egen ndups = total(tag1)
			gen tag2 = 1 
			bysort year country urtgrp : egen tot = total(tag2)
			gen rdups = ndups / tot
			gen tag3 = 0 
			replace tag3 = 1 if rdups > 0.5
			drop tag1 tag2 ndups tot rdups
			
			/* extend selection to whole rotational group */
			bysort year country urtgrp : egen taga = max(tag3)
			drop tag3
			
			/* check if the rotational group with duplicates is the one covering most years in current release. If yes ignore */
			tab urtgrp year if taga == 1  & lgstgrp == 0 & _merge == 1
			drop if taga == 1 & lgstgrp == 0 & _merge == 1
			drop  test2 taga
			
			/* check for unbalances */
			bysort country : egen test3 = total(nrtgrp2013)
			bysort country : egen test4 = total(nrtgrp2014)
			bysort country : egen test5 = total(nrtgrp2015)
			replace test3 = 0 if test3 == .
			replace test4 = 0 if test4 == .
			replace test5 = 0 if test5 == .
			tab urtgrp year if ( test3 != 0 & lgstgrp == 0 & _merge == 1 ) & ( test4 != 0 & lgstgrp == 0 & _merge == 1 ) &( test5 != 0 & lgstgrp == 0 & _merge == 1 )	
			drop if ( test3 != 0 & lgstgrp == 0 & _merge == 1 ) & ( test4 != 0 & lgstgrp == 0 & _merge == 1 ) & ( test5 != 0 & lgstgrp == 0 & _merge == 1 )
			drop test3 test4 test5
			
		/* this is the updated masterfile */
		gen merge2012 = _merge
		drop _merge
		save "${datapath}/EU-SILC/19 L-2023/masterD.dta", replace
		
		/* this is 2012D file for later control */
		keep if merge2012 == 1 
		drop merge2012
		save "${datapath}/EU-SILC/8 L-2012/2012D.dta", replace


/* 2011 */	
	/* open the 2011 Household register to get data from rotational groups inactive in more recent releases and their uhid */ 
	clear
	local filen : dir "${datapath}/EU-SILC/7 L-2011/"  files "udb_l11d_ver*"
	display `filen'
	local filel "${datapath}/EU-SILC/7 L-2011/"
	display `"`filel'"'
	local fileln : display `"`filel'"' `filen'
	use `"`fileln'"', clear
	
	local new_var = lower("`var'")

    foreach var of varlist _all {
    	local new_var = lower("`var'")
    	cap rename `var' `new_var'
    }

	*/ block Stata from displaying IDs in exponential format */ 
	tostring db030, replace
	gen year = db010
	gen country = db020
	gen hid = db030
	gen rotation_group = db075
	sort country hid year
	replace country = "EL" if country == "GR"
	
	/* count the number of rotational groups for each country in this release */
	bysort country rotation_group: gen nvals = _n == 1
	bysort country : egen nrtgrp2011 = total(nvals)
	drop nvals 
	
	/* get the rotation group(s) that cover most years */
	bysort country rotation_group : egen maxyear = max(year) 
	bysort country rotation_group : egen minyear = min(year)
	gen years_cov = maxyear - minyear + 1
	bysort country : egen maxgrp = max(years_cov) 
	gen slctd_rtgrp = 0
	bysort country rotation_group: replace slctd_rtgrp = rotation_group if years_cov == maxgrp 
	gen lgstgrp = 0
	bysort country rotation_group: replace lgstgrp = 1 if years_cov == maxgrp
	
	/* build household and rotationgroup IDs that are unique across releases */
	tostring rotation_group, generate(rotation_groupstr)
	gen drpout_year = 0
	replace drpout_year = maxyear + 4 - years_cov
	
		/* check for rotation groups that dropped out before planned */
		bysort country rotation_group : egen maxyear_grp = max(year)
		replace drpout_year = maxyear_grp if maxyear_grp < maxyear
		
	tostring drpout_year, replace
	gen uhid = country + rotation_groupstr + drpout_year + hid
	gen urtgrp = country + rotation_groupstr + drpout_year
	destring drpout_year, replace 	
	
		/* check if any selected groups have been selected in the more recent 2012 release ("prolonged rotation groups") */
		sort year country rotation_group hid 
		merge m:m year country rotation_group using "${datapath}/EU-SILC/8 L-2012/2012D.dta"
		replace slctd_rtgrp = rotation_group if _merge == 1
		
		/* tag rotation groups that have already been selected in the more recent release in some years (overlapping) */
		gen atag = 0
		replace atag = 1 if _merge == 3
		bysort country rotation_group : egen btag = max(atag) 
		bysort country rotation_group : egen ndrpoy = max(drpout_year2012)
		replace drpout_year = ndrpoy if btag == 1
		drop atag btag ndrpoy
		
		/* update urtgrp and uhid so that "prolonged rotation groups" maintain their urtgrp across different releases */
		tostring drpout_year, replace
		replace uhid = country + rotation_groupstr + drpout_year + hid
		replace urtgrp = country + rotation_groupstr + drpout_year
		destring drpout_year, replace	
		drop rotation_groupstr maxyear_grp minyear years_cov maxgrp maxyear_grp maxyear
		
		/* drop overlapping rotation group years and data from the more recent release */
		keep if _merge == 1 
		drop _merge 
		
		/* check if any selected groups have been selected in the more recent 2013 release ("prolonged rotation groups") */
		merge m:m year country urtgrp using "${datapath}/EU-SILC/9 L-2013/2013D.dta"
		replace slctd_rtgrp = rotation_group if _merge == 1
		keep if _merge == 1 
		drop _merge
		
		/* check if any selected groups have been selected in the more recent 2014 release ("prolonged rotation groups") */
		merge m:m year country urtgrp using "${datapath}/EU-SILC/10 L-2014/2014D.dta"
		replace slctd_rtgrp = rotation_group if _merge == 1
		keep if _merge == 1 
		drop _merge
		
	destring drpout_year, replace 
	drop if slctd_rtgrp == 0
	
	/* for later checks */
	gen drpout_year2011 = drpout_year
	gen slctd_urtgrp2011 = urtgrp 	
	gen slctd_uhid2011 = uhid
	
	/* merge to masterfile */
	merge 1:1 year uhid using "${datapath}/EU-SILC/19 L-2023/masterD.dta"
	
		/* check for duplicates caused by same rotational groups in terms of same hid, different rotation_group */
		duplicates report year country hid
		duplicates tag year country hid, generate(test2)
		tab country year if test2 != 0 	
		tab urtgrp year  if test2 != 0 
		
			/* check if the problem regards a large portion of the rotational group, if the portion is small ignore */
			gen tag1 = 0 
			replace tag1 = 1 if test2 != 0 
			bysort year country urtgrp : egen ndups = total(tag1)
			gen tag2 = 1 
			bysort year country urtgrp : egen tot = total(tag2)
			gen rdups = ndups / tot
			gen tag3 = 0 
			replace tag3 = 1 if rdups > 0.5
			drop tag1 tag2 ndups tot rdups
			
			/* extend selection to whole rotational group */
			bysort year country urtgrp : egen taga = max(tag3)
			drop tag3
			
			/* check if the rotational group with duplicates is the one covering most years in current release. If yes ignore */
			tab urtgrp year if taga == 1  & lgstgrp == 0 & _merge == 1
			drop if taga == 1 & lgstgrp == 0 & _merge == 1
			drop  test2 taga
			
			/* check for unbalances */
			bysort country : egen test3 = total(nrtgrp2012)
			bysort country : egen test4 = total(nrtgrp2013)
			bysort country : egen test5 = total(nrtgrp2014)
			replace test3 = 0 if test3 == .
			replace test4 = 0 if test4 == .
			replace test5 = 0 if test5 == .
			tab urtgrp year if ( test3 != 0 & lgstgrp == 0 & _merge == 1 ) & ( test4 != 0 & lgstgrp == 0 & _merge == 1 ) &( test5 != 0 & lgstgrp == 0 & _merge == 1 )
			drop if ( test3 != 0 & lgstgrp == 0 & _merge == 1 ) & ( test4 != 0 & lgstgrp == 0 & _merge == 1 ) &( test5 != 0 & lgstgrp == 0 & _merge == 1 )
			drop test3 test4 test5
			
		/* this is the updated masterfile */
		gen merge2011 = _merge
		drop _merge
		save "${datapath}/EU-SILC/19 L-2023/masterD.dta", replace
		
		/* this is 2011D file for later control */
		keep if merge2011 == 1 
		drop merge2011
		save "${datapath}/EU-SILC/7 L-2011/2011D.dta", replace

		
/* 2010 */		
	/* open the 2010 Household register to get data from rotational groups inactive in more recent releases and their uhid */ 
	clear
	local filen : dir "${datapath}/EU-SILC/6 L-2010/"  files "udb_l10d_ver*"
	display `filen'
	local filel "${datapath}/EU-SILC/6 L-2010/"
	display `"`filel'"'
	local fileln : display `"`filel'"' `filen'
	use `"`fileln'"', clear
	
	local new_var = lower("`var'")

    foreach var of varlist _all {
    	local new_var = lower("`var'")
    	cap rename `var' `new_var'
    }

	*/ block Stata from displaying IDs in exponential format */ 
	tostring db030, replace
	gen year = db010
	gen country = db020
	gen hid = db030
	gen rotation_group = db075
	sort country hid year
	replace country = "EL" if country == "GR"
	
	/* count the number of rotational groups for each country in this release */
	bysort country rotation_group: gen nvals = _n == 1
	bysort country : egen nrtgrp2010 = total(nvals)
	drop nvals 
	
	/* get the rotation group(s) that cover most years */
	bysort country rotation_group : egen maxyear = max(year) 
	bysort country rotation_group : egen minyear = min(year)
	gen years_cov = maxyear - minyear + 1
	bysort country : egen maxgrp = max(years_cov) 
	gen slctd_rtgrp = 0
	bysort country rotation_group: replace slctd_rtgrp = rotation_group if years_cov == maxgrp 
	gen lgstgrp = 0
	bysort country rotation_group: replace lgstgrp = 1 if years_cov == maxgrp
	
	/* build household and rotationgroup IDs that are unique across releases */
	tostring rotation_group, generate(rotation_groupstr)
	gen drpout_year = 0
	replace drpout_year = maxyear + 4 - years_cov
	
		/* check for rotation groups that dropped out before planned */
		bysort country rotation_group : egen maxyear_grp = max(year)
		replace drpout_year = maxyear_grp if maxyear_grp < maxyear
		
	tostring drpout_year, replace
	gen uhid = country + rotation_groupstr + drpout_year + hid
	gen urtgrp = country + rotation_groupstr + drpout_year
	destring drpout_year, replace 	
	
		/* check if any selected groups have been selected in the more recent 2011 release ("prolonged rotation groups") */
		sort year country rotation_group hid 
		merge m:m year country rotation_group using "${datapath}/EU-SILC/7 L-2011/2011D.dta"
		replace slctd_rtgrp = rotation_group if _merge == 1
		
		/* tag rotation groups that have already been selected in the more recent release in some years (overlapping) */
		gen atag = 0
		replace atag = 1 if _merge == 3
		bysort country rotation_group : egen btag = max(atag) 
		bysort country rotation_group : egen ndrpoy = max(drpout_year2011)
		replace drpout_year = ndrpoy if btag == 1
		drop atag btag ndrpoy
		
		/* update urtgrp and uhid so that "prolonged rotation groups" maintain their urtgrp across different releases */
		tostring drpout_year, replace
		replace uhid = country + rotation_groupstr + drpout_year + hid
		replace urtgrp = country + rotation_groupstr + drpout_year
		destring drpout_year, replace	
		drop rotation_groupstr maxyear_grp minyear years_cov maxgrp maxyear_grp maxyear
		
		/* drop overlapping rotation group years and data from the more recent release */
		keep if _merge == 1 
		drop _merge 
		
		/* check if any selected groups have been selected in the more recent 2012 release ("prolonged rotation groups") */
		merge m:m year country urtgrp using "${datapath}/EU-SILC/8 L-2012/2012D.dta"
		replace slctd_rtgrp = rotation_group if _merge == 1
		keep if _merge == 1 
		drop _merge
		
		/* check if any selected groups have been selected in the more recent 2013 release ("prolonged rotation groups") */
		merge m:m year country urtgrp using "${datapath}/EU-SILC/9 L-2013/2013D.dta"
		replace slctd_rtgrp = rotation_group if _merge == 1
		keep if _merge == 1 
		drop _merge
		
	destring drpout_year, replace 
	drop if slctd_rtgrp == 0
	
	/* for later checks */
	gen drpout_year2010 = drpout_year
	gen slctd_urtgrp2010 = urtgrp 	
	gen slctd_uhid2010 = uhid
	
	/* merge to masterfile */
	merge 1:1 year uhid using "${datapath}/EU-SILC/19 L-2023/masterD.dta"
	
		/* check for duplicates caused by same rotational groups in terms of same hid, different rotation_group */
		duplicates report year country hid
		duplicates tag year country hid, generate(test2)
		tab country year if test2 != 0 	
		tab urtgrp year  if test2 != 0 
		
			/* check if the problem regards a large portion of the rotational group, if the portion is small ignore */
			gen tag1 = 0 
			replace tag1 = 1 if test2 != 0 
			bysort year country urtgrp : egen ndups = total(tag1)
			gen tag2 = 1 
			bysort year country urtgrp : egen tot = total(tag2)
			gen rdups = ndups / tot
			gen tag3 = 0 
			replace tag3 = 1 if rdups > 0.5
			drop tag1 tag2 ndups tot rdups
			
			/* extend selection to whole rotational group */
			bysort year country urtgrp : egen taga = max(tag3)
			drop tag3
			
			/* check if the rotational group with duplicates is the one covering most years in current release. If yes ignore */
			tab urtgrp year if taga == 1  & lgstgrp == 0 & _merge == 1
			drop if taga == 1 & lgstgrp == 0 & _merge == 1
			drop  test2 taga
			
			/* check for unbalances */
			bysort country : egen test3 = total(nrtgrp2011)
			bysort country : egen test4 = total(nrtgrp2012)
			bysort country : egen test5 = total(nrtgrp2013)
			replace test3 = 0 if test3 == .
			replace test4 = 0 if test4 == .
			replace test5 = 0 if test5 == .
			tab urtgrp year if ( test3 != 0 & lgstgrp == 0 & _merge == 1 ) & ( test4 != 0 & lgstgrp == 0 & _merge == 1 ) &( test5 != 0 & lgstgrp == 0 & _merge == 1 )
			drop if ( test3 != 0 & lgstgrp == 0 & _merge == 1 ) & ( test4 != 0 & lgstgrp == 0 & _merge == 1 ) &( test5 != 0 & lgstgrp == 0 & _merge == 1 )
			drop test3 test4 test5
			
		/* this is the updated masterfile */
		gen merge2010 = _merge
		drop _merge
		save "${datapath}/EU-SILC/19 L-2023/masterD.dta", replace
		
		/* this is 2010D file for later control */
		keep if merge2010 == 1 
		drop merge2010
		save "${datapath}/EU-SILC/6 L-2010/2010D.dta", replace
	
	
/* 2009 */
	/* open the 2009 Household register to get data from rotational groups inactive in more recent releases and their uhid */ 
	clear
	local filen : dir "${datapath}/EU-SILC/5 L-2009/"  files "udb_l09d_ver*"
	display `filen'
	local filel "${datapath}/EU-SILC/5 L-2009/"
	display `"`filel'"'
	local fileln : display `"`filel'"' `filen'
	use `"`fileln'"', clear	
	
	local new_var = lower("`var'")

    foreach var of varlist _all {
    	local new_var = lower("`var'")
    	cap rename `var' `new_var'
    }

	*/ block Stata from displaying IDs in exponential format */ 
	tostring db030, replace
	gen year = db010
	gen country = db020
	gen hid = db030
	gen rotation_group = db075
	sort country hid year
	replace country = "EL" if country == "GR"
	
	/* count the number of rotational groups for each country in this release */
	bysort country rotation_group: gen nvals = _n == 1
	bysort country : egen nrtgrp2009 = total(nvals)
	drop nvals 
	
	/* get the rotation group(s) that cover most years */
	bysort country rotation_group : egen maxyear = max(year) 
	bysort country rotation_group : egen minyear = min(year)
	gen years_cov = maxyear - minyear + 1
	bysort country : egen maxgrp = max(years_cov) 
	gen slctd_rtgrp = 0
	bysort country rotation_group: replace slctd_rtgrp = rotation_group if years_cov == maxgrp 
	gen lgstgrp = 0
	bysort country rotation_group: replace lgstgrp = 1 if years_cov == maxgrp
	
	/* build household and rotationgroup IDs that are unique across releases */
	tostring rotation_group, generate(rotation_groupstr)
	gen drpout_year = 0
	replace drpout_year = maxyear + 4 - years_cov
	
		/* check for rotation groups that dropped out before planned */
		bysort country rotation_group : egen maxyear_grp = max(year)
		replace drpout_year = maxyear_grp if maxyear_grp < maxyear
		
	tostring drpout_year, replace
	gen uhid = country + rotation_groupstr + drpout_year + hid
	gen urtgrp = country + rotation_groupstr + drpout_year
	destring drpout_year, replace 	
	
		/* check if any selected groups have been selected in the more recent 2010 release ("prolonged rotation groups") */
		sort year country rotation_group hid 
		merge m:m year country rotation_group using "${datapath}/EU-SILC/6 L-2010/2010D.dta"
		replace slctd_rtgrp = rotation_group if _merge == 1
		
		/* tag rotation groups that have already been selected in the more recent release in some years (overlapping) */
		gen atag = 0
		replace atag = 1 if _merge == 3
		bysort country rotation_group : egen btag = max(atag) 
		bysort country rotation_group : egen ndrpoy = max(drpout_year2010)
		replace drpout_year = ndrpoy if btag == 1
		drop atag btag ndrpoy
		
		/* update urtgrp and uhid so that "prolonged rotation groups" maintain their urtgrp across different releases */
		tostring drpout_year, replace
		replace uhid = country + rotation_groupstr + drpout_year + hid
		replace urtgrp = country + rotation_groupstr + drpout_year
		destring drpout_year, replace	
		drop rotation_groupstr maxyear_grp minyear years_cov maxgrp maxyear_grp maxyear
		
		/* drop overlapping rotation group years and data from the more recent release */
		keep if _merge == 1 
		drop _merge 
		
		/* check if any selected groups have been selected in the more recent 2011 release ("prolonged rotation groups") */
		merge m:m year country urtgrp using "${datapath}/EU-SILC/7 L-2011/2011D.dta"
		replace slctd_rtgrp = rotation_group if _merge == 1
		keep if _merge == 1 
		drop _merge
		
		/* check if any selected groups have been selected in the more recent 2012 release ("prolonged rotation groups") */
		merge m:m year country urtgrp using "${datapath}/EU-SILC/8 L-2012/2012D.dta"
		replace slctd_rtgrp = rotation_group if _merge == 1
		keep if _merge == 1 
		drop _merge
		
	destring drpout_year, replace 
	drop if slctd_rtgrp == 0
	
	/* for later checks */
	gen drpout_year2009 = drpout_year
	gen slctd_urtgrp2009 = urtgrp 	
	gen slctd_uhid2009 = uhid
	
	/* merge to masterfile */
	merge 1:1 year uhid using "${datapath}/EU-SILC/19 L-2023/masterD.dta"
	
		/* check for duplicates caused by same rotational groups in terms of same hid, different rotation_group */
		duplicates report year country hid
		duplicates tag year country hid, generate(test2)
		tab country year if test2 != 0 	
		tab urtgrp year  if test2 != 0 
		
			/* check if the problem regards a large portion of the rotational group, if the portion is small ignore */
			gen tag1 = 0 
			replace tag1 = 1 if test2 != 0 
			bysort year country urtgrp : egen ndups = total(tag1)
			gen tag2 = 1 
			bysort year country urtgrp : egen tot = total(tag2)
			gen rdups = ndups / tot
			gen tag3 = 0 
			replace tag3 = 1 if rdups > 0.5
			drop tag1 tag2 ndups tot rdups
			
			/* extend selection to whole rotational group */
			bysort year country urtgrp : egen taga = max(tag3)
			drop tag3
			
			/* check if the rotational group with duplicates is the one covering most years in current release. If yes ignore */
			tab urtgrp year if taga == 1  & lgstgrp == 0 & _merge == 1
			drop if taga == 1 & lgstgrp == 0 & _merge == 1
			drop  test2 taga
			
			/* check for unbalances */
			bysort country : egen test3 = total(nrtgrp2010)
			bysort country : egen test4 = total(nrtgrp2011)
			bysort country : egen test5 = total(nrtgrp2012)
			replace test3 = 0 if test3 == .
			replace test4 = 0 if test4 == .
			replace test5 = 0 if test5 == .
			tab urtgrp year if ( test3 != 0 & lgstgrp == 0 & _merge == 1 ) & ( test4 != 0 & lgstgrp == 0 & _merge == 1 ) &( test5 != 0 & lgstgrp == 0 & _merge == 1 )
			drop if ( test3 != 0 & lgstgrp == 0 & _merge == 1 ) & ( test4 != 0 & lgstgrp == 0 & _merge == 1 ) &( test5 != 0 & lgstgrp == 0 & _merge == 1 )
			drop test3 test4 test5
			
		/* this is the updated masterfile */
		gen merge2009 = _merge
		drop _merge
		save "${datapath}/EU-SILC/19 L-2023/masterD.dta", replace
		
		/* this is 2009D file for later control */
		keep if merge2009 == 1 
		drop merge2009
		save "${datapath}/EU-SILC/5 L-2009/2009D.dta", replace			

		
/* 2008 */
	/* open the 2008 Household register to get data from rotational groups inactive in more recent releases and their uhid */ 
	clear
	local filen : dir "${datapath}/EU-SILC/4 L-2008/"  files "udb_l08d_ver*"
	display `filen'
	local filel "${datapath}/EU-SILC/4 L-2008/"
	display `"`filel'"'
	local fileln : display `"`filel'"' `filen'
	use `"`fileln'"', clear
	
	local new_var = lower("`var'")

    foreach var of varlist _all {
    	local new_var = lower("`var'")
    	cap rename `var' `new_var'
    }

	*/ block Stata from displaying IDs in exponential format */ 
	tostring db030, replace
	gen year = db010
	gen country = db020
	gen hid = db030
	gen rotation_group = db075 
	sort country hid year
	replace country = "EL" if country == "GR"
	
	/* count the number of rotational groups for each country in this release */
	bysort country rotation_group: gen nvals = _n == 1
	bysort country : egen nrtgrp2008 = total(nvals)
	drop nvals 
	
	/* get the rotation group(s) that cover most years */
	bysort country rotation_group : egen maxyear = max(year) 
	bysort country rotation_group : egen minyear = min(year)
	gen years_cov = maxyear - minyear + 1
	bysort country : egen maxgrp = max(years_cov) 
	gen slctd_rtgrp = 0
	bysort country rotation_group: replace slctd_rtgrp = rotation_group if years_cov == maxgrp 
	gen lgstgrp = 0
	bysort country rotation_group: replace lgstgrp = 1 if years_cov == maxgrp
	
	/* build household and rotationgroup IDs that are unique across releases */
	tostring rotation_group, generate(rotation_groupstr)
	gen drpout_year = 0
	replace drpout_year = maxyear + 4 - years_cov
	
		/* check for rotation groups that dropped out before planned */
		bysort country rotation_group : egen maxyear_grp = max(year)
		replace drpout_year = maxyear_grp if maxyear_grp < maxyear
		
	tostring drpout_year, replace
	gen uhid = country + rotation_groupstr + drpout_year + hid
	gen urtgrp = country + rotation_groupstr + drpout_year
	destring drpout_year, replace 
	
		/* check if any selected groups have been selected in the more recent 2009 release ("prolonged rotation groups") */
		sort year country rotation_group hid 
		merge m:m year country rotation_group using "${datapath}/EU-SILC/5 L-2009/2009D.dta"
		replace slctd_rtgrp = rotation_group if _merge == 1
		
		/* tag rotation groups that have already been selected in the more recent release in some years (overlapping) */
		gen atag = 0
		replace atag = 1 if _merge == 3
		bysort country rotation_group : egen btag = max(atag) 
		bysort country rotation_group : egen ndrpoy = max(drpout_year2009)
		replace drpout_year = ndrpoy if btag == 1
		drop atag btag ndrpoy
		
		/* update urtgrp and uhid so that "prolonged rotation groups" maintain their urtgrp across different releases */
		tostring drpout_year, replace
		replace uhid = country + rotation_groupstr + drpout_year + hid
		replace urtgrp = country + rotation_groupstr + drpout_year
		destring drpout_year, replace	
		drop rotation_groupstr maxyear_grp minyear years_cov maxgrp maxyear_grp maxyear
		
		/* drop overlapping rotation group years and data from the more recent release */
		keep if _merge == 1 
		drop _merge 
		
		/* check if any selected groups have been selected in the more recent 2010 release ("prolonged rotation groups") */
		merge m:m year country urtgrp using "${datapath}/EU-SILC/6 L-2010/2010D.dta"
		replace slctd_rtgrp = rotation_group if _merge == 1
		keep if _merge == 1 
		drop _merge
		
		/* check if any selected groups have been selected in the more recent 2011 release ("prolonged rotation groups") */
		merge m:m year country urtgrp using "${datapath}/EU-SILC/7 L-2011/2011D.dta"
		replace slctd_rtgrp = rotation_group if _merge == 1
		keep if _merge == 1 
		drop _merge
		
	destring drpout_year, replace 
	drop if slctd_rtgrp == 0
	
	/* for later checks */
	gen drpout_year2008 = drpout_year
	gen slctd_urtgrp2008 = urtgrp 	
	gen slctd_uhid2008 = uhid
	
	/* merge to masterfile */
	merge 1:1 year uhid using "${datapath}/EU-SILC/19 L-2023/masterD.dta"
	
		/* check for duplicates caused by same rotational groups in terms of same hid, different rotation_group */
		duplicates report year country hid
		duplicates tag year country hid, generate(test2)
		tab country year if test2 != 0 	
		tab urtgrp year  if test2 != 0
		
			/* check if the problem regards a large portion of the rotational group, if the portion is small ignore */
			gen tag1 = 0 
			replace tag1 = 1 if test2 != 0 
			bysort year country urtgrp : egen ndups = total(tag1)
			gen tag2 = 1 
			bysort year country urtgrp : egen tot = total(tag2)
			gen rdups = ndups / tot
			gen tag3 = 0 
			replace tag3 = 1 if rdups > 0.5
			drop tag1 tag2 ndups tot rdups
			
			/* extend selection to whole rotational group */
			bysort year country urtgrp : egen taga = max(tag3)
			drop tag3
			
			/* check if the rotational group with duplicates is the one covering most years in current release. If yes ignore */
			tab urtgrp year if taga == 1  & lgstgrp == 0 & _merge == 1
			drop if taga == 1 & lgstgrp == 0 & _merge == 1
			drop  test2 taga
			
			/* check for unbalances */
			bysort country : egen test3 = total(nrtgrp2009)
			bysort country : egen test4 = total(nrtgrp2010)
			bysort country : egen test5 = total(nrtgrp2011)
			replace test3 = 0 if test3 == .
			replace test4 = 0 if test4 == .
			replace test5 = 0 if test5 == .
			tab urtgrp year if ( test3 != 0 & lgstgrp == 0 & _merge == 1 ) & ( test4 != 0 & lgstgrp == 0 & _merge == 1 ) &( test5 != 0 & lgstgrp == 0 & _merge == 1 )
			drop if ( test3 != 0 & lgstgrp == 0 & _merge == 1 ) & ( test4 != 0 & lgstgrp == 0 & _merge == 1 ) &( test5 != 0 & lgstgrp == 0 & _merge == 1 )
			drop test3 test4 test5
			
		/* this is the updated masterfile */
		gen merge2008 = _merge
		drop _merge
		save "${datapath}/EU-SILC/19 L-2023/masterD.dta", replace
		
		/* this is 2008D file for later control */
		keep if merge2008 == 1 
		drop merge2008
		save "${datapath}/EU-SILC/4 L-2008/2008D.dta", replace			

		
/* 2007 */		
		/* open the 2007 Household register to get data from rotational groups inactive in more recent releases and their uhid */ 
		clear
		local filen : dir "${datapath}/EU-SILC/3 L-2007/"  files "udb_l07d_ver*"
		display `filen'
		local filel "${datapath}/EU-SILC/3 L-2007/"
		display `"`filel'"'
		local fileln : display `"`filel'"' `filen'
	use `"`fileln'"', clear
		
	local new_var = lower("`var'")

    foreach var of varlist _all {
    	local new_var = lower("`var'")
    	cap rename `var' `new_var'
    }

		*/ block Stata from displaying IDs in exponential format */ 
		tostring db030, replace
		gen year = db010
		gen country = db020
		gen hid = db030
		gen rotation_group = db075 
		sort country hid year
		replace country = "EL" if country == "GR"
		
		/* count the number of rotational groups for each country in this release */
		bysort country rotation_group: gen nvals = _n == 1
		bysort country : egen nrtgrp2007 = total(nvals)
		drop nvals 
		
		/* get the rotation group(s) that cover most years */
		bysort country rotation_group : egen maxyear = max(year) 
		bysort country rotation_group : egen minyear = min(year)
		gen years_cov = maxyear - minyear + 1
		bysort country : egen maxgrp = max(years_cov) 
		gen slctd_rtgrp = 0
		bysort country rotation_group: replace slctd_rtgrp = rotation_group if years_cov == maxgrp 
		gen lgstgrp = 0
		bysort country rotation_group: replace lgstgrp = 1 if years_cov == maxgrp
		
		/* build household and rotationgroup IDs that are unique across releases */
		tostring rotation_group, generate(rotation_groupstr)
		gen drpout_year = 0
		replace drpout_year = maxyear + 4 - years_cov
		
			/* check for rotation groups that dropped out before planned */
			bysort country rotation_group : egen maxyear_grp = max(year)
			replace drpout_year = maxyear_grp if maxyear_grp < maxyear
			
		tostring drpout_year, replace
		gen uhid = country + rotation_groupstr + drpout_year + hid
		gen urtgrp = country + rotation_groupstr + drpout_year
		destring drpout_year, replace 	
		
		/* check if any selected groups have been selected in the more recent 2008 release ("prolonged rotation groups") */
		sort year country rotation_group hid 
		merge m:m year country rotation_group using "${datapath}/EU-SILC/4 L-2008/2008D.dta"
		replace slctd_rtgrp = rotation_group if _merge == 1
		
		/* tag rotation groups that have already been selected in the more recent release in some years (overlapping) */
		gen atag = 0
		replace atag = 1 if _merge == 3
		bysort country rotation_group : egen btag = max(atag) 
		bysort country rotation_group : egen ndrpoy = max(drpout_year2008)
		replace drpout_year = ndrpoy if btag == 1
		drop atag btag ndrpoy
		
		/* update urtgrp and uhid so that "prolonged rotation groups" maintain their urtgrp across different releases */
		tostring drpout_year, replace
		replace uhid = country + rotation_groupstr + drpout_year + hid
		replace urtgrp = country + rotation_groupstr + drpout_year
		destring drpout_year, replace	
		drop rotation_groupstr maxyear_grp minyear years_cov maxgrp maxyear_grp maxyear
		
		/* drop overlapping rotation group years and data from the more recent release */
		keep if _merge == 1 
		drop _merge 
		
		/* check if any selected groups have been selected in the more recent 2009 release ("prolonged rotation groups") */
		merge m:m year country urtgrp using "${datapath}/EU-SILC/5 L-2009/2009D.dta"
		replace slctd_rtgrp = rotation_group if _merge == 1
		keep if _merge == 1 
		drop _merge
		
		/* check if any selected groups have been selected in the more recent 2010 release ("prolonged rotation groups") */
		merge m:m year country urtgrp using "${datapath}/EU-SILC/6 L-2010/2010D.dta"
		replace slctd_rtgrp = rotation_group if _merge == 1
		keep if _merge == 1 
		drop _merge
	destring drpout_year, replace 
	drop if slctd_rtgrp == 0
	
	/* for later checks */
	gen drpout_year2007 = drpout_year
	gen slctd_urtgrp2007 = urtgrp 	
	gen slctd_uhid2007 = uhid
	
	/* merge to masterfile */
	merge 1:1 year uhid using "${datapath}/EU-SILC/19 L-2023/masterD.dta"
	
		/* check for duplicates caused by same rotational groups in terms of same hid, different rotation_group */
		duplicates report year country hid
		duplicates tag year country hid, generate(test2)
		tab country year if test2 != 0 	
		tab urtgrp year  if test2 != 0 
		
			/* check if the problem regards a large portion of the rotational group, if the portion is small ignore */
			gen tag1 = 0 
			replace tag1 = 1 if test2 != 0 
			bysort year country urtgrp : egen ndups = total(tag1)
			gen tag2 = 1 
			bysort year country urtgrp : egen tot = total(tag2)
			gen rdups = ndups / tot
			gen tag3 = 0 
			replace tag3 = 1 if rdups > 0.5
			drop tag1 tag2 ndups tot rdups
			
			/* extend selection to whole rotational group */
			bysort year country urtgrp : egen taga = max(tag3)
			drop tag3
			
			/* check if the rotational group with duplicates is the one covering most years in current release. If yes ignore */
			tab urtgrp year if taga == 1  & lgstgrp == 0 & _merge == 1
			drop if taga == 1 & lgstgrp == 0 & _merge == 1
			drop  test2 taga
			
			/* check for unbalances */
			bysort country : egen test3 = total(nrtgrp2008)
			bysort country : egen test4 = total(nrtgrp2009)
			bysort country : egen test5 = total(nrtgrp2010)
			replace test3 = 0 if test3 == .
			replace test4 = 0 if test4 == .
			replace test5 = 0 if test5 == .
			tab urtgrp year if ( test3 != 0 & lgstgrp == 0 & _merge == 1 ) & ( test4 != 0 & lgstgrp == 0 & _merge == 1 ) & ( test5 != 0 & lgstgrp == 0 & _merge == 1 ) 	
			drop if ( test3 != 0 & lgstgrp == 0 & _merge == 1 ) & ( test4 != 0 & lgstgrp == 0 & _merge == 1 ) & ( test5 != 0 & lgstgrp == 0 & _merge == 1 )
			drop test3 test4 test5
			
		/* this is the updated masterfile */
		gen merge2007 = _merge
		drop _merge
		save "${datapath}/EU-SILC/19 L-2023/masterD.dta", replace
		
		/* this is 2007D file for later control */
		keep if merge2007 == 1 
		drop merge2007
		save "${datapath}/EU-SILC/3 L-2007/2007D.dta", replace			

/* 2006 */		
		/* open the 2006 Household register to get data from rotational groups inactive in more recent releases and their uhid */ 
		clear
		local filen : dir "${datapath}/EU-SILC/2 L-2006/"  files "udb_l06d_ver*"
		display `filen'
		local filel "${datapath}/EU-SILC/2 L-2006/"
		display `"`filel'"'
		local fileln : display `"`filel'"' `filen'
	use `"`fileln'"', clear
		
	local new_var = lower("`var'")

    foreach var of varlist _all {
    	local new_var = lower("`var'")
    	cap rename `var' `new_var'
    }

		*/ block Stata from displaying IDs in exponential format */ 
		tostring db030, replace
		gen year = db010
		gen country = db020
		gen hid = db030
		gen rotation_group = db075 
		sort country hid year
		replace country = "EL" if country == "GR"
		
		/* count the number of rotational groups for each country in this release */
		bysort country rotation_group: gen nvals = _n == 1
		bysort country : egen nrtgrp2006 = total(nvals)
		drop nvals 
		
		/* get the rotation group(s) that cover most years */
		bysort country rotation_group : egen maxyear = max(year) 
		bysort country rotation_group : egen minyear = min(year)
		gen years_cov = maxyear - minyear + 1
		bysort country : egen maxgrp = max(years_cov) 
		gen slctd_rtgrp = 0
		bysort country rotation_group: replace slctd_rtgrp = rotation_group if years_cov == maxgrp 
		gen lgstgrp = 0
		bysort country rotation_group: replace lgstgrp = 1 if years_cov == maxgrp
		
		/* build household and rotationgroup IDs that are unique across releases */
		tostring rotation_group, generate(rotation_groupstr)
		gen drpout_year = 0
		replace drpout_year = maxyear + 4 - years_cov
		
			/* check for rotation groups that dropped out before planned */
			bysort country rotation_group : egen maxyear_grp = max(year)
			replace drpout_year = maxyear_grp if maxyear_grp < maxyear
		tostring drpout_year, replace
		gen uhid = country + rotation_groupstr + drpout_year + hid
		gen urtgrp = country + rotation_groupstr + drpout_year
		destring drpout_year, replace 	
		
		/* check if any selected groups have been selected in the more recent 2007 release ("prolonged rotation groups") */
		sort year country rotation_group hid 
		merge m:m year country rotation_group using "${datapath}/EU-SILC/3 L-2007/2007D.dta"
		replace slctd_rtgrp = rotation_group if _merge == 1
		
		/* tag rotation groups that have already been selected in the more recent release in some years (overlapping) */
		gen atag = 0
		replace atag = 1 if _merge == 3
		bysort country rotation_group : egen btag = max(atag) 
		bysort country rotation_group : egen ndrpoy = max(drpout_year2007)
		replace drpout_year = ndrpoy if btag == 1
		drop atag btag ndrpoy
		
		/* update urtgrp and uhid so that "prolonged rotation groups" maintain their urtgrp across different releases */
		tostring drpout_year, replace
		replace uhid = country + rotation_groupstr + drpout_year + hid
		replace urtgrp = country + rotation_groupstr + drpout_year
		destring drpout_year, replace	
		drop rotation_groupstr maxyear_grp minyear years_cov maxgrp maxyear_grp maxyear
		
		/* drop overlapping rotation group years and data from the more recent release */
		keep if _merge == 1 
		drop _merge 
		
		/* check if any selected groups have been selected in the more recent 2008 release ("prolonged rotation groups") */
		merge m:m year country urtgrp using "${datapath}/EU-SILC/4 L-2008/2008D.dta"
		replace slctd_rtgrp = rotation_group if _merge == 1
		keep if _merge == 1 
		drop _merge
		
		/* check if any selected groups have been selected in the more recent 2009 release ("prolonged rotation groups") */
		merge m:m year country urtgrp using "${datapath}/EU-SILC/5 L-2009/2009D.dta"
		replace slctd_rtgrp = rotation_group if _merge == 1
		keep if _merge == 1 
		drop _merge
		
	destring drpout_year, replace 
	drop if slctd_rtgrp == 0
	
	/* for later checks */
	gen drpout_year2006 = drpout_year
	gen slctd_urtgrp2006 = urtgrp 	
	gen slctd_uhid2006 = uhid
	
	/* merge to masterfile */
	merge 1:1 year uhid using "${datapath}/EU-SILC/19 L-2023/masterD.dta"
	
		/* check for duplicates caused by same rotational groups in terms of same hid, different rotation_group */
		duplicates report year country hid
		duplicates tag year country hid, generate(test2)
		tab country year if test2 != 0 	
		tab urtgrp year  if test2 != 0 
		
			/* check if the problem regards a large portion of the rotational group, if the portion is small ignore */
			gen tag1 = 0 
			replace tag1 = 1 if test2 != 0 
			bysort year country urtgrp : egen ndups = total(tag1)
			gen tag2 = 1 
			bysort year country urtgrp : egen tot = total(tag2)
			gen rdups = ndups / tot
			gen tag3 = 0 
			replace tag3 = 1 if rdups > 0.5
			drop tag1 tag2 ndups tot rdups
			
			/* extend selection to whole rotational group */
			bysort year country urtgrp : egen taga = max(tag3)
			drop tag3
			
			/* check if the rotational group with duplicates is the one covering most years in current release. If yes ignore */
			tab urtgrp year if taga == 1  & lgstgrp == 0 & _merge == 1
			drop if taga == 1 & lgstgrp == 0 & _merge == 1
			drop  test2 taga
			
			/* check for unbalances */
			bysort country : egen test3 = total(nrtgrp2007)
			bysort country : egen test4 = total(nrtgrp2008)
			bysort country : egen test5 = total(nrtgrp2009)
			replace test3 = 0 if test3 == .
			replace test4 = 0 if test4 == .
			replace test5 = 0 if test5 == .
			tab urtgrp year if ( test3 != 0 & lgstgrp == 0 & _merge == 1 ) & ( test4 != 0 & lgstgrp == 0 & _merge == 1 ) &( test5 != 0 & lgstgrp == 0 & _merge == 1 )
			drop if ( test3 != 0 & lgstgrp == 0 & _merge == 1 ) & ( test4 != 0 & lgstgrp == 0 & _merge == 1 ) &( test5 != 0 & lgstgrp == 0 & _merge == 1 )
			drop test3 test4 test5
			
		/* this is the updated masterfile */
		gen merge2006 = _merge
		drop _merge
		save "${datapath}/EU-SILC/19 L-2023/masterD.dta", replace
		
		/* this is 2006D file for later control */
		keep if merge2006 == 1 
		drop merge2006
		save "${datapath}/EU-SILC/2 L-2006/2006D.dta", replace			

		
/* 2005 */	
		/* open the 2005 Household register to get data from rotational groups inactive in more recent releases and their uhid */ 
		clear
		local filen : dir "${datapath}/EU-SILC/1 L-2005/"  files "udb_l05d_ver*"
		display `filen'
		local filel "${datapath}/EU-SILC/1 L-2005/"
		display `"`filel'"'
		local fileln : display `"`filel'"' `filen'
	use `"`fileln'"', clear
		
		
	local new_var = lower("`var'")

    foreach var of varlist _all {
    	local new_var = lower("`var'")
    	cap rename `var' `new_var'
    }

		*/ block Stata from displaying IDs in exponential format */ 
		tostring db030, replace
		gen year = db010
		gen country = db020
		gen hid = db030
		gen rotation_group = db075
		sort country hid year
		replace country = "EL" if country == "GR"
		
		/* count the number of rotational groups for each country in this release */
		bysort country rotation_group: gen nvals = _n == 1
		bysort country : egen nrtgrp2005 = total(nvals)
		drop nvals 
		
		/* get the rotation group(s) that cover most years */
		bysort country rotation_group : egen maxyear = max(year) 
		bysort country rotation_group : egen minyear = min(year)
		gen years_cov = maxyear - minyear + 1
		bysort country : egen maxgrp = max(years_cov) 
		gen slctd_rtgrp = 0
		bysort country rotation_group: replace slctd_rtgrp = rotation_group if years_cov == maxgrp 
		gen lgstgrp = 0
		bysort country rotation_group: replace lgstgrp = 1 if years_cov == maxgrp
		
		/* build household and rotationgroup IDs that are unique across releases */
		tostring rotation_group, generate(rotation_groupstr)
		gen drpout_year = 0
		replace drpout_year = maxyear + 4 - years_cov
		
			/* check for rotation groups that dropped out before planned */
			bysort country rotation_group : egen maxyear_grp = max(year)
			replace drpout_year = maxyear_grp if maxyear_grp < maxyear
			
		tostring drpout_year, replace
		gen uhid = country + rotation_groupstr + drpout_year + hid
		gen urtgrp = country + rotation_groupstr + drpout_year
		destring drpout_year, replace 	
		
		/* check if any selected groups have been selected in the more recent 2006 release ("prolonged rotation groups") */
		sort year country rotation_group hid 
		merge m:m year country rotation_group using "${datapath}/EU-SILC/2 L-2006/2006D.dta"
		replace slctd_rtgrp = rotation_group if _merge == 1
		
		/* tag rotation groups that have already been selected in the more recent release in some years (overlapping) */
		gen atag = 0
		replace atag = 1 if _merge == 3
		bysort country rotation_group : egen btag = max(atag) 
		bysort country rotation_group : egen ndrpoy = max(drpout_year2006)
		replace drpout_year = ndrpoy if btag == 1
		drop atag btag ndrpoy
		
		/* update urtgrp and uhid so that "prolonged rotation groups" maintain their urtgrp across different releases */
		tostring drpout_year, replace
		replace uhid = country + rotation_groupstr + drpout_year + hid
		replace urtgrp = country + rotation_groupstr + drpout_year
		destring drpout_year, replace	
		drop rotation_groupstr maxyear_grp minyear years_cov maxgrp maxyear_grp maxyear
		
		/* drop overlapping rotation group years and data from the more recent release */
		keep if _merge == 1 
		drop _merge 
		
		/* check if any selected groups have been selected in the more recent 2007 release ("prolonged rotation groups") */
		merge m:m year country urtgrp using "${datapath}/EU-SILC/3 L-2007/2007D.dta"
		replace slctd_rtgrp = rotation_group if _merge == 1
		keep if _merge == 1 
		drop _merge
		
		/* check if any selected groups have been selected in the more recent 2008 release ("prolonged rotation groups") */
		merge m:m year country urtgrp using "${datapath}/EU-SILC/4 L-2008/2008D.dta"
		replace slctd_rtgrp = rotation_group if _merge == 1
		keep if _merge == 1 
		drop _merge
		
	destring drpout_year, replace 
	drop if slctd_rtgrp == 0
	
	/* for later checks */
	gen drpout_year2005 = drpout_year
	gen slctd_urtgrp2005 = urtgrp 	
	gen slctd_uhid2005 = uhid
	
	/* merge to masterfile */
	merge 1:1 year uhid using "${datapath}/EU-SILC/19 L-2023/masterD.dta"
	
		/* check for duplicates caused by same rotational groups in terms of same hid, different rotation_group */
		duplicates report year country hid
		duplicates tag year country hid, generate(test2)
		tab country year if test2 != 0 	
		tab urtgrp year  if test2 != 0 
		
			/* check if the problem regards a large portion of the rotational group, if the portion is small ignore */
			gen tag1 = 0 
			replace tag1 = 1 if test2 != 0 
			bysort year country urtgrp : egen ndups = total(tag1)
			gen tag2 = 1 
			bysort year country urtgrp : egen tot = total(tag2)
			gen rdups = ndups / tot
			gen tag3 = 0 
			replace tag3 = 1 if rdups > 0.5
			drop tag1 tag2 ndups tot rdups
			
			/* extend selection to whole rotational group */
			bysort year country urtgrp : egen taga = max(tag3)
			drop tag3
			
			/* check if the rotational group with duplicates is the one covering most years in current release. If yes ignore */
			tab urtgrp year if taga == 1  & lgstgrp == 0 & _merge == 1
			drop if taga == 1 & lgstgrp == 0 & _merge == 1
			drop  test2 taga
			
			/* check for unbalances */
			bysort country : egen test3 = total(nrtgrp2006)
			bysort country : egen test4 = total(nrtgrp2007)
			bysort country : egen test5 = total(nrtgrp2008)
			replace test3 = 0 if test3 == .
			replace test4 = 0 if test4 == .
			replace test5 = 0 if test5 == .
			tab urtgrp year if ( test3 != 0 & lgstgrp == 0 & _merge == 1 ) & ( test4 != 0 & lgstgrp == 0 & _merge == 1 ) &( test5 != 0 & lgstgrp == 0 & _merge == 1 )
			drop if ( test3 != 0 & lgstgrp == 0 & _merge == 1 ) & ( test4 != 0 & lgstgrp == 0 & _merge == 1 ) &( test5 != 0 & lgstgrp == 0 & _merge == 1 )
			drop test3 test4 test5
			
		/* this is the updated masterfile */
		gen merge2005 = _merge
		drop _merge
		save "${datapath}/EU-SILC/19 L-2023/masterD.dta", replace
		
		/* this is 2005D file for later control */
		keep if merge2005 == 1 
		drop merge2005
		save "${datapath}/EU-SILC/1 L-2005/2005D.dta", replace	
		
	/* clean up and generate yrelease */
	use "${datapath}/EU-SILC/19 L-2023/masterD.dta", clear 
	gen yrelease = 0 
	replace yrelease = 2020 if merge2020 == 1
	replace yrelease = 2019 if merge2019 == 1
	replace yrelease = 2018 if merge2018 == 1
	replace yrelease = 2017 if merge2017 == 1
	replace yrelease = 2016 if merge2016 == 1
	replace yrelease = 2015 if merge2015 == 1
	replace yrelease = 2014 if merge2014 == 1
	replace yrelease = 2013 if merge2013 == 1
	replace yrelease = 2012 if merge2012 == 1
	replace yrelease = 2011 if merge2011 == 1
	replace yrelease = 2010 if merge2010 == 1
	replace yrelease = 2009 if merge2009 == 1
	replace yrelease = 2008 if merge2008 == 1
	replace yrelease = 2007 if merge2007 == 1
	replace yrelease = 2006 if merge2006 == 1
	replace yrelease = 2005 if merge2005 == 1
	
	drop  slctd_rtgrp lgstgrp drpout_year maxgrp ///
	      nrtgrp*  drpout_year* slctd_urtgrp*  slctd_uhi*  merge* 

		  
	save "${datapath}/EU-SILC/19 L-2023/masterD.dta", replace
