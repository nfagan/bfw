function [m1_gf_dirs, m2_gf_dirs] = gaze_following_behavior(m1_gf_pos, m2_gf_pos)

% flip m2 x
m2_gf_pos(:, 1) = -m2_gf_pos(:, 1);

m1_gf_dirs = m1_gf_pos ./ vecnorm( m1_gf_pos, 2, 2 );
m2_gf_dirs = m2_gf_pos ./ vecnorm( m2_gf_pos, 2, 2 );

end