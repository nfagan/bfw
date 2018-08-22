function set_fixation_criterion(varargin)

ff = @fullfile;

defaults = bfw.get_common_make_defaults();
defaults.duration = 100;  % ms;

params = bfw.parsestruct( defaults, varargin );
conf = params.config;

isd = params.input_subdir;
osd = params.output_subdir;

fix_p = bfw.gid( ff('fixations', isd), conf );
save_p = bfw.gid( ff('fixations', osd), conf );

fix_mats = bfw.require_intermediate_mats( params.files, fix_p, params.files_containing );

parfor i = 1:numel(fix_mats)
  fprintf( '\n %d of %d', i, numel(fix_mats) );
  
  fix_file = shared_utils.io.fload( fix_mats{i} );
  un_filename = fix_file.unified_filename;
  
  fields = { 'm1', 'm2' };
  
  output_file = fullfile( save_p, un_filename );
  
  if ( bfw.conditional_skip_file(output_file, params.overwrite) )
    continue;
  end
  
  for j = 1:numel(fields)
    
    if ( ~isfield(fix_file, fields{j}) ), continue; end
    
    c_fix_file = fix_file.(fields{j});
    
    if ( ~isfield(c_fix_file, 'original') )
      c_fix_file.original = c_fix_file;
    end
    
    starts = c_fix_file.original.start_indices;
    stops = c_fix_file.original.stop_indices;
    is_fix = c_fix_file.original.is_fixation;   
    
    too_short_tf_ind = stops - starts < params.duration;
    too_short_num_ind = find( too_short_tf_ind );
    
    for k = 1:numel(too_short_num_ind)
      start = starts(too_short_num_ind(k));
      stop = stops(too_short_num_ind(k));
      is_fix(start:stop) = false;
    end
    
    c_fix_file.is_fixation = is_fix;
    c_fix_file.start_indices = starts( ~too_short_tf_ind );
    c_fix_file.stop_indices = stops( ~too_short_tf_ind );
    
    fix_file.(fields{j}) = c_fix_file;
  end
  
  shared_utils.io.require_dir( save_p );
  
  fix_file.adjust_params = params;
  
  do_save( output_file, fix_file );
end

end

function do_save( filename, fix_file )

save( filename, 'fix_file' );

end