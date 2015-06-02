# nhanes_tools
R code to download NHANES files and merge them into useable data.tables
This is a (hopefully) working version of some scripts that will download NHANES data from the ftp server.  It was tested on a Mac running Yosemite, R 3.1.3, and RStudio 0.99.441.

There are also some files to facilitate merging datasets within a wave together (using data.table, but it could be done with base merge or dplyr).

The ftp download sometimes crashes (due to the FTP server, not the code as far as I know).  If so, you have to delete the entire wave that was in the process of being downloaded and restart.

I would suggest doing 1-3 waves at a time in the loop I wrote.  They take 5-10 minutes each on my computer to download and resave as .rds files, which are compressed by default.  Across all waves they take about 250 MB (compressed size).

The process also saves a file that lists all the files in the FTP directory.
