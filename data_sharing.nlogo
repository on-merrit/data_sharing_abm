; ticks = 6 months
; default publishing rate: once every 6 months

breed [groups group]
breed [grants grant]
breed [datasets dataset]

groups-own [
  resources
  total-grants
  total-resources
  resources-for-data-paper
  chance
  proposal-strength
  data-sharing-policy?
  total-datasets
  n-publications
  default-publications
  total-default-publications
  data-publications
  total-data-publications
  n-pubs-this-round
  publication-success
  publication-history ; implementation of tracking the publication history was adapted from https://stackoverflow.com/a/59862247/3149349
]

grants-own [
  grant-year
]

datasets-own [
  dataset-year
]

to setup
  clear-all

  ask patches [set pcolor white]

  create-groups n-groups
  let pub-history-length history-length * 2 ; so a history of "3" years becomes 6 ticks = 3 years
  ask turtles [
    setxy random-xcor random-ycor
    set shape "person"
    set resources 1
    set proposal-strength 0
    set total-grants 0
    ; set data-sharing policy for now
    ifelse random-float 1 > .8 [ set data-sharing-policy? True ] [ set data-sharing-policy? False]
    set total-datasets 0
    set n-publications 0
    set n-pubs-this-round 0
    set publication-history n-values pub-history-length [0]
  ]


  reset-ticks
end


to go
  if ticks = 500 [stop] ; stop after 250 years (500)
  if not share-data? and reuse-data? [error "Data sharing has to be enabled to model data-reuse. Please set `share-data?` to `On`"]
  publish
  if share-data? [share-data]
  setup-grants
  allocate-grants
  update-indices

  tick
end

to publish
  ifelse not reuse-data? [
    ask groups [
      adjust-resources-when-data-sharing
      default-publishing
    ]
  ] [
    ask groups [
      adjust-resources-when-data-sharing
    ]

    ; choose some groups to re-use data
    let reusers n-of (.2 * n-groups) groups

    ; from https://stackoverflow.com/a/30966520/3149349
    let non-reusers groups with [not member? self reusers]

    ask non-reusers [
      default-publishing
    ]

    ask reusers [
      ifelse count datasets < 1 [
        ; if there are no datasets, publish as usual
        default-publishing
      ] [
        ; otherwise, create publications from data

        ; reduce resources by some factor (1 for now, so going for one data publication per tick on average)
        ifelse total-resources < 1 [
          set resources-for-data-paper total-resources * 1.2 ; it is easier to produce publications from data
          set total-resources 0
        ] [
          set resources-for-data-paper 1.2 ; it is easier to produce publications from data
          set total-resources total-resources - 1
        ]
        ; use the remaining resources to produce normal publications
        set default-publications random-poisson total-resources
        ; use the additional resources to consume a dataset, to produce a publication
        set data-publications random-poisson resources-for-data-paper
        ask n-of 1 datasets [ die ] ; let one random dataset die

        ; recalculate total publications based on the sum of both
        set n-pubs-this-round default-publications + data-publications

        ; update indices
        set n-publications n-publications + n-pubs-this-round
        set total-default-publications total-default-publications + default-publications
        set total-data-publications total-data-publications + data-publications
        set publication-history fput n-pubs-this-round but-last publication-history
      ]
    ]
  ]

end

to adjust-resources-when-data-sharing
  ifelse share-data? [
    ifelse data-sharing-policy? [
      let rdm-drag .05 * n-pubs-this-round ; rdm takes 5% of resources, determined from n-pubs last round
      set total-resources resources + n-grants - rdm-drag
      ] [
        set total-resources resources + n-grants
      ]
    ] [
        set total-resources resources + n-grants
    ]
end


to default-publishing
  set n-pubs-this-round random-poisson total-resources
  set default-publications n-pubs-this-round
  set n-publications n-publications + n-pubs-this-round

  set publication-history fput n-pubs-this-round but-last publication-history
end



to share-data
  ask groups with [data-sharing-policy?] [
   hatch-datasets n-pubs-this-round [ create-link-with myself ]

  ask datasets-here [
    set shape "box"
    move-to one-of neighbors
  ]

  set total-datasets total-datasets + 1
  ]
end

to setup-grants
  create-grants n-available-grants
  ; set up our new grants
  ask grants with [count link-neighbors = 0] [
    set grant-year -0.5 ; need to set grant year to negative, so the grant stays alive and has an effect for 6 rounds
    set shape "star"
    setxy random-xcor random-ycor
  ]
end

to award-grant
  create-link-with one-of grants with [count link-neighbors = 0]
  let group-neighbor one-of neighbors
  ask link-neighbors with [breed = grants] [move-to group-neighbor]
  ; the above is not ideal, since every grant is moved to the same patch. but not too important now

  set total-grants total-grants + 1
end


