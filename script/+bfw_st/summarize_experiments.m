function summarize_experiments(varargin)

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

%%  fix info

fix_info_outs = params.fix_info_outs;

if ( isempty(fix_info_outs) )
  fix_info_outs = bfw_st.fix_info( make_params );
end


for i = 1:4
    
    if ( i == 1 )
        mask_func = @(labels) findor(labels, {'eyes_nf', 'face'});
        base_subdir = 'sham_and_stim';
        gcats = {};
        pcats = {};
    elseif (i ==2) 
        mask_func = @(labels) fcat.mask(labels ...
            , @findor, {'eyes_nf', 'face'} ...
            , @find, 'sham' ...
        );
        base_subdir = 'sham_only';
        gcats = { 'previous_stim_type' };
        pcats = {};
    elseif (i==3)
         mask_func = @(labels) fcat.mask(labels ...
            , @findor, {'eyes_nf', 'face'});
        base_subdir = 'sham_and_stim_quantiles';
        gcats = { 'day_time_quantile' };
        pcats = {};
    else
        mask_func = @(labels) fcat.mask(labels...
        , @findor, {'eyes_nf', 'face'}...
        , @ find, 'sham' ...
         );
        base_subdir = 'sham_only_quantiles';
        pcats = {'day_time_quantile'};
        gcats = {'previous_stim_type'};
 
    end

    bfw_st.plot_fix_info( fix_info_outs ...
      , 'mask_func', mask_func ...
      , plot_params ...
      , 'base_subdir', base_subdir ...
      , 'gcats', gcats ...
      , 'pcats', pcats ...
    );
end

% %%  amp vs vel
% 
% bfw_st.stim_amp_vs_vel( plot_params );
% 
% %%  isi
% stim_time_outs = params.stim_time_outs;
% 
% if ( isempty(stim_time_outs) )
%   stim_time_outs = bfw_load_stim_events( make_params );
% end
% % 
% [isi, isi_labels] = make_isi( stim_time_outs );
% summarize_isi( isi, isi_labels', params );


%%  fixation decay

decay_outs = params.decay_outs;

if ( isempty(decay_outs) )
  decay_outs = bfw_st.stim_fixation_decay( make_params );
end


for i = 1:4
    if ( i == 1 )
        bfw_st.plot_fixation_decay( decay_outs, plot_params ...
        , 'mask', rowmask(decay_outs.labels) ...    %   'mask', find(decay_outs.labels, 'sham')
        , 'gcats', {} ...   %   'gcats', 'previous_stim_type'
        , 'base_subdir','sham_and_stim'...
        );

    elseif (i == 2) 
        
        bfw_st.plot_fixation_decay( decay_outs, plot_params ...
    , 'mask', find(decay_outs.labels, 'sham')...
    , 'gcats', {'previous_stim_type'} ...  
    , 'base_subdir', 'sham_only'...
    );

    elseif ( i == 3 )
        
        bfw_st.plot_fixation_decay( decay_outs, plot_params ...
        , 'mask', rowmask(decay_outs.labels) ...    %   'mask', find(decay_outs.labels, 'sham')
        , 'pcats', {'day_time_quantile'} ...   %   'gcats', 'previous_stim_type'
        , 'base_subdir', 'sham_and_stim_quantiles'...
        );
    
    else 
        base_subdir = 'sham_only_quantiles';
        
        bfw_st.plot_fixation_decay( decay_outs, plot_params ...
        , 'mask', find(decay_outs.labels, 'sham')...
        , 'gcats', {'previous_stim_type'} ...   
        , 'pcats', {'day_time_quantile'}...
        , 'base_subdir','sham_only_quantiles'...
        ); 
        
    end
    

end


end

% 
% 
% % ISI
% function [isis, isi_labels] = make_isi(stim_time_outs)
% 
% stim_labels = stim_time_outs.labels';
% stim_times = stim_time_outs.stim_times;
% 
% run_I = findall( stim_labels, 'unified_filename' );
% 
% isi_labels = fcat();
% isis = [];
% 
% for i = 1:numel(run_I)
%   run_ind = run_I{i};
%   
%   if ( numel(run_ind) < 2 )
%     continue;
%   end
%   
%   [sorted_times, sorted_ind] = sort( stim_times(run_ind) );
%   sorted_run_inds = run_ind(sorted_ind);
%   
%   deltas = diff( sorted_times );
%   
%   append( isi_labels, stim_labels, sorted_run_inds(1:end-1) );
%   isis = [ isis; deltas(:) ];
% end
% 
% assert_ispair( isis, isi_labels );
% 
% end
% 
% function summarize_isi(isi, isi_labels, params)
% 
% pl = plotlabeled.make_common();
% 
% figs_each = { 'task_type', 'protocol_name' };
% 
% pcat_combs = { {'session', 'task_type'}, {'task_type'} };
% 
% comb_inds = dsp3.numel_combvec( pcat_combs );
% num_combs = size( comb_inds, 2 );
% 
% for idx = 1:num_combs
% 
% pcats = pcat_combs{comb_inds(1, idx)};
% 
% fig_I = findall( isi_labels, figs_each );
% 
% for i = 1:numel(fig_I)
%   pltdat = isi(fig_I{i});
%   pltlabs = prune( isi_labels(fig_I{i}) );
% 
%   [axs, inds] = pl.hist( pltdat, pltlabs, pcats, 100 );
% 
%   for j = 1:numel(inds)
%     med = median( pltdat(inds{j}) );
%     shared_utils.plot.hold( axs(j), 'on' );
%     shared_utils.plot.add_vertical_lines( axs(j), med, 'r--' );
%     text( axs(j), med, max(get(axs(j), 'ylim')), sprintf('M = %0.2f', med) );
%   end
%   
%   if ( params.do_save )
%     save_p = bfw_st.stim_summary_plot_p( params, 'isi' );
%     shared_utils.plot.fullscreen( gcf );
%     dsp3.req_savefig( gcf, save_p, pltlabs, [pcats, figs_each] );
%   end
% end
% 
% end
% 
% end