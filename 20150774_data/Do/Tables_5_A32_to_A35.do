*--------------------------------------------------------------------------------------------------------------------------------------------------------------*
* This program performs the estimations of Tables 5, Figure 2, and A.32 to A.35 (online appendix) of "This mine is mine: how minerals fuel conflicts in Africa"
* This version: October 2016
*--------------------------------------------------------------------------------------------------------------------------------------------------------------*

* ------------------------------------------------------------------------------------ *
			*  Table 5 and Figure 2 - Feasibility and the diffusion of war *
* ------------------------------------------------------------------------------------ *

cap log close
log using "$Results\Table_5.log", replace

// Table 5

use "$Output_data\BCRT_rebel", clear

sort id year 

sort id year 
eststo: reghdfe acled nb_battle_all 																		if l.acled == 0 & ldistance_battle != ., vce(cluster actor_g) absorb(id it)
sort id year 
eststo: reghdfe acled battle_a battle_m  																	if l.acled == 0 & ldistance_battle != ., vce(cluster actor_g) absorb(id it)
lincom battle_m - battle_a
sort id year 	
eststo: reghdfe acled nb_battle_a nb_battle_m  																if l.acled == 0 & ldistance_battle != ., vce(cluster actor_g) absorb(id it)
lincom nb_battle_m - nb_battle_a
sort id year 	
eststo: reghdfe acled nb_battle_a nb_battle_m  nb_battle_an nb_battle_mn 									if l.acled == 0 & ldistance_battle != ., vce(cluster actor_g) absorb(id it)
lincom nb_battle_m  - nb_battle_a
lincom nb_battle_mn - nb_battle_an

sort id year
eststo: reghdfe acled nb_battle_a nb_battle_m nb_battle_a_l1 nb_battle_m_l1 								if l.acled == 0 & ldistance_battle != ., vce(cluster actor_g) absorb(id it)
lincom nb_battle_m    - nb_battle_a 
lincom nb_battle_m_l1 - nb_battle_a_l1
sort id year
eststo: reghdfe acled nb_battle_a nb_battle_m nb_battle_a_l1 nb_battle_m_l1 nb_battle_a_l2 nb_battle_m_l2  	if l.acled == 0 & ldistance_battle != ., vce(cluster actor_g) absorb(id it)
lincom nb_battle_m    - nb_battle_a
lincom nb_battle_m_l1 - nb_battle_a_l1
lincom nb_battle_m_l2 - nb_battle_a_l2

sort id year 
eststo: reghdfe acled nb_battle_all ldistance_battle nb_battle_all_dist 									if l.acled == 0 & ldistance_battle != ., vce(cluster actor_g) absorb(id it)
sort id year 
eststo: reghdfe acled nb_battle_a nb_battle_m ldistance_battle nb_battle_a_dist nb_battle_m_dist 			if l.acled == 0 & ldistance_battle != ., vce(cluster actor_g) absorb(id it)

// Figure 2

*  Numbers correspond to 100*ln(x) with x in [100,1500]*
*  Ex: log(100km) = 4.6 

