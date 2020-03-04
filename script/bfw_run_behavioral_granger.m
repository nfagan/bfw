function granger_outs = bfw_run_behavioral_granger(varargin)

defaults = bfw.get_common_plot_defaults( bfw.get_common_make_defaults() );
defaults.look_outputs = [];
defaults.file_name = 'auto';

params = bfw.parsestruct( defaults, varargin );

look_outputs = get_look_outputs( params );

%%

mask_func = @(labels, mask) fcat.mask( labels, mask ...
  , @find, {'free_viewing'} ...
);

% wrap_mask_func = mask_func;
sessions_func = @(l) ref( combs(l, 'session'), '()', 1 );
wrap_mask_func = @(l, m) find( l, sessions_func(l), mask_func(l, m) );

granger_outs = bfw_bhv_granger.behavioral_granger( look_outputs ...
  , 'mask_func', wrap_mask_func ...
  , 'bin_size', 1e3 ...
  , 'step_size', 1e3 ...
  , 'alpha', 0.05 ...
  , 'max_lag', 300 ...
  , 'gauss_win_size', 20 ...
  , 'permutation_test', true ...
);

%%

handle_save( granger_outs, params );

% debug_plot( granger_outs );

end

function look_outputs = get_look_outputs(params)

look_outputs = params.look_outputs;

if ( isempty(look_outputs) )
  look_outputs = bfw_make_looking_vector( ...
    'rois', 'face' ...
    , 'config', params.config ...
  );
end

end

function handle_save(granger_outs, params)

if ( ~params.do_save )
  return
end

save_p = bfw_bhv_granger.granger_save_p( {dsp3.datedir, params.base_subdir} ...
  , params.config );
shared_utils.io.require_dir( save_p );

file_name = sprintf( '%s%s', params.prefix, handle_filename(params.file_name, save_p) );
save( fullfile(save_p, file_name), 'granger_outs', '-v7.3' );

end

function file_name = handle_filename(file_name, save_p)

if ( strcmp(file_name, 'auto') )
  curr_files = shared_utils.io.filenames( shared_utils.io.findmat(save_p) );
  pattern = 'granger_';
  latest_nums = fcat.parse( curr_files, pattern );
  
  if ( isempty(latest_nums) )
    num = 1;
  else
    num = max( latest_nums ) + 1;
  end
  
  if ( isnan(num) )
    num = 1;
  end
  
  file_name = sprintf( '%s%d', pattern, num );
  file_path = shared_utils.char.require_end( fullfile(save_p, file_name), '.mat' );
  
  while ( exist(file_path) ~= 0 )
    file_name = num + 1;
    file_path = shared_utils.char.require_end( fullfile(save_p, file_name), '.mat' );
  end
  
  file_name = shared_utils.char.require_end( file_name, '.mat' );
end

end