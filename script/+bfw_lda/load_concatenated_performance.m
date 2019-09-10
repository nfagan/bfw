function perf = load_concatenated_performance(load_func, load_func_inputs, mask_func)

perf = struct();

for i = 1:numel(load_func_inputs)
  tmp_perf = load_func( load_func_inputs{i}{:} );
  fields = fieldnames( tmp_perf );
  
  for j = 1:numel(fields)
    f = fields{j};
    
    if ( ~isempty(tmp_perf.(f)) )
      keep_ind = mask_func( tmp_perf.(f).labels, i );
      tmp_perf.(f).performance = indexpair( tmp_perf.(f).performance, tmp_perf.(f).labels, keep_ind );
    end

    if ( i == 1 )      
      perf.(f) = tmp_perf.(f);
    elseif ( ~isempty(tmp_perf.(f)) )
      perf.(f).performance = [ perf.(f).performance; tmp_perf.(f).performance ];
      perf.(f).labels = [ perf.(f).labels; tmp_perf.(f).labels ];
    end
  end
end

end