foreach number in 460 529 570 599 621 639 655 668 680 690 700 709 717 724 731{
	lincom nb_battle_a+nb_battle_a_dist*`number'/100
	g beta_m0_`number' = r(estimate)
	g se_m0_`number'   = r(se)
	lincom nb_battle_m+nb_battle_m_dist*`number'/100
	g beta_m1_`number' = r(estimate)
	g se_m1_`number'   = r(se)
	}
	keep if _n == 1
	collapse (mean) beta_m0_* beta_m1_* se_m0_* se_m1_*

	foreach type in m0 m1{ 
	rename beta_`type'_460 beta_`type'_1
	rename beta_`type'_529 beta_`type'_2
	rename beta_`type'_570 beta_`type'_3
	rename beta_`type'_599 beta_`type'_4
	rename beta_`type'_621 beta_`type'_5
	rename beta_`type'_639 beta_`type'_6
	rename beta_`type'_655 beta_`type'_7
	rename beta_`type'_668 beta_`type'_8
	rename beta_`type'_680 beta_`type'_9
	rename beta_`type'_690 beta_`type'_10
	rename beta_`type'_700 beta_`type'_11
	rename beta_`type'_709 beta_`type'_12
	rename beta_`type'_717 beta_`type'_13
	rename beta_`type'_724 beta_`type'_14
	rename beta_`type'_731 beta_`type'_15
	*
	rename se_`type'_460 se_`type'_1
	rename se_`type'_529 se_`type'_2
	rename se_`type'_570 se_`type'_3
	rename se_`type'_599 se_`type'_4
	rename se_`type'_621 se_`type'_5
	rename se_`type'_639 se_`type'_6
	rename se_`type'_655 se_`type'_7
	rename se_`type'_668 se_`type'_8
	rename se_`type'_680 se_`type'_9
	rename se_`type'_690 se_`type'_10
	rename se_`type'_700 se_`type'_11
	rename se_`type'_709 se_`type'_12
	rename se_`type'_717 se_`type'_13
	rename se_`type'_724 se_`type'_14
	rename se_`type'_731 se_`type'_15
}
g obs = 1
reshape long beta_m0_ beta_m1_ se_m0_ se_m1_, i(obs) j(distance_cat)

foreach var in beta_m0 beta_m1 se_m0 se_m1{
	rename `var'_ `var'
}
g beta_m0_min = beta_m0-1.96*se_m0
g beta_m0_max = beta_m0+1.96*se_m0
*
g beta_m1_min = beta_m1-1.96*se_m1
g beta_m1_max = beta_m1+1.96*se_m1

g zero     = 0
local zero = 0 

global bandwidth  = 0.66
gen    beta_bench = 0
local  beta_bench = beta_bench

drop if distance_cat>10

label define distance_cat 1 "100" 2 "200" 3 "300" 4 "400" 5 "500" 6 "600" 7 "700" 8 "800" 9 "900" 10 "1000"
label values distance_cat distance_cat
label list

twoway rarea beta_m0_min beta_m0_max distance_cat, fintensity(inten30) bsty(ci) sort  xlabel(1 2 3 4 5 6 7 8 9 10,  valuelabel)  yscale(range(0.00 0.10)) ylabel(0 0.05 0.10,  valuelabel) ///
|| scatter beta_m0 distance_cat, scheme(s2color) c(l) xtitle("Distance to previous year's battles (km)") ///
|| line beta_bench distance_cat, color(gs5) ///
title("Effect of # battles won in t-1 on conflict outbreak in t", pos(11) ring(0) size(medium)) legend(off) bgcolor(white) graphregion(color(white)) ysize(4) xsize(4) scale(0.8)
graph export $Results\Figure_2a.eps, as(eps) replace
*
twoway rarea beta_m1_min beta_m1_max distance_cat,  fintensity(inten30) bsty(ci) sort  xlabel(1 2 3 4 5 6 7 8 9 10,  valuelabel) yscale(range(0.00 0.20)) ylabel(0 0.05 0.10 0.15 0.20 0.25 0.30,  valuelabel) ///
|| scatter beta_m1 distance_cat, scheme(s2color) c(l) xtitle("Distance to previous year's battles (km)") ///
|| line beta_bench distance_cat, color(gs5) ///
title("Effect of # battles won in t-1 on conflict outbreak in t", pos(11) ring(0) size(medium)) bgcolor(white) graphregion(color(white))  legend(off)  ysize(4) xsize(4) scale(0.8)
graph export $Results\Figure_2b.eps, as(eps) replace
*
set linesize 250
esttab, mtitles drop() b(%5.3f) se(%5.3f) compress r2 starlevels(c 0.1 b 0.05 a 0.01)  se 
esttab, mtitles drop() b(%5.3f) se(%5.3f) r2  starlevels({$^c$} 0.1 {$^b$} 0.05 {$^a$} 0.01) se tex label  title(Table 5) 
eststo clear

