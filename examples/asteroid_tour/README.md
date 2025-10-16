# Asteroid tour design

## Problem description

We consider a set $\mathcal{A} = \{a_1, \ldots, a_N\}$ of $N$ asteroids, and we seek a tour that visits (at most?) $K \leq N$ asteroids. Let $i = 1,\ldots,N$ denote the index of asteroids, and $k = 1,\ldots,K$ denote the index of the visit.
We expect $N$ to be on the order of 100s ~ 1000s, and $K$ to be on the order of 10s. 
We define the visit sequence matrix variables $X \in \mathbb{B}^{N \times K}$ such that

$$
X_{ik} = 
\begin{cases}
    1 & \text{asteroid $i$ is the spacecraft's $k$-th visit} \\
    0 & \text{otherwise}
\end{cases}
$$

We also introduce the encounter times variables $\Delta t \in \mathbb{R}^{K-1}$, such that the $k$-th visit to the corresonding asteroid occurs at time $t_k$ given by

$$
t_k = t_0 + \sum_{\tau = 1}^{k-1} \Delta t_{\tau}
$$

where $t_0$ is the initial departure epoch from Earth. (We could make $t_k$ a variable itself, but that would require an additional constraint to ensure the vector $t$ is monotonic). 

### Length-K sequence design problem

The length-$K$ asteroid tour MINLP is given by

$$
\begin{align}
    \min_{X, \Delta t} \quad& \sum_{k=1}^{K-1} \Delta v[a_k(t_k), a_{k+1} (t_{k+1})]
    \\
    \text{such that} \quad&
    \sum_{i=1}^N X_{ik} = 1 \quad \forall k = 1,\ldots,K
    \\&
    \sum_{k=1}^K X_{ik} \leq 1 \quad \forall i = 1,\ldots,N
    \\&
    \sum_{k=1}^{K-1} \Delta t_k \leq \Delta t_{\max}
    \\&
    X_{ik} = \{0,1\} \quad \forall i = 1,\ldots,N, \,\, k = 1\,\ldots,K
    \\&
    \Delta t_k \geq 0 \quad \forall k = 1,\ldots, K-1
\end{align}
$$

- The objective is to minimize the sum of transfer cost between each asteroid rendez-vous transfer, which is a function of the departing asteroid $a_k$ and arriving asteroid $a_{k+1}$, along with their encounter times $t_k$ and $t_{k+1}$
- The first constraint ensures exactly one asteorid is visited on the $k$-th visit (summation of $X$ column-wise)
- The second constraint ensures each asteroid is visited at most once (summation of $X$ row-wise)
- The third constraint ensures the time of flight is within the maximum mission duration
- The fourth constraint ensures $X_{ik}$ is binary
- The fifth constraint ensures the time of flight is always positive; in practice, it is better to also assign a lower and upper bound on $\Delta t$ (since we know that a good tour would have a moderate TOF), to something like $\Delta t_{\min} \leq \Delta t \leq \Delta t_{\max}$.

By introducing a slack variable $\eta \in \mathbb{R}_+^{K-1}$ for each transfer cost, we decompose the above problem to the sequencing problem, which is a MILP, and transfer design problem, which is an NLP, given respectively by

$$
\begin{align}
    \min_{X, \Delta t, \eta} \quad& \sum_{k=1}^{K-1} \eta_k
    \\
    \text{such that} \quad&
    \sum_{i=1}^N X_{ik} = 1 \quad \forall k = 1,\ldots,K
    \\&
    \sum_{k=1}^K X_{ik} \leq 1 \quad \forall i = 1,\ldots,N
    \\&
    \sum_{k=1}^{K-1} \Delta t_k \leq \Delta t_{\max}
    \\&
    X_{ik} = \{0,1\} \quad \forall i = 1,\ldots,N, \,\, k = 1\,\ldots,K
    \\&
    \Delta t_k \geq 0 \quad \forall k = 1,\ldots, K-1
\end{align}
$$

and 

$$
\begin{align}
    \min_{\Delta t} \quad& \sum_{k=1}^{K-1} \Delta v[a_k(t_k), a_{k+1} (t_{k+1})]
    \\
    \text{such that} \quad&
    \sum_{k=1}^{K-1} \Delta t_k \leq \Delta t_{\max}
    \\&
    \Delta t_k \geq 0 \quad \forall k = 1,\ldots, K-1
\end{align}
$$

