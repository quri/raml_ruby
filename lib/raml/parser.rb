require 'yaml'

module Raml
  # @private
  class Parser
    class << self
      def parse(data, file_dir=Dir.getwd)
        register_include_tag
        
        data = YAML.load data
        expand_includes data, file_dir
        
        Root.new data
      end

      private
      
      def register_include_tag
        YAML.add_tag '!include', Raml::Parser::Include
      end
      
      def expand_includes(val, cwd)
        case val
        when Hash
          val.merge!(val, &expand_includes_transform(cwd))
        when Array
          val.map!(&expand_includes_transform(cwd))
        end
      end
          
      def expand_includes_transform(cwd)
        proc do |arg1, arg2|
          val      = arg2.nil? ? arg1 : arg2
          child_wd = cwd
          
          if val.is_a? Raml::Parser::Include
            child_wd = expand_includes_working_dir cwd, val.path
            path = val.path
            val      = val.content cwd
            val.define_singleton_method(:file_path) { child_wd + "/" + path.split("/").last }
          end
          
          expand_includes val, child_wd
          
          val
        end
      end
      
      def expand_includes_working_dir(current_wd, include_pathname)
        file_path = File.dirname include_pathname
        if file_path.start_with? '/'
         file_path
        else
          "#{current_wd}/#{file_path}"
        end
      end
    end
  end
end