/* QUANTIF */

use "$Output_data\BCRT_rebel.dta", clear
g test = 1 
collapse (sum) nb_acled nb_gid=test, by(actor_country year)
sum nb_gid 
scalar mean_nb_gid   = r(mean) 
sum nb_acled 
scalar mean_nb_acled = r(mean) 


******************************************
di "quantif"
di 0.040*mean_nb_gid*100/mean_nb_acled	 
******************************************

log close

* ------------------------------------------------------------------------------------ *
					*  Table A32 to A35: Robustness on battles won *
* ------------------------------------------------------------------------------------ *

cap log close
log using "$Results\Table_A32_to_A35.log", replace


**************************
// Table A32 : Statistics
**************************

use "$Output_data\BCRT_rebel", clear

keep if ldistance_battle!=.
distinct actor actor_country
preserve

*how many countries per actor on average? 
collapse year, by(actor iso_1)
g nb_country = 1
collapse (sum) nb_country, by(actor)
tab nb_country
sum nb_country
restore 

foreach var in acled nb_acled nb_battle_all battle_a battle_m nb_battle_a nb_battle_m nb_battle_an nb_battle_mn distance_battle{
	use "$Output_data\BCRT_rebel", clear
	
	g distance_battle = exp(ldistance_battle)
	keep if distance_battle!=.

		foreach var2 in nb_battle_all nb_battle_a nb_battle_m nb_battle_an nb_battle_mn{
		replace `var2' = exp(`var2')-1
		}

	collapse (count) N = `var' (mean) mean = `var' (median) median = `var' (sd) sd = `var'
	g name = "`var'" 
	save "$Results\stats_`var'", replace
}

use "$Results\stats_acled", clear
foreach var in nb_acled nb_battle_all battle_a battle_m nb_battle_a nb_battle_m nb_battle_an nb_battle_mn distance_battle{
append using "$Results\stats_`var'"
}
*
order name N mean sd median
save "$Results\Table_A32", replace
*
foreach var in acled nb_acled nb_battle_all battle_a battle_m nb_battle_a nb_battle_m nb_battle_an nb_battle_mn distance_battle{
erase "$Results\stats_`var'.dta"
}

**************************
// Table A33 : Conley S.E. 
**************************

use "$Output_data\BCRT_baseline", clear
collapse (max) latitude longitude, by(gid)
save "$Output_data\temp0", replace

use "$Output_data\BCRT_rebel", clear
sort  gid 
merge gid using "$Output_data\temp0", nokeep
tab  _merge
drop _merge

erase "$Output_data\temp0.dta"

