function bfw_cluster_run_spatial_bin_degree_control(varargin)

defaults = bfw.get_common_make_defaults();
defaults.use_binned_pos = false;
params = bfw.parsestruct( defaults, varargin );

%%  linear model for degree tuning

conf = params.config;

save_p = get_save_path( conf );
shared_utils.io.require_dir( save_p );
save_file_path = fullfile( save_p, 'perm_model_results.mat' );

[t_mean_psth, psth_labels, event_pos, deg_event_pos] = load_source_data( conf );

use_binned_pos = params.use_binned_pos;
rng_state = load_rng_state( conf );

if ( use_binned_pos )
  event_pos = deg_event_pos;
end

[mdls, mdl_ps, mdl_perm_ps, mdl_labels] = degree_linear_model( t_mean_psth, event_pos, psth_labels' ...
  , 'permute', true ...
  , 'iters', 1e3 ...
  , 'rng_state', rng_state ...
);

save( save_file_path, 'mdls', 'mdl_ps', 'mdl_perm_ps', 'mdl_labels', '-v7.3' );

end

function [mdls, mdl_ps, p_perm_sig, mdl_labels] = degree_linear_model(t_mean_psth, psth_event_pos, psth_labels, varargin)

assert_ispair( t_mean_psth, psth_labels );
assert_ispair( psth_event_pos, psth_labels );

defaults = struct();
defaults.permute = false;
defaults.iters = 1e3;
defaults.rng_state = [];
params = bfw.parsestruct( defaults, varargin );

do_permute = params.permute;
rng_state = params.rng_state;

if ( ~isempty(rng_state) )
  s = rng();
  cleanup = onCleanup( @() rng(s) );
  rng( rng_state );
end

mdl_each = { 'unit_uuid', 'region', 'session' };
mdl_I = findall( psth_labels, mdl_each );

mdls = {};
mdl_labels = fcat;
p_perm_sig = [];

pos_kinds = { 'x-degrees', 'y-degrees' };

for i = 1:2
  deg = psth_event_pos(:, i);
  pos_kind = pos_kinds{i};

  for j = 1:numel(mdl_I)    
    shared_utils.general.progress( j, numel(mdl_I) );
    
    mdl_ind = mdl_I{j};
    [mdl, tmp_labels] = pos_linear_model( deg, t_mean_psth, psth_labels, mdl_ind );
    addsetcat( tmp_labels, 'position-kind', pos_kind );
    
    append( mdl_labels, tmp_labels );
    mdls{end+1, 1} = mdl;
    real_beta = mdl.Coefficients.Estimate(2);
    
    if ( do_permute )
      met_crit = false( params.iters, 1 );
      
      parfor k = 1:params.iters
        tmp_deg = deg;
        perm_ind = randperm( numel(mdl_ind) );
        tmp_deg(mdl_ind) = tmp_deg(mdl_ind(perm_ind));
        
        null_mdl = pos_linear_model( tmp_deg, t_mean_psth, psth_labels, mdl_ind );
        null_beta = null_mdl.Coefficients.Estimate(2);
        
        if ( real_beta < 0 )
          crit = null_beta < real_beta;
        else
          crit = null_beta > real_beta;
        end
        
        met_crit(k) = crit;
      end
      
      p_perm_sig(end+1, 1) = 1 - sum( met_crit ) / numel( met_crit );
    else
      p_perm_sig(end+1, 1) = nan;
    end
  end
end

assert_ispair( mdls, mdl_labels );
mdl_ps = cellfun( @(x) x.Coefficients.pValue(2), mdls );
assert_ispair( mdl_ps, mdl_labels );
assert_ispair( p_perm_sig, mdl_labels );

end

function [t_mean_psth, psth_labels, event_pos, deg_event_pos] = load_source_data(conf)

data_file = fullfile( bfw.dataroot(conf), 'analyses' ...
  , 'spatial_bin_control', 'post_mean_psth_data_for_cluster.mat' );
data = load( data_file );
t_mean_psth = data.t_mean_psth;
psth_labels = data.psth_labels;
event_pos = data.event_pos;
deg_event_pos = data.deg_event_pos;

end

function [mdl, mdl_labels] = pos_linear_model(x, y, labels, mask)

assert_ispair( x, labels );
assert_ispair( y, labels );
assert( isvector(x) && isvector(y) ...
  , 'Expected response and predictors to be vectors.' );

mdl = fitlm( x(mask), y(mask) );
mdl_labels = append1( fcat, labels, mask );

end

function p = get_save_path(conf)

p = fullfile( bfw.dataroot(conf), 'analyses', 'spatial_bin_control' );

end

function state = load_rng_state(conf)

state_file = fullfile( bfw.dataroot(conf), 'analyses' ...
  , 'spatial_bin_control', 'rng_102720.mat' );
state = shared_utils.io.fload( state_file );

end