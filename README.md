# Fuzzy Logic System in Prolog

## 1. Problem

Estimate the quality and other parameters of the kebab, based on some input quantities.

## 2. Inputs & Outputs

#### 2.1. Input parameters

| Parameter | Description                                 |     Range     |
| :-------: | :------------------------------------------ | :-----------: |
| `r_salad` | ratio of salad mass to total mass           |  $[0.0,1.0]$  |
| `r_sauce` | ratio of sauce mass (ml) to total mass (kg) | $[0.0,200.0]$ |
|  `shape`  | how square the bread shape is               |  $[0.0,1.0]$  |
|  `spicy`  | actual spicyness, compared to expected      | $[-1.0,1.0]$  |
|  `t_fry`  | fry time (min)                              |  $[0.0,5.0]$  |

The ratio of meat mass to the total mass can be derived as such: `r_meat = 1.0 - r_salad`. Total mass is not explicitely given or needed for the purposes of the system.

#### 2.2. Output parameters

| Parameter | Description                                                    |    Range    |
| :-------: | :------------------------------------------------------------- | :---------: |
|   `qu`    | quality of the studied kebab                                   | $[1.0,5.0]$ |
|  `t_eat`  | how suited for consumption the kebab is temperature wise _(1)_ | $[0.0,1.0]$ |
| `p_leak`  | the probability the sauce will leak and ruin your shirt        | $[0.0,1.0]$ |

_(1)_ measured as soon as the customer is handed the kebab by a staff member

## 3. Fuzzy System

The proposed solution is to use the Sugeno (also known as Takagi–Sugeno–Kang or TSK) Fuzzy System. The inference process works as follows:

#### 3.1. Fuzzification

The inputs are fuzzified - each input is assigned to a fuzzy set with some degree of membership. The degree of membership is represented by a number within the $[0,1]$ interval. The fuzzy set contains a number of truth values, each represented by a membership function. In the case of this system, all membership functions are trapezoidal, however such function can be degenerated into a triangular membership function.

#### 3.2. Rules, weights and output levels

Rules behave similar to _if, then_ statements - the major difference is that the truth values are not boolean and instead continous. The boolean logic operators cannot operate on such values and instead we define a number of fuzzy logic analogues:

|   Boolean   |   Fuzzy    |
| :---------: | :--------: |
| $x \land y$ | $min(x,y)$ |
| $x \lor y$  | $max(x,y)$ |
|  $\neg x$   |  $1 - x$   |

In the Sugeno model each rule contains a predicate and sets the consequent of the rule can be represented by a polynomial function. Linear functions (hyperplane equations) are used in this system, however - only the constant term is set to a non-zero value.

An example rule, identified as `qu_fair1` in the program, looks like this (in an abstract notation):

`if r_salad=ok & t_fry=raw then qu=fair`

With the $X$ representing the input vector, the weight value $W$ will be calculated as $W=min(r\_salad\_ok(X),t\_fry\_raw(X))$, where the $r\_salad\_ok$ and $t\_fry\_raw$ are the membership functions of the input parameters. The output level is just $Z=0*X_{r\_salad}+0*X_{t\_fry}+3$.

#### 3.3. Defuzzification

The calculated weight and output level values for different rules need to be combined somehow to obtain the _crisp_ output values. In the case of the Sugeno model each output is the weighted average of the values from the corresponding rule set.

## 4. Program structure

The first half of the program consists mostly of library predicates needed to implement the fuzzy model:

- `min`/`max` - minimum/maxium of the list;
- `lin` - dimension-generalized linear function (hyperplane equation);
- `lerp` - linear interpolation for the trapezoidal member functions;
- `mf` - standard trapezoidal member function (predicate?);
- `wa` - weighted average of the list;
- `fzz` - fuzzy system inference - applies the rules and calculates weighted average as described in the _Fuzzy System_ section above of one output parameter.

The next half is mostly inputs' and outputs' membeship functions, output levels' hyperplane equations and rule sets.

## 5. System model design

#### 5.1. Membership functions - table

