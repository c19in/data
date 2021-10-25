#!/usr/bin/env bash

## For now, do the two JSON endpoints and a few of the CSV endpoints

JSONDATASRC="https://data.covid19india.org/v4/min" # ensure no trailing /
CSVDATASRC="https://data.covid19india.org/csv/latest" # ensure no trailing /

CTIME=`date +%Y-%m-%d_%H%M`

mkdir -p tmp

for JSONFILE in timeseries.min.json data.min.json; do
    echo "Downloading ${JSONFILE}"
    wget --no-check-certificate -a "WGET_${CTIME}.log" -O "tmp/${JSONFILE}" "${JSONDATASRC}/${JSONFILE}"
done

for STATECODE in AP AR AS BR CT GA GJ HR HP JH KA KL MP MH MN ML MZ NL \
		 OR PB RJ SK TN TG TR UT UP WB AN CH DN DL JK LA LD PY TT; do
    JSONFILE="timeseries-${STATECODE}.min.json"
    echo "Downloading ${JSONFILE}"
    wget --no-check-certificate -a "WGET_${CTIME}.log" -O "tmp/${JSONFILE}" "${JSONDATASRC}/${JSONFILE}"
done



## Before checking these in, we want to insert newlines so that diffs become cleaner

echo "Converting JSON files"
Rscript prettifyJSON.R


## Download CSV files

for CSVFILE in case_time_series.csv     \
	       states.csv districts.csv \
	       state_wise_daily.csv     \
	       state_wise.csv           \
	       district_wise.csv; do
    echo "Downloading ${CSVFILE}"
    wget --no-check-certificate -a "WGET_${CTIME}.log" -O "${CSVFILE}" "${CSVDATASRC}/${CSVFILE}"
done

