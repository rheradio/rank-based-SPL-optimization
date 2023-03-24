# An R implementation of Nair et al.'s algorithm to find best-performing configurations in a Software Product Line

Implementation of the rank-based algorithm proposed in:

[*Vivek Nair, Tim Menzies, Norbert Siegmund, and Sven Apel. Using Bad
Learners to Find Good Configurations. In 11th Joint Meeting on Foundations
of Software Engineering (ESEC/FSE), page 257–267, Paderborn, Germany,
2017.*](https://dl.acm.org/doi/10.1145/3106237.3106238)

## Motivation

The [original Nair et al.'s implementation](https://github.com/ai-se/Reimplement/tree/cleaned_version) doesn't use a sample of configurations but the whole configuration space. In contrast, the implementation in this repository works with samples (use variable SAMPLE_SIZE in [rank_based_approach.R](https://github.com/rheradio/rank-based-spl-optimization/blob/main/rank_based_approach.R) to change the sample size).

## Usage

Our implementation is written in the [R language](https://www.r-project.org/). 

* [rank_based_approach.R](https://github.com/rheradio/rank-based-spl-optimization/blob/main/rank_based_approach.R) implements Nair et al.'s rank-based approach.
* [uniform_random_sampling.R](https://github.com/rheradio/rank-based-spl-optimization/blob/main/uniform_random_sampling.R) implements an optimization method based on uniform random sampling.
* [run_experiments.R](https://github.com/rheradio/rank-based-spl-optimization/blob/main/run_experiments.R) runs both methods on the SPLs in the [data](https://github.com/rheradio/rank-based-spl-optimization/tree/main/data) directory, and analyze the results.

