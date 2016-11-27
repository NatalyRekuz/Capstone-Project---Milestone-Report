setwd("D:/Coursera/Capstone Project")

library(stringi)
library(devtools)
library(hunspell)
library(tm)
library(SnowballC)
library(openNLP)
library(RWeka)
library(doParallel)
library(dplyr)
library(ggplot2)
library(gridExtra)

# software environment:
sessionInfo()
# R version 3.3.2 (2016-10-31)
# Platform: x86_64-w64-mingw32/x64 (64-bit)
# Running under: Windows >= 8 x64 (build 9200)
# 
# locale:
#     [1] LC_COLLATE=English_United States.1252  LC_CTYPE=English_United States.1252   
# [3] LC_MONETARY=English_United States.1252 LC_NUMERIC=C                          
# [5] LC_TIME=English_United States.1252    
# 
# attached base packages:
#     [1] parallel  stats     graphics  grDevices utils     datasets  methods   base     
# 
# other attached packages:
#     [1] gridExtra_2.2.1   ggplot2_2.2.0     dplyr_0.5.0       doParallel_1.0.10 iterators_1.0.8  
# [6] foreach_1.4.3     RWeka_0.4-29      openNLP_0.2-6     SnowballC_0.5.1   tm_0.6-2         
# [11] NLP_0.1-9         hunspell_2.2      devtools_1.12.0   stringi_1.1.2    
# 
# loaded via a namespace (and not attached):
#     [1] slam_0.1-39         reshape2_1.4.2      splines_3.3.2       rJava_0.9-8        
# [5] lattice_0.20-34     colorspace_1.3-1    testthat_1.0.2      htmltools_0.3.5    
# [9] stats4_3.3.2        yaml_2.1.13         mgcv_1.8-15         ModelMetrics_1.1.0 
# [13] nloptr_1.0.4        DBI_0.5-1           withr_1.0.2         plyr_1.8.4         
# [17] stringr_1.1.0       MatrixModels_0.4-1  munsell_0.4.3       gtable_0.2.0       
# [21] codetools_0.2-15    evaluate_0.10       memoise_1.0.0       labeling_0.3       
# [25] knitr_1.14          RWekajars_3.9.0-1   SparseM_1.74        caret_6.0-72       
# [29] quantreg_5.29       pbkrtest_0.4-6      swirl_2.4.2         Rcpp_0.12.8        
# [33] scales_0.4.1        openNLPdata_1.5.3-2 lme4_1.1-12         digest_0.6.10      
# [37] grid_3.3.2          tools_3.3.2         bitops_1.0-6        magrittr_1.5       
# [41] lazyeval_0.2.0      RCurl_1.95-4.8      tibble_1.2          crayon_1.3.2       
# [45] car_2.1-3           MASS_7.3-45         Matrix_1.2-7.1      rsconnect_0.5      
# [49] assertthat_0.1      minqa_1.2.4         rmarkdown_1.1       httr_1.2.1         
# [53] R6_2.2.0            nnet_7.3-12         nlme_3.1-128   

## Downloading
URL <- "https://d396qusza40orc.cloudfront.net/dsscapstone/dataset/Coursera-SwiftKey.zip"
if(!file.exists("Coursera-SwiftKey.zip")){
    download.file(URL, "Coursera-SwiftKey.zip")
    unzip("Coursera-SwiftKey.zip")
}

blogs_raw <- stri_read_lines("./final/en_US/en_US.blogs.txt")
news_raw <- stri_read_lines("./final/en_US/en_US.news.txt")
twitter_raw <- stri_read_lines("./final/en_US/en_US.twitter.txt")

if(!file.exists("base_info")){
    dir.create("base_info")
}
save(blogs_raw, file = "base_info/blogs_raw.RData")
save(news_raw, file = "base_info/news_raw.RData")
save(twitter_raw, file = "base_info/twitter_raw.RData")

## Number of words (raw data sets)
words_blogs_raw <- stri_count_words(blogs_raw)
words_news_raw <- stri_count_words(news_raw)
words_twitter_raw <- stri_count_words(twitter_raw)

save(words_blogs_raw, file = "base_info/words_blogs_raw.RData")
save(words_news_raw, file = "base_info/words_news_raw.RData")
save(words_twitter_raw, file = "base_info/words_twitter_raw.RData")

