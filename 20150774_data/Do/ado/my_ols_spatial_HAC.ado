 
*! S. HSIANG 6/2010: PROGRAM TO ESTIMATE SPATIAL HAC ERRORS FOR OLS REGRESSION MODEL [BETA VERSION]

/*-----------------------------------------------------------------------------

S. HSIANG
SHSIANG@BERKELEY.EDU

ORIGINAL: 6/10
LAST UPDATED: 4/29/2013

 ------------------------------------------------------------------------------

 [BETA VERSION]

 This may contain errors. Please notify me of any errors you find.
 
 ------------------------------------------------------------------------------

 Syntax:
 
 ols_spatial_HAC Yvar Xvarlist, lat(latvar) lon(lonvar) Timevar(tvar) Panelvar(pvar) [DISTcutoff(#) LAGcutoff(#) bartlett DISPlay star dropvar]

 Function calculates non-parametric (GMM) spatial and autocorrelation 
 structure using a panel data set.  Spatial correlation is estimated for all
 observations within a given period.  Autocorrelation is estimated for a
 given individual over multiple periods up to some lag length. Var-Covar
 matrix is robust to heteroskedasticity.
 
 A variable equal to 1 is required to estimate a constant term.
 
 Example commands:
 
 ols_spatial_HAC dep indep1 indep2 const, lat(C1) lon(C2) t(year) p(id) dist(300) lag(3) bartlett disp

 ols_spatial_HAC dep indep*, lat(C1) lon(C2) timevar(year) panelvar(id) dist(100) lag(2) star dropvar

 ------------------------------------------------------------------------------
 
 Requred arguments: 
 
 Yvar: dependent variable  
 Xvarlist: independnet variables (INCLUDE constant as column)
 latvar: variable containing latitude in DEGREES of each obs
 lonvar: same, but longitude
 tvar: varible containing time variable
 pvar: variable containing panel variable (must be numeric, see "encode")
 
 ------------------------------------------------------------------------------
 
 Optional arguments:
 
 distcutoff(#): {abbrev dist(#)} describes the distance cutoff in KILOMETERS for the spatial kernal (the distance at which spatial correlation is assumed to vanish). Default is 1 KM.
 
 lagcutoff(#): {abbrev lag(#)} describes the maximum number of temporal periods for the linear Bartlett window that weights serial correlation across time periods (the distance at which serial correlation is assumed to vanish). Default is 0 PERIODS (no serial correlation). {Note, Greene recommends at least T^0.25}  
 
 ------------------------------------------------------------------------------
 
 Options:
 
 bartlett: use a linear bartlett window for spatial correlations, instead of a uniform kernal
 
 display: {abbrev disp} display a table with estimated coeff and SE & t-stat using OLS, adjusting for spatial correlation and adjusting for both spatial and serial correlation. Can be used with star option. Ex:
 
 -----------------------------------------------
     Variable |   OLS      spatial    spatHAC   
 -------------+---------------------------------
       indep1 |    0.568      0.568      0.568  
              |    0.198      0.206      0.240  
              |    2.876      2.761      2.369  
        const |    6.415      6.415      6.415  
              |    0.790      1.176      1.340  
              |    8.119      5.454      4.786  
 -----------------------------------------------
                                  legend: b/se/t
 

 star: same as display, but uses stars to denote significance and does not show SE & t-stat. Can be used with display option. Ex:
 
 -----------------------------------------------------
     Variable |    OLS        spatial      spatHAC    
 -------------+---------------------------------------
       indep1 |   0.568***     0.568***     0.568**   
        const |   6.415***     6.415***     6.415***  
 -----------------------------------------------------
                   legend: * p<.1; ** p<.05; *** p<.01
                   
                   
 dropvar: Drops variables that Stata would drop due to collinearity. This requires that an additiona regression is run, so it slows the code down. For large datasets, if this function is called many times, it may be faster to ensure that colinear variables are dropped in advance rather than using the option dropvar. If Stata returns "estimates post: matrix has missing values", than including the option dropvar may solve the problem. (This option written by Kyle Meng).
 
 ------------------------------------------------------------------------------
 
 Implementation:
 
 The default kernal used to weight spatial correlations is a uniform kernal that
 discontinously falls from 1 to zero at length locCutoff in all directions (it is isotropic). This is the kernal recommented by Conley (2008). If the option "bartlett" is selected, a conical kernal that decays linearly with distance in all directions is used instead.
 
 Serial correlation bewteen observations of the same individual over multiple periods seperated by lag L are weighted by 

       w(L) = 1 - L/(lagCutoff+1)
       
 ------------------------------------------------------------------------------

 Notes:

 Location arguments should specify lat-lon units in DEGREES, however
 distcutoff should be specified in KILOMETERS. 

 distcutoff must exceed zero. CAREFUL: do not supply
 coordinate locations in modulo(360) if observations straddle the
 zero-meridian or in modulo(180) if they straddle the date-line. 

 Distances are computed by approximating the planet's surface as a plane
 around each observation.  This allows for large changes in LAT to be
 present in the dataset (it corrects for changes in the length of
 LON-degrees associated with changes in LAT). However, it does not account
 for the local curvature of the surface around a point, so distances will
 be slightly lower than true geodesics. This should not be a concern so
 long as locCutoff is < O(~2000km), probably.

 Each time-series for an individual observation in the panel is treated
 with Heteroskedastic and Autocorrelation Standard Errors. If lagcutoff =
 0, than this estimate is equivelent to White standard errors (with spatial correlations 
 accounted for). If lagcutoff = infinity, than this treatment is
 equivelent to the "cluster" command in Stata at the panel variable level.

 This script stores estimation results in standard Stata formats, so most "ereturn" commands should work properly.  It is also compatible with "outreg2," although I have not tested other programs.

 ------------------------------------------------------------------------------

 References:

      TG Conley "GMM Estimation with Cross Sectional Dependence" 
      Journal of Econometrics, Vol. 92 Issue 1(September 1999) 1-45
      http://www.elsevier.com/homepage/sae/econworld/econbase/econom/frame.htm
      
      and 

      Conley "Spatial Econometrics" New Palgrave Dictionary of Economics,
      2nd Edition, 2008

      and

      Greene, Econometric Analysis, p. 546

	  and

	  Modified from scripts written by Ruben Lebowski and Wolfram Schlenker and Jean-Pierre Dube and Solomon Hsiang
 
 -----------------------------------------------------------------------------*/
