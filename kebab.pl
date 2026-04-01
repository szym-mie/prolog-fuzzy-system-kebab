:-module(kebab,_,[classic]).

% ----
% kebab.pl
% Compatible with Ciao Prolog and, presumably, with other classic Prologs
% as well.
% Author: Szymon Miękina
% ----

% -- lib --

% defp - binary min max
max2(X,Y,Y) :- X=<Y,!.
max2(X,Y,X) :- X>Y.

min2(X,Y,Y) :- X>=Y,!.
min2(X,Y,X) :- X<Y.

% defp - list min max
max_([],V,V).
max_([X|Xs],A,V) :- X>=A,max_(Xs,X,V).
max_([X|Xs],A,V) :- X<A,max_(Xs,A,V).
max([X1|Xs],V) :- max_(Xs,X1,V).

min_([],V,V).
min_([X|Xs],A,V) :- X=<A,min_(Xs,X,V).
min_([X|Xs],A,V) :- X>A,min_(Xs,A,V).
min([X1|Xs],V) :- min_(Xs,X1,V).

% defp - linear interpolation between two 2D points
lerp([X1,Y1],_,X1,Y1) :- !.
lerp(_,[X2,Y2],X2,Y2) :- !.
lerp([X1,Y1],[X2,Y2],Xp,Yp) :-
    X1<Xp,
    Xp<X2,
    W2 is (Xp-X1)/(X2-X1),
    W1 is 1-W2,
    Yp is W1*Y1+W2*Y2,!.
lerp(_,_,_,0).

% defp - generalized plane equation
lin_([F],[],A,V) :- V is A+F. % add free term
lin_([E|Es],[X|Xs],A,V) :- lin_(Es,Xs,A+E*X,V).
lin(Es,Xs,V) :- lin_(Es,Xs,0,V).

% defp - linear equation in 1D,2D,3D
lin3([A,B,C,D],X,Y,Z,V) :- V is A*X+B*Y+C*Z+D.
lin2([A,B,C],X,Y,V) :- lin3([A,B,0,C],X,Y,0,V).
lin1([A,B],X,V) :- lin3([A,0,0,B],X,0,0,V).

% defp - weighted average
wa_([],[],_,0,0) :- !.
wa_([],[],T,B,V) :- V is T/B,!.
wa_([W|Ws],[Z|Zs],T,B,V) :-
    T1 is T+W*Z,
    B1 is B+W,
    wa_(Ws,Zs,T1,B1,V).
wa(Ws,Xs,V) :- wa_(Ws,Xs,0,0,V).

% defp - trapezoidal membership fn
%        L1   R1
% 1 .    ._____.
%   .__./       \.__
% 0    L0       R0
mf([L0,L1,R1,R0],X,M) :-
    lerp([L0,0],[L1,1],X,M1),
    lerp([L1,1],[R1,1],X,M2),
    lerp([R1,1],[R0,0],X,M3),
    max([M1,M2,M3],M).

% defp - fuzzy evaluation of rules + sugeno
fzz_([],Ws,Zs,_,M) :- wa(Ws,Zs,M). % calculate weighted average
fzz_([P|Ps],Ws,Zs,X,M) :-
    G=..[P,X,W1,Z1], call(G), % evaluate predicate
    fzz_(Ps,[W1|Ws],[Z1|Zs],X,M). % append W, Z
fzz(Ps,X,M) :- fzz_(Ps,[],[],X,M).

% -- fuzzy sys --

% input mfs: 
% r_salad:
r_salad_low(X,M) :- mf([0.0,0.0,0.5,0.7],X,M).
r_salad_ok(X,M) :- mf([0.5,0.7,0.7,0.9],X,M).
r_salad_high(X,M) :- mf([0.7,0.9,1.0,1.0],X,M).
% r_sauce:
r_sauce_dry(X,M) :- mf([0.0,0.0,50.0,80.0],X,M).
r_sauce_ok(X,M) :- mf([50.0,80.0,100.0,150.0],X,M).
r_sauce_wet(X,M) :- mf([100.0,150.0,200.0,200.0],X,M).
% shape:
shape_long(X,M) :- mf([0.0,0.0,0.1,0.3],X,M).
shape_rollo(X,M) :- mf([0.1,0.3,0.3,0.5],X,M).
shape_dumpling(X,M) :- mf([0.3,0.5,0.5,0.8],X,M).
shape_wide(X,M) :- mf([0.5,0.8,1.0,1.0],X,M).
% spicy:
spicy_mild(X,M) :- mf([-1.0,-1.0,-0.5,0.5],X,M).
spicy_hot(X,M) :- mf([-0.5,0.5,1.0,1.0],X,M).
% t_fry:
t_fry_raw(X,M) :- mf([0.0,0.0,1.0,1.5],X,M).
t_fry_ok(X,M) :- mf([1.0,1.5,1.5,2.5],X,M).
t_fry_burn(X,M) :- mf([1.5,2.5,2.5,4.0],X,M).
t_fry_coal(X,M) :- mf([2.5,4.0,5.0,5.0],X,M).

