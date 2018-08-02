## Data Processing for Capstone Project - Milestone Report

## General steps in this process   
# 1. Summarize the objective,
# 2. Describe the inputs and outputs,
# 3. Generate a list of working assumptions to guide subsequent design decisions,
# 4. Use information from the preceding steps to develop a design, and
# 5. Develop the function prototype, coding the design steps as comments into the function prototype.

# Once you decide how to clean and tokenize the corpus 
# (e.g. do you break it into sentences? how do you handle stop words? etc.), 
# you can proceed directly to build various sizes of n-grams with the tokens_ngrams() function.

# The general process is:

#   Load data from text files
#   Summarise data
#   Create a sample set
#   Generate corpus
#   Clean / transform the corpus
#   Generate n-grams & write to output files
#   Aggregate n-gram files to get frequencies by n-gram
#   Break n-grams into "base" and "prediction"
#   At this point you have the inputs you need for a prediction algorithm.

## Task 0 - Understanding the Problem
# Obtaining the data - Can you download the data and load/manipulate it in R?
# Familiarizing yourself with NLP and text mining 
# Learn about the basics of natural language processing and how it relates to the data science process you have learned in the Data Science Specialization.

# Questions to consider

# What do the data look like?
# Where do the data come from?
# Can you think of any other data sources that might help you in this project?
# What are the common steps in natural language processing?
# What are some common issues in the analysis of text data?
# What is the relationship between NLP and the concepts you have learned in the Specialization?

## Task 1 - Getting and cleaning the data

# Tokenization - identifying appropriate tokens such as words, punctuation, and numbers. Writing a function that takes a file as input and returns a tokenized version of it.
# Profanity filtering - removing profanity and other words you do not want to predict.
# Take the file and return a tokenized version of it.


## Task 2 - Exploratory Data Analysis

# Exploratory analysis - perform a thorough exploratory analysis of the data, understanding the distribution of words and relationship between the words in the corpora.
# Understand frequencies of words and word pairs - build figures and tables to understand variation in the frequencies of words and word pairs in the data.

# Questions to consider

# Some words are more frequent than others - what are the distributions of word frequencies?
# What are the frequencies of 2-grams and 3-grams in the dataset?
# How many unique words do you need in a frequency sorted dictionary to cover 50% of all word instances in the language? 90%?
# How do you evaluate how many of the words come from foreign languages?
# Can you think of a way to increase the coverage -- identifying words that may not be in the corpora or using a smaller number of words in the dictionary to cover the same number of phrases?


## Task 3 - Modeling (not needed for the Milestone Report, but will be necessary for the final project submission)

# Build basic n-gram model - using the exploratory analysis you performed, build a basic n-gram model for predicting the next word based on the previous 1, 2, or 3 words.
# Build a model to handle unseen n-grams - in some cases people will want to type a combination of words that does not appear in the corpora. Build a model to handle cases where a particular n-gram isn't observed.

# Questions to consider

# How can you efficiently store an n-gram model (think Markov Chains)?
# How can you use the knowledge about word frequencies to make your model smaller and more efficient?
# How many parameters do you need (i.e. how big is n in your n-gram model)?
# Can you think of simple ways to "smooth" the probabilities (think about giving all n-grams a non-zero probability even if they aren't observed in the data) ?
# How do you evaluate whether your model is any good?
# How can you use backoff models to estimate the probability of unobserved n-grams?


#-------------------Load suitable libraries for text analysis_______________________________

library(quanteda)
library(readtext)
library(spacyr)
library(quanteda.corpora)
library(quanteda.dictionaries)
library(stopwords)
library(stringi)
library(tm)
library(DT)
library(data.table)
library(dplyr)
library(ggplot2)
library(wordcloud)
library(knitr)
library(scales)
#--------------------Load data from text files--------------------------------------------------

#   Create folder for all the data
if (!file.exists("./data")) {  
    dir.create("data")   
}

if(!file.exists("Coursera-SwiftKey.zip")){
    download.file("https://d396qusza40orc.cloudfront.net/dsscapstone/dataset/Coursera-SwiftKey.zip", "Coursera-SwiftKey.zip")
    unzip("Coursera-SwiftKey.zip")
}
blogs <- readLines("./data/final/en_US/en_US.blogs.txt", warn = FALSE, encoding = "UTF-8")
news <- readLines("./data/final/en_US/en_US.news.txt", warn = FALSE, encoding = "UTF-8")
twitter <- readLines("./data/final/en_US/en_US.twitter.txt", warn = FALSE, encoding = "UTF-8")

#-------------------Summarise data----------------------------------------------------

# Get some basic details of the files (size, word counts, line counts and basic data tables)

df <- data.frame(File = c("Blogs", "News", "Twitter"),
                 Size = sapply(list(blogs, news, twitter), function(x) {
                     format(object.size(x),"MB")
                 }),
                 Lines = sapply(list(blogs, news, twitter), function(x) {
                     stri_stats_general(x)[1]
                 }),
                 Words = sapply(list(blogs, news, twitter), function(x) {
                     stri_stats_latex(x)[4]
                 }),
                 Word_Characters = sapply(list(blogs, news, twitter), function(x) {
                     stri_stats_latex(x)[1]
                 }),
                 Avg_Characters = sapply(list(blogs, news, twitter), function(x) {
                     format(round(mean(nchar(x))))
                 }),
                 Max_Characters = sapply(list(blogs, news, twitter), function(x) {
                     max(nchar(x))
                 }),
                 AvgSentenceLength = sapply(list(blogs, news, twitter), function(x) {
                     format(round(mean(sapply(gregexpr("\\S+", x), length))))
                 })
                 )


