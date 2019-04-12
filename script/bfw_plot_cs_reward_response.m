function bfw_plot_cs_reward_response(reward_response, varargin)

defaults = bfw.get_common_make_defaults();
defaults.base_subdir = '';
defaults.do_save = false;
defaults.base_mask = rowmask( reward_response.labels );

params = bfw.parsestruct( defaults, varargin );

%%

plot_psth( reward_response, params );

end

function plot_psth(reward_response_out, params)

base_save_p = fullfile( bfw.dataroot(params.config), 'plots', 'cs_psth', dsp3.datedir );

psth_dat = reward_response_out.psth;
psth_labs = reward_response_out.labels';

bfw.unify_single_region_labels( psth_labs );

gcats = { 'reward-level' };
pcats = { 'unit_uuid', 'region', 'event-name' };

unit_I = findall( psth_labs, 'unit_uuid', params.base_mask );

for i = 1:numel(unit_I)
  shared_utils.general.progress( i, numel(unit_I) );
  
  unit_ind = unit_I{i};
  
  pltdat = psth_dat(unit_ind, :);
  pltlabs = psth_labs(unit_ind);
  
  pl = plotlabeled.make_common();
  
  pl.add_errors = false;
  pl.x = reward_response_out.t;
  
  axs = pl.lines( pltdat, pltlabs, gcats, pcats );
  
  if ( params.do_save )
    region_subdir = combs( psth_labs, 'region', unit_ind );
    region_subdir = strjoin( region_subdir(:), '_' );
    
    save_p = fullfile( base_save_p, params.base_subdir, region_subdir );
    
    dsp3.req_savefig( gcf, save_p, prune(pltlabs), pcats );
  end
end

end