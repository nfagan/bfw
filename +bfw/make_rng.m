function make_rng(varargin)

ff = @fullfile;

defaults = bfw.get_common_make_defaults();

params = bfw.parsestruct( defaults, varargin );

conf = params.config;
isd = params.input_subdir;
osd = params.output_subdir;

input_p = bfw.gid( ff('unified', isd), conf );
output_p = bfw.gid( ff('rng', osd), conf );

mats = bfw.require_intermediate_mats( params.files, input_p, params.files_containing );

for i = 1:numel(mats)
  bfw.progress( i, numel(mats), mfilename );
  
  un_file = shared_utils.io.fload( mats{i} );
  un_filename = un_file.m1.unified_filename;
  
  output_filename = fullfile( output_p, un_filename );
  
  if ( bfw.conditional_skip_file(output_filename, params.overwrite) )
    continue;
  end
  
  s = rng();
  
  rng_state = struct();
  rng_state.state = s;
  rng_state.unified_filename = un_filename;
  
  shared_utils.io.require_dir( output_p );
  
  save( output_filename, 'rng_state' );
end

end