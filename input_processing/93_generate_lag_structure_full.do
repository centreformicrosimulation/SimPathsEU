/*******************************************************************************
* PROJECT:      SimPaths EU
* SECTION:      Input processing
* OBJECT:       Generate comprehensive lag-structure workbook – all processes
*
* OUTPUT FILE:  documentation/SimPaths_lag_structure_full_{country}.xlsx
*
* SHEETS:
*   all_regressors   every individual regressor × one column per model
*   grouped          categorical dummies collapsed, one column per model
*   notes            legend / key
*
* CODING:
*   c    current-period value (no _L1 / _L2 suffix in the Excel header)
*   l    first-order lag  (_L1 suffix)
*   l2   second-order lag (_L2 suffix)
*
* COLUMNS:  one column per model, ordered by Order-in-Process:
*   P1 | R1a R1b | E1a E1b E2a | HO1 | H1 H2 |
*   W1fa W1ma W1fb W1mb | (RMSE excluded) |
*   U1 U2 | F1 | Single_female…SingleAC_Males | I1a I1b |
*   W1fa_sel W1ma_sel W1fb_sel W1mb_sel
*
* NOTES:
*   - Reads cleaned workbooks when available; falls back to raw input/country.
*   - Multi-outcome sheets (E2a → Low/Medium; H1 → Poor/Fair/Good/VeryGood/Excellent)
*     have outcome-category suffixes stripped before lag detection.
*   - Trailing lone underscores (proportional-odds shared coefficients) are stripped.
*   - reg_RMSE excluded: diagnostics only, not a behavioural process.
*   - Hyphenated sheet names (W1fa-sel etc.) stored in proc_sh_*; the corresponding
*     Stata-valid proc_key uses an underscore (W1fa_sel).
*   - liww* regressors (log-income-weighted working hours) grouped under
*     "hours worked / leisure" in the grouped sheet.
*
* AUTHOR:       SimPaths team
* LAST UPDATE:  2026-03-16
*******************************************************************************/

version 15.1
clear all
set more off

/*============================================================================
  USER SETTINGS  – edit these three locals to run for a different country
============================================================================*/
local country         "PL"
local CLEAN_INPUT_DIR "/Users/pineapple/IdeaProjects/SimPathsEU_JAN/input_processing/clean_excel_files_`country'"
local RAW_INPUT_DIR   "/Users/pineapple/IdeaProjects/SimPathsEU_JAN/input/`country'"
local OUTPUT_FILE     "/Users/pineapple/IdeaProjects/SimPathsEU_JAN/documentation/SimPaths_lag_structure_full_`country'.xlsx"