cap program drop my_ols_spatial_HAC
program my_ols_spatial_HAC, eclass byable(recall)
//version 9.2
version 11
syntax varlist(ts fv min=2) [if] [in], ///
				lat(varname numeric) lon(varname numeric) ///
				Timevar(varname numeric) Panelvar(varname numeric) [LAGcutoff(integer 0) DISTcutoff(real 1) ///
				DISPlay star bartlett dropvar]
				
/*--------PARSING COMMANDS AND SETUP-------*/

capture drop touse
marksample touse				// indicator for inclusion in the sample
gen touse = `touse'

//parsing variables
loc Y = word("`varlist'",1)		

loc listing "`varlist'"



loc X ""
scalar k_variables = 0

//make sure that Y is not included in the other_var list
foreach i of loc listing {
	if "`i'" ~= "`Y'"{
		loc X "`X' `i'"
		scalar k_variables = k_variables + 1 // # indep variables
		
	}
}

//Kyle Meng's code to drop omitted variables that Stata would drop due to collinearity

if "`dropvar'" == "dropvar"{
	
	quietly reg `Y' `X' if `touse', nocons
	
	mat omittedMat=e(b)
	local newVarList=""
	local i=1
	scalar k_variables = 0 //replace the old k if this option is selected
	
	foreach var of varlist `X'{
		if omittedMat[1,`i']!=0{
			loc newVarList "`newVarList' `var'"
			scalar k_variables = k_variables + 1
		}
		local i=`i'+1
	}
	
	loc X "`newVarList'"
}

