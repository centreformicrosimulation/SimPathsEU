/*******************************************************************************
* PROJECT:        SimPaths EU
* SECTION:        Retirement (Poland)
* PURPOSE:        Rename Year_transformed labels in reg_retirement Excel output
* SHEETS:         R1a, R1b
*******************************************************************************/

clear all
set more off

* Defaults (override via args)
local excel_path "$dir_work/reg_retirement_${country}"
local old_name "Year_transformed"
local new_r1a "Year_transformed_R1a"
local new_r1b "Year_transformed_R1b"

args excel_path_arg old_name_arg new_r1a_arg new_r1b_arg
if "`excel_path_arg'" != "" local excel_path "`excel_path_arg'"
if "`old_name_arg'" != "" local old_name "`old_name_arg'"
if "`new_r1a_arg'" != "" local new_r1a "`new_r1a_arg'"
if "`new_r1b_arg'" != "" local new_r1b "`new_r1b_arg'"

if "`excel_path'" == "" {
    display as error "excel_path is empty. Provide a path or set dir_work/country."
    exit 198
}

capture confirm file "`excel_path'"
if _rc {
    capture confirm file "`excel_path'.xlsx"
    if _rc {
        display as error "File not found: `excel_path' (.xlsx also not found)"
        exit 601
    }
    local excel_path "`excel_path'.xlsx"
}

foreach sheet in R1a R1b {
    local new_name "`new_r1a'"
    if "`sheet'" == "R1b" local new_name "`new_r1b'"

    import excel using "`excel_path'", sheet("`sheet'") clear allstring
    gen long _row = _n

    local found = 0
    local opened = 0
    ds, has(type string)
    foreach var of varlist `r(varlist)' {
        quietly levelsof _row if `var' == "`old_name'", local(rows)
        if "`rows'" != "" {
            local found = 1
            if `opened' == 0 {
                putexcel set "`excel_path'", sheet("`sheet'") modify
                local opened = 1
            }
            foreach r of local rows {
                putexcel `var'`r' = "`new_name'"
            }
        }
    }

    if `found' == 0 {
        display as text "No matches for `old_name' found on sheet `sheet'."
    }
}

display as text "Done."