sort id year 
*
sort id year 
eststo: my_reg2hdfespatial acled nb_battle_all 																			if l.acled == 0 & ldistance_battle != ., timevar(it) panelvar(id) lat(latitude) lon(longitude) distcutoff(500) lagcutoff(100000)  
sort id year 
eststo: my_reg2hdfespatial acled battle_a battle_m  																	if l.acled == 0 & ldistance_battle != ., timevar(it) panelvar(id) lat(latitude) lon(longitude) distcutoff(500) lagcutoff(100000)
lincom battle_m - battle_a
sort id year 	
eststo: my_reg2hdfespatial acled nb_battle_a nb_battle_m  																if l.acled == 0 & ldistance_battle != . , timevar(it) panelvar(id) lat(latitude) lon(longitude) distcutoff(500) lagcutoff(100000)
lincom nb_battle_m - nb_battle_a
sort id year 	
eststo: my_reg2hdfespatial acled nb_battle_a nb_battle_m  nb_battle_an nb_battle_mn 									if l.acled == 0 & ldistance_battle != . , timevar(it) panelvar(id) lat(latitude) lon(longitude) distcutoff(500) lagcutoff(100000)
lincom nb_battle_m - nb_battle_a
lincom nb_battle_mn - nb_battle_an
*
sort id year
eststo: my_reg2hdfespatial acled nb_battle_a nb_battle_m nb_battle_a_l1 nb_battle_m_l1 									if l.acled == 0 & ldistance_battle != ., timevar(it) panelvar(id) lat(latitude) lon(longitude) distcutoff(500) lagcutoff(100000)
lincom nb_battle_m - nb_battle_a
lincom nb_battle_m_l1 - nb_battle_a_l1
sort id year
eststo: my_reg2hdfespatial acled nb_battle_a nb_battle_m nb_battle_a_l1 nb_battle_m_l1 nb_battle_a_l2 nb_battle_m_l2  	if l.acled == 0 & ldistance_battle != ., timevar(it) panelvar(id) lat(latitude) lon(longitude) distcutoff(500) lagcutoff(100000)
lincom nb_battle_m - nb_battle_a
lincom nb_battle_m_l1 - nb_battle_a_l1
lincom nb_battle_m_l2 - nb_battle_a_l2
*
sort id year 
eststo: my_reg2hdfespatial acled nb_battle_all 	ldistance_battle nb_battle_all_dist 									if l.acled == 0 & ldistance_battle != ., timevar(it) panelvar(id) lat(latitude) lon(longitude) distcutoff(500) lagcutoff(100000)
sort id year 
eststo: my_reg2hdfespatial acled nb_battle_a nb_battle_m ldistance_battle nb_battle_a_dist nb_battle_m_dist 			if l.acled == 0 & ldistance_battle != ., timevar(it) panelvar(id) lat(latitude) lon(longitude) distcutoff(500) lagcutoff(100000)

set linesize 250
esttab, mtitles drop() b(%5.3f) se(%5.3f) compress r2 starlevels(c 0.1 b 0.05 a 0.01)  se 
esttab, mtitles drop() b(%5.3f) se(%5.3f) r2  starlevels({$^c$} 0.1 {$^b$} 0.05 {$^a$} 0.01) se tex label  title(Table A33) 
eststo clear

**********************************
// Table A34 : Two way clustering
**********************************

use "$Output_data\BCRT_rebel", clear

egen actor_cell = group(actor gid)

sort id year 
*
sort id year 
eststo: reghdfe acled nb_battle_all 																		if l.acled == 0 & ldistance_battle != ., vce(cluster actor_g gid) absorb(id it)
sort id year 
eststo: reghdfe acled battle_a battle_m  																	if l.acled == 0 & ldistance_battle != . , vce(cluster actor_g gid) absorb(id it)
lincom battle_m - battle_a
sort id year 	
eststo: reghdfe acled nb_battle_a nb_battle_m  																if l.acled == 0 & ldistance_battle != . , vce(cluster actor_g gid) absorb(id it)
lincom nb_battle_m - nb_battle_a
sort id year 	
eststo: reghdfe acled nb_battle_a nb_battle_m  nb_battle_an nb_battle_mn 									if l.acled == 0 & ldistance_battle != . , vce(cluster actor_g gid) absorb(id it)
lincom nb_battle_m - nb_battle_a
lincom nb_battle_mn - nb_battle_an
*
sort id year
eststo: reghdfe acled nb_battle_a nb_battle_m nb_battle_a_l1 nb_battle_m_l1 								if l.acled == 0 & ldistance_battle != ., vce(cluster actor_g gid) absorb(id it)
lincom nb_battle_m - nb_battle_a
lincom nb_battle_m_l1 - nb_battle_a_l1
sort id year
eststo: reghdfe acled nb_battle_a nb_battle_m nb_battle_a_l1 nb_battle_m_l1 nb_battle_a_l2 nb_battle_m_l2  	if l.acled == 0 & ldistance_battle != ., vce(cluster actor_g gid) absorb(id it)
lincom nb_battle_m - nb_battle_a
lincom nb_battle_m_l1 - nb_battle_a_l1
lincom nb_battle_m_l2 - nb_battle_a_l2
*
sort id year 
eststo: reghdfe acled nb_battle_all ldistance_battle nb_battle_all_dist 									if l.acled == 0 & ldistance_battle != ., vce(cluster actor_g gid) absorb(id it)
sort id year 
eststo: reghdfe acled nb_battle_a nb_battle_m ldistance_battle nb_battle_a_dist nb_battle_m_dist 			if l.acled == 0 & ldistance_battle != ., vce(cluster actor_g gid) absorb(id it)
*
set linesize 250
esttab, mtitles drop() b(%5.3f) se(%5.3f) compress r2 starlevels(c 0.1 b 0.05 a 0.01)  se 
esttab, mtitles drop() b(%5.3f) se(%5.3f) r2  starlevels({$^c$} 0.1 {$^b$} 0.05 {$^a$} 0.01) se tex label  title(Table A34) 
eststo clear

