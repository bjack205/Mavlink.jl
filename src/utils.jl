
function camelcase(s::AbstractString, delim="_")
    join(uppercasefirst.(split(s, delim)))
end
camelcase(s::Symbol) = Symbol(camelcase(string(s)))