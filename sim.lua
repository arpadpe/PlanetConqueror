agents={
    "/home/arpad/Documents/MAS/PlanetConqueror/base.lua", 1,
}
param = {
     {1},           -- Parameter '1', is a static parameter which is accessible by the agents.
     {1},           -- Parameter '2', going from 1 to 100, with step increments of 1.
     {50},          -- C
     {10},          -- D
     {200},         -- E
     {200},         -- G
     {20},          -- I
     {1},           -- M
     {3},           -- N
     {5},           -- P
     {2},           -- Q
     {9},           -- S
     {80},          -- T
     {5},           -- W
     {5},           -- X
     {5},           -- Y
}
sim={
     eDistPrecision = 0.000001,
     stepPrecision  = 0.001,
     runTime        = 100,
     mapWidth       = 200,
     mapHeight      = 200,
     mapScale       = 1.0,
     simThreads     = 4,
}