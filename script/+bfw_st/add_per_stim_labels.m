function labels = add_per_stim_labels(labels, stim_ts)

bfw.get_region_labels( labels );
bfw.add_monk_labels( labels );
bfw_st.add_stim_trial_order_labels( labels, stim_ts );
bfw_st.add_previous_stim_labels( labels );

end