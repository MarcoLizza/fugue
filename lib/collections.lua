local collections = {
}

function collections.select(table, comparator)
  for key, value in pairs(table) do
    if comparator(key, value) then
      return value
    end
  end
  return nil
end

function collections.find(table, comparator)
  for key, value in pairs(table) do
    if comparator(key, value) then
      return key
    end
  end
  return nil
end

return collections
