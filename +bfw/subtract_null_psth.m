function mod_amount = subtract_null_psth(psth, null_psth, psth_t, window_pre, window_post, take_mean)

specificity = { 'unit_uuid', 'channel', 'looks_by', 'looks_to' };

window_pre_ind = psth_t >= window_pre(1) & psth_t < window_pre(2);
window_post_ind = psth_t >= window_post(1) & psth_t < window_post(2);

[I, C] = psth.get_indices( specificity );

is_sig = true( numel(I), 1 );

modulation_amount = zeros( size(psth.data, 1), 1 );

mod_amount = Container();

null_psth = null_psth.require_fields( 'modulation_direction' );

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
  
  if ( take_mean )
    real_mean_pre = nanmean( real_mean_pre );
    real_mean_post = nanmean( real_mean_post );
  end
    
  switch ( cell_type )
    case 'pre'
      signed_mod_amount = real_mean_pre - fake_mean_pre;
      mod_amt = abs( signed_mod_amount );
      signed_mod_amount = sign( signed_mod_amount );
    case 'post'
      signed_mod_amount = real_mean_post - fake_mean_post;
      mod_amt = abs( signed_mod_amount );
      signed_mod_amount = sign( signed_mod_amount );
    case { 'pre_and_post' }
      mod_pre = abs( real_mean_pre - fake_mean_pre );
      mod_post = abs( real_mean_post - fake_mean_post );
      mod_amt = nanmean( [mod_pre, mod_post], 2 );
      
      if ( take_mean )
        pre_gt = mod_pre >= mod_post;
        signed_mod_amount = zeros( size(mod_pre) );
        signed_mod_amount(pre_gt) = sign( real_mean_pre(pre_gt) - fake_mean_pre(pre_gt) );
        signed_mod_amount(~pre_gt) = sign( real_mean_post(~pre_gt) - fake_mean_post(~pre_gt) );
      end
    case 'none'
      mod_pre = abs( real_mean_pre - fake_mean_pre );
      mod_post = abs( real_mean_post - fake_mean_post );
      mod_amt = nanmean( [mod_pre, mod_post], 2 );
      is_sig(i) = false;
      
      if ( take_mean )
        pre_gt = mod_pre >= mod_post;
        signed_mod_amount = zeros( size(mod_pre) );
        signed_mod_amount(pre_gt) = sign( real_mean_pre(pre_gt) - fake_mean_pre(pre_gt) );
        signed_mod_amount(~pre_gt) = sign( real_mean_post(~pre_gt) - fake_mean_post(~pre_gt) );
      end
    otherwise
      error( 'Unrecognized cell type "%s".', cell_type );
  end
  
  if ( take_mean )
    current = set_data( one(subset_null), mod_amt );
    if ( signed_mod_amount == 1 )
      direction = 'enhance';
    elseif ( signed_mod_amount == -1 )
      direction = 'suppress';
    else
      direction = 'direction__null';
    end
    current('modulation_direction') = direction;
    mod_amount = mod_amount.append( current );
  else
    modulation_amount(I{i}) = mod_amt;       
  end
end

if ( ~take_mean )
  mod_amount = set_data( psth, modulation_amount );
end

end