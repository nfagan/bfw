function make_edf_blink_info(varargin)

ff = @fullfile;

defaults = bfw.get_common_make_defaults();
params = bfw.parsestruct( defaults, varargin );

conf = params.config;

isd = params.input_subdir;
osd = params.output_subdir;

edf_p = bfw.gid( ff('edf', isd), conf );
save_p = bfw.gid( ff('blinks', osd), conf );

shared_utils.io.require_dir( save_p );

edfs = bfw.require_intermediate_mats( params.files, edf_p, params.files_containing );

for i = 1:numel(edfs)
  fprintf( '\n %d of %d', i, numel(edfs) );
  
  edf = shared_utils.io.fload( edfs{i} );
  
  fields = fieldnames( edf );
  
  unified_filename = edf.(fields{1}).unified_filename;
  
  filename = fullfile( save_p, unified_filename );
  
  if ( bfw.conditional_skip_file(filename, params.overwrite) ), continue; end
  
  blink_info = struct();
  
  for j = 1:numel(fields)
    c_edf = edf.(fields{j}).edf;
    
    s_blinks = c_edf.Events.Eblink.start;
    e_blinks = c_edf.Events.Eblink.end;
    
    blink_info.(fields{j}).starts = s_blinks;
    blink_info.(fields{j}).ends = e_blinks;
    blink_info.(fields{j}).durations = e_blinks - s_blinks;
    
    blink_info.(fields{j}).unified_filename = edf.(fields{j}).unified_filename;
  end
  
  save( filename, 'blink_info' );
end