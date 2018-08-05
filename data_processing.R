## data_processing.R

#-------------------Load suitable libraries for text analysis_______________________________

library(quanteda)
library(readtext)
library(spacyr)
library(quanteda.corpora)
library(quanteda.dictionaries)
library(text2vec)
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

sample_size <- 0.01    # Use 1% of the total as a sample
blogs_index <- sample(seq_len(length(blogs)),length(blogs)*sample_size)
blogs_sample <- blogs[blogs_index[]]
news_index <- sample(seq_len(length(news)),length(news)*sample_size)
news_sample <- blogs[news_index[]]
twitter_index <- sample(seq_len(length(twitter)),length(twitter)*sample_size)
twitter_sample <- twitter[twitter_index[]]

allfiles <- rbind(blogs_sample, news_sample, twitter_sample)

#-----------------------Create a corpus-----------------------------------------------------

blogs_corp <- corpus(blogs_sample)
news_corp <- corpus(news_sample)
twitter_corp <- corpus(twitter_sample)

sample_corp <- corpus(allfiles)
summary(sample_corp)

# Break into sentences
sample_corp <- corpus_reshape(sample_corp, to = "sentences")

# Removes URLs
sample_corp <- gsub("http[^[:space:]]*","", sample_corp) 

#---------------Tokenise to segment text in the corpus by word boundaries-----------------

# Remove separators
mytoks <- tokens(sample_corp, remove_punct = TRUE, remove_twitter = TRUE) # removes white spaces, numbers, punctuation and twitter hashtags
mytoks <- tokens_tolower(mytoks)  # convert to lower case

# Remove profanity
# Profanity filter reference: https://www.freewebheaders.com/full-list-of-bad-words-banned-by-google/
if (!file.exists("./data/profanities.txt")) {
    download.file("https://www.freewebheaders.com/full-list-of-bad-words-banned-by-google/",
                  destfile = "profanities.txt")
}
profanity <- readLines("./data/profanities.txt", encoding = "UTF-8")
profanity_corp <- corpus(profanity)
prof_toks <- tokens(profanity_corp)

clean_toks <- tokens_select(mytoks, prof_toks, selection = 'remove')

ngram <- tokens_ngrams(clean_toks, n = 1:4)
head(ngram[[1]], 50)
tail(ngram[[1]], 50)

# Create a document frequency matrix
capstone_dfm <- dfm(clean_toks)
# Trim the dfm, removing sparse terms
capstone_trim <- dfm_trim(capstone_dfm, min_docfreq = 5)
# Create a Feature Co-Occurence matrix
capstonefcm <- fcm(capstone_trim)

#----------------------Exploratory analysis-------------------------------------------------

feat <- names(topfeatures(capstonefcm, 50))
topcap_fcm <- fcm_select(capstonefcm, feat)
dim(topcap_fcm)

size <- log(colSums(dfm_select(capstone_dfm, feat)))
textplot_network(topcap_fcm, min_freq = 0.8, vertex_size = size / max(size) * 3)

totalWords <- sum(colSums(capstone_dfm)) # Gives total number of words
Top10_words <- topfeatures(capstone_dfm) # Gives top 10 most frequent words



unigram <- tokens_ngrams(mytoks, n = 1)
bigram <- tokens_ngrams(mytoks, n = 2)
trigram <- tokens_ngrams(mytoks, n = 3)
quadgram <- tokens_ngrams(mytoks, n = 4)

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

#---------------------Modelling---------------------------------------------------------


















