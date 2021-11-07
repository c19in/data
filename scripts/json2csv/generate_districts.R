## Usage: Rscript generate_states.R <JSONROOT>

## Create the districts.csv file from JSON data. Columns are
##
## Date,State,District,Confirmed,Recovered,Deceased,Other,Tested
##
## Rows are sorted by Date, then by State, then by District.  All data (should be)
## available in timeseries-XX.min.json. India total NOT included

args <- commandArgs(trailingOnly = TRUE)

ROOT <- args[1]
if (is.na(ROOT)) ROOT <- getwd()

library(jsonlite)

## Although the final file is sorted by date, it is more convenient to
## process one state at a time. 

## TT not to be included
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
      PY = 'Puducherry')

## sort names by code to get desired order (to match covid19india.org)
STATE.NAMES <- STATE.NAMES[sort(names(STATE.NAMES))]

### Example:
##
## state_file <- sprintf("timeseries-%s.min.json", "DL")
## jdata <- read_json(file.path(ROOT, state_file))
## str(jdata, max.level = 2)
## List of 1
##  $ DL:List of 2
##   ..$ dates    :List of 613
##   ..$ districts:List of N

## The 'dates' component gives state total, which We don't care about
## here (but should be consistent with the numbers in
## timeseries.min.json - something to check separately TODO)

## So, given state code, we can extract the part we want using

if (FALSE)
{
    S <- "TR"
    jdata <- read_json(file.path(ROOT, sprintf("timeseries-%s.min.json", S)))[[S]][["districts"]]
    str(jdata, max.level = 2)

    ## List of 9
    ##  $ Dhalai       :List of 1
    ##   ..$ dates:List of 552
    ##  $ Gomati       :List of 1
    ##   ..$ dates:List of 558
}

## Components of jdata are now district names. Each such component has
## a (single) component named "dates" which is a list named by
## dates. Within these are components delta, delta7, and total. We
## only need to extract total. At this point, we have the same
## structure as in generate_states.R, so we can just re-use that code.

## str(jdata$WB, max.level = 2)
## str(jdata$TT, max.level = 1)
## str(jdata$WB$dates[["2020-06-21"]])

extractNumbers <- function(x)
{
    if (is.null(x)) stop("Data not available, check before calling.")
    if (!length(x$total)) return(NULL) # FIXME: should this happen?
    FIELDS <- c("Confirmed", "Recovered", "Deceased", "Other", "Tested")
    fields <- tolower(FIELDS)
    ## not all names are always there. Replace others by 0
    ans <- unlist(x$total)[fields]
    ans[is.na(ans)] <- 0
    if (length(ans) == 0) str(x)
    names(ans) <- FIELDS
    ## if (ans["Confirmed"] == 0 && sum(ans[1:4]) != 0) print(unname(ans))
    ans
}

## Use dates starting from "2020-01-30", but many dates will be
## missing, so check

DATES <- as.character(seq(as.Date("2020-01-30"), Sys.Date(), by = 1))

extractDataByDate <- function(D, jdata, STATE = "")
{
    ldate <- 
        lapply(names(jdata),
               function(S)
               {
                   x <- jdata[[S]]$dates[[D]]
                   if (is.null(x)) NULL
                   else extractNumbers(x)
               })
    names(ldate) <- names(jdata)
    ## str(ldate)
    ddate <- do.call(rbind, ldate)
    if (is.null(ddate))
        return(NULL)
    else {
        ## str(list(Date = D, State = STATE, District = rownames(ddate),
        ##          ddate = as.data.frame(ddate)))
        ddate <-
            cbind(Date = D, State = unname(STATE), District = rownames(ddate),
                  as.data.frame(ddate))
        rownames(ddate) <- NULL
        ## drop states that have all 0 confirmed
        ddate <- subset(ddate, Confirmed + Recovered + Other + Tested != 0)
        return(ddate)
    }
}


## Loop through states and collect results in a list

all.states <- 
    lapply(names(STATE.NAMES),
           function(SCODE) {
               message(SCODE)
               file <- file.path(ROOT, sprintf("timeseries-%s.min.json", SCODE))
               jdata <- read_json(file)[[SCODE]][["districts"]]
               do.call(rbind,
                       lapply(DATES, extractDataByDate,
                              jdata = jdata,
                              STATE = SCODE))
           })

districts <- do.call(rbind, all.states)

## Sort by Date, then State (code), then District.
o <- with(districts, order(Date, State, District))
districts <- districts[o, ]

## Finally, replace state codes by state names. Also, Tested==0 really
## means NA and should be recorded accordingly, so modify.

districts <- within(districts,
{
    State  <-  STATE.NAMES[State]
    is.na(Tested) <- Tested == 0
})

## Includes some rows like:
##
## 2020-04-26,Rajasthan,Other State,0,2,2,0,
## 2020-04-26,Tamil Nadu,Unknown,0,25,-1,0,
##
## which are not included in covid19india.org's output. These all seem
## to have Confirmed==0, so just skip those.

## districts <- subset(districts, Confirmed != 0)

write.csv(districts, file = "districts.csv", row.names = FALSE, quote = FALSE, na = "")

