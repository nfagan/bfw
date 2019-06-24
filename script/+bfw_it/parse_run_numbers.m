function nums = parse_run_numbers(strs)

strs = cellstr( strs );
nums = nan( size(strs) );
prefix = 'run_number-';
n_prefix = numel( prefix );

for i = 1:numel(strs)
  str = strs{i};
  max_ind = numel( str );
  
  if ( max_ind < n_prefix+1 )
    continue;
  end
  
  nums(i) = str2double( str(n_prefix+1:end) );
end

end