% output lvls:
% U <- [r_salad,r_sauce,shape,spicy,t_fry]
qu_puke_z(U,V) :- lin([0,0,0,0,0,1],U,V).
qu_poor_z(U,V) :- lin([0,0,0,0,0,2],U,V).
qu_fair_z(U,V) :- lin([0,0,0,0,0,3],U,V).
qu_good_z(U,V) :- lin([0,0,0,0,0,5],U,V).
t_eat_ok_z(U,V) :- lin([0,0,0,0,0,1.0],U,V).
t_eat_hot_z(U,V) :- lin([0,0,0,0,0,0.5],U,V).
t_eat_burn_z(U,V) :- lin([0,0,0,0,0,0.0],U,V).
p_leak_low_z(U,V) :- lin([0,0,0,0,0,0.1],U,V).
p_leak_high_z(U,V) :- lin([0,0,0,0,0,1.0],U,V).

% rules:
% sym legend:
% Xv <- r_salad  Xs <- r_sauce
% Xh <- shape    Xp <- spicy
% Xf <- t_fry
% qu:
qu_puke1([_,_,_,_,Xf],W,Z) :-
    t_fry_coal(Xf,Mf), % only 1 input
    W is Mf * 10, % extra weight
    qu_puke_z([0,0,0,0,Xf],Z).
qu_poor1([_,_,_,_,Xf],W,Z) :-
    t_fry_raw(Xf,W),
    qu_poor_z([0,0,0,0,Xf],Z).
qu_poor2([_,_,_,_,Xf],W,Z) :-
    t_fry_burn(Xf,W),
    qu_poor_z([0,0,0,0,Xf],Z).
qu_poor3([Xv,Xs,_,_,Xf],W,Z) :-
    r_salad_low(Xv,Mv),
    r_sauce_dry(Xs,Ms),
    t_fry_raw(Xf,Mf),
    min([Mv,Ms,Mf],W), % and operation
    qu_poor_z([Xv,Xs,0,0,Xf],Z).
qu_poor4([Xv,Xs,_,_,Xf],W,Z) :-
    r_salad_high(Xv,Mv),
    r_sauce_wet(Xs,Ms),
    t_fry_burn(Xf,Mf),
    min([Mv,Ms,Mf],W),
    qu_poor_z([Xv,Xs,0,0,Xf],Z).
qu_poor5([_,_,Xh,_,_],W,Z) :-
    shape_wide(Xh,W),
    qu_poor_z([0,0,Xh,0,0],Z).
qu_poor6([_,Xs,_,_,_],W,Z) :-
    r_sauce_dry(Xs,W),
    qu_poor_z([0,Xs,0,0,0],Z).
qu_poor7([Xv,_,_,_,_],W,Z) :-
    r_salad_low(Xv,Mv),
    W is Mv * 2,
    qu_poor_z([Xv,0,0,0,0],Z).
qu_fair1([Xv,_,_,_,Xf],W,Z) :-
    r_salad_ok(Xv,Mv),
    t_fry_raw(Xf,Mf),
    min([Mv,Mf],W),
    qu_fair_z([Xv,0,0,0,Xf],Z).
qu_fair2([Xv,_,_,_,Xf],W,Z) :-
    r_salad_ok(Xv,Mv),
    t_fry_burn(Xf,Mf),
    min([Mv,Mf],W),
    qu_fair_z([Xv,0,0,0,Xf],Z).
qu_fair3([_,_,Xh,_,_],W,Z) :-
    shape_long(Xh,W),
    qu_fair_z([0,0,Xh,0,0],Z).
qu_fair4([_,Xs,_,_,_],W,Z) :-
    r_sauce_wet(Xs,W),
    qu_fair_z([0,Xs,0,0,0],Z).
qu_good1([_,Xs,_,_,_],W,Z) :-
    r_sauce_ok(Xs,W),
    qu_good_z([0,Xs,0,0,0],Z).
qu_good2([_,_,_,_,Xf],W,Z) :-
    t_fry_ok(Xf,W),
    qu_good_z([0,0,0,0,Xf],Z).
qu_good3([Xv,Xs,Xh,_,Xf],W,Z) :-
    r_salad_ok(Xv,Mv),
    r_sauce_ok(Xs,Ms),
    shape_rollo(Xh,Mh),
    t_fry_ok(Xf,Mp),
    min([Mv,Ms,Mh,Mp],W),
    qu_good_z([Xv,Xs,Xh,0,Xf],Z).
