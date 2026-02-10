/*******************************************************************************
* PROJECT:        SimPaths EU
* SECTION:        Education (Poland)
* PURPOSE:        Rename Year_transformed labels in reg_education Excel output
* SHEETS:         E1a, E1b, E2a
*******************************************************************************/

clear all
set more off

* Defaults (override via args)
local excel_path "$dir_work/reg_education_${country}"
local old_name "Year_transformed"
local old_sq "Year_transformed_sq"
local old_prefix "Year_transformed_"
local old_sq_prefix "Year_transformed_sq_"
local new_e1a "Year_transformed_E1a"
local new_e1b "Year_transformed_E1b"
local new_e2a_prefix "Year_transformed_E2a_"
local new_sq_e1a "Year_transformed_sq_E1a"
local new_sq_e1b "Year_transformed_sq_E1b"
local new_sq_e2a_prefix "Year_transformed_sq_E2a_"

args excel_path_arg old_name_arg new_e1a_arg new_e1b_arg ///
    old_sq_arg new_sq_e1a_arg new_sq_e1b_arg ///
    old_prefix_arg new_e2a_prefix_arg old_sq_prefix_arg new_sq_e2a_prefix_arg
if "`excel_path_arg'" != "" local excel_path "`excel_path_arg'"
if "`old_name_arg'" != "" local old_name "`old_name_arg'"
if "`new_e1a_arg'" != "" local new_e1a "`new_e1a_arg'"
if "`new_e1b_arg'" != "" local new_e1b "`new_e1b_arg'"
if "`old_sq_arg'" != "" local old_sq "`old_sq_arg'"
if "`new_sq_e1a_arg'" != "" local new_sq_e1a "`new_sq_e1a_arg'"
if "`new_sq_e1b_arg'" != "" local new_sq_e1b "`new_sq_e1b_arg'"
if "`old_prefix_arg'" != "" local old_prefix "`old_prefix_arg'"
if "`new_e2a_prefix_arg'" != "" local new_e2a_prefix "`new_e2a_prefix_arg'"
if "`old_sq_prefix_arg'" != "" local old_sq_prefix "`old_sq_prefix_arg'"
if "`new_sq_e2a_prefix_arg'" != "" local new_sq_e2a_prefix "`new_sq_e2a_prefix_arg'"

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

foreach sheet in E1a E1b E2a {
    import excel using "`excel_path'", sheet("`sheet'") clear allstring
    gen long _row = _n

    local found = 0
    local opened = 0
    ds, has(type string)
    foreach var of varlist `r(varlist)' {
        if inlist("`sheet'", "E1a", "E1b") {
            local new_name "`new_e1a'"
            local new_sq_name "`new_sq_e1a'"
            if "`sheet'" == "E1b" {
                local new_name "`new_e1b'"
                local new_sq_name "`new_sq_e1b'"
            }

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

            quietly levelsof _row if `var' == "`old_sq'", local(rows_sq)
            if "`rows_sq'" != "" {
                local found = 1
                if `opened' == 0 {
                    putexcel set "`excel_path'", sheet("`sheet'") modify
                    local opened = 1
                }
                foreach r of local rows_sq {
                    putexcel `var'`r' = "`new_sq_name'"
                }
            }
        }

        if "`sheet'" == "E2a" {
            quietly levelsof _row if strpos(`var', "`old_prefix'") == 1, local(rows_prefix)
            if "`rows_prefix'" != "" {
                local found = 1
                if `opened' == 0 {
                    putexcel set "`excel_path'", sheet("`sheet'") modify
                    local opened = 1
                }
                foreach r of local rows_prefix {
                    local cell = `"`= `var'[`r']'"'
                    local newcell : subinstr local cell "`old_prefix'" "`new_e2a_prefix'" 1
                    putexcel `var'`r' = "`newcell'"
                }
            }

            quietly levelsof _row if strpos(`var', "`old_sq_prefix'") == 1, local(rows_sq_prefix)
            if "`rows_sq_prefix'" != "" {
                local found = 1
                if `opened' == 0 {
                    putexcel set "`excel_path'", sheet("`sheet'") modify
                    local opened = 1
                }
                foreach r of local rows_sq_prefix {
                    local cell = `"`= `var'[`r']'"'
                    local newcell : subinstr local cell "`old_sq_prefix'" "`new_sq_e2a_prefix'" 1
                    putexcel `var'`r' = "`newcell'"
                }
            }
        }
    }

    if `found' == 0 {
        display as text "No matches for `old_name' found on sheet `sheet'."
    }
}

display as text "Done."
