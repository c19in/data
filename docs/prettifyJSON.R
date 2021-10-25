## Run using Rscript

stopifnot(require(jsonlite))

data_min <- read_json("tmp/data.min.json")

data_min_original <- readLines("tmp/data.min.json", encoding = "UTF-8")
stopifnot(length(data_min_original) == 1)

data_min_string <- minify(toJSON(data_min, auto_unbox = TRUE))

stopifnot(data_min_original == data_min_string)

## N <- 100
## substring(data_min_original, 1, N) == substring(data_min_string, 1, N)
## rbind(substring(data_min_original, 1, N),
##       substring(data_min_string, 1, N))


### Goal: To write JSON slightly less minified, by inserting newlines
### so that update diffs are reasonable. There doesn't seem to be a
### built-in way to do that, so we will implement a custom writer.

### For data.min.json, the structure is

### structure:
##
## > str(data_min$WB)
## List of 6
##  $ delta     :List of 4
##   ..$ confirmed: int 974
##   ..$ deceased : int 12
##   ..$ recovered: int 808
##   ..$ tested   : int 43159
##  $ delta21_14:List of 1
##   ..$ confirmed: int 5038
##  $ delta7    :List of 6
##   ..$ confirmed  : int 5560
##   ..$ deceased   : int 82
##   ..$ recovered  : int 5192
##   ..$ tested     : int 235532
##   ..$ vaccinated1: int 3274712
##   ..$ vaccinated2: int 1067359
##  $ meta      :List of 4
##   ..$ date        : chr "2021-10-23"
##   ..$ last_updated: chr "2021-10-23T19:47:24+05:30"
##   ..$ population  : int 96906000
##   ..$ tested      :List of 2
##   .. ..$ date  : chr "2021-10-23"
##   .. ..$ source: chr "https://www.wbhealth.gov.in/uploaded_files/corona/WB_DHFW_Bulletin_23RD_OCT_REPORT_FINAL.pdf"
##  $ total     :List of 6
##   ..$ confirmed  : int 1585466
##   ..$ deceased   : int 19045
##   ..$ recovered  : int 1558690
##   ..$ tested     : int 18885567
##   ..$ vaccinated1: int 51245364
##   ..$ vaccinated2: int 19316609
##  $ districts :List of 24
##   ..$ Alipurduar       :List of 5
##   .. ..$ delta     :List of 4
##   .. .. ..$ confirmed  : int 4
##   .. .. ..$ recovered  : int 5
##   .. .. ..$ vaccinated1: int 8618
##   .. .. ..$ vaccinated2: int 3177
##   .. ..$ delta21_14:List of 1
##   .. .. ..$ confirmed: int 50
##   .. ..$ delta7    :List of 5
##   .. .. ..$ confirmed  : int 27
##   .. .. ..$ deceased   : int 1
##   .. .. ..$ recovered  : int 40
##   .. .. ..$ vaccinated1: int 67882
##   .. .. ..$ vaccinated2: int 23239
##   .. ..$ meta      :List of 1
##   .. .. ..$ population: int 1700000
##   .. ..$ total     :List of 5
##   .. .. ..$ confirmed  : int 15553
##   .. .. ..$ deceased   : int 102
##   .. .. ..$ recovered  : int 15401
##   .. .. ..$ vaccinated1: int 910100
##   .. .. ..$ vaccinated2: int 323490
##   ..$ Bankura          :List of 5
##   .. ..$ delta     :List of 4
##   .. .. ..$ confirmed  : int 24
##   .. .. ..$ recovered  : int 16
##   .
##   .
##   .


## Not really important for data.min, as this will mostly change
## everyday, but just to verify that we can do it.

write_data_min <- function(x, file = "")
{
    stringify <- function(obj) minify(toJSON(obj, auto_unbox = TRUE))
    write2file <- function(..., append = TRUE) cat(..., file = file, sep = "", append = append)
    ## x is a nested list. First level is states.
    ## Just do each state on its own line
    write2file("{", append = FALSE)
    for (i in seq_along(x))
    {
        s <- names(x)[i]
        write2file('\n"', s, '":')
        write2file(stringify(x[[s]]))
        if (i < length(x)) write2file(",")
    }
    write2file("\n}")
}

write_data_min(data_min, file = "data.min.json")

## verify that file can be read as JSON

reread <- read_json("data.min.json")
stopifnot(identical(reread, data_min))


