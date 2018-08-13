function make_at_measure(varargin)

import shared_utils.io.fload;
ff = @fullfile;

defaults = bfw.get_common_make_defaults();
defaults.within = { 'looks_to', 'looks_by' };
defaults.summary_function = @rowops.nanmean;
defaults.input_dir = '';
defaults.output_dir = '';
defaults.meas_type = '';
defaults.z_score = true;

params = bfw.parsestruct( defaults, varargin );

conf = params.config;

if ( isempty(params.input_dir) || isempty(params.output_dir) )
  error( '`input_dir` and `output_dir` must be specified.' );
end

if ( isempty(params.meas_type) )
  error( '`meas_type` must be specified.' );
end

input_dir = params.input_dir;
output_dir = params.output_dir;
isd = params.input_subdir;
osd = params.output_subdir;

meas_type = params.meas_type;

meas_p = bfw.gid( ff(input_dir, isd), conf );
output_p = bfw.gid( ff(output_dir, osd), conf );

meas_mats = bfw.require_intermediate_mats( params.files, meas_p, params.files_containing );

for i = 1:numel(meas_mats)
  fprintf( '\n %d of %d', i, numel(meas_mats) );
  
  meas = fload( meas_mats{i} );
  
  un_filename = meas.unified_filename;
  
  output_filename = fullfile( output_p, un_filename );
  
  if ( bfw.conditional_skip_file(output_filename, params.overwrite) )
    continue;
  end
  
  shared_utils.io.require_dir( output_p );
  
  if ( meas.is_link )
    meas_struct = struct();
    meas_struct.is_link = true;
    meas_struct.data_file = meas.data_file;
    meas_struct.unified_filename = un_filename;
    do_save( output_filename, meas_struct );
    continue;
  end
  
  output_measure = meas.(meas_type);
  
  for j = 1:numel(output_measure)
    c_meas = output_measure{j};
    c_meas = c_meas.each1d( params.within, params.summary_function );
    
    if ( params.z_score )
      dat = c_meas.data;
      dat_b = output_measure{j}.data;
      
      mean_1d = rowops.nanmean( dat_b );
      std_1d = rowops.nanstd( dat_b );
      
      for k = 1:size(dat, 1)
        dat(k, :, :) = (dat(k, :, :) - mean_1d) ./ std_1d;
      end
      
      c_meas.data = dat;
    end
    
    output_measure{j} = c_meas;
  end
  
  meas_struct = struct();
  meas_struct.is_link = false;
  meas_struct.measure = Container.concat( output_measure );
  meas_struct.frequencies = meas.frequencies;
  meas_struct.unified_filename = un_filename;
  meas_struct.params = params;
  meas_struct.within_trial_params = meas.params;
  meas_struct.align_params = meas.align_params;
  do_save( output_filename, meas_struct );
end

end

function do_save(filename, meas_struct)
save( filename, 'meas_struct' );
end