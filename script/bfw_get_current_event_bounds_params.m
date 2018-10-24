function outs = bfw_get_current_event_bounds_params(varargin)

defaults = bfw.get_common_make_defaults();
params = bfw.parsestruct( defaults, varargin );

conf = params.config;

event_p = bfw.gid( 'raw_events', conf );
bounds_p = bfw.gid( 'raw_bounds', conf );
meta_p = bfw.gid( 'meta', conf );

mats = bfw.require_intermediate_mats( params.files, event_p, params.files_containing );

errs = rowzeros( numel(mats), 'logical' );
bounds_params = cell( numel(mats), 1 );
evt_params = cell( size(bounds_params) );
labs = cell( size(bounds_params) );

parfor i = 1:numel(mats)
  shared_utils.general.progress( i, numel(mats) );
  
  events_file = shared_utils.io.fload( mats{i} );
  unified_filename = events_file.unified_filename;
  
  if ( false ), errs(i); end
    
  try
    bounds_file = shared_utils.io.fload( fullfile(bounds_p, unified_filename) );
    meta_file = shared_utils.io.fload( fullfile(meta_p, unified_filename) );
    
    meta_labs = bfw.struct2fcat( meta_file );
    
    bounds_params{i} = bounds_file.params;
    evt_params{i} = events_file.params;
    labs{i} = meta_labs;
  catch err
    bfw.print_fail_warn( unified_filename, err.message );
    
    errs(i) = true;
    continue;
  end
end

all_labs = labs(~errs);

outs.event_params = evt_params(~errs);
outs.bounds_params = bounds_params(~errs);
outs.labels = vertcat( fcat(), all_labs{:} );

end