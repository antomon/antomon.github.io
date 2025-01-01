#### Modular inverse

The modular inverse is a fundamental concept in number theory and cryptography. It is essential for solving modular equations, whose solution is determined within a given modulus $n$, meaning the values satisfy the equation in terms of congruence relations.

> **Definition (*Modular inverse*)**: The modular inverse of an integer $a$ modulo $n$ is an integer $x$ such that:
> $$
> a \cdot x \equiv 1 \pmod{n}.
> $$

> **Theorem (*Existence of modular inverse*)**: An integer $a$ has a modular inverse modulo $n$ if and only if $\gcd(a, n) = 1$. If the modular inverse exists, it is unique modulo $n$.

A proof sketch can be given leveraging the Bézout's Identity, because if $\gcd(a, n) = 1$, then there exist integers $x$ and $y$ such that:
$$
ax + ny = 1.
$$

Taking this equation modulo $n$, we get:
$$
ax \equiv 1 \pmod{n}
$$

proving that $x$ is the modular inverse of $a$ modulo $n$. The uniqueness follows from the properties of congruence classes.

> Algorithm (*Modular inverse via Extended Euclidean Algorithm*):
>
> 1. Input integers $a$ and $n$, where $\gcd(a, n) = 1$.
> 
> 2. Initialize:
>    - $r_0 = n$, $r_1 = a$ (remainder terms).
>    - $s_0 = 1$, $s_1 = 0$ (coefficients for $n$).
>    - $t_0 = 0$, $t_1 = 1$ (coefficients for $a$).
> 
> 3. While $r_1 \neq 0$:
>    1. Compute $q = \lfloor r_0 / r_1 \rfloor$ (quotient).
>    2. Update:
>       - $r_2 = r_0 - q \cdot r_1$
>       - $s_2 = s_0 - q \cdot s_1$
>       - $t_2 = t_0 - q \cdot t_1$
>    3. Set $r_0 = r_1$, $r_1 = r_2$, $s_0 = s_1$, $s_1 = s_2$, $t_0 = t_1$, $t_1 = t_2$.
> 4. Output: The modular inverse is $t_0 \mod n$.

### Fermat’s Little Theorem

> Theorem (Fermat’s Little Theorem): If $p$ is a prime number and $a$ is an integer such that $p \nmid a$, then:
> $$
> a^{p-1} \equiv 1 \pmod{p}.
> $$
> Consequently, the modular inverse of $a$ modulo $p$ is:
> $$
> a^{p-2} \mod p.
> $$

This theorem provides an efficient way to compute modular inverses when $n$ is prime.

### Fermat Primality Test

> Algorithm (Fermat Primality Test):
>
> 1. Input: Integer $n$ to be tested for primality, integer $a$ where $1 < a < n$.
> 2. Compute $a^{n-1} \mod n$ using modular exponentiation.
> 3. If $a^{n-1} \not\equiv 1 \pmod{n}$:
>    - Output: $n$ is composite.
> 4. Otherwise:
>    - Output: $n$ is likely prime.

### Examples

1. Finding a Modular Inverse:
   - Find the modular inverse of $3$ modulo $7$.
   - Using the Extended Euclidean Algorithm:
     - $7 = 2 \cdot 3 + 1$
     - $3 = 3 \cdot 1 + 0$
     - Working backwards:
       $$
       1 = 7 - 2 \cdot 3.
       $$
       So the modular inverse of $3$ modulo $7$ is $-2 \equiv 5 \pmod{7}$.

2. Using Fermat’s Little Theorem:
   - Compute the modular inverse of $3$ modulo $7$.
   - By Fermat’s theorem:
     $$
     3^{7-2} \mod 7 = 3^5 \mod 7.
     $$
     Using modular exponentiation:
     $$
     3^5 \mod 7 = (((3^2 \mod 7) \cdot 3) \mod 7 \cdot 3) \mod 7 = 5.
     $$
     The modular inverse is $5$.

3. Fermat Primality Test:
   - Test $n = 17$ for primality with $a = 3$.
   - Compute $3^{16} \mod 17$:
     $$
     3^{16} \mod 17 = 1.
     $$
     Output: $17$ is likely prime.

These concepts and algorithms highlight the importance of modular inverses in cryptography and number theory.

  FERMATO A PAG 10 DI RSA.PDF 








































#### Modular Exponentiation

Modular exponentiation is a key operation in cryptography, enabling efficient computation of powers modulo a number. This operation is central to cryptographic systems like RSA, where large exponentiations are common.

> Definition (Modular Exponentiation): Modular exponentiation computes $a^b \mod n$, where $a$ is the base, $b$ is the exponent, and $n$ is the modulus. Direct computation is impractical for large $b$, so efficient algorithms like square-and-multiply are used.

### Algorithm: Square-and-Multiply

> Algorithm (Square-and-Multiply Algorithm):
>
> 1. Input: Integers $a, b, n$ where $a$ is the base, $b$ is the exponent, and $n$ is the modulus.
>
> 2. Convert $b$ to its binary representation:
>    1. Input: Integer $b$.
>    2. Initialize: $binary\_representation = []$.
>    3. While $b > 0$:
>        - Append $b \mod 2$ to $binary\_representation$.
>        - Update $b = \lfloor b / 2 \rfloor$.
>    4. Reverse $binary\_representation$ to get the bits in correct order.
>    5. Output: $binary\_representation$.
>
> 3. Initialize:
>    - $result = 1$.
>
> 4. For each bit $b_i$ in $binary\_representation$:
>    1. Update $result = (result \cdot result) \mod n$.
>    2. If $b_i = 1$, then update $result = (result \cdot a) \mod n$.
>
> 5. Output: Return $result$, which is $a^b \mod n$.

### Example: Computing $3^{13} \mod 7$

To compute $3^{13} \mod 7$ using the Square-and-Multiply Algorithm:

1. Convert $b = 13$ to binary: $13 = (1101)_2$.
2. Initialize $result = 1$.
3. Process each bit from left to right:
   - First bit $1$: Square $result = (1^2 \mod 7) = 1$; Multiply $result = (1 \cdot 3 \mod 7) = 3$.
   - Second bit $1$: Square $result = (3^2 \mod 7) = 2$; Multiply $result = (2 \cdot 3 \mod 7) = 6$.
   - Third bit $0$: Square $result = (6^2 \mod 7) = 1$; No multiplication (bit is 0).
   - Fourth bit $1$: Square $result = (1^2 \mod 7) = 1$; Multiply $result = (1 \cdot 3 \mod 7) = 3$.
4. Final $result = 5$.

This algorithm ensures efficient computation, even for very large numbers, making it an essential tool for cryptographic operations like encryption and decryption in RSA.

