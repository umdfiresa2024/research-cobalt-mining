*-----------------------------------------------------------------------------------------------------------------------------------*
* This program performs the estimations of Tables 12 and 13 (appendix) of "This mine is mine: how minerals fuel conflicts in Africa"
* This version: October 2016
*-----------------------------------------------------------------------------------------------------------------------------------*

* ------------------------------------------------------------------------------------ *
					*  Table 12 - Heterogenous effects: cleavages *
* ------------------------------------------------------------------------------------ *

cap log close
log using "$Results\Table_12.log", replace

use "$Output_data\BCRT_baseline", clear

cor icrg_qog_init wbgi_gee_init wbgi_rle_init wbgi_cce_init wbgi_vae_init  p_polity2_init 

/* drop diamonds and tantalum for baseline */
drop if mainmineral == "diamond" | mainmineral == "tantalum"

** TABLE 12 - INEQUALITY, ETC.

foreach var in solt_ginmar_init  {
	egen median_`var' 	= pctile(`var'), p(50)
	g high_`var' 		= (`var'>median_`var' & `var'!=.)
	replace high_`var' 	=. if `var'==.
	g triple_`var'   	= main_lprice_mines*high_`var'
	g triple2_`var' 	=  main_lprice_hist0*high_`var'
	label var triple_`var'  "main_lprice_mines*`var'"
}
eststo: reghdfe acled  main_lprice_mines  triple_*		if sd_mines == 0 			, vce(cluster country_nb) absorb(cell it) 
eststo: reghdfe acled  main_lprice_hist0 triple2_*     								, vce(cluster country_nb) absorb(cell it) 

drop triple* high median_*


foreach var in ETHFRAC_RQ RELFRAC_RQ {
	egen median_`var' 	= pctile(`var'), p(50)
	g high_`var' 		= (`var'>median_`var' & `var'!=.)
	replace high_`var' 	=. if `var'==.
	g triple_`var'   	= main_lprice_mines*high_`var'
	g triple2_`var' 	=  main_lprice_hist0*high_`var'
	label var triple_`var'  "main_lprice_mines*`var'"
}	

eststo: reghdfe acled  main_lprice_mines  triple_*		if sd_mines == 0 			, vce(cluster country_nb) absorb(cell it) 
eststo: reghdfe acled  main_lprice_hist0 triple2_*     								, vce(cluster country_nb) absorb(cell it) 

drop triple* high_* median_*

foreach var in  ETHPOL_RQ RELPOL_RQ {
	egen median_`var' 	= pctile(`var'), p(50)
	g high_`var' 		= (`var'>median_`var' & `var'!=.)
	replace high_`var' 	=. if `var'==.
	g triple_`var'   	= main_lprice_mines*high_`var'
	g triple2_`var' 	= main_lprice_hist0*high_`var'
	label var triple_`var'  "main_lprice_mines*`var'"
}
	
eststo: reghdfe acled  main_lprice_mines  triple_*		if sd_mines == 0 			, vce(cluster country_nb) absorb(cell it) 
eststo: reghdfe acled  main_lprice_hist0 triple2_*     								, vce(cluster country_nb) absorb(cell it) 

drop triple* high_* median_*
	
g triple_indig_Cederman  	= main_lprice_mines*indig_Cederman
g triple2_indig_Cederman	=  main_lprice_hist0*indig_Cederman
label var triple_indig_Cederman  "main_lprice_mines*indig_Cederman"

	
eststo: my_reg2hdfespatial acled   main_lprice_mines triple_* if sd_mines == 0		, timevar(it) panelvar(cell) lat(latitude) lon(longitude) distcutoff(500) lagcutoff(100000) 
eststo: my_reg2hdfespatial acled   main_lprice_hist0 triple2_* 						, timevar(it) panelvar(cell) lat(latitude) lon(longitude) distcutoff(500) lagcutoff(100000) 


set linesize 250
esttab, mtitles drop() b(%5.3f) se(%5.3f) compress r2 starlevels(c 0.1 b 0.05 a 0.01)  se 
esttab, mtitles drop() b(%5.3f) se(%5.3f) r2  starlevels({$^c$} 0.1 {$^b$} 0.05 {$^a$} 0.01) se tex label  title(Table 12) 
eststo clear

