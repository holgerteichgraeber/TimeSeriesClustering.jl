---
title: 'TimeSeriesClustering: An extensible framework in Julia'
tags:
  - Julia
  - unsupervised learning
  - representative periods
  - optimization
  - machine learning
  - time series
authors:
  - name: Holger Teichgraeber
    orcid: 0000-0002-4061-2226
    affiliation: 1
  - name: Lucas Elias Kuepper
    orcid: 0000-0002-1992-310X
    affiliation: 1
  - name: Adam R. Brandt
    orcid: 0000-0002-2528-1473
    affiliation: 1
affiliations:
 - name: Department of Energy Resources Engineering, Stanford University
   index: 1
date: 18 August 2019
bibliography: paper.bib
---

# Summary

``TimeSeriesClustering`` is a Julia implementation of unsupervised learning methods for time series datasets. It provides functionality for clustering and aggregating, detecting motifs, and quantifying similarity between time series datasets.
The software provides a type system for temporal data, and provides an implementation of the most commonly used clustering methods and extreme value selection methods for temporal data.
``TimeSeriesClustering`` provides simple integration of multi-dimensional time-series data (e.g. multiple attributes such as wind availability, solar availability, and electricity demand) in a single aggregation process.
The software is applicable to general time series datasets and lends itself well to a multitude of application areas within the field of time series data mining.
``TimeSeriesClustering`` was originally developed to perform time series aggregation for energy systems optimization problems. Because of the software's origin, many of the examples in this work stem from the field of energy systems optimization.

## General package features

The unique design of ``TimeSeriesClustering`` allows for scientific comparison of the performance of different time-series aggregation methods, both in terms of the statistical error measure and in terms of its impact on the application outcome.
The clustering methods that are implemented in ``TimeSeriesClustering`` follow the framework presented by @Teichgraeber:2019, and the extreme value selection methods follow the framework presented by @Lindenmeyer:2019. Using these frameworks allows ``TimeSeriesClustering`` to be generally extensible to new aggregation methods in the future.

The following are the key features that ``TimeSeriesClustering`` provides. Implementation details can be found in the software's documentation.

- *The type system*: The data type (called struct in Julia) ``ClustData`` stores all time-series data in a common format. Besides the data itself, it automatically processes and stores information which are relevant for later use in the application for which the time-series data will be used. The data type ``ClustResult`` additionally stores information relevant for evaluating clustering performance. These data types make ``TimeSeriesClustering`` to be easily integrated with any analysis that relies on iterative evaluation of the clustering and aggregation methods.

- *The aggregation methods*: The most commonly used clustering methods and extreme value selection methods are implemented with a common interface, allowing for simple comparison of these methods on a given data set and optimization problem.

- *The generalized import of time series in csv format*: Time series can be loaded through csv files in a pre-defined format. From this, variable names, which we call attributes, and node names are automatically loaded and stored. The original time series can be sliced into periods of user-defined length. This information can then be used in the definition of the sets of the optimization problem later.

- *Multiple attributes and nodes*: Multiple time series, one for each attribute (and node, if the data has a spatial component), are automatically combined and aggregated simultaneously.

## Package features useful for energy systems optimization

``TimeSeriesClustering`` was originally developed for time-series input data to energy systems optimization problems. In this section, we describe some of its features with respect to their use in energy systems optimization.

In energy systems optimization, the choice of temporal modeling, especially of time-series aggregation methods, can have significant impact on overall optimization outcome, which in the end is used to make policy and business decisions.
It is thus important to not view time-series aggregation and optimization model formulation as two seperate, consecutive steps, but to integrate time-series aggregation into the overall process of building an optimization model in an iterative manner. Because the most commonly used clustering methods and extreme value selection methods are implemented with a common interface, ``TimeSeriesClustering`` allows for this iterative integration in a simple way.

The type system for temporal data provided by ``TimeSeriesClustering`` allows for easy integration with the formulation of optimization problems.
The information stored in the datatype ``ClustData`` such as the number of periods, the number of time steps per period, and the chronology of the periods can be used to formulate the sets of an optimization problem.

