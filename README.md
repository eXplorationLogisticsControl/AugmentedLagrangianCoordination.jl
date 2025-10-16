# AugmentedLagrangianCoordination.jl

Julia implementation of Augmented Lagrangian Coordination (ALC)

## Get started

1. Clone this repository and `cd` into it
2. Start julia REPL, enter package mode, and activate package 

```julia
(@v1.10) pkg> activate .
(AugmentedLagrangianCoordination) pkg>
```

3. Test installation & package

```julia
(AugmentedLagrangianCoordination) pkg> test
```

For examples on how to define subproblems to construct the `CoordinatedProblems` struct, see e.g. `Golinski` in [`src/toy/Golinski.jl`](https://github.gatech.edu/SSOG/ALC.jl/blob/main/src/toy/Golinski.jl). 

## References

- S. Tosserams, L. F. P. Etman, P. Y. Papalambros, and J. E. Rooda, “An augmented Lagrangian relaxation for analytical target cascading using the alternating direction method of multipliers,” Structural and Multidisciplinary Optimization, vol. 31, no. 3, pp. 176–189, 2006, doi: [10.1007/s00158-005-0579-0](https://link.springer.com/article/10.1007/s00158-005-0579-0).
- S. Tosserams, L. F. P. Etman, and J. E. Rooda, “An augmented Lagrangian decomposition method for quasi-separable problems in MDO,” Structural and Multidisciplinary Optimization, vol. 34, no. 3, pp. 211–227, 2007, doi: [10.1007/s00158-006-0077-z](https://link.springer.com/article/10.1007/s00158-006-0077-z).
- M. Isaji, Y. Takubo, and K. Ho, “Multidisciplinary Design Optimization Approach to Integrated Space Mission Planning and Spacecraft Design,” Journal of Spacecraft and Rockets, pp. 1–11, 2022, doi: [10.2514/1.A35284](https://arc.aiaa.org/doi/10.2514/1.A35284).
  
