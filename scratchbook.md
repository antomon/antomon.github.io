

### Number theory

#### Primes and factorization

The journey into number theory starts with the basic building blocks of integers and their relationships, such as divisibility and the idea of prime numbers.

> **Definition (*Set of integers*)**: The set of integers is denoted as $\mathbb{Z} = {..., -2, -1, 0, 1, 2, ...}$.

> **Definition (*Divisibility*)**: Two integers $a$ and $b$ are divisible if there exists an integer $c$ such that $b = a \cdot c$. When true, this relationship is written as $a \mid b$. 

For example, $6 \mid 18$ holds because $18 = 6 \cdot 3$. If $a \nmid b$, then $a$ does not divide $b$.

> **Theorem (*Division algorithm*)**: For any integers $a$ and $b > 0$, there exist unique integers $q$ (quotient) and $r$ (remainder) such that:
> $$
> a = q \cdot b + r, \quad 0 \leq r < b
> $$.

For example, dividing $17$ by $5$ gives $q = 3$ and $r = 2$, as $17 = 3 \cdot 5 + 2$.

Prime numbers are the building blocks of integers. 

> **Definition (*Integer primality*)**: A number $p > 1$ is prime if its only divisors are $1$ and $p$. 

For instance, $7$ is prime, while $12$ is composite because $12 = 2 \cdot 6$.

> **Theorem (*Fundamental theorem of arithmetic*)**: Every integer $n > 1$ can be uniquely expressed as a product of prime powers:
> $$
> n = p_1^{e_1} \cdot p_2^{e_2} \cdots p_k^{e_k}
> $$,
> where $p_i$ are distinct primes, $i$ and $e_i$ are positive integers, and $k$ is the number of distinct prime factors of $n$.

For example, $84 = 2^2 \cdot 3 \cdot 7$ demonstrates this principle.

> **Remark**: It is straightforward to compute the product of two large prime numbers $p$ and $q$. However, the reverse operation, determining the original prime factors from their product $n = p \cdot q$, is computationally difficult. This difficulty arises from the lack of efficient algorithms for factorizing large integers. The best-known algorithms, such as the General Number Field Sieve (GNFS)[^GNFS-homomorphic-encryption-developers], have exponential time complexity for large inputs. This asymmetry makes factoring infeasible within a reasonable timeframe as the bit length of $p$ and $q$ increases. Moreover, the factors $p$ and $q$ are typically chosen to be large primes of similar bit length to avoid simple heuristics or optimizations. 
> This problem is so significant that it has its own name, the Integer Factorization Problem (denoted $ \text{Fact}[n] $), and it underpins the security of many public-key cryptosystems, including RSA, ensuring that decrypting or compromising encrypted data without the private key remains practically impossible.

[^GNFS-homomorphic-encryption-developers]: Lenstra, A. K., & Lenstra, H. W. (1993). **The development of the number field sieve** (Vol. 1554). Springer-Verlag. [DOI](https://doi.org/10.1007/BFb0091534)

#### Greatest common divisor

To explore relationships between numbers, we often need their greatest common divisor, e.g. to simplify a fraction or to synchronize cycles.

> **Definition (*Greatest common divisor (GCD)*)**: The greatest common divisor of two integers $a$ and $b$, denoted $\gcd(a, b)$, is the largest integer dividing both $a$ and $b$. 

For example, $\gcd(12, 18) = 6$. 

> **Definition (*Relatively primality of integers*)**: Two integers are relatively prime if their GCD is $1$.

Finding the GCD is efficient with the Euclidean algorithm:

> **Theorem (*Euclidean algorithm*)**: The GCD of two integers can be computed using the recursive relation:
> $$
> \gcd(a, b) = \gcd(b, a \mod b).
> $$

This recursive formula stems from the property of divisors:
$$
\gcd(a, b) = \gcd(b, a - q \cdot b),
$$
where $q$ is the quotient when $a$ is divided by $b$. Since $a - q \cdot b = a \mod b$, the recursion simplifies to:
$$
\gcd(a, b) = \gcd(b, r),
$$
where $r = a \mod b$. 

For example, consider the integers $72$ and $27$. Using the Euclidean algorithm:
$$
\begin{aligned}
\gcd(385, 364) &= \gcd(364, 385 \mod 364) = \gcd(364, 21), \\
\gcd(364, 21) &= \gcd(21, 364 \mod 21) = \gcd(21, 7), \\
\gcd(21, 7) &= \gcd(7, 21 \mod 7) = \gcd(7, 0) = 7.
\end{aligned}
$$

Thus, $\gcd(72, 27) = 9$. 





### Modular Arithmetic

In modular arithmetic, we focus on remainders.

> **Definition**: If $a, b, n \in \mathbb{Z}$ and $n > 0$, then $a$ is congruent to $b$ modulo $n$, written $a \equiv b \pmod{n}$, if $n \mid (a - b)$.

For example, $23 \equiv 8 \pmod{5}$ because $5 \mid (23 - 8)$.

### Modular Exponentiation

Cryptographic applications often involve exponentiation under a modulus.

> **Definition**: Modular exponentiation computes $a^b \mod n$ efficiently using the **square-and-multiply algorithm**.

For example, to compute $3^{13} \mod 7$:

Thus, $3^{13} \equiv 5 \pmod{7}$.

### Modular Inverses

The modular inverse is vital in cryptography for ensuring reversible operations.

> **Definition**: The **modular inverse** of $a$ modulo $n$ is an integer $x$ such that:

An inverse exists if and only if $\gcd(a, n) = 1$.

### Euler’s Theorem

> **Theorem**: (Euler’s Theorem) If $a$ and $n$ are coprime, then:
>
> where $\phi(n)$ is Euler’s totient function, counting integers less than $n$ that are coprime to $n$.

For example, $\phi(12) = 4$ because ${1, 5, 7, 11}$ are coprime to $12$.

### Chinese Remainder Theorem

The Chinese Remainder Theorem (CRT) is a powerful tool for combining modular computations.

> **Theorem**: (Chinese Remainder Theorem) Suppose $n\_1, n\_2, \dots, n\_k$ are pairwise coprime. For any integers $a\_1, a\_2, \dots, a\_k$, there exists a unique $x \pmod{N}$, where $N = n\_1 \cdot n\_2 \cdots n\_k$, satisfying:

CRT simplifies complex modular arithmetic, making it essential in RSA operations.

## Conclusion

This primer on number theory has introduced the mathematical backbone of RSA. By mastering these concepts, readers can better understand the mechanisms that secure cryptographic systems. The next sections will explore group theory and elliptic curves, expanding the mathematical toolkit for modern encryption.

