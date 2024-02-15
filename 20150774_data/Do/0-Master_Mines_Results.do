
	* ---------------------------------------------------------------------------------------------*
	* Master do-file for the results of "This mine is mine: how minerals fuel conflicts in Africa" *
	* ---------------------------------------------------------------------------------------------*
		
		
clear all
set mem 5g
set matsize 8000
set maxvar  8000

ssc install distinct, replace
ssc install geodist, replace
ssc install reghdfe, replace
ssc install tmpdir, replace
ssc install xtpqml, replace
ssc install tuples, replace

* cd directory here
global base "XXXXX"

* Global

global Output_data	"Data_Code_BCRT_AER\Data"
global Results		"Data_Code_BCRT_AER\results"
global Do_files     "Data_Code_BCRT_AER\Do"

cd "$base"

* To run before anything
do "$Do_files\my_spatial_2sls.do"

/* Results */

do $Do_files\Table_1.do							 	// Descriptive statistics
do $Do_files\Table_2.do								// Conflict and mineral prices (baseline)
do $Do_files\Tables_3_A26_to_A28.do					// Minerals and types of conflict events 
do $Do_files\Tables_4_A29_to_A31.do					// Ethnic homeland regressions
do $Do_files\Tables_5_A32_to_A35.do					// Battles won regressions and figures
do $Do_files\Tables_6_7_16_17_A36_to_A38.do			// Mines ownership and transparency
do $Do_files\Tables_8_to_11.do						// Appendix results up to Table 11
do $Do_files\Tables_12_13.do						// Appendix results on country-level heterogeneity
do $Do_files\Tables_14_15_A24.do					// Appendix results and web appendix on minerals' heterogeneity
do $Do_files\Quantifications.do						// Quantifications exercises discussed in section 4.6
do $Do_files\Tables_wappendix_others.do				// Other tables and Figures displayed in Web Appendix




