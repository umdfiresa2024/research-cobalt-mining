*----------------------------------------------------------------------------------------------------------------------------------------------------*
* This program performs the estimations of Tables 4, A.29, A.30, A.31 (online appendix) of "This mine is mine: how minerals fuel conflicts in Africa"
* This version: October 2016
*----------------------------------------------------------------------------------------------------------------------------------------------------*


* ------------------------------------------------------------------------------------ *
					*  Table 4 - Mines in ethnic homelands *
* ------------------------------------------------------------------------------------ *

cap log close
log using "$Results\Table_4.log", replace

use "$Output_data\BCRT_actor_ethnic", clear

egen actor_country 	= group(actor iso_1)
egen it 			= group(iso_1 year)
egen actor_group 	= group(actor)

gen acled_exclu_ethnic = nb_acled_exclu_ethnic>0

g interact_t0 		= price_ethnic*mines_t0 
g interact_t0_ni 	= price_ethnic_ni*mines_t0_ni 
g interact_t0_nh 	= price_ethnic_nh*mines_t0_nh

label var price_ethnic 		"ln price main mineral (homeland in country)"
label var interact_t0  		"ln price main mineral (homeland in country) $\times$ \# mines"
label var price_ethnic_ni 	"ln price main mineral (entire homeland)"
label var interact_t0_ni 	"ln price main mineral (entire  homeland) $\times$ \# mines"
label var price_ethnic_nh 	"ln price main mineral (in country outside homeland)"
label var interact_t0_nh 	"ln price main mineral (in country outside homeland) $\times$ \# mines"

* Baseline
eststo: reghdfe acled   			 price_ethnic mines_t0 interact_t0 if sd_mine_ethnic==0, absorb(actor_country year) vce(cluster actor_group)   
eststo: reghdfe acled   			 price_ethnic mines_t0 interact_t0 if sd_mine_ethnic==0, absorb(actor_country it) vce(cluster actor_group)   
* Excluding homeland
eststo: reghdfe acled_exclu_ethnic   price_ethnic mines_t0 interact_t0 if sd_mine_ethnic==0, absorb(actor_country year) vce(cluster actor_group)   
eststo: reghdfe acled_exclu_ethnic   price_ethnic mines_t0 interact_t0 if sd_mine_ethnic==0, absorb(actor_country it) vce(cluster actor_group)   
* Splitting the effect
eststo: reghdfe acled  				 price_ethnic mines_t0 interact_t0 price_ethnic_ni mines_t0_ni interact_t0_ni price_ethnic_nh mines_t0_nh interact_t0_nh if sd_mine_ethnic==0, absorb(actor_country year) vce(cluster actor_group)   
eststo: reghdfe acled_exclu_ethnic   price_ethnic mines_t0 interact_t0 price_ethnic_ni mines_t0_ni interact_t0_ni price_ethnic_nh mines_t0_nh interact_t0_nh if sd_mine_ethnic==0, absorb(actor_country year) vce(cluster actor_group)   

set linesize 250
esttab, mtitles drop(mines*) b(%5.3f) se(%5.3f) compress r2 starlevels(c 0.1 b 0.05 a 0.01)  se 
esttab, mtitles drop(mines*) b(%5.3f) se(%5.3f) r2  starlevels({$^c$} 0.1 {$^b$} 0.05 {$^a$} 0.01) se tex label  title(Table 4) 
eststo clear

log close

* ------------------------------------------------------------------------------------ *
			*  Table A29 to A31: Robustness on ethnic homeland specifications *
* ------------------------------------------------------------------------------------ *

cap log close
log using "$Results\Tables_A29_to_A31.log", replace

**************************
// Table A29 : Statistics
**************************

use "$Output_data\BCRT_actor_ethnic", clear
*
egen actor_country 	= group(actor iso_1)
distinct actor
distinct actor_country

foreach var in acled acled_exclu_ethnic acled_mine1 acled_mine0 nb_acled  mines_t0 mines_t0_ni mines_t0_nh{
use "$Output_data\BCRT_actor_ethnic", clear
*
gen acled_exclu_ethnic = nb_acled_exclu_ethnic>0

egen actor_country 	= group(actor iso_1)
distinct actor
distinct actor_country

g acled_mine1 = acled if mines_t0>0
g acled_mine0 = acled if mines_t0==0

collapse (count) N = `var' (mean) mean = `var' (median) median = `var' (sd) sd = `var'
g name = "`var'" 
save "$Results\stats_`var'", replace
}
foreach var in acled_nom acled_exclu_ethnic_nom{
use "$Output_data\BCRT_actor_ethnic_nomine", clear
*
gen acled_exclu_ethnic_nom = nb_acled_exclu_ethnic>0
rename acled acled_nom
collapse (count) N = `var' (mean) mean = `var' (median) median = `var' (sd) sd = `var'
g name = "`var'" 
save "$Results\stats_`var'", replace
}
use "$Results\stats_acled", clear
foreach var in acled_exclu_ethnic acled_mine1 acled_mine0 nb_acled  mines_t0 mines_t0_ni mines_t0_nh acled_nom acled_exclu_ethnic_nom{ 
append using "$Results\stats_`var'"
}
*
order name N mean sd median
save "$Results\Table_A29", replace
*
foreach var in acled acled_exclu_ethnic acled_mine1 acled_mine0 nb_acled  mines_t0 mines_t0_ni mines_t0_nh acled_nom acled_exclu_ethnic_nom{
erase "$Results\stats_`var'.dta"
}

**************************
// Table A30 : Price index
**************************

