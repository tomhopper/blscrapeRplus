# blscrapeRplus

[![Project Status: Active – The project has reached a stable, usable state and is being actively developed.](https://www.repostatus.org/badges/latest/active.svg "Active")](https://github.com/tomhopper/blscrapeRplus) [![Build Status: Passing - The project passes all build checks](https://travis-ci.org/travis-ci/travis-web.svg?branch=master  "Passing")](https://github.com/tomhopper/blscrapeRplus) ![Lifecycle Status: Maturing - The API has been roughed out, but finer details likely to change](https://img.shields.io/badge/lifecycle-maturing-blue.svg "Maturing")


A wrapper for the R package [blscrapeR](https://github.com/keberwein/blscrapeR) (available on CRAN as of this writing) intended to simplify downloading and saving data series. Where `bls_api()` will return only a range of years supported by a single call to the BLS' API (Up to 20 years for calls with a registered API key, and 10 years without one), `get_bls_data()` and `load_bls_data()` will return all data between two years, or all available data, in a single data frame. 

## Installation

```
devtools::install_github("tomhopper/blscraperplus")
```

## Example

```
> load_bls_data(file_name = "temp/employer_jobs_s.rds", series_id = "CES0000000001", start_year = 1994)
Downloading data from BLS.
REQUEST_SUCCEEDED
REQUEST_SUCCEEDED
REQUEST_SUCCEEDED
# A tibble: 306 x 8
    year period periodName latest  value footnotes seriesID      Date      
   <dbl> <chr>  <chr>      <chr>   <dbl> <chr>     <chr>         <date>    
 1  1994 M01    January    NA     112601 ""        CES0000000001 1994-01-31
 2  1994 M02    February   NA     112785 ""        CES0000000001 1994-02-28
 3  1994 M03    March      NA     113248 ""        CES0000000001 1994-03-31
 4  1994 M04    April      NA     113592 ""        CES0000000001 1994-04-30
 5  1994 M05    May        NA     113928 ""        CES0000000001 1994-05-31
 6  1994 M06    June       NA     114242 ""        CES0000000001 1994-06-30
 7  1994 M07    July       NA     114613 ""        CES0000000001 1994-07-31
 8  1994 M08    August     NA     114902 ""        CES0000000001 1994-08-31
 9  1994 M09    September  NA     115251 ""        CES0000000001 1994-09-30
10  1994 M10    October    NA     115464 ""        CES0000000001 1994-10-31
# … with 296 more rows```
```

The next time we run the function, supplying the same filename, it just loads the data from disk.
```
> load_bls_data(file_name = "temp/employer_jobs_s.rds", series_id = "CES0000000001", start_year = 1994)
Loading data from existing data file.
# A tibble: 306 x 8
    year period periodName latest  value footnotes seriesID      date      
   <dbl> <chr>  <chr>      <chr>   <dbl> <chr>     <chr>         <date>    
 1  1994 M01    January    NA     112601 ""        CES0000000001 1994-01-01
 2  1994 M02    February   NA     112785 ""        CES0000000001 1994-02-01
 3  1994 M03    March      NA     113248 ""        CES0000000001 1994-03-01
 4  1994 M04    April      NA     113592 ""        CES0000000001 1994-04-01
 5  1994 M05    May        NA     113928 ""        CES0000000001 1994-05-01
 6  1994 M06    June       NA     114242 ""        CES0000000001 1994-06-01
 7  1994 M07    July       NA     114613 ""        CES0000000001 1994-07-01
 8  1994 M08    August     NA     114902 ""        CES0000000001 1994-08-01
 9  1994 M09    September  NA     115251 ""        CES0000000001 1994-09-01
10  1994 M10    October    NA     115464 ""        CES0000000001 1994-10-01
# … with 296 more rows
```

If we want to load newer data, we just delete the file.

## Functions

### get_bls_data

`get_bls_data()` is the core function. It repeatedly calls `blscrapeR::bls_api()` to download all data in a given series for the indicated years. It will download all available years'-worth of data, if no years are provided.

### load_bls_data

`load_bls_data()` is intended as the public interface to `get_bls_data()`. `load_bls_data()` accepts, at a minimum, a file name and a BLS series ID. If the file exists, the function will skip downloading data from the BLS (saving time) and simply load the data from the specified file. If the file does not exist, it will download the data from the BLS and save the data to an R serialized data file using `saveRDS()` under the given filename.

## TODO

* Add a flag to delete any existing file with the given name, and download fresh data.
* Automatically create filenames in `load_bls_data()` given the series name.

## Change Log

1.0.0
: Working version

1.1.0
: BREAKING CHANGE. Changed date conversion; date column is now named `date` instead of `Date`, and dates will be set to first of the month instead of end of the month.

## A Note on Versioning

Versions will be in the form: *X.Y.Z*

X
: Major version. Changes (possibly breaking) in exported function names, output formats.

Y
: Minor version. Changes in internal function handling. Changes will usually be backward-compatible, unless otherwise noted.

Z
: Patch. Used for backward-compatible bug fixes.
