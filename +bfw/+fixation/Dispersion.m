%   See brains/ino/src/fixation.h and brains/ino/src/fixation.cpp

classdef Dispersion < handle
  
  properties (Access = private)
    threshold;
    n_samples;
    update_interval;
    place_index;
    x_coordinates;
    y_coordinates;
  end
  
  methods (Access = public)
    function obj = Dispersion(thresh, n_samples, update_interval)
      if ( nargin < 1 ), thresh = 20; end
      if ( nargin < 2 ), n_samples = 4; end
      if ( nargin < 3 ), update_interval = 50; end
      
      obj.threshold = thresh;
      obj.n_samples = n_samples;
      obj.update_interval = update_interval;
      obj.place_index = 1;
      
      obj.x_coordinates = nan( 1, n_samples );
      obj.y_coordinates = nan( size(obj.x_coordinates) );
    end
    
    function tf = detect(obj, x, y)
      assert( numel(x) == numel(y), 'Number of x-samples must match number of y samples.' );
      
      last_update = nan;
      stp = 1;
      tf = false( size(x) );
      
      while ( stp <= numel(tf) )
        if ( isnan(last_update) || stp - last_update > obj.update_interval )
          insert_coordinate( obj, x(stp), y(stp) );
          
          dispersion = obj.get_dispersion();
          
          tmp_is_fix = dispersion < obj.threshold;
          
          stop = min( stp+obj.update_interval-1, numel(tf) );
          tf(stp:stop) = tmp_is_fix;
        end
        
        stp = stp + 1;
      end
    end
  end
  
  methods (Access = private)
    
    function insert_coordinate(obj, x, y)
      if ( obj.place_index <= obj.n_samples )
        obj.x_coordinates(obj.place_index) = x;
        obj.y_coordinates(obj.place_index) = y;
        obj.place_index = obj.place_index + 1;
      else
        %   place index is past
        obj.shift_left();
        obj.x_coordinates(obj.place_index-1) = x;
        obj.y_coordinates(obj.place_index-1) = y;
      end
    end
    
    function shift_left(obj)
      for i = 1:obj.n_samples-1
        obj.x_coordinates(i) = obj.x_coordinates(i+1);
        obj.y_coordinates(i) = obj.y_coordinates(i+1);
      end
    end
    
    function d = get_dispersion(obj)
      
      first_iteration = true;
      maxs = struct( 'x', nan, 'y', nan );
      
      for i = 1:obj.place_index-2
        for j = i+1:obj.place_index-1
          ax = obj.x_coordinates(i);
          ay = obj.y_coordinates(i);
          
          bx = obj.x_coordinates(j);
          by = obj.y_coordinates(j);
          
          dx = abs(ax - bx);
          dy = abs(ay - by);
          
          if ( first_iteration || dx > maxs.x )
            maxs.x = dx;
          end
          
          if ( first_iteration || dy > maxs.y )
            maxs.y = dy;
          end
          
          first_iteration = false;
        end
      end
      
      d = (maxs.x + maxs.y) / 2;
    end
    
  end
  
end