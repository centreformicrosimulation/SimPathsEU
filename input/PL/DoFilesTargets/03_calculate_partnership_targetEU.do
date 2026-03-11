version 17.0
clear all
set more off

* Paths (edit if needed)
local work_dir "/Users/pineapple/Library/CloudStorage/OneDrive-UniversityofEssex/WorkCEMPA/SimPathsEU/validate_alignments"
local country "PL"
local input_dir  "`work_dir'/`country'/input_data"

* ============================================================
* 1) Load and append all initial population files 2011-2023
* ============================================================
tempfile appended
clear
save `appended', emptyok replace

forval yr = 2011/2023 {
    capture import delimited using "`input_dir'/population_initial_`country'_`yr'.csv", ///
        clear varnames(1) bindquote(strict)
    if _rc != 0 {
        di as error "WARNING: could not load population_initial_`country'_`yr'.csv — skipping"
        continue
    }
    destring dag idperson idbenefitunit idmother idfather dwt, replace force
    gen int file_year = `yr'
    append using `appended'
    save `appended', replace
}

use `appended', clear

* ============================================================
* 2) Define partnered share — BU membership logic
*
*  Eligible  : dag >= 18
*  Partnered : there exists at least one OTHER adult (age >= 18)
*              in the same benefit unit (file_year x idbenefitunit)
*              who is NOT this person's mother or father
*
*  idpartner is NOT used — partnership is inferred purely from
*  BU co-residency, consistent with getPartner() logic.
* ============================================================
keep if dag >= 18

* Keep only the variables needed for the join
keep file_year idbenefitunit idperson idmother idfather dag dwt

* --- Step A: build list of BU adult members to self-join against ---
preserve
    keep file_year idbenefitunit idperson
    rename idperson other_idperson
    tempfile bu_adults
    save `bu_adults', replace
restore

* --- Step B: self-join on (file_year, idbenefitunit) ---
* Each person is expanded against all adults in their BU
joinby file_year idbenefitunit using `bu_adults'

* Remove self-matches
drop if other_idperson == idperson

* Remove cases where the co-resident is this person's parent
drop if other_idperson == idmother | other_idperson == idfather

* Each remaining row means a qualifying co-resident exists
gen byte has_partner = 1

* Reduce to one row per person: partnered = 1 if any qualifying row
collapse (max) partnered = has_partner, by(file_year idbenefitunit idperson)

* --- Step C: save partnered flags, then merge into full eligible pop ---
* joinby silently drops persons with NO qualifying co-resident, so we
* must restore them from the full dataset and assign partnered = 0.

tempfile partnered_flags
save `partnered_flags', replace

* Reload full eligible population as master
use `appended', clear
destring dag idperson idbenefitunit idmother idfather dwt, replace force
keep if dag >= 18
keep file_year idbenefitunit idperson dwt

* Merge partnered flags in as using — unmatched master = no partner
merge 1:1 file_year idbenefitunit idperson using `partnered_flags', ///
    keep(master match) nogen
replace partnered = 0 if missing(partnered)

* ============================================================
* 3) Collapse to annual weighted share
* ============================================================
collapse (mean) partnered_share = partnered ///
         (sum)  n_eligible = partnered      ///   raw count only for reference
         [pw = dwt], by(file_year)

* n_eligible above is sum of weights — replace with unweighted count if preferred
* For unweighted N alongside weighted share, use a two-step approach:
* Step 1: save weighted share
tempfile weighted_share
save `weighted_share', replace

* Step 2: unweighted counts
use `appended', clear
destring dag idperson idbenefitunit dwt, replace force
keep if dag >= 18
keep file_year idbenefitunit idperson

merge 1:1 file_year idbenefitunit idperson using `partnered_flags', ///
    keep(master match) nogen
replace partnered = 0 if missing(partnered)

collapse (count) n_eligible = idperson ///
         (sum)   n_partnered = partnered, by(file_year)

merge 1:1 file_year using `weighted_share', nogen

rename file_year year

format partnered_share %12.7f

label var n_eligible      "Eligible persons (age >= 18, unweighted N)"
label var n_partnered     "Partnered persons (unweighted N)"
label var partnered_share "Partnered share (weighted by dwt)"

order year n_eligible n_partnered partnered_share

* ============================================================
* 4) Full comparison table
* ============================================================
//export excel using "`work_dir'/partnered_share_initialPop_BUlogic.xlsx", ///
//    firstrow(variables) replace

* ============================================================
* 5) Slim target-format file: year + partnered_share only
* ============================================================
preserve
    keep year partnered_share
    format partnered_share %12.7f
    export excel using "`work_dir'/partnered_share_targets_BUlogic.xlsx", ///
        firstrow(variables) replace
restore

list, sep(0)
