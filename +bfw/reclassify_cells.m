function out = reclassify_cells( psth, null_psth, z_psth, psth_t, window_pre, window_post, alpha )

specificity = { 'unit_uuid', 'channel', 'looks_by', 'looks_to' };

assert( psth.labels == null_psth.labels && null_psth.labels == z_psth.labels ...
  , 'Labels must be consistent across null, z, and non-z.' );

window_pre_ind = psth_t >= window_pre(1) & psth_t < window_pre(2);
window_post_ind = psth_t >= window_post(1) & psth_t < window_post(2);

[I, C] = psth.get_indices( specificity );

for i = 1:numel(I)
  fprintf( '\n %d of %d', i, numel(I) );
  
  subset_psth = psth(I{i});
  subset_null = null_psth(I{i});
  subset_z = z_psth(I{i});
  
  assert( shape(subset_psth, 1) == 1, 'More than 1 row associated with "%s"', strjoin(C(i, :), ', ') );
  
  ps = 1 - normcdf( abs(subset_z.data) );

  sig_pre = ps(1) <= alpha;
  sig_post = ps(2) <= alpha;

  is_pre_only = sig_pre && ~sig_post;
  is_post_only = sig_post && ~sig_pre;
  is_pre_and_post = sig_pre && sig_post;

  if ( is_pre_only )
    cell_type = 'pre';
  elseif ( is_post_only )
    cell_type = 'post';
  elseif ( is_pre_and_post )
    cell_type = 'pre_and_post';
  else
    cell_type = 'none';
  end
  
  real_pre = nanmean( subset_psth.data(:, window_pre_ind), 2 );
  real_post = nanmean( subset_psth.data(:, window_post_ind), 2 );
  
  fake_pre = nanmean( subset_null.data(:, window_pre_ind), 2 );
  fake_post = nanmean( subset_null.data(:, window_post_ind), 2 );

  mean_fake_pre = nanmean( fake_pre, 1 );
  mean_fake_post = nanmean( fake_post, 1 );

  if ( strcmp(cell_type, 'pre') )
    mod_sign = sign( real_pre - mean_fake_pre );
  elseif ( strcmp(cell_type, 'post') )
    mod_sign = sign( real_post - mean_fake_post );
  else
    mod_sign_pre = sign( real_pre - mean_fake_pre );
    mod_sign_post = sign( real_post - mean_fake_post );
    if ( mod_sign_pre == mod_sign_post )
      mod_sign = mod_sign_pre;
    else
      mod_sign = 2;
    end
  end

  if ( mod_sign ~= 2 )
    mod_direction = get_string_modulation_direction( mod_sign );
  else
    mod_pre = get_string_modulation_direction( mod_sign_pre );
    mod_post = get_string_modulation_direction( mod_sign_post );
    mod_direction = strjoin( {mod_pre, mod_post}, '_' );
  end
  
  psth('cell_type', I{i}) = cell_type;
  psth('modulation_direction', I{i}) = mod_direction;
end

out = psth.labels;

end

function mod_direction = get_string_modulation_direction( mod_sign )

if ( mod_sign == -1 )
  mod_direction = 'suppress';
elseif ( mod_sign == 1 )
  mod_direction = 'enhance';
elseif ( mod_sign == 0 )
  mod_direction = 'direction__null';
else
  error( 'Mod sign was %d', mod_sign );
end

end