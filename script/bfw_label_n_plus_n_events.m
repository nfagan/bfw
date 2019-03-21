function [labels, intervals] = bfw_label_n_plus_n_events(start_times, labels, I, varargin)

assert_ispair( start_times, labels );

defaults = struct();
defaults.n_next = 1;
defaults.next_category_names = { 'roi', 'looks_by' };
defaults.mask_inputs = {};

params = bfw.parsestruct( defaults, varargin );

next_cats = params.next_category_names;
N = params.n_next;
mask_inputs = params.mask_inputs;

next_cat_names = cellfun( @(x) sprintf('next_%s', x), next_cats, 'un', 0 );
addcat( labels, next_cat_names );

intervals = nan( numel(start_times), 1 );

for i = 1:numel(I)
  mask = fcat.mask( labels, I{i}, mask_inputs{:} );
  
  begin = 1;
  stop = numel( mask ) - N;

  for j = begin:stop
    current_row = mask(j);
    next_row = mask(j + N);

    for k = 1:numel(next_cats)
      next_lab = char( cellstr(labels, next_cats{k}, next_row) );
      next_lab = sprintf( 'next_%s', next_lab );

      setcat( labels, next_cat_names{k}, next_lab, current_row );
    end    

    current_start = start_times(current_row);
    next_start = start_times(next_row);
    
    intervals(current_row) = next_start - current_start;
  end
end


end