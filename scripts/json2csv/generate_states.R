## Usage: Rscript generate_states.R <JSONROOT>

## Create the states.csv file from JSON data. Columns are
##
## Date,State,Confirmed,Recovered,Deceased,Other,Tested
##
## Rows are sorted by Date, then by State.  All data (should be)
## available in timeseries.min.json

args <- commandArgs(trailingOnly = TRUE)

ROOT <- args[1]
if (is.na(ROOT)) ROOT <- getwd()

library(jsonlite)

jdata <- read_json(file.path(ROOT, "timeseries.min.json"))

## Seems simplest to go by date. Components of jdata are state codes
## (including TT=India). Each such component has a (single) component
## named "dates" which is a list named by dates. Within these are
## components delta, delta7, and total. We only need to extract total.

## str(jdata$WB, max.level = 2)
## str(jdata$TT, max.level = 1)
## str(jdata$WB$dates[["2020-06-21"]])

extractNumbers <- function(x)
{
    if (is.null(x)) stop("Data not available, check before calling.")
    FIELDS <- c("Confirmed", "Recovered", "Deceased", "Other", "Tested")
    fields <- tolower(FIELDS)
    ## not all names are always there. Replace others by 0
    ans <- unlist(x$total)[fields]
    ans[is.na(ans)] <- 0
    names(ans) <- FIELDS
    ans
}

## Test:
## extractNumbers(jdata$TT$dates[["2020-02-03"]])

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


## sort names by code to get desired order (to match covid19india.org)
STATE.NAMES <- STATE.NAMES[sort(names(STATE.NAMES))]

STATE.CODES <- names(STATE.NAMES)
names(STATE.CODES) <- STATE.NAMES

## Dates start from "2020-01-30" and go upto today. Some date / state
## combinations may be missing, so check.

DATES <- as.character(seq(as.Date("2020-01-30"), Sys.Date(), by = 1))

extractDataByDate <- function(D, jdata, add.unassigned = TRUE)
{
    ldate <- 
        lapply(STATE.CODES,
               function(S)
               {
                   x <- jdata[[S]]$dates[[D]]
                   if (is.null(x)) NULL
                   else extractNumbers(x)
               })
    ddate <- do.call(rbind, ldate)
    if (is.null(ddate))
        return(NULL)
    else {
        ddate <-
            cbind(Date = D, State = rownames(ddate),
                  as.data.frame(ddate))
        if (add.unassigned)
        {
            ## If India number does not equal state total, add a row
            ## with State="State Unassigned".
            w <- which(ddate$State == "India")
            stopifnot(length(w) == 1)
            unassigned.c <- ddate$Confirmed[w] - sum(ddate$Confirmed[-w])
            unassigned.r <- ddate$Recovered[w] - sum(ddate$Recovered[-w])
            unassigned.d <- ddate$Deceased[w] - sum(ddate$Deceased[-w])
            if (unassigned.c | unassigned.r | unassigned.d)
            {
                message(sprintf("(C,R,D) discrepancy on %s = (%d,%d,%d)",
                                D, unassigned.c, unassigned.r, unassigned.d))
                ## Insert new column right after India
                ddate <- rbind(head(ddate, w),
                               tail(ddate, -(w-1))) # second one is duplicate
                ddate$State[w+1] <- "State Unassigned"
                ddate$Confirmed[w+1] <- unassigned.c
                ddate$Recovered[w+1] <- unassigned.r
                ddate$Deceased[w+1] <- unassigned.d
                ddate$Other[w+1] <- 0 # ignore
                ddate$Tested[w+1] <- 0 # ignore
                ## str(ddate[w+1, ])
            }
        }
        rownames(ddate) <- NULL
        ## drop states that have all 0 confirmed
        ddate <- subset(ddate, Confirmed + Other + Tested != 0)
        return(ddate)
    }
}

str(extractDataByDate("2021-03-02", jdata))

states <- do.call(rbind,
                  lapply(DATES, extractDataByDate, jdata = jdata,
                         add.unassigned = TRUE))

## One special case handled here: Tested==0 really means NA. These
## were missing in the JSON, but to handle 'Other' we converted them
## to 0. But the Tested==0 values should become missing in the output,
## so:

states <- within(states,
{
    is.na(Tested) <- Tested == 0
})

write.csv(states, file = "states.csv", row.names = FALSE, quote = FALSE, na = "")
