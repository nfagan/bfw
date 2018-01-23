conf = bfw.config.load();

% p = bfw.get_intermediate_directory( 'aligned' );
p = '/Volumes/My Passport/NICK/Chang Lab 2016/brains/free_viewing/intermediates/aligned/1khz';

aligned = shared_utils.io.find( p, '.mat' );

test1 = struct( 'm1', [], 'm2', [] );

for i = 1:numel(aligned)
  current = shared_utils.io.fload( aligned{i} );
  
  fields = fieldnames( current );
  
  for j = 1:numel(fields)
    current_m = current.(fields{j});
    pos = current_m.position;
    ns = zeros( size(pos, 1), 2 );
    for k = 1:size(pos, 1)
      [nans, nanl] = shared_utils.logical.find_all_starts( isnan(pos(k, :)) );
      ns(k, 1) = numel(nans);
      ns(k, 2) = (numel(nans) / size(pos, 2)) * 100;
    end
    
%     pos = bfw.interpolate_nans( pos, 1 );
    test1.(fields{j})(end+1:end+2, :) = ns;
  end
  
%   test1{i} = current;
  
%   save( fullfile(bfw.get_intermediate_directory('aligned'), current.m1.aligned_filename), 'current' );
end

%%

