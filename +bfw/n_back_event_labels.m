function [backs, back_ts] = n_back_event_labels(sorted_events, varargin)

defaults = struct();
defaults.num_back = -1;
defaults.each = { 'unified_filename' };
defaults.of = {'roi', 'looks_by'};
defaults.mask_func = @bfw.default_mask_func;

params = bfw.parsestruct( defaults, varargin );

num_back = params.num_back;
of = params.of;
each = params.each;
back_mask = params.mask_func( sorted_events.labels, rowmask(sorted_events.labels) );

ts = bfw.event_column( sorted_events, 'start_time' );
[back, back_ts] = bfw.n_back( sorted_events.labels, ts, each, of, num_back, back_mask );
backs = cell( size(back) );
back_str = sprintf( '%+d', num_back );

parfor i = 1:numel(backs)
  bck = char( back{i} );  % convert [] -> ''
  
  if ( isempty(bck) )
    backs{i} = bck;
  else
    backs{i} = sprintf( '%s_%s', bck, back_str );
  end
end

end