library(foreign)
library(RCurl)
library(downloader)
library(magrittr)
library(readr)
options(stringsAsFactors = FALSE)

# function to set up directories for downloading
# data_dir is directory on computer in which subdirectories will be made for all nhanes files (can end in "/" on Mac but CANNOT on Windows)
# yr is the first year of the nhanes wave of interest (always odd)
setup_nhanes <- function(data_dir = "./data/", yr = 2009){
    if(!file.exists(data_dir)) stop("The data_dir you provided does not exist or the syntax is wrong.  On Unix/Mac you can use a slash at the end, but on Windows you cannot use the slash.")
    data_dir <- normalizePath(path.expand(data_dir), winslash = "/")
    if(!yr %in% seq(1999, 2011, 2)) stop("first year must be an odd number from 1999 to 2011")
    data_url <- paste0("ftp://ftp.cdc.gov/pub/Health_Statistics/NCHS/nhanes/", yr, "-", yr + 1, "/") # ftp location of data files to download
    death_url <- paste0("ftp://ftp.cdc.gov/pub/Health_Statistics/NCHS/datalinkage/linked_mortality/") # ftp location of death files to download
    diryears <- paste(yr, yr + 1, sep = "_")
    target_dir <- paste0(data_dir, "/nhanes_", diryears, "/") # name of subdirectory where downloaded data will be saved
    dir.create(target_dir, showWarnings = FALSE) # suppress warning if directory already exists
    output <- list(data_url = data_url, death_url = death_url, target_dir = target_dir, years = diryears)
    return(output) # returns needed data elements for later functions
}

# function to return filenames from ftp directory and details of files for later update checking (not implemented yet)
# uses output from setup_nhanes as input
# string is using grepl on filename
# getURL syntax from RCurl package example
.get_filenames <- function(dir_url, select = "") {
    f <- 
        getURL(dir_url, ftp.use.epsv = FALSE, crlf = TRUE) %>%
        strsplit(., "\r*\n") %>%
        unlist %>%
        grep(select, ., ignore.case = TRUE, value = TRUE)
    if(length(f) == 0) {
        f <- NULL
        return(f)
    } else {
        f <- 
            strsplit(f, "\\s+") %>%
            do.call(rbind, .) %>% 
            as.data.frame %>%
            .[, 5:9]
        names(f) <- c("size", "month", "day", "year", "filename")
        return(f)
    }
}

# function to get data files and death files
get_nhanes_filenames <- function(setup, save_file_list = TRUE){
    f_data <-  .get_filenames(setup$data_url, select = ".xpt$")
    f_death <- .get_filenames(setup$death_url, select = paste0("NHANES_", setup$years))
    if(save_file_list){
        f1 <- rbind(f_data, f_death)
        saveRDS(f1, paste0(setup$target_dir, "download_file_specs.rds"))
    }
    filenames_data <- 
        f_data$filename %>% 
        paste0(setup$data_url, .)
    filenames_death <- 
        if(length(f_death) == 0) {
            NULL
        } else {
            f_death$filename %>% 
            paste0(setup$death_url, .)
        }
    filenames <- 
        c(filenames_data, filenames_death)
    return(filenames)
}

# function to take an ftp url, download to temp file, convert from SAS transport to R, and save data and labels as RDS files in destination directory
# set console to FALSE if running parallel
.read_save_xpt <- function(ftp_url, setup, console = TRUE) {
    if(console) {
        message("Loading wave = ", setup$years, ", file = ", basename(ftp_url), appendLF = FALSE) 
    }
    temp <- tempfile()
    .try_download(ftp_url, temp, mode = "wb", quiet = TRUE) # "curl" MUCH faster than "auto"
    f <- read.xport(temp) # extracts data file(s)
    l <- lookup.xport(temp) # extracts format information list (may have more than 1 item)
    orig_name <- 
        names(l) %>% 
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
    if(console) {
        message("Completed. File count: ", length(finalname))
    } else {
        r <- paste0("Completed:  ", basename(ftp_url), "File count:  ", length(finalname))
        return(r)
    }
}

# function to download associated death file for specific NHANES year
# set console to false if running parallel
.read_save_fwf <- function(ftp_url, setup, console = TRUE){
    if(console){
        message("Loading wave = ", setup$years, ", death file = ", basename(ftp_url), appendLF = FALSE) 
    }
    s <- .create_death_specs()
    temp <- tempfile()
    .try_download(ftp_url, temp, quiet = TRUE)
    dat <- read_fwf(temp, fwf_positions(s$fwf$start, s$fwf$end, col_names = s$fwf$var), col_types = paste0(s$fwf$type, collapse = ""), na = ".")
    filename_data <- paste0(setup$target_dir, "death.rds")
    filename_labs <- paste0(setup$target_dir, "death_label.rds")
    saveRDS(dat, filename_data)
    saveRDS(s$labs, filename_labs)
    if(console) {
        message("Completed loading death file.\n")
    } else {
        r <- paste0("Completed:  ", basename(filename_data))
        return(r)
    }
}