use "$Output_data\BCRT_actor_ethnic", clear

egen actor_country 	= group(actor iso_1)
egen it 			= group(iso_1 year)
egen actor_group 	= group(actor)

gen acled_exclu_ethnic = nb_acled_exclu_ethnic>0

g interact_t0 		= lprice_index*mines_t0_all
g interact_t0_ni 	= lprice_index_ni*mines_t0_all_ni 
g interact_t0_nh 	= lprice_index_nh*mines_t0_all_nh


label var lprice_index 		"ln price index (homeland in country)"
label var interact_t0  		"ln price index (homeland in country) $\times$ \# mines"
label var lprice_index_ni 	"ln price index (entire homeland)"
label var interact_t0_ni 	"ln price index (entire  homeland) $\times$ \# mines"
label var lprice_index_nh 	"ln price index (in country outside homeland)"
label var interact_t0_nh 	"ln price index (in country outside homeland) $\times$ \# mines"

* Baseline
eststo: reghdfe acled   			 lprice_index mines_t0 interact_t0 if sd_mine_ethnic==0, absorb(actor_country year) vce(cluster actor_group)   
eststo: reghdfe acled   			 lprice_index mines_t0 interact_t0 if sd_mine_ethnic==0, absorb(actor_country it) vce(cluster actor_group)  
* Excluding homeland
eststo: reghdfe acled_exclu_ethnic   lprice_index mines_t0 interact_t0 if sd_mine_ethnic==0, absorb(actor_country year) vce(cluster actor_group)   
eststo: reghdfe acled_exclu_ethnic   lprice_index mines_t0 interact_t0 if sd_mine_ethnic==0, absorb(actor_country it) vce(cluster actor_group)  
* Splitting the effect
eststo: reghdfe acled   			 lprice_index lprice_index_ni lprice_index_nh mines_t0 mines_t0_ni mines_t0_nh interact_t0 interact_t0_ni interact_t0_nh if sd_mine_ethnic==0, absorb(actor_country year) vce(cluster actor_group)   
eststo: reghdfe acled_exclu_ethnic   lprice_index lprice_index_ni lprice_index_nh mines_t0 mines_t0_ni mines_t0_nh interact_t0 interact_t0_ni interact_t0_nh if sd_mine_ethnic==0, absorb(actor_country year) vce(cluster actor_group)   

set linesize 250
esttab, mtitles drop(mines*) b(%5.3f) se(%5.3f) compress r2 starlevels(c 0.1 b 0.05 a 0.01)  se 
esttab, mtitles drop(mines*) b(%5.3f) se(%5.3f) r2  starlevels({$^c$} 0.1 {$^b$} 0.05 {$^a$} 0.01) se tex label  title(Table A30) 
eststo clear

*********************************
// Table A31 : Excl. mining areas
*********************************

use "$Output_data\BCRT_actor_ethnic_nomine", clear

egen actor_country 	= group(actor iso_1)
egen it 			= group(iso_1 year)
egen actor_group 	= group(actor)

gen acled_exclu_ethnic = nb_acled_exclu_ethnic>0

g interact_t0 		= price_ethnic*mines_t0
g interact_t0_ni	= price_ethnic_ni*mines_t0_ni 
g interact_t0_nh 	= price_ethnic_nh*mines_t0_nh

label var price_ethnic 		"ln price main mineral (homeland in country)"
label var interact_t0  		"ln price main mineral (homeland in country) $\times$ \# mines"
label var price_ethnic_ni 	"ln price main mineral (entire homeland)"
label var interact_t0_ni 	"ln price main mineral (entire  homeland) $\times$ \# mines"
label var price_ethnic_nh 	"ln price main mineral (in country outside homeland)"
label var interact_t0_nh 	"ln price main mineral (in country outside homeland) $\times$ \# mines"

* Baseline
eststo: reghdfe acled   			price_ethnic mines_t0 interact_t0 if sd_mine_ethnic==0, absorb(actor_country year) vce(cluster actor_group)   
eststo: reghdfe acled   			price_ethnic mines_t0 interact_t0 if sd_mine_ethnic==0, absorb(actor_country it) vce(cluster actor_group)   
* Excluding homeland
eststo: reghdfe acled_exclu_ethnic  price_ethnic mines_t0 interact_t0 if sd_mine_ethnic==0, absorb(actor_country year) vce(cluster actor_group)   
eststo: reghdfe acled_exclu_ethnic  price_ethnic mines_t0 interact_t0 if sd_mine_ethnic==0, absorb(actor_country it) vce(cluster actor_group)   
* Splitting the effect
eststo: reghdfe acled  				price_ethnic mines_t0 interact_t0 price_ethnic_ni mines_t0_ni interact_t0_ni price_ethnic_nh mines_t0_nh interact_t0_nh if sd_mine_ethnic==0, absorb(actor_country year) vce(cluster actor_group)   
eststo: reghdfe acled_exclu_ethnic  price_ethnic mines_t0 interact_t0 price_ethnic_ni mines_t0_ni interact_t0_ni price_ethnic_nh mines_t0_nh interact_t0_nh if sd_mine_ethnic==0, absorb(actor_country year) vce(cluster actor_group)   

set linesize 250
esttab, mtitles drop(mines*) b(%5.3f) se(%5.3f) compress r2 starlevels(c 0.1 b 0.05 a 0.01)  se 
esttab, mtitles drop(mines*) b(%5.3f) se(%5.3f) r2  starlevels({$^c$} 0.1 {$^b$} 0.05 {$^a$} 0.01) se tex label  title(Table A31) 
eststo clear

log close
