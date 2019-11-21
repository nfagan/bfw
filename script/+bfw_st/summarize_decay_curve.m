function summarize_decay_curve(varargin)

make_defaults = bfw.get_common_make_defaults();
plot_defaults = bfw.get_common_plot_defaults();

defaults = shared_utils.struct.union( make_defaults, plot_defaults );
defaults.config = bfw_st.default_config();
defaults.stim_time_outs = [];
defaults.decay_outs = [];
defaults.fix_info_outs = [];

params = bfw.parsestruct( defaults, varargin );
make_params = shared_utils.struct.intersect( params, make_defaults );
plot_params = shared_utils.struct.intersect( params, plot_defaults );

%%  fixation decay

decay_outs = params.decay_outs;

if ( isempty(decay_outs) )
  decay_outs = bfw_st.stim_fixation_decay( make_params );
end

is_average_at_day_or_run_level_cmbtns = true;
is_run_halves = false;
%is_long_shorts = true;
%is_trial_wise_subtractions = [true false];

% collapse_func = @run_level_average;
collapse_func = @day_level_average;

cmbtns = dsp3.numel_combvec( is_average_at_day_or_run_level_cmbtns, is_run_halves );
num_combs = size( cmbtns, 2 );

for idx = 1:num_combs
  comb = cmbtns(:, idx);
  is_average_at_day_or_run_level = is_average_at_day_or_run_level_cmbtns(comb(1));
  is_run_half = is_run_halves(comb(2));
  %is_trial_wise_subtraction = is_trial_wise_subtractions(comb(3));
  %is_long_short = is_long_shorts(comb(3));
  

%   for i = 1:7
  for i = 6
    before_plot_funcs={};
    
    xcats = {};
    gcats = {};
    pcats = {};
    fcat = {};
    base_subdir = '';
    mask = findnone( decay_outs.labels, 'previous_undefined' );
      
    if ( is_run_half )
      gcats{end+1} = 'run_time_quantile';
      base_subdir = sprintf( '%s%s', base_subdir, 'run_half_' );
    end
    
    if ( is_average_at_day_or_run_level )
      before_plot_funcs{end+1} = collapse_func;
      base_subdir = sprintf( '%s%s', base_subdir, 'run_level_average_' );
    end 

