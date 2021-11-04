#!/usr/bin/env bash

## Download JSON endpoints and store them in prettified form (to help debugging)

JSONDATASRC="https://data.covid19india.org/v4/min" # ensure no trailing /
CTIME=`date +%Y-%m-%d_%H%M`

mkdir -p tmp

for JSONFILE in timeseries.min.json data.min.json; do
    echo "Downloading ${JSONFILE}"
    wget --no-check-certificate -a "WGET_${CTIME}.log" -O "tmp/${JSONFILE}" "${JSONDATASRC}/${JSONFILE}"
    echo "Converting ${JSONFILE}"
    python3 -m json.tool --indent 1 tmp/${JSONFILE} ${JSONFILE}
done

for STATECODE in AP AR AS BR CT GA GJ HR HP JH KA KL MP MH MN ML MZ NL \
		 OR PB RJ SK TN TG TR UT UP WB AN CH DN DL JK LA LD PY; do
    JSONFILE="timeseries-${STATECODE}.min.json"
    echo "Downloading ${JSONFILE}"
    wget --no-check-certificate -a "WGET_${CTIME}.log" -O "tmp/${JSONFILE}" "${JSONDATASRC}/${JSONFILE}"
done

for STATECODE in AP AR AS BR CT GA GJ HR HP JH KA KL MP MH MN ML MZ NL \
		 OR PB RJ SK TN TG TR UT UP WB AN CH DN DL JK LA LD PY; do
    INFILE="tmp/timeseries-${STATECODE}.min.json"
    OUTFILE="timeseries-${STATECODE}.min.json"
    echo "Converting ${OUTFILE}"
    python3 -m json.tool --indent 1 ${INFILE} ${OUTFILE}
done

