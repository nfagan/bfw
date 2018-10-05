function make_raw_events(varargin)

import shared_utils.io.fload;

ff = @fullfile;

defaults = bfw.get_common_make_defaults();
defaults.duration = NaN;  % ms
defaults.bin_raw = true;
defaults.window_size = 10;
defaults.step_size = 10;
defaults.require_fixations = true;
defaults.fixations_subdir = 'eye_mmv_fixations';

params = bfw.parsestruct( defaults, varargin );

conf = params.config;
isd = params.input_subdir;
osd = params.output_subdir;
fsd = params.fixations_subdir;

duration = params.duration;
assert( ~isnan(duration), '"duration" cannot be nan.' );

aligned_samples_p = bfw.gid( ff('aligned_raw_samples', isd), conf );

bounds_p = ff( aligned_samples_p, 'bounds' );
time_p = ff( aligned_samples_p, 'time' );
fixations_p = ff( aligned_samples_p, fsd );

events_p = bfw.gid( ff('events', osd), conf );

mats = bfw.require_intermediate_mats( params.files, bounds_p, params.files_containing );

for i = 1:numel(mats)
  shared_utils.general.progress( i, numel(mats), mfilename );
  
  bounds_file = fload( mats{i} );
  
  unified_filename = bounds_file.unified_filename;
  
  try
    fix_file = fload( fullfile(fixations_p, unified_filename) ); 
    time_file = fload( fullfile(time_p, unified_filename) );
  catch err
    print_fail_warn( unified_filename, err.message );
    continue;
  end
  
  monk_ids = intersect( {'m1', 'm2'}, fieldnames(bounds_file) );
  
  should_save = true;
  
  t = time_file.t;
  
  for j = 1:numel(monk_ids)
    monk_id = monk_ids{j};
    
    bounds = bounds_file.(monk_id);
    is_fix = fix_file.(monk_id);
    
    try
      exclusive_evts = find_exclusive_events( t, bounds, is_fix, params );
    catch err
      print_fail_warn( unified_filename, err.message );
      should_save = false;
      break;  
    end
  end
  
  d = 10;
  
end

end

function outs = find_exclusive_events(t, bounds, is_fix, params)

import shared_utils.vector.slidebin;

roi_names = keys( bounds );

ws = params.window_size;
ss = params.step_size;
should_bin_raw = params.bin_raw;
duration = params.duration;

if ( should_bin_raw )  
  is_fix = cellfun( @any, slidebin(is_fix, ws, ss) );
  t = cellfun( @median, slidebin(t, ws, ss) );
  duration = round( duration / ss );
end

evts = [];
evt_names = {};

for i = 1:numel(roi_names)
  roi_name = roi_names{i};
  
  ib = bounds(roi_name);
  
  if ( should_bin_raw )
    ib = cellfun( @any, slidebin(ib, ws, ss) );
  end
  
  is_valid_sample = ib;
  
  if ( params.require_fixations )
    is_valid_sample = is_valid_sample & is_fix;
  end
  
  evts_this_roi = shared_utils.logical.find_starts( is_valid_sample, duration );
  evt_names_this_roi = repmat( {roi_name}, numel(evts_this_roi), 1 );
  
  evts = [ evts; evts_this_roi(:) ];
  evt_names = [ evt_names; evt_names_this_roi ];
end  

outs.indices = evts;
outs.ids = evt_names;
outs.t = t;

end

function print_fail_warn(un_file, msg)
warning( '"%s" failed: %s', un_file, msg );
end