/*============================================================================
  HELPER: integer column number → Excel column letter(s)  (1=A, 27=AA …)
============================================================================*/
program define __col2xl, rclass
    version 15.1
    syntax, NUM(integer)
    local n = `num'
    local col ""
    while `n' > 0 {
        local rem = mod(`n' - 1, 26)
        local col = char(65 + `rem') + "`col'"
        local n   = floor((`n' - 1) / 26)
    }
    return local col "`col'"
end


/*============================================================================
  PROCESS (COLUMN) DEFINITIONS
  One column per individual model, following Order-in-Process.
  proc_key  = Stata-valid name (no hyphens)
  proc_sh_* = actual Excel sheet name (may differ: W1fa_sel → "W1fa-sel")
  proc_wb_* = workbook filename without .xlsx
  proc_desc_* = short description for header row
  proc_cats_* = outcome-category suffixes to strip (multi-outcome sheets)
============================================================================*/

* Ordered list of process keys (Stata-valid names)
local proc_keys ///
    P1 ///
    R1a R1b ///
    E1a E1b E2a ///
    HO1 ///
    H1 H2 ///
    W1fa W1ma W1fb W1mb ///
    U1 U2 ///
    F1 ///
    Single_female Single_male SingleDep_Females SingleDep_Males ///
    Couples SingleAC_Females SingleAC_Males ///
    I1a I1b ///
    W1fa_sel W1ma_sel W1fb_sel W1mb_sel

* ---- Workbooks ----
local proc_wb_P1                reg_leaveParentalHome
local proc_wb_R1a               reg_retirement
local proc_wb_R1b               reg_retirement
local proc_wb_E1a               reg_education
local proc_wb_E1b               reg_education
local proc_wb_E2a               reg_education
local proc_wb_HO1               reg_home_ownership
local proc_wb_H1                reg_health
local proc_wb_H2                reg_health
local proc_wb_W1fa              reg_wages
local proc_wb_W1ma              reg_wages
local proc_wb_W1fb              reg_wages
local proc_wb_W1mb              reg_wages
local proc_wb_U1                reg_partnership
local proc_wb_U2                reg_partnership
local proc_wb_F1                reg_fertility
local proc_wb_Single_female     reg_labourSupplyUtility
local proc_wb_Single_male       reg_labourSupplyUtility
local proc_wb_SingleDep_Females reg_labourSupplyUtility
local proc_wb_SingleDep_Males   reg_labourSupplyUtility
local proc_wb_Couples           reg_labourSupplyUtility
local proc_wb_SingleAC_Females  reg_labourSupplyUtility
local proc_wb_SingleAC_Males    reg_labourSupplyUtility
local proc_wb_I1a               reg_income
local proc_wb_I1b               reg_income
local proc_wb_W1fa_sel          reg_employmentSelection
local proc_wb_W1ma_sel          reg_employmentSelection
local proc_wb_W1fb_sel          reg_employmentSelection
local proc_wb_W1mb_sel          reg_employmentSelection

* ---- Actual sheet names within each workbook ----
local proc_sh_P1                P1
local proc_sh_R1a               R1a
local proc_sh_R1b               R1b
local proc_sh_E1a               E1a
local proc_sh_E1b               E1b
local proc_sh_E2a               E2a
local proc_sh_HO1               HO1
local proc_sh_H1                H1
local proc_sh_H2                H2
local proc_sh_W1fa              W1fa
local proc_sh_W1ma              W1ma
local proc_sh_W1fb              W1fb
local proc_sh_W1mb              W1mb
local proc_sh_U1                U1
local proc_sh_U2                U2
local proc_sh_F1                F1
local proc_sh_Single_female     Single_female
local proc_sh_Single_male       Single_male
local proc_sh_SingleDep_Females SingleDep_Females
local proc_sh_SingleDep_Males   SingleDep_Males
local proc_sh_Couples           Couples
local proc_sh_SingleAC_Females  SingleAC_Females
local proc_sh_SingleAC_Males    SingleAC_Males
local proc_sh_I1a               I1a
local proc_sh_I1b               I1b
local proc_sh_W1fa_sel          W1fa-sel
local proc_sh_W1ma_sel          W1ma-sel
local proc_sh_W1fb_sel          W1fb-sel
local proc_sh_W1mb_sel          W1mb-sel

* ---- Dependent variable title (header row 2 – "dependent variable") ----
local proc_dv_title_P1                "exited parental home"
local proc_dv_title_R1a               "enter retirement"
local proc_dv_title_R1b               "retired"
local proc_dv_title_E1a               "in continuous education"
local proc_dv_title_E1b               "return to education"
local proc_dv_title_E2a               "education level"
local proc_dv_title_HO1               "home ownership"
local proc_dv_title_H1                "health status"
local proc_dv_title_H2                "long-term sick or disabled"
local proc_dv_title_W1fa              "potential wage"
local proc_dv_title_W1ma              "potential wage"
local proc_dv_title_W1fb              "potential wage"
local proc_dv_title_W1mb              "potential wage"
local proc_dv_title_U1                "enter partnership"
local proc_dv_title_U2                "exit partnership"
local proc_dv_title_F1                "fertility"
local proc_dv_title_Single_female     "weekly labour supply"
local proc_dv_title_Single_male       "weekly labour supply"
local proc_dv_title_SingleDep_Females "weekly labour supply"
local proc_dv_title_SingleDep_Males   "weekly labour supply"
local proc_dv_title_Couples           "weekly labour supply"
local proc_dv_title_SingleAC_Females  "weekly labour supply"
local proc_dv_title_SingleAC_Males    "weekly labour supply"
local proc_dv_title_I1a               "capital income"
local proc_dv_title_I1b               "capital income"
local proc_dv_title_W1fa_sel          "employment selection"
local proc_dv_title_W1ma_sel          "employment selection"
local proc_dv_title_W1fb_sel          "employment selection"
local proc_dv_title_W1mb_sel          "employment selection"

* ---- Dependent variable code (header row 3 – "code") ----
local proc_dv_code_P1                "dlftphm"
local proc_dv_code_R1a               "drtren"
local proc_dv_code_R1b               "dlrtrd"
local proc_dv_code_E1a               "ded"
local proc_dv_code_E1b               "der"
local proc_dv_code_E2a               "deh_c3"
local proc_dv_code_HO1               "dhh_owned"
local proc_dv_code_H1                "dhe"
local proc_dv_code_H2                "dlltsd"
local proc_dv_code_W1fa              "fullTimeHourlyEarningsPotential"
local proc_dv_code_W1ma              "fullTimeHourlyEarningsPotential"
local proc_dv_code_W1fb              "fullTimeHourlyEarningsPotential"
local proc_dv_code_W1mb              "fullTimeHourlyEarningsPotential"
local proc_dv_code_U1                "dcpen"
local proc_dv_code_U2                "dcpex"
local proc_dv_code_F1                "dnc"
local proc_dv_code_Single_female     "labourSupplyWeekly"
local proc_dv_code_Single_male       "labourSupplyWeekly"
local proc_dv_code_SingleDep_Females "labourSupplyWeekly"
local proc_dv_code_SingleDep_Males   "labourSupplyWeekly"
local proc_dv_code_Couples           "labourSupplyWeekly"
local proc_dv_code_SingleAC_Females  "labourSupplyWeekly"
local proc_dv_code_SingleAC_Males    "labourSupplyWeekly"
local proc_dv_code_I1a               "ypncp"
local proc_dv_code_I1b               "ypncp"
local proc_dv_code_W1fa_sel          "lowWageOffer"
local proc_dv_code_W1ma_sel          "lowWageOffer"
local proc_dv_code_W1fb_sel          "lowWageOffer"
local proc_dv_code_W1mb_sel          "lowWageOffer"

* ---- Process descriptions (shown in header row 3 alongside process code) ----
local proc_desc_P1                "Leaving parental home"
local proc_desc_R1a               "Retirement decision"
local proc_desc_R1b               "Retirement decision"
local proc_desc_E1a               "Remaining in education"
local proc_desc_E1b               "Returning to education"
local proc_desc_E2a               "Education attainment"
local proc_desc_HO1               "Home ownership"
local proc_desc_H1                "Health transitions"
local proc_desc_H2                "Disability"
local proc_desc_W1fa              "Wage - female FT"
local proc_desc_W1ma              "Wage - male FT"
local proc_desc_W1fb              "Wage - female PT"
local proc_desc_W1mb              "Wage - male PT"
local proc_desc_U1                "Partnership entry"
local proc_desc_U2                "Partnership exit"
local proc_desc_F1                "Fertility"
local proc_desc_Single_female     "Labour supply - single female"
local proc_desc_Single_male       "Labour supply - single male"
local proc_desc_SingleDep_Females "Labour supply - single dep. female"
local proc_desc_SingleDep_Males   "Labour supply - single dep. male"
local proc_desc_Couples           "Labour supply - couple"
local proc_desc_SingleAC_Females  "Labour supply - single AC female"
local proc_desc_SingleAC_Males    "Labour supply - single AC male"
local proc_desc_I1a               "Income process (capital)"
local proc_desc_I1b               "Income process (capital, alt.)"
local proc_desc_W1fa_sel          "Emp. selection - female FT"
local proc_desc_W1ma_sel          "Emp. selection - male FT"
local proc_desc_W1fb_sel          "Emp. selection - female PT"
local proc_desc_W1mb_sel          "Emp. selection - male PT"

* ---- Outcome-category suffixes to strip (multi-outcome sheets; empty = none) ----
local proc_cats_P1
local proc_cats_R1a
local proc_cats_R1b
local proc_cats_E1a
local proc_cats_E1b
local proc_cats_E2a               Low Medium
local proc_cats_HO1
local proc_cats_H1                Poor Fair Good VeryGood Excellent
local proc_cats_H2
local proc_cats_W1fa
local proc_cats_W1ma
local proc_cats_W1fb
local proc_cats_W1mb
local proc_cats_U1
local proc_cats_U2
local proc_cats_F1
local proc_cats_Single_female
local proc_cats_Single_male
local proc_cats_SingleDep_Females
local proc_cats_SingleDep_Males
local proc_cats_Couples
local proc_cats_SingleAC_Females
local proc_cats_SingleAC_Males
local proc_cats_I1a
local proc_cats_I1b
local proc_cats_W1fa_sel
local proc_cats_W1ma_sel
local proc_cats_W1fb_sel
local proc_cats_W1mb_sel


/*============================================================================
  COLLECTION PHASE
  Read each model sheet; extract regressor names from column A; post triples
  (base_var, proc_key, lag_status) to a postfile.
============================================================================*/
tempname ph
tempfile ph_data

postfile `ph' str80 base_var str32 proc_key str4 lag_status ///
    using `ph_data', replace

foreach pk of local proc_keys {

    local wb   "`proc_wb_`pk''"
    local sh   "`proc_sh_`pk''"
    local cats "`proc_cats_`pk''"

    * Locate input file (prefer cleaned version)
    local infile "`CLEAN_INPUT_DIR'/`wb'.xlsx"
    capture confirm file "`infile'"
    if _rc local infile "`RAW_INPUT_DIR'/`wb'.xlsx"
    capture confirm file "`infile'"
    if _rc {
        di as err "  [SKIP] Workbook not found: `wb'.xlsx"
        continue
    }

    di as txt "Processing `wb' / `sh'  [proc: `pk']"

    capture noisily import excel "`infile'", sheet("`sh'") firstrow clear
    if _rc {
        di as err "  [SKIP] Cannot read sheet `sh' from `infile'"
        continue
    }

    * First column = REGRESSOR names
    quietly ds
    local rvar = word("`r(varlist)'", 1)

    quietly count
    local nrows = r(N)

    forvalues i = 1/`nrows' {

        local raw = strtrim(`rvar'[`i'])
        if "`raw'" == "" continue

        * Skip metadata / header rows
        local lraw = lower("`raw'")
        if regexm("`lraw'", "^(constant|regressor|coefficient|inversemillsratio)") continue
        if "`lraw'" == "." continue

        * ---- Strip outcome-category suffix (multi-outcome sheets only) ----
        local s "`raw'"
        foreach cat of local cats {
            if regexm("`s'", "_`cat'$") {
                local s = regexr("`s'", "_`cat'$", "")
            }
        }

        * Strip trailing lone underscore (shared proportional-odds coefficients)
        if regexm("`s'", "_$") local s = regexr("`s'", "_$", "")

        * ---- Determine lag status from suffix ----
        if      regexm("`s'", "_L2$") local lag "l2"
        else if regexm("`s'", "_L1$") local lag "l"
        else                           local lag "c"

        * Base variable: strip lag suffix
        if      "`lag'" == "l2" local base = regexr("`s'", "_L2$", "")
        else if "`lag'" == "l"  local base = regexr("`s'", "_L1$", "")
        else                    local base "`s'"

        if "`base'" == "" continue

        post `ph' ("`base'") ("`pk'") ("`lag'")
    }
}

postclose `ph'

di as txt _n "Collection complete."


/*============================================================================
  AGGREGATE
  For each (base_var, proc_key) pair, merge all observed lag statuses into a
  combined string: c, l, l2, c,l, c,l2, l,l2, or c,l,l2.
============================================================================*/
use `ph_data', clear

* Deduplicate exact triples
duplicates drop base_var proc_key lag_status, force

* Indicator variables for each lag type
gen byte has_c  = (lag_status == "c")
gen byte has_l  = (lag_status == "l")
gen byte has_l2 = (lag_status == "l2")

* Collapse: one row per (base_var, proc_key)
collapse (max) has_c has_l has_l2, by(base_var proc_key)

* Build combined lag string (c first, then l, then l2)
gen str8 combined_lag = ""
replace combined_lag = "c"       if has_c==1 & has_l==0 & has_l2==0
replace combined_lag = "l"       if has_c==0 & has_l==1 & has_l2==0
replace combined_lag = "l2"      if has_c==0 & has_l==0 & has_l2==1
replace combined_lag = "c,l"     if has_c==1 & has_l==1 & has_l2==0
replace combined_lag = "c,l2"    if has_c==1 & has_l==0 & has_l2==1
replace combined_lag = "l,l2"    if has_c==0 & has_l==1 & has_l2==1
replace combined_lag = "c,l,l2"  if has_c==1 & has_l==1 & has_l2==1

drop has_c has_l has_l2

* Reshape to wide: one column per proc_key
reshape wide combined_lag, i(base_var) j(proc_key) string

* Ensure all proc_key columns exist (fill with empty if absent)
foreach pk of local proc_keys {
    capture confirm variable combined_lag`pk'
    if _rc gen str8 combined_lag`pk' = ""
    replace combined_lag`pk' = "" if combined_lag`pk' == "."
}

* Rename to lag_{proc_key}
foreach pk of local proc_keys {
    rename combined_lag`pk' lag_`pk'
}

/*---- Sort rows by meaningful display order ---------------------------------
  sort_grp 1: core person characteristics
  sort_grp 2: income / wealth / wage variables
  sort_grp 3: macro / time controls
  sort_grp 9: anything else (alphabetical)
---------------------------------------------------------------------------*/
gen str80 bv_upper = upper(base_var)
gen byte sort_grp = 9

* Core characteristics
replace sort_grp = 1 if regexm(bv_upper, "^(DGN|DGNSP)")
replace sort_grp = 1 if regexm(bv_upper, "^(DAG|DAGSQ|RCS)")
replace sort_grp = 1 if regexm(bv_upper, "^(DED|DEH|DEHM|DEHF|DEHSP)")
replace sort_grp = 1 if regexm(bv_upper, "^(DCPST|DHHTP|DCPYY|DCPAGDF|NEW_REL)")
replace sort_grp = 1 if regexm(bv_upper, "^(DNC|D_CHILDREN)")
replace sort_grp = 1 if regexm(bv_upper, "^(DHE|DHM|DHMGHQ|GHQ|DLLTSD)")
replace sort_grp = 1 if regexm(bv_upper, "^(LES_C|LESSP|LESDF|REACHED_RETIREMENT)")

* Income / wealth
replace sort_grp = 2 if regexm(bv_upper, "^(YDSES|YPNBIHS|YPTCIIHS|INCOMEDIV|YNBCPDF)")
replace sort_grp = 2 if regexm(bv_upper, "^(YPLGRS|YPNCP|YPNOAB)")
replace sort_grp = 2 if regexm(bv_upper, "^(LOG_HOURLY|FULLTIMEHOURLY|LIWW)")
replace sort_grp = 2 if regexm(bv_upper, "^(DHH_OWN|DHHOWN)")

* Macro / time controls
replace sort_grp = 3 if regexm(bv_upper, "^(PL[0-9]|EL[0-9]|IT[0-9]|HU[0-9])")
replace sort_grp = 3 if regexm(bv_upper, "^(YEAR_TRANSFORMED|Y[0-9]{4}|Y2223)")
replace sort_grp = 3 if regexm(bv_upper, "^(POST2015|POST2020|FERTILITYRATE|REALWAGEGROWTH)")

sort sort_grp base_var

* ---- Covariate description for col B of all_regressors ----
gen str160 bv_desc = ""
replace bv_desc = "Gender (1=male)"                         if regexm(bv_upper, "^DGN$")
replace bv_desc = "Spouse gender"                           if regexm(bv_upper, "^DGNSP$")
replace bv_desc = "Age (years)"                             if regexm(bv_upper, "^DAG$")
replace bv_desc = "Age squared"                             if regexm(bv_upper, "^DAGSQ$")
replace bv_desc = "Age restricted cubic spline"             if regexm(bv_upper, "^RCS")
replace bv_desc = "In education"                            if regexm(bv_upper, "^DED")
replace bv_desc = "Education level category"                if regexm(bv_upper, "^DEH_C")
replace bv_desc = "Spouse education level"                  if regexm(bv_upper, "^DEHSP")
replace bv_desc = "Mother's education level"                if regexm(bv_upper, "^DEHM")
replace bv_desc = "Father's education level"                if regexm(bv_upper, "^DEHF")
replace bv_desc = "Partnership status category"             if regexm(bv_upper, "^DCPST")
replace bv_desc = "Household type"                          if regexm(bv_upper, "^DHHTP")
replace bv_desc = "Years since partnership formed"          if regexm(bv_upper, "^DCPYY")
replace bv_desc = "Age difference from partner"             if regexm(bv_upper, "^DCPAGDF")
replace bv_desc = "New relationship indicator"              if regexm(bv_upper, "^NEW_REL")
replace bv_desc = "Number of children"                      if regexm(bv_upper, "^DNC")
replace bv_desc = "Children present"                        if regexm(bv_upper, "^D_CHILDREN")
replace bv_desc = "Health status (1=Poor to 5=Excellent)"   if regexm(bv_upper, "^DHE$")
replace bv_desc = "Health status category"                  if regexm(bv_upper, "^DHE_C")
replace bv_desc = "Spouse health status"                    if regexm(bv_upper, "^DHESP")
replace bv_desc = "Mental health (GHQ score)"               if regexm(bv_upper, "^(DHM|DHMGHQ|GHQ)")
replace bv_desc = "Long-term sick or disabled"              if regexm(bv_upper, "^DLLTSD")
replace bv_desc = "Activity status category"                if regexm(bv_upper, "^LES_C")
replace bv_desc = "Spouse activity status"                  if regexm(bv_upper, "^LESSP")
replace bv_desc = "Activity status difference (couple)"     if regexm(bv_upper, "^LESDF")
replace bv_desc = "Reached retirement age"                  if regexm(bv_upper, "^REACHED_RETIREMENT")
replace bv_desc = "Household income quintile"               if regexm(bv_upper, "^YDSES")
replace bv_desc = "Household non-benefit income"            if regexm(bv_upper, "^YPNBIHS")
replace bv_desc = "Total capital + transfer income (hh)"    if regexm(bv_upper, "^YPTCIIHS")
replace bv_desc = "Income diversity index"                  if regexm(bv_upper, "^INCOMEDIV$")
replace bv_desc = "Income diversity index (squared)"        if regexm(bv_upper, "^INCOMESQDIV")
replace bv_desc = "Non-benefit income difference (couple)"  if regexm(bv_upper, "^YNBCPDF")
replace bv_desc = "Employment income – gross"               if regexm(bv_upper, "^YPLGRS")
replace bv_desc = "Capital income"                          if regexm(bv_upper, "^YPNCP")
replace bv_desc = "Pension / old-age benefit income"        if regexm(bv_upper, "^YPNOAB")
replace bv_desc = "Log leisure / hours worked"              if regexm(bv_upper, "^LIWW")
replace bv_desc = "Log potential hourly wage"               if regexm(bv_upper, "^LOG_HOURLY")
replace bv_desc = "Potential full-time hourly wage"         if regexm(bv_upper, "^FULLTIMEHOURLY")
replace bv_desc = "Home owner"                              if regexm(bv_upper, "^(DHH_OWN|DHHOWN)")
replace bv_desc = "Region (NUTS Level 1)"                   if regexm(bv_upper, "^(PL[0-9]|EL[0-9]|IT[0-9]|HU[0-9])")
replace bv_desc = "Year"            if regexm(bv_upper, "^Y[0-9]{4}$") | regexm(bv_upper, "^Y2223$")
replace bv_desc = "Time trend"                              if regexm(bv_upper, "^YEAR_TRANSFORMED")
replace bv_desc = "Post-2015 indicator"                     if regexm(bv_upper, "^POST2015")
replace bv_desc = "Post-2020 indicator"                     if regexm(bv_upper, "^POST2020")
replace bv_desc = "Fertility rate (macro)"                  if regexm(bv_upper, "^FERTILITYRATE")
replace bv_desc = "Real wage growth (macro)"                if regexm(bv_upper, "^REALWAGEGROWTH")

drop bv_upper sort_grp

* Save for both sheets
tempfile wide_data
save `wide_data'


/*============================================================================
  WRITE SHEET 1: all_regressors
  Col A : covariate code  (regressor base name, e.g. Deh_c4_Low)
  Col B : covariate name  (human-readable description)
  Col C : row-type label in header rows; "process" label in row 4
  Cols D+: one column per model, in Order-in-Process order

  Header layout (4 rows):
    Row 1 – A="", B="", C="process group",      D+=process description
    Row 2 – A="", B="", C="dependent variable", D+=dep-var title
    Row 3 – A="", B="", C="code",               D+=dep-var code
    Row 4 – A="covariate code", B="covariate name", C="process", D+=model code
    Row 5+ – data
============================================================================*/
di as txt _n "Writing sheet: all_regressors"

putexcel set "`OUTPUT_FILE'", sheet("all_regressors") replace

* ---- Row 1 (process group name) ----
putexcel A1 = ""
putexcel B1 = ""
putexcel C1 = "process group", bold

* ---- Row 2 (dependent variable title) ----
putexcel A2 = ""
putexcel B2 = ""
putexcel C2 = "dependent variable", bold

* ---- Row 3 (dependent variable code) ----
putexcel A3 = ""
putexcel B3 = ""
putexcel C3 = "code", bold

* ---- Row 4 (model / process code) ----
putexcel A4 = "covariate code", bold
putexcel B4 = "covariate name", bold
putexcel C4 = "process",        bold

local cnum = 4
foreach pk of local proc_keys {
    __col2xl, num(`cnum')
    local xlc "`r(col)'"
    putexcel `xlc'1 = "`proc_desc_`pk''"
    putexcel `xlc'2 = "`proc_dv_title_`pk''"
    putexcel `xlc'3 = "`proc_dv_code_`pk''"
    putexcel `xlc'4 = "`pk'", bold
    local ++cnum
}

* ---- Data rows (start at row 5) ----
local nobs = _N
forvalues r = 1/`nobs' {
    local rnum = `r' + 4
    putexcel A`rnum' = base_var[`r']
    local desc = bv_desc[`r']
    if "`desc'" != "" & "`desc'" != "." putexcel B`rnum' = "`desc'"

    local cnum = 4
    foreach pk of local proc_keys {
        __col2xl, num(`cnum')
        local xlc "`r(col)'"
        local val = lag_`pk'[`r']
        if "`val'" != "" & "`val'" != "." {
            putexcel `xlc'`rnum' = "`val'"
        }
        local ++cnum
    }
}

di as txt "  → `nobs' regressors written."


/*============================================================================
  PREPARE GROUPED DATA
  Apply categorical-grouping rules to collapse dummies to their base variable,
  then aggregate lag statuses within each (grp_var × proc_key).

  Grouping rules (applied to upper-cased base_var):
    Age transforms    DAG*, DAGSQ, RCS*        → "age (dag)"
    Gender            DGN*, DGNSP              → "gender (dgn)"
    Education dummies DED*, DEH_C*, DEHSP*     → "education level (deh)"
    Maternal educ.    DEHM*                    → "maternal education (dehm)"
    Paternal educ.    DEHF*                    → "paternal education (dehf)"
    Partnership       DCPST*, DHHTP*, etc.     → "partnership status (dcpst)"
    Children          DNC*, D_CHILDREN*        → "children (dnc, dnc02)"
    Health (cats)     DHE_C*                   → "health status (dhe)"
    Mental health     DHM*, GHQ*               → "mental health (dhm)"
    Disability        DLLTSD*                  → "disability status (dlltsd)"
    Activity status   LES_C*, LESSP*, LESDF*   → "activity status (les)"
    HH income / SES   YDSES*, YPNBIHS*, etc.   → "household income / SES (ydses_c5)"
    Emp. income       YPLGRS*                  → "employment income (yplgrs)"
    Capital income    YPNCP*                   → "capital income (ypncp)"
    Pension income    YPNOAB*                  → "pension income (ypnoab)"
    Hours / leisure   LIWW*                    → "hours worked / leisure (liwwh)"
    Potential wage    LOG_HOURLY*, FULLTIMEHOURLY* → "potential wage"
    Home ownership    DHH_OWN*, DHHOWN*        → "home owner (dhh_owned)"
    Region dummies    PL#, EL#, IT#, HU#       → "region (drgn1)"
    Year dummies      Y20**, YEAR_TRANSFORMED* → "year / time trend (stm)"
    Other trends      POST*, FERTILITYRATE, …  → "year / time trend (stm)"
============================================================================*/
use `wide_data', clear

gen str80 bv_upper = upper(base_var)
gen str80 grp_var   = base_var
gen str80 grp_label = base_var

* Age and age transforms
replace grp_var   = "age"                         if regexm(bv_upper, "^(DAG|DAGSQ|RCS)")
replace grp_label = "Age"                         if regexm(bv_upper, "^(DAG|DAGSQ|RCS)")

* Gender
replace grp_var   = "gender"                      if regexm(bv_upper, "^(DGN|DGNSP)$")
replace grp_label = "Gender"                      if regexm(bv_upper, "^(DGN|DGNSP)$")

* Own education: dummies and indicators (ded = in-education flag; deh_c* = attainment dummies)
replace grp_var   = "education"                   if regexm(bv_upper, "^(DED|DEH_C)")
replace grp_label = "Education level"             if regexm(bv_upper, "^(DED|DEH_C)")

* Spouse education (kept separate from own education)
replace grp_var   = "spouse_education"            if regexm(bv_upper, "^DEHSP")
replace grp_label = "Spouse education"            if regexm(bv_upper, "^DEHSP")

* Maternal education
replace grp_var   = "maternal_education"          if regexm(bv_upper, "^DEHM")
replace grp_label = "Maternal education"          if regexm(bv_upper, "^DEHM")

* Paternal education
replace grp_var   = "paternal_education"          if regexm(bv_upper, "^DEHF")
replace grp_label = "Paternal education"          if regexm(bv_upper, "^DEHF")

* Partnership / household structure
replace grp_var   = "partnership_status"          if regexm(bv_upper, "^(DCPST|DHHTP|DCPYY|DCPAGDF|NEW_REL)")
replace grp_label = "Partnership status"          if regexm(bv_upper, "^(DCPST|DHHTP|DCPYY|DCPAGDF|NEW_REL)")

* Children
replace grp_var   = "children"                   if regexm(bv_upper, "^(DNC|D_CHILDREN)")
replace grp_label = "Number of children"          if regexm(bv_upper, "^(DNC|D_CHILDREN)")

* Health status categories (dhe = own health; dhesp = spouse health)
replace grp_var   = "health_status"               if regexm(bv_upper, "^DHE") | regexm(bv_upper, "^DHESP")
replace grp_label = "Health status"               if regexm(bv_upper, "^DHE") | regexm(bv_upper, "^DHESP")

* Mental health
replace grp_var   = "mental_health"               if regexm(bv_upper, "^(DHM|DHMGHQ|GHQ)")
replace grp_label = "Mental health"               if regexm(bv_upper, "^(DHM|DHMGHQ|GHQ)")

* Disability
replace grp_var   = "disability"                  if regexm(bv_upper, "^DLLTSD")
replace grp_label = "Disability status"           if regexm(bv_upper, "^DLLTSD")

* Activity / employment status
replace grp_var   = "activity_status"             if regexm(bv_upper, "^(LES_C|LESSP|LESDF|REACHED_RETIREMENT_AGE)")
replace grp_label = "Activity status"             if regexm(bv_upper, "^(LES_C|LESSP|LESDF|REACHED_RETIREMENT_AGE)")

* Household income / SES
replace grp_var   = "ses_income"                  if regexm(bv_upper, "^(YDSES|YPNBIHS|YPTCIIHS|INCOMEDIV|INCOMESQDIV|YNBCPDF)")
replace grp_label = "Household income / SES"      if regexm(bv_upper, "^(YDSES|YPNBIHS|YPTCIIHS|INCOMEDIV|INCOMESQDIV|YNBCPDF)")

* Employment income
replace grp_var   = "employment_income"           if regexm(bv_upper, "^YPLGRS")
replace grp_label = "Employment income"           if regexm(bv_upper, "^YPLGRS")

* Capital income
replace grp_var   = "capital_income"              if regexm(bv_upper, "^YPNCP")
replace grp_label = "Capital income"              if regexm(bv_upper, "^YPNCP")

* Pension income
replace grp_var   = "pension_income"              if regexm(bv_upper, "^YPNOAB")
replace grp_label = "Pension income"              if regexm(bv_upper, "^YPNOAB")

* Hours worked / leisure utility terms (liww* = log-income-weighted working hours)
replace grp_var   = "hours_leisure"               if regexm(bv_upper, "^LIWW")
replace grp_label = "Hours worked / leisure"      if regexm(bv_upper, "^LIWW")

* Potential wage
replace grp_var   = "potential_wage"              if regexm(bv_upper, "^(LOG_HOURLY|FULLTIMEHOURLY)")
replace grp_label = "Potential wage"              if regexm(bv_upper, "^(LOG_HOURLY|FULLTIMEHOURLY)")

* Home ownership
replace grp_var   = "home_ownership"              if regexm(bv_upper, "^(DHH_OWN|DHHOWN)")
replace grp_label = "Home owner"                  if regexm(bv_upper, "^(DHH_OWN|DHHOWN)")

* Region dummies
replace grp_var   = "region"                      if regexm(bv_upper, "^(PL[0-9]|EL[0-9]|IT[0-9]|HU[0-9])")
replace grp_label = "Region"                      if regexm(bv_upper, "^(PL[0-9]|EL[0-9]|IT[0-9]|HU[0-9])")

* Year dummies and time trends
replace grp_var   = "year"  if regexm(bv_upper, "^Y[0-9]{4}$")
replace grp_var   = "year"  if regexm(bv_upper, "^Y2223$")
replace grp_var   = "year"  if regexm(bv_upper, "^(YEAR_TRANSFORMED|POST2015|POST2020|FERTILITYRATE|REALWAGEGROWTH)")
replace grp_label = "Year / time trend"           if grp_var == "year"

drop bv_upper

* Save pre-collapse snapshot; used later for the strict-grouped sheet
tempfile grpraw_data
save `grpraw_data'

/*---- Aggregate: one row per (grp_var × proc_key) -------------------------
  Convert each lag_{pk} string to binary indicators, collapse with max,
  then rebuild the combined lag string.
---------------------------------------------------------------------------*/
foreach pk of local proc_keys {
    gen byte g_c_`pk'  = strpos(lag_`pk', "c")  > 0
    gen byte g_l_`pk'  = (strpos(lag_`pk', ",l") > 0) | (lag_`pk' == "l")
    gen byte g_l2_`pk' = strpos(lag_`pk', "l2") > 0
    drop lag_`pk'
}

collapse (max) g_c_* g_l_* g_l2_* (firstnm) grp_label, by(grp_var)

foreach pk of local proc_keys {
    gen str8 grp_lag_`pk' = ""
    replace grp_lag_`pk' = "c"       if g_c_`pk'==1 & g_l_`pk'==0 & g_l2_`pk'==0
    replace grp_lag_`pk' = "l"       if g_c_`pk'==0 & g_l_`pk'==1 & g_l2_`pk'==0
    replace grp_lag_`pk' = "l2"      if g_c_`pk'==0 & g_l_`pk'==0 & g_l2_`pk'==1
    replace grp_lag_`pk' = "c,l"     if g_c_`pk'==1 & g_l_`pk'==1 & g_l2_`pk'==0
    replace grp_lag_`pk' = "c,l2"    if g_c_`pk'==1 & g_l_`pk'==0 & g_l2_`pk'==1
    replace grp_lag_`pk' = "l,l2"    if g_c_`pk'==0 & g_l_`pk'==1 & g_l2_`pk'==1
    replace grp_lag_`pk' = "c,l,l2"  if g_c_`pk'==1 & g_l_`pk'==1 & g_l2_`pk'==1
    drop g_c_`pk' g_l_`pk' g_l2_`pk'
}

* Sort grouped rows
gen bv_upper = upper(grp_var)
gen byte sort_grp = 9
replace sort_grp = 1 if inlist(grp_var, "gender", "age", "education", "spouse_education", "maternal_education", "paternal_education")
replace sort_grp = 1 if inlist(grp_var, "partnership_status", "children", "health_status", "mental_health", "disability")
replace sort_grp = 1 if grp_var == "activity_status"
replace sort_grp = 2 if inlist(grp_var, "ses_income", "employment_income", "capital_income")
replace sort_grp = 2 if inlist(grp_var, "pension_income", "potential_wage", "home_ownership", "hours_leisure")
replace sort_grp = 3 if inlist(grp_var, "region", "year")
sort sort_grp grp_var
drop bv_upper sort_grp

* ---- Canonical variable code for col A of grouped sheet ----
gen str80 grp_code = grp_var          // default: use internal key as code
replace grp_code = "dgn"                            if grp_var == "gender"
replace grp_code = "dag"                            if grp_var == "age"
replace grp_code = "deh"                            if grp_var == "education"
replace grp_code = "dehsp"                          if grp_var == "spouse_education"
replace grp_code = "dehm"                           if grp_var == "maternal_education"
replace grp_code = "dehf"                           if grp_var == "paternal_education"
replace grp_code = "dcpst"                          if grp_var == "partnership_status"
replace grp_code = "dnc"                            if grp_var == "children"
replace grp_code = "dhe"                            if grp_var == "health_status"
replace grp_code = "dhm"                            if grp_var == "mental_health"
replace grp_code = "dlltsd"                         if grp_var == "disability"
replace grp_code = "les_c4"                         if grp_var == "activity_status"
replace grp_code = "ydses_c5"                       if grp_var == "ses_income"
replace grp_code = "yplgrs"                         if grp_var == "employment_income"
replace grp_code = "ypncp"                          if grp_var == "capital_income"
replace grp_code = "ypnoab"                         if grp_var == "pension_income"
replace grp_code = "liwwh"                          if grp_var == "hours_leisure"
replace grp_code = "fullTimeHourlyEarningsPotential" if grp_var == "potential_wage"
replace grp_code = "dhh_owned"                      if grp_var == "home_ownership"
replace grp_code = "drgn1"                          if grp_var == "region"
replace grp_code = "stm"                            if grp_var == "year"

tempfile grouped_data
save `grouped_data'


/*============================================================================
  WRITE SHEET 2: grouped
  Col A : covariate code  (canonical SimPaths variable name, e.g. deh, dag)
  Col B : covariate name  (human-readable group label)
  Col C : row-type label in header rows; "process" label in row 4
  Cols D+: one column per model

  Header layout (4 rows):
    Row 1 – A="", B="", C="process group",      D+=process description
    Row 2 – A="", B="", C="dependent variable", D+=dep-var title
    Row 3 – A="", B="", C="code",               D+=dep-var code
    Row 4 – A="covariate code", B="covariate name", C="process", D+=model code
    Row 5+ – data
============================================================================*/
di as txt _n "Writing sheet: grouped"

putexcel set "`OUTPUT_FILE'", sheet("grouped") modify

* ---- Row 1 (process group name) ----
putexcel A1 = ""
putexcel B1 = ""
putexcel C1 = "process group", bold

* ---- Row 2 (dependent variable title) ----
putexcel A2 = ""
putexcel B2 = ""
putexcel C2 = "dependent variable", bold

* ---- Row 3 (dependent variable code) ----
putexcel A3 = ""
putexcel B3 = ""
putexcel C3 = "code", bold

* ---- Row 4 (model / process code) ----
putexcel A4 = "covariate code", bold
putexcel B4 = "covariate name", bold
putexcel C4 = "process",        bold

local cnum = 4
foreach pk of local proc_keys {
    __col2xl, num(`cnum')
    local xlc "`r(col)'"
    putexcel `xlc'1 = "`proc_desc_`pk''"
    putexcel `xlc'2 = "`proc_dv_title_`pk''"
    putexcel `xlc'3 = "`proc_dv_code_`pk''"
    putexcel `xlc'4 = "`pk'", bold
    local ++cnum
}

local ngrp = _N
forvalues r = 1/`ngrp' {
    local rnum = `r' + 4
    putexcel A`rnum' = grp_code[`r']
    putexcel B`rnum' = grp_label[`r']

    local cnum = 4
    foreach pk of local proc_keys {
        __col2xl, num(`cnum')
        local xlc "`r(col)'"
        local val = grp_lag_`pk'[`r']
        if "`val'" != "" & "`val'" != "." {
            putexcel `xlc'`rnum' = "`val'"
        }
        local ++cnum
    }
}

di as txt "  → `ngrp' grouped rows written."


/*============================================================================
  PREPARE STRICT-GROUPED DATA
  Uses the same conceptual groups as the grouped sheet, but rows are only
  collapsed when they share IDENTICAL lag patterns across every model column.
  One row per unique (conceptual group × lag-signature vector).

  Method:
    1. Reload pre-collapse snapshot (one row per base_var, with grp_var assigned).
    2. Build a lag-signature string by concatenating all lag_{pk} values.
    3. Deduplicate on (grp_var, lag_signature): dummies with the same pattern
       merge into one row; those with differing patterns stay separate.
============================================================================*/
use `grpraw_data', clear

* ---- Canonical variable code (same mapping as grouped sheet) ----
gen str80 grp_code = grp_var
replace grp_code = "dgn"                             if grp_var == "gender"
replace grp_code = "dag"                             if grp_var == "age"
replace grp_code = "deh"                             if grp_var == "education"
replace grp_code = "dehsp"                           if grp_var == "spouse_education"
replace grp_code = "dehm"                            if grp_var == "maternal_education"
replace grp_code = "dehf"                            if grp_var == "paternal_education"
replace grp_code = "dcpst"                           if grp_var == "partnership_status"
replace grp_code = "dnc"                             if grp_var == "children"
replace grp_code = "dhe"                             if grp_var == "health_status"
replace grp_code = "dhm"                             if grp_var == "mental_health"
replace grp_code = "dlltsd"                          if grp_var == "disability"
replace grp_code = "les_c4"                          if grp_var == "activity_status"
replace grp_code = "ydses_c5"                        if grp_var == "ses_income"
replace grp_code = "yplgrs"                          if grp_var == "employment_income"
replace grp_code = "ypncp"                           if grp_var == "capital_income"
replace grp_code = "ypnoab"                          if grp_var == "pension_income"
replace grp_code = "liwwh"                           if grp_var == "hours_leisure"
replace grp_code = "fullTimeHourlyEarningsPotential" if grp_var == "potential_wage"
replace grp_code = "dhh_owned"                       if grp_var == "home_ownership"
replace grp_code = "drgn1"                           if grp_var == "region"
replace grp_code = "stm"                             if grp_var == "year"

* ---- Build lag-pattern signature (concatenate all lag values) ----
gen str512 lag_sig = ""
foreach pk of local proc_keys {
    replace lag_sig = lag_sig + "|" + lag_`pk'
}

* ---- Build combined column labels for each (grp_var × lag-signature) --------
*
*   Col A  base_var_combined  : ALL covariate codes in the group joined with
*                               " / " — mirrors col A of the all_regressors sheet
*                               (e.g. "Deh_c3_Low / Deh_c3_Low_Dag / Deh_c3_Medium")
*   Col B  bv_desc_combined   : DISTINCT descriptions joined with " / "
*                               (e.g. "Education level category / In education")
*
*   Both use sequential forvalues accumulation; max group size is computed
*   dynamically so the loop length adapts to the actual data.
*
* -- Col A : base_var_combined ------------------------------------------------
preserve
    keep grp_var lag_sig base_var
    sort grp_var lag_sig base_var
    * Determine the largest group size to set forvalues upper bound
    bysort grp_var lag_sig: gen int _gcnt = _N
    qui summarize _gcnt
    local max_bv = r(max)
    drop _gcnt
    * Accumulate: row k gets the combined string from row k-1 plus own code
    gen str2000 base_var_combined = base_var
    forvalues k = 2/`max_bv' {
        by grp_var lag_sig: replace base_var_combined = base_var_combined[_n-1] + " / " + base_var ///
            if _n == `k'
    }
    by grp_var lag_sig: keep if _n == _N   // last row = fully concatenated
    keep grp_var lag_sig base_var_combined
    tempfile bvar_map
    save `bvar_map'
restore
merge m:1 grp_var lag_sig using `bvar_map', nogenerate

