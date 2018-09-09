---
title: 'ipc: An R Package for Inter-process Communication'
authors:
- affiliation: '1'
  name: Ian E. Fellows
  orcid: 0000-0003-1261-0925
date: "4 September 2018"
output: pdf_document
bibliography: paper.bib
tags:
- R
- High Performance Computing
- Interactive Visualization
affiliations:
- index: 1
  name: Fellows Statistics
---

# Summary

In computer science, asynchronous processing is critical for performing a wide array of tasks, from high performance computing to web services. Communication between these disparate asynchronous processes is often required. Currently the statistical computing language R provides no built in features to handle interprocess communication. Several packages have been written to handle the passing of text or binary data between processes (e.g. [@txtq], [@liteq], and [@rzmq]).

What is lacking is a framework to easily pass R objects between processes along with an associated signal, and have handler functions automatically execute them in the receiving process. Additionally, it is desirable to have a system that can be backed flexibly either through the file system or a database connection The `ipc` R package aims to fill this void.

For example, one might signal for the execution of an expression in one thread to set a variable `a`.

```
q <- queue()
q$producer$fireEval(a <- 1)
```

Then in another thread, this signal can be processed, resulting in the value `a` being set to 1 in the receiving thread after calling the `consume` method.

```
q$consumer$consume()
```

This package can be applied to high performance computing environments, easily allowing parallel worker processes to communicate partial results or progress to the main thread. Another major use case is to support asynchronous web based user interfaces ([@shiny]) to long running statistical algorithms.


# Acknowledgements

We acknowledge the Center for Disease Control, and in particular Ray Shiraishi for their support in the development of the `ipc` package.

# References
