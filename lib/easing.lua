local easing = {
}

-- MODULE FUNCTIONS ------------------------------------------------------------

function easing.linear(value)
  return value
end

function easing.quadratic(value)
  return math.pow(value, 2.0)
end

-- END OF MODULE ---------------------------------------------------------------

return easing

-- END OF FILE -----------------------------------------------------------------
