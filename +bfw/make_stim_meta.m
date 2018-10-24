function make_stim_meta(varargin)

defaults = bfw.get_common_make_defaults();

params = bfw.parsestruct( defaults, varargin );

conf = params.config;
isd = params.input_subdir;
osd = params.output_subdir;

un_p = bfw.gid( fullfile('unified', isd), conf );
meta_p = bfw.gid( fullfile('stim_meta', osd), conf );

mats = bfw.require_intermediate_mats( params.files, un_p, params.files_containing );

parfor i = 1:numel(mats)
  shared_utils.general.progress( i, numel(mats), mfilename );
  
  un_file = shared_utils.io.fload( mats{i} );
  
  unified_filename = un_file.m1.unified_filename;
  output_filename = fullfile( meta_p, unified_filename );
  
  if ( bfw.conditional_skip_file(output_filename, params.overwrite) )
    continue;
  end
  
  try
    stim_meta_file = stim_meta_main( un_file, unified_filename );
    
    shared_utils.io.require_dir( meta_p );
    shared_utils.io.psave( output_filename, stim_meta_file, 'stim_meta_file' );
    
  catch err
    bfw.print_fail_warn( unified_filename, err.message );
  end
end

end

function stim_meta_file = stim_meta_main(un_file, unified_filename)

stim_meta_file = struct();
stim_meta_file.unified_filename = unified_filename;
stim_meta_file.used_stimulation = false;

% preceded introduction of stimulation
if ( ~isfield(un_file.m1, 'stimulation_params') )
  return; 
end

stim_params = un_file.m1.stimulation_params;

% run on which stimulation was not used
if ( ~stim_params.use_stim_comm )
  return; 
end

stim_meta_file.used_stimulation = true;

fs = fieldnames( stim_params );

for i = 1:numel(fs)
  stim_meta_file.(fs{i}) = stim_params.(fs{i});  
end

stim_meta_file.protocol_name = bfw.get_stim_protocol_name( stim_params.protocol );

end