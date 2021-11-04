## The ideal per-state source data would have one file per date per
## state, with columns giving:
##
## Date,State,District,Confirmed,Recovered,Deceased,Other,Tested
##
## where Other usually refers to miscellenous reasons such as
## migration.

## This script reads the 'districts.csv' file in the format provided
## by https://data.covid19india.org/, and produces such files. This is
## supposed to be a one-time operation, to facilitate a reverse
## workflow that produces the requisite API endpoints from such source
## files.

## The idea is that if future data (beyond the covid19india.org sunset
## date of 31 October 2021) are collected and stored in this format,
## then we should be able to recreate the aggregate files as needed in
## a straightforward way (the main challenge is to obtain the daily
## files in the first place, because the data provided by official are
## usually not in a machine-readable format).

DISTRICTFILE <- commandArgs(trailingOnly = TRUE)[1]
DATADIR <- "daily-data" ## also command line argument?

if (is.na(DISTRICTFILE)) stop("Usage: Rscript aggregate2dailycsv.R <districts.csv>")
if (!dir.exists(DATADIR)) stop("Data directory ", DATADIR, " does not exist.")

districts <- read.csv(DISTRICTFILE)

STATE.NAMES <-
    c(AP = 'Andhra Pradesh',
      AR = 'Arunachal Pradesh',
      AS = 'Assam',
      BR = 'Bihar',
      CT = 'Chhattisgarh',
      GA = 'Goa',
      GJ = 'Gujarat',
      HR = 'Haryana',
      HP = 'Himachal Pradesh',
      JH = 'Jharkhand',
      KA = 'Karnataka',
      KL = 'Kerala',
      MP = 'Madhya Pradesh',
      MH = 'Maharashtra',
      MN = 'Manipur',
      ML = 'Meghalaya',
      MZ = 'Mizoram',
      NL = 'Nagaland',
      OR = 'Odisha',
      PB = 'Punjab',
      RJ = 'Rajasthan',
      SK = 'Sikkim',
      TN = 'Tamil Nadu',
      TG = 'Telangana',
      TR = 'Tripura',
      UT = 'Uttarakhand',
      UP = 'Uttar Pradesh',
      WB = 'West Bengal',
      AN = 'Andaman and Nicobar Islands',
      CH = 'Chandigarh',
      DN = 'Dadra and Nagar Haveli and Daman and Diu',
      DL = 'Delhi',
      JK = 'Jammu and Kashmir',
      LA = 'Ladakh',
      LD = 'Lakshadweep',
      PY = 'Puducherry',
      TT = 'India')

STATE.CODES <- names(STATE.NAMES)
names(STATE.CODES) <- STATE.NAMES


str(districts)

districts <-
    within(districts,
    {
        State <- STATE.CODES[State]
    })

