*---------------------------------------------------------------------------------------------------------------------------*
* This program performs the baseline estimations (Table 2) of "This mine is mine: how minerals fuel conflicts in Africa"
* This version: October 2016
*---------------------------------------------------------------------------------------------------------------------------*

cap log close
log using "$Results\Table_2.log", replace


* ------------------------------------------------------------------------------------ *
					*  Table 2 - Conflict and mineral prices *
* ------------------------------------------------------------------------------------ *

use "$Output_data\BCRT_baseline", clear

/* drop diamonds and tantalum for baseline */
drop if mainmineral == "diamond" | mainmineral == "tantalum"

/*condition for estimation with spatial lags of mines*/
global condition_around "(mainmineral != "diamond" & mainmineral_around != "diamond" & mainmineral != "tantalum" & mainmineral_around != "tantalum")"

/*column 1: time varying mining area dummy*/
eststo: my_reg2hdfespatial acled  mines main_lprice main_lprice_mines m_lprice_mines     								   							, timevar(it) panelvar(cell) lat(latitude) lon(longitude) distcutoff(500) lagcutoff(100000) 
/*column 2: mine open the entire period*/
eststo: my_reg2hdfespatial acled  main_lprice_mines 									if sd_mines == 0							    			, timevar(it) panelvar(cell) lat(latitude) lon(longitude) distcutoff(500) lagcutoff(100000) 
/*column 3: mine open the entire period, with surrounding mines*/
eststo: my_reg2hdfespatial acled  main_lprice_mines main_lprice_a 						if sd_mines == 0  & sd_mines_a ==0  & $condition_around		, timevar(it) panelvar(cell) lat(latitude) lon(longitude) distcutoff(500) lagcutoff(100000)
/*column 4: mine at some point over the period*/
eststo: my_reg2hdfespatial acled   main_lprice_hist0 									   															, timevar(it) panelvar(cell) lat(latitude) lon(longitude) distcutoff(500) lagcutoff(100000) 
/*column 5: year dummies only */
eststo: my_reg2hdfespatial acled  main_lprice_mines 									if sd_mines == 0											, timevar(year) panelvar(cell) lat(latitude) lon(longitude) distcutoff(500) lagcutoff(100000) 

preserve
/*column 6: neighbourhood FE*/
use "$Output_data\BCRT_neighbour", clear
eststo: my_reg2hdfespatial acled   mines main_lprice main_lprice_mines m_lprice_mines 	if sd_mines == 0	    									, timevar(year) panelvar(couple) lat(latitude) lon(longitude) distcutoff(500) lagcutoff(100000) 

restore

set linesize 250
esttab, mtitles drop(m_lprice_mines) b(%5.3f) se(%5.3f) compress r2 starlevels(c 0.1 b 0.05 a 0.01)  se 
esttab, mtitles drop(m_lprice_mines) b(%5.3f) se(%5.3f) r2  starlevels({$^c$} 0.1 {$^b$} 0.05 {$^a$} 0.01) se tex label  title(Table 2) 
eststo clear

log close