//generating a function of the included obs
quietly count if `touse'		
scalar n = r(N)					// # obs
scalar n_obs = r(N)

/*--------FIRST DO OLS, STORE RESULTS-------*/


quietly: reg `Y' `X' if `touse', nocons
estimates store OLS

//est tab OLS, stats(N r2)

/*--------SECOND, IMPORT ALL VALUES INTO MATA-------*/

mata{

Y_var = st_local("Y") //importing variable assignments to mata
X_var = st_local("X")
lat_var = st_local("lat")
lon_var = st_local("lon")
time_var = st_local("timevar")
panel_var = st_local("panelvar")

//NOTE: values are all imported as "views" instead of being copied and pasted as Mata data because it is faster, however none of the matrices are changed in any way, so it should not permanently affect the data. 

st_view(Y=.,.,tokens(Y_var),"touse") //importing variables vectors to mata
st_view(X=.,.,tokens(X_var),"touse")
st_view(lat=.,.,tokens(lat_var),"touse")
st_view(lon=.,.,tokens(lon_var),"touse")
st_view(time=.,.,tokens(time_var),"touse")
st_view(panel=.,.,tokens(panel_var),"touse")

k_variables = st_numscalar("k_variables")				//importing other parameters
n = st_numscalar("n")
b = st_matrix("e(b)")				// (estimated coefficients, row vector)
lag_var = st_local("lagcutoff")
lag_cutoff = strtoreal(lag_var)
dist_var = st_local("distcutoff")
dist_cutoff = strtoreal(dist_var)

XeeX = J(k_variables, k_variables, 0) 				//set variance-covariance matrix equal to zeros


/*--------THIRD, CORRECT VCE FOR SPATIAL CORR-------*/

timeUnique = uniqrows(time)
Ntime = rows(timeUnique) 		// # of obs. periods

for (ti = 1; ti <= Ntime; ti++){
	
	

	// 1 if in year ti, 0 otherwise:

	rows_ti = time:==timeUnique[ti,1] 	

	//get subsets of variables for time ti (without changing original matrix)
	
	Y1 = select(Y, rows_ti)
	X1 = select(X, rows_ti)
	lat1 = select(lat, rows_ti)
	lon1 = select(lon, rows_ti)
	e1 = Y1 - X1*b'
	
	n1 = length(Y1) 			// # obs for period ti
	
	//loop over all observations in period ti

	for (i = 1; i <=n1; i++){
		

		//----------------------------------------------------------------
        // step a: get non-parametric weight
	
	    //This is a Euclidean distance scale IN KILOMETERS specific to i
        
		lon_scale = cos(lat1[i,1]*pi()/180)*111 
		lat_scale = 111
		

		// Distance scales lat and lon degrees differently depending on
        // latitude.  The distance here assumes a distortion of Euclidean
        // space around the location of 'i' that is approximately correct for 
        // displacements around the location of 'i'
        //
        //	Note: 	1 deg lat = 111 km
        // 			1 deg lon = 111 km * cos(lat)
		
		distance_i = ((lat_scale*(lat1[i,1]:-lat1)):^2 + /// 	
					  (lon_scale*(lon1[i,1]:-lon1)):^2):^0.5


		
		// this sets all observations beyon dist_cutoff to zero, and weights all nearby observations equally [this kernal is isotropic]
		
		window_i = distance_i :<= dist_cutoff

		//----------------------------------------------------------------
        // adjustment for the weights if a "bartlett" kernal is selected as an option
  
		if ("`bartlett'"=="bartlett"){
		
			// this weights observations as a linear function of distance
			// that is zero at the cutoff distance
			
			weight_i = 1 :- distance_i:/dist_cutoff
			
			window_i = window_i:*weight_i
		}

 
        //----------------------------------------------------------------
        // step b: construct X'e'eX for the given observation
 
 		XeeXh = ((X1[i,.]'*J(1,n1,1)*e1[i,1]):*(J(k_variables,1,1)*e1':*window_i'))*X1

		//add each new k x k matrix onto the existing matrix (will be symmetric)
	
		XeeX = XeeX + XeeXh 	
	
	} //i
} // ti



