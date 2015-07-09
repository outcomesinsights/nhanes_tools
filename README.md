# nhanes_tools
R code to download NHANES files from 1999 and later, and store them as .rds files in a data directory on your computer.  There are also some simple utilities to merge selected files into useable data.tables.  

This is a (hopefully) working version of some scripts that will download NHANES data from the CDC's ftp server, including the mortality files.  It was tested on a Mac running Yosemite, R 3.1.3, and RStudio 0.99.447.

Note that the utilities to merge files use data.table, but the process could be done with base merge or dplyr.

The ftp download sometimes crashes (due to the FTP server, not the code as far as I know).  If that happens, you have to delete the entire wave that was in the process of being downloaded and restart.  I will add some "try-catch" functionality to retry downloading and address some of these issues.

I would suggest doing 1-3 waves at a time in the loop I wrote.  Single waves take 5-10 minutes each on my computer to download and resave as .rds files, which are compressed by default.  Across all waves they take about 250 MB (compressed size) on your hard drive.

The process also saves a file that lists all the files in the FTP directory.  This listing, and the download process itself, only works on .xpt files and a fixed-width file (.dat) for the death data.  There are some .txt files in the directory that are ignored.  

## Other Resources  
There are some excellent resources for downloading and using NHANES data.  

1. Anthony Damico has a very comprehensive site on working with many public use datasets including NHANES at http://www.asdfree.com  
2. The NHANES site itself contains R code as well.  http://www.cdc.gov/nchs/tutorials/Nhanes/Downloads/intro.htm  
3. There are other NHANES repositories if you use GitHub's search function on "nhanes".  One that seems very good is here:  https://github.com/cjendres1/nhanes  

## About Outcomes Insights, Inc.
Outcomes Insights is a small, specialized consulting company with expertise in manipulating and analyzing electronic health data.  One of our goals is to provide tools to help other researchers conduct reproducible research more quicky and accurately.  These tools are intended help with those goals.
