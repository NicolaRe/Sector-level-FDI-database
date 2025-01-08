# Sector-level-FDI-gravity-database
The do-file in this repository was developed for a Master's thesis at the University of Groningen titled: "Do aggregate gravity models for FDI mask sector heterogeneities in the investment motive and the distance elasticity? Insights from a novel sector-level dataset." A key innovative feature of this thesis is the use of a novel sector-level FDI database: the Multinational Revenue, Employment, and Investment Database (MREID) by Ahmad et al. (2023). This database provides comprehensive FDI data with broad geographical and sectoral coverage, including both developed and developing countries, across 25 sectors at the granular 2-digit NAICS level. The dataset is built from operational firm-level data sourced from Bureau van Dijk's Orbis database.

To perform gravity estimations at both the sectoral and country-level (aggregated across sectors), the MREID database was merged with various gravity and control variables from additional datasets. The steps taken to construct the final country-level and sector-level datasets for the gravity estimations are documented in the do-file titled "dataset construction," available in this repository. To ensure the code is fully reproducible, all necessary Excel and data files have also been uploaded and should be saved in the same working directory as the do-file. While the data sources used are listed, some (e.g., from the World Bank) are regularly updated, and variable names may occasionally change. For this reason, the exact data files used in the analysis have been provided to ensure seamless reproducibility.

DATA SOURCES

1. Multinational Revenue, Employment, and Investment Database (MREID) by Ahmad et al. (2023): https://www.usitc.gov/data/gravity/mreid.htm
2. Penn World Table 10.0 Feenstra et al. (2015): https://www.rug.nl/ggdc/productivity/pwt/pwt-releases/pwt100
3. CEPII gravity database (Conte et al., 2022):  https://www.cepii.fr/cepii/en/bdd_modele/bdd_modele.asp
As this datafile is too large to be uploaded here, download it yourself as a Stata .dta-file from CEPII, save it in your working directory, and name it "Gravity_V202211_original.dta", to make it compatible with the naming in the Do-File.
5. World Development Indicators  (The World Bank): https://databank.worldbank.org/source/world-development-indicators
4. Financial Development Index by IMF: https://www.imf.org/en/Publications/WP/Issues/2016/12/31/Introducing-a-New-Broad-based-Index-of-Financial-Development-43621
5. Economic Freedom Index by Fraser Institute: https://www.fraserinstitute.org/economic-freedom/dataset?geozone=world&page=dataset&min-year=2&max-year=0&filter=0&year=2010
6. Bilateral exchange rate regime by Harms and Knaze (2021): https://www.international.economics.uni-mainz.de/data-on-bilateral-exchange-rate-regimes/ 
