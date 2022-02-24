function labels = apply_new_cell_id_labels(labels, id_matrix)

[unit_I, match_rows, new_ids] = bfw.find_new_id_labels( labels, id_matrix );
for i = 1:numel(unit_I)
  setcat( labels, 'unit_uuid', sprintf('unit_uuid__%s', new_ids{i}), unit_I{i} );
end

end