
cap program drop crime_hetero_u_pct
program define crime_hetero_u_pct
syntax, BELOWCRIMEPCT(integer) MAXREP(integer)
clear all
set more off
set maxvar 20000

use tmp/ready_sim_loop, clear


dis "***************** Below crime at percentile `belowcrimepct' ************"




* exclude pairs of experimental street to experiental street 

dis "*************** Generating the nearby hotspots ***************"
quietly drop if id == objectid
forvalues i = 1/`maxrep' {
    gen sp250_hsp_high_crime_`i' = ///
        assign_hsp_`i' == 1 & /// the experimental in the pair you are paired with is hsp
        all_assign_hsp_`i' == 2 & /// you all in the pair is a spillover
        hs_u`belowcrimepct' == 0 

    gen sp250_hsp_low_crime_`i' = ///
    	assign_hsp_`i' == 1 & /// the experimental in the pair you are paired with is hsp
   	all_assign_hsp_`i' == 2 & /// you all in the pair is a spillover
    	hs_u`belowcrimepct' == 1 
   
    gen sp250_bw_high_crime_`i' = ///
        assign_bw_`i' == 1 & /// the experimental in the pai is a bw
        all_assign_bw_`i' == 2 & /// the all in the pair is a spillover 
	hs_u`belowcrimepct' == 0

    gen sp250_bw_low_crime_`i' = ///
        assign_bw_`i' == 1 & /// the experimental in the pai is a bw
        all_assign_bw_`i' == 2 & /// the all in the pair is a spillover 
	hs_u`belowcrimepct' == 1


    gen sp250_hsp_bw_high_crime_`i' = ///
        assign_hsp_`i' == 1 & assign_bw_`i' == 1 & /// the experimental in the pair is hsp and bw
        all_assign_bw_`i' == 2 & all_assign_hsp_`i' == 2 & /// the all in the pair is a spillover of both 
	hs_u`belowcrimepct' == 0

    gen sp250_hsp_bw_low_crime_`i' = ///
        assign_hsp_`i' == 1 & assign_bw_`i' == 1 & /// the experimental in the pair is hsp and bw
        all_assign_bw_`i' == 2 & all_assign_hsp_`i' == 2  & /// the all in the pair is a spillover of both
	hs_u`belowcrimepct' == 1
}



************************************************************
* Keep just the spillover data *****************************
************************************************************
keep id ///
sp250_hsp_high_crime* ///
sp250_hsp_low_crime* ///
sp250_bw_high_crime* ///
sp250_bw_low_crime* ///
sp250_hsp_bw_high_crime* ///
sp250_hsp_bw_low_crime* 

***********************************************************
* collapse to get the maximum for all simulations **********
************************************************************
* Change the id to objectid so we can merge stuff later
rename id objectid


dis "******** Collapsing **************"
fcollapse (max) sp250*, by(objectid)

dis "** Replacements to fix high-low conflicts ***"
forvalues i = 1/`maxrep' {
	quietly replace sp250_hsp_low_crime_`i' = 0 if sp250_hsp_high_crime_`i' == 1
	quietly replace sp250_bw_low_crime_`i' = 0 if sp250_bw_high_crime_`i' == 1
	quietly replace sp250_hsp_bw_low_crime_`i' = 0 if sp250_hsp_bw_high_crime_`i' == 1
} 



***********************************************************
* Merge in the other observations that are not spillovers *
***********************************************************,
quietly merge 1:1 objectid using in_data/treat_status, keepusing(objectid) nogen



***********************************************************
* Replace observations with missing ***********************
***********************************************************
dis "**** Missing values replacement for non-nearby streets ***"
* These are observations that are not near any hotspots 
foreach var of varlist sp250* {
	quietly replace `var' = 0 if missing(`var')
}

