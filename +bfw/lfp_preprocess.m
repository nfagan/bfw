function [lfp, params] = lfp_preprocess(lfp, varargin)

defaults = struct();
defaults.filter = true;
defaults.reference_subtract = true;
defaults.f1 = 2.5;
defaults.f2 = 250;
defaults.filter_order = 2;
defaults.sample_rate = 1e3;
defaults.ref_index = [];

params = shared_utils.general.parsestruct( defaults, varargin );

if ( params.reference_subtract )
  assert( ~isempty(params.ref_index), ['If reference subtracting, ' ...
    , 'supply a ''ref_index'' parameter giving the reference channel.'] );
  
  keepi = setdiff( 1:size(lfp, 1), params.ref_index );
  ref = lfp(params.ref_index, :);  
  lfp = lfp(keepi, :) - ref;
end

if ( params.filter )
  f1 = params.f1;
  f2 = params.f2;
  filt_order = params.filter_order;
  fs = params.sample_rate;
  lfp = bfw.zpfilter( lfp, f1, f2, fs, filt_order );
end

end