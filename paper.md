---
title: A scripted workflow for updating GIS regression mapping models using land use and other predictors of air pollution
author:  
- name: Ivan C. Hanigan
  affilnum: 1,3
  email: ivan.hanigan@sydney.edu.au
  orcid: 0000-0002-6360-6793  
- name: Luke Knibbs 
  affilnum: 2
- name: Christy Geromboux
  affilnum: 1
affiliation:
- affilnum: 1
  affil: The University of Sydney, University Centre for Rural Health, School of Public Health
- affilnum: 2
  affil: The University of Queensland, School of Public Health
- affilnum: 3
  affil: The University of Canberra, Centre for Research and Action in Public Health
output:
  pdf_document:
    fig_caption: yes
    keep_tex: no
    number_sections: yes
    template: tex_components/manuscript.latex
  html_document: null
  word_document: null
fontsize: 11pt
capsize: normalsize
csl: tex_components/meemodified.csl
documentclass: article
classoption: a4paper
spacing: singlespacing
bibliography: paper.bib
---

# Summary

## Introduction

In this study we aimed to develop a scripted workflow to update geographical information system (GIS) regression mapping models that use land use and other predictors. 
GIS regression mapping was first introduced by @Briggs1997 and is a technique commonly used to create predictive spatial models (and spatiotemporal models) of pollutant levels. It is also known as land use regression (LUR), however, the label LUR does not reflect the fact that non-land use predictors are often used such as chemical transport models or remote sensing data (e.g. satellite aerosol optical depth). These models add more information than just land use data to the model as predictor variables. 
Such GIS regression mapping models are used extensively in epidemiological studies of health impacts of air pollution exposure [@Knibbs2014a; @DeHoogh2016; @Pereira2017; @Knibbs2018; @Dirgawati2019; @Cowie2019a].

## Purpose of the software

The updating of a GIS regression model can be conceptualised in five ways. These distinguish between updates that: 

1. create predictions at new locations, using the same regression equation and predictor data
1. predict at the same locations using data for new time periods but use the same regression equation
1. use data for new time periods to develop a new regression equation but keep the same set of candidate predictors
1. use new data and new equations developed with additional candidate predictor variables
1. create predictive models for a new pollutant using the same procedures.

The scripted workflow that we developed provides a set of software tools and a set of method steps that guide a user through the development of a GIS regression mapping model. Depending on the amount of data available models can be updated relatively quickly. In addition the updated models and data are 
well documented and reproducible. 

Primarily we focus on the type of updates that apply a previously developed 
model regression equation to a new set of locations within the same study area. New locations can be
defined by the user or can be based on a dataset containing regularly located points (i.e. a grid) or locations of the participants in a epidemiological study (i.e. exposure estimates). 
We aim to automate most of the process to reduce required efforts from the user. 

Our scripted workflow tools are aimed at GIS specialists and uses the PostGIS and R software environments which are technically sophisticated computing tools. These can be complicated to install and configure so we also provide an online cloud-based virtual desktop environment with these tools pre-configured so that users can develop the updates without having to install the tools on their local computers.  All the software is published as free and open source software. Some of the data inputs require additional data provision agreements to be made between data owners and data users.

We developed a case study based on the methodology used by Knibbs et al. 2014. We also provide links to the protocols developed by the European Study of Cohorts for Air Pollution Effects (ESCAPE) [@Beelen:2013;@Eeftens:2012] as set out in the ESCAPE Exposure assessment manual [@escape]. Within air pollution research the ESCAPE methodology is used as the standard for developing GIS regression mapping models. 

## Current application

The scripted workflow has been developed through the Australian National Health and Medical Research Council (NHMRC) centre of research excellence Centre for Air pollution, energy and health Research (CAR).
CAR is a collaboration between more than 30 researchers from around Australia and internationally in diverse but related disciplines who are at the forefront of their scientific fields. The Centre is based in eight of Australia's most prestigious research institutions. 
The Centre provides an example of a current application for this scripted air pollution prediction models.

# Acknowledgments

TODO 

# References
