agents={
    "/home/arpad/Documents/MAS/PlanetConqueror/base.lua", 1,
}
param = {
     {1},        -- Parameter '1', is a static parameter which is accessible by the agents.
     {1,1},    -- Parameter '2', going from 1 to 100, with step increments of 1.
     {100},         -- C
     {5},           -- D
     {150},         -- E
     {200},         -- G
     {20},          -- I
     {0},           -- M
     {1},           -- N
     {8},           -- P
     {1},           -- Q
     {3},           -- S
     {100},         -- T
     {6},           -- W
     {2},           -- X
     {3},           -- Y
}
sim={
     eDistPrecision = 0.000001,
     stepPrecision  = 0.001,
     runTime        = 500,
     mapWidth       = 200,
     mapHeight      = 200,
     mapScale       = 1.0,
     simThreads     = 4,
}