**********************************************************
* Find expected values ***********************************
**********************************************************
egen e_sp250_hsp_low_crime	 = rowmean(sp250_hsp_low_crime*)
egen e_sp250_hsp_high_crime	 = rowmean(sp250_hsp_high_crime*)
egen e_sp250_bw_low_crime	 = rowmean(sp250_bw_low_crime*)
egen e_sp250_bw_high_crime	 = rowmean(sp250_bw_high_crime*)
egen e_sp250_hsp_bw_low_crime	 = rowmean(sp250_hsp_bw_low_crime*)
egen e_spe50_hsp_bw_high_crime	 = rowmean(sp250_hsp_bw_high_crime*)



save out_data/sims/sims_u`belowcrimepct', replace

*********************************************************
* Save a temp dataset of just the expected value ********
*********************************************************
keep objectid e_*
tempfile expected_values
save `expected_values'


**********************************************************
* Repeat the same process for the real data **************
***********************************************************
use tmp/ready_real_data, clear
quietly drop if id == objectid 


    gen sp250_hsp_high_crime = ///
        treat_hsp == 1 & /// the experimental in the pair you are paired with is hsp
        all_sp250_hsp == 1 & /// you all in the pair is a spillover
        hs_u`belowcrimepct' == 0 

    gen sp250_hsp_low_crime = ///
    	treat_hsp == 1 & /// the experimental in the pair you are paired with is hsp
   	all_sp250_hsp == 1 & /// you all in the pair is a spillover
    	hs_u`belowcrimepct' == 1 
   
    gen sp250_bw_high_crime = ///
        treat_bw == 1 & /// the experimental in the pai is a bw
        all_sp250_bw == 1 & /// the all in the pair is a spillover 
	hs_u`belowcrimepct' == 0

    gen sp250_bw_low_crime = ///
        treat_bw == 1 & /// the experimental in the pai is a bw
        all_sp250_bw == 1 & /// the all in the pair is a spillover 
	hs_u`belowcrimepct' == 1


    gen sp250_hsp_bw_high_crime = ///
        treat_hsp == 1 & treat_bw == 1 & /// the experimental in the pair is hsp and bw
        all_sp250_hsp == 1 & all_sp250_bw == 1 & /// the all in the pair is a spillover 
	hs_u`belowcrimepct' == 0

    gen sp250_hsp_bw_low_crime = ///
        treat_hsp == 1 & treat_bw == 1 & /// the experimental in the pair is hsp and bw
        all_sp250_hsp == 1 &  all_sp250_bw == 1 & /// the all in the pair is a spillover 
	hs_u`belowcrimepct' == 1


**************************************************************
* Keep just the spillover variables we just created **********
**************************************************************
keep id ///
sp250_hsp_high_crime ///
sp250_hsp_low_crime ///
sp250_bw_high_crime ///
sp250_bw_low_crime ///
sp250_hsp_bw_high_crime ///
sp250_hsp_bw_low_crime

* Rename the id variable
rename id objectid


****************************************************************
* Perform the collapse *****************************************
****************************************************************
fcollapse (max) sp250*, by(objectid)

****************************************************************
* Make a correction so that any street with a high crime hotspot
* nearby and a low crime hotstpot nearby is classified only as 
* a high crime spillover 
****************************************************************
quietly replace sp250_hsp_low_crime = 0 if sp250_hsp_high_crime == 1
quietly replace sp250_bw_low_crime = 0 if sp250_bw_high_crime == 1
quietly replace sp250_hsp_bw_low_crime = 0 if sp250_hsp_bw_high_crime == 1
 




******************************************************************
* Merge in the rest of the street segments *********************
******************************************************************
quietly merge 1:1 objectid using in_data/treat_status, keepusing(objectid) nogen

***********************************************************
* Replace observations with missing ***********************
***********************************************************
* These are observations that are not near any hotspots 
foreach var of varlist sp250* {
	quietly replace `var' = 0 if missing(`var')
}

**********************************************************
* Merge in the expected value data **********************
*********************************************************
merge 1:1 objectid using `expected_values', nogen




save out_data/real/real_u`belowcrimepct', replace


end

*****
