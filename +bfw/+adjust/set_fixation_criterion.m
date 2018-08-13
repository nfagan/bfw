function set_fixation_criterion(varargin)

defaults = bfw.get_common_make_defaults();
defaults.duration = 100;  % ms;

params = bfw.parsestruct( defaults, varargin );
conf = params.config;

fix_p = bfw.get_intermediate_directory( 'fixations', conf );

fix_mats = bfw.require_intermediate_mats( params.files, fix_p, params.files_containing );

parfor i = 1:numel(fix_mats)
  fprintf( '\n %d of %d', i, numel(fix_mats) );
  
  fix_file = shared_utils.io.fload( fix_mats{i} );
  
  fields = { 'm1', 'm2' };
  
  for j = 1:numel(fields)
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
  
  fix_file.adjust_params = params;
  
  do_save( fix_mats{i}, fix_file );
end

end

function do_save( filename, fix_file )

save( filename, 'fix_file' );

end