# handles errors and warnings in the download process
# source:  http://stackoverflow.com/questions/12193779/how-to-write-trycatch-in-r
# ... used to pass options to download.file
.try_download <- function(link, dest, times = 5, warn_msg = "There was a warning!", err_msg = "There was an error!", fin_msg = NULL, ...){
    check <- 1
    while(check <= times & check > 0) {
        check <- check + 
            tryCatch(
            {
                download(link, dest, ...)
                return(-check)
            },
            warning = function(cond) {
                if(!is.null(warn_msg)){
                    message(warn_msg)
                    message(cond)
                    message("\nAttempt = ", check)
                }
                return(1)
            },
            error = function(cond) {
                if(!is.null(err_msg)){
                    message(err_msg)
                    message(cond)
                    message("\nAttempt = ", check)
                }
                return(1)
            },
            finally = {
                message(fin_msg)
            })
    }
    invisible(check - 1)
}

# function to decide which read function to use
download_nhanes <- function(ftp_url, setup, ...){
    if(grepl(".xpt$", ftp_url, ignore.case = TRUE)){
        .read_save_xpt(ftp_url, setup, ...)
    } else if(grepl(".dat$", ftp_url, ignore.case = TRUE)){
        .read_save_fwf(ftp_url, setup, ...)
    } else {
        stop("file to be downloaded does not end in .xpt or .dat")
    }
}

# creates information for loading death data and labels
.create_death_specs <- function() {
    list(
        fwf = 
            rbind(
                data.frame(var = "SEQN",          start =  1, end =  5, type = "i"),
                data.frame(var = "ELIGSTAT",      start = 15, end = 15, type = "i"),
                data.frame(var = "MORTSTAT",      start = 16, end = 16, type = "i"),
                data.frame(var = "CAUSEAVL",      start = 17, end = 17, type = "i"),
                data.frame(var = "UCOD_LEADING",  start = 18, end = 20, type = "c"),
                data.frame(var = "DIABETES",      start = 21, end = 21, type = "i"),
                data.frame(var = "HYPERTEN",      start = 22, end = 22, type = "i"),
                data.frame(var = "PERMTH_INT",    start = 44, end = 46, type = "i"),
                data.frame(var = "PERMTH_EXM",    start = 47, end = 49, type = "i"),
                data.frame(var = "MORTSRCE_NDI",  start = 50, end = 50, type = "i"),
                data.frame(var = "MORTSRCE_CMS",  start = 51, end = 51, type = "i"),
                data.frame(var = "MORTSRCE_SSA",  start = 52, end = 52, type = "i"),
                data.frame(var = "MORTSRCE_DC",   start = 53, end = 53, type = "i"),
                data.frame(var = "MORTSRCE_DCL",  start = 54, end = 54, type = "i")
            ),
        labs = 
            rbind(
            	data.frame(name = "SEQN",          label =	'NHANES Respondent Sequence Number'),
            	data.frame(name = "ELIGSTAT",      label =	'Eligibility Status for Mortality Follow-up'),
            	data.frame(name = "MORTSTAT",      label =	'Final Mortality Status'),
            	data.frame(name = "CAUSEAVL",      label =	'Cause of Death Data Available'),
            	data.frame(name = "UCOD_LEADING",  label =	'Underlying Cause of Death Recode from UCOD_113 Leading Causes'),
            	data.frame(name = "DIABETES",      label =	'Diabetes flag from multiple cause of death'),
            	data.frame(name = "HYPERTEN",      label =	'Hypertension flag from multiple cause of death'),
            	data.frame(name = "PERMTH_INT",    label =	'Person Months of Follow-up from Interview Date'),
            	data.frame(name = "PERMTH_EXM",    label =	'Person Months of Follow-up from MEC/Exam Date'),
            	data.frame(name = "MORTSRCE_NDI",  label =	'Mortality Source: NDI Match'),
            	data.frame(name = "MORTSRCE_CMS",  label =	'Mortality Source: CMS Information'),
            	data.frame(name = "MORTSRCE_SSA",  label =	'Mortality Source: SSA Information'),
            	data.frame(name = "MORTSRCE_DC",   label =	'Mortality Source: Death Certificate Match'),
            	data.frame(name = "MORTSRCE_DCL",  label =	'Mortality Source: Data Collection')
            )
    )
}

# EXAMPLES:
# Get entire NHANES directory and read into subdirectory as .rds objects
# Note:  may work better doing this one or two waves at a time
# waves <- seq(1999, 2011, 2)
# for(wave in waves[1:7]){
#     cat("Starting wave: ", wave, "\n")
#     n <- setup_nhanes(data_dir = "./data/raw/", yr = wave)
#     filenames <- get_nhanes_filenames(n)
#     for(file in filenames){
#         download_nhanes(file, n)
#     }
#     cat("Finished wave: ", wave, "\n")
# }

# This version downloads files in parallel.  Not quite twice as fast (on my computer)
# Returns a list of completed files at the end.  Set console = FALSE in above functions
# library(foreach)
# library(doMC) # use library(doSNOW) on Windows
# 
# registerDoMC(cores = 4) # set number of cores for your computer here
# foreach(file = filenames, .packages = c("foreign", "downloader"), .combine = rbind) %dopar% {
#     download_nhanes(file, n, console = FALSE)
# }

# TO DO
# other things that could be done
# convert all variable names in data and label files to lower case? (option - after the fact)
# put data and labels in separate subdirectories? (option - after the fact)
# use Hmisc sas transport read function as an option (includes labels as col attribute)
# convert dates to Date class (probably not needed for nhanes)
# group files by type (exam, lab, diet, etc) (option after the fact -- need to look up groupings somehow (website))
# convert integers from num back to integer (?)
# download documentation file for each file (after the fact?)