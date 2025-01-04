global path "working directory"
cd "$path"
clear
clear matrix
set more off

*to install:
*ssc install wbopendata

*generate country pair identifier
use mreid.dta, replace
*drop country_pair
*encode country_pair, gen(country_pair_encode) //for clustering
egen country_pair = concat(iso3_o iso3_d) 
save mreid.dta, replace

**************************************
********** Prepare Data **************
**************************************

*get real GDP from WDI -> as World Bank data changes, I only downloaded the data once from the World Bank (14/09/2024) and saved it as the data set "realGDP_constant2015USD_old"
/*
*https://databank.worldbank.org/metadataglossary/world-development-indicators/series/NY.GDP.MKTP.KD
wbopendata, indicator(NY.GDP.MKTP.KD) clear long
keep countrycode countryname year ny_gdp_mktp_kd
rename countrycode iso3_d
rename ny_gdp_mktp_kd gdp_dest
keep if year >= 2010
keep if year <= 2020
save realGDP_constant2015USD.dta, replace
*/
*get exchange rate data from WDI -> as World Bank data changes, I only downloaded the data once from the World Bank (14/09/2024) and saved it as the data set "xr_old"
/*
*https://databank.worldbank.org/metadataglossary/world-development-indicators/series/PA.NUS.FCRF
wbopendata, indicator(PA.NUS.FCRF) clear long
keep countrycode countryname year pa_nus_fcrf
rename countrycode iso3_d
rename pa_nus_fcrf xr
keep if year >= 2010
keep if year <= 2020
save xr.dta, replace
*/
* get Human Capital Index from PWT
use pwt100.dta, replace
encode country, gen(country_enc)
xtset country_enc year
keep iso3_d country country_enc year hc 

gen missing_hc = missing(hc) // Create a flag for missing human capital
bysort country_enc: egen all_missing = total(missing_hc) // Collapse the data to check if human capital is missing for all years per country
bysort country: gen drop_country = (all_missing == _N) // If the total of missing values equals the number of years (or observations per country), human capital is missing for all years
drop if drop_country // Drop countries where human capital is missing for all years
drop missing_hc all_missing drop_country // Clean up unnecessary variables

* Estimate a linear trend for each country to deal with missing values for 2020
xtreg hc c.year#i.country_enc i.country_enc
expand 2 if year == 2019
by country_enc year, sort: replace year = 2020 if year == 2019 & _n == _N 
predict predicted_hc2 
replace hc = predicted_hc if year == 2020
keep iso3_d country year hc
save pwt_hc.dta, replace 

* get host country tariff from WDI  -> as World Bank data changes, I only downloaded the data once from the World Bank (14/09/2024) and saved it as the data set "tariff_dest_old"
/*
wbopendata, indicator(TM.TAX.MRCH.WM.AR.ZS) clear long
keep countrycode countryname year tm_tax_mrch_wm_ar_zs
rename countrycode iso3_d
rename tm_tax_mrch_wm_ar_zs tariff_dest
keep if year >= 2010
keep if year <= 2020
save tariff_dest.dta, replace
*/ 

* get bilateral XR regime data
use xr_regime.dta, replace
drop if year < 2010 | year > 2020
egen country_pair = concat(iso1 iso2) 
encode country_pair, gen(country_pair_encode) 
save xr_regime2.dta, replace

* get economic freedom index from Heritage Foundation
import excel "heritage.xlsx", firstrow clear
keep if Year >= 2010 & Year < 2021
drop A
rename ISOCode3 iso3_d
rename Year year
keep iso3_d year Countries EconomicFreedomSummaryIndex
rename EconomicFreedomSummaryIndex freedom
save heritage, replace

* get GDP deflator 
use pwt100.dta, replace
encode country, gen(country_enc)
xtset country_enc year
keep iso3_d country country_enc year pl_gdpo 

