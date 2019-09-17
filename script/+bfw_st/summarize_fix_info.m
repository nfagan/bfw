function summarize_fix_info(varargin)

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

fix_info_outs = params.fix_info_outs;

if ( isempty(fix_info_outs) )
  fix_info_outs = bfw_st.fix_info( make_params );
end

is_collapsed_at_run_levels = false;
is_run_halves = false;
is_trial_wise_subtractions = false;
%is_long_shorts = [true false];
collapse_funcs=@run_level_average;
%collapse_funcs = { @run_level_average, @run_level_median };


% summary_func = @(x) nanmedian(x, 1);
summary_func = @(x) nanmean(x, 1);

cmbtns = dsp3.numel_combvec( is_collapsed_at_run_levels, is_run_halves ...
 , is_trial_wise_subtractions, collapse_funcs );
num_combs = size( cmbtns, 2 );

for idx = 1:num_combs
  shared_utils.general.progress( idx, num_combs );
    
  comb = cmbtns(:, idx);
  is_collapsed_at_run_level = is_collapsed_at_run_levels(comb(1));
  is_run_half = is_run_halves(comb(2));
  is_trial_wise_subtraction = is_trial_wise_subtractions(comb(3));
  %is_long_short = is_long_shorts(comb(4));
  collapse_func=collapse_funcs;
  %collapse_func = collapse_funcs{comb(4)};

  for i = 1:7
    before_plot_funcs = {};

    xcats = {};
    gcats = {};
    pcats = {};
    fcats = { 'region' };
    base_subdir = '';
    additional_mask_func_inputs = {};
      
    if ( is_run_half )
      gcats{end+1} = 'run_time_quantile';
      base_subdir = sprintf( '%s%s', base_subdir, 'run_half_' );
    end
    
     if ( is_collapsed_at_run_level )
      before_plot_funcs{end+1} = collapse_func;
      base_subdir = sprintf( '%s%s_', base_subdir, func2str(collapse_func) );
     end 

%     if ( is_long_short )
%       base_subdir = sprintf( '%s%s', base_subdir, 'short_vs_long_preceding_' );
%       fcats{end+1} = 'roi';
%       xcats{end+1} = 'preceding_stim_duration_quantile';
%       additional_mask_func_inputs = [additional_mask_func_inputs, {@findnone, '<preceding_stim_duration_quantile>'}];
%     end

     
    if ( is_trial_wise_subtraction )
      before_plot_funcs{end+1} = @trial_wise_subtraction;
      base_subdir = sprintf( '%s%s', base_subdir, 'trial_wise_subtraction_' );
    end

   
    before_plot_func = @(varargin) apply_functions( before_plot_funcs, varargin{:} );
    
    
    if ( i == 1 )
        mask_func = @(labels) fcat.mask(labels ...
            , @findor, {'eyes_nf', 'face'} ...
            , additional_mask_func_inputs{:} ... 
        );
        base_subdir = sprintf( '%s%s', base_subdir, 'sham_and_stim' );
    elseif (i ==2 ) 
        mask_func = @(labels) fcat.mask(labels ...
            , @findor, {'eyes_nf', 'face'} ...
            , @findnone, 'previous_undefined' ...
            , @find, 'sham' ...
            , additional_mask_func_inputs{:} ... 
        );
        base_subdir = sprintf( '%s%s', base_subdir, 'sham_only_previous');
        gcats{end+1} = 'previous_stim_type';
        
    elseif (i ==3 ) 
    mask_func = @(labels) fcat.mask(labels ...
        , @findor, {'eyes_nf', 'face'} ...
        , @findnone, 'previous_undefined' ...
        , @find, 'sham' ...
        , additional_mask_func_inputs{:} ... 
    );
    base_subdir = sprintf( '%s%s', base_subdir, 'sham_only_previous_isicontrol');
    gcats{end+1} = 'previous_stim_type';
    pcats{end+1}='stim_isi_quantile';
        
