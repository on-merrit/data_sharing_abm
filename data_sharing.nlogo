extensions [profiler]
; ticks = 6 months
; default publishing rate: once every 6 months

breed [groups group]
breed [grants grant]
breed [datasets dataset]
breed [funders funder]

groups-own [
  resources
  long-term-orientation
  data-sharing?
  total-grants
  total-resources
  resources-for-data-paper
  total-datasets
  n-publications ; all publications
  n-grants
  primary-publications
  publications-with-data-shared ; current publications with shared data
  total-primary-publications
  n-publications-with-data-shared ; total publications with shared data
  data-sharing-propensity ; how many publications came with data
  n-pubs-this-round
  publication-success
  publication-history ; implementation of tracking the publication history was adapted from https://stackoverflow.com/a/59862247/3149349
  data-sharing-success
  data-sharing-history
  grant-history
  chance
  proposal-strength-default
  proposal-strength-data
  update-counter ; this is needed so every agent has their own update window (and not all agents changing at the same time)
  ; these two are needed to compare longer periods
  success-this-period
  success-last-period
  openness-for-change
  publication-quantile ;quantile of publication distribution, computed when sharing of data starts
]

grants-own [
  grant-year
  data-sharing-policy?
]

datasets-own [
  dataset-year
]

to setup
  clear-all

  ask patches [set pcolor white]

  create-groups n-groups
  let pub-history-length history-length * 2 ; so a history of "3" years becomes 6 ticks = 3 years
  ask groups [
    setxy random-xcor random-ycor
    set shape "person"
    set resources .3
    set total-grants 0
    set total-datasets 0
    set n-publications 0
    set n-pubs-this-round 0
    set publication-history n-values pub-history-length [0]
    set data-sharing-history n-values pub-history-length [0]
    set grant-history n-values 21 [0]
    set update-counter random 100
    set data-sharing? false
    set openness-for-change .2
    ; TODO: the values for myopia are too low: chances to publish each round are slim at baseline, therefore need to consider longer timeframe
    (ifelse
      agent-orientation = "all-myopic" [ set long-term-orientation 1 ]
      agent-orientation = "all-long-term" [ set long-term-orientation 5 ]
      agent-orientation = "uniform" [ set long-term-orientation one-of [1 2 3 4 5] ]
    )
  ]

  let n-data-sharers data-sharers / 100 * n-groups

  ask n-of n-data-sharers groups [ set data-sharing? true ]

  create-funders 1
  ask funders [
    setxy random-xcor random-ycor
    set shape "tree"
    set color 15 ; red
  ]
  reset-ticks
end


to go
  if ticks = 500 [stop] ; stop after 250 years (500)

  ; create prestige quantiles at sharing start
  if ticks = sharing-start [
    let q25 calc-pct 25 [n-publications] of groups
    let q50 calc-pct 50 [n-publications] of groups
    let q75 calc-pct 75 [n-publications] of groups

    ask groups [
      if n-publications <= q25 [set publication-quantile "q[0-25]"]
      if n-publications > q25 and n-publications <= q50 [set publication-quantile "q(25-50]"]
      if n-publications > q50 and n-publications <= q75 [set publication-quantile "q(50-75]"]
      if n-publications > q75 [set publication-quantile "q(75-100]"]
    ]
  ]

  publish
  setup-grants
  allocate-grants
  update-indices
  if ticks >= sharing-start [ update-sharing-decision ]

  tick
end

to update-sharing-decision
  run learning-mechanism
end

to learn-rationally
  ask groups [
    ; update only according to own update frequency
    if update-counter mod long-term-orientation = 0 [
      ; change comparison window according to long-term-orientation of group
      let group-history sublist but-first publication-history 0 long-term-orientation
      set success-this-period mean group-history
      ; compare to current grants and adapt
      ; here we could also add a logistic function
      if success-this-period * 1.5 < success-last-period [ set data-sharing? not data-sharing? ]

      ; we set the success of the last period equal to the current one, so the next time we arrive in this loop it is the last period
      set success-last-period success-this-period
    ]
  ]
