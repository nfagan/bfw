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

for i = 1:3
    if ( i == 1 )
        mask_func = @(labels) findor(labels, {'eyes_nf', 'face'});
        base_subdir = 'sham_and_stim';
        gcats = {};
    elseif (i ==2 ) 
        mask_func = @(labels) fcat.mask(labels ...
            , @findor, {'eyes_nf', 'face'} ...
            , @find, 'sham' ...
        );
        base_subdir = 'sham_only';
        gcats = { 'previous_stim_type' };
    else
         mask_func = @(labels) fcat.mask(labels ...
            , @findor, {'eyes_nf', 'face'});
        base_subdir = 'sham_and_stim_quantiles';
        gcats = { 'day_time_quantile' };
    end

    bfw_st.plot_fix_info( fix_info_outs ...
      , 'mask_func', mask_func ...
      , plot_params ...
      , 'base_subdir', base_subdir ...
      , 'gcats', gcats ...
    );
end


end