* -- Col B : bv_desc_combined (distinct descriptions only) --------------------
preserve
    keep grp_var lag_sig bv_desc
    bysort grp_var lag_sig bv_desc: keep if _n == 1   // one row per distinct description
    sort grp_var lag_sig bv_desc
    bysort grp_var lag_sig: gen int _dcnt = _N
    qui summarize _dcnt
    local max_dv = r(max)
    drop _dcnt
    gen str320 bv_desc_combined = bv_desc
    forvalues k = 2/`max_dv' {
        by grp_var lag_sig: replace bv_desc_combined = bv_desc_combined[_n-1] + " / " + bv_desc ///
            if _n == `k'
    }
    by grp_var lag_sig: keep if _n == _N   // last row = fully concatenated
    keep grp_var lag_sig bv_desc_combined
    tempfile desc_map
    save `desc_map'
restore
merge m:1 grp_var lag_sig using `desc_map', nogenerate

* ---- Deduplicate: keep one row per unique (group × lag pattern) ----
duplicates drop grp_var lag_sig, force

* ---- Sort (same priority tiers as grouped sheet) ----
gen byte sort_grp = 9
replace sort_grp = 1 if inlist(grp_var, "gender", "age", "education", "spouse_education", "maternal_education", "paternal_education")
replace sort_grp = 1 if inlist(grp_var, "partnership_status", "children", "health_status", "mental_health", "disability")
replace sort_grp = 1 if grp_var == "activity_status"
replace sort_grp = 2 if inlist(grp_var, "ses_income", "employment_income", "capital_income")
replace sort_grp = 2 if inlist(grp_var, "pension_income", "potential_wage", "home_ownership", "hours_leisure")
replace sort_grp = 3 if inlist(grp_var, "region", "year")
sort sort_grp grp_var lag_sig
drop sort_grp lag_sig

