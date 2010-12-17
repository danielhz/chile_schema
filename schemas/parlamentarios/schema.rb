require 'yaml'

class Schema
  # Initialize a new schema
  def initialize(file = nil)
    @data = {
      :classes    => {},
      :predicates => {},
      :types      => {}
    }
    @domains = {}
    add(file) unless file.nil?
  end
  # Get classes, predicates o datatypes in lexical order
  def elements(key = :classes, included_domains = domains, excluded_domains = [])
    included = included_domains.map{ |d| @domains[d][key] }.flatten.uniq
    excluded = excluded_domains.map{ |d| @domains[d][key] }.flatten.uniq
    @data[key].select{ |k,v| included.include? k and !excluded.include? k }.map { |k,v|
      v.merge({:name => k})
    }.sort{ |x,y| x[:name] <=> y[:name] }
  end
  # Get domains in lexical order
  def domains
    @domains.keys.sort
  end
  # Read a schema from a YAML file.
  def add(file)
    doc = YAML.load_file(file)

    doc.each do |domain|
      unless @domains.include? domain['name']
        @domains[domain['name']] = { :classes => [], :predicates => [] }
      end
      domain['schema'].each do |sub,v|
        unless @data[:classes].include? sub
          @data[:classes][sub] = { :in => {}, :out => {} }
        end
        unless @domains[domain['name']][:classes].include? sub
          @domains[domain['name']][:classes] << sub
        end
        v.each do |pred,objs|
          unless @data[:predicates].include? pred
            @data[:predicates][pred] = {:pairs => []}
          end
          unless @domains[domain['name']][:predicates].include? pred
            @domains[domain['name']][:predicates] << pred
          end
          objs.split(' ').each do |obj|
            unless @data[:classes][sub][:out].include? pred
              @data[:classes][sub][:out][pred] = []
            end
            @data[:classes][sub][:out][pred] << obj
            @data[:predicates][pred][:pairs] << [sub, obj]
            if obj[0,1] == '#'
              unless @data[:classes].include? obj
                @data[:classes][obj] = { :in => {}, :out => {} }
              end
              unless @data[:classes][obj][:in].include? pred
                @data[:classes][obj][:in][pred] = []
              end
              @data[:classes][obj][:in][pred] << sub
            end
          end
        end
      end
    end
  end
  # Converts the domain in a yaml file
  def to_yaml
    s = "---\n"
    domains.each do |domain_name|
      s << "- domain:\n"
      s << "  name: \"#{domain_name}\"\n"
      s << "  schema:\n"
      @domains[domain_name][:classes].each do |sub|
        s << "    \"#{sub}\":\n"
        @data[:classes][sub][:out].each do |pre,obj|
          s << "      \"#{pre}\": \"#{obj.join(' ')}\"\n"
        end
      end
    end
    s
  end
end
