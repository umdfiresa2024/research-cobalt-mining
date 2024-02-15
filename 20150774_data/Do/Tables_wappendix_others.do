*-----------------------------------------------------------------------------------------------------------------------------------------------*
* This program performs most of the robustness analysis shown in the Web Appendix of "This mine is mine: how minerals fuel conflicts in Africa" *
* This version: October 2016
*-----------------------------------------------------------------------------------------------------------------------------------------------*

			// OUTLINE //

// Table A1 		Distribution of main minerals
// Figure A1 		Conflicts and mines over time 
// Figure A4 		World prices by mineral
// Table A2 		Country-level statistics
// Table A5			Conflicts in neighbouring cells 
// Table A4 		Correlations
// Table A5			Conflicts in neighbouring cells 
// Tables A6-A7 	Conflict onset and ending 
// Table A8 		UCDP-GED 
// Table A9 		Standard errors
// Table A10 		Instrumenting mining activity 
// Table A11 		Droppping large players 
// Table A12 		Adding diamond / tantalum
// Table A13 		Dropping minerals one by one
// Table A14 		FE Logit estimator
// Table A15 		Intensity of mining
// Table A16 		Excluding multiple countries cells
// Table A17-A20 	Levels versus differences
// Table A21 		Time-varying controls 
// Table A22 		Non classical measurement error
// Table A23 		Port-level corruption
// Table A25 		Conflict, mining and population



* ------------------------------------------------------------------------------------ *
					*  Table A1 - Distribution of main minerals *
* ------------------------------------------------------------------------------------ *


cap log close
log using "$Results\Table_A1.log", replace
use "$Output_data\BCRT_baseline", clear
tab mainmineral 
log close

* ------------------------------------------------------------------------------------ *
					*  Figure A1 - Conflicts and mines over time *
* ------------------------------------------------------------------------------------ *

use "$Output_data\BCRT_baseline", clear
collapse (sum) nb_mines_a nb_acled, by(year)
label var nb_mines_a "# mines"
label var nb_acled   "# acled events"
label var year     "Year"

drop if year == .
twoway line nb_acled year, scheme(s1mono) c(l l) m(s i) lwidth(medthick) lcolor(black)  yscale(range(2000 3500)) xlabel(1997(1)2010) ylabel(2000(500)3500) 
graph export "$Results/Figure_A1a.eps", as(eps) replace
twoway line nb_mines_a year, scheme(s1mono) c(l l) m(s i) lwidth(medthick) lcolor(black) xlabel(1997(1)2010)
graph export "$Results/Figure_A1b.eps", as(eps) replace


* ------------------------------------------------------------------------------------ *
						*  Figure A4 - Prices by mineral *
* ------------------------------------------------------------------------------------ *

use "$Output_data/BCRT_baseline.dta", clear
drop if mainmineral == "diamond" | mainmineral == "tungsten" | mainmineral == "manganese"  | mainmineral == "tantalum"
collapse (max) main_lprice, by(mainmineral year)
*
g price_metal_real = exp(main_lprice)
*
drop if mainmineral == ""
g lprice_metal_real = log(price_metal_real)
*
rename lprice_metal_real lprice_metal
rename price_metal_real  price_metal
*
drop if price_metal == . | mainmineral==""
global metals       "aluminum copper gold iron lead nickel tin zinc coal phosphate platinum silver"
save "$Output_data/temp.dta", replace

foreach metal in $metals{
use  "$Output_data/temp.dta", clear
keep if mainmineral == "`metal'"
label var lprice_metal "`metal' price, log"
keep year lprice_metal*
twoway line lprice_metal year, scheme(s1mono) c(l l) m(s i) lwidth(medthick) lcolor(black) xlabel(1997(1)2010)
graph export "$Results/Figure_A4_`metal'.eps", as(eps) replace
}

erase "$Output_data/temp.dta"

* ------------------------------------------------------------------------------------ *
						*  Table A2 - Country-level statistics *
* ------------------------------------------------------------------------------------ *

cap log close 
log using "$Results\Table_A2.log", replace

use "$Output_data\BCRT_baseline", clear
collapse (sum) nb_mines_a nb_acled (mean) mines_a acled, by(iso_1 year)
collapse (mean) nb_mines_a nb_acled (mean) mines_a acled, by(iso_1)
sum nb_mines_a nb_acled, d
distinct iso_1 if nb_mines_a == 0
distinct iso_1 if nb_mines_a >0
distinct iso_1 if nb_acled == 0
distinct iso_1 if nb_acled >0

log close


* ------------------------------------------------------------------------------------ *
						*  Table A3 - Summary statistics *
* ------------------------------------------------------------------------------------ *

use "$Output_data\BCRT_baseline", clear

gen t = 1
bys iso_1 year : egen nb_grid = sum(t)
bys iso_1 year : egen nb_m = sum(t) if mines_a == 1
bys iso_1 year : egen max = max(nb_m)
replace nb_m = max 
drop max

bys iso_1 year : egen nb_a = sum(t) if acled == 1
bys iso_1 year : egen max = max(nb_a)
replace nb_a = max 
drop max

gen share_grid_mines = nb_m / nb_grid
gen share_grid_acled = nb_a / nb_grid

bys iso_1 year : egen sum_nb_acled = sum(nb_acled)
bys iso_1 year : egen sum_nb_mines = sum(nb_mines_a)

collapse (mean) share_grid_mines share_grid_acled nb_m sum_nb_acled sum_nb_mines, by(iso_1)

foreach var of varlist share_grid_mines share_grid_acled nb_m sum_nb_acled {
replace `var' = 0 if `var' == .
}

