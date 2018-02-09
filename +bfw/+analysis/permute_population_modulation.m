function permute_population_modulation( psth, null_psth, psth_t, N, window_pre, window_post )

psth = psth({'mutual', 'm1'});
psth = psth({'eyes', 'face'});

specificity = { 'unit_uuid', 'looks_by', 'looks_to' };

window_pre_ind = psth_t >= window_pre(1) & psth_t < window_pre(2);
window_post_ind = psth_t >= window_post(1) & psth_t < window_post(2);

modulated_psth = Container();

[I, C] = psth.get_indices( specificity );

is_sig = true( numel(I), 1 );

modulation_amount = zeros( size(psth.data, 1), 1 );

for i = 1:numel(I)
  fprintf( '\n %d of %d', i, numel(I) );
  
  subset_psth = psth.data(I{i}, :);
  subset_null = null_psth(C(i, :));
  
  assert( shape(subset_null, 1) == 1, 'Null must be a single value.' );
  
  cell_type = char( subset_null('cell_type') );
  
  real_mean_pre = nanmean( subset_psth(:, window_pre_ind), 2 );
  real_mean_post = nanmean( subset_psth(:, window_post_ind), 2 );
  
  fake_mean_pre = nanmean( subset_null.data(:, window_pre_ind), 2 );
  fake_mean_post = nanmean( subset_null.data(:, window_post_ind), 2 );
    
  switch ( cell_type )
    case 'pre'
      mod_amt = abs( real_mean_pre - fake_mean_pre );
    case 'post'
      mod_amt = abs( real_mean_post - fake_mean_post );
    case { 'pre_and_post' }
      mod_pre = abs( real_mean_pre - fake_mean_pre );
      mod_post = abs( real_mean_post - fake_mean_post );
      mod_amt = mean( [mod_pre, mod_post], 2 );
    case 'none'
      mod_pre = abs( real_mean_pre - fake_mean_pre );
      mod_post = abs( real_mean_post - fake_mean_post );
      mod_amt = mean( [mod_pre, mod_post], 2 );
      is_sig(i) = false;
    otherwise
      error( 'Unrecognized cell type "%s".', cell_type );
  end
  
  modulation_amount(I{i}, :) = mod_amt;        
end

%%

ind_eyes = psth.where( 'eyes' );
ind_face = psth.where( 'face' );
ind_excl = psth.where( 'm1' );
ind_

[I, C] = psth.get_indices( 'unit_uuid' );

for i = 1:numel(I)
  index = I{i};
  
  one_unit_data = modulation_amount(index, :);
  one_unit_labels = psth.labels.keep(index);
  
  
end



for i = 1:numel(I)
  subset = modulated_psth(I{i});
  subset_is_sig = is_sig(I{i});
  
  ind_eyes = subset.where( 'eyes' );
  ind_face = subset.where( 'face' );
  ind_mut = subset.where( 'mutual' );
  ind_excl = subset.where( 'm1' );
  
  is_sig_eyes = subset_is_sig(ind_eyes);
  is_sig_face = subset_is_sig(ind_face);
  is_sig_mut = subset_is_sig(ind_mut);
  is_sig_excl = subset_is_sig(ind_excl);

  eyes = subset.data(ind_eyes);
  face = subset.data(ind_face);
  mut = subset.data(ind_mut);
  excl = subset.data(ind_excl);

  eyes_over_face = (eyes-face) ./ (face + eyes);
  mut_over_excl = (mut-excl) ./ (mut + excl);
  
      
end

end

function get_modulation_index( data, eye_index, face_index, mut_index, excl_index )



end