tempfile tgrouped_data
save `tgrouped_data'


/*============================================================================
  WRITE SHEET 3: grouped_strict
  Identical layout to grouped, but rows are merged only when all model-column
  lag values are the same.  Groups with heterogeneous lag patterns appear as
  multiple rows (same col A label, different lag values across columns D+).

  Header layout (4 rows): same as grouped and all_regressors
  Col A : covariate code(s) (base_var_combined — same codes as the
          all_regressors sheet; multiple codes merged into one row are joined
          with " / ", e.g. "Deh_c3_Low / Deh_c3_Low_Dag / Deh_c3_Medium")
  Col B : covariate name(s) (bv_desc_combined — distinct descriptions joined
          with " / ", e.g. "Education level category / In education")
  Col C : row-type label / "process" in row 4
  Cols D+: one column per model
============================================================================*/
di as txt _n "Writing sheet: grouped_strict"

putexcel set "`OUTPUT_FILE'", sheet("grouped_strict") modify

* ---- Row 1 (process group name) ----
putexcel A1 = ""
putexcel B1 = ""
putexcel C1 = "process group", bold

* ---- Row 2 (dependent variable title) ----
putexcel A2 = ""
putexcel B2 = ""
putexcel C2 = "dependent variable", bold

* ---- Row 3 (dependent variable code) ----
putexcel A3 = ""
putexcel B3 = ""
putexcel C3 = "code", bold

