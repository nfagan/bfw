function make_raw_events(varargin)

import shared_utils.io.fload;

ff = @fullfile;

defaults = bfw.get_common_make_defaults();
defaults.duration = NaN;  % ms
defaults.require_fixations = true;
defaults.fixations_subdir = 'eye_mmv_fixations';
defaults.samples_subdir = 'aligned_binned_raw_samples';

params = bfw.parsestruct( defaults, varargin );

conf = params.config;
isd = params.input_subdir;
osd = params.output_subdir;
fsd = params.fixations_subdir;
ssd = params.samples_subdir;

duration = params.duration;
assert( ~isnan(duration), '"duration" cannot be nan.' );

aligned_samples_p = bfw.gid( ff(ssd, isd), conf );

time_p = ff( aligned_samples_p, 'time' );
bounds_p = ff( aligned_samples_p, 'bounds' );
fixations_p = ff( aligned_samples_p, fsd );

events_p = bfw.gid( ff('raw_events', osd), conf );

mats = bfw.require_intermediate_mats( params.files, time_p, params.files_containing );

for i = 1:numel(mats)
  shared_utils.general.progress( i, numel(mats), mfilename );
  
  time_file = fload( mats{i} );
  
  unified_filename = time_file.unified_filename;
  
  try
    bounds_file = fload( fullfile(bounds_p, unified_filename) );
    fix_file = fload( fullfile(fixations_p, unified_filename) ); 
  catch err
    print_fail_warn( unified_filename, err.message );
    continue;
  end
  
  monk_ids = intersect( {'m1', 'm2'}, fieldnames(bounds_file) );
  
  should_save = true;
  
  t = time_file.t;
  
  exclusive_events = struct();
  
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
    
    exclusive_events.(monk_id) = exclusive_evts;
  end
  
  d = 10;
  
end

end

function outs = find_exclusive_events(t, bounds, is_fix, params)

import shared_utils.vector.slidebin;

roi_names = keys( bounds );

duration = params.duration;

evts = [];
evt_names = {};

for i = 1:numel(roi_names)
  roi_name = roi_names{i};
    
  is_valid_sample = bounds(roi_name);
  
  if ( params.require_fixations )
    is_valid_sample = is_valid_sample & is_fix;
  end
  
  evts_this_roi = shared_utils.logical.find_starts( is_valid_sample, duration );
  evt_names_this_roi = repmat( {roi_name}, numel(evts_this_roi), 1 );
  
  evts = [ evts; evts_this_roi(:) ];
  evt_names = [ evt_names; evt_names_this_roi ];
end  

outs.indices = evts;
outs.times = columnize( t(evts) );
outs.ids = evt_names;

end

function print_fail_warn(un_file, msg)
warning( '"%s" failed: %s', un_file, msg );
end