%{
@T begin export

namespace bfw
  record ConfigConstants
    config_filename: char
    config_id: char
    config_folder: char
  end

  record Paths
    data_root: char
    repositories: char
    plots: char
    mount: char
  end

  record Dependencies
    repositories: {list<char>}
    classes: {list<char>}
    others: {list<char>}
  end

  record Cluster
    use_cluster: logical
  end

  record Config
    BFW__IS_CONFIG__: logical
    PATHS: bfw.Paths
    DEPENDS: bfw.Dependencies
    CLUSTER: bfw.Cluster
  end

end

end
%}