* ---- Row 4 (model / process code) ----
putexcel A4 = "covariate code", bold
putexcel B4 = "covariate name", bold
putexcel C4 = "process",        bold

local cnum = 4
foreach pk of local proc_keys {
    __col2xl, num(`cnum')
    local xlc "`r(col)'"
    putexcel `xlc'1 = "`proc_desc_`pk''"
    putexcel `xlc'2 = "`proc_dv_title_`pk''"
    putexcel `xlc'3 = "`proc_dv_code_`pk''"
    putexcel `xlc'4 = "`pk'", bold
    local ++cnum
}

local ntgrp = _N
forvalues r = 1/`ntgrp' {
    local rnum = `r' + 4
    putexcel A`rnum' = base_var_combined[`r']
    local cdesc = bv_desc_combined[`r']
    if "`cdesc'" == "." local cdesc = ""
    putexcel B`rnum' = "`cdesc'"

    local cnum = 4
    foreach pk of local proc_keys {
        __col2xl, num(`cnum')
        local xlc "`r(col)'"
        local val = lag_`pk'[`r']
        if "`val'" != "" & "`val'" != "." {
            putexcel `xlc'`rnum' = "`val'"
        }
        local ++cnum
    }
}

di as txt "  → `ntgrp' strict-grouped rows written."


/*============================================================================
  WRITE SHEET 4: notes
============================================================================*/
di as txt _n "Writing sheet: notes"

putexcel set "`OUTPUT_FILE'", sheet("notes") modify

putexcel A1 = "SimPaths lag-structure: key and rules", bold

* ── Section 1: Lag codes ────────────────────────────────────────────────────
putexcel A3 = "1. Lag codes", bold
putexcel A4 = "Code",    bold
putexcel B4 = "Meaning", bold
putexcel A5 = "c"
putexcel B5 = "Current-period value – no _L1 or _L2 suffix in the regressor name"
putexcel A6 = "l"
putexcel B6 = "First-order lag – regressor name ends with _L1"
putexcel A7 = "l2"
putexcel B7 = "Second-order lag – regressor name ends with _L2"
putexcel A8 = "c,l"
putexcel B8 = "Both current and first-order lagged values present for the same regressor in the same model"
putexcel A9 = "c,l2"
putexcel B9 = "Both current and second-order lagged values present"
putexcel A10 = "l,l2"
putexcel B10 = "Both first- and second-order lags present"
putexcel A11 = "c,l,l2"
putexcel B11 = "All three lag forms present"

* ── Section 2: Sheets ────────────────────────────────────────────────────────
putexcel A13 = "2. Sheets", bold
putexcel A14 = "Sheet",        bold
putexcel B14 = "Description",  bold
putexcel A15 = "all_regressors"
putexcel B15 = "One row per individual base variable found across all estimation workbooks (lag suffixes and outcome-category suffixes stripped). Columns A-B give the variable code and its description; column C carries the process-section label; columns D onward show lag usage per model."
putexcel A16 = "grouped"
putexcel B16 = "Categorical dummy sets collapsed to one row per conceptual group using the maximum lag observed across dummies in the group. Column A gives the canonical EM variable code; column B gives the group label. See Section 4 for grouping rules."
putexcel A17 = "grouped_strict"
putexcel B17 = "Same conceptual grouping as the grouped sheet, but rows are only merged when ALL lag values are identical across every model column. Rows with different lag patterns within the same conceptual group remain as separate rows. Columns A-B show the combined covariate codes and descriptions of the merged variables. Use this sheet to identify groups where different dummies of the same variable are treated with different lag structures across processes."
putexcel A18 = "schedule_check"
putexcel B18 = "Timing consistency audit. Lists every (process, covariate) pair where a current-period value (lag = c) is used, cross-referenced against the schedule order of the process that produces that variable. Flag meanings — CHECK: the producing process runs later in the schedule so the c value has not yet been updated this period and is effectively behaving as a lagged value (potential modelling issue to review); same module: producer and consumer are in the same schedule block (ambiguous, depends on within-module ordering); OK: producer runs before consumer so the c value is genuinely up-to-date; exogenous: variable is not produced by any behavioural process (age, gender, region, macro variables) and is always safe to use as c. Rows are sorted with CHECK first. Schedule order: 1 Leaving home, 2 Retirement, 3 Education, 4 Home ownership, 5 Health, 6 Wages, 8 Partnership, 9 Fertility, 10 Labour supply, 11 Income, 12 Employment selection."
putexcel A19 = "notes"
putexcel B19 = "This sheet."

* ── Section 3: Technical rules ───────────────────────────────────────────────
putexcel A21 = "3. Processing rules", bold
putexcel A22 = "Rule",        bold
putexcel B22 = "Detail",      bold
putexcel A23 = "Workbook lookup"
putexcel B23 = "Cleaned workbooks (clean_excel_files_{country}/) are used when available; raw input/{country}/ is used as fallback."
putexcel A24 = "Category stripping"
putexcel B24 = "Multi-outcome sheets embed outcome labels in regressor names. E2a: _Low and _Medium suffixes are stripped. H1: _Poor, _Fair, _Good, _VeryGood and _Excellent suffixes are stripped. This ensures Deh_c4_Low and Deh_c4_Medium collapse to the same base variable Deh_c4."
putexcel A25 = "Trailing underscores"
putexcel B25 = "Proportional-odds models share some coefficients across outcomes; these are coded with a trailing underscore (e.g. PL4_). The underscore is stripped before lag detection."
putexcel A26 = "RMSE excluded"
putexcel B26 = "reg_RMSE is a diagnostics workbook and is not a behavioural process; it is excluded throughout."
putexcel A27 = "Hyphenated sheet names"
putexcel B27 = "Employment-selection sheets are named W1fa-sel etc. in Excel. The corresponding Stata proc_key uses an underscore (W1fa_sel) for compatibility."
putexcel A28 = "Column ordering"
putexcel B28 = "Model columns follow the Order-in-Process sequence: P1 | R1a R1b | E1a E1b E2a | HO1 | H1 H2 | W1fa W1ma W1fb W1mb | U1 U2 | F1 | labour supply (7 types) | I1a I1b | employment selection (4 types)."

* ── Section 4: Grouped-sheet category rules ──────────────────────────────────
putexcel A30 = "4. Grouping rules (grouped and grouped_strict sheets)", bold
putexcel A31 = "EM code",      bold
putexcel B31 = "Group label",  bold
putexcel C31 = "Base-variable patterns collapsed into this group", bold

putexcel A32 = "dgn"
putexcel B32 = "Gender"
putexcel C32 = "Dgn, Dgnsp (exact match)"

putexcel A33 = "dag"
putexcel B33 = "Age"
putexcel C33 = "Dag, Dagsq, Rcs* (age restricted cubic splines)"

putexcel A34 = "deh"
putexcel B34 = "Education level"
putexcel C34 = "Ded (in-education flag), Deh_c* (attainment category dummies)"

putexcel A35 = "dehsp"
putexcel B35 = "Spouse education"
putexcel C35 = "Dehsp* – kept separate from own education"

putexcel A36 = "dehm"
putexcel B36 = "Maternal education"
putexcel C36 = "Dehm*"

putexcel A37 = "dehf"
putexcel B37 = "Paternal education"
putexcel C37 = "Dehf*"

putexcel A38 = "dcpst"
putexcel B38 = "Partnership status"
putexcel C38 = "Dcpst*, Dhhtp*, Dcpyy (years in partnership), Dcpagdf (age difference), New_rel"

putexcel A39 = "dnc"
putexcel B39 = "Number of children"
putexcel C39 = "Dnc*, D_children*"

putexcel A40 = "dhe"
putexcel B40 = "Health status"
putexcel C40 = "Dhe* (own health, 1=Poor to 5=Excellent) and Dhesp* (spouse health) – combined"

putexcel A41 = "dhm"
putexcel B41 = "Mental health"
putexcel C41 = "Dhm*, Dhmghq*, Ghq* (GHQ subjective wellbeing score)"

putexcel A42 = "dlltsd"
putexcel B42 = "Disability status"
putexcel C42 = "Dlltsd* (long-term sick or disabled)"

putexcel A43 = "les_c4"
putexcel B43 = "Activity status"
putexcel C43 = "Les_c* (own), Lessp* (spouse), Lesdf* (couple joint status), Reached_retirement_age"

putexcel A44 = "ydses_c5"
putexcel B44 = "Household income / SES"
putexcel C44 = "Ydses* (quintiles), Ypnbihs* (non-benefit income), Yptciihs*, Incomediv*, Ynbcpdf* (couple income difference)"

putexcel A45 = "yplgrs"
putexcel B45 = "Employment income"
putexcel C45 = "Yplgrs* (gross personal employment income)"

putexcel A46 = "ypncp"
putexcel B46 = "Capital income"
putexcel C46 = "Ypncp* (personal capital income)"

putexcel A47 = "ypnoab"
putexcel B47 = "Pension income"
putexcel C47 = "Ypnoab* (pension / old-age benefit income)"

putexcel A48 = "liwwh"
putexcel B48 = "Hours worked / leisure"
putexcel C48 = "Liww* (log-income-weighted working hours / leisure utility terms)"

putexcel A49 = "fullTimeHourlyEarningsPotential"
putexcel B49 = "Potential wage"
putexcel C49 = "Log_hourly*, FullTimeHourly* (potential hourly wage)"

putexcel A50 = "dhh_owned"
putexcel B50 = "Home owner"
putexcel C50 = "Dhh_own*, Dhhown* (home ownership dummy)"

putexcel A51 = "drgn1"
putexcel B51 = "Region"
putexcel C51 = "Country-specific NUTS1 region dummies: PL1–PL9, EL1–EL9, IT1–IT9, HU1–HU9"

putexcel A52 = "stm"
putexcel B52 = "Year / time trend"
putexcel C52 = "Year dummies (Y2010–Y2023, Y2223), Year_transformed (linear trend), Post2015, Post2020, FertilityRate, RealWageGrowth"

/*============================================================================
  WRITE SHEET 5: schedule_check
  For every (process, covariate) pair where the lag code includes "c"
  (current-period value), this sheet compares the consuming process's
  schedule order against the order of the process that produces / updates
  that covariate.

  Schedule order (from SimPathsEU_Schedule):
    1  P1          Leaving parental home
    2  R1a, R1b    Retirement
    3  E1a, E1b, E2a  Education
    4  HO1         Home ownership
    5  H1, H2      Health
    6  W1fa/ma/fb/mb  Potential wages
    8  U1, U2      Partnership  (7 = RMSE, excluded)
    9  F1          Fertility
   10  Single_*, Couples, SingleAC_*  Labour supply
   11  I1a, I1b    Income
   12  W1*_sel     Employment selection

  Flag meanings:
    ⚠ CHECK      Producer runs AFTER consumer → c value not yet updated;
                 effectively behaves as a lagged value
    ~ same module  Producer and consumer are in the same module block
    ✓ OK         Producer runs before consumer → c is already updated
    – exogenous  Variable is not produced by any behavioural process
============================================================================*/
di as txt _n "Writing sheet: schedule_check"

* ---- load all_regressors data; reshape to long (one row per base_var × process) ----
use `wide_data', clear
keep base_var bv_desc lag_*

reshape long lag_, i(base_var) j(proc_key) string
rename lag_ lag_code

* drop rows where the variable does not appear in this process
drop if lag_code == "" | lag_code == "."

* keep only observations where the current-period value is used
keep if regexm(lag_code, "c")

* ---- consumer: schedule order and module label ----
gen int consumer_order = .
replace consumer_order = 1  if proc_key == "P1"
replace consumer_order = 2  if inlist(proc_key, "R1a", "R1b")
replace consumer_order = 3  if inlist(proc_key, "E1a", "E1b", "E2a")
replace consumer_order = 4  if proc_key == "HO1"
replace consumer_order = 5  if inlist(proc_key, "H1", "H2")
replace consumer_order = 6  if inlist(proc_key, "W1fa", "W1ma", "W1fb", "W1mb")
replace consumer_order = 8  if inlist(proc_key, "U1", "U2")
replace consumer_order = 9  if proc_key == "F1"
replace consumer_order = 10 if inlist(proc_key, "Single_female", "Single_male", "SingleDep_Females")
replace consumer_order = 10 if inlist(proc_key, "SingleDep_Males", "Couples", "SingleAC_Females", "SingleAC_Males")
replace consumer_order = 11 if inlist(proc_key, "I1a", "I1b")
replace consumer_order = 12 if inlist(proc_key, "W1fa_sel", "W1ma_sel", "W1fb_sel", "W1mb_sel")

gen str60 consumer_module = ""
replace consumer_module = "1 · Leaving home"    if proc_key == "P1"
replace consumer_module = "2 · Retirement"      if inlist(proc_key, "R1a", "R1b")
replace consumer_module = "3 · Education"       if inlist(proc_key, "E1a", "E1b", "E2a")
replace consumer_module = "4 · Home ownership"  if proc_key == "HO1"
replace consumer_module = "5 · Health"          if inlist(proc_key, "H1", "H2")
replace consumer_module = "6 · Wages"           if inlist(proc_key, "W1fa", "W1ma", "W1fb", "W1mb")
replace consumer_module = "8 · Partnership"     if inlist(proc_key, "U1", "U2")
replace consumer_module = "9 · Fertility"       if proc_key == "F1"
replace consumer_module = "10 · Labour supply"  if inlist(proc_key, "Single_female", "Single_male", "SingleDep_Females")
replace consumer_module = "10 · Labour supply"  if inlist(proc_key, "SingleDep_Males", "Couples", "SingleAC_Females", "SingleAC_Males")
replace consumer_module = "11 · Income"         if inlist(proc_key, "I1a", "I1b")
replace consumer_module = "12 · Employment sel." if inlist(proc_key, "W1fa_sel", "W1ma_sel", "W1fb_sel", "W1mb_sel")

* ---- producer: which process updates this covariate? ----
gen bv_upper = upper(base_var)

gen int  producer_order  = .
gen str60 producer_proc  = ""
gen str60 producer_module = ""

* 1 · Leaving home: P1 → dlftphm
replace producer_order  = 1               if regexm(bv_upper, "^DLFTPHM")
replace producer_proc   = "P1"            if regexm(bv_upper, "^DLFTPHM")
replace producer_module = "1 · Leaving home" if regexm(bv_upper, "^DLFTPHM")

* 2 · Retirement: R1a → drtren, R1b → dlrtrd
replace producer_order  = 2               if regexm(bv_upper, "^(DRTREN|DLRTRD)")
replace producer_proc   = "R1a / R1b"     if regexm(bv_upper, "^(DRTREN|DLRTRD)")
replace producer_module = "2 · Retirement" if regexm(bv_upper, "^(DRTREN|DLRTRD)")

* 3 · Education: E1a → ded, E1b → der, E2a → deh_c3; spouse education same order
replace producer_order  = 3               if regexm(bv_upper, "^DED($|_)")
replace producer_proc   = "E1a"           if regexm(bv_upper, "^DED($|_)")
replace producer_module = "3 · Education" if regexm(bv_upper, "^DED($|_)")

replace producer_order  = 3               if regexm(bv_upper, "^DER($|_)")
replace producer_proc   = "E1b"           if regexm(bv_upper, "^DER($|_)")
replace producer_module = "3 · Education" if regexm(bv_upper, "^DER($|_)")

replace producer_order  = 3               if regexm(bv_upper, "^DEH_C")
replace producer_proc   = "E2a"           if regexm(bv_upper, "^DEH_C")
replace producer_module = "3 · Education" if regexm(bv_upper, "^DEH_C")

replace producer_order  = 3               if regexm(bv_upper, "^DEHSP")
replace producer_proc   = "E2a (spouse)"  if regexm(bv_upper, "^DEHSP")
replace producer_module = "3 · Education" if regexm(bv_upper, "^DEHSP")

* 4 · Home ownership: HO1 → dhh_owned
replace producer_order  = 4                  if regexm(bv_upper, "^(DHH_OWN|DHHOWN)")
replace producer_proc   = "HO1"              if regexm(bv_upper, "^(DHH_OWN|DHHOWN)")
replace producer_module = "4 · Home ownership" if regexm(bv_upper, "^(DHH_OWN|DHHOWN)")

* 5 · Health: H1 → dhe (own + spouse); H2 → dlltsd (own + spouse)
replace producer_order  = 5               if regexm(bv_upper, "^DHE($|_)")
replace producer_proc   = "H1"            if regexm(bv_upper, "^DHE($|_)")
replace producer_module = "5 · Health"    if regexm(bv_upper, "^DHE($|_)")

replace producer_order  = 5               if regexm(bv_upper, "^DHESP")
replace producer_proc   = "H1 (spouse)"   if regexm(bv_upper, "^DHESP")
replace producer_module = "5 · Health"    if regexm(bv_upper, "^DHESP")

replace producer_order  = 5               if regexm(bv_upper, "^DLLTSD($|_)")
replace producer_proc   = "H2"            if regexm(bv_upper, "^DLLTSD($|_)")
replace producer_module = "5 · Health"    if regexm(bv_upper, "^DLLTSD($|_)")

replace producer_order  = 5               if regexm(bv_upper, "^DLLTSDSP")
replace producer_proc   = "H2 (spouse)"   if regexm(bv_upper, "^DLLTSDSP")
replace producer_module = "5 · Health"    if regexm(bv_upper, "^DLLTSDSP")

* 6 · Wages: W1* produce potential earnings; liwwh / leisure terms derived from wages
replace producer_order  = 6              if regexm(bv_upper, "^(LIWWH|LIWWHSQ|MALELEISURE|FEMALELEISURE|HRS_40PLUS|L1_LOG_HOURLY)")
replace producer_proc   = "W1 (wages)"   if regexm(bv_upper, "^(LIWWH|LIWWHSQ|MALELEISURE|FEMALELEISURE|HRS_40PLUS|L1_LOG_HOURLY)")
replace producer_module = "6 · Wages"    if regexm(bv_upper, "^(LIWWH|LIWWHSQ|MALELEISURE|FEMALELEISURE|HRS_40PLUS|L1_LOG_HOURLY)")

* 8 · Partnership: U1/U2 → dcpst, dcpen, dcpex, dcpagdf, dcpyy, new_rel, dhhtp
replace producer_order  = 8                if regexm(bv_upper, "^(DCPST|DCPEN|DCPEX|DCPAGDF|DCPYY|NEW_REL|DHHTP)")
replace producer_proc   = "U1 / U2"        if regexm(bv_upper, "^(DCPST|DCPEN|DCPEX|DCPAGDF|DCPYY|NEW_REL|DHHTP)")
replace producer_module = "8 · Partnership" if regexm(bv_upper, "^(DCPST|DCPEN|DCPEX|DCPAGDF|DCPYY|NEW_REL|DHHTP)")

* 9 · Fertility: F1 → dnc (incl. dnc02), d_children
replace producer_order  = 9               if regexm(bv_upper, "^(DNC|D_CHILDREN)")
replace producer_proc   = "F1"            if regexm(bv_upper, "^(DNC|D_CHILDREN)")
replace producer_module = "9 · Fertility" if regexm(bv_upper, "^(DNC|D_CHILDREN)")

* 10 · Labour supply → les_c4 (own + spouse + couple)
replace producer_order  = 10                  if regexm(bv_upper, "^(LES_C|LESSP|LESDF)")
replace producer_proc   = "Labour supply"     if regexm(bv_upper, "^(LES_C|LESSP|LESDF)")
replace producer_module = "10 · Labour supply" if regexm(bv_upper, "^(LES_C|LESSP|LESDF)")

* 11 · Income: I1a/I1b → ypncp; income aggregates, ydses quintile
replace producer_order  = 11             if regexm(bv_upper, "^(YPNCP|YPLGRS|YPNBIHS|YPTCIIHS|YNBCPDF|LN_YPNCP|INCOMEDIV|INCOMESQ|YDSES)")
replace producer_proc   = "I1a / I1b"    if regexm(bv_upper, "^(YPNCP|YPLGRS|YPNBIHS|YPTCIIHS|YNBCPDF|LN_YPNCP|INCOMEDIV|INCOMESQ|YDSES)")
replace producer_module = "11 · Income"  if regexm(bv_upper, "^(YPNCP|YPLGRS|YPNBIHS|YPTCIIHS|YNBCPDF|LN_YPNCP|INCOMEDIV|INCOMESQ|YDSES)")

drop bv_upper

* ---- flag ----
* Note: in Stata missing (.) > all real numbers, so guard with != . before < / >
gen str30 flag = ""
replace flag = "- exogenous"   if producer_order == .
replace flag = "OK"            if producer_order != . & producer_order < consumer_order
replace flag = "same module"   if producer_order != . & producer_order == consumer_order
replace flag = "CHECK"         if producer_order != . & producer_order > consumer_order

* sort: issues first, then same-module, then OK, then exogenous; break ties by consumer order then variable name
gen int flag_sort = 4
replace flag_sort = 1 if flag == "CHECK"
replace flag_sort = 2 if flag == "same module"
replace flag_sort = 3 if flag == "OK"
sort flag_sort consumer_order base_var proc_key
drop flag_sort

* ---- write to Excel ----
putexcel set "`OUTPUT_FILE'", sheet("schedule_check") modify

putexcel A1 = "Schedule vs. lag-usage check", bold
putexcel A2 = "Shows every (process, covariate) pair where a current-period value (lag = c) is used. The flag compares the consuming process's schedule order against the order of the process that produces that variable."
putexcel A3 = "Flag meanings:   CHECK = producer runs AFTER consumer (c is effectively lagged and has not been updated yet this period);   same module = producer and consumer are in the same schedule block;   OK = producer runs before consumer;   exogenous = variable is not produced by any behavioural process."

putexcel A5 = "Covariate code",    bold
putexcel B5 = "Covariate name",    bold
putexcel C5 = "Consuming process", bold
putexcel D5 = "Consumer module",   bold
putexcel E5 = "Consumer order",    bold
putexcel F5 = "Lag used",          bold
putexcel G5 = "Producing process", bold
putexcel H5 = "Producer module",   bold
putexcel I5 = "Producer order",    bold
putexcel J5 = "Flag",              bold

local nsc = _N
forvalues r = 1/`nsc' {
    local rnum = `r' + 5

    local bvcode = base_var[`r']
    putexcel A`rnum' = "`bvcode'"

    local desc = bv_desc[`r']
    if "`desc'" == "." local desc = ""
    putexcel B`rnum' = "`desc'"

    local pk   = proc_key[`r']
    putexcel C`rnum' = "`pk'"

    local cmod = consumer_module[`r']
    putexcel D`rnum' = "`cmod'"

    local cord = consumer_order[`r']
    putexcel E`rnum' = `cord'

    local lc = lag_code[`r']
    putexcel F`rnum' = "`lc'"

    local pprc = producer_proc[`r']
    putexcel G`rnum' = "`pprc'"

    local pmod = producer_module[`r']
    putexcel H`rnum' = "`pmod'"

    local pord = producer_order[`r']
    if `pord' != . putexcel I`rnum' = `pord'

    local fl = flag[`r']
    putexcel J`rnum' = "`fl'"
}

di as txt "  -> `nsc' current-lag rows written to schedule_check."

di as res _n "Lag-structure workbook written to:" _n "  `OUTPUT_FILE'"