## Creating density plot of word counts
wnr <- as.data.frame(words_news_raw)
wbr <- as.data.frame(words_blogs_raw)
wtr <- as.data.frame(words_twitter_raw)
colnames(wnr) <- "news"
colnames(wbr) <- "blogs"
colnames(wtr) <- "twitter"
wnr$count <- seq_along(1:nrow(wnr))
wbr$count <- seq_along(1:nrow(wbr))
wtr$count <- seq_along(1:nrow(wtr))
wntr <- full_join(wnr, wtr, by = "count")
wntbr <- full_join(wntr, wbr, by = "count")
wntbr_g <- gather(wntbr, source, value, -count)

words_density <- ggplot(wntbr_g, aes(x=value)) + geom_density(aes(group=source, colour=source)) + 
    scale_x_log10(breaks = 10^(0:4), labels = 10^(0:4)) +
    labs(x = "Count", y = "Density", title = "Density Plot of Word Counts")
save(wntbr_g, file = "base_info/words_density.RData")


# Table of features for report (raw data)
files_name <- c("Blogs", "News", "Twitter")
files_size <- c(round(file.info("./final/en_US/en_US.blogs.txt")$size/1024^2, 0),
                round(file.info("./final/en_US/en_US.news.txt")$size/1024^2, 0),
                round(file.info("./final/en_US/en_US.twitter.txt")$size/1024^2, 0))
files_lines <- c(length(blogs_raw), length(news_raw), length(twitter_raw))
files_words <- c(sum(words_blogs_raw), sum(words_news_raw), sum(words_twitter_raw))
base_info <- data.frame(files_name, files_size, files_lines, files_words)
colnames(base_info) <- c("Name", "Size (mb)", "Lines", "Words")
base_info

## Sampling
set.seed(5678)
my_number <- rbinom(100000, size = 1, prob = 0.01)

sample_blogs <- blogs_raw[my_number == 1]
sample_news <- news_raw[my_number == 1]
sample_twitter <- twitter_raw[my_number == 1]

if(!file.exists("sampling")){
    dir.create("sampling")
}
save(sample_blogs, file = "sampling/sample_blogs.RData")
save(sample_news, file = "sampling/sample_news.RData")
save(sample_twitter, file = "sampling/sample_twitter.RData")

# Number of words (samples)
words_sample_blogs <- stri_count_words(sample_blogs)
words_sample_news <- stri_count_words(sample_news)
words_sample_twitter <- stri_count_words(sample_twitter)

save(words_sample_blogs, file = "base_info/words_sample_blogs.RData")
save(words_sample_news, file = "base_info/words_sample_news.RData")
save(words_sample_twitter, file = "base_info/words_sample_twitter.RData")

# Table of features for report (samples)
files_name_s <- c("Blogs sample", "News sample", "Twitter sample")
files_size_s <- c(round(file.info("./sampling/sample_blogs.RData")$size, 0),
                round(file.info("./sampling/sample_news.RData")$size, 0),
                round(file.info("./sampling/sample_twitter.RData")$size, 0))
files_lines_s <- c(length(sample_blogs), length(sample_news), length(sample_twitter))
files_words_s <- c(sum(words_sample_blogs), sum(words_sample_news), sum(words_sample_twitter))
base_info_s <- data.frame(files_name_s, files_size_s, files_lines_s, files_words_s)
colnames(base_info_s) <- c("Name", "Size (kb)", "Lines", "Words")
base_info_s

## join three obtained data sets into one common data set
sample_data <- c(sample_blogs, sample_news, sample_twitter)

# The following steps are used to prepare the combined data for the analysis:
transf <- matrix(c(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 
                   'Convert to ASCII',
                   'Convert text to lowercase',
                   'Transform short form of auxiliary verbs ("\'ll" to "will", "don\'t" to 
                   "do not" etc.)',
                   "Remove hashtags & usernames",
                   "Remove retweet objects",
                   "Remove http & ftp addressess",
                   "Remove e-mail addresses",
                   "Remove sequence numbers (e.g., 25th)",
                   "Remove profanity",
                   "Remove punctuation", 
                   "Remove digits",
                   "Remove extra white spaces"),
                 ncol = 2, byrow = FALSE)
