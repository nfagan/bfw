function fs = m_fields(file)

fs = intersect( fieldnames(file), {'m1', 'm2'} );

end