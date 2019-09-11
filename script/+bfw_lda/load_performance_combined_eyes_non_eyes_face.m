function perf = load_performance_combined_eyes_non_eyes_face(enef_dir, rest_dir, varargin)

enef_perf = bfw_lda.load_performance( enef_dir, varargin{:} );
rest_perf = bfw_lda.load_performance( rest_dir, varargin{:} );

fields = intersect( fieldnames(enef_perf), fieldnames(rest_perf) );
perf = struct();

for i = 1:numel(fields)
  f = fields{i};
  
  enef = enef_perf.(f);
  
  if ( isempty(enef) )
    perf.(f) = [];
  else
    rest = rest_perf.(f);
    
    if ( isempty(rest) )
      perf.(f) = enef;
    else
      src_ind = find( enef.labels, 'eyes_nf/face' );
      dest_ind = findnot( rest.labels, 'eyes_nf/face' );
      
      rest_labs = prune( rest.labels(dest_ind) );
      rest_performance = rest.performance(dest_ind, :);
      
      enef_labs = prune( enef.labels(src_ind) );
      enef_performance = enef.performance(src_ind, :);
      
      perf.(f) = enef;
      perf.(f).performance = [ enef_performance; rest_performance ];
      perf.(f).labels = [ enef_labs'; rest_labs ];
    end
  end
end

end