colnames(transf) <- c("Order", "Transformation")

### steps from 1 to 3:
sample_data <- iconv(sample_data, to = "ASCII", sub = "")
sample_data <- tolower(sample_data)
sample_data <- gsub("'m", " am", sample_data)
sample_data <- gsub("'ve", " have", sample_data)
sample_data <- gsub("'re", " are", sample_data)
sample_data <- gsub("'ll", " will", sample_data)
sample_data <- gsub("isn't", "is not", sample_data)
sample_data <- gsub("aren't", "are not", sample_data)
sample_data <- gsub("wouldn't", "would not", sample_data)
sample_data <- gsub("can't", "can not", sample_data)
sample_data <- gsub("couldn't", "could not", sample_data)
sample_data <- gsub("doesn't", "does not", sample_data)
sample_data <- gsub("didn't", "did not", sample_data)
sample_data <- gsub("don't", "do not", sample_data)
sample_data <- gsub("shouldn't", "should not", sample_data)
sample_data <- gsub("hasn't", "has not", sample_data)
sample_data <- gsub("haven't", "have not", sample_data)
sample_data <- gsub("hadn't", "had not", sample_data)
sample_data <- gsub("mustn't", "must not", sample_data)
sample_data <- gsub("its", "it is", sample_data)
sample_data <- gsub("it's", "it is", sample_data)
sample_data <- gsub("he's going", "he is going", sample_data)
sample_data <- gsub("she's going", "she is going", sample_data)
sample_data <- gsub("1st", "first", sample_data)
sample_data <- gsub("2nd", "second", sample_data)
sample_data <- gsub("3rd", "third", sample_data)

# Save 
save(sample_data, file = "sampling/sample_data.RData")


## Spelling mistakes
# cluster <- makeCluster(detectCores() - 1) # convention to leave 1 core for OS
# registerDoParallel(cluster)
# spell_mistakes <- hunspell(sample_data)
# stopCluster(cluster) 
# mistakes_vect <- unlist(spell_mistakes)
# tail(sort(table(mistakes_vect)), 50)


### create corpus
cluster <- makeCluster(detectCores() - 1)
registerDoParallel(cluster)

my_corpus_s <- Corpus(VectorSource(sample_data))

stopCluster(cluster)


# The list of profanity can be downloaded from 
# http://www.freewebheaders.com/wordpress/wp-content/uploads/full-list-of-bad-words-banned-by-google-txt-file.zip.

bad_words <- "bad-words-banned-by-google.txt"
profanity <- suppressWarnings(stri_read_lines(bad_words))
profanity <- tolower(stri_trim_both(profanity))

save(profanity, file = "base_info/profanity.RData")

## Function for cleaning corpus
corpusCleaner <- function(corpus) {
    # codingConvert <- content_transformer(function(x) iconv(x, to = "ASCII", sub = ""))
    specialCleaner <- content_transformer(function(x, pattern) gsub(pattern, " ", x))
    x <- corpus
    # x <- tm_map(x, codingConvert)
    # hashtags & usernames
    x <- tm_map(x, specialCleaner, "#\\w+|@\\w+")
    # retweet objects
    x <- tm_map(x, specialCleaner, "(RT |via)((?:\\b\\W*@\\w+)+)")
    # URLs
    x <- tm_map(x, specialCleaner, "(ftp|http)(s?):?//.*\\b")
    # e-mails
    x <- tm_map(x, specialCleaner, "\\b[A-Z a-z 0-9._ - ]*[@](.*?)[.]{1,3} \\b")
    x <- tm_map(x, specialCleaner, "\\d+(th)")
    # x <- tm_map(x, content_transformer(tolower))
    x <- tm_map(x, removeWords, profanity)
    x <- tm_map(x, removePunctuation, preserve_intra_word_dashes = TRUE)
    x <- tm_map(x, removeNumbers)
    x <- tm_map(x, stripWhitespace)
    x
}

# steps from 4 to 12
cluster <- makeCluster(detectCores() - 1)
registerDoParallel(cluster)
corpus_cleaned <- corpusCleaner(my_corpus_s)
stopCluster(cluster)


