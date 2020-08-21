function beta_info = roi_linear_model_combinations(spikes, rois, lm_I, roi_order)

beta_info = [];

for i = 1:numel(lm_I)
  lm_mask = lm_I{i};

  subset_spikes = spikes(lm_mask);
  subset_rois = rois(lm_mask);

  lm_outs = ...
    bfw_lda.roi_linear_model( subset_spikes, subset_rois, roi_order );
  beta_info(end+1, :) = [lm_outs.roi_beta, lm_outs.roi_beta_p];
end

end