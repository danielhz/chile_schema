#!/usr/bin/ruby

require 'yaml'

schema = YAML.load_file('schema.yaml')

Classes = {}
Predicates = {}

def file_name(res)
  file_name = res.sub(/^#/, 'class_').sub(/^@/, 'predicate_')
  file_name = file_name.gsub('á','a').gsub('é','e').gsub('í','i').gsub('ó','o').gsub('ú','u')
  file_name = file_name.gsub('Á','A').gsub('É','E').gsub('Í','I').gsub('Ó','O').gsub('Ú','U')
  file_name = file_name.gsub('ñ','n').gsub('Ñ','N')
  puts "adding " + file_name + ".tex"
  file_name + ".tex"
end

def new_class(res)
  Classes[res] = { :file => File.new(file_name(res), 'w'), :in   => {}, :out  => {} }
end

def new_predicate(res)
  Predicates[res] = { :file => File.new(file_name(res), 'w'), :pairs => [] }
end

schema.each do |sub,v|
  new_class(sub) unless Classes.include? sub
  v.each do |pred,objs|
    new_predicate(pred) unless Predicates.include? pred
    objs.split(' ').each do |obj|
      Classes[sub][:out][pred] = [] unless Classes[sub][:out].include? pred
      Classes[sub][:out][pred] << obj
      Predicates[pred][:pairs] << [sub, obj]
      if obj[0,1] == '#'
        new_class(obj) unless Classes.include? obj
        Classes[obj][:in][pred] = [] unless Classes[obj][:in].include? pred
        Classes[obj][:in][pred] << sub
      end
    end
  end
end

def write_class(c)
  file     = Classes[c][:file]
  pred_in  = Classes[c][:in]
  pred_out = Classes[c][:out]
  file << "\\item[Atributos salientes:] \\hfill \\\\\n"
  file << "  \\begin{tabular}{ll}\n"
  file << "    {\\em predicado} & {\\em objetos} \\\\\n"
  pred_out.each { |pred,v| file << "    #{pred}: & #{v.map{ |x| '\\' + x }.join(' ')} \\\\\n" }
  file << "  \\end{tabular}\n"
  file << "\\item[Atributos entrantes:] \\hfill \\\\\n"
  file << "  \\begin{tabular}{ll}\n"
  file << "    {\\em predicado} & {\\em sujetos} \\\\\n"
  pred_in.each { |pred,v| file << "    #{pred}: & #{v.map{ |x| '\\' + x }.join(' ')} \\\\\n" }
  file << "  \\end{tabular}\n"
end

Classes.each_key { |c| write_class(c) }

def write_predicate(pred)
  file  = Predicates[pred][:file]
  pairs = Predicates[pred][:pairs]
  file << "\\item[Elementos relacionados:] \\hfill \\\\\n"
  file << "  \\begin{tabular}{ll}\n"
  file << "    {\\em sujeto} & {\\em objeto} \\\\\n"
  pairs.each { |e| file << "    \\#{e[0]} & \\#{e[1]} \\\\\n" }
  file << "  \\end{tabular}\n"
  unless File.exist?("node_" + file_name(pred))
    file = File.new("node_" + file_name(pred), 'w')
    file << "\\subsubsection{#{pred}}\n\n"
    file << "\\begin{description}\n"
    file << "  \\input{#{file_name(pred)}}"
    file << "\\end{description}\n"
  end
end

Predicates.each_key { |pred| write_predicate(pred) }

predicate_index = File.new('predicates.tex', 'w')
Dir["node_predicate_*.tex"].each do |f|
  predicate_index << "\\input{#{f}}\n"
end
