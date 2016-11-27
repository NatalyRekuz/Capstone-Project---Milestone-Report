# Data Science Specialization Capstone Project - Milestone Report
Nataly Rekuz  
November 26, 2016  



## Synopsis

This Milestone Report is the part of Data Science Capstone Project (Coursera / Johns Hopkins University). 

The goal of Data Science Capstone Project is to develop the application that could predict the next word a user will type, based on the probable sequence of words. This is similar to what we can use with most smartphone keyboards: the functionality could be used to suggest the next word to the users and give opportunity to select word instead of typing it by hand.


The goals of the Milestone Report are to demonstrate the working with the data and to determine the direction of creating predictive algorithm.


*According to assignment Milestone Report should be "written in a brief, concise style, in a way that a non-data scientist manager could appreciate", so this report is not overweighted with chunks of code. The data scientists and other interested people could find all files with whole code [here](https://github.com/NatalyRekuz/Data-Science-Specialization-Capstone-Project-Milestone-Report).* 



## Data Processing and Exploratory Data Analysis

The datasets we're working with come from [HC corpora](http://www.corpora.heliohost.org/), which is a collection of corpora for various languages. The corpora are collected from publicly available sources.

The data could be downloaded from the Coursera site [Capstone Dataset](https://d396qusza40orc.cloudfront.net/dsscapstone/dataset/Coursera-SwiftKey.zip) . Datasets were made available in French, German, Russian and English. For this report we use the English datasets.


We're starting with a really large, unstructured database of the English language.
The datasets are analyzed to obtain the general statistics.



### Basic summaries

The R packages we use for this project:


```r
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
```
After downloading data and loading data into R environment we extract the info we are interested in.



Basic summaries of original files are presented in the table below:



|Name    | Size (mb)|   Lines|    Words|
|:-------|---------:|-------:|--------:|
|Blogs   |       200|  899288| 37546246|
|News    |       196| 1010242| 34762395|
|Twitter |       159| 2360148| 30093410|

The density plot below demonstrates the word distribution for three files. For easy perception the log10 scale is used for x-axis of the plot.

<img src="Milestone_Report_files/figure-html/density_plot-1.png" style="display: block; margin: auto;" />


### Sampling and Cleaning Data


#### Sampling

The data sets are fairly large. We need to reduce the time needed for the pre-processing and the obtaining of ngrams, so we'd like to work with the smaller subsets of the data.

We used the `rbinom` function to create 3 separate sub-sample datasets by reading in the random subsets of the original data sets and writing them out to 3 separate files.

Basic summaries of files after sampling are presented in the table below:





|Name           | Size (kb)| Lines|  Words|
|:--------------|---------:|-----:|------:|
|Blogs sample   |    853974|  8346| 345111|
|News sample    |    871438|  9377| 326439|
|Twitter sample |    764008| 21903| 279759|
Then we join three obtained data sets into overall data set.



#### Cleaning Data


The following steps are used to prepare the joint data set for the analysis:



|Order |Transformation                                                                      |
|:-----|:-----------------------------------------------------------------------------------|
|1     |Convert to ASCII                                                                    |
|2     |Convert text to lowercase                                                           |
|3     |Transform short form of auxiliary verbs ("'ll" to "will", "don't" to "do not" etc.) |
|4     |Remove hashtags & usernames                                                         |
|5     |Remove retweet objects                                                              |
|6     |Remove http & ftp addressess                                                        |
|7     |Remove e-mail addresses                                                             |
|8     |Remove sequence numbers (e.g., 25th)                                                |
|9     |Remove profanity                                                                    |
|10    |Remove punctuation                                                                  |
|11    |Remove digits                                                                       |
|12    |Remove extra white spaces                                                           |
The list of profanity can be downloaded from  [List of profanity (zip)](http://www.freewebheaders.com/wordpress/wp-content/uploads/full-list-of-bad-words-banned-by-google-txt-file.zip). These were also locally stored as "bad-words-banned-by-google.txt".


Steps from 1 to 3 were applied directly to the joint data set with base functions. Then the data set has been converted into the corpus and other steps were performed with the functions of `tm` package.


Some types of data transformation don't fit for this project's goals. 
We don't use:

- stemming (the process of reducing inflected (or sometimes derived) words to their word stem, base or root form);

- removing stopwords (most common words of the English language).

These types of transformation could distort info we use and lead to incorrect analysis.



## Creating the Document-Term Matrices


After cleaning data the document-term matrix can be computed. We convert the cleaned text corpus into document-term matrices based on different ngrams.
We built frequency-term matrices for unigram, bigram, trigram, fourgram and fivegram.  





### The Most Frequent N-Grams


The plots below demonstrate the most common N-grams obtained from our cleaned corpus:

<img src="Milestone_Report_files/figure-html/plot_1to4Grams-1.png" style="display: block; margin: auto;" /><img src="Milestone_Report_files/figure-html/plot_1to4Grams-2.png" style="display: block; margin: auto;" /><img src="Milestone_Report_files/figure-html/plot_1to4Grams-3.png" style="display: block; margin: auto;" /><img src="Milestone_Report_files/figure-html/plot_1to4Grams-4.png" style="display: block; margin: auto;" /><img src="Milestone_Report_files/figure-html/plot_1to4Grams-5.png" style="display: block; margin: auto;" />


## Future Work

It is known that currently available predictive text models can run on mobile phones, which typically have limited memory and processing power. We have to take into account the size and speed of prediction model, so we'll investigate applying some additional transformations of data (e.g., determine synonyms, clustering) in order to reduce the size of document-term matrices. 

The prediction model will be based on the n-gram approach. We'll use Markov chains concept in building the model to predict the most likely next word with using the probability matrices. 

We'll estimate the benefits of using different smoothing techniques (Katz's back-off model, Kneser–Ney smoothing etc.) and choose certain one.

The Shiny application should have user-friendly interface. It'll let the user input text and suggest several possible next words.