* Estimate a linear trend for each country to deal with missing values for 2020
xtreg pl_gdpo c.year#i.country_enc i.country_enc
expand 2 if year == 2019
by country_enc year, sort: replace year = 2020 if year == 2019 & _n == _N 
predict predicted_pl
replace pl_gdpo = predicted_pl if year == 2020
keep iso3_d country year pl_gdpo
save pwt_pl.dta, replace 

**************************************
********** Data Merging **************
**************************************
* 1) country-level variables 
* a) Host country-level
* xr
* merge by host country iso
use mreid.dta, replace
merge m:1 iso3_d year using xr_old.dta //not merged: 2021 observations in MREID, countries not included in MREID 
drop if _merge == 2 //drop the observations for which there is no matching observation with investment data from the MREID
drop _merge
rename xr xr_host
save mreid_xr.dta, replace

* gdp
* merge by host country iso
use mreid_xr.dta, replace
merge m:1 iso3_d year using realGDP_constant2015USD_old.dta //not merged: 2021 observations in MREID, countries not included in MREID 
drop if _merge == 2 //drop the observations for which there is no matching observation with investment data from the MREID
drop _merge
rename ny_gdp_mktp_kd gdp_dest
save mreid_gdp.dta, replace

*financial development
use fin_dev, replace
rename code iso3_d
rename FD fd_host
keep if year >= 2010 & year <= 2020
save fd_host, replace
*merge by host country
use mreid_gdp.dta, replace
merge m:1 iso3_d year using fd_host.dta
drop if _merge == 2
drop _merge
save mreid_gdp, replace

* human capital index
use mreid_gdp.dta, replace
merge m:1 iso3_d year using pwt_hc.dta // not merged from master: some countries like Bosnia Herzegovina for which no human capital index data is available, from using: 2021 observations with nor MREID data as well as years before 2010
drop if _merge == 2 
drop _merge
rename hc hc_dest
save mreid_gdp.dta, replace 

* tariff
use mreid_gdp.dta, replace
merge m:1 iso3_d year using tariff_dest_old.dta
drop if  _merge == 2 
drop _merge
save mreid_gdp.dta, replace

* economic freedom index
use mreid_gdp, replace
merge m:1 iso3_d year using heritage 
drop if _merge == 2
drop _merge
drop Countries
rename freedom freedom_d
save mreid_gdp, replace

* country-level variables 
* b) Origin country-level
*xr
use xr_old.dta, replace
rename iso3_d iso3_o
rename xr xr_origin
save xr_origin_old.dta, replace
*merge by source country iso
use mreid_gdp.dta, replace
merge m:1 iso3_o year using xr_origin_old.dta
drop if _merge == 2 
drop _merge
save mreid_gdp.dta, replace

*GDP
use realGDP_constant2015USD.dta, replace
rename iso3_d iso3_o
rename gdp_dest gdp_origin
keep iso3_o gdp year
save realGDP_constant2015USD_origin.dta, replace
*merge by source country iso
use mreid_gdp.dta, replace
merge m:1 iso3_o year using realGDP_constant2015USD_origin_old.dta 
drop if _merge == 2
drop _merge
save mreid_gdp.dta, replace

*financial development
use fin_dev, replace
rename code iso3_o
rename FD fd_origin
keep if year >= 2010 & year <= 2020
save fd_origin, replace
*merge
use mreid_gdp.dta, replace
merge m:1 iso3_o year using fd_origin.dta
drop if _merge == 2 
drop _merge
drop FI FM FID FIA FIE FMD FMA FME
save mreid_gdp, replace

* human capital index
use pwt_hc, replace
rename iso3_d iso3_o
save pwt_hc_origin.dta, replace

use mreid_gdp.dta, replace
merge m:1 iso3_o year using pwt_hc_origin.dta
drop if _merge == 2 
drop _merge
rename hc hc_origin
save mreid_gdp.dta, replace 

* economic freedom index
use heritage, replace
rename iso3_d iso3_o 
rename freedom freedom_o
save heritage, replace