#------------------------Create a sample data set-------------------------------------------

set.seed(091996)

sample_size <- 0.05
blogs_index <- sample(seq_len(length(blogs)),length(blogs)*sample_size)
blogs_sample <- blogs[blogs_index[]]
news_index <- sample(seq_len(length(news)),length(news)*sample_size)
news_sample <- blogs[news_index[]]
twitter_index <- sample(seq_len(length(twitter)),length(twitter)*sample_size)
twitter_sample <- twitter[twitter_index[]]

allfiles <- rbind(blogs_sample, news_sample, twitter_sample)

#-----------------------Create a corpus-----------------------------------------------------

sample_corp <- corpus(allfiles)
summary(sample_corp)

blogs_corp <- corpus(blogs_sample)
news_corp <- corpus(news_sample)
twitter_corp <- corpus(twitter_sample)


# Remove profanity
# Profanity filter reference: https://www.freewebheaders.com/full-list-of-bad-words-banned-by-google/
if (!file.exists("./data/profanities.txt")) {
    download.file("https://www.freewebheaders.com/full-list-of-bad-words-banned-by-google/",
                  destfile = "profanities.txt")
}
profanity <- readLines("./data/profanities.txt")

# Break into sentences
allSentCorp <- corpus_reshape(sample_corp, to = "sentences")

# Removes URLs
no_url <- gsub("http[^[:space:]]*","", allSentCorp) 

# Remove separators
toks <- tokens(no_url, remove_punct = TRUE, remove_twitter = TRUE) # removes white spaces, numbers, punctuation and twitter hashtags



#----------------------Exploratory analysis-------------------------------------------------

ngram <- tokens_ngrams(toks, n = 1:3)
head(ngram[[1]], 50)
tail(ngram[[1]], 50)

capstone_dfm <- dfm(toks)

totalWords <- sum(colSums(capstone_dfm)) # Gives total number of words
Top10_words <- topfeatures(capstone_dfm) # Gives top 10 most frequent words



unigram <- tokens_ngrams(toks, n = 1)
bigram <- tokens_ngrams(toks, n = 2)
trigram <- tokens_ngrams(toks, n = 3)
quadgram <- tokens_ngrams(toks, n = 4)

unigram_dfm <- dfm(unigram)
bigram_dfm <- dfm(bigram)
trigram_dfm <- dfm(trigram)
quadgram_dfm <- dfm(quadgram)


#----------------------Plots----------------------------------------------------------------

# Plot 1 Unigram
top30uni <- topfeatures(unigram_dfm, 30)
top30uni <- sort(top30uni, decreasing = FALSE)
uni_df <- data.frame(words = names(top30uni), freq = top30uni)
plot1 <- ggplot(data = uni_df, aes(x = factor(words, levels = words), y = freq)) + 
    geom_bar(stat = "identity", position = position_dodge()) +
    theme_minimal() +
    labs(x = "Unigram", y = expression("Frequency")) +
    labs(title = expression("Frequency of single words")) +
    coord_flip() +
    guides(fill=FALSE) 
plot(plot1)

# Plot 2 Bigram
top30bi <- topfeatures(bigram_dfm, 30)
top30bi <- sort(top30bi, decreasing = FALSE)
bi_df <- data.frame(words = names(top30bi), freq = top30bi)
plot2 <- ggplot(data = bi_df, aes(x = factor(words, levels = words), y = freq)) + 
    geom_bar(stat = "identity", position = position_dodge()) +
    theme_minimal() +
    labs(x = "Bigram", y = expression("Frequency")) +
    labs(title = expression("Frequency of 2 word sequences")) +
    coord_flip() +
    guides(fill=FALSE) 
plot(plot2)

# Plot 3 Trigram
top30tri <- topfeatures(trigram_dfm, 30)
top30tri <- sort(top30tri, decreasing = FALSE)
tri_df <- data.frame(words = names(top30tri), freq = top30tri)
plot3 <- ggplot(data = tri_df, aes(x = factor(words, levels = words), y = freq)) + 
    geom_bar(stat = "identity", position = position_dodge()) +
    theme_minimal() +
    labs(x = "Trigram", y = expression("Frequency")) +
    labs(title = expression("Frequency of 3 word sequences")) +
    coord_flip() +
    guides(fill=FALSE) 
plot(plot3)

# Plot 4 Quadgram
top30quad <- topfeatures(quadgram_dfm, 30)
top30quad <- sort(top30quad, decreasing = FALSE)
quad_df <- data.frame(words = names(top30quad), freq = top30quad)
plot4 <- ggplot(data = quad_df, aes(x = factor(words, levels = words), y = freq)) + 
    geom_bar(stat = "identity", position = position_dodge()) +
    theme_minimal() +
    labs(x = "Quadgram", y = expression("Frequency")) +
    labs(title = expression("Frequency of 4 word sequences")) +
    coord_flip() +
    guides(fill=FALSE) 
plot(plot4)

# Coverage
freqWords <- topfeatures(capstone_dfm, totalWords) 

cover <- topfeatures(unigram_dfm, length(unigram_dfm))
df2 <- data.frame(cover)
df2$n <- c(1:nrow(df2))
df2$total <- cumsum(df2$cover)

















