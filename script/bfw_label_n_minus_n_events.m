function [labels, intervals] = bfw_label_n_minus_n_events(start_times, labels, I, varargin)

assert_ispair( start_times, labels );

defaults = struct();
defaults.n_previous = 1;
defaults.previous_category_names = { 'roi', 'looks_by' };
defaults.mask_inputs = {};

params = bfw.parsestruct( defaults, varargin );

prev_cats = params.previous_category_names;
N = params.n_previous;
mask_inputs = params.mask_inputs;

prev_cat_names = cellfun( @(x) sprintf('previous_%s', x), prev_cats, 'un', 0 );
addcat( labels, prev_cat_names );

intervals = nan( numel(start_times), 1 );

for i = 1:numel(I)
  mask = fcat.mask( labels, I{i}, mask_inputs{:} );
  
  begin = 1 + N;
  stop = numel( mask );

  for j = begin:stop
    previous_row = mask(j - N);
    current_row = mask(j);

    for k = 1:numel(prev_cats)
      prev_lab = char( cellstr(labels, prev_cats{k}, previous_row) );
      prev_lab = sprintf( 'previous_%s', prev_lab );

      setcat( labels, prev_cat_names{k}, prev_lab, current_row );
    end    

    prev_start = start_times(previous_row);
    current_start = start_times(current_row);
    
    intervals(current_row) = current_start - prev_start;
  end
end


end