| Parameter |   Ident.   |          Trapezoid          |
| :-------: | :--------: | :-------------------------: |
| `r_salad` |   `low`    |     $(0.0,0.0,0.5,0.7)$     |
|     .     |    `ok`    |     $(0.5,0.7,0.7,0.9)$     |
|     .     |   `high`   |     $(0.7,0.9,1.0,1.0)$     |
| `r_sauce` |   `dry`    |    $(0.0,0.0,50.0,80.0)$    |
|     .     |    `ok`    |  $(50.0,80.0,100.0,150.0)$  |
|     .     |   `wet`    | $(100.0,150.0,200.0,200.0)$ |
|  `shape`  |   `long`   |     $(0,0,0.0,0.1,0.3)$     |
|     .     |  `rollo`   |     $(0.1,0.3,0.4,0.5)$     |
|     .     | `dumpling` |     $(0.4,0.5,0.6,0.8)$     |
|     .     |   `wide`   |     $(0.6,0.8,1.0,1.0)$     |
|  `spicy`  |   `mild`   |   $(-1.0,-1.0,-0.5,0.5)$    |
|     .     |   `hot`    |    $(-0.5,0.5,1.0,1.0)$     |
|  `t_fry`  |   `raw`    |     $(0.0,0.0,1.0,1.5)$     |
|     .     |    `ok`    |     $(1.0,1.5,1.5,2.5)$     |
|     .     |   `burn`   |     $(1.5,2.5,2.5,4.0)$     |
|     .     |   `coal`   |     $(2.5,4.0,5.0,5.0)$     |

#### 5.2. Membership functions - plots

```
r_salad        ok
                \
1 .  _________   .   _________
     |        \ / \ /        |
     |   low   / : /   high  |
0 .__|________/_\ /_\________|__
     |       |   |   |       |
    0.0     0.5 0.7 0.9     1.0

r_sauce

1 .  _________   ________   _________
     |        \ /        \ /        |
     |   dry   /    ok    /   wet   |
0 .__|________/_\________/_\________|__
     |       |   |      |   |       |
    0.0    50.0 80.0 100.0 150.0  200.0

shape

1 .  _________   _________   ____________   _________
     |        \ /         \ /            \ /        |
     |  long   /   rollo   /   dumpling   /   wide  |
0 .__|________/_\_________/_\____________/_\________|__
     |       |   |       |   |          |   |       |
    0.0     0.1 0.3     0.4 0.5        0.6 0.8     1.0

spicy

1 .  __________   __________
     |         \ /         |
     |   mild   /    hot   |
0 .__|_________/_\_________|__
     |        |   |        |
   -1.0     -0.5 0.5      1.0

t_fry          ok     burn
                \     /
1 .  _________   .   .   _________
     |        \ / \ / \ /        |
     |   raw   / : / : /   coal  |
0 .__|________/_\ /_\ / \________|__
     |       |   |   |   |       |
    0.0     1.0 1.5 2.5 4.0     5.0
```

#### 5.3. Rules

|     Ident.     | Conditions                                         | Efects        | Addendum       |
| :------------: | :------------------------------------------------- | :------------ | :------------- |
|   `qu_puke1`   | `t_fry=coal`                                       | `qu=puke`     | $W*10$ _(1,4)_ |
|   `qu_poor1`   | `t_fry=raw`                                        | `qu=poor`     | -              |
|   `qu_poor2`   | `t_fry=burn`                                       | .             | -              |
|   `qu_poor3`   | `r_salad=low & r_sauce=dry & t_fry=raw`            | .             | -              |
|   `qu_poor4`   | `r_salad=high & r_sauce=wet & t_fry=burn`          | .             | -              |
|   `qu_poor5`   | `shape=wide`                                       | .             | -              |
|   `qu_poor6`   | `r_sauce=dry`                                      | .             | -              |
|   `qu_poor7`   | `r_salad=low`                                      | .             | $W*2$ _(2,4)_  |
|   `qu_fair1`   | `r_salad=ok & t_fry=raw`                           | `qu=fair`     | -              |
|   `qu_fair2`   | `r_salad=ok & t_fry=burn`                          | .             | -              |
|   `qu_fair3`   | `shape=long`                                       | .             | -              |
|   `qu_fair4`   | `r_sauce=wet`                                      | .             | -              |
|   `qu_good1`   | `r_sauce=ok`                                       | `qu=good`     | -              |
|   `qu_good2`   | `t_fry=ok`                                         | .             | -              |
|   `qu_good3`   | `r_salad=ok & r_sauce=ok & shape=rollo & t_fry=ok` | .             | -              |
|  `t_eat_ok1`   | `t_fry=raw`                                        | `t_eat=ok`    | -              |
|  `t_eat_ok2`   | `spicy=mild & t_fry=ok`                            | .             | -              |
|  `t_eat_ok3`   | `r_sauce=dry & spicy=mild & t_fry=burn`            | .             | -              |
|  `t_eat_ok4`   | `r_salad=high`                                     | .             | $W*2$ _(3,4)_  |
|  `t_eat_hot1`  | `spicy=hot`                                        | `t_eat=hot`   | -              |
|  `t_eat_hot2`  | `t_fry=burn`                                       | .             | -              |
|  `t_eat_hot3`  | `r_sauce=wet & spicy=hot`                          | .             | -              |
| `t_eat_burn1`  | `t_fry=coal`                                       | `t_eat=burn`  | -              |
| `t_eat_burn2`  | `r_sauce=wet & t_fry=coal`                         | .             | -              |
| `t_eat_burn3`  | `spicy=hot & t_fry=coal`                           | .             | -              |
| `p_leak_low1`  | `r_sauce=dry`                                      | `p_leak=low`  | -              |
| `p_leak_low2`  | `r_sauce=ok & shape=rollo`                         | .             | -              |
| `p_leak_low3`  | `r_sauce=ok & shape=long`                          | .             | -              |
| `p_leak_high1` | `r_sauce=wet`                                      | `p_leak=high` | -              |
| `p_leak_high2` | `r_sauce=ok & shape=wide`                          | .             | -              |

