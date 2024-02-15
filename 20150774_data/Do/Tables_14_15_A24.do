*------------------------------------------------------------------------------------------------------------------------------------------------------------*
* This program performs the estimations of Tables 14 and 15 (appendix) and A24 (online appendix) of "This mine is mine: how minerals fuel conflicts in Africa"
* This version: October 2016
*------------------------------------------------------------------------------------------------------------------------------------------------------------*

* ------------------------------------------------------------------------------------ *
					*  Table 14 - Heterogenous effects: Capital intensity *
* ------------------------------------------------------------------------------------ *

cap log close
log using "$Results\Table_14.log", replace

use "$Output_data\BCRT_baseline", clear

/* drop diamonds and tantalum for baseline */
drop if mainmineral == "diamond" | mainmineral == "tantalum"
*

*** OPEN-PIT
eststo: my_reg2hdfespatial acled main_lprice_mines amethod_someOP_Interac if sd_mines == 0	, timevar(it) panelvar(cell) lat(latitude) lon(longitude) distcutoff(500) lagcutoff(100000) 	 
eststo: my_reg2hdfespatial acled main_lprice_hist0 amethod_someOP_Intera0 					, timevar(it) panelvar(cell) lat(latitude) lon(longitude) distcutoff(500) lagcutoff(100000) 

*** ENERGY / LABOR
eststo: my_reg2hdfespatial acled main_lprice_mines cross_nrj_employees if sd_mines == 0  	, timevar(it) panelvar(cell) lat(latitude) lon(longitude) distcutoff(500) lagcutoff(100000) 	 
eststo: my_reg2hdfespatial acled main_lprice_hist0 nrj_employees_hist0 						, timevar(it) panelvar(cell) lat(latitude) lon(longitude) distcutoff(500) lagcutoff(100000) 

*** AGE MINE
eststo: my_reg2hdfespatial acled main_lprice_mines lprice_open if sd_mines == 0  			, timevar(it) panelvar(cell) lat(latitude) lon(longitude) distcutoff(500) lagcutoff(100000) 	 
eststo: my_reg2hdfespatial acled main_lprice_hist0 lprice_open0		 	  					, timevar(it) panelvar(cell) lat(latitude) lon(longitude) distcutoff(500) lagcutoff(100000) 


set linesize 250
esttab, mtitles drop() b(%5.3f) se(%5.3f) compress r2 starlevels(c 0.1 b 0.05 a 0.01)  se 
esttab, mtitles drop() b(%5.3f) se(%5.3f) r2  starlevels({$^c$} 0.1 {$^b$} 0.05 {$^a$} 0.01) se tex label  title(Table 14) 
eststo clear

log close


* ------------------------------------------------------------------------------------ *
					*  Table 15 - Heterogenous effects: Lootability *
* ------------------------------------------------------------------------------------ *

cap log close
log using "$Results\Table_15.log", replace

use "$Output_data\BCRT_baseline", clear

*** UNIT PRICE
eststo: my_reg2hdfespatial  acled  median_1_price median_2_price   		if sd_mines == 0	  	  			, timevar(it) panelvar(cell) lat(latitude) lon(longitude) distcutoff(500) lagcutoff(100000) 	
eststo: my_reg2hdfespatial  acled  median_1_price0 median_2_price0   	if main_lprice_mines !=. 	  		, timevar(it) panelvar(cell) lat(latitude) lon(longitude) distcutoff(500) lagcutoff(100000) 	

*** RENTS ***
eststo: my_reg2hdfespatial acled main_lprice_mines arents_Interac 		if sd_mines == 0  					, timevar(it) panelvar(cell) lat(latitude) lon(longitude) distcutoff(500) lagcutoff(100000) 	 
eststo: my_reg2hdfespatial acled   main_lprice_hist0 arents_Intera0 	if main_lprice_mines !=. 			, timevar(it) panelvar(cell) lat(latitude) lon(longitude) distcutoff(500) lagcutoff(100000) 

*** ORE CONCENTRATION ***
eststo: my_reg2hdfespatial acled main_lprice_mines ore_con_Interac 		if sd_mines == 0  					, timevar(it) panelvar(cell) lat(latitude) lon(longitude) distcutoff(500) lagcutoff(100000) 	 
eststo: my_reg2hdfespatial acled   main_lprice_hist0 ore_con_Intera0 	if main_lprice_mines !=. 			, timevar(it) panelvar(cell) lat(latitude) lon(longitude) distcutoff(500) lagcutoff(100000) 

set linesize 250
esttab, mtitles drop() b(%5.3f) se(%5.3f) compress r2 starlevels(c 0.1 b 0.05 a 0.01)  se 
esttab, mtitles drop() b(%5.3f) se(%5.3f) r2  starlevels({$^c$} 0.1 {$^b$} 0.05 {$^a$} 0.01) se tex label  title(Table 15) 
eststo clear

log close


* ------------------------------------------------------------------------------------ *
				*  Table A24 - Further tests on mineral capital intensity *
* ------------------------------------------------------------------------------------ *

cap log close
log using "$Results\Table_A24.log", replace

use "$Output_data\BCRT_baseline", clear

/* drop diamonds and tantalum for baseline */
drop if mainmineral == "diamond" | mainmineral == "tantalum"

*** PRODUCTION FUNCTION
eststo: my_reg2hdfespatial acled main_lprice_mines K_int_pf_Interac if sd_mines == 0  			 , timevar(it) panelvar(cell) lat(latitude) lon(longitude) distcutoff(500) lagcutoff(100000) 	 
eststo: my_reg2hdfespatial acled main_lprice_hist0 K_int_pf_Intera0 if main_lprice_mines !=. 	 , timevar(it) panelvar(cell) lat(latitude) lon(longitude) distcutoff(500) lagcutoff(100000) 

*** LEAD TIME
eststo: my_reg2hdfespatial acled main_lprice_mines Ltmean_Interac if sd_mines == 0  			, timevar(it) panelvar(cell) lat(latitude) lon(longitude) distcutoff(500) lagcutoff(100000) 	 
eststo: my_reg2hdfespatial acled main_lprice_hist0 Ltmean_Intera0 if main_lprice_mines !=. 		, timevar(it) panelvar(cell) lat(latitude) lon(longitude) distcutoff(500) lagcutoff(100000) 

*** ARTISANAL
eststo: my_reg2hdfespatial acled main_lprice_mines artisanal_Interac if sd_mines == 0  			, timevar(it) panelvar(cell) lat(latitude) lon(longitude) distcutoff(500) lagcutoff(100000) 	 
eststo: my_reg2hdfespatial acled main_lprice_hist0 artisanal_Intera0 if main_lprice_mines !=. 	, timevar(it) panelvar(cell) lat(latitude) lon(longitude) distcutoff(500) lagcutoff(100000) 

set linesize 250
esttab, mtitles drop() b(%5.3f) se(%5.3f) compress r2 starlevels(c 0.1 b 0.05 a 0.01)  se 
esttab, mtitles drop() b(%5.3f) se(%5.3f) r2  starlevels({$^c$} 0.1 {$^b$} 0.05 {$^a$} 0.01) se tex label  title(Table A24) 
eststo clear

log close