end


to learn-socially
  ask groups [
    ; update only according to own update frequency
    if update-counter mod long-term-orientation = 0 [
      let others n-of 5 other groups

      let rank-list sort-on [(- n-pubs-this-round)] groups
      let top-group first rank-list
      let peer-state [data-sharing?] of top-group

      if not data-sharing? = peer-state [
        if random-float 1 < openness-for-change [
          set data-sharing? peer-state
        ]
      ]
    ]
  ]
end


to publish
  ask groups [
    default-publishing
  ]
end


to default-publishing
  let current-resources resources + n-grants
  let other-publications 0 ; need to keep better track of what is used where
  set publications-with-data-shared 0

  ifelse data-sharing? and ticks >= sharing-start [
    set current-resources current-resources - current-resources * rdm-cost  ; rdm takes 5% of resources, we assume those 5% count in the same tick, since data has to be published along the publication
    set publications-with-data-shared random-poisson current-resources
  ] [
    set publications-with-data-shared 0
    set other-publications random-poisson current-resources
  ]

  set primary-publications publications-with-data-shared + other-publications
  set total-primary-publications total-primary-publications + primary-publications
  set n-pubs-this-round primary-publications
  set n-publications n-publications + primary-publications
  set n-publications-with-data-shared n-publications-with-data-shared + publications-with-data-shared
  ifelse n-publications = 0 [
    set data-sharing-propensity 0
  ] [
    set data-sharing-propensity n-publications-with-data-shared / n-publications
  ]

  ; share datasets if such publications where generated
  share-data

  set publication-history fput primary-publications but-last publication-history
end


to share-data
  hatch-datasets publications-with-data-shared [ create-link-with myself ]

  ask datasets-here [
    set shape "box"
    move-to one-of neighbors
  ]

  set total-datasets total-datasets + publications-with-data-shared
  set data-sharing-history fput publications-with-data-shared but-last data-sharing-history
end



to setup-grants
  ask funders [
    hatch-grants grants-per-funder
  ]
  ; set up our new grants
  ask grants with [count link-neighbors = 0] [
    set grant-year -0.5 ; need to set grant year to negative, so the grant stays alive and has an effect for 4/6 rounds
    set shape "star"
    move-to one-of neighbors
  ]
end

to award-grant
  create-link-with one-of grants with [count link-neighbors = 0]

  ask link-neighbors with [breed = grants] [move-to one-of [neighbors] of myself]

  set total-grants total-grants + 1
end


; new grant mechanism
; will need higher settings for chance, potentially. Calibrate based on gini of publication distributions I find (use DescTools and Gini)

to allocate-grants
  ask groups [
    set publication-success sum publication-history
    set data-sharing-success sum data-sharing-history
  ]

  let max-pub-success max [publication-success] of groups
  ; ensure we do not divide by zero
  if max-pub-success = 0 [ set max-pub-success 1 ]

  let max-data-success max [data-sharing-success] of groups
  ; ensure we do not divide by zero
  if max-data-success = 0 [ set max-data-success 1 ]

  ask groups [
    set publication-success publication-success / max-pub-success ; standardise publication success
    set data-sharing-success data-sharing-success / max-data-success ; standardise data sharing success
  ]

  ask funders [
    ask groups [
      set chance random-float 1
      set proposal-strength-default chance * importance-of-chance + (1 - importance-of-chance) * publication-success

      let pub-and-data-success publication-success * pubs-vs-data + data-sharing-success * (1 - pubs-vs-data)
      set proposal-strength-data chance * importance-of-chance + (1 - importance-of-chance) * pub-and-data-success
    ]

    ifelse ticks >= sharing-start [
      ; implementation adapted from https://stackoverflow.com/a/38268346/3149349
      let rank-list sort-on [(- proposal-strength-data)] groups ; need to invert proposal-strength, so that higher values are on top of the list
      let top-groups sublist rank-list 0 grants-per-funder
      foreach top-groups [ x -> ask x [ award-grant ] ]
    ] [
      let rank-list sort-on [(- proposal-strength-default)] groups
      let top-groups sublist rank-list 0 grants-per-funder
      foreach top-groups [ x -> ask x [ award-grant ] ]
    ]
  ]
