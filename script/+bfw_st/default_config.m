function conf = default_config(varargin)

conf = bfw.set_dataroot( bfw_st.make_data_root(varargin{:}), varargin{:} );

end