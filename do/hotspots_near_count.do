clear all
set more off
set maxvar 20000

/*
JC: I changed to use .dta of all the datasets instead of .txt. I understand that
this hurts reproducibility, but we can always uncomment those lines if needed. 
*/


* Identifiers HS
// import delimited "hs_segments.txt", delimiter(";") encoding(utf8) clear 
use in_data/hs_segments
keep fid objectid
rename fid in_fid
compress

tempfile hs
save `hs'

* Identifiers Network
// import delimited "all_segments.txt", delimiter(";") encoding(utf8) clear 
use in_data/all_segments
keep fid objectid
rename fid near_fid
rename objectid id // important change
compress

tempfile net
save `net'

* Load distance table
//import delimited "near_table.txt", delimiter(";") encoding(utf8) clear 
// drop objectid near_rank
// 
// gen double dist = real(subinstr(near_dist,",",".",1))
// drop near_dist
use in_data/near_table // has all that stuff above done to it

* to change for robustness
local radius = 250
gen byte _within = dis<=`radius'

* merge identifiers
merge m:1 in_fid using `hs'
assert _merge==3
cap drop _merge

merge m:1 near_fid using `net', keep(1 3)
assert _merge==3
cap drop _merge

keep id objectid _within
keep if _within==1

tempfile partialdata
save `partialdata'

tempfile partialdata_simulations
merge m:1 objectid using "in_data/simulations.dta",  keep(1 3)
assert _merge==3
cap drop _merge

cap drop _merge
save `partialdata_simulations'


foreach x in hsp bw {
	forvalues r = 1/1000 {
		
		di "*** Repetition `r' for `x' ***"
		
		use `partialdata_simulations', clear
		keep _within id assign_`x'_`r' 
		
		qui gen n_sp250_`x'_`r' = (assign_`x'_`r'==1 & _within==1)

		keep if n_sp250_`x'_`r'==1

		collapse (sum) n_sp250 , by(id)

		rename id objectid
		
		compress
		
		tempfile data_`x'_`r'
		save `data_`x'_`r''
	}
}

use `partialdata_simulations', clear

merge m:1 objectid using "in_data/treat_status.dta", keep(1 3) keepusing(treat_hsp treat_bw)
assert _merge==3
cap drop _merge

keep _within objectid id treat_hsp treat_bw 

collapse ///
(sum) treat_hsp ///
(sum) treat_bw, ///
by(id)

qui replace treat_hsp = 0 if missing(treat_hsp)
qui replace treat_bw = 0 if missing(treat_bw)

rename treat_* n_sp250_*

rename id objectid

merge 1:1 objectid using "in_data/treat_status.dta", keepusing(objectid treat_hsp treat_bw)
// replace spillover to be 0 if treated 
cap drop _merge

replace n_sp250_hsp = 0 if (treat_hsp == 1 | treat_bw == 1)
replace n_sp250_bw = 0 if (treat_hsp == 1 | treat_bw == 1)


merge 1:1 objectid using "in_data/simulations.dta", keep(3)
assert _merge==2 | _merge==3
cap drop _merge

foreach x in hsp bw {
	forvalues r = 1/1000 {
		qui merge 1:1 objectid using `data_`x'_`r'', keep(1 3)
		assert _merge==1 | _merge==3 
		cap drop _merge
		
		qui replace n_sp250_`x'_`r' = 0 if missing(n_sp250_`x'_`r')

		qui replace n_sp250_`x'_`r' = 0 if (assign_hsp_`r' == 1 | assign_bw_`r' == 1)
	}


	egen e_sp250_`x' = rowmean(n_sp250_`x'_1 - n_sp250_`x'_1000)
}

// generate interaction terms
forvalues r = 1/1000 {
	qui gen n_sp250_hsp_bw_`r'= n_sp250_hsp_`r' * n_sp250_bw_`r'
}

egen e_sp250_hsp_bw = rowmean(n_sp250_hsp_bw_1 - n_sp250_hsp_bw_1000)

preserve
drop assign*
drop n_sp250_hsp n_sp250_bw e_sp250_hsp e_sp250_bw 

save "out_data/simulationnumbers_count.dta", replace

restore

keep objectid ///
n_sp250_hsp ///
n_sp250_bw ///
e_sp250_hsp ///
e_sp250_bw  ///
e_sp250_hsp_bw


gen n_sp250_hsp_bw = n_sp250_hsp*n_sp250_bw , after(n_sp250_bw)

foreach v of varlist n_sp250_* {
	qui sum `v', d
	qui gen z_`v' = (`v' - r(mean))/r(sd)
}

save "out_data/intensity_hs_count_nearby.dta", replace


*****
