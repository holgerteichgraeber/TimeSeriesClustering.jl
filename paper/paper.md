---
title: 'ClustForOpt: Time-series aggregation for optimization in Julia'
tags:
  - Julia
  - clustering
  - representative periods
  - optimization
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
date: 5 July 2019
bibliography: paper.bib
---

# Summary

``ClustForOpt`` is an extensible framework for time-series aggregation in Julia. It is designed specifically to perform time series aggregation for energy systems optimization problems, though could be adapated to be used with arbitrary time series datasets. ``ClustForOpt`` provides a type system for temporal data that can easily be integrated with the formulation of optimization problems, and provides an implementation of the most commonly used clustering methods and extreme value selection methods for temporal data. ``ClustForOpt`` provides simple integration of multiple attributes (e.g. wind availability, solar availability, and electricity demand) in a single aggregation process.

The unique design of ``ClustForOpt`` allows for scientific comparison of the performance of different time-series aggregation methods, both in terms of the statistical error measure and in terms of optimization outcome.
The choice of temporal modeling, especially of time-series aggregation methods, can have significant impact on overall optimization outcome, which in the end is used to make policy and business decisions. It is thus important to not view time-series aggregation and optimization model formulation as two seperate, consecutive steps, but to integrate time-series aggregation into the overall process of building an optimization model in an iterative manner. ``ClustForOpt`` allows for this iterative integration in a simple way.

``ClustForOpt`` provides two sample optimization problems to illustrate the integration of time-series aggregation and optimization problem formulation through our type system.
However, it is generally thought to be independent of the application at hand, and others are encouraged to use the package as a base for their own optimization problem formulation.
The Julia package [``CapacityExpansion``](https://github.com/YoungFaithful/CapacityExpansion.jl) provides a detailed generation and transmission capacity expansion model built upon ``ClustForOpt``, and illustrates its capabilities in conjunction with a complex optimization problem formulation.

The clustering methods that are implemented in ``ClustForOpt`` follow the framework presented by @Teichgraeber:2019, and the extreme value selection methods follow the framework presented by @Lindenmeyer:2019. Using these frameworks allows ``ClustForOpt`` to be generally extensible to new aggregation methods in the future.

To the best of our knowledge, time-series aggregation has been included in two open-source packages to date, both in written in Python.
@TSAM provides an implementation of several time-series aggregation methods in Python.
Calliope [@Pfenninger:2018] is a capacity expansion modeling software in Python that includes time-series aggregation for the use case of generation and transmission capacity expansion modeling.

``ClustForOpt`` is the first package to provide time-series aggregation in Julia [@Bezanson:2017]. This is advantageous because it can be used in conjunction with the JuMP [@Dunning:2017] package in Julia, which provides an excellent modeling language for optimization problems. Furthermore, ``ClustForOpt`` includes both clustering and extreme value selection and integrates them into the same output type. This is important in order to retain the characteristics of the time-series that are relevant to many optimization problems.

At this point, we would like to point to the key features that ``ClustForOpt`` provides. Implementation details can be found in the software's documentation.

- *The type system*: The data type (called struct in Julia) ``ClustData`` stores all time-series data in a common format. Besides the data itself, it automatically processes and stores information which are relevant to formulating the sets of the optimization problem later, such as number of periods, the number of time steps per period, and the chronology of the periods. The data type ``ClustResult`` additionally stores information relevant for evaluating clustering performance. These data types make ``ClustForOpt`` to be easily integrated with any optimization problem and analysis.

- *The aggregation methods*: The most commonly used clustering methods and extreme value selection methods are implemented with a common interface, allowing for simple comparison of these methods on a given data set and optimization problem.

- *The generalized import of time series in csv format*: Time series can be loaded through csv files in a pre-defined format. From this, variable names, attributes, and node names are automatically loaded and stored. The original time series can be sliced into periods of user-defined length. This information can then be used in the definition of the sets of the optimization problem later.

- *Multiple attributes and nodes*: Multiple time series, one for each attribute and node, are automatically combined and aggregated simultaneously.

# Application areas

Generally, optimization is concerned with the maximization or minimization of a certain objective subject to a number of constraints. The range of optimization problems ``ClustForOpt`` is applicable to is broad.
They generally fall into the class of design and operations problems, also called planning problems or two-stage optimization problems. In these problems, decisions on two time horizons have to be made: Long-term design decisions, as to what equipment to buy, and short-term operating decisions, as to when to operate that equipment. Because the two time horizons are intertwined, operating decisions impact the system design, and vice versa. Operating decisions are of temporal nature, and the amount of temporal input data for these optimization problems often makes them computationally intractable.
Usually, time series of length $N$ (e.g. hourly electricity demand for one year, where $N=8760$) are split into $\hat{K}$ periods of length $T=\frac{N}{\hat{K}}$ (e.g. $\hat{K}=365$ daily periods, with $T=24$), and each of the $\hat{K}$ periods is treated independently in the operations stage of the optimization problem. Using time-series aggregation methods, we can represent the data with $K < \hat{K}$ periods, which results in reduced computational complexity and improved modeling performance.

Many of the design and operations optimization problems that time-series aggregation has been applied to are in the general domain of energy systems optimization. These problems include generation and transmission capacity expansion problems [@Nahmmacher:2016; @Pfenninger:2017], local energy supply system design problems [@Bahl:2017; @Kotzur:2018], and individual technology design problems [@Brodrick:2017; @Teichgraeber:2017].
Time series of interest in these problems include energy demands (electricity, heating, cooling), electricity prices, wind and solar availability factors, and temperatures.

Many other planning problems in operations research that involve time-varying operations have similar characteristics that make them suitable for time-series aggregation. Some examples are aggregate and detailed production scheduling, job shop design and scheduling, distribution system (warehouse) design and control [@Dempster:1981], and electric vehicle charging station sizing [@Jia:2012].
Time series of interest in these problems include product demands, electricity prices, and electricity demands.
A related class of problems that ``ClustForOpt`` can be useful to is scenario reduction for stochastic programming [@Karuppiah:2010]. Two-stage stochastic programs have similar characteristics to the previously described two-stage problems, and are often computationally intractable due to a large number of scenarios. ``ClustForOpt`` can be used to reduce a large number of scenarios $\hat{K}$ into a computationally tractable number of scenarios $K < \hat{K}$.
Furthermore, ``ClustForOpt`` could be used in operational contexts such as developing operational strategies for typical days, or aggregating repetitive operating conditions for use in model predictive control.
Because it keeps track of the chronology of the periods, it can also be used to calculate transition probabilities between clustered periods for Markov chain modeling.

``ClustForOpt`` has been used in several research projects to date. It has been used to compare both conventionally-used clustering methods and shape-based clustering methods and their characteristics [@Teichgraeber:2019], and also to compare extreme value selection methods [@Lindenmeyer:2019].
It has also been used to analyze temporal modeling detail in energy systems modeling with high renewable energy penetration [@Kuepper:2019].
``ClustForOpt`` also serves as input to [``CapacityExpansion``](https://github.com/YoungFaithful/CapacityExpansion.jl), a scalable capacity expansion model in Julia.
Furthermore, ``ClustForOpt`` has been used as an educational tool. It is frequently used for class projects in the Stanford University course "Optimization of Energy Systems", and has also served as a basis for the capacity expansion studies evaluated in homeworks for the Stanford University course "Advanced Methods in Modeling for Climate and Energy Policy".

# References