use mreid_gdp, replace
merge m:1 iso3_o year using heritage 
drop if _merge == 2
drop _merge Countries
save  mreid_gdp, replace
use heritage, replace // restore original naming of heritage dataset
rename freedom_o freedom
rename iso3_o iso3_d
save heritage, replace

* 2) bilateral gravity variables
* use CEPII dataset
use Gravity_V202211_original.dta, replace
order distw_harmonic comcol comlang_off col45 contig
drop gmt_offset_2020_o-tradeflow_imf_d
*delete countries in CEPII with ambiguous country names
drop if country_id_d == "MYS.1" |  country_id_d == "PAK.1" |  country_id_d == "IDN.1" |  country_id_d == "YEM.1" |  country_id_d == "ETH.1" |  country_id_d == "DEU.1"|  country_id_d == "ANT.1" | country_id_d == "VNM.1" | country_id_d == "SDN.1"
drop if country_id_o == "MYS.1" |  country_id_o == "PAK.1" |  country_id_o == "IDN.1" |  country_id_o == "YEM.1" |  country_id_o == "ETH.1" |  country_id_o == "DEU.1"|  country_id_o == "ANT.1"|  country_id_o == "VNM.1"|  country_id_o == "SDN.1"
egen country_pair = concat(iso3_o iso3_d)
save Gravity_V202211_deleted.dta, replace
* merge by country pair
use mreid_gdp.dta, replace
merge m:1 country_pair year using Gravity_V202211_deleted.dta 
drop if _merge == 2
drop _merge
keep if naics2 !=. 
save mreid_gdp_gravity.dta, replace

* XR regime
use mreid_gdp_gravity.dta, replace
merge m:1 country_pair year using xr_regime2.dta
drop if _merge == 2
drop _merge
drop direct_link indirect_link other_nslt jf_1 ifs1 iso1 country2 ifs2 iso2 country1
rename bilateral_dejure_regime regime_dejure
rename bilateral_defacto_regime regime_defacto
save mreid_gdp_gravity.dta, replace 

* 3) construct distance variables
use mreid_gdp_gravity, replace
* distance in financial development 
gen fd_distance = fd_host - fd_origin
* distance in economic freedom
gen freedom_dist = freedom_o - freedom_d

order country_pair iso3_o country_o iso3_d country_d year gdp_origin gdp_dest distw_harmonic naics2 naics2description extensive greenfield mergers OperatingrevenueTurnover OperatingrevenueTurnover_green  OperatingrevenueTurnover_mergers TotalassetsthUSD  TotalassetsthUSD_green  TotalassetsthUSD_mergers Numberofemployees  Numberofemployees_green  Numberofemployees_mergers FixedassetsthUSD  FixedassetsthUSD_green FixedassetsthUSD_mergers comcol col45 comlang_off contig xr_host xr_origin

* delete all 2021 observations (due to potential distortions caused by the Covid19 pandemic)
keep if year >= 2010 & year <= 2020 

save data.dta, replace

**************************************
********** Rescaling assets **********
**************************************
* rescale FDI assets and GDP
use data, replace
gen TotalassetsthUSD_rs = TotalassetsthUSD / 1000
gen TotalassetsthUSDmergers_rs =  TotalassetsthUSD_mergers / 1000
gen TotalassetsthUSDgreen_rs =  TotalassetsthUSD_green / 1000

gen FixedassetsthUSD_rs = FixedassetsthUSD / 1000
gen FixedassetsthUSDmergers_rs =  FixedassetsthUSD_mergers / 1000
gen FixedassetsthUSDgreen_rs =  FixedassetsthUSD_green / 1000

gen OperatingrevenueTurnover_rs = OperatingrevenueTurnover / 1000
gen OperatingrevenueTurnoverm_rs =  OperatingrevenueTurnover_mergers / 1000
gen OperatingrevenueTurnoverg_rs =  OperatingrevenueTurnover_green / 1000

drop TotalassetsthUSD TotalassetsthUSD_green TotalassetsthUSD_mergers FixedassetsthUSD FixedassetsthUSD_green FixedassetsthUSD_mergers OperatingrevenueTurnover OperatingrevenueTurnover_green OperatingrevenueTurnover_mergers

