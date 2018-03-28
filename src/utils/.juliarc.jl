# .juliarc.jl file
# Holger Teichgraeber - hteich@stanford.edu
# March 2018

"""
struct Col
  lblue::String 
  dblue::String
  lgreen::String
  dgreen::String
  orange::String
  red::String
  purple::String
  brown::String
  grey ::String
  yellow::String
end
Defines a struct that holds colors (used for stanford colors)
"""
struct Col
  lblue::String 
  dblue::String
  lgreen::String
  dgreen::String
  orange::String
  red::String
  purple::String
  brown::String
  grey ::String
  yellow::String
end

"""
"""
function get_colors(c::Col)
  println(fieldnames(c))
end

 # Stanford Colors
StanfordLBlue = "#0098db" #Sky
StanfordOrange = "#e98300" # Poppy
StanfordLGreen = "#009b76" # Mint
StanfordRed = "#B1040E" # bright Red
StanfordPurple = "#53284f" # Purple
StanfordBrown = "#8d3c1e" # Redwood
StanfordGrey = "#928b81" #Stone legacy
StanfordYellow = "#eaab00" # Sun
StanfordDGreen = "#175e54" # Palo Alto
StanfordDBlue = "#00548f" # Link Hover
const col = Col(StanfordLBlue,StanfordDBlue,StanfordLGreen,StanfordDGreen,StanfordOrange,StanfordRed,StanfordPurple,StanfordBrown,StanfordGrey,StanfordYellow)

# iterable color object
const cols = [StanfordLGreen,StanfordOrange,StanfordLBlue,StanfordRed,StanfordYellow,StanfordPurple,StanfordBrown,StanfordGrey,StanfordDBlue,StanfordDGreen]