%     if ( is_long_short )
%       base_subdir = sprintf( '%s%s', base_subdir, 'short_vs_long_preceding_' );
%       pcats{end+1} = 'preceding_stim_duration_quantile';
%     end

    before_plot_func = @(varargin) apply_functions( before_plot_funcs, varargin{:} );
    
    if ( i == 1 )
        bfw_st.plot_fixation_decay( decay_outs, plot_params ...
        , 'mask', mask ...    %   'mask', find(decay_outs.labels, 'sham')
        , 'gcats', {} ...   %   'gcats', 'previous_stim_type'
        , 'pcats', pcats ...
        , 'base_subdir',sprintf( '%s%s', base_subdir, 'sham_and_stim' )...
        , 'before_plot_func', before_plot_func ...
        );

    elseif (i == 2) 
        
        bfw_st.plot_fixation_decay( decay_outs, plot_params ...
    , 'mask', find(decay_outs.labels, 'sham', mask)...
    , 'gcats', {'previous_stim_type'} ...  
    , 'base_subdir', sprintf( '%s%s', base_subdir, 'sham_only_previous')...
    , 'before_plot_func', before_plot_func ...
    );
    
    elseif (i ==3 ) 
        
        bfw_st.plot_fixation_decay( decay_outs, plot_params ...
    , 'mask', find(decay_outs.labels, 'sham', mask)...
    , 'gcats', {'previous_stim_type'} ...  
    , 'base_subdir', sprintf( '%s%s', base_subdir, 'sham_only_previous_isicontrol')...
    , 'pcats', {'stim_isi_quantile'}  ...
    , 'before_plot_func', before_plot_func ...
    );

    elseif ( i == 4 )
        
        bfw_st.plot_fixation_decay( decay_outs, plot_params ...
        , 'mask', mask ...    %   'mask', find(decay_outs.labels, 'sham')
        , 'pcats', {'day_time_quantile'} ...   %   'gcats', 'previous_stim_type'
        , 'base_subdir', sprintf( '%s%s', base_subdir, 'sham_and_stim_day_quantiles')...
        , 'pcats', pcats ...
        , 'before_plot_func', before_plot_func ...
        );
    
    elseif (i == 5)
        
        bfw_st.plot_fixation_decay( decay_outs, plot_params ...
        , 'mask', mask ...    %   'mask', find(decay_outs.labels, 'sham')
        , 'gcats', {'previous_stim_type'} ...   %   'gcats', 'previous_stim_type'
        , 'base_subdir', sprintf( '%s%s', base_subdir, 'sham_and_stim_previous' )...
        , 'before_plot_func', before_plot_func ...
        );
        
     elseif (i == 6)
        
        bfw_st.plot_fixation_decay( decay_outs, plot_params ...
        , 'mask', mask ...    %   'mask', find(decay_outs.labels, 'sham')
        , 'gcats', {'previous_stim_type'} ...   %   'gcats', 'previous_stim_type'
        , 'base_subdir', sprintf( '%s%s', base_subdir, 'sham_and_stim_previous_isicontrol' )...
        , 'pcats', {'stim_isi_quantile'} ...
        , 'fcat',{'region';'task_type'}...
        , 'before_plot_func', before_plot_func ...
        );
    
    elseif (i == 7 )
        
         bfw_st.plot_fixation_decay( decay_outs, plot_params ...
        , 'mask', findnone(decay_outs.labels, '<preceding_stim_duration_quantile>', mask)...
        , 'gcats', {'stim_type'} ...  
        , 'base_subdir', sprintf( '%s%s', base_subdir, 'short_vs_long_preceding' )...
        , 'xcats', {'preceding_stim_duration_quantile'}...
        , 'fcat', {'region','task_type'}...
        , 'before_plot_func', before_plot_func ...
        );
       
      
       
    else
        
     bfw_st.plot_fixation_decay( decay_outs, plot_params ...
        , 'mask', findnone(decay_outs.labels, '<preceding_stim_duration_quantile>', mask)...
        , 'gcats', {'stim_type'} ...  
        , 'base_subdir', sprintf( '%s%s', base_subdir, 'short_vs_long_preceding_iticontrol' )...
        , 'xcats', {'preceding_stim_duration_quantile'}...
        , 'pcats', {'stim_isi_quantile'} ...
        , 'fcat', {'roi'}...
        , 'before_plot_func', before_plot_func ...
        );
%         before_plot_func = @stim_minus_sham;
%         
%         bfw_st.plot_fixation_decay( decay_outs, plot_params ...
%         , 'mask', mask ...
%         , 'gcats', {} ...   
%         , 'pcats', {}...
%         , 'base_subdir',sprintf( '%s%s', base_subdir, 'stim_minus_sham' )...;
%         , 'before_plot_func', before_plot_func ...
%         ); 
        
    end
  end
end

end



function [data, labels] = apply_functions(functions, data, labels, spec)

for i = 1:numel(functions)
  [data, labels] = functions{i}( data, labels, spec );
end

end

function [data, labels] = run_level_average(data, labels, spec)

use_spec = union( spec, {'unified_filename'} );
[labels, each_I] = keepeach( labels', use_spec );
data = bfw.row_nanmean( data, each_I );

end

function [data, labels] = day_level_average(data, labels, spec)

use_spec = spec;
use_spec = setdiff( use_spec, {'unified_filename'} );
use_spec = union( use_spec, {'session'} );

[labels, each_I] = keepeach( labels', use_spec );
data = bfw.row_nanmean( data, each_I );

end

function [data, labels] = stim_minus_sham(data, labels, spec)

use_spec = setdiff( spec, {'stim_type'} );
use_spec = union( use_spec, {'unified_filename'} );

[data, labels] = bfw_st.stim_minus_sham( data, labels', use_spec );

end