## Function dtmCreator
dtmCreator <-function(corpus, size) {
    nGramToken <- function(x) NGramTokenizer(x, Weka_control(min = size, max = size))
    cluster <- makeCluster(detectCores() - 1)
    registerDoParallel(cluster)
    dtm_ngram <- DocumentTermMatrix(corpus, control = list(tokenize = nGramToken,
                                                           wordLengths = c(1,Inf)))
    stopCluster(cluster)
    dtm_ngram
}

# document-term matrix based on different ngrams
dtm_unigram <- dtmCreator(corpus_cleaned, 1)
dtm_bigram <- dtmCreator(corpus_cleaned, 2)
dtm_trigram <- dtmCreator(corpus_cleaned, 3)
dtm_fourgram <- dtmCreator(corpus_cleaned, 4)
dtm_fivegram <- dtmCreator(corpus_cleaned, 5)

### Saving dtms
if(!file.exists("ngrams")){
    dir.create("ngrams")
}
save(dtm_unigram, file = "./ngrams/dtm_unigram.RData")
save(dtm_bigram, file = "./ngrams/dtm_bigram.RData")
save(dtm_trigram, file = "./ngrams/dtm_trigram.RData")
save(dtm_fourgram, file = "./ngrams/dtm_fourgram.RData")
save(dtm_fivegram, file = "./ngrams/dtm_fivegram.RData")


### Function dtmToNGram
dtmToNGram <- function(dtm_ngram, rate) {
    sparse_matrix <- removeSparseTerms(dtm_ngram, rate) %>%
        as.matrix %>% as.data.frame
    colnames(sparse_matrix) <- make.names(colnames(sparse_matrix))
    sort_freq <- sort(colSums(sparse_matrix), decreasing = TRUE)
    show_n_gram <- data.frame(term = names(sort_freq), frequency = sort_freq)
    rownames(show_n_gram) <- NULL
    show_n_gram
}

freq_unigram <- dtmToNGram(dtm_unigram, 0.999)
freq_bigram <- dtmToNGram(dtm_bigram, 0.9998)
freq_trigram <- dtmToNGram(dtm_trigram, 0.9998)
freq_fourgram <- dtmToNGram(dtm_fourgram, 0.9999)
freq_fivegram <- dtmToNGram(dtm_fivegram, 0.9999)

##### Saving dtm's frequencies 
save(freq_unigram, file = "./ngrams/freq_unigram.RData")
save(freq_bigram, file = "./ngrams/freq_bigram.RData")
save(freq_trigram, file = "./ngrams/freq_trigram.RData")
save(freq_fourgram, file = "./ngrams/freq_fourgram.RData")
save(freq_fivegram, file = "./ngrams/freq_fivegram.RData")


## Plot n-grams
plot_unigram <- ggplot(freq_unigram[1:20, ], aes(x = reorder(term, frequency), 
                                                 y = frequency, fill = frequency)) + 
    geom_bar(stat="identity") +
    labs(x = "Term", y = "Frequency", title = "Top 20 unigrams") + 
    coord_flip()

plot_bigram <- ggplot(freq_bigram[1:20, ], aes(x = reorder(term, frequency), 
                                               y = frequency, fill = frequency)) + 
    geom_bar(stat="identity") +
    labs(x = "Term", y = "Frequency", title = "Top 20 bigrams") + 
    coord_flip()
grid.arrange(plot_unigram, plot_bigram, ncol = 2)

plot_trigram <- ggplot(freq_trigram[1:20, ], aes(x = reorder(term, frequency), 
                                                 y = frequency, fill = frequency)) + 
    geom_bar(stat="identity") +
    labs(x = "Term", y = "Frequency", title = "Top 20 trigrams") + 
    coord_flip()

plot_fourgram <- ggplot(freq_fourgram[1:20, ], aes(x = reorder(term, frequency), 
                                                   y = frequency, fill = frequency)) + 
    geom_bar(stat="identity") +
    labs(x = "Term", y = "Frequency", title = "Top 20 four-grams") + 
    coord_flip()
grid.arrange(plot_trigram, plot_fourgram, ncol = 2)

plot_fifegram <- ggplot(freq_fivegram[1:30,], aes(x = reorder(term, frequency), 
                                                  y = frequency, fill = frequency)) + 
    geom_bar(stat="identity") +
    labs(x = "Term", y = "Frequency", title="Top 30 five-grams") + 
    coord_flip()
plot_fifegram 


