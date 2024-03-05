# Website sources for Applied Machine Learning for Tabular Data

Welcome! This is a work in progress. We want to create a practical guide to developing quality predictive models from tabular data. We'll publish materials here as we create them and welcome community contributions in the form of discussions, suggestions, and edits. 

We also want these materials to be reusable and open. The sources are in the source [GitHub repository](https://github.com/aml4td/website) with a Creative Commons license attached (see below).

Our intention is to write these materials and, when we feel we're done, pick a publishing partner to produce a print version.

The book takes a holistic view of the predictive modeling process and focuses on a few areas that are usually left out of similar works. For example, the effectiveness of the model can be driven by how the predictors are represented.  Because of this, we tightly couple feature engineering methods with machine learning models.  Also, quite a lot of work happens after we have determined our best model and created the final fit.  These post-modeling activities are an important part of the model development process and will be described in detail. 

To cite this work, we suggest: 

```bib
@online{aml4td,
  Author = {Kuhn, M and Johnson, K},
  title = {{Applied Machine Learning for Tabular Data}},
  year = {2023},
  url = { https://aml4td.org},
  urldate = {2023-11-20}
}
```

## License

<a rel="license" href="http://creativecommons.org/licenses/by-nc-sa/4.0/"><img alt="Creative Commons License" style="border-width:0" src="premade/cc-by-nc-sa.png" /></a>

This work is licensed under a [Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License](http://creativecommons.org/licenses/by-nc-sa/4.0/"). Our goal is to have an open book where people can reuse and reference the materials but can't just put their names on them and resell them (without our permission). 

## Intended Audience

Our intended audience includes data analysts of many types: statisticians, data scientists, professors and instructors of machine learning courses, laboratory scientists, and anyone else who desires to understand how to create a model for prediction.  We don't expect readers to be experts in these methods or the math behind them. Instead, our approach throughout this work is applied.  That is, we want readers to use this material to build intuition about the predictive modeling process.  What are good and bad ideas for the modeling process?  What pitfalls should we look out for?  How can we be confident that the model will be predictive for new samples?  What are advantages and disadvantages of different types of models?  These are just some of the questions that this work will address.

Some background in modeling and statistics will be extremely useful. Having seen or used basic regression models is good, and an understanding of basic statistical concepts such as variance, correlation, populations, samples, etc., is needed.  There will also be some mathematical notation, so you'll need to be able to grasp these abstractions.  But we will keep this to those parts where it is absolutely necessary.  There are a few more statistically sophisticated sections for some of the more advanced topics. 

If you would like a more theoretical treatment of machine learning models, then we recommend Hastie et al. (2017). Other books for gaining a more in-depth understanding of machine learning are Bishop and Nasrabadi (2006), Arnold et al. (2019) and, for more of a deep learning focus, Goodfellow et al. (2016).

## Is there code? 

We definitely want to decouple the content of this work from specific software. [One of our other books](http://appliedpredictivemodeling.com/) on modeling had computing sections. Many people found these sections to be a useful resource at the time of the book's publication. However, code can quickly become outdated in today's computational environment.  In addition, this information takes up a lot of page space that would be better used for other topics.

We will create _computing supplements_ to go along with the materials. Since we use R's tidymodels framework for calculations, the supplement currently in-progress is:  

- [`tidymodels.aml4td.org`](https://tidymodels.aml4td.org)

If you are interested in working on a python/scikit-learn supplement, please [file an issue](https://github.com//aml4td/website/issues)  

## Are there exercises?

Many readers found the Exercise sections of _Applied Predictive Modeling_ to be helpful for solidifying the concepts presented in each chapter. The current set can be found at [`exercises.aml4td.org`](https://exercises.aml4td.org)

## How can I ask questions? 

If you have questions about the content, it is probably best to ask on a public forum, like [cross-validated](https://stats.stackexchange.com/). You'll most likely get a faster answer there if you take the time to ask the questions in the best way possible.   

If you want a direct answer from us, you should follow what I call [_Yihui's Rule_](https://yihui.org/en/2017/08/so-gh-email/): add an issue to GitHub (labeled as "Discussion") first. It may take some time for us to get back to you. 

If you think there is a bug, please [file an issue](https://github.com//aml4td/website/issues). 

## Can I contribute? 

There is a [contributing page](https://github.com/aml4td/website/blob/main/chapters/contributing.qmd) with details on how to get up and running to compile the materials (there are a lot of software dependencies) and suggestions on how to help. 

If you just want to fix a typo, you can make a pull request to alter the appropriate `.qmd` file. 

Please feel free to improve the quality of this content by submitting **pull requests**. A merged PR will make you appear in the contributor list. It will, however, be considered a donation of your work to this project. You are still bound by the conditions of the license, meaning that you are **not considered an author, copyright holder, or owner** of the content once it has been merged in.