log close

*Which countries are the more religiously divided and drive the result?
use "$Output_data\BCRT_baseline", clear
drop if mainmineral == "diamond" | mainmineral == "tantalum"
reghdfe acled  main_lprice_mines  if sd_mines == 0, vce(cluster country_nb) absorb(cell it) 
keep if e(sample) 
collapse (mean) RELFRAC_RQ RELPOL_RQ (mean) mines (sum) acled, by(iso_1)
drop if mines == 0
cor RELFRAC_RQ RELPOL_RQ
egen rankRELFRAC_RQ = rank(RELFRAC_RQ), field
egen rankRELPOL_RQ = rank(RELPOL_RQ), field
tab iso_1 if rankRELFRAC_RQ<=5
tab iso_1 if rankRELPOL_RQ<=5

* ------------------------------------------------------------------------------------ *
				*  Table 13 - Heterogenous effects: Institutional quality *
* ------------------------------------------------------------------------------------ *

cap log close
log using "$Results\Table_13.log", replace

use "$Output_data\BCRT_baseline", clear

cor icrg_qog_init wbgi_gee_init wbgi_rle_init wbgi_cce_init wbgi_vae_init  p_polity2_init 

/* drop diamonds and tantalum for baseline */
drop if mainmineral == "diamond" | mainmineral == "tantalum"

foreach var in icrg_qog_init {
	egen median_`var' 	= pctile(`var'), p(50)
	g high 				= (`var'>median_`var' & `var'!=.)
	replace high 		=. if `var'==.
	g triple   			= main_lprice_mines*high
	g triple2 			=  main_lprice_hist0*high
	label var triple  "main_lprice_mines*`var'"
	
	eststo: reghdfe acled  main_lprice_mines  triple		if sd_mines == 0 			, vce(cluster country_nb) absorb(cell it) 
	eststo: reghdfe acled  main_lprice_hist0  triple2    								, vce(cluster country_nb) absorb(cell it) 

	*
	drop triple* high median_`var'
}

foreach var in wbgi_gee_init wbgi_rle_init  wbgi_vae_init wbgi_cce_init {
	egen median_`var' 		= pctile(`var'), p(50)
	g high_`var' 			= (`var'>median_`var' & `var'!=.)
	replace high_`var' 		=. if `var'==.
	g triple_`var'  		= main_lprice_mines*high_`var'
	g triple2_`var' 		=  main_lprice_hist0*high_`var'
	label var triple_`var'  "main_lprice_mines*`var'"
	label var triple2_`var' "main_lprice_mines (ever)*`var'"
}	
	eststo: reghdfe acled  main_lprice_mines  triple_*		if sd_mines == 0 			, vce(cluster country_nb) absorb(cell it) 
	eststo: reghdfe acled  main_lprice_hist0  triple2_*    								, vce(cluster country_nb) absorb(cell it) 
	
drop triple* high_* median_*

foreach var in  p_polity2_init {
	egen median_`var' 	= pctile(`var'), p(50)
	g high	 			= (`var'>median_`var' & `var'!=.)
	replace high 		=. if `var'==.
	g triple   			= main_lprice_mines*high
	g triple2 			= main_lprice_hist0*high
	label var triple  "main_lprice_mines*`var'"

	eststo: reghdfe acled  main_lprice_mines  triple  	if sd_mines == 0 			, vce(cluster country_nb) absorb(cell it) 
	eststo: reghdfe acled  main_lprice_hist0  triple2  								, vce(cluster country_nb) absorb(cell it) 

	*
	drop triple* high median_`var'
}

set linesize 250
esttab, mtitles drop() b(%5.3f) se(%5.3f) compress r2 starlevels(c 0.1 b 0.05 a 0.01)  se 
esttab, mtitles drop() b(%5.3f) se(%5.3f) r2  starlevels({$^c$} 0.1 {$^b$} 0.05 {$^a$} 0.01) se tex label  title(Table 13) 
eststo clear
		
cap log close