// -----------------------------------------------------------------
// generate the VCE for only cross-sectional spatial correlation, 
// return it for comparison

invXX = luinv(X'*X) * n

XeeX_spatial = XeeX / n

V = invXX * XeeX_spatial * invXX / n

// Ensures that the matrix is symmetric 
// in theory, it should be already, but it may not be due to rounding errors for large datasets
V = (V+V')/2 

st_matrix("V_spatial", V)

} // mata


//------------------------------------------------------------------
// storing old statistics about the estimate so postestimation can be used

matrix beta = e(b)
scalar r2_old = e(r2)
scalar df_m_old = e(df_m)
scalar df_r_old = e(df_r)
scalar rmse_old = e(rmse)
scalar mss_old = e(mss)
scalar rss_old = e(rss)
scalar r2_a_old = e(r2_a)

// the row and column names of the new VCE must match the vector b

matrix colnames V_spatial = `X'
matrix rownames V_spatial = `X'
  
// this sets the new estimates as the most recent model

ereturn post beta V_spatial, esample(`touse')

// then filling back in all the parameters for postestimation

ereturn local cmd = "ols_spatial"

ereturn scalar N = n_obs

ereturn scalar r2 = r2_old
ereturn scalar df_m = df_m_old
ereturn scalar df_r = df_r_old
ereturn scalar rmse = rmse_old
ereturn scalar mss = mss_old
ereturn scalar rss = rss_old
ereturn scalar r2_a = r2_a_old

ereturn local title = "Linear regression"
ereturn local depvar = "`Y'"
ereturn local predict = "regres_p"
ereturn local model = "ols"
ereturn local estat_cmd = "regress_estat"

//storing these estimates for comparison to OLS and the HAC estimates

estimates store spatial



/*--------FOURTH, CORRECT VCE FOR SERIAL CORR-------*/

mata{

panelUnique = uniqrows(panel)
Npanel = rows(panelUnique) 		// # of panels

for (pi = 1; pi <= Npanel; pi++){
	
	// 1 if in panel pi, 0 otherwise:

	rows_pi = panel:==panelUnique[pi,1] 	

	//get subsets of variables for panel pi (without changing original matrix)
	
	Y1 = select(Y, rows_pi)
	X1 = select(X, rows_pi)
	time1 = select(time, rows_pi)
	e1 = Y1 - X1*b'

	n1 = length(Y1) 			// # obs for panel pi
	
	//loop over all observations in panel pi

	for (t = 1; t <=n1; t++){

   		// ----------------------------------------------------------------
        // step a: get non-parametric weight
        
        // this is the weight for Newey-West with a Bartlett kernal
* original weight in Solomon's code       
*        weight = (1:-abs(time1[t,1] :- time1))/(lag_cutoff+1)
* my modifications
*        weight = 1
       weight = 1:-(abs(time1[t,1] :- time1))/(lag_cutoff+1)
         // obs var far enough apart in time are prescribed to have no estimated
        // correlation (Greene recomments lag_cutoff >= T^0.25 {pg 546})
        
        window_t = (abs(time1[t,1]:- time1) :<= lag_cutoff) :* weight
        
        //this is required so diagonal terms in var-covar matrix are not
        //double counted (since they were counted once above for the spatial
        //correlation estimates:
        
        window_t = window_t :* (time1[t,1] :!= time1)                   
            
  		// ----------------------------------------------------------------
        // step b: construct X'e'eX for given observation
         
       	XeeXh = ((X1[t,.]'*J(1,n1,1)*e1[t,1]):*(J(k_variables,1,1)*e1':*window_t'))*X1

		//add each new k x k matrix onto the existing matrix (will be symmetric)
		        
        XeeX = XeeX + XeeXh

	} // t
} // pi




// -----------------------------------------------------------------
// generate the VCE for x-sectional spatial correlation and serial correlation

XeeX_spatial_HAC = XeeX / n

V = invXX * XeeX_spatial_HAC * invXX / n

// Ensures that the matrix is symmetric 
// in theory, it should be already, but it may not be due to rounding errors for large datasets
V = (V+V')/2 

st_matrix("V_spatial_HAC", V)

} // mata

//------------------------------------------------------------------
//storing results

matrix beta = e(b)

// the row and column names of the new VCE must match the vector b

matrix colnames V_spatial_HAC = `X'
matrix rownames V_spatial_HAC = `X'

// this sets the new estimates as the most recent model

marksample touse				// indicator for inclusion in the sample

ereturn post beta V_spatial_HAC, esample(`touse')

// then filling back in all the parameters for postestimation

ereturn local cmd = "ols_spatial_HAC"

ereturn scalar N = n_obs
ereturn scalar r2 = r2_old
ereturn scalar df_m = df_m_old
ereturn scalar df_r = df_r_old
ereturn scalar rmse = rmse_old
ereturn scalar mss = mss_old
ereturn scalar rss = rss_old
ereturn scalar r2_a = r2_a_old

ereturn local title = "Linear regression"
ereturn local depvar = "`Y'"
ereturn local predict = "regres_p"
ereturn local model = "ols"
ereturn local estat_cmd = "regress_estat"

//storing these estimates for comparison to OLS and the HAC estimates

estimates store spatHAC

//------------------------------------------------------------------
//displaying results

disp as txt " "
disp as txt "OLS REGRESSION"
disp as txt " "
disp as txt "SE CORRECTED FOR CROSS-SECTIONAL SPATIAL DEPENDANCE"
disp as txt "             AND PANEL-SPECIFIC SERIAL CORRELATION"
disp as txt " "
disp as txt "DEPENDANT VARIABLE: `Y'"
disp as txt "INDEPENDANT VARIABLES: `X'"
disp as txt " "
disp as txt "SPATIAL CORRELATION KERNAL CUTOFF: `distcutoff' KM"

if "`bartlett'" == "bartlett" {
	disp as txt "(NOTE: LINEAR BARTLETT WINDOW USED FOR SPATIAL KERNAL)"
}
	
disp as txt "SERIAL CORRELATION KERNAL CUTOFF: `lagcutoff' PERIODS"

ereturn display // standard Stata regression table format

// displaying different SE if option selected

if "`display'" == "display"{
	disp as txt " "
	disp as txt "STANDARD ERRORS UNDER OLS, WITH SPATIAL CORRECTION AND WITH SPATIAL AND SERIAL CORRECTION:"
	estimates table OLS spatial spatHAC, b(%7.3f) se(%7.3f) t(%7.3f) stats(N r2) 	
}

if "`star'" == "star"{
	disp as txt " "
	disp as txt "STANDARD ERRORS UNDER OLS, WITH SPATIAL CORRECTION AND WITH SPATIAL AND SERIAL CORRECTION:"
	estimates table OLS spatial spatHAC, b(%7.3f) star(0.10 0.05 0.01)
}

//------------------------------------------------------------------
// cleaning up Mata environment

capture mata mata drop V invXX  XeeX XeeXh XeeX_spatial_HAC window_t window_i weight t i ti pi X1 Y1 e1 time1 n1 lat lon lat1 lon1 lat_scale lon_scale rows_ti rows_pi timeUnique panelUnique Ntime Npanel X X_var XeeX_spatial Y Y_var b dist_cutoff dist_var distance_i k_variables lag_cutoff lag_var lat_var lon_var n panel panel_var time time_var weight_i

/*
if "`bartlett'" == "bartlett" {
	capture mata mata drop weight_i			
}
*/

end



