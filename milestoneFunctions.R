## milestoneFunctions.R

# Functions for use in the Milestone Report

#-------------------1. Summarising the data----------------------------------------------

# Get the file size
fileSize <- function(x) {
    format(object.size(x),"MB")
}

# Get the number of lines
fileLines <- function(x) {
    stri_stats_general(x)[1]
}

# Get the total number of words
fileWords <- function(x) {
    stri_stats_latex(x)[4]
}

# Get the total number of word characters
fileWordChars <- function(x) {
    stri_stats_latex(x)[1]
}

# Get the average number of characters in a line
fileLineNChars <- function(x) {
    mean(nchar(x))
}

# Get the number of characters in the longest line
fileMaxChars <- function(x) {
    max(nchar(x))
}

# Get the average sentence length
fileSentLen <- function(x) {
    mean(sapply(gregexpr("\\S+", x), length))
}

#-------------------2. Cleaning the data-------------------------------------------------
# Use quanteda functions to tokenise the corpus

# Remove URLs
removeURL <- function(x) {
    gsub("http[^[:space:]]*","",x)
}

profanityFilter <- function(corpusFile) {
    #https://www.freewebheaders.com/full-list-of-bad-words-banned-by-google/
    profanity <- readLines(paste0("data/profanities.txt"))
    lapply(corpusFile, setdiff, y = profanity)
}



























































