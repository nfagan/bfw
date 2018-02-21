function make_event_aligned_gaze(varargin)

import shared_utils.io.fexists;
import shared_utils.vector.find_nearest;

defaults = bfw.get_common_make_defaults();
defaults.look_back = -0.5;
defaults.look_ahead = 0.5;

params = bfw.parsestruct( defaults, varargin );

event_p = bfw.get_intermediate_directory( 'events' );
aligned_p = bfw.get_intermediate_directory( 'aligned' );
start_p = bfw.get_intermediate_directory( 'start_stop' );
output_p = bfw.get_intermediate_directory( 'event_aligned_gaze' );

event_mats = bfw.require_intermediate_mats( params.files, event_p, params.files_containing );

look_back = params.look_back;
look_ahead = params.look_ahead;

for i = 1:numel(event_mats)
  fprintf( '\n %d of %d', i, numel(event_mats) );
  
  events = shared_utils.io.fload( event_mats{i} );
  
  un_filename = events.unified_filename;
  
  aligned_filename = fullfile( aligned_p, un_filename );
  start_filename = fullfile( start_p, un_filename );
  
  if ( ~fexists(aligned_filename) || ~fexists(start_filename) )
    fprintf( '\n Missing aligned or start file for "%s".', un_filename );
    continue;
  end
  
  aligned = shared_utils.io.fload( aligned_filename );
  starts = shared_utils.io.fload( start_filename );
  
  output_filename = fullfile( output_p, un_filename );
  
  if ( bfw.conditional_skip_file(output_filename, params.overwrite) )
    continue;
  end
  
  is_plex_time = false;
  
  if ( events.adjustments.isKey('to_plex_time') )
    is_plex_time = true;
  end
  
  if ( is_plex_time )
    start_t = starts.fv_plex_start;
  else
    start_t = starts.fv_mat_start;
  end
  
  event_times = cellfun( @(x) x - start_t, events.times, 'un', false );
  id_times = aligned.m1.time;
  
  rois = events.roi_key.keys();
  monks = events.monk_key.keys();
  
  total_n_events = sum( sum(cellfun(@numel, event_times)) );
  total_n_samples = ceil(look_ahead - look_back) * aligned.params.fs;
  
  x_data = zeros( total_n_events, total_n_samples );
  y_data = zeros( size(x_data) );
  
  for j = 1:numel(rois)
    for k = 1:numel(monks)
      row = events.roi_key(rois{j});
      col = events.monk_key(monks{k});
      c_event_times = event_times{row, col}(:);
      
      start_ts = c_event_times + look_back;
      end_ts = c_event_times + look_ahead;
      
      start_inds = arrayfun( @(x) find_nearest(id_times, x), start_ts );
      end_inds = arrayfun( @(x) find_nearest(id_times, x), end_ts );
      t0_ind = arrayfun( @(x) find_nearest(id_times, x), c_event_times );
      
      start_offsets = (t0_ind - start_inds) - (abs(look_back) * aligned.params.fs);
      end_offsets = (end_inds - t0_ind) - (abs(look_ahead) * aligned.params.fs);
      
      if ( any(start_offsets ~= 0) || any(end_offsets ~= 0) )
        d = 10;
      end
      
%       for h = 1:numel(start_inds)
%         
%       end
    end
  end
end

end