%     elseif ( i == 3 )
%          mask_func = @(labels) fcat.mask(labels ...
%             , @findor, {'eyes_nf', 'face'}...
%             , @findnone, 'previous_undefined'...
%             , additional_mask_func_inputs{:} ... 
%          );
%         gcats{end+1}='day_time_quantile' ;
%         base_subdir = sprintf( '%s%s', base_subdir, 'sham_and_stim_day_quantiles');
    elseif (i == 4 ) 
        mask_func = @(labels) fcat.mask(labels ...
            , @findor, {'eyes_nf', 'face'} ...
            , @findnone, 'previous_undefined' ...
            , additional_mask_func_inputs{:} ... 
        );
        base_subdir = sprintf( '%s%s', base_subdir, 'sham_and_stim_previous' );
        gcats{end+1} = 'previous_stim_type';
        
    elseif (i == 5 )
        mask_func = @(labels) fcat.mask(labels ...
            , @findor, {'eyes_nf', 'face'} ...
            , @findnone, 'previous_undefined' ...
            , additional_mask_func_inputs{:} ... 
        );
        base_subdir = sprintf( '%s%s', base_subdir, 'sham_and_stim_previous_isicontrol' );
        gcats{end+1} = 'previous_stim_type';
        pcats{end+1}='stim_isi_quantile';
    
%       mask_func = @(labels) fcat.mask(labels ...
%           , @findor, {'eyes_nf', 'face'} ...
%           , additional_mask_func_inputs{:} ... 
%       );
%       before_plot_func = @stim_minus_sham;
%       base_subdir = sprintf( '%s%s', base_subdir, 'stim_minus_sham' );

    elseif (i == 6) 
         mask_func = @(labels) fcat.mask(labels ...
            , @findor, {'eyes_nf', 'face'} ...
            , @findnone, '<preceding_stim_duration_quantile>' ...
            , additional_mask_func_inputs{:} ... 
        );
        base_subdir = sprintf( '%s%s', base_subdir, 'short_vs_long_preceding' );
        gcats{end+1} = 'stim_type';
        fcats{end+1} = 'roi';
        xcats{end+1} = 'preceding_stim_duration_quantile';

    else
        
         mask_func = @(labels) fcat.mask(labels ...
            , @findor, {'eyes_nf', 'face'} ...
            , @findnone, '<preceding_stim_duration_quantile>' ...
            , additional_mask_func_inputs{:} ... 
        );
        base_subdir = sprintf( '%s%s', base_subdir, 'short_vs_long_preceding_iticontrol' );
        gcats{end+1} = 'stim_type';
        fcats{end+1} = 'roi';
        xcats{end+1} = 'preceding_stim_duration_quantile';
        pcats{end+1}='iti_quantile';
        
    end

    bfw_st.plot_fix_info( fix_info_outs ...
      , 'mask_func', mask_func ...
      , plot_params...
      , 'base_subdir', base_subdir ...
      , 'xcats', xcats ...
      , 'gcats', gcats ...
      , 'pcats', pcats ...
      , 'fcats', fcats ...
      , 'before_plot_func', before_plot_func ...
      , 'summary_func', summary_func ...
    );
  end
end

%  amp vs vel
 
bfw_st.stim_amp_vs_vel( plot_params );
 
end

function [data, labels] = apply_functions(functions, data, labels, spec)

for i = 1:numel(functions)
  [data, labels] = functions{i}( data, labels, spec );
end

end

function [d, l] = trial_wise_subtraction(data, labels, spec)

use_spec = setdiff( getcats(labels) ...
, {'stim_id', 'stim_order', 'next_stim_type', 'previous_stim_type', 'stim_type'} );
[d, l] = bfw_st.trial_wise_stim_type_difference( data, labels', use_spec );

% mask_eyes = find( l, 'eyes_nf' );
% d = d(mask_eyes);
% l = l(mask_eyes);

end

function [data, labels] = run_level_average(data, labels, spec)

use_spec = union( spec, {'unified_filename'} );
[labels, each_I] = keepeach( labels', use_spec );
data = bfw.row_nanmean( data, each_I );

end

function [data, labels] = run_level_median(data, labels, spec)

use_spec = union( spec, {'unified_filename'} );
[labels, each_I] = keepeach( labels', use_spec );
data = bfw.row_nanmedian( data, each_I );

end

function [data, labels] = stim_minus_sham(data, labels, spec)

use_spec = setdiff( spec, {'stim_type'} );
use_spec = union( use_spec, {'unified_filename'} );

[data, labels] = bfw_st.stim_minus_sham( data, labels', use_spec );

end



