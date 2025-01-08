# Sector-level-FDI-gravity-database
The do-file uploaded to this repository was created for a Master thesis at the University of Groningen: "Do aggregate gravity models for FDI mask sector heterogeneities in the investment motive and the distance elasticity? Insights from a novel sector-level dataset". 
A key innovative feature of my thesis is the use of a novel sector-level database for FDI, the Multinational Revenue, Employment, and Investment Database (MREID) by Ahmad et al. (2023). This database offers FDI data with extensive geographical and sectoral coverage, spanning both developing and developed countries and 25 sectors at the granular 2-digit NAICS level. The dataset is based on operational firm-level data from Bureau van Dijk's Orbis database.

In order to apply gravity estimations at the sector-level as well as at the country-level - aggregated across sectors -, the MREID database is merged with several gravity and control variables from other datasets. The coding efforts to construct the final country-level and sector-level datasets for the gravity estimations are shown in the do-file "dataset construction" uploaded to this repository. To make the code plug and play, the excel files and data files used are uploaded as well and should be saved in the same working directory as the do-file. The data sources are indicated in the following. However, as data e.g., from the World Bank, is continuously updated, or variable names are sometimes subject to change, I uploaded each data file used in the do-file, to make it directly reproducible. 

DATA SOURCES

1. Multinational Revenue, Employment, and Investment Database (MREID) by Ahmad et al. (2023): https://www.usitc.gov/data/gravity/mreid.htm
2. Penn World Table 10.0 Feenstra et al. (2015): https://www.rug.nl/ggdc/productivity/pwt/pwt-releases/pwt100
3. CEPII gravity database (Conte et al., 2022):  https://www.cepii.fr/cepii/en/bdd_modele/bdd_modele.asp
4. World Development Indicators  (The World Bank): https://databank.worldbank.org/source/world-development-indicators
4. Financial Development Index by IMF: https://www.imf.org/en/Publications/WP/Issues/2016/12/31/Introducing-a-New-Broad-based-Index-of-Financial-Development-43621
5. Economic Freedom Index by Fraser Institute: https://www.fraserinstitute.org/economic-freedom/dataset?geozone=world&page=dataset&min-year=2&max-year=0&filter=0&year=2010
6. Bilateral exchange rate regime by Harms and Knaze (2021): https://www.international.economics.uni-mainz.de/data-on-bilateral-exchange-rate-regimes/ 
