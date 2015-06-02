library(foreign)
library(RCurl)
library(magrittr)
options(stringsAsFactors = FALSE)

# function to set up directories for downloading
# data_dir is directory on computer in which subdirectories will be made for all nhanes files (must end in "/")
# yr is the first year of the nhanes wave of interest (always odd)
setup_nhanes <- function(data_dir = "./data/raw/", yr = 2009){
    if(!file.exists(data_dir)) stop("data_dir does not exist")
    if(yr < 1999) stop("first year must be 1999 or greater")
    if(yr %% 2 == 0) stop("first year must be odd")
    url <- paste0("ftp://ftp.cdc.gov/pub/Health_Statistics/NCHS/nhanes/", yr, "-", yr + 1, "/") # ftp location of files to download
    diryears <- paste(yr, yr + 1, sep = "_")
    target_dir <- paste0(data_dir, "nhanes_", diryears, "/") # name of subdirectory where downloaded data will be saved
    if(!file.exists(target_dir)) { # creates subdirectory if it doesn't exist
        dir.create(target_dir)
    }
    output <- list(url = url, target_dir = target_dir, years = diryears)
    return(output) # returns needed data elements for later functions
}

# function to return filenames from ftp directory and details of files for later update checking (not implemented yet)
# uses output from setup_nhanes as input
get_filenames <- function(setup) {
    f <- getURL(setup$url, ftp.use.epsv = FALSE, crlf = TRUE) %>%
    strsplit(., "\n") %>%
    unlist %>%
    grep(".xpt$", ., ignore.case = TRUE, value = TRUE) %>%
    strsplit("\\s+") %>%
    do.call(rbind, .) %>% 
    as.data.frame %>%
    .[, 5:9]
names(f) <- c("size", "month", "day", "year", "filename")
saveRDS(f, paste0(setup$target_dir, "download_specs.rds"))
filenames <- f$filename %>% 
    paste0(setup$url, .)
return(filenames)
}

# function to take an ftp url, download to temp file, convert from SAS transport to R, and save data and labels as RDS files in destination directory
read_save <- function(ftp_url, setup) {
    temp <- tempfile()
    download.file(ftp_url, temp, mode = "wb", method = "curl") # "curl" MUCH faster than "auto"
    f <- read.xport(temp) # extracts data file(s)
    l <- lookup.xport(temp) # extracts format information list (may have more than 1 item)
    orig_name <- names(l) %>% 
        tolower %>%
        paste0(., ".rds")
    orig_name_label <- gsub(".rds", "_label.rds", orig_name) # name formats file
    finalname <- paste0(setup$target_dir, orig_name) # full name with path included
    finalname_label <- paste0(setup$target_dir, orig_name_label) # full name with path included
    names(l) <- NULL # removes file name from format list which removes it from variable names when converted to data.frame below
    l <- lapply(l, data.frame) # makes format list a list of dataframes (recycles some vectors like length, headpad, etc)
    names(l) <- orig_name_label
    lapply(1:length(finalname_label), function(i) saveRDS(l[[i]], finalname_label[[i]])) # formats saved using RDS (compressed binary file)
    if(class(f) == "data.frame"){ # determines whether there is a single dataframe or a list of dataframes to save
        saveRDS(f, finalname) # save single file using RDS
    } else {
        lapply(1:length(finalname),   function(i) saveRDS(f[[i]], finalname[[i]])) # data a list of dataframes using RDS for each
    }
}

# Get entire NHANES directory and read into subdirectory as .rds objects
# note:  seems to work better doing this one wave at a time (no loop)
waves <- seq(1999, 2011, 2) # for looping.  2013-2014 is not available yet 
for(wave in waves){ 
    n <- setup_nhanes(data_dir = "./data/raw/", yr = wave)
    filenames <- get_filenames(n)
    for(file in filenames){
        read_save(file, n)
    }
}

# other things that could be done
# convert all variable names in data and label files to lower case? (option - after the fact)
# put data and labels in separate subdirectories? (option - after the fact)
# use Hmisc sas transport read function as an option (includes labels as col attribute)
# convert dates to Date class (probably not needed for nhanes)
# group files by type (exam, lab, diet, etc) (option after the fact -- need to look up groupings somehow (website))
# convert integers from num back to integer (?)
# download documentation file for each file (after the fact?)