#!/usr/bin/env bash

## For now, do the two JSON endpoints and a few of the CSV endpoints

JSONDATASRC="https://data.covid19india.org/v4/min" # ensure no trailing /
CSVDATASRC="https://data.covid19india.org/csv/latest" # ensure no trailing /

CTIME=`date +%Y-%m-%d_%H%M`

mkdir -p tmp

for JSONFILE in timeseries.min.json data.min.json; do
    wget --no-check-certificate -a "WGET_${CTIME}.log" -O "tmp/${JSONFILE}" "${JSONDATASRC}/${JSONFILE}"
done

## Before checking these in, we want to insert newlines so that diffs become cleaner

Rscript prettifyJSON.R

for CSVFILE in case_time_series.csv     \
	       states.csv districts.csv \
	       state_wise_daily.csv     \
	       state_wise.csv           \
	       district_wise.csv; do
    wget --no-check-certificate -a "WGET_${CTIME}.log" -O "${CSVFILE}" "${CSVDATASRC}/${CSVFILE}"
done