% t_eat:
t_eat_ok1([_,_,_,_,Xf],W,Z) :-
    t_fry_raw(Xf,W),
    t_eat_ok_z([0,0,0,0,Xf],Z).
t_eat_ok2([_,_,_,Xp,Xf],W,Z) :-
    spicy_mild(Xp,Mp),
    t_fry_ok(Xf,Mf),
    min([Mp,Mf],W),
    t_eat_ok_z([0,0,0,Xp,Xf],Z).
t_eat_ok3([_,Xs,_,Xp,Xf],W,Z) :-
    r_sauce_dry(Xs,Ms),
    spicy_mild(Xp,Mp),
    t_fry_burn(Xf,Mf),
    min([Ms,Mp,Mf],W),
    t_eat_ok_z([0,Xs,0,Xp,Xf],Z).
t_eat_ok4([Xv,_,_,_,_],W,Z) :-
    r_salad_high(Xv,Mv),
    W is Mv * 2,
    t_eat_ok_z([Xv,0,0,0,0],Z).
t_eat_hot1([_,_,_,Xp,_],W,Z) :-
    spicy_hot(Xp,W),
    t_eat_hot_z([0,0,0,Xp,0],Z).
t_eat_hot2([_,_,_,_,Xf],W,Z) :-
    t_fry_burn(Xf,W),
    t_eat_hot_z([0,0,0,0,Xf],Z).
t_eat_hot3([_,Xs,_,Xp,_],W,Z) :-
    r_sauce_wet(Xs,Ms),
    spicy_hot(Xp,Mp),
    min([Ms,Mp],W),
    t_eat_hot_z([0,Xs,0,Xp,0],Z).
t_eat_burn1([_,_,_,_,Xf],W,Z) :-
    t_fry_coal(Xf,W),
    t_eat_burn_z([0,0,0,0,Xf],Z).
t_eat_burn2([_,Xs,_,_,Xf],W,Z) :-
    r_sauce_wet(Xs,Ms),
    t_fry_coal(Xf,Mf),
    min([Ms,Mf],W),
    t_eat_burn_z([0,Xs,0,0,Xf],Z).
t_eat_burn3([_,_,_,Xp,Xf],W,Z) :-
    spicy_hot(Xp,Mp),
    t_fry_coal(Xf,Mf),
    min([Mp,Mf],W),
    t_eat_burn_z([0,0,0,Xp,Xf],Z).
% p_leak:
p_leak_low1([_,Xs,_,_,_],W,Z) :-
    r_sauce_dry(Xs,W),
    p_leak_low_z([0,Xs,0,0,0],Z).
p_leak_low2([_,Xs,Xh,_,_],W,Z) :-
    r_sauce_ok(Xs,Ms),
    shape_rollo(Xh,Mh),
    min([Ms,Mh],W),
    p_leak_low_z([0,Xs,Xh,0,0],Z).
p_leak_low3([_,Xs,Xh,_,_],W,Z) :-
    r_sauce_ok(Xs,Ms),
    shape_long(Xh,Mh),
    min([Ms,Mh],W),
    p_leak_low_z([0,Xs,Xh,0,0],Z).
p_leak_high1([_,Xs,_,_,_],W,Z) :-
    r_sauce_wet(Xs,W),
    p_leak_high_z([0,Xs,0,0,0],Z).
p_leak_high2([_,Xs,Xh,_,_],W,Z) :-
    r_sauce_ok(Xs,Ms),
    shape_wide(Xh,Mh),
    min([Ms,Mh],W),
    p_leak_high_z([0,Xs,Xh,0,0],Z).
% rule sets:
qu_rules([
    qu_puke1,qu_poor1,qu_poor2,qu_poor3,
    qu_poor4,qu_poor5,qu_poor6,qu_poor7,
    qu_fair1,qu_fair2,qu_fair3,qu_fair4,
    qu_good1,qu_good2,qu_good3
]).
t_eat_rules([
    t_eat_ok1,t_eat_ok2,t_eat_ok3,t_eat_ok4,
    t_eat_hot1,t_eat_hot2,t_eat_hot3,
    t_eat_burn1,t_eat_burn2,t_eat_burn3
]).
p_leak_rules([
    p_leak_low1,p_leak_low2,p_leak_low3,
    p_leak_high1,p_leak_high2
]).

% output evals:
qu(X,M) :- qu_rules(Ps), fzz(Ps,X,M).
t_eat(X,M) :- t_eat_rules(Ps), fzz(Ps,X,M).
p_leak(X,M) :- p_leak_rules(Ps), fzz(Ps,X,M).

% -- fuzzy sys infer --

kebab(X,[Mqu,Mt_eat,Mp_leak]) :-
    qu(X,Mqu),
    t_eat(X,Mt_eat),
    p_leak(X,Mp_leak).
