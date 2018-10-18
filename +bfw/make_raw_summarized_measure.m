function make_raw_summarized_measure(varargin)

defaults = bfw.get_common_make_defaults();
defaults.measure = '';
defaults.summary_func = @(x) nanmean(x, 1);

params = bfw.parsestruct( defaults, varargin );

conf = params.config;
isd = params.input_subdir;
osd = params.output_subdir;

meas_subdir = get_measure( params );

input_p = bfw.gid( fullfile(meas_subdir, isd), conf );
output_p = bfw.gid( sprintf('summarized_%s', meas_subdir, osd), conf );

mats = bfw.require_intermediate_mats( params.files, input_p, params.files_containing );

for i = 1:numel(mats)
  shared_utils.general.progress( i, numel(mats), mfilename );
  
  meas_file = shared_utils.io.fload( mats{i} );
  
  unified_filename = meas_file.unified_filename;
  output_filename = fullfile( output_p, unified_filename );
  
  if ( bfw.conditional_skip_file(output_filename, params.overwrite) )
    continue;
  end
  
  try
    labs = fcat.from( meas_file.labels, meas_file.categories );

    [summary_labs, I] = keepeach( labs', getcats(labs) );
    dat = rowop( meas_file.data, I, params.summary_func );
    
    assert_ispair( dat, summary_labs );
    
    summary_file = copy_meas_file( meas_file );
    summary_file.params = params;
    summary_file.data = dat;
    summary_file.labels = categorical( summary_labs );
    summary_file.categories = getcats( summary_labs );
    
    shared_utils.io.require_dir( output_p );
    shared_utils.io.psave( output_filename, summary_file, 'summary_file' );
  catch err
    bfw.print_fail_warn( unified_filename, err.message );
    continue;
  end
end

end

function summary_file = copy_meas_file(meas_file)

summary_file = struct();
summary_file.unified_filename = meas_file.unified_filename;
summary_file.f = meas_file.f;
summary_file.t = meas_file.t;
summary_file.was_reference_subtracted = meas_file.was_reference_subtracted;

end

function s = get_measure(params)

s = params.measure;
assert( ~isempty(s), 'Specify an "measure".' );

end