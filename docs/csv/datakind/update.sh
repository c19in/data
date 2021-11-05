#!/usr/bin/env bash

## Only some of the CSV endpoints

CSVDATASRC="https://data.covid19bharat.org/csv/latest" # ensure no trailing /
CTIME=`date +%Y-%m-%d_%H%M`

for CSVFILE in case_time_series.csv     \
	       states.csv districts.csv \
	       state_wise_daily.csv     \
	       state_wise.csv           \
	       district_wise.csv; do
    echo "Downloading ${CSVFILE}"
    wget --no-check-certificate -a "WGET_${CTIME}.log" -O "${CSVFILE}" "${CSVDATASRC}/${CSVFILE}"
done

