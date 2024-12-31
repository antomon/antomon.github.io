#### Congruence

> **Definition (*Congruence*)**: For integers $a$, $b$, and $n$ with $n > 0$, $a$ is congruent to $b$ modulo $n$, written $a \equiv b \pmod{n}$, if $n \mid (a - b)$.
 
For example, $23 \equiv 8 \pmod{5}$ because $5 \mid (23 - 8)$. 

This congruence partitions integers into **congruence classes** modulo $n$, grouping numbers that share the same remainder when divided by $n$. These equivalence classes reduce infinitely many integers to a manageable finite set.

> **Theorem (*Equivalence relation*)**: Congruence modulo $n$ satisfies the three fundamental properties of an equivalence relation:
>
> 1. Reflexivity: $a \equiv a \pmod{n}$, since $n \mid (a - a) = 0$.
> 2. Symmetry: If $a \equiv b \pmod{n}$, then $b \equiv a \pmod{n}$, because $n \mid (a - b)$ implies $n \mid (b - a)$.
> 3. Transitivity: If $a \equiv b \pmod{n}$ and $b \equiv c \pmod{n}$, then $a \equiv c \pmod{n}$, as $n \mid (a - b)$ and $n \mid (b - c)$ imply $n \mid (a - c)$.

These properties ensure that modular arithmetic forms a consistent framework for mathematical operations.

> **Theorem (*Congruence and remainders*)**: From the Division Algorithm, we have $r = a \mod b$, meaning $a \equiv b \pmod{n}$ if and only if $a$ and $b$ share the same remainder when divided by $n$. Moreover, both $a$ and $b$ are congruent to that common remainder:
> $$
> a \equiv b \pmod{n} \implies a \mod n = b \mod n.
> $$

This relationship provides a computational foundation for modular arithmetic.

Every integer modulo $n$ can be uniquely represented by a remainder within a specific range. This principle is foundational to modular arithmetic, as it ensures that each congruence class has a single canonical representative. The following theorem formalizes this idea:

> **Theorem (*Unique representation*)**: For $n \geq 2$, every integer is congruent modulo $n$ to exactly one element of the set $\{0, 1, 2, \dots, n-1\}$.

The notion of congruence naturally leads to the concept of a congruence class, which groups integers that share the same remainder when divided by $n$. These classes partition the set of integers into distinct subsets, each representing one equivalence class under congruence modulo $n$.

> **Definition (*Congruence class*)**: A congruence class modulo $n$, denoted $[a]_n$, is the set of integers equivalent to $a \pmod{n}$:
> $$
> [a]_n = \{a + kn \mid k \in \mathbb{Z}\}.
> $$

These classes partition $\mathbb{Z}$ into $n$ disjoint subsets, which together form the set $\mathbb{Z}_n$, the set of equivalence classes modulo $n$. Each subset corresponds to a unique remainder in $\{0, 1, \dots, n-1\}$.

For example, modulo $3$, the congruence classes are:
- $[0]_3 = \{..., -3, 0, 3, 6, ...\}$,
- $[1]_3 = \{..., -2, 1, 4, 7, ...\}$,
- $[2]_3 = \{..., -1, 2, 5, 8, ...\}.

Thus, $\mathbb{Z}_3 = \{[0]_3, [1]_3, [2]_3\}$, representing all possible congruence classes modulo $3$.

The concept of a congruence class provides a structured way to organize integers under modulo $n$. Each congruence class contains infinitely many integers that share the same modular properties. To simplify working with these classes, it is common to choose specific representatives for computations. The following definitions introduce the two most commonly used representatives:

> **Definition (*Least positive representative*)**: The least positive representative of a congruence class modulo $n$ is the smallest nonnegative integer in the class, given by $a \mod n$.

For example, consider modulo $5$:
- For $[7]_5$, the least positive representative is $7 \mod 5 = 2$.
- For $[-11]_5$, the least positive representative is $-11 \mod 5 = 4$.

> **Definition (*Least magnitude representative*)**: The least magnitude representative of a congruence class modulo $n$ minimizes $|r|$, where $-n/2 < r \leq n/2$.

Again, for modulo $5$:
- For $[7]_5$, the least magnitude representative is $2$, as $-5/2 < 2 \leq 5/2$.
- For $[-11]_5$, the least magnitude representative is $-1$, as $-5/2 < -1 \leq 5/2$.

These representatives are key to simplifying modular arithmetic calculations and ensuring consistent results.

#### Addition and multiplication

In modular arithmetic, fundamental operations like addition and multiplication follow specific rules that maintain consistency within the modular system. These rules are formalized in the following theorem:

> **Theorem (Modular addition and multiplication)**: For integers $a$ and $b$:
> $$
> \begin{aligned}
> (a + b) \mod n &= ((a \mod n) + (b \mod n)) \mod n, \\
> (a \cdot b) \mod n &= ((a \mod n) \cdot (b \mod n)) \mod n.
> \end{aligned}
> $$

When comparing $\mathbb{Z}$ (integers) and $\mathbb{Z}_n$ (integers modulo n), we find both similarities and key differences in their algebraic properties:

1. **Similarities**:

   - Both have well-defined addition and multiplication operations.
   - Zero has no multiplicative inverse in both systems.
   - 1 (and -1 in $\mathbb{Z}$ or its equivalent $n-1$ in $\mathbb{Z}_n$) always has a multiplicative inverse.

2. **Differences**:

   - In $\mathbb{Z}$, only ±1 have multiplicative inverses.
   - In $\mathbb{Z}_n$, any element $a$ where $\gcd(a,n)=1$ has a multiplicative inverse.
   - $\mathbb{Z}$ is infinite, while $\mathbb{Z}_n$ has exactly $n$ elements.
   - All operations in $\mathbb{Z}_n$ are bounded by $n$, while operations in $\mathbb{Z}$ can grow indefinitely.

This distinction in multiplicative inverses makes $\mathbb{Z}_n$ particularly useful in applications like cryptography, where invertible elements are crucial for encryption and decryption operations.














#### Modular Exponentiation

> **Definition (Modular Exponentiation)**: Modular exponentiation is a key operation in cryptography, efficiently computing $a^b \mod n$. Direct computation is impractical for large exponents, so the **square-and-multiply algorithm** is used:
>
> 1. Express $b$ in binary.
> 2. Initialize $result = 1$.
> 3. For each bit of $b$ (starting from the most significant):
>    - Square $result$ modulo $n$.
>    - Multiply $result$ by $a$ modulo $n$ if the bit is $1$.

Example:
To compute $3^{13} \mod 7$:
$$
\begin{aligned}
13 &= (1101)_2, \\
3^{13} \mod 7 &= (((3^2 \mod 7)^2 \mod 7) \cdot 3 \mod 7) = 5.
\end{aligned}
$$
This algorithm ensures efficient computation, even for very large numbers, and is central to RSA encryption and decryption.

#### Modular Inverses

> **Definition (Modular Inverse)**: The modular inverse of $a$ modulo $n$ is the integer $x$ such that:
> $$
>     a \cdot x \equiv 1 \pmod{n}.
> $$
> An inverse exists if and only if $\gcd(a, n) = 1$.

The **Extended Euclidean Algorithm** efficiently computes this inverse, which is essential for generating RSA keys and performing decryption.

### Applications in Cryptography

Modular arithmetic is the backbone of cryptographic systems like RSA, enabling secure and efficient encryption, decryption, and key exchange. By confining computations to equivalence classes, it ensures that operations remain computationally feasible even with the massive numbers typical of cryptographic applications.

