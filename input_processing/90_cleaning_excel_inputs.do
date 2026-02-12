****************************************************
* Clean regression Excel workbooks (no overwrite)
* Output:
*   OUTPUT_DIR/<original filename>.xlsx
*
* For each workbook:
*   - Copies sheets: Info, Gof (no changes; if present)
*   - Cleans model sheets:
*       * drop rows that are completely empty (type-safe, no egen)
*       * drop columns that are completely empty (type-safe)
****************************************************

clear all
set more off

/****************************************************
* USER SETTINGS
****************************************************/
local country "PL"

local INPUT_DIR  "/Users/pineapple/IdeaProjects/SimPathsEU_JAN/input/`country'"
local OUTPUT_DIR "/Users/pineapple/IdeaProjects/SimPathsEU_JAN/input_processing/clean_excel_files_`country'"
local EXT "xlsx"

* Ensure output folder exists
capture mkdir "`OUTPUT_DIR'"

* Sheets to copy unchanged (if present)
local passthrough "Info Gof"

* Workbooks to process (filenames WITHOUT extension)
local workbooks ///
"reg_education reg_health reg_partnership reg_fertility reg_home_ownership reg_leaveParentalHome reg_retirement reg_income reg_wages reg_labourSupplyUtility reg_RMSE reg_employmentSelection"


foreach wb of local workbooks {

    di as txt "--------------------------------------------"
    di as txt "Processing workbook: `wb'"
    di as txt "--------------------------------------------"

    local infile  "`INPUT_DIR'/`wb'.`EXT'"
    local outfile "`OUTPUT_DIR'/`wb'.`EXT'"   // same name, different folder

    * Define model sheets for each workbook
    local models ""
    if "`wb'" == "reg_education"             local models "E1a E1b E2a"
    if "`wb'" == "reg_health"                local models "H1 H2"
    if "`wb'" == "reg_partnership"           local models "U1 U2"
    if "`wb'" == "reg_fertility"             local models "F1"
    if "`wb'" == "reg_home_ownership"        local models "HO1"
    if "`wb'" == "reg_leaveParentalHome"     local models "P1"
    if "`wb'" == "reg_retirement"            local models "R1a R1b"
    if "`wb'" == "reg_income"                local models "I1a I1b"
    if "`wb'" == "reg_wages"                 local models "W1fa W1ma W1fb W1mb"
    if "`wb'" == "reg_labourSupplyUtility"   local models "Single_female Single_male SingleDep_Females SingleDep_Males Couples SingleAC_Females SingleAC_Males"
    if "`wb'" == "reg_RMSE"                  local models "RMSE"
    if "`wb'" == "reg_employmentSelection"   local models "W1fa-sel W1ma-sel W1fb-sel W1mb-sel"

    local export_started = 0

    /**********************
    * A) Copy Info + Gof unchanged
    **********************/
    foreach s of local passthrough {

        capture noisily import excel "`infile'", sheet("`s'") firstrow clear
        if _rc {
            di as txt "  Passthrough sheet `s' not found -> skipping"
            continue
        }

        capture noisily {
            if (`export_started' == 0) {
                export excel using "`outfile'", sheet("`s'") replace firstrow(variables)
                local export_started = 1
            }
            else {
                export excel using "`outfile'", sheet("`s'") sheetmodify firstrow(variables)
            }
        }
        if _rc {
            di as err "ERROR: Could not save `outfile' (close Excel / check permissions)."
            exit 603
        }
    }

    /**********************
    * B) Clean model sheets
    **********************/
    foreach s of local models {

        di as txt "  Cleaning sheet: `s'"

        capture noisily import excel "`infile'", sheet("`s'") firstrow clear
        if _rc {
            di as err "    -> Could not import sheet `s' from `infile' (skipping)"
            continue
        }

        * 1) Drop rows that are completely empty (NO egen; type-safe)
        gen byte __row_has_any = 0
        foreach v of varlist _all {

            capture confirm numeric variable `v'
            if !_rc {
                replace __row_has_any = 1 if __row_has_any==0 & `v' < .
                continue
            }

            capture confirm string variable `v'
            if !_rc {
                replace __row_has_any = 1 if __row_has_any==0 & strlen(itrim(`v')) > 0
                continue
            }
        }
        drop if __row_has_any == 0
        drop __row_has_any

        * 2) Drop columns that are completely empty (type-safe)
        foreach v of varlist _all {

            capture confirm numeric variable `v'
            if !_rc {
                quietly count if `v' < .
                if r(N) == 0 drop `v'
                continue
            }

            capture confirm string variable `v'
            if !_rc {
                quietly count if strlen(itrim(`v')) > 0
                if r(N) == 0 drop `v'
                continue
            }
        }

        * 3) Export cleaned sheet
        capture noisily {
            if (`export_started' == 0) {
                export excel using "`outfile'", sheet("`s'") replace firstrow(variables)
                local export_started = 1
            }
            else {
                export excel using "`outfile'", sheet("`s'") sheetmodify firstrow(variables)
            }
        }
        if _rc {
            di as err "ERROR: Could not save `outfile' (close Excel / check permissions)."
            exit 603
        }
    }

    if (`export_started' == 0) di as err "No sheets exported for `wb'."
    else di as res "Done: `outfile'"
}

di as res "All done."
