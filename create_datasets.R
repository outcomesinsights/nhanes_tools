library(data.table)
library(magrittr)
options(stringsAsFactors = FALSE)

# f = nhanes file (no suffix -- just main file code like "mcq" and not "mcq_f" or "mcq_f.rds")
# yr = first year of wave, 
# d = location of all of the nhanes data with no "/" at the end
# lab = indicator of whether the label file should be included (if FALSE, then data file will be retrieved)
load_nhanes <- function(f = "", yr, d = "./data/raw/nhanes", lab = FALSE){
    l <- letters[(yr - 1999) / 2 + 1]
    yr_yr <- paste(yr, yr + 1, sep = "_")
    ext <- 
        if(lab == FALSE) {
            ".rds"
        } else {
            "_label.rds"
        }
    f1 <- paste0(d, "_", yr_yr, "/", f, "_", l, ext)
    f2 <- paste0(d, "_", yr_yr, "/", f, ext)
    if(file.exists(f1)) {
        o <- readRDS(f1) 
    } else if(file.exists(f2)) {
        o <- readRDS(f2)
    } else {
        stop(paste0("can't find file called ", f, " - check name and start year to make sure it exists"))
    }
    setDT(o)
    if(lab == TRUE) {
        return(o[, .(name, label)])
    } else {
        return(o)
    }
}

# takes vector of file names, pull them and merges them all by SEQN.  
# automatically loads demo, so no need to include this
load_merge <- function(vec_of_files, yr){
    dt <- load_nhanes("demo", yr)
    setkey(dt, SEQN)
    for(f in vec_of_files){
        y <- load_nhanes(f, yr)
        dt <- merge(dt, y, all.x = TRUE, by = "SEQN")
    }
    return(dt)
}

# creates a data dictionary based on labels files (eventually merge into above function using classes?)
load_labs_merge <- function(vec_of_files, yr){
    vec_of_files <- c("demo", vec_of_files)
    dt <- lapply(vec_of_files, load_nhanes, yr = yr, lab = TRUE)
    dt1 <- rbindlist(dt) %>% 
        .[, .(name, label)] %>% 
        setkey(., name) %>% 
        .[J(unique(name)), mult = "first"] # get rid of multiple SEQN rows
    return(dt1)
}

## example:  load single files
# demographics <- load_nhanes("demo", 2003)
# med_cond_ques <- load_nhanes("mcq", 2003)

# demographics_lab <- load_nhanes("demo", 2003, lab = TRUE) %>% setDT
# med_cond_ques_lab <- load_nhanes("mcq", 2003, lab = TRUE) %>% setDT

## example:  load many files
# listing <- c("mcq", "dex", "hcq", "hiq", "vix", "uc") # demo is assumed
# full <- load_merge(listing, 2003) # open all datasets and merge together by SEQN
# full_labs <- load_labs_merge(listing, 2003) # open all label datasets and stack them