``TimeSeriesClustering`` provides two sample optimization problems to illustrate the integration of time-series aggregation and optimization problem formulation through our type system.
However, it is generally thought to be independent of the application at hand, and others are encouraged to use the package as a base for their own optimization problem formulation.
The Julia package [``CapacityExpansion``](https://github.com/YoungFaithful/CapacityExpansion.jl) provides a detailed generation and transmission capacity expansion model built upon ``TimeSeriesClustering``, and illustrates its capabilities in conjunction with a complex optimization problem formulation.

## ``TimeSeriesClustering`` within the broader ecosystem
``TimeSeriesClustering`` is the first package to provide broadly applicable unsupervised learning methods specifically for time series in Julia [@Bezanson:2017].
There are several other related packages that provide useful tools for these tasks, both in Julia and in the general open-source community, and we describe them in order to provide guidance on the broader tools available for these kinds of modeling problems.

The [``Clustering``](https://github.com/JuliaStats/Clustering.jl) package in Julia provides a broad range of clustering methods and and allows computation of clustering validation measures. ``TimeSeriesClustering`` provides a simplified workflow for clustering time series, and works on top of the ``Clustering`` package by making use of a subset of the clustering methods implemented in the ``Clustering`` package.
``TimeSeriesClustering`` has several features that add to the functionality, such as automatically clustering multiple attributes simultaneously and providing multiple initializations for partitional clustering algorithms.

The [``TSML``](https://github.com/IBM/TSML.jl) package in Julia provides processing and machine learning methods for time-series data. Its focus is on time-series data with date and time stamps, and it provides a broad range of processing tools. It integrates with other machine learning libraries within the broader Julia ecoysystem. 

The [``TimeSeries``](https://github.com/JuliaStats/TimeSeries.jl) package in Julia provides a way to store data with time stamps, and perform table opertions and plotting based on time stamps. The ``TimeSeries`` package may be useful for pre-processing or post-processing data in conjunction with ``TimeSeriesClustering``. The main difference is in the way data is stored: In the ``TimeSeries`` package, data is stored based on time stamps. In ``TimeSeriesClustering``, we store data based on index and time step length, which is relevant to clustering and its applications.

In python, clustering and time-series analysis tasks can be performed using packages such as [``scikit-learn``](https://scikit-learn.org/stable/) [@Pedregosa:2011] and [``PyClustering``](https://github.com/annoviko/pyclustering/) [@Novikov:2019].
The package [``tslearn``](https://github.com/rtavenar/tslearn) provides clustering methods specifically for time series, both the conventional k-means method and shape-based methods such as k-shape and dynamic time warping barycenter averaging.
The [``STUMPY``](https://github.com/TDAmeritrade/stumpy) package [@Law:2019] calculates something called the matrix profile, which can be used for many data mining tasks.

In R, time series clustering can be performed using the [``tsclust``](https://cran.r-project.org/web/packages/TSclust/index.html) package [@Montero:2014], and the [``dtw``](http://dtw.r-forge.r-project.org/) package [@Giorgino:2009] provides functionality for dynamic time warping, i.e. when the shape of the time series matters for clustering.

With specific focus on energy systems optimization, time-series aggregation has been included in two open-source packages to date, both in written in Python.
[``TSAM``](https://github.com/FZJ-IEK3-VSA/tsam) [@TSAM] provides an implementation of several time-series aggregation methods in Python.
[``Calliope``](https://github.com/calliope-project/calliope) [@Pfenninger:2018] is a capacity expansion modeling software in Python that includes time-series aggregation for the use case of generation and transmission capacity expansion modeling.
``TimeSeriesClustering`` is the first package to provide time-series aggregation in Julia [@Bezanson:2017].
For energy systems optimization, this is advantageous because it can be used in conjunction with the [``JuMP``](https://github.com/JuliaOpt/JuMP.jl) package [@Dunning:2017] in Julia, which provides an excellent modeling language for optimization problems.
Furthermore, ``TimeSeriesClustering`` includes both clustering and extreme value selection and integrates them into the same output type. This is important in order to retain the characteristics of the time-series that are relevant to many optimization problems.

# Application areas
``TimeSeriesClustering`` is broadly applicable to many fields where time series analysis occurs.
Time-series clustering and aggregation methods alone have applications in the fields of aviation, astronomy, biology, climate, energy, environment, finance, medicine, psychology, robotics, speech recognition, and user analysis [@Liao:2005, @Aghabozorgi:2015].
These methods can be used for time-series representation and indexing, which helps reduce the dimension (i.e. the number of data points) of the original data [@Fu:2011].

Many tasks in time series data mining also fall into the application area of our software [@Fu:2011, @Hebert:2014].
Here, our software can be used to measure similarity between time-series datasets [@Serra:2014].
Closely related is the task of finding time-series motifs [@Lin:2002, @Yankov:2007, @Mueen:2014]. Time-series motifs are pairs of individual time series that are very similar to each other.
This task occurs in many disciplines, for example in finding repeated animal behavior [@Mueen:2013], finding regulatory elements in DNA [@Das:2007], and finding patterns in EEG signals [@Castro:2010].
Another application area of our software is segmentation and clustering of audio datasets [@Siegler:1997, @Lefevre:2011, @Kamper:2017].

In the remainder of this section, we provide an overview of how time-series aggregation applies to input data of optimization problems.

Generally, optimization is concerned with the maximization or minimization of a certain objective subject to a number of constraints. The range of optimization problems ``TimeSeriesClustering`` is applicable to is broad.
They generally fall into the class of design and operations problems, also called planning problems or two-stage optimization problems. In these problems, decisions on two time horizons have to be made: Long-term design decisions, as to what equipment to buy, and short-term operating decisions, as to when to operate that equipment. Because the two time horizons are intertwined, operating decisions impact the system design, and vice versa. Operating decisions are of temporal nature, and the amount of temporal input data for these optimization problems often makes them computationally intractable.
Usually, time series of length $N$ (e.g. hourly electricity demand for one year, where $N=8760$) are split into $\hat{K}$ periods of length $T=\frac{N}{\hat{K}}$ (e.g. $\hat{K}=365$ daily periods, with $T=24$), and each of the $\hat{K}$ periods is treated independently in the operations stage of the optimization problem. Using time-series aggregation methods, we can represent the data with $K < \hat{K}$ periods, which results in reduced computational complexity and improved modeling performance.

Many of the design and operations optimization problems that time-series aggregation has been applied to are in the general domain of energy systems optimization. These problems include generation and transmission capacity expansion problems [@Nahmmacher:2016; @Pfenninger:2017], local energy supply system design problems [@Bahl:2017; @Kotzur:2018], and individual technology design problems [@Brodrick:2017; @Teichgraeber:2017].
Time series of interest in these problems include energy demands (electricity, heating, cooling), electricity prices, wind and solar availability factors, and temperatures.

Many other planning problems in operations research that involve time-varying operations have similar characteristics that make them suitable for time-series aggregation. Some examples are aggregate and detailed production scheduling, job shop design and scheduling, distribution system (warehouse) design and control [@Dempster:1981], and electric vehicle charging station sizing [@Jia:2012].
Time series of interest in these problems include product demands, electricity prices, and electricity demands.
A related class of problems that ``TimeSeriesClustering`` can be useful to is scenario reduction for stochastic programming [@Karuppiah:2010]. Two-stage stochastic programs have similar characteristics to the previously described two-stage problems, and are often computationally intractable due to a large number of scenarios. ``TimeSeriesClustering`` can be used to reduce a large number of scenarios $\hat{K}$ into a computationally tractable number of scenarios $K < \hat{K}$.
Furthermore, ``TimeSeriesClustering`` could be used in operational contexts such as developing operational strategies for typical days, or aggregating repetitive operating conditions for use in model predictive control.
Because it keeps track of the chronology of the periods, it can also be used to calculate transition probabilities between clustered periods for Markov chain modeling.

``TimeSeriesClustering`` has been used in several research projects to date. It has been used to compare both conventionally-used clustering methods and shape-based clustering methods and their characteristics [@Teichgraeber:2019], and also to compare extreme value selection methods [@Lindenmeyer:2019].
It has also been used to analyze temporal modeling detail in energy systems modeling with high renewable energy penetration [@Kuepper:2019].
``TimeSeriesClustering`` also serves as input to [``CapacityExpansion``](https://github.com/YoungFaithful/CapacityExpansion.jl), a scalable capacity expansion model in Julia.
Furthermore, ``TimeSeriesClustering`` has been used as an educational tool. It is frequently used for class projects in the Stanford University course "Optimization of Energy Systems", and has also served as a basis for the capacity expansion studies evaluated in homeworks for the Stanford University course "Advanced Methods in Modeling for Climate and Energy Policy".

# References