to allocate-grants
  ask groups [
    set chance random-float 1
    set publication-success median publication-history
  ]

  let max-pub-success max [publication-success] of groups
  ; ensure we do not divide by zero
  if max-pub-success = 0 [ set max-pub-success 1 ]

  ask groups [
    set publication-success publication-success / max-pub-success ; standardise publication success
    set proposal-strength chance * importance-of-chance + (1 - importance-of-chance) * publication-success
  ]

  ; implementation adapted from https://stackoverflow.com/a/38268346/3149349
  let rank-list sort-on [(- proposal-strength)] groups ; need to invert proposal-strength, so that higher values are on top of the list
  let top-groups sublist rank-list 0 n-available-grants

  foreach top-groups [ x -> ask x [ award-grant ] ]

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

end

; maybe these reporters could be improved by passing the "n-grants" or "n-publications" to the same procedure
to-report grants-gini
  ; adapted from the peer reviewer game, bianchi et al. DOI: 10.1007/s11192-018-2825-4 (https://www.comses.net/codebases/6b77a08b-7e60-4f47-9ebb-6a8a2e87f486/releases/1.0.0/)
  let list1 [who] of groups
  let list2 [who] of groups
  let s 0
  foreach list1 [ ?1 ->
    let temp [n-grants] of group ?1
    foreach list2 [ ??1 ->
      set s s + abs(temp - [n-grants] of group ??1)
    ]
  ]
  let gini-index s / (2 * (mean [n-grants] of groups) * (count groups) ^ 2)
  report gini-index
end


to-report publications-gini
  let list1 [who] of groups
  let list2 [who] of groups
  let s 0
  foreach list1 [ ?1 ->
    let temp [n-publications] of group ?1
    foreach list2 [ ??1 ->
      set s s + abs(temp - [n-publications] of group ??1)
    ]
  ]
  let gini-index s / (2 * (mean [n-publications] of groups) * (count groups) ^ 2)
  report gini-index
end


to-report n-grants
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

to-report mean-default-publications [ agentset ]
  report precision mean [total-default-publications] of agentset 2
end

to-report mean-data-publications [ agentset ]
  report precision mean [total-data-publications] of agentset 2
end
@#$#@#$#@
GRAPHICS-WINDOW
45
131
481
568
-1
-1
12.97
1
10
1
1
1
0
1
1
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
640
47
703
80
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
507
46
570
79
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
533
314
831
547
mean-publications
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
"data sharers" 1.0 0 -5298144 true "" "plot mean-publications groups with [data-sharing-policy?]"
"others" 1.0 0 -7500403 true "" "plot mean-publications groups with [not data-sharing-policy?]"

PLOT
832
314
1160
549
n-publications distribution
NIL
NIL
0.0
3000.0
0.0
10.0
true
false
"" ""
PENS
"default" 40.0 1 -16777216 true "" "histogram [n-publications] of groups"

BUTTON
575
47
638
80
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
27
196
60
n-groups
n-groups
20
1000
100.0
1
1
NIL
HORIZONTAL

SLIDER
196
26
368
59
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
yearly publications
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
1161
314
1461
550
mean number of grants
NIL
NIL
0.0
5.0
0.0
0.2
true
true
"" ""
PENS
"data-sharers" 1.0 0 -5298144 true "" "plot mean-grants groups with [data-sharing-policy?]"
"others" 1.0 0 -7500403 true "" "plot mean-grants groups with [not data-sharing-policy?]"

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

SWITCH
369
25
492
58
share-data?
share-data?
0
1
-1000

SLIDER
23
61
195
94
n-available-grants
n-available-grants
1
100
6.0
1
1
NIL
HORIZONTAL

SLIDER
197
62
369
95
importance-of-chance
importance-of-chance
0
1
0.4
.1
1
NIL
HORIZONTAL

PLOT
1461
313
1777
548
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
"grants" 1.0 0 -14070903 true "" "plot grants-gini"
"publications" 1.0 0 -5298144 true "" "plot publications-gini"

SWITCH
371
62
494
95
reuse-data?
reuse-data?
0
1
-1000

PLOT
534
547
830
751
data vs default publications
NIL
NIL
0.0
4.0
0.0
4.0
true
true
"" ""
PENS
"default" 1.0 0 -9276814 true "" "plot mean-default-publications groups "
"data" 1.0 0 -5298144 true "" "plot mean-data-publications groups "

PLOT
833
548
1160
753
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
  <experiment name="experiment" repetitions="10" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>mean-grants groups with [data-sharing-policy?]</metric>
    <metric>mean-grants groups with [not data-sharing-policy?]</metric>
    <metric>mean-publications groups with [data-sharing-policy?]</metric>
    <metric>mean-publications groups with [not data-sharing-policy?]</metric>
    <enumeratedValueSet variable="history-length">
      <value value="18"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mechanism">
      <value value="&quot;grant-history&quot;"/>
      <value value="&quot;grant-random&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="n-groups">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="share-data?">
      <value value="true"/>
      <value value="false"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="baseline" repetitions="5" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>mean-grants groups</metric>
    <metric>mean-publications groups</metric>
    <metric>grants-gini</metric>
    <metric>publications-gini</metric>
    <enumeratedValueSet variable="history-length">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="n-available-grants">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="n-groups">
      <value value="100"/>
    </enumeratedValueSet>
    <steppedValueSet variable="importance-of-chance" first="0" step="0.2" last="1"/>
    <enumeratedValueSet variable="share-data?">
      <value value="false"/>
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