**********************************
// Table A35 : Battles only on RHS
**********************************

use "$Output_data\BCRT_rebel", clear

sort id year 
*
sort id year 
eststo: reghdfe acled_battles nb_battle_all 																		if l.acled == 0 & ldistance_battle != ., vce(cluster actor_g) absorb(id it)
sort id year 
eststo: reghdfe acled_battles battle_a battle_m  																	if l.acled == 0 & ldistance_battle != . , vce(cluster actor_g) absorb(id it)
lincom battle_m - battle_a
sort id year 	
eststo: reghdfe acled_battles nb_battle_a nb_battle_m  																if l.acled == 0 & ldistance_battle != . , vce(cluster actor_g) absorb(id it)
lincom nb_battle_m - nb_battle_a
sort id year 	
eststo: reghdfe acled_battles nb_battle_a nb_battle_m  nb_battle_an nb_battle_mn 									if l.acled == 0 & ldistance_battle != . , vce(cluster actor_g) absorb(id it)
lincom nb_battle_m - nb_battle_a
lincom nb_battle_mn - nb_battle_an
*
sort id year
eststo: reghdfe acled_battles nb_battle_a nb_battle_m nb_battle_a_l1 nb_battle_m_l1 								if l.acled == 0 & ldistance_battle != ., vce(cluster actor_g) absorb(id it)
lincom nb_battle_m - nb_battle_a
lincom nb_battle_m_l1 - nb_battle_a_l1
sort id year
eststo: reghdfe acled_battles nb_battle_a nb_battle_m nb_battle_a_l1 nb_battle_m_l1 nb_battle_a_l2 nb_battle_m_l2  	if l.acled == 0 & ldistance_battle != ., vce(cluster actor_g) absorb(id it)
lincom nb_battle_m - nb_battle_a
lincom nb_battle_m_l1 - nb_battle_a_l1
lincom nb_battle_m_l2 - nb_battle_a_l2
*
sort id year 
eststo: reghdfe acled_battles nb_battle_all ldistance_battle nb_battle_all_dist 									if l.acled == 0 & ldistance_battle != ., vce(cluster actor_g) absorb(id it)
sort id year 
eststo: reghdfe acled_battles nb_battle_a nb_battle_m ldistance_battle nb_battle_a_dist nb_battle_m_dist 			if l.acled == 0 & ldistance_battle != ., vce(cluster actor_g) absorb(id it)

set linesize 250
esttab, mtitles drop() b(%5.3f) se(%5.3f) compress r2 starlevels(c 0.1 b 0.05 a 0.01)  se 
esttab, mtitles drop() b(%5.3f) se(%5.3f) r2  starlevels({$^c$} 0.1 {$^b$} 0.05 {$^a$} 0.01) se tex label  title(Table A35) 
eststo clear

log close