foreach var of varlist nb_m sum_nb_acled sum_nb_mines{
gen t = round(`var')
replace `var' = t
drop t
}
sort iso_1

save "$Results\Table_A3", replace

use "$Output_data\iso_afr.dta"
sort  iso_1
merge iso_1 using "$Results\Table_A3"
drop _merge
sort country
save "$Results\Table_A3.dta", replace

* ------------------------------------------------------------------------------------ *
								* Table A4 - Correlations *
* ------------------------------------------------------------------------------------ *

cap log close
log using "$Results\Table_A4.log", replace

use "$Output_data\BCRT_baseline", clear

collapse (max) mines_a acled latitude longitude (mean) nb_mines_a (mean) year, by(cell country_nb)
tab country_nb, gen(country_nbd)
/*between cells, panel*/
eststo: my_spatial_2sls acled    mines_a country_nbd*	, latitude(latitude) longitude(longitude) id(cell) time(year) lag(0) dist(500) lagdist(0) /*no time dimension*/
eststo: my_spatial_2sls acled nb_mines_a country_nbd*	, latitude(latitude) longitude(longitude) id(cell) time(year) lag(0) dist(500) lagdist(0) /*no time dimension*/

/*between cells, panel*/
use "$Output_data\BCRT_baseline", clear
eststo: my_reg2hdfespatial acled   mines_a				, timevar(year) panelvar(it) lat(latitude) lon(longitude) distcutoff(500) lagcutoff(100000) 
eststo: my_reg2hdfespatial acled   mines_a				, timevar(it) panelvar(cell) lat(latitude) lon(longitude) distcutoff(500) lagcutoff(100000) 

/*within cells, panel*/
use "$Output_data\BCRT_baseline", clear
eststo: my_reg2hdfespatial acled    mines_a  lprec temp	, timevar(it) panelvar(cell) lat(latitude) lon(longitude) distcutoff(500) lagcutoff(100000) 
eststo: my_reg2hdfespatial acled  nb_mines_a lprec temp	, timevar(it) panelvar(cell) lat(latitude) lon(longitude) distcutoff(500) lagcutoff(100000) 

set linesize 250
esttab, mtitles drop() b(%5.3f) se(%5.3f) compress r2 starlevels(c 0.1 b 0.05 a 0.01)  se 
esttab, mtitles drop() b(%5.3f) se(%5.3f) r2  starlevels({$^c$} 0.1 {$^b$} 0.05 {$^a$} 0.01) se tex label  title() 
eststo clear

log close

* ------------------------------------------------------------------------------------ *
					* Table A5 - Conflicts in neighbouring cells *
* ------------------------------------------------------------------------------------ *

cap log close
log using "$Results\Table_A5.log", replace

use "$Output_data\BCRT_baseline", clear

/* drop diamonds and tantalum for baseline */
drop if mainmineral == "diamond" | mainmineral == "tantalum"

/*condition for estimation with spatial lags of mines*/
g condition_around=((mainmineral != "diamond" & mainmineral_around != "diamond" & mainmineral != "tantalum" & mainmineral_around != "tantalum"))

* columns 1-2: neighbour conflict (1 degree cells) in RHS, not instrumented
eststo: reghdfe acled  main_lprice_mines acled_around_1 							if sd_mines == 0  & condition_around==1     , vce(cluster country_nb) absorb(cell it)
eststo: reghdfe acled  main_lprice_hist0 acled_around_1 							if condition_around==1     					, vce(cluster country_nb) absorb(cell it)
* columns 3/4: neighbour conflict in RHS (1 and 2 degree cells), instrumented by prices in 1 and 2 degree cells
eststo: reghdfe acled  main_lprice_mines (acled_around = main_lprice_a) 			if sd_mines == 0  & condition_around==1 , vce(cluster country_nb) absorb(cell it)
eststo: reghdfe acled  main_lprice_hist0 (acled_around = main_lprice_a) 			if condition_around==1 					, vce(cluster country_nb) absorb(cell it)
* columns 5/6: neighbour conflict in degree 1 in RHS, instrumented by conflict in neighbours of neighbours
eststo: reghdfe acled  main_lprice_mines (acled_around_1 = acled_around_2) 			if sd_mines == 0  & condition_around==1 , vce(cluster country_nb) absorb(cell it)
eststo: reghdfe acled  main_lprice_hist0 (acled_around_1 = acled_around_2) 			if condition_around==1 					, vce(cluster country_nb) absorb(cell it) 

set linesize 250
esttab, mtitles drop() b(%5.3f) se(%5.3f) compress r2 starlevels(c 0.1 b 0.05 a 0.01)  se 
esttab, mtitles drop() b(%5.3f) se(%5.3f) r2  starlevels({$^c$} 0.1 {$^b$} 0.05 {$^a$} 0.01) se tex label  title() 
eststo clear

log close

* ------------------------------------------------------------------------------------ *
					* Tables A6-A7 - Conflict onset and ending  *
* ------------------------------------------------------------------------------------ *


cap log close
log using "$Results\Table_A6_A7.log", replace

use "$Output_data\BCRT_baseline", clear
sort cell year
/*cell level onset*/
g       onset = (acled==1 & l.acled==0)
replace onset = . if l.acled==1
/*cell level ending*/
g       ending = (acled==0 & l.acled==1)
replace ending = . if l.acled==0

/* drop diamonds and tantalum for baseline */
drop if mainmineral == "diamond" | mainmineral == "tantalum"

/*condition for estimation with spatial lags of mines*/
global condition_around "(mainmineral != "diamond" & mainmineral_around != "diamond" & mainmineral != "tantalum" & mainmineral_around != "tantalum")"

foreach var in onset ending{

/*column 1: time varying mining area dummy*/
eststo: my_reg2hdfespatial `var'  mines main_lprice main_lprice_mines m_lprice_mines     								   		, timevar(it) panelvar(cell) lat(latitude) lon(longitude) distcutoff(500) lagcutoff(100000) 
/*column 2: mine open the entire period*/
eststo: my_reg2hdfespatial `var'  main_lprice_mines if sd_mines == 0							    						   	, timevar(it) panelvar(cell) lat(latitude) lon(longitude) distcutoff(500) lagcutoff(100000) 
/*column 3: mine open the entire period, with surrounding mines*/
eststo: my_reg2hdfespatial `var'  main_lprice_mines main_lprice_a if sd_mines == 0  & sd_mines_a ==0  & $condition_around		, timevar(it) panelvar(cell) lat(latitude) lon(longitude) distcutoff(500) lagcutoff(100000)
/*column 4: mine at some point over the period (simply the price variable )*/
eststo: my_reg2hdfespatial `var'   main_lprice_hist0 			   																, timevar(it) panelvar(cell) lat(latitude) lon(longitude) distcutoff(500) lagcutoff(100000) 
/*column 5: year dummies only */
eststo: my_reg2hdfespatial `var'   main_lprice_mines if sd_mines == 0			   												, timevar(year) panelvar(cell) lat(latitude) lon(longitude) distcutoff(500) lagcutoff(100000) 

preserve
/*column 6: neighbour-pair FE */
use "$Output_data\BCRT_neighbour", clear

sort cell year
/*cell level onset*/
g       onset = (acled==1 & l.acled==0)
replace onset = . if acled==1 & l.acled==1
/*cell level ending*/
g       ending = (acled==0 & l.acled==1)
replace ending = . if acled==0 & l.acled==0

eststo: my_reg2hdfespatial `var'   mines main_lprice main_lprice_mines m_lprice_mines if sd_mines == 0	    					, timevar(year) panelvar(couple) lat(latitude) lon(longitude) distcutoff(500) lagcutoff(100000) 
restore

set linesize 250
esttab, mtitles drop(m_lprice_mines) b(%5.3f) se(%5.3f) compress r2 starlevels(c 0.1 b 0.05 a 0.01)  se 
esttab, mtitles drop(m_lprice_mines) b(%5.3f) se(%5.3f) r2  starlevels({$^c$} 0.1 {$^b$} 0.05 {$^a$} 0.01) se tex label  title() 
eststo clear
}

log close


* --------------------------------------------------------------------------------------- *
							* Table A8 - UCDP-GED *
* --------------------------------------------------------------------------------------- *

cap log close
log using "$Results\Table_A8.log", replace

use "$Output_data\BCRT_baseline", clear

g ucdp = (nb_ucdp>0)

/* drop diamonds and tantalum for baseline */
drop if mainmineral == "diamond" | mainmineral == "tantalum"

bys iso_1 year: egen ucdp_check = max(ucdp)
tab ucdp_check

bys iso_1: egen ucdp_min = min(year) if ucdp_check == 1
bys iso_1: egen ucdp_max = max(year) if ucdp_check == 1

gen window = (year > ucdp_min-1 & year < ucdp_max+1)
tab window ucdp_check

gen event=ucdp if ucdp_check == 1
replace event=acled if ucdp_check == 0

gen interacACLED=main_lprice_mines*(1-ucdp_check) 		// price if obs is NOT in UCDP sample
gen interacUCDP=main_lprice_mines*(ucdp_check) 			// price if obs is in UCDP sample

gen interac_histACLED=main_lprice_hist0*(1-ucdp_check) // price if obs is NOT in UCDP sample
gen interac_histUCDP=main_lprice_hist0*(ucdp_check)    // price if obs is in UCDP sample

/*effect of UCDP on UCDP sample*/
eststo: my_reg2hdfespatial ucdp   main_lprice_mines 								if sd_mines == 0 & ucdp_check == 1	, timevar(it) panelvar(cell) lat(latitude) lon(longitude) distcutoff(500) lagcutoff(100000) 
eststo: my_reg2hdfespatial ucdp   main_lprice_hist0 								if ucdp_check == 1					, timevar(it) panelvar(cell) lat(latitude) lon(longitude) distcutoff(500) lagcutoff(100000) 
/*effect of ACLED on UCDP sample*/
eststo: my_reg2hdfespatial acled  main_lprice_mines 								if sd_mines == 0 & ucdp_check == 1	, timevar(it) panelvar(cell) lat(latitude) lon(longitude) distcutoff(500) lagcutoff(100000) 
eststo: my_reg2hdfespatial acled  main_lprice_hist0 								if ucdp_check == 1					, timevar(it) panelvar(cell) lat(latitude) lon(longitude) distcutoff(500) lagcutoff(100000) 
/*Effect of both*/
eststo: my_reg2hdfespatial event  main_lprice_mines ucdp_check 						if sd_mines == 0					, timevar(it) panelvar(cell) lat(latitude) lon(longitude) distcutoff(500) lagcutoff(100000) 
eststo: my_reg2hdfespatial event  main_lprice_hist0 ucdp_check 															, timevar(it) panelvar(cell) lat(latitude) lon(longitude) distcutoff(500) lagcutoff(100000) 
/*Mutually exclusive categories*/
eststo: my_reg2hdfespatial event  interacUCDP interacACLED ucdp_check 				if sd_mines == 0					, timevar(it) panelvar(cell) lat(latitude) lon(longitude) distcutoff(500) lagcutoff(100000) 
eststo: my_reg2hdfespatial event  interac_histUCDP interac_histACLED ucdp_check 										, timevar(it) panelvar(cell) lat(latitude) lon(longitude) distcutoff(500) lagcutoff(100000) 

set linesize 250
esttab, mtitles drop() b(%5.3f) se(%5.3f) compress r2 starlevels(c 0.1 b 0.05 a 0.01)  se 
esttab, mtitles drop() b(%5.3f) se(%5.3f) r2  starlevels({$^c$} 0.1 {$^b$} 0.05 {$^a$} 0.01) se tex label  title() 
eststo clear

log close


* --------------------------------------------------------------------------------------- *
							* Table A9 - Standard errors *
* --------------------------------------------------------------------------------------- *

cap log close
log using "$Results\Table_A9.log", replace

use "$Output_data\BCRT_baseline", clear

/* drop diamonds and tantalum for baseline */
drop if mainmineral == "diamond" | mainmineral == "tantalum"

/*condition for estimation with spatial lags of mines*/
global condition_around "(mainmineral != "diamond" & mainmineral_around != "diamond" & mainmineral != "tantalum" & mainmineral_around != "tantalum")"

		*** distcutoff: 100   -- lagcutoff: 100000

/*column 1: time varying mining area dummy*/
eststo: my_reg2hdfespatial acled  mines main_lprice main_lprice_mines m_lprice_mines     								   		, timevar(it) panelvar(cell) lat(latitude) lon(longitude) distcutoff(100) lagcutoff(100000) 
/*column 2: mine open the entire period*/
eststo: my_reg2hdfespatial acled  main_lprice_mines if sd_mines == 0							    						   	, timevar(it) panelvar(cell) lat(latitude) lon(longitude) distcutoff(100) lagcutoff(100000) 
/*column 3: mine open the entire period, with surrounding mines*/
eststo: my_reg2hdfespatial acled  main_lprice_mines main_lprice_a if sd_mines == 0  & sd_mines_a ==0  & $condition_around		, timevar(it) panelvar(cell) lat(latitude) lon(longitude) distcutoff(100) lagcutoff(100000)
/*column 4: mine at some point over the period (simply the price variable )*/
eststo: my_reg2hdfespatial acled   main_lprice_hist0 			   																, timevar(it) panelvar(cell) lat(latitude) lon(longitude) distcutoff(100) lagcutoff(100000) 
/*column 5: year dummies only */
eststo: my_reg2hdfespatial acled   main_lprice_mines if sd_mines == 0															, timevar(year) panelvar(cell) lat(latitude) lon(longitude) distcutoff(100) lagcutoff(100000) 

preserve
/*column 6: neighbour-pair FE */
use "$Output_data\BCRT_neighbour", clear
eststo: my_reg2hdfespatial acled   mines main_lprice main_lprice_mines m_lprice_mines if sd_mines == 0	    					, timevar(year) panelvar(couple) lat(latitude) lon(longitude) distcutoff(100) lagcutoff(100000) 
restore

set linesize 250
esttab, mtitles drop(m_lprice_mines) b(%5.3f) se(%5.3f) compress r2 starlevels(c 0.1 b 0.05 a 0.01)  se 
esttab, mtitles drop(m_lprice_mines) b(%5.3f) se(%5.3f) r2  starlevels({$^c$} 0.1 {$^b$} 0.05 {$^a$} 0.01) se tex label  title() 
eststo clear

		*** distcutoff: 1000   -- lagcutoff: 100000

/*column 1: time varying mining area dummy*/
eststo: my_reg2hdfespatial acled  mines main_lprice main_lprice_mines m_lprice_mines     								   		, timevar(it) panelvar(cell) lat(latitude) lon(longitude) distcutoff(1000) lagcutoff(100000) 
/*column 2: mine open the entire period*/
eststo: my_reg2hdfespatial acled  main_lprice_mines if sd_mines == 0							    						   	, timevar(it) panelvar(cell) lat(latitude) lon(longitude) distcutoff(1000) lagcutoff(100000) 
/*column 3: mine open the entire period, with surrounding mines*/
eststo: my_reg2hdfespatial acled  main_lprice_mines main_lprice_a if sd_mines == 0  & sd_mines_a ==0  & $condition_around		, timevar(it) panelvar(cell) lat(latitude) lon(longitude) distcutoff(1000) lagcutoff(100000)
/*column 4: mine at some point over the period (simply the price variable )*/
eststo: my_reg2hdfespatial acled   main_lprice_hist0 			   																, timevar(it) panelvar(cell) lat(latitude) lon(longitude) distcutoff(1000) lagcutoff(100000) 
/*column 5: year dummies only */
eststo: my_reg2hdfespatial acled   main_lprice_mines if sd_mines == 0															, timevar(year) panelvar(cell) lat(latitude) lon(longitude) distcutoff(1000) lagcutoff(100000) 

preserve
/*column 6: neighbour-pair FE */
use "$Output_data\BCRT_neighbour", clear
eststo: my_reg2hdfespatial acled   mines main_lprice main_lprice_mines m_lprice_mines if sd_mines == 0	    					, timevar(year) panelvar(couple) lat(latitude) lon(longitude) distcutoff(1000) lagcutoff(100000) 
restore

set linesize 250
esttab, mtitles drop(m_lprice_mines) b(%5.3f) se(%5.3f) compress r2 starlevels(c 0.1 b 0.05 a 0.01)  se 
esttab, mtitles drop(m_lprice_mines) b(%5.3f) se(%5.3f) r2  starlevels({$^c$} 0.1 {$^b$} 0.05 {$^a$} 0.01) se tex label  title() 
eststo clear

		*** distcutoff: 100   -- lagcutoff: 1

/*column 1: time varying mining area dummy*/
eststo: my_reg2hdfespatial acled  mines main_lprice main_lprice_mines m_lprice_mines     								   		, timevar(it) panelvar(cell) lat(latitude) lon(longitude) distcutoff(100) lagcutoff(1) 
/*column 2: mine open the entire period*/
eststo: my_reg2hdfespatial acled  main_lprice_mines if sd_mines == 0							    						   	, timevar(it) panelvar(cell) lat(latitude) lon(longitude) distcutoff(100) lagcutoff(1) 
/*column 3: mine open the entire period, with surrounding mines*/
eststo: my_reg2hdfespatial acled  main_lprice_mines main_lprice_a if sd_mines == 0  & sd_mines_a ==0  & $condition_around		, timevar(it) panelvar(cell) lat(latitude) lon(longitude) distcutoff(100) lagcutoff(1)
/*column 4: mine at some point over the period (simply the price variable )*/
eststo: my_reg2hdfespatial acled   main_lprice_hist0 			   																, timevar(it) panelvar(cell) lat(latitude) lon(longitude) distcutoff(100) lagcutoff(1) 
/*column 5: year dummies only */
eststo: my_reg2hdfespatial acled   main_lprice_mines if sd_mines == 0															, timevar(year) panelvar(cell) lat(latitude) lon(longitude) distcutoff(100) lagcutoff(1) 

preserve
/*column 6: neighbour-pair FE */
use "$Output_data\BCRT_neighbour", clear
eststo: my_reg2hdfespatial acled   mines main_lprice main_lprice_mines m_lprice_mines if sd_mines == 0	    					, timevar(year) panelvar(couple) lat(latitude) lon(longitude) distcutoff(100) lagcutoff(1) 
restore

set linesize 250
esttab, mtitles drop(m_lprice_mines) b(%5.3f) se(%5.3f) compress r2 starlevels(c 0.1 b 0.05 a 0.01)  se 
esttab, mtitles drop(m_lprice_mines) b(%5.3f) se(%5.3f) r2  starlevels({$^c$} 0.1 {$^b$} 0.05 {$^a$} 0.01) se tex label  title() 
eststo clear

		*** distcutoff: 1000   -- lagcutoff: 5

/*column 1: time varying mining area dummy*/
eststo: my_reg2hdfespatial acled  mines main_lprice main_lprice_mines m_lprice_mines     								   		, timevar(it) panelvar(cell) lat(latitude) lon(longitude) distcutoff(1000) lagcutoff(5) 
/*column 2: mine open the entire period*/
eststo: my_reg2hdfespatial acled  main_lprice_mines if sd_mines == 0							    						   	, timevar(it) panelvar(cell) lat(latitude) lon(longitude) distcutoff(1000) lagcutoff(5) 
/*column 3: mine open the entire period, with surrounding mines*/
eststo: my_reg2hdfespatial acled  main_lprice_mines main_lprice_a if sd_mines == 0  & sd_mines_a ==0  & $condition_around		, timevar(it) panelvar(cell) lat(latitude) lon(longitude) distcutoff(1000) lagcutoff(5)
/*column 4: mine at some point over the period (simply the price variable )*/
eststo: my_reg2hdfespatial acled   main_lprice_hist0 			   																, timevar(it) panelvar(cell) lat(latitude) lon(longitude) distcutoff(1000) lagcutoff(5) 
/*column 5: year dummies only */
eststo: my_reg2hdfespatial acled   main_lprice_mines if sd_mines == 0															, timevar(year) panelvar(cell) lat(latitude) lon(longitude) distcutoff(1000) lagcutoff(5) 

preserve
/*column 6: neighbour-pair FE */
use "$Output_data\BCRT_neighbour", clear
eststo: my_reg2hdfespatial acled   mines main_lprice main_lprice_mines m_lprice_mines if sd_mines == 0	    					, timevar(year) panelvar(couple) lat(latitude) lon(longitude) distcutoff(1000) lagcutoff(5) 
restore

set linesize 250
esttab, mtitles drop(m_lprice_mines) b(%5.3f) se(%5.3f) compress r2 starlevels(c 0.1 b 0.05 a 0.01)  se 
esttab, mtitles drop(m_lprice_mines) b(%5.3f) se(%5.3f) r2  starlevels({$^c$} 0.1 {$^b$} 0.05 {$^a$} 0.01) se tex label  title() 
eststo clear

		*** country clusters 

g condition_around =(mainmineral != "diamond" & mainmineral_around != "diamond" & mainmineral != "tantalum" & mainmineral_around != "tantalum")

/*column 1: time varying mining area dummy*/
eststo: reghdfe acled  mines main_lprice main_lprice_mines m_lprice_mines     								   		, a(it cell) vce(cluster country_nb)
/*column 2: mine open the entire period*/
eststo: reghdfe acled  main_lprice_mines if sd_mines == 0							    						   	, a(it cell) vce(cluster country_nb)
/*column 3: mine open the entire period, with surrounding mines*/
eststo: reghdfe acled  main_lprice_mines main_lprice_a if sd_mines == 0  & sd_mines_a ==0  & condition_around==1	, a(it cell) vce(cluster country_nb)
/*column 4: mine at some point over the period (simply the price variable )*/
eststo: reghdfe acled   main_lprice_hist0 			   																, a(it cell) vce(cluster country_nb)
/*column 5: year dummies only */
eststo: reghdfe acled   main_lprice_mines if sd_mines == 0															, a(it cell) vce(cluster country_nb)

preserve
/*column 6: neighbour-pair FE */
use "$Output_data\BCRT_neighbour", clear
eststo: reghdfe acled   mines main_lprice main_lprice_mines m_lprice_mines if sd_mines == 0	    					, a(year couple) vce(cluster country_nb) 
restore

set linesize 250
esttab, mtitles drop(m_lprice_mines) b(%5.3f) se(%5.3f) compress r2 starlevels(c 0.1 b 0.05 a 0.01)  se 
esttab, mtitles drop(m_lprice_mines) b(%5.3f) se(%5.3f) r2  starlevels({$^c$} 0.1 {$^b$} 0.05 {$^a$} 0.01) se tex label  title() 
eststo clear

log close


* --------------------------------------------------------------------------------------- *
						* Table A10 - Instrumenting mining activity *
* --------------------------------------------------------------------------------------- *


cap log close
log using "$Results\Table_A10.log", replace

use "$Output_data\BCRT_baseline", clear

/* drop diamonds and tantalum for baseline */
drop if mainmineral == "diamond" | mainmineral == "tantalum"

/* mining areas: from the first time a mine was observed onwards */
sort cell year
bys  cell: gen cum_mines	= sum(mines)
g mining_area 				= cum_mines>0 
replace mining_area 		= . if cum_mines ==0 & max_mine>0

/* mining areas: mine is observed in 1997 */
g temp1 					= (year == 1997 & mines == 1)
bys gid: egen mining_area2 	= max(temp1)
drop temp1

/* interactions */
g main_lprice_hist1 		= main_lprice*mining_area
g main_lprice_hist2 		= main_lprice*mining_area2
g main_lprice_hist3 		= main_lprice*mining_area_prior5
g main_lprice_hist4 		= main_lprice*mining_area_priorall

keep if main_lprice_mines != .

*******************************************
* First instrument: mine open before 1997 *
*******************************************

/* equivalent of col 2, baseline table*/

//first stage 
reghdfe main_lprice_mines main_lprice_hist4 	if sd_mines==0 		   			, vce(cluster country_nb) absorb(cell it)  
//second stage
eststo: reghdfe acled  (main_lprice_mines = main_lprice_hist4) if sd_mines==0 	, vce(cluster country_nb) absorb(cell it) 

/* equivalent of col 4, baseline table*/

//first stage
reghdfe main_lprice_hist0 main_lprice_hist4, vce(cluster country_nb) absorb(cell it) 
//second stage
eststo: reghdfe acled  (main_lprice_hist0 = main_lprice_hist4), vce(cluster country_nb) absorb(cell it) 

/* equivalent of col 6, baseline table*/

// demeaning
preserve
use "$Output_data\BCRT_neighbour", clear
g main_lprice_hist4 = main_lprice*mining_area_priorall
g control 			= mining_area_priorall*m_main_lprice
reghdfe acled   main_lprice  (mines main_lprice_mines m_lprice_mines= main_lprice_hist4 mining_area_priorall control)  if sd_mines == 0, vce(cluster country_nb) absorb(couple year) 
keep if e(sample)
foreach var in acled main_lprice mines main_lprice_mines m_lprice_mines main_lprice_hist4 mining_area_priorall control{
	bys year: egen mean_`var'_it   = mean(`var')
}
foreach var in acled main_lprice mines main_lprice_mines m_lprice_mines main_lprice_hist4 mining_area_priorall control{
	g `var'_dm = `var'-mean_`var'_it
}
foreach var in acled main_lprice mines main_lprice_mines m_lprice_mines main_lprice_hist4 mining_area_priorall control{
	bys couple: egen mean_`var'_cell = mean(`var'_dm)
}

foreach var in acled main_lprice mines main_lprice_mines m_lprice_mines main_lprice_hist4 mining_area_priorall control{
	g `var'_ddm = `var'-mean_`var'_cell-mean_`var'_it
}
//first stage
my_spatial_2sls main_lprice_mines_ddm main_lprice_ddm main_lprice_hist4_ddm mining_area_priorall_ddm control_ddm, latitude(latitude) longitude(longitude) id(couple) time(year) lag(100000) dist(500) lagdist(0)
//second stage
eststo: my_spatial_2sls acled_ddm main_lprice_ddm, end(mines_ddm main_lprice_mines_ddm m_lprice_mines_ddm) iv(main_lprice_hist4_ddm mining_area_priorall_ddm control_ddm) latitude(latitude) longitude(longitude) id(couple) time(year) lag(100000) dist(500) lagdist(0)
restore

******************************************************************
* Second instrument: main_lprice instrumenting for mine opening  *
******************************************************************

//first stage
reghdfe mines main_lprice, vce(cluster country_nb) absorb(cell it) 
//second stage
eststo: reghdfe acled  (mines = main_lprice), vce(cluster country_nb) absorb(cell it) 

set linesize 250
esttab, mtitles drop(m_lprice_mines_ddm) b(%5.3f) se(%5.3f) compress r2 starlevels(c 0.1 b 0.05 a 0.01)  se 
esttab, mtitles drop(m_lprice_mines_ddm) b(%5.3f) se(%5.3f) r2  starlevels({$^c$} 0.1 {$^b$} 0.05 {$^a$} 0.01) se tex label  title() 
eststo clear

log close

* --------------------------------------------------------------------------------------- *
						* Table A11 - Droppping large players *
* --------------------------------------------------------------------------------------- *


cap log close
log using "$Results\Table_A11.log", replace

use "$Output_data\BCRT_baseline", clear

/* drop diamonds and tantalum for baseline */
drop if mainmineral == "diamond" | mainmineral == "tantalum"

/*condition for estimation with spatial lags of mines*/
global condition_around "(mainmineral != "diamond" & mainmineral_around != "diamond" & mainmineral != "tantalum" & mainmineral_around != "tantalum")"

/*column 1: time varying mining area dummy*/
eststo: my_reg2hdfespatial acled  mines main_lprice main_lprice_mines m_lprice_mines    if big == 0							   								, timevar(it) panelvar(cell) lat(latitude) lon(longitude) distcutoff(500) lagcutoff(100000) 
/*column 2: mine open the entire period*/
eststo: my_reg2hdfespatial acled  main_lprice_mines 									if sd_mines == 0 & big == 0							    		   	, timevar(it) panelvar(cell) lat(latitude) lon(longitude) distcutoff(500) lagcutoff(100000) 
/*column 3: mine open the entire period, with surrounding mines*/
eststo: my_reg2hdfespatial acled  main_lprice_mines main_lprice_a 						if sd_mines == 0  & sd_mines_a ==0  & $condition_around	& big == 0	, timevar(it) panelvar(cell) lat(latitude) lon(longitude) distcutoff(500) lagcutoff(100000)
/*column 4: mine at some point over the period (simply the price variable )*/
eststo: my_reg2hdfespatial acled   main_lprice_hist0 									if  big == 0	   													, timevar(it) panelvar(cell) lat(latitude) lon(longitude) distcutoff(500) lagcutoff(100000) 
/*column 5: year dummies only */
eststo: my_reg2hdfespatial acled  main_lprice_mines 									if sd_mines == 0 & big == 0											, timevar(year) panelvar(cell) lat(latitude) lon(longitude) distcutoff(500) lagcutoff(100000) 

preserve
/*column 6: neighbour-pair FE */
use "$Output_data\BCRT_neighbour", clear
eststo: my_reg2hdfespatial acled   mines main_lprice main_lprice_mines m_lprice_mines 	if sd_mines == 0	 & big == 0   									, timevar(year) panelvar(couple) lat(latitude) lon(longitude) distcutoff(500) lagcutoff(100000) 
restore

set linesize 250
esttab, mtitles drop(m_lprice_mines) b(%5.3f) se(%5.3f) compress r2 starlevels(c 0.1 b 0.05 a 0.01)  se 
esttab, mtitles drop(m_lprice_mines) b(%5.3f) se(%5.3f) r2  starlevels({$^c$} 0.1 {$^b$} 0.05 {$^a$} 0.01) se tex label  title() 
eststo clear

log close


* --------------------------------------------------------------------------------------- *
						* Table A12 - Adding diamond / tantalum *
* --------------------------------------------------------------------------------------- *

cap log close
log using "$Results\Table_A12.log", replace

use "$Output_data\BCRT_baseline", clear

/*condition for estimation with spatial lags of mines*/
global condition_around "(mainmineral != "diamond" & mainmineral_around != "diamond" & mainmineral != "tantalum" & mainmineral_around != "tantalum")"

/*column 1: time varying mining area dummy*/
eststo: my_reg2hdfespatial acled  mines main_lprice main_lprice_mines m_lprice_mines     								   						, timevar(it) panelvar(cell) lat(latitude) lon(longitude) distcutoff(500) lagcutoff(100000) 
/*column 2: mine open the entire period*/
eststo: my_reg2hdfespatial acled  main_lprice_mines 								if sd_mines == 0							    		   	, timevar(it) panelvar(cell) lat(latitude) lon(longitude) distcutoff(500) lagcutoff(100000) 
/*column 3: mine open the entire period, with surrounding mines*/
eststo: my_reg2hdfespatial acled  main_lprice_mines main_lprice_a 					if sd_mines == 0  & sd_mines_a ==0  & $condition_around		, timevar(it) panelvar(cell) lat(latitude) lon(longitude) distcutoff(500) lagcutoff(100000)
/*column 4: mine at some point over the period (simply the price variable )*/
eststo: my_reg2hdfespatial acled   main_lprice_hist0 			   																				, timevar(it) panelvar(cell) lat(latitude) lon(longitude) distcutoff(500) lagcutoff(100000) 
/*column 5: year dummies only */
eststo: my_reg2hdfespatial acled  main_lprice_mines 								if sd_mines == 0											, timevar(year) panelvar(cell) lat(latitude) lon(longitude) distcutoff(500) lagcutoff(100000) 

preserve
/*column 6: neighbour-pair FE */
use "$Output_data\BCRT_neighbour", clear
eststo: my_reg2hdfespatial acled   mines main_lprice main_lprice_mines m_lprice_mines if sd_mines == 0	    									, timevar(year) panelvar(couple) lat(latitude) lon(longitude) distcutoff(500) lagcutoff(100000) 

restore

set linesize 250
esttab, mtitles drop(m_lprice_mines) b(%5.3f) se(%5.3f) compress r2 starlevels(c 0.1 b 0.05 a 0.01)  se 
esttab, mtitles drop(m_lprice_mines) b(%5.3f) se(%5.3f) r2  starlevels({$^c$} 0.1 {$^b$} 0.05 {$^a$} 0.01) se tex label  title() 
eststo clear

log close


* --------------------------------------------------------------------------------------- *
						* Table A13 - Dropping minerals one by one *
* --------------------------------------------------------------------------------------- *

cap log close
log using "$Results\Table_A13.log", replace

use "$Output_data\BCRT_baseline", clear

tab mainmineral 

/* drop diamonds and tantalum for baseline */
drop if mainmineral == "diamond" | mainmineral == "tantalum" 

/*condition for estimation with spatial lags of mines*/
global condition_around "(mainmineral != "diamond" & mainmineral_around != "diamond" & mainmineral != "tantalum" & mainmineral_around != "tantalum")"

levelsof mainmineral, local(name)

foreach x of local name {
eststo, title("`x'"): my_reg2hdfespatial acled  main_lprice_mines if sd_mines == 0	&  mainmineral != "`x'"						    						   	, timevar(it) panelvar(cell) lat(latitude) lon(longitude) distcutoff(500) lagcutoff(100000) 
}

set linesize 250
esttab, mtitles drop() b(%5.3f) se(%5.3f) compress r2 starlevels(c 0.1 b 0.05 a 0.01)  se 
esttab, mtitles drop() b(%5.3f) se(%5.3f) r2  starlevels({$^c$} 0.1 {$^b$} 0.05 {$^a$} 0.01) se tex label  title() 
eststo clear

log close

* --------------------------------------------------------------------------------------- *
						* Table A14 - FE Logit estimator *
* --------------------------------------------------------------------------------------- *


cap log close
log using "$Results\Table_A14.log", replace

use "$Output_data\BCRT_baseline", clear

/* drop diamonds and tantalum for baseline */
drop if mainmineral == "diamond" | mainmineral == "tantalum"

/*condition for estimation with spatial lags of mines*/
global condition_around "(mainmineral != "diamond" & mainmineral_around != "diamond" & mainmineral != "tantalum" & mainmineral_around != "tantalum")"

/*column 1: time varying mining area dummy*/
eststo: clogit acled  mines main_lprice main_lprice_mines m_lprice_mines yeard*									   								, group(cell) cluster(country_nb)
/*column 2: mine open the entire period*/			
eststo: clogit acled  main_lprice_mines yeard* 										if sd_mines == 0							    			, group(cell) cluster(country_nb)
/*column 3: mine open the entire period, with surrounding mines*/
eststo: clogit acled  main_lprice_mines main_lprice_a yeard* 						if sd_mines == 0  & sd_mines_a ==0  & $condition_around		, group(cell) cluster(country_nb)
/*column 4: mine at some point over the period (simply the price variable )*/
eststo: clogit acled   main_lprice_hist0 yeard* 			   																					, group(cell) cluster(country_nb)

preserve
/*column 6: neighbour-pair FE */
use "$Output_data\BCRT_neighbour", clear
eststo: clogit acled   mines main_lprice main_lprice_mines m_lprice_mines 			if sd_mines == 0	    									, group(cell) cluster(country_nb)

restore

set linesize 250
esttab, mtitles drop(m_lprice_mines) b(%5.3f) se(%5.3f) compress r2 starlevels(c 0.1 b 0.05 a 0.01)  se 
esttab, mtitles drop(m_lprice_mines) b(%5.3f) se(%5.3f) r2  starlevels({$^c$} 0.1 {$^b$} 0.05 {$^a$} 0.01) se tex label  title() 
eststo clear

log close


* --------------------------------------------------------------------------------------- *
							* Table A15 - Intensity of mining *
* --------------------------------------------------------------------------------------- *


cap log close
log using "$Results\Table_A15.log", replace

use "$Output_data\BCRT_baseline", clear

/* drop diamonds and tantalum for baseline */
drop if mainmineral == "diamond" | mainmineral == "tantalum"

	/*condition for estimation with spatial lags of mines*/
global condition_around "(mainmineral != "diamond" & mainmineral_around != "diamond" & mainmineral != "tantalum" & mainmineral_around != "tantalum")"

global metals      				"aluminum coal copper lead tin nickel zinc gold platinum silver iron phosphate"

/* CONVERT PRICE UNITS TO TONS (other minerals are already in tons) */
replace price_gold     		= price_gold*32150.7     	/*initially in $ / troy oz*/
replace price_platinum 		= price_platinum*32150.7	/*initially in $/ troy oz*/
replace price_silver   		= price_silver*321.507   	/*initially in cents / troy oz*/
replace price_tin      		= price_tin*10  			/* initially in cents / kg */
replace price_lead     		= price_lead*10 			/* initially in cents / kg */
replace price_zinc     		= price_zinc*10  			/* initially in cents / kg */
*
bys gid : egen production_mean = mean(production_main)
*
gen production_97 = production_main if year == 1997
bys gid : egen t  = max(production_97)
drop production_97
rename t production_97
*
g value_mainmineral = 0
g value_mainmineral97 = 0

foreach metal in $metals{
replace value_mainmineral    	= price_`metal' * production_mean	       if mainmineral == "`metal'"
replace value_mainmineral97    	= price_`metal' * production_97		       if mainmineral == "`metal'"
}
*
gen lvalue_mainmineral 		= ln(1+value_mainmineral)
gen lvalue_mainmineral97 	= ln(1+value_mainmineral97)

g main_lprice_lnbmines    	= main_lprice*log(nb_mines+1)

bys cell: egen nb_mines_av	= mean(nb_mines)
g main_lprice_nbmines_av    = main_lprice*nb_mines_av
 
** Intensive AND extensive **
* est1:  nb of mines
eststo: my_reg2hdfespatial acled main_lprice_nbmines if sd_nb_mines == 0							    		, timevar(it) panelvar(cell) lat(latitude) lon(longitude) distcutoff(500) lagcutoff(100000) 

* est2:  nb of mines (average)
eststo: my_reg2hdfespatial acled main_lprice_nbmines_av							    						   	, timevar(it) panelvar(cell) lat(latitude) lon(longitude) distcutoff(500) lagcutoff(100000) 

* est3:  average production value
eststo: my_reg2hdfespatial acled lvalue_mainmineral  if sd_mines == 0							    			, timevar(it) panelvar(cell) lat(latitude) lon(longitude) distcutoff(500) lagcutoff(100000) 

* est4:  average production value
eststo: my_reg2hdfespatial acled lvalue_mainmineral  							    						   	, timevar(it) panelvar(cell) lat(latitude) lon(longitude) distcutoff(500) lagcutoff(100000) 

* est5:  production value in 1997
eststo: my_reg2hdfespatial acled  lvalue_mainmineral97  if sd_mines == 0							    		, timevar(it) panelvar(cell) lat(latitude) lon(longitude) distcutoff(500) lagcutoff(100000) 

* est6:  production value in 1997
eststo: my_reg2hdfespatial acled  lvalue_mainmineral97  							    						, timevar(it) panelvar(cell) lat(latitude) lon(longitude) distcutoff(500) lagcutoff(100000) 


set linesize 250
esttab, mtitles drop() b(%5.3f) se(%5.3f) compress r2 starlevels(c 0.1 b 0.05 a 0.01)  se 
esttab, mtitles drop() b(%5.3f) se(%5.3f) r2  starlevels({$^c$} 0.1 {$^b$} 0.05 {$^a$} 0.01) se tex label  title() 
eststo clear

log close

* --------------------------------------------------------------------------------------- *
					* Table A16 - Exluding multiple countries cells *
* --------------------------------------------------------------------------------------- *


cap log close
log using "$Results\Table_A16.log", replace

use "$Output_data\BCRT_baseline", clear

bys cell: egen mean_bdist = mean(bdist1)
drop if mean_bdist < 30

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
/*column 4: mine at some point over the period (simply the price variable )*/
eststo: my_reg2hdfespatial acled   main_lprice_hist0 			   																					, timevar(it) panelvar(cell) lat(latitude) lon(longitude) distcutoff(500) lagcutoff(100000) 
/*column 5: year dummies only */
eststo: my_reg2hdfespatial acled  main_lprice_mines 									if sd_mines == 0											, timevar(year) panelvar(cell) lat(latitude) lon(longitude) distcutoff(500) lagcutoff(100000) 

preserve
/*column 6: neighbour-pair FE */
use "$Output_data\BCRT_neighbour", clear

bys cell: egen mean_bdist = mean(bdist1)
drop if mean_bdist < 30

eststo: my_reg2hdfespatial acled   mines main_lprice main_lprice_mines m_lprice_mines 	if sd_mines == 0	    									, timevar(year) panelvar(couple) lat(latitude) lon(longitude) distcutoff(500) lagcutoff(100000) 

restore

set linesize 250
esttab, mtitles drop(m_lprice_mines) b(%5.3f) se(%5.3f) compress r2 starlevels(c 0.1 b 0.05 a 0.01)  se 
esttab, mtitles drop(m_lprice_mines) b(%5.3f) se(%5.3f) r2  starlevels({$^c$} 0.1 {$^b$} 0.05 {$^a$} 0.01) se tex label  title() 
eststo clear

log close


* --------------------------------------------------------------------------------------- *
					* Table A17 to A20 : levels versus differences *
* --------------------------------------------------------------------------------------- *


cap log close
log using "$Results\Tables_A17_to_A20.log", replace

*-----------------------------*
* Table A19 : log differences *
*-----------------------------*

use "$Output_data\BCRT_baseline", clear

/* drop diamonds for baseline */
drop if mainmineral == "diamond" | mainmineral == "tantalum"

/*linear trends by mineral*/
g trend = year-1996
replace mainmineral = "nomineral" if mainmineral == ""
tab mainmineral, gen(mainminerald)
forvalues x=1(1)13{
gen trend_mainmineral`x' = trend*mainminerald`x'
}
/*column 1: price levels */
eststo: my_reg2hdfespatial acled  main_lprice_mines   if sd_mines == 0							    						   		, timevar(it) panelvar(cell) lat(latitude) lon(longitude) distcutoff(500) lagcutoff(100000) 
/*column 2: first log difference */
eststo: my_reg2hdfespatial acled  main_dlprice_mines  if sd_mines == 0							    						   		, timevar(it) panelvar(cell) lat(latitude) lon(longitude) distcutoff(500) lagcutoff(100000) 
/*column 3: second differences */
eststo: my_reg2hdfespatial acled  main_d2lprice_mines if sd_mines == 0							    						   		, timevar(it) panelvar(cell) lat(latitude) lon(longitude) distcutoff(500) lagcutoff(100000) 
/*column 4: third differences */
eststo: my_reg2hdfespatial acled  main_d3lprice_mines if sd_mines == 0							    						   		, timevar(it) panelvar(cell) lat(latitude) lon(longitude) distcutoff(500) lagcutoff(100000) 

set linesize 250
esttab, mtitles drop() b(%5.3f) se(%5.3f) compress r2 starlevels(c 0.1 b 0.05 a 0.01)  se 
esttab, mtitles drop() b(%5.3f) se(%5.3f) r2  starlevels({$^c$} 0.1 {$^b$} 0.05 {$^a$} 0.01) se tex label  title() 
eststo clear

*------------------------------*
* Table A20 :short vs long run *
*------------------------------*

use "$Output_data\BCRT_baseline", clear

/* drop diamonds and tantalum for baseline */
drop if mainmineral == "diamond" | mainmineral == "tantalum"

/*condition for estimation with spatial lags of mines*/
global condition_around "(mainmineral != "diamond" & mainmineral_around != "diamond" & mainmineral != "tantalum" & mainmineral_around != "tantalum")"

drop main_lprice_mines_l1
sort cell year

g main_lprice_mines_l1  = l.main_lprice_mines 
g main_lprice_mines_l2  = l2.main_lprice_mines 
g main_lprice_mines_d1  = d.main_lprice_mines 
g main_lprice_mines_d1f = f.main_lprice_mines_d1 
g main_lprice_mines_f1  = f.main_lprice_mines 

*ONLY LAG
eststo: my_reg2hdfespatial acled  main_lprice_mines_l1  											if sd_mines == 0	, timevar(it) panelvar(cell) lat(latitude) lon(longitude) distcutoff(500) lagcutoff(100000) 
*LAG AND CURRENT
eststo: my_reg2hdfespatial acled  main_lprice_mines_l1 main_lprice_mines	 						if sd_mines == 0	, timevar(it) panelvar(cell) lat(latitude) lon(longitude) distcutoff(500) lagcutoff(100000) 
lincom main_lprice_mines_l1+main_lprice_mines	 					// sum coeffs
*CURRENT AND TWO LAGS 
eststo: my_reg2hdfespatial acled  main_lprice_mines_l2 main_lprice_mines_l1 main_lprice_mines 		if sd_mines == 0	, timevar(it) panelvar(cell) lat(latitude) lon(longitude) distcutoff(500) lagcutoff(100000) 
lincom main_lprice_mines_l2+main_lprice_mines_l1+main_lprice_mines	// sum coeffs
*ONLY LEAD
eststo: my_reg2hdfespatial acled  main_lprice_mines_f1  											if sd_mines == 0	, timevar(it) panelvar(cell) lat(latitude) lon(longitude) distcutoff(500) lagcutoff(100000) 
*LEAD AND CURRENT
eststo: my_reg2hdfespatial acled  main_lprice_mines_f1 main_lprice_mines	 						if sd_mines == 0	, timevar(it) panelvar(cell) lat(latitude) lon(longitude) distcutoff(500) lagcutoff(100000) 
lincom main_lprice_mines_f1+main_lprice_mines						// sum coeffs	 
*LAG AND FIRST DIFF
eststo: my_reg2hdfespatial acled  main_lprice_mines main_lprice_mines_d1	 						if sd_mines == 0	, timevar(it) panelvar(cell) lat(latitude) lon(longitude) distcutoff(500) lagcutoff(100000) 
*CURRENT AND FIRST DIFF LEAD AND LAG
eststo: my_reg2hdfespatial acled  main_lprice_mines main_lprice_mines_d1 main_lprice_mines_d1f 		if sd_mines == 0	, timevar(it) panelvar(cell) lat(latitude) lon(longitude) distcutoff(500) lagcutoff(100000) 

set linesize 250
esttab, mtitles drop() b(%5.3f) se(%5.3f) compress r2 starlevels(c 0.1 b 0.05 a 0.01)  se 
esttab, mtitles drop() b(%5.3f) se(%5.3f) r2  starlevels({$^c$} 0.1 {$^b$} 0.05 {$^a$} 0.01) se tex label  title() 
eststo clear


*---------------------------------*
	    * UNIT ROOT TESTS 	 *
*---------------------------------*

// Start with raw WB data
// Mineral prices from 1960 to 2012

use "$Output_data\wb_prices", clear 

rename aluminum_price_wb 		price_1 
rename copper_price_wb 			price_2
rename lead_price_wb 			price_3
rename tin_price_wb 			price_4
rename nickel_price_wb 			price_5
rename zinc_price_wb 			price_6
rename gold_price_wb 			price_7	
rename platinum_price_wb 		price_8
rename silver_price_wb 			price_9
rename iron_price_wb 			price_10
rename coal_price_wb 			price_11
rename phosphate_price_wb		price_12

reshape long price_, i(year) j(mineral)
tsset mineral year
rename price_ price

g lprice     = log(price)
g dlprice    = d.lprice
g d2lprice   = lprice-l2.lprice
g d3lprice   = lprice-l3.lprice

/*purge from mineral and year dummies*/
tab year, gen(yeard)
tab mineral, gen(minerald)

foreach var in lprice dlprice d2lprice d3lprice{
qui reg `var' yeard* 
predict `var'_res_y, res
}
save "$Output_data\price_stationarity", replace

*--------------------------------------------------*
* Table A17 - Dickey Fuller tests, for each series *
*--------------------------------------------------*

/* Dickey fuller test - null is unit root (non stationary)*/
forvalues x=1(1)12{
use "$Output_data\price_stationarity", clear
qui keep if mineral == `x'
qui dfuller lprice_res_y, drift
di r(p)
}

*----------------------------------------*
* Table A18 - Panel data unit root tests *
*----------------------------------------*

* WITH LOG PRICE PURGED FROM YEAR DUMMIES

/* Im Pesaran Shin*/
use "$Output_data\price_stationarity", clear
xtunitroot ips lprice_res_y

/*Levin Lin Chu test*/
use "$Output_data\price_stationarity", clear
drop if mineral == 11 /*requires balanced panel*/
xtunitroot llc lprice_res_y 

/*Harris–Tzavalis test*/
use "$Output_data\price_stationarity", clear
drop if mineral == 11 /*requires balanced panel*/
xtunitroot ht lprice_res_y 

/*Breitung test*/
use "$Output_data\price_stationarity", clear
drop if mineral == 11 /*requires balanced panel*/
xtunitroot breitung lprice_res_y

/*Fisher type (combined Dickey Fuller)*/
use "$Output_data\price_stationarity", clear
drop if mineral == 11 /*requires balanced panel*/
xtunitroot fisher lprice_res_y, pp lags(3)

/*Hadri test*/
use "$Output_data\price_stationarity", clear
drop if mineral == 11 /*requires balanced panel*/
xtunitroot hadri lprice_res_y

*clean 
erase "$Output_data\price_stationarity.dta"
log close


* --------------------------------------------------------------------------------------- *
						* Table A21 - Time-varying controls  *
* --------------------------------------------------------------------------------------- *

cap log close
log using "$Results\Table_A21.log", replace

use "$Output_data\BCRT_baseline", clear

/* drop diamonds and tantalum for baseline */
drop if mainmineral == "diamond" | mainmineral == "tantalum"

/*condition for estimation with spatial lags of mines*/
global condition_around "(mainmineral != "diamond" & mainmineral_around != "diamond" & mainmineral != "tantalum" & mainmineral_around != "tantalum")"

/* interaction: precipitaton, temperature */

egen mean_temp  = mean(temp)
egen mean_lprec = mean(lprec)
gen mines_temp 	= mines*(temp-mean_temp)
gen mines_prec 	= mines*(lprec-mean_lprec)


* Precipitation and temperature *
*********************************

/*column 1: time varying mining area dummy*/
eststo: my_reg2hdfespatial acled  mines main_lprice main_lprice_mines m_lprice_mines  mines_temp mines_prec	temp lprec					   											, timevar(it) panelvar(cell) lat(latitude) lon(longitude) distcutoff(500) lagcutoff(100000) 
/*column 2: mine open the entire period*/
eststo: my_reg2hdfespatial acled  main_lprice_mines mines_temp mines_prec	 temp lprec 									if sd_mines == 0				    					, timevar(it) panelvar(cell) lat(latitude) lon(longitude) distcutoff(500) lagcutoff(100000) 
/*column 3: mine open the entire period, with surrounding mines*/
eststo: my_reg2hdfespatial acled  main_lprice_mines main_lprice_a mines_temp mines_prec	 temp lprec 						if sd_mines == 0  & sd_mines_a ==0  & $condition_around	, timevar(it) panelvar(cell) lat(latitude) lon(longitude) distcutoff(500) lagcutoff(100000)
/*column 4: mine at some point over the period (simply the price variable )*/
eststo: my_reg2hdfespatial acled   main_lprice_hist0 mines_temp mines_prec	 temp lprec 			   																				, timevar(it) panelvar(cell) lat(latitude) lon(longitude) distcutoff(500) lagcutoff(100000) 
/*column 5: year dummies only */
eststo: my_reg2hdfespatial acled  main_lprice_mines mines_temp mines_prec	 temp lprec 									if sd_mines == 0										, timevar(year) panelvar(cell) lat(latitude) lon(longitude) distcutoff(500) lagcutoff(100000) 

preserve
/*column 6: neighbour-pair FE */
use "$Output_data\BCRT_neighbour", clear

egen mean_temp  = mean(temp)
egen mean_lprec = mean(lprec)
gen mines_temp 	= mines*(temp-mean_temp)
gen mines_prec 	= mines*(lprec-mean_lprec)

eststo: my_reg2hdfespatial acled   mines main_lprice main_lprice_mines m_lprice_mines mines_temp mines_prec	temp lprec 		if sd_mines == 0	    								, timevar(year) panelvar(couple) lat(latitude) lon(longitude) distcutoff(500) lagcutoff(100000) 

restore

set linesize 250
esttab, mtitles drop(m_lprice_mines) b(%5.3f) se(%5.3f) compress r2 starlevels(c 0.1 b 0.05 a 0.01)  se 
esttab, mtitles drop(m_lprice_mines) b(%5.3f) se(%5.3f) r2  starlevels({$^c$} 0.1 {$^b$} 0.05 {$^a$} 0.01) se tex label  title() 
eststo clear

log close

* --------------------------------------------------------------------------------------- *
					* Table A22 - Non classical measurement error *
* --------------------------------------------------------------------------------------- *

cap log close
log using "$Results\Table_A22.log", replace

use "$Output_data\BCRT_baseline", clear
collapse year, by(gid)
drop year
sort gid
save "$Output_data\tmp", replace

use "$Output_data\Diamond_gid", clear
rename long longitude
drop longitude

gen know_prod		= (mineinfo == "Y" 	| mineinfo == "y")
gen artisanal_prod	= (mineinfo == "YA")
gen commercial_prod	= (mineinfo == "YC")
gen possible_prod	= (mineinfo == "P1" | mineinfo == "P2")
gen unknow_prod		= (mineinfo == "N" 	| mineinfo == "U")

keep if know_prod == 1 | artisanal_prod == 1| commercial_prod == 1

sort gid 
merge gid using "$Output_data\tmp"
keep if _merge == 3
drop _merge

gen t = 1
bys gid : egen nb_mines_diam = sum(t)
label var nb_mines_diam "Nb of mines by grid. Source: DIADATA"
duplicates drop
keep gid nb_mines_diam know_prod artisanal_prod commercial_prod
sort gid
save "$Output_data\lujala_temp", replace

use "$Output_data\BCRT_baseline", clear
sort gid
merge gid using "$Output_data\lujala_temp"
replace nb_mines_diam=0 if nb_mines_diam==.
erase "$Output_data\lujala_temp.dta"

*start with correlation
correlate nb_diamond nb_mines_diam

*cross-tab
tabulate nb_diamond nb_mines_diam

gen RMD_ddummy=0
replace RMD_ddummy=1 if nb_diamond>=1
replace RMD_ddummy=. if nb_diamond==.

gen Lujala_ddummy=0
replace Lujala_ddummy=1 if nb_mines_diam>=1
replace Lujala_ddummy=. if nb_mines_diam==.

tabulate RMD_ddummy Lujala_ddummy
tabulate RMD_ddummy artisanal_prod
tabulate RMD_ddummy commercial_prod

egen id_iso = group(iso_1)

*pooled panel
eststo: reg nb_diamond nb_mines_diam nb_acled					,  r cl(country_nb)
*pooled panel with yearFE
eststo: areg nb_diamond nb_mines_diam nb_acled 					, absorb(year) r cl(country_nb)
*pooled panel with countryFE
eststo: areg nb_diamond nb_mines_diam nb_acled 					, absorb(id_iso) ro cl(country_nb)
*pooled panel with country*yearFE
eststo: areg nb_diamond nb_mines_diam nb_acled 					, absorb(it) r cl(country_nb)

set linesize 250
esttab, mtitles keep(nb_mines_diam nb_acled) b(%5.3f) se(%5.3f) compress r2 starlevels(c 0.1 b 0.05 a 0.01)  se 
esttab, mtitles keep(nb_mines_diam nb_acled) b(%5.3f) se(%5.3f) r2  starlevels({$^c$} 0.1 {$^b$} 0.05 {$^a$} 0.01) se tex label  title() 
eststo clear

erase "$Output_data\tmp.dta"


log close 

* --------------------------------------------------------------------------------------- *
						* Table A23 - Port-level corruption *
* --------------------------------------------------------------------------------------- *

cap log close
log using "$Results\Table_A23.log", replace

use "$Output_data\BCRT_baseline", clear

* Control for overall corruption
egen median_wbgi_cce_init 		= pctile(wbgi_cce_init), p(50)
g low_wbgi_cce_init 			= (wbgi_cce_init<median_wbgi_cce_init & wbgi_cce_init!=.)
replace low_wbgi_cce_init 		=. if wbgi_cce_init ==.

/* drop diamonds and tantalum for baseline */
drop if mainmineral == "diamond" | mainmineral == "tantalum"

g triple_dum_diff_q  			= main_lprice_mines*dum_diff_q
g triple2_dum_diff_q 			= main_lprice_hist0*dum_diff_q

g triple_diff_q  				= main_lprice_mines*diff_q
g triple2_diff_q 				= main_lprice_hist0*diff_q

g triple_wbgi_cce_init 			= main_lprice_mines*wbgi_cce_init
g triple2_wbgi_cce_init 		= main_lprice_hist0*wbgi_cce_init

* With continuous variable
eststo: reghdfe acled  main_lprice_mines triple_diff*						if sd_mines == 0 		, vce(cluster country_nb) absorb(cell it)
eststo: reghdfe acled  main_lprice_hist0 triple2_diff*    											, vce(cluster country_nb) absorb(cell it)

eststo: reghdfe acled  main_lprice_mines triple_diff*	triple_wb* 			if sd_mines == 0 		, vce(cluster country_nb) absorb(cell it)
eststo: reghdfe acled  main_lprice_hist0 triple2_diff*  triple2_wb*  								, vce(cluster country_nb) absorb(cell it)

* With dummy
eststo: reghdfe acled  main_lprice_mines triple_dum*						if sd_mines == 0 		, vce(cluster country_nb) absorb(cell it)
eststo: reghdfe acled  main_lprice_hist0 triple2_dum*    											, vce(cluster country_nb) absorb(cell it)

eststo: reghdfe acled  main_lprice_mines triple_dum*	triple_wb* 			if sd_mines == 0 		, vce(cluster country_nb) absorb(cell it)
eststo: reghdfe acled  main_lprice_hist0 triple2_dum*   triple2_wb*  								, vce(cluster country_nb) absorb(cell it)

set linesize 250
esttab, mtitles drop() b(%5.3f) se(%5.3f) compress r2 starlevels(c 0.1 b 0.05 a 0.01)  se 
esttab, mtitles drop() b(%5.3f) se(%5.3f) r2  starlevels({$^c$} 0.1 {$^b$} 0.05 {$^a$} 0.01) se tex label  title() 
eststo clear

log close  
	
* --------------------------------------------------------------------------------------- *
						* Table A25 - Conflict, mining and population *
* --------------------------------------------------------------------------------------- *


cap log close
log using "$Results\Table_A25.log", replace

use "$Output_data\BCRT_baseline", clear

/* drop diamonds and tantalum for baseline */
drop if mainmineral == "diamond" | mainmineral == "tantalum"

* Night time lights
eststo: my_reg2hdfespatial nlights_mean  main_lprice_mines  if sd_mines == 0						, timevar(it) panelvar(cell) lat(latitude) lon(longitude) distcutoff(500) lagcutoff(100000) 
eststo: my_reg2hdfespatial nlights_mean  main_lprice_hist0  										, timevar(it) panelvar(cell) lat(latitude) lon(longitude) distcutoff(500) lagcutoff(100000) 

* Population
g lpop1  = log(pop_gpw_sum)

eststo: my_reg2hdfespatial lpop1  main_lprice_mines  if sd_mines == 0								, timevar(it) panelvar(cell) lat(latitude) lon(longitude) distcutoff(500) lagcutoff(100000) 
eststo: my_reg2hdfespatial lpop1  main_lprice_hist0	 												, timevar(it) panelvar(cell) lat(latitude) lon(longitude) distcutoff(500) lagcutoff(100000) 

*Interpolated
bys gid : ipolate pop_gpw_sum year, g(pop_ipolate1)
g lpop1_ipolate  = log(pop_ipolate1)
eststo: my_reg2hdfespatial lpop1_ipolate  main_lprice_mines if sd_mines == 0						, timevar(it) panelvar(cell) lat(latitude) lon(longitude) distcutoff(500) lagcutoff(100000) 
eststo: my_reg2hdfespatial lpop1_ipolate  main_lprice_hist0											, timevar(it) panelvar(cell) lat(latitude) lon(longitude) distcutoff(500) lagcutoff(100000) 

*distance to capital city 
gen main_lprice_border 	= main_lprice_mines* lbdist1
gen main_lprice_capdist = main_lprice_mines* log(capdist)
*
gen main_lprice_hist_border 	= main_lprice_hist0* lbdist1
gen main_lprice_hist_capdist 	= main_lprice_hist0* log(capdist)

eststo: my_reg2hdfespatial acled  main_lprice_mines main_lprice_border main_lprice_capdist if sd_mines == 0	, timevar(it) panelvar(cell) lat(latitude) lon(longitude) distcutoff(500) lagcutoff(100000) 
eststo: my_reg2hdfespatial acled   main_lprice_hist0 main_lprice_hist_border  main_lprice_hist_capdist		, timevar(it) panelvar(cell) lat(latitude) lon(longitude) distcutoff(500) lagcutoff(100000) 

set linesize 250
esttab, mtitles drop() b(%5.3f) se(%5.3f) compress r2 starlevels(c 0.1 b 0.05 a 0.01)  se 
esttab, mtitles drop() b(%5.3f) se(%5.3f) r2  starlevels({$^c$} 0.1 {$^b$} 0.05 {$^a$} 0.01) se tex label  title() 
eststo clear

log close