end

to update-indices
  ask grants [
   set grant-year grant-year + .5
   if (grant-year >= 3) [ die ]
  ]

  ask datasets [
   set dataset-year dataset-year + .5
   if (dataset-year >= 10) [ die ] ; let datasets vanish after 10 years. could be changed later
  ]

  ask groups [
    set n-grants count-n-grants
    set grant-history fput n-grants but-last grant-history
  ]

  ask groups [
    set update-counter update-counter + 1
  ]
end

; the initial computation for the gini index was adapted from the peer reviewer game, bianchi et al. DOI: 10.1007/s11192-018-2825-4 (https://www.comses.net/codebases/6b77a08b-7e60-4f47-9ebb-6a8a2e87f486/releases/1.0.0/)
; the below and now used implementation was provided by TurtleZero on Stackoverflow: https://stackoverflow.com/a/70524851/3149349
to-report gini [ samples ]
  let n length samples
  let indexes (range 1 (n + 1))
  let bias-function [ [ i yi ] -> (n + 1 - i) * yi ]
  let biased-samples (map bias-function indexes sort samples)
  let ratio sum biased-samples / sum samples
  let G (1 / n ) * (n + 1 - 2 * ratio)
  report G
end


to-report count-n-grants
  report count link-neighbors with [breed = grants]
end

to-report mean-grants  [ agentset ]
  report precision mean [n-grants] of agentset 2
end

to-report var-grants
  report precision variance [n-grants] of groups 2
end

to-report mean-publications  [ agentset ]
  report precision mean [n-publications] of agentset 2
end

to-report mean-primary-publications [ agentset ]
  report precision mean [total-primary-publications] of agentset 2
end

; group of reporters that targets the numbers of publications of three groups:
; those with low, medium or high shares of data grants
to-report non-data-sharer-pubs
  let x groups with [data-sharing-propensity < .25]
  report precision mean [n-publications] of x 2
end

to-report some-data-sharer-pubs
  let x groups with [data-sharing-propensity >= .25 and data-sharing-propensity < .75]
  report precision mean [n-publications] of x 2
end

to-report most-data-sharer-pubs
  let x groups with [data-sharing-propensity >= .75]
  report precision mean [n-publications] of x 2
end

to-report no-grants
  let x groups with [total-grants = 0]
  report precision mean [n-publications] of x 2
end

; reporters on success of myopic vs long-term oriented ones
to-report myopics
  let x groups with [long-term-orientation < 3]
  report precision mean [n-publications] of x 2
end

to-report mid-myopics
  let x groups with [long-term-orientation = 3]
  report precision mean [n-publications] of x 2
end

to-report long-termers
  let x groups with [long-term-orientation > 2]
  report precision mean [n-publications] of x 2
end

; calculate quantiles
; https://stackoverflow.com/a/54420235/3149349
to-report calc-pct [ #pct #vals ]
  let #listvals sort #vals
  let #pct-position #pct / 100 * length #vals
  ; find the ranks and values on either side of the desired percentile
  let #low-rank floor #pct-position
  let #low-val item #low-rank #listvals
  let #high-rank ceiling #pct-position
  let #high-val item #high-rank #listvals
  ; interpolate
  ifelse #high-rank = #low-rank
  [ report #low-val ]
  [ report #low-val + ((#pct-position - #low-rank) / (#high-rank - #low-rank)) * (#high-val - #low-val) ]
end

to-report data-sharers-within-group [agentset]
  ifelse ticks < sharing-start [
    report 0
  ] [
    let n count agentset
    let sharers count agentset with [data-sharing?]
    report sharers / n
  ]
end

; report mean number of produced datasets per groups
to-report mean-datasets [agentset]
  ifelse ticks < sharing-start [
    report 0
  ] [
    report mean [total-datasets] of agentset
  ]
end

to-report mean-datasets-q1
  report mean-datasets groups with [publication-quantile = "q[0-25]"]
end
to-report mean-datasets-q2
  report mean-datasets groups with [publication-quantile = "q(25-50]"]
end
to-report mean-datasets-q3
  report mean-datasets groups with [publication-quantile = "q(50-75]"]
end
to-report mean-datasets-q4
  report mean-datasets groups with [publication-quantile = "q(75-100]"]
end


to-report mean-grants-quartiles [agentset]
  ifelse ticks < sharing-start [
    report 0
  ] [
    report mean [n-grants] of agentset
  ]
end

to-report mean-grants-q1
  report mean-grants-quartiles groups with [publication-quantile = "q[0-25]"]
end
to-report mean-grants-q2
  report mean-grants-quartiles groups with [publication-quantile = "q(25-50]"]
end
to-report mean-grants-q3
  report mean-grants-quartiles groups with [publication-quantile = "q(50-75]"]
end
to-report mean-grants-q4
  report mean-grants-quartiles groups with [publication-quantile = "q(75-100]"]
end


to-report stuff
  report [(list who n-publications n-publications-with-data-shared n-grants)] of groups
end
@#$#@#$#@
GRAPHICS-WINDOW
32
221
468
658
-1
-1
12.97
1
10
1
1
1
0
0
0
1
-16
16
-16
16
0
0
1
ticks
30.0

BUTTON
715
30
778
63
NIL
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
582
29
645
62
NIL
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

MONITOR
825
12
950
57
mean-grants
mean-grants groups
17
1
11

MONITOR
953
11
1071
56
variance of resources
var-grants
17
1
11

MONITOR
829
63
941
108
mean-publications
mean-publications groups
17
1
11

PLOT
532
312
848
547
n-publications distribution
NIL
NIL
0.0
4000.0
0.0
10.0
true
false
"" ""
PENS
"default" 100.0 1 -16777216 true "" "histogram [n-publications] of groups"

BUTTON
650
30
713
63
step
go
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
24
25
154
58
n-groups
n-groups
20
500
100.0
1
1
NIL
HORIZONTAL

SLIDER
300
28
437
61
history-length
history-length
1
20
3.0
1
1
NIL
HORIZONTAL

PLOT
533
125
831
312
bi-yearly publications
NIL
NIL
0.0
100.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 1 -16777216 true "" "histogram [n-pubs-this-round] of groups"

PLOT
833
127
1159
313
grant distribution
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 1 -16777216 true "" "histogram [n-grants] of groups"

PLOT
1160
128
1458
313
total number of grants
NIL
NIL
0.0
200.0
0.0
10.0
true
false
"" ""
PENS
"default" 10.0 1 -16777216 true "" "histogram [total-grants] of groups"

SLIDER
25
63
156
96
grants-per-funder
grants-per-funder
1
20
14.0
1
1
NIL
HORIZONTAL

SLIDER
154
26
294
59
importance-of-chance
importance-of-chance
0
1
0.7
.01
1
NIL
HORIZONTAL

PLOT
1184
312
1500
547
Gini coefficients
NIL
NIL
0.0
10.0
0.0
1.0
true
true
"" ""
PENS
"grants" 1.0 0 -14070903 true "" "plot gini [n-grants] of groups"
"publications" 1.0 0 -5298144 true "" "plot gini [n-publications] of groups"
"datasets" 1.0 0 -15040220 true "" "plot gini [total-datasets] of groups"

PLOT
849
314
1182
548
number of datasets
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot count datasets"

SLIDER
173
111
318
144
pubs-vs-data
pubs-vs-data
0
1
1.0
.01
1
NIL
HORIZONTAL

SLIDER
344
112
475
145
rdm-cost
rdm-cost
0
1
0.0
.01
1
NIL
HORIZONTAL

PLOT
534
549
847
728
success of groups
NIL
NIL
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"no grants" 1.0 0 -16777216 true "" "plot no-grants"
"no data" 1.0 0 -7500403 true "" "plot non-data-sharer-pubs"
"mid data" 1.0 0 -2674135 true "" "plot some-data-sharer-pubs"
"most data" 1.0 0 -955883 true "" "plot most-data-sharer-pubs"

CHOOSER
24
108
162
153
agent-orientation
agent-orientation
"all-myopic" "all-long-term" "uniform"
0

SLIDER
159
66
299
99
sharing-start
sharing-start
0
500
500.0
20
1
NIL
HORIZONTAL

PLOT
846
545
1139
732
publication distribution sucess
NIL
NIL
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"q[0-25]" 1.0 0 -8053223 true "" "plot mean [n-publications] of groups with [publication-quantile = \"q[0-25]\"]"
"q(25-50]" 1.0 0 -13210332 true "" "plot mean [n-publications] of groups with [publication-quantile = \"q(25-50]\"]"
"(50-75]" 1.0 0 -14730904 true "" "plot mean [n-publications] of groups with [publication-quantile = \"q(50-75]\"]"
"q(75-100]" 1.0 0 -4079321 true "" "plot mean [n-publications] of groups with [publication-quantile = \"q(75-100]\"]"

PLOT
1139
546
1500
733
data sharing propensity
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot count groups with [data-sharing?] "

SLIDER
304
66
444
99
data-sharers
data-sharers
0
100
50.0
1
1
%
HORIZONTAL

CHOOSER
24
161
162
206
learning-mechanism
learning-mechanism
"learn-rationally" "learn-socially"
1

PLOT
850
731
1145
907
sharing extent
NIL
NIL
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"q1" 1.0 0 -8053223 true "" "plot mean [total-datasets] of groups with [publication-quantile = \"q[0-25]\"]"
"q2" 1.0 0 -13210332 true "" "plot mean [total-datasets] of groups with [publication-quantile = \"q(25-50]\"]"
"q3" 1.0 0 -2674135 true "" "plot mean [total-datasets] of groups with [publication-quantile = \"q(50-75]\"]"
"q4" 1.0 0 -955883 true "" "plot mean [total-datasets] of groups with [publication-quantile = \"q(75-100]\"]"

PLOT
532
728
850
909
data sharers
NIL
NIL
0.0
1.0
0.0
1.0
true
true
"" ""
PENS
"q1" 1.0 0 -16777216 true "" "plot data-sharers-within-group groups with [publication-quantile = \"q[0-25]\"]"
"q2" 1.0 0 -7500403 true "" "plot data-sharers-within-group groups with [publication-quantile = \"q(25-50]\"]"
"q3" 1.0 0 -2674135 true "" "plot data-sharers-within-group groups with [publication-quantile = \"q(50-75]\"]"
"q4" 1.0 0 -955883 true "" "plot data-sharers-within-group groups with [publication-quantile = \"q(75-100]\"]"

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.2.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="01-baseline" repetitions="100" sequentialRunOrder="false" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>mean-grants groups</metric>
    <metric>mean-publications groups</metric>
    <metric>gini [total-grants] of groups</metric>
    <metric>gini [n-publications] of groups</metric>
    <metric>sum [total-primary-publications] of groups</metric>
    <enumeratedValueSet variable="grants-per-funder">
      <value value="14"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="history-length">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pubs-vs-data">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="agent-orientation">
      <value value="&quot;all-myopic&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sharing-start">
      <value value="500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="rdm-cost">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="n-groups">
      <value value="100"/>
    </enumeratedValueSet>
    <steppedValueSet variable="importance-of-chance" first="0" step="0.1" last="1"/>
  </experiment>
  <experiment name="02-baseline-detail" repetitions="100" sequentialRunOrder="false" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>mean-grants groups</metric>
    <metric>mean-publications groups</metric>
    <metric>gini [total-grants] of groups</metric>
    <metric>gini [n-publications] of groups</metric>
    <metric>sum [total-primary-publications] of groups</metric>
    <enumeratedValueSet variable="grants-per-funder">
      <value value="14"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="history-length">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pubs-vs-data">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="agent-orientation">
      <value value="&quot;all-myopic&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sharing-start">
      <value value="500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="rdm-cost">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="n-groups">
      <value value="100"/>
    </enumeratedValueSet>
    <steppedValueSet variable="importance-of-chance" first="0.3" step="0.02" last="0.5"/>
  </experiment>
  <experiment name="03-baseline-end" repetitions="100" sequentialRunOrder="false" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>stuff</metric>
    <metric>gini [n-grants] of groups</metric>
    <metric>gini [n-publications] of groups</metric>
    <metric>sum [total-primary-publications] of groups</metric>
    <enumeratedValueSet variable="grants-per-funder">
      <value value="14"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="history-length">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pubs-vs-data">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="agent-orientation">
      <value value="&quot;all-myopic&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sharing-start">
      <value value="500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="rdm-cost">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="n-groups">
      <value value="100"/>
    </enumeratedValueSet>
    <steppedValueSet variable="importance-of-chance" first="0.36" step="0.02" last="0.44"/>
  </experiment>
  <experiment name="04-rational" repetitions="100" sequentialRunOrder="false" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>gini [n-grants] of groups ; current grants</metric>
    <metric>gini [n-pubs-this-round] of groups ; publications of the current round</metric>
    <metric>gini [publications-with-data-shared] of groups ; this is the number of datasets in this round</metric>
    <metric>count datasets</metric>
    <metric>sum [n-pubs-this-round] of groups</metric>
    <metric>sum [total-primary-publications] of groups</metric>
    <metric>sum [total-datasets] of groups</metric>
    <metric>count groups with [data-sharing?]</metric>
    <metric>mean-datasets-q1</metric>
    <metric>mean-datasets-q2</metric>
    <metric>mean-datasets-q3</metric>
    <metric>mean-datasets-q4</metric>
    <metric>data-sharers-within-group groups with [publication-quantile = "q[0-25]"]</metric>
    <metric>data-sharers-within-group groups with [publication-quantile = "q(25-50]"]</metric>
    <metric>data-sharers-within-group groups with [publication-quantile = "q(50-75]"]</metric>
    <metric>data-sharers-within-group groups with [publication-quantile = "q(75-100]"]</metric>
    <enumeratedValueSet variable="grants-per-funder">
      <value value="14"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="history-length">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pubs-vs-data">
      <value value="0.5"/>
      <value value="0.85"/>
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="agent-orientation">
      <value value="&quot;all-long-term&quot;"/>
      <value value="&quot;all-myopic&quot;"/>
      <value value="&quot;uniform&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="rdm-cost">
      <value value="0"/>
      <value value="0.05"/>
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sharing-start">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="data-sharers">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="n-groups">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="importance-of-chance">
      <value value="0.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="learning-mechanism">
      <value value="&quot;learn-rationally&quot;"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="05-social" repetitions="100" sequentialRunOrder="false" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>gini [n-grants] of groups ; current grants</metric>
    <metric>gini [n-pubs-this-round] of groups ; publications of the current round</metric>
    <metric>gini [publications-with-data-shared] of groups ; this is the number of datasets in this round</metric>
    <metric>count datasets</metric>
    <metric>sum [n-pubs-this-round] of groups</metric>
    <metric>sum [total-primary-publications] of groups</metric>
    <metric>sum [total-datasets] of groups</metric>
    <metric>count groups with [data-sharing?]</metric>
    <metric>mean-datasets-q1</metric>
    <metric>mean-datasets-q2</metric>
    <metric>mean-datasets-q3</metric>
    <metric>mean-datasets-q4</metric>
    <metric>data-sharers-within-group groups with [publication-quantile = "q[0-25]"]</metric>
    <metric>data-sharers-within-group groups with [publication-quantile = "q(25-50]"]</metric>
    <metric>data-sharers-within-group groups with [publication-quantile = "q(50-75]"]</metric>
    <metric>data-sharers-within-group groups with [publication-quantile = "q(75-100]"]</metric>
    <enumeratedValueSet variable="grants-per-funder">
      <value value="14"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="history-length">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pubs-vs-data">
      <value value="0.5"/>
      <value value="0.85"/>
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="agent-orientation">
      <value value="&quot;all-long-term&quot;"/>
      <value value="&quot;all-myopic&quot;"/>
      <value value="&quot;uniform&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="rdm-cost">
      <value value="0"/>
      <value value="0.05"/>
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sharing-start">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="data-sharers">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="n-groups">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="importance-of-chance">
      <value value="0.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="learning-mechanism">
      <value value="&quot;learn-socially&quot;"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="06-success-of-groups" repetitions="100" sequentialRunOrder="false" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>mean-grants-q1</metric>
    <metric>mean-grants-q2</metric>
    <metric>mean-grants-q3</metric>
    <metric>mean-grants-q4</metric>
    <enumeratedValueSet variable="grants-per-funder">
      <value value="14"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="history-length">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pubs-vs-data">
      <value value="0.5"/>
      <value value="0.85"/>
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="agent-orientation">
      <value value="&quot;all-long-term&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="rdm-cost">
      <value value="0"/>
      <value value="0.05"/>
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sharing-start">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="data-sharers">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="n-groups">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="importance-of-chance">
      <value value="0.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="learning-mechanism">
      <value value="&quot;learn-socially&quot;"/>
      <value value="&quot;learn-rationally&quot;"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="05a-social-sensitivity" repetitions="100" sequentialRunOrder="false" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>gini [n-grants] of groups</metric>
    <metric>gini [n-publications] of groups</metric>
    <metric>gini [total-datasets] of groups</metric>
    <metric>count datasets</metric>
    <metric>sum [n-pubs-this-round] of groups</metric>
    <metric>sum [total-primary-publications] of groups</metric>
    <metric>sum [total-datasets] of groups</metric>
    <metric>count groups with [data-sharing?]</metric>
    <metric>mean-datasets-q1</metric>
    <metric>mean-datasets-q2</metric>
    <metric>mean-datasets-q3</metric>
    <metric>mean-datasets-q4</metric>
    <metric>data-sharers-within-group groups with [publication-quantile = "q[0-25]"]</metric>
    <metric>data-sharers-within-group groups with [publication-quantile = "q(25-50]"]</metric>
    <metric>data-sharers-within-group groups with [publication-quantile = "q(50-75]"]</metric>
    <metric>data-sharers-within-group groups with [publication-quantile = "q(75-100]"]</metric>
    <metric>mean-grants-q1</metric>
    <metric>mean-grants-q2</metric>
    <metric>mean-grants-q3</metric>
    <metric>mean-grants-q4</metric>
    <enumeratedValueSet variable="grants-per-funder">
      <value value="14"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="history-length">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pubs-vs-data">
      <value value="0.5"/>
      <value value="0.85"/>
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="agent-orientation">
      <value value="&quot;all-long-term&quot;"/>
      <value value="&quot;all-myopic&quot;"/>
      <value value="&quot;uniform&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="rdm-cost">
      <value value="0"/>
      <value value="0.05"/>
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sharing-start">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="data-sharers">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="n-groups">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="importance-of-chance">
      <value value="0.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="learning-mechanism">
      <value value="&quot;learn-socially&quot;"/>
    </enumeratedValueSet>
  </experiment>
</experiments>
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
