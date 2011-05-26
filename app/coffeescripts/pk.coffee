PK ?= {}

PK.render = (template, args) ->
  # we explicitly don't support multiple arguments to JST because JST rendering only takes a single hash argument
  args = [args] unless args?.length?
  templateFn = JST[if PK.mobile && JST["mobile_#{template}"] then "mobile_#{template}" else template]
  if templateFn
    templateFn.apply(window, args) 
  else
    throw "Unable to find template #{template}!"
