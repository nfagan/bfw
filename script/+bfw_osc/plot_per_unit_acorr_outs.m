function plot_per_unit_acorr_outs(acorr_outs, varargin)

defaults = bfw.get_common_plot_defaults( bfw.get_common_make_defaults() );
params = bfw.parsestruct( defaults, varargin );

labs = acorr_outs.labels';
base_mask = get_base_mask( labs );

unit_I = findall( labs, 'unit_uuid', base_mask );

for i = 1:numel(unit_I)
  d = 10;
end

end

function base_mask = get_base_mask(labels)

base_mask = findnone( labels, bfw.nan_unit_uuid() );

end