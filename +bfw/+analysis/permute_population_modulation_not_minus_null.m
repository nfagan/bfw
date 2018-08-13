function [all_modulation_index, all_significant] = permute_population_modulation_not_minus_null( psth, psth_t, N, window, summary_func )

psth = psth({'mutual', 'm1'});
psth = psth({'eyes', 'face'});

specificity = { 'unit_uuid', 'channel', 'looks_by', 'looks_to' };

window_ind = psth_t >= window(1) & psth_t < window(2);

[I, C] = psth.get_indices( specificity );

mod_amount = Container();

for i = 1:numel(I)
  fprintf( '\n %d of %d', i, numel(I) );
  
  subset_psth = psth(I{i});
  
  meaned = nanmean( subset_psth.data(:, window_ind), 2 );
  meaned = summary_func( meaned, 1 );
  
  mod_amount = mod_amount.append( set_data(one(subset_psth), meaned) );
end

[I, C] = mod_amount.get_indices( {'unit_uuid', 'channel'} );

all_significant = Container();
all_modulation_index = Container();

for i = 1:numel(I)
  index = I{i};

  l_psth = mod_amount(index);
  one_unit_data = l_psth.data;
  
  ind_eyes = l_psth.where( 'eyes' );
  ind_face = l_psth.where( 'face' );
  ind_excl = l_psth.where( 'm1' );
  ind_mut = l_psth.where( 'mutual' );
  
  [real_ef, real_me] = get_modulation_index( one_unit_data, ind_eyes, ind_face, ind_mut, ind_excl );
  
  real_data = [ real_ef, real_me ];
  permuted_data = zeros( N, 2 );
  
  n = numel( ind_eyes );
  
  for j = 1:N
    i1 = randperm( n );
    i2 = randperm( n );
    i3 = randperm( n );
    i4 = randperm( n );
    
    ind_eyes = ind_eyes(i1);
    ind_face = ind_face(i2);
    ind_mut = ind_mut(i3);
    ind_excl = ind_excl(i4);

    [fake_ef, fake_me] = get_modulation_index( one_unit_data, ind_eyes, ind_face, ind_mut, ind_excl );    
    
    permuted_data(j, :) = [ fake_ef, fake_me ];
  end
  
  if ( sign(real_ef) == -1 )
    test_func_ef = @lt;
  else
    test_func_ef = @gt;
  end

  if ( sign(real_me) == -1 )
    test_func_me = @lt;
  else
    test_func_me = @gt;
  end

  n_ef = sum( test_func_ef(real_ef, permuted_data(:, 1)) );
  n_me = sum( test_func_me(real_me, permuted_data(:, 2)) ); 
  
  p_ef = 1 - (n_ef / N);
  p_me = 1 - (n_me / N);

  cont = set_data( one(l_psth), [p_ef, p_me] );
  
  all_significant = all_significant.append( cont );
  all_modulation_index = all_modulation_index.append( set_data(cont, real_data) );
end

end

function [eyes_over_face, mut_over_excl] = get_modulation_index( data, eye_index, face_index, mut_index, excl_index )

eyes = data(eye_index);
face = data(face_index);
mut = data(mut_index);
excl = data(excl_index);

eyes = nanmean( eyes );
face = nanmean( face );
mut = nanmean( mut );
excl = nanmean( excl );

eyes_over_face = (eyes-face) / (face + eyes);
mut_over_excl = (mut-excl) / (mut + excl);

end