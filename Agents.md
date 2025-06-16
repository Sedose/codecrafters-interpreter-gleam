In Gleam, 

- we use Result(a, Nil) instead of Option for most things including returning optional data.

- we have shadowing, so you don't have to do this token0, token1 business to not collide with token binding (variable (btw runtime constant)).

- Writing a recursive function would be much easier to follow than forcing it into a list.fold pattern.

- You can pattern match on prefixes, getting rid of this additional pending state you need to keep track of
pattern matching on strings prefixes would work really well here and would mean you don't have to build a list of graphemes.

- Appending to lists always copies them entirely, it's better to build the list in reverse and then reverse once right at the end before you return.