rename TotalassetsthUSD_rs TotalassetsthUSD
rename TotalassetsthUSDgreen_rs TotalassetsthUSD_green
rename TotalassetsthUSDmergers_rs TotalassetsthUSD_mergers

rename FixedassetsthUSD_rs FixedassetsthUSD
rename  FixedassetsthUSDgreen_rs  FixedassetsthUSD_green
rename  FixedassetsthUSDmergers_rs  FixedassetsthUSD_mergers

rename OperatingrevenueTurnover_rs  OperatingrevenueTurnover
rename   OperatingrevenueTurnoverg_rs   OperatingrevenueTurnover_green
rename OperatingrevenueTurnoverm_rs   OperatingrevenueTurnover_mergers

gen gdp_origin_rs = gdp_origin / 1000000
gen gdp_dest_rs = gdp_dest / 1000000
rename gdp_origin gdp_origin_og
rename gdp_dest gdp_dest_og
rename gdp_origin_rs gdp_origin
rename gdp_dest_rs gdp_dest

drop gdp_origin_og gdp_dest_og

save data.dta, replace 

**************************************
******* Construct Gravity Datasets ***
**************************************

**************************************
********** country level (aggregated)*
**************************************
*ohne Sektoren
use data.dta, replace

*drop sector "Unclassified establishments" as not meaningful for later sector-level analysis -> for comparability, delete these observations also in the country-level dataset
drop if naics2 == 99 

*create aggregated FDI variables as total assets/fixed assets/revenue summed across sectors at country-pair-year level
collapse (sum) total_fdi_stock = TotalassetsthUSD total_fdi_stock_fixed = FixedassetsthUSD total_revenue=OperatingrevenueTurnover, by(iso3_d country_d iso3_o  country_o year distw_harmonic gdp_dest gdp_origin country_pair comcol col45 comlang_off contig hc_origin hc_dest xr_host xr_origin fd_distance tariff_dest  regime_dejure freedom_dist) // keep all variables we want to maintain in dataset
save countrylevel_data.dta, replace 

*declare as Panel
use countrylevel_data.dta, replace
encode country_pair, gen(country_pair_encode) 
xtset country_pair_encode year
xtdescribe //unbalanced, since in MREID not every country pair has observations in each year

*check which years are missing
preserve
fillin country_pair year
sort country_pair
by country_pair: gen year_count = _N
merge 1:1 country_pair year using mreid_gdp_gravity_countrylevel
list country_pair year if _merge == 1
keep if _merge ==1
tab country_pair
restore
*495 not merged from master -> these are the country_pair-year combinations that don't have observations in the MREID


*generate log variables
gen lndistw = ln(distw_harmonic) 
label variable lndistw "log of distance"
gen lngdp_o = ln(gdp_origin) 
label variable lngdp_o  "log of origin country real GDP" 
gen lngdp_d = ln(gdp_dest) 
label variable lngdp_d "log of destination country real GDP"
gen sum_gdp = gdp_origin+gdp_dest
label variable sum_gdp "sum of GDPs"
gen lnsumgdp = ln(sum_gdp)
label variable lnsumgdp "log of sum of GDPs" 
gen ln_tariff = ln(tariff_dest)
* delete domestic investment
keep if iso3_d != iso3_o 

*generate surrounding market potential
* weight each gdp of source country per host country and year with the bilateral distance 
gen distwgdp_origin = gdp_origin/distw_harmonic 
egen total_distwgdp_origin = total(distwgdp_origin), by (iso3_d year) 
gen smp_dest=total_distwgdp_origin - distwgdp_origin 
*smp_dest changes per country-pair and year due to a) GDP that changes over time, and b) the respective source country which is not included in SMP of the host
gen lnsmp_dest = ln(smp_dest)
drop total_distwgdp_origin distwgdp_origin
label variable smp_dest "surrounding market potential per destination country, year"
label variable lnsmp_dest "log of SMP"