## Next, do this for the much more complicated timeseries.min.json file

timeseries_min <- read_json("tmp/timeseries.min.json")
timeseries_min_original <- readLines("tmp/timeseries.min.json", encoding = "UTF-8")
stopifnot(length(timeseries_min_original) == 1)

timeseries_min_string <- minify(toJSON(timeseries_min, auto_unbox = TRUE))
stopifnot(timeseries_min_original == timeseries_min_string)

## Hmm, this is only statewise historical data. From where does the
## website get district-wise historical data?

## Anyway, let's do one line date-wise so that only new lines are added 

write_timeseries_min <- function(x, file = "", newfile = TRUE)
{
    stringify <- function(obj) minify(toJSON(obj, auto_unbox = TRUE))
    write2file <- function(..., append = TRUE) cat(..., file = file, sep = "", append = append)
    ## x is a nested list. First levels are states > "dates" > "YYYY-MM-DD"
    write2file("{", append = !newfile)
    for (i in seq_along(x))
    {
        s <- names(x)[i]
        write2file('\n"', s, '":{')
        ## x[[s]] has only 'dates' for state level data, and 'dates'
        ## and 'districts' for district level data.
        if (!identical(names(x[[s]]), "dates"))
            stop("Expecting a single component named 'dates', found ",
                 paste(names(x[[s]]), collpse = " "))
        write2file('\n"dates":{')
        dlist <- x[[s]][["dates"]]
        for (j in seq_along(dlist))
        {
            d <- names(dlist)[j]
            write2file('\n"', d, '":')
            write2file(stringify(dlist[[d]]))
            if (j < length(dlist)) write2file(",")
        }
        ## close date and state
        if (i < length(x))
            write2file("\n}},") 
        else
            write2file("\n}}")
    }
    write2file("\n}")
}

write_timeseries_min(timeseries_min, file = "timeseries.min.json")

## verify that file can be read as JSON

reread <- read_json("timeseries.min.json")
stopifnot(identical(reread, timeseries_min))

## Do the same for statewise

state_codes <- c("AP", "AR", "AS", "BR", "CT", "GA", "GJ", "HR", "HP",
                 "JH", "KA", "KL", "MP", "MH", "MN", "ML", "MZ", "NL",
                 "OR", "PB", "RJ", "SK", "TN", "TG", "TR", "UT", "UP",
                 "WB", "AN", "CH", "DN", "DL", "JK", "LA", "LD", "PY")


## For states, two components under state, dates and districts. dates
## is a repeat of the above, but only for one state. Then districts
## has each district, with the same structure as a state.

## For the districts part, we will re-use the state timeseries code.

write_timeseries_state_min <- function(x, file = "")
{
    stopifnot(length(x) == 1)
    stringify <- function(obj) minify(toJSON(obj, auto_unbox = TRUE))
    write2file <- function(..., append = TRUE) cat(..., file = file, sep = "", append = append)
    ## x is a nested list. First levels are states > "dates" > "YYYY-MM-DD"
    write2file("{", append = FALSE)
    s <- names(x)
    write2file('\n"', s, '":{')
    ## x[[s]] has only 'dates' for state level data, and 'dates'
    ## and 'districts' for district level data.
    if (!all(names(x[[s]] %in% c("dates", "districts"))))
        stop("Expecting components named 'dates' and 'districts', found ",
             paste(names(x[[s]]), collapse = " "))
    write2file('\n"dates":{')
    dlist <- x[[s]][["dates"]]
    for (j in seq_along(dlist))
    {
        d <- names(dlist)[j]
        write2file('\n"', d, '":')
        write2file(stringify(dlist[[d]]))
        if (j < length(dlist)) write2file(",")
    }
    ## close 'dates' but not state, and start districts
    write2file('\n},\n"districts":')
    write_timeseries_min(x[[s]][["districts"]], file = file, newfile = FALSE)
    ## close 'districts' and state
    write2file("\n}}")
}



for (STATECODE in state_codes)
{
    message(STATECODE)
    state_json_file <- sprintf("timeseries-%s.min.json", STATECODE)
    timeseries_state <- read_json(file.path("tmp", state_json_file))
    write_timeseries_state_min(timeseries_state, file = state_json_file)
    reread <- read_json(state_json_file)
    stopifnot(identical(reread, timeseries_state))
}

## Finally, TT is India. TODO

