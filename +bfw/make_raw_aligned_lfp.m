function make_raw_aligned_lfp(varargin)

import shared_utils.io.fload;

defaults = bfw.get_common_make_defaults();
defaults.window_size = 150;
defaults.look_back = -500;
defaults.look_ahead = 500;
defaults.sample_rate = 1e3;

params = bfw.parsestruct( defaults, varargin );

conf = params.config;
isd = params.input_subdir;
osd = params.output_subdir;
files = params.files;
fc = params.files_containing;

data_root = bfw.dataroot( conf );

plex_meta_p = bfw.gid( fullfile('plex_meta', isd), conf );
event_p = bfw.gid( fullfile('raw_events', isd), conf );
lfp_p = bfw.gid( fullfile('lfp', isd), conf );
aligned_p = bfw.gid( fullfile('raw_aligned_lfp', osd), conf );

mats = bfw.require_intermediate_mats( files, plex_meta_p, fc );

lfp_map = containers.Map();

for i = 1:numel(mats)
  shared_utils.general.progress( i, numel(mats), mfilename );
  
  meta_file = fload( mats{i} );
  
  unified_filename = meta_file.unified_filename;
  output_filename = fullfile( aligned_p, unified_filename );
  
  if ( bfw.conditional_skip_file(output_filename, params.overwrite) )
    continue;
  end
  
  try
    events_file = fload( fullfile(event_p, unified_filename) );
    lfp_file = fload( fullfile(lfp_p, unified_filename) );
    
    if ( lfp_file.is_link )
      lfp_file = shared_utils.io.fload( fullfile(lfp_p, unified_filename) );
    end
    
    get_aligned_lfp( lfp_file, events_file, meta_file, params );
    
  catch err
    bfw.print_fail_warn( unified_filename, err.message );
    continue;
  end
end

end

function get_aligned_lfp(lfp_file, meta_file, events_file, params)
end