*generate absolute skill endowment difference 
gen abs_sk_diff = abs(hc_origin-hc_dest)

*outlier -> have been identified in the sector-level gravity regression
gen outlier = (country_pair == "USACHN") | (country_pair == "USALUX") | (country_pair == "USAGBR")  

* drop all observations which have missing values in the main gravity variables
drop if missing(lngdp_o) | missing(lngdp_d) | missing(lndistw) | missing(lnsumgdp) | missing(abs_sk_diff) | missing(lnsmp_dest)

*** ACHTUNG
save gravity_countrylevel.dta, replace

**************************************
********** sector level **************
**************************************
use data.dta, replace
*drop sector "Unclassified establishments" as not meaningful for sector-level analysis
drop if naics2 == 99 // 318.442

*declare as Panel with country-pair-sector units
egen country_pair_sector = concat(country_pair naics2)
encode country_pair_sector, gen(country_pair_sector_encode)
xtset country_pair_sector_encode year
xtdescribe

*generate gravity variables
gen lndistw = ln(distw_harmonic) 
label variable lndistw "log of distance"
gen lngdp_o = ln(gdp_origin)
label variable lngdp_o  "log of origin country real GDP"
gen lngdp_d = ln(gdp_dest)
label variable lngdp_d "log of destination country real GDP"
gen sum_gdp = gdp_origin+gdp_dest
label variable sum_gdp "sum of GDPs"
gen lnsumgdp = ln(sum_gdp)
label variable lnsumgdp "log of sum of GDPs"
* delete domestic investment
keep if iso3_d != iso3_o
*generate absolute skill endowment difference & ratio
gen abs_sk_diff = abs(hc_origin-hc_dest)
*log tariff
gen ln_tariff = ln(tariff_dest)

save sectorlevel_data.dta, replace

*smp 
use sectorlevel_data.dta, replace
*generate surrounding market potential
gen distwgdp_origin = gdp_origin/distw_harmonic 
order country_pair iso3_o country_o iso3_d country_d year gdp_origin gdp_dest distw_harmonic naics2 naics2description distwgdp_origin  
sort iso3_d iso3_o year
*sector duplicates
egen country_pair_year_identifier = group(country_pair year)
bysort country_pair_year_identifier (naics2): gen tag = _n == 1
order country_pair iso3_o country_o iso3_d country_d year gdp_origin gdp_dest distw_harmonic naics2 naics2description distwgdp_origin  tag
replace distwgdp_origin = 0 if tag == 0 //now one value of distwgdp_origin per country-pair & year; if > 1 sector, distwgdp_origin == 0
*sum over source countries but not sector duplicates
egen total_distwgdp_origin = total(distwgdp_origin), by (iso3_d year) 
order country_pair iso3_o country_o iso3_d country_d year gdp_origin gdp_dest distw_harmonic naics2 naics2description distwgdp_origin  tag total_distwgdp_origin
rename distwgdp_origin distwgdp_without_duplicates
*create distwgdp_origin again 
gen distwgdp_origin = gdp_origin/distw_harmonic
order country_pair iso3_o country_o iso3_d country_d year gdp_origin gdp_dest distw_harmonic naics2 naics2description distwgdp_origin distwgdp_without_duplicates  tag total_distwgdp_origin 
gen smp_dest=total_distwgdp_origin - distwgdp_origin 
order country_pair iso3_o country_o iso3_d country_d year gdp_origin gdp_dest distw_harmonic naics2 naics2description distwgdp_origin distwgdp_without_duplicates  tag total_distwgdp_origin  smp_dest
*constant across sectors per country-pair-year
gen lnsmp_dest = ln(smp_dest)
drop distwgdp_origin distwgdp_without_duplicates tag total_distwgdp_origin country_id_o-country_exists_d
label variable smp_dest "surrounding market potential per destination country, year"
label variable lnsmp_dest "log of SMP"

*what else do I need in sector-level data set?
encode iso3_d, gen(iso3_d_encode)
encode iso3_o, gen(iso3_o_encode)
drop countryname
egen country_dest_sector = concat(iso3_d naics2)
egen country_origin_sector = concat(iso3_o naics2)
encode country_dest_sector, gen(country_dest_sector_encode)
encode country_origin_sector, gen(country_origin_sector_encode)

*EU dummies
gen EU_temp = 0
foreach code in AUT BEL BGR HRV CYP CZE DNK EST FIN FRA DEU GRC HUN IRL ITA LVA LTU LUX MLT NLD POL PRT ROU SVK SVN ESP SWE {
    replace EU_temp = 1 if iso3_d == "`code'"
}
rename EU_temp EU_d

gen EU_temp = 0
foreach code in AUT BEL BGR HRV CYP CZE DNK EST FIN FRA DEU GRC HUN IRL ITA LVA LTU LUX MLT NLD POL PRT ROU SVK SVN ESP SWE {
    replace EU_temp = 1 if iso3_o == "`code'"
}
rename EU_temp EU_o

gen GBR_d = (iso3_d == "GBR")

*gen OECD dummies 
gen oecd_temp = 0
foreach code in AUS AUT BEL CAN CHL COL CZE DNK EST FIN FRA DEU GRC HUN IRL ISL ISR ITA JPN KOR LVA LTU LUX MEX NLD NZL NOR POL PRT SVK SVN SWE CHE TUR GBR USA {
    replace oecd_temp = 1 if iso3_o == "`code'"
}
rename oecd_temp OECD_o

gen oecd_temp = 0
foreach code in AUS AUT BEL CAN CHL COL CZE DNK EST FIN FRA DEU GRC HUN IRL ISL ISR ITA JPN KOR LVA LTU LUX MEX NLD NZL NOR POL PRT SVK SVN SWE CHE TUR GBR USA {
    replace oecd_temp = 1 if iso3_d == "`code'"
}
rename oecd_temp OECD_d


*gen sector categories: primary, secondary, tertiary
gen primary = (naics2 == 11 | naics2 == 21) // agricultural sector + mining, gas and oil extraction
gen utilities = (naics2 == 22)
gen secondary = inlist(naics2, 23, 31, 32, 33) // construction sector and manufacturing (food + textile, materials, finished product manufacturing)
gen tertiary = !(primary | secondary | utilities) // remaining sectors are all part of the tertiary sector

*gen sector categories: non-financial, financial
gen financial = (naics2 == 52 | naics2 == 53) // finance & insurance, real estate
gen non_financial = (financial == 0)

*outlier -> determined in sector-level gravity regression with all country-pairs
gen outlier = (country_pair == "USACHN") | (country_pair == "USALUX") | (country_pair == "USAGBR") 

* drop all observations which have missing values in the main gravity variables
drop if missing(lngdp_o) | missing(lngdp_d) | missing(lndistw) | missing(lnsumgdp) | missing(abs_sk_diff) | missing(lnsmp_dest)

* generate 1-year lags of main gravity variables
sort country_pair_sector_encode year
gen lngdp_o_lag = L.lngdp_o
gen lngdp_d_lag = L.lngdp_d
gen lnsumgdp_lag = L.lnsumgdp
gen abs_sk_diff_lag = L.abs_sk_diff
gen lnsmp_dest_lag = L.lnsmp_dest

* Achtung
save gravity_sectorlevel.dta, replace

* generate total assets deflated by US GDP deflator

use gravity_sectorlevel, replace
merge m:1 iso3_d year using pwt_pl.dta 
drop if _merge == 2 
drop _merge

gen pl_us_temp = pl_gdpo if iso3_d == "USA"
* Fill the pl_us_temp variable across all rows for the same year
bysort year (pl_us_temp): replace pl_us_temp = pl_us_temp[_n-1] if missing(pl_us_temp)

gen pl_us = pl_us_temp
drop pl_us_temp  

gen TotalAssets_deflated = TotalassetsthUSD / pl_us
* ACHTUNG
save gravity_sectorlevel_defl.dta, replace