_(1)_ burnt bread negates all possible positive qualities of the kebab

_(2)_ just-meat kebab is not at all that tasty

_(3)_ to offset the added amount of water in the salad - presumably causing the kebab to heat up slower

_(4)_ please be aware that the weight scaling of individual rules might not be considered a standard practice and was the quick and easy solution by the author to handle special cases

## 6. Examples

#### 6.1. Coal kebab (completely burned)

###### Query

```prolog
kebab([0.5,80.0,0.4,0.0,4.0],M).
```

50-50 meat and salad, a reasonable amount of sauce, rollo, burnt completely (4 minutes of frying).

###### Result

| Parameter | Infered | Meaning                                   |
| :-------: | :-----: | :---------------------------------------- |
|   `qu`    | `1.46`  | VERY low overall quality - uneatable      |
|  `t_eat`  | `0.125` | very hot, cannot be held in hand for long |
| `p_leak`  |  `0.1`  | low probability of sauce leaking          |

#### 6.2. Very good

###### Query

```prolog
kebab([0.7,105.0,0.4,0.0,1.5],M).
```

70% salad and 30% meat, a bit too much sauce, but welldone.

###### Result

| Parameter | Infered | Meaning                                      |
| :-------: | :-----: | :------------------------------------------- |
|   `qu`    | `4.92`  | nearly perfect score                         |
|  `t_eat`  | `0.72`  | somewhat too hot to begin eating immediately |
| `p_leak`  | `0.25`  | -                                            |

#### 6.3. Dry, meat, raw

###### Query

```prolog
kebab([0.2,30.0,0.6,1.0,0.5],M).
```

Dry, spicy, very meaty dumpling and to top that - raw.

###### Result

| Parameter | Infered | Meaning     |
| :-------: | :-----: | :---------- |
|   `qu`    |  `2.0`  | low quality |
|  `t_eat`  | `0.75`  | -           |
| `p_leak`  |  `0.1`  | -           |

#### 6.4. Spicy, fried

###### Query

```prolog
kebab([0.6,80.0,0.4,1.0,2.5],M).
```

Sensible amount of sauce, spicy and bit overdone, nearly burned.

###### Result

| Parameter | Infered | Meaning                         |
| :-------: | :-----: | :------------------------------ |
|   `qu`    | `3.00`  | mediocre quality                |
|  `t_eat`  |  `0.5`  | hot - can be held but not eaten |
| `p_leak`  |  `0.1`  | -                               |

#### 6.5. Mild veggie square

###### Query

```prolog
kebab([0.9,150.0,1.0,-0.5,1.2],M).
```

A lot of salad drowning in mild sauce, tiny bit underfried.

###### Result

| Parameter | Infered | Meaning                               |
| :-------: | :-----: | :------------------------------------ |
|   `qu`    | `2.77`  | below average quality                 |
|  `t_eat`  |  `1.0`  | completely safe to eat                |
| `p_leak`  |  `1.0`  | your shirt/hoodie/trousers are ruined |

## 7. Compability

The program is guaranteed to work within the _Ciao Prolog_ system. Presumably the progam could be ported to other _Prolog_ dialects, with some minor changes to the source code: most notably the lack of `:-module` in _ISO-Prolog_ would require the omission of this directive. The program does not take advantage of other _Ciao_ system features, such as preprocessor or external packages.

## 8. Acknowledgments

No LLMs or other generative AI technologies have been used to create or edit any part of this project, or to help development in any other way: to create explainations, translations, system commands, or execute searches etc. 

For information on licesning, see the `LICENSE.txt` file in the root of the project.

Szymon Miękina, April 2026
