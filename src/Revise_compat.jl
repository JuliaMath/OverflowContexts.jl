import .Revise: LineSkippingIterator, RelocatableExpr

Base.hash(x::RelocatableExpr, h::UInt) = hash(LineSkippingIterator(x.ex.args),
                                              hash(x.ex.head, @unchecked h + hashrex_seed))

@unchecked function Base.hash(iter::LineSkippingIterator, h::UInt)
    h += hashlsi_seed
    for x in iter
        if x isa Expr
            h += hash(LineSkippingIterator(x.args), hash(x.head, h + hashrex_seed))
        elseif x isa Symbol
            xs = String(x)
            if startswith(xs, '#')  # all gensymmed symbols are treated as identical
                h += hash("gensym", h)
            else
                h += hash(x, h)
            end
        elseif x isa Number
            h += hash(typeof(x), hash(x, h))::UInt
        else
            h += hash(x, h)::UInt
